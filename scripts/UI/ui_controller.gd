extends Control
class_name UIController

@export var inventory: Node
@export var blank_icon: Texture2D

@export var state_manager: StateManager
@export var game_manager: GameManager
@export var player: Player
@export var screen_manager: ScreenManager
@onready var hotbar: ItemList = $Hotbar
@onready var daytimer_label: Label = $DayTimer
@onready var interact_label: Label = $InteractLabel
@onready var crosshair: ColorRect = $Crosshair

@onready var pause_menu: Control = $PauseMenu
@onready var quit_button: Button = $PauseMenu/Quit
@onready var resume_button: Button = $PauseMenu/Resume

var daytimer: DayTimer

func _ready():
	# Initialize the day timer and connect signals
	daytimer = DayTimer.new()
	add_child(daytimer)
	daytimer.day_start.connect(on_day_start)
	daytimer.day_end.connect(on_day_end)
	daytimer.time_changed.connect(on_time_changed)
	daytimer.day_start.connect(game_manager.on_day_start)

	# Connect inventory signals to update the hotbar and highlight the selected slot
	inventory.inventory_changed.connect(update_hotbar)
	inventory.selected_item_changed.connect(highlight_slot)
	# Initial hotbar update
	update_hotbar()

	# Connect the game paused signal to show the pause menu
	state_manager.paused.connect(on_game_paused)

	pause_menu.hide()
	quit_button.pressed.connect(state_manager.quit)
	resume_button.pressed.connect(state_manager.toggle_pause)
	player.interact_target.connect(toggle_interact_label)

	game_manager.update_orders_ui.connect(screen_manager.update_screen)



func toggle_interact_label(show_label: bool, text: String = ""):
	print("Toggling interact label: ", show_label, text)
	if show_label:
		interact_label.text = text
		interact_label.show()
	else:
		interact_label.hide()

func update_hotbar():
	for i in range(inventory.inventory_size):
		if i >= hotbar.get_item_count(): # Initial setup of hotbar icons and text
			hotbar.add_item(" ", blank_icon)
			hotbar.set_item_text(i, "0")
		var slot = inventory.slots[i]
		if slot.item == null: # make sure the hotbar icon and text are blank if there is no item in the slot
			hotbar.set_item_icon(i, blank_icon)
			hotbar.set_item_text(i, "0")
		else: # update the hotbar icon and qty text to match the item in the slot
			hotbar.set_item_icon(i, slot.item.Icon)
			if slot.item.MaxStackSize > 1:
				hotbar.set_item_text(i, str(slot.quantity))
			else:
				hotbar.set_item_text(i, "1")

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


func highlight_slot(index: int):
	if index >= 0 and index < hotbar.get_item_count():
		hotbar.select(index)    

func on_game_paused(paused: bool):
	if paused:
		
		get_tree().paused = true
		pause_menu.show()
	else:
		get_tree().paused = false
		pause_menu.hide()
		pass
	pass
