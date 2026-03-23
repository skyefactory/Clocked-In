extends Control
class_name UIController

@export var inventory: Node
@export var blank_icon: Texture2D

@export var game_manager: GameManager
@export var order_manager: OrderManager
@export var player: Player
@export var screen_manager: ScreenManager
@onready var hotbar: ItemList = $Hotbar
@onready var daytimer_label: Label = $VBox/HBox/DayTimer
@onready var interact_label: Label = $InteractLabel
@onready var cash_label: Label = $VBox/CashLabel
@onready var rating_label: Label = $VBox/RatingLabel
@onready var day_label: Label = $VBox/HBox/DayLabel
@onready var crosshair: ColorRect = $Crosshair
@onready var inventory_hint: Label = $InventoryHint

@onready var pause_menu: Control = $PauseMenu
@onready var quit_button: Button = $PauseMenu/Quit
@onready var resume_button: Button = $PauseMenu/Resume
@onready var day_end_confirmation: Control = $DayEndConfirmation
@onready var day_end_confirm_button: Button = $DayEndConfirmation/Confirm
@onready var day_completed_label: Label = $DayEndConfirmation/DayCompletedLabel
@onready var day_complete_instruction_label: Label = $DayReadyToBeCompletedLabel

@onready var assembler_crafting_station: CraftingStation = $AssemblerCraftingStation

var daytimer: DayTimer
var inventory_hint_request_id: int = 0
var pickup_hint_container: VBoxContainer

const PICKUP_HINT_DURATION: float = 2.0
const PICKUP_HINT_FADE_DURATION: float = 0.25

var day_ready_to_be_completed: bool = false

func _process(delta: float) -> void:
	if day_ready_to_be_completed and Input.is_action_just_released("end_day"):
		player.release_mouse()
		day_completed_label.text = "Day %d Complete!" % Gamestate.current_day
		day_end_confirmation.show()

func _ready():
	# Initialize the day timer and connect signals
	daytimer = DayTimer.new()
	add_child(daytimer)
	daytimer.day_start.connect(on_day_start)
	daytimer.day_end.connect(on_day_end)
	daytimer.time_changed.connect(on_time_changed)
	daytimer.time_changed.connect(game_manager.on_time_changed)
	daytimer.day_start.connect(game_manager.on_day_start)
	daytimer.day_start.connect(order_manager.on_day_start)
	daytimer.day_end.connect(order_manager.on_day_end)
	daytimer.day_end.connect(game_manager.on_day_end)
	daytimer.time_changed.connect(order_manager.on_time_changed)

	# Connect inventory signals to update the hotbar and highlight the selected slot
	inventory.inventory_changed.connect(update_hotbar)
	inventory.inventory_changed.connect(refresh_inventory_hint)
	inventory.selected_item_changed.connect(highlight_slot)
	inventory.selected_item_changed.connect(show_inventory_hint)
	inventory.item_added.connect(show_pickup_hint)
	inventory.item_removed.connect(show_take_hint)
	# Initial hotbar update
	update_hotbar()
	inventory_hint.hide()
	setup_pickup_hint_container()
	resized.connect(update_pickup_hint_position)

	# Connect the game paused signal to show the pause menu
	game_manager.paused.connect(on_game_paused)

	pause_menu.hide()
	quit_button.pressed.connect(game_manager.quit)
	resume_button.pressed.connect(game_manager.toggle_pause)
	player.interact_target.connect(toggle_interact_label)

	order_manager.update_orders_ui.connect(screen_manager.update_screen)
	order_manager.all_orders_completed.connect(game_manager.on_all_orders_completed)
	cash_label.text = "Cash: $%d" % Gamestate.cash
	match Gamestate.rating:
		1:
			rating_label.text = "Rating: ★"
		2:
			rating_label.text = "Rating: ★★"
		3:
			rating_label.text = "Rating: ★★★"
		4:
			rating_label.text = "Rating: ★★★★"
		5:
			rating_label.text = "Rating: ★★★★★"
	day_label.text = "Day %d" % Gamestate.current_day

	game_manager.show_day_end_confirmation.connect(show_day_end_confirmation)
	day_end_confirm_button.pressed.connect(switch_to_day_end_scene)



func show_day_end_confirmation():
	day_ready_to_be_completed = true
	day_complete_instruction_label.text = "Day %d complete! Press F to end the day." % Gamestate.current_day
	day_complete_instruction_label.show()
func switch_to_day_end_scene():
	day_end_confirmation.hide()
	day_complete_instruction_label.hide()
	Scenechange.change_scene("res://scenes/DayEndSummary.tscn")

# trigger to show the interaction label. Called by other scripts when they need it via signal.
func toggle_interact_label(show_label: bool, text: String = ""):
	if game_manager and game_manager.is_paused:
		interact_label.hide()
		return

	if show_label:
		interact_label.text = text
		interact_label.show()
	else:
		interact_label.hide()

# update the inventory hotbar.
func update_hotbar():
	# go over each slot in the inventory and update the corresponding hotbar icon and text to match it.
	for i in range(inventory.inventory_size):
		if i >= hotbar.get_item_count(): # Initial setup of hotbar icons and text
			hotbar.add_item(" ", blank_icon)
			hotbar.set_item_text(i, "0/0")
		var slot = inventory.slots[i]
		if slot.item == null: # make sure the hotbar icon and text are blank if there is no item in the slot
			hotbar.set_item_icon(i, blank_icon)
			hotbar.set_item_text(i, "0/0")
		else: # update the hotbar icon and qty text to match the item in the slot
			hotbar.set_item_icon(i, slot.item.Icon)
			var max_qty = slot.item.MaxStackSize
			hotbar.set_item_text(i, "%d/%d" % [slot.quantity, max_qty])

func refresh_inventory_hint() -> void:
	show_inventory_hint(inventory.selected_slot)

# function for when the day is started, could be used to trigger UI/Audio events
func on_day_start():
	pass
# function for when the day is started, will probably be used to display a scoring screen or something similar
func on_day_end():
	pass

# update daytimer label
func on_time_changed(hour: int, minute: int, pm: bool, spedup: bool):
	var display_hour = hour
	if display_hour == 0:
		display_hour = 12
	var am_pm = "PM" if pm else "AM"
	if spedup:
		daytimer_label.text = "%01d:%02d %s ▶▶" % [display_hour, minute, am_pm]
	else:
		daytimer_label.text = "%01d:%02d %s" % [display_hour, minute, am_pm]

# select the slot in the ItemList.
func highlight_slot(index: int):
	if index >= 0:
		if(index < hotbar.get_item_count()):
			hotbar.select(index)    

# shows a hint with the item quantity and name when selected
func show_inventory_hint(index: int) -> void:

	# if the index is out of bounds, hide the hint and return.
	if index < 0 or index >= inventory.inventory_size:
		inventory_hint.hide()
		return


	var slot: InventorySlot = inventory.slots[index]
	# if the slot is empty, hide the hint and return.
	if slot == null or slot.item == null or slot.quantity <= 0:
		inventory_hint.hide()
		return

	# show the hint with the item name and quantity, 
	inventory_hint.text = "Holding: %s" % slot.item.Name
	inventory_hint.show()

func setup_pickup_hint_container() -> void:
	pickup_hint_container = VBoxContainer.new() # make a container to hold the pickup hints
	pickup_hint_container.name = "PickupHintContainer" #give name
	pickup_hint_container.mouse_filter = Control.MOUSE_FILTER_IGNORE # ignore mouse
	pickup_hint_container.top_level = true # top of the UI
	pickup_hint_container.custom_minimum_size = Vector2(260.0, 0.0) # size
	add_child(pickup_hint_container) # add as a child to the UI
	update_pickup_hint_position()

func update_pickup_hint_position() -> void:
	if pickup_hint_container == null:
		return
	# get viewport
	var rect := get_viewport().get_visible_rect()
	#set position to bottom center of the screen
	pickup_hint_container.position = Vector2((rect.size.x * 0.5) - 130.0, rect.size.y - 420.0)

func show_pickup_hint(item_name: String, quantity: int) -> void:
	show_item_hint(item_name, quantity, true)

func show_take_hint(item_name: String, quantity: int) -> void:
	show_item_hint(item_name, quantity, false)

func show_item_hint(item_name: String, quantity: int, is_positive: bool) -> void:
	if quantity <= 0:
		return

	if pickup_hint_container == null:
		return

	var pickup_label := Label.new()
	pickup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pickup_label.text = "%s%d %s" % ["+" if is_positive else "-", quantity, item_name]
	pickup_label.modulate = Color(0.75, 1.0, 0.75, 1.0) if is_positive else Color(1.0, 0.45, 0.45, 1.0)
	
	pickup_hint_container.add_child(pickup_label)
	pickup_hint_container.move_child(pickup_label, 0)
	

	var tween := create_tween()
	tween.tween_interval(PICKUP_HINT_DURATION)
	tween.tween_property(pickup_label, "modulate:a", 0.0, PICKUP_HINT_FADE_DURATION)
	tween.finished.connect(pickup_label.queue_free)


func on_game_paused(paused: bool):
	if paused:
		interact_label.hide()
		get_tree().paused = true
		pause_menu.show()
	else:
		get_tree().paused = false
		pause_menu.hide()
		if player:
			player.refresh_interaction_prompt()
	pass

# trigger area for the assembler crafting station, shows the crafting UI when the player is within range and hides it when they leave range.
func _on_assembler_trigger_area_body_entered(body: Node3D) -> void:
	if body == player:
		assembler_crafting_station.player_within_range = true
		player.set_interactable(assembler_crafting_station)

# hide the crafting UI when the player leaves the trigger area.
func _on_assembler_trigger_area_body_exited(body: Node3D) -> void:
	if body == player:
		player.clear_interactable(assembler_crafting_station)
		assembler_crafting_station.hide()
		assembler_crafting_station.player_within_range = false
