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

@onready var assembler_crafting_station: CraftingStation = $AssemblerCraftingStation

var daytimer: DayTimer
var inventory_hint_request_id: int = 0

func _ready():
	# Initialize the day timer and connect signals
	daytimer = DayTimer.new()
	add_child(daytimer)
	daytimer.day_start.connect(on_day_start)
	daytimer.day_end.connect(on_day_end)
	daytimer.time_changed.connect(on_time_changed)
	daytimer.day_start.connect(game_manager.on_day_start)
	daytimer.day_start.connect(order_manager.on_day_start)
	daytimer.day_end.connect(order_manager.on_day_end)
	daytimer.day_end.connect(game_manager.on_day_end)
	daytimer.time_changed.connect(order_manager.on_time_changed)

	# Connect inventory signals to update the hotbar and highlight the selected slot
	inventory.inventory_changed.connect(update_hotbar)
	inventory.selected_item_changed.connect(highlight_slot)
	inventory.selected_item_changed.connect(show_inventory_hint)
	# Initial hotbar update
	update_hotbar()
	inventory_hint.hide()

	# Connect the game paused signal to show the pause menu
	game_manager.paused.connect(on_game_paused)

	pause_menu.hide()
	quit_button.pressed.connect(game_manager.quit)
	resume_button.pressed.connect(game_manager.toggle_pause)
	player.interact_target.connect(toggle_interact_label)

	order_manager.update_orders_ui.connect(screen_manager.update_screen)
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

# trigger to show the interaction label. Called by other scripts when they need it via signal.
func toggle_interact_label(show_label: bool, text: String = ""):
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
	if index >= 0 and index < hotbar.get_item_count():
		hotbar.select(index)    

# shows a hint with the item quantity and name when selected
func show_inventory_hint(index: int) -> void:
	# increment the request id to invalidate any previous requests, 
	# this way if the player quickly changes selection we won't have multiple hints 
	# showing up and hiding at different times.
	inventory_hint_request_id += 1
	var request_id = inventory_hint_request_id

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
	# then hide it after 2 seconds if the request id hasn't changed (meaning the player hasn't changed selection).
	inventory_hint.text = "%d %s" % [slot.quantity, slot.item.Name]
	inventory_hint.show()

	await get_tree().create_timer(2.0).timeout
	if request_id == inventory_hint_request_id:
		inventory_hint.hide()

func on_game_paused(paused: bool):
	if paused:
		get_tree().paused = true
		pause_menu.show()
	else:
		get_tree().paused = false
		pause_menu.hide()
		pass
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
