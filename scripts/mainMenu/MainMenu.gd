extends Control

@onready var new_game_button = $New #button to start a new game
@onready var load_button = $Load #button to load an existing game
@onready var quit_button = $Quit #button to quit the game
@onready var settings_button = $Settings #button to open the settings menu
@onready var confirmation_modal = $ConfirmationModal # modal that asks the player to confirm if they want to start a new game when they already have a save file
@onready var confirm_yes_button = $ConfirmationModal/ConfirmYes # button to confirm starting a new game and overwriting the existing save file
@onready var confirm_no_button = $ConfirmationModal/ConfirmNo # button to cancel starting a new game and keep the existing save file
@onready var settings_modal = $SettingsModal # modal that contains the settings options, this will be implemented in the future, for now it just prints to the console when the settings button is pressed.
@onready var submit_settings_button = $SettingsModal/Submit # button to submit the settings changes, this will be implemented in the future, for now it just prints to the console when pressed.
@onready var cancel_settings_button = $SettingsModal/Cancel # button to cancel any changes made in the settings modal and close the modal, this will be implemented in the future, for now it just prints to the console when pressed.


@onready var name_entry_modal = $NameEntryModal # modal that asks the player to enter their restaurant and chef name when starting a new game, this only shows up if they don't have an existing save file, if they do have a save file it will just use the names from the save file.
@onready var restauraunt_name: LineEdit = $NameEntryModal/RestaurauntName # line edit for the player to enter their restaurant name when starting a new game
@onready var chef_name: LineEdit = $NameEntryModal/ChefName # line edit for the player to enter their chef name when starting a new game
@onready var name_confirm_button = $NameEntryModal/Confirm # button to confirm the entered names and start the new game

@export var fullscreen_toggle: CheckButton # checkbox to toggle fullscreen mode on and off
@export var volume_slider: HSlider # slider to adjust the game's volume
@export var sensitivity_slider: HSlider # slider to adjust the game's mouse sensitivity


#keybind settings. each of these is the entry where the player can enter a single character keybind.
@export var move_forward: LineEdit 
@export var move_backward: LineEdit
@export var move_left: LineEdit
@export var move_right: LineEdit
@export var interact: LineEdit
@export var toggle_menu: LineEdit
@export var drop_item: LineEdit
@export var end_day: LineEdit

@export var volume_slider_label: Label # the label that displays the current volume percentage for the volume slider
@export var sensitivity_slider_label: Label # the label that displays the current sensitivity value for the sensitivity slider

# takes the input from a line edit for a keybind, and normalizes it to a standard key name using godot keycodes. If the input is empty or invalid, it falls back to the previous keybind
func _normalize_keybind_or_fallback(raw_key: String, fallback: String) -> String:
	var trimmed = raw_key.strip_edges()
	if trimmed == "":
		return fallback

	var keycode = OS.find_keycode_from_string(trimmed)
	if keycode == 0:
		return fallback

	return OS.get_keycode_string(keycode)

# syncs the settings UI with the current values in the gamestate, this is used when opening the settings menu to make sure the UI reflects the current settings values.
func _sync_settings_ui_from_gamestate() -> void:
	fullscreen_toggle.button_pressed = Gamestate.fullscreen
	volume_slider.value = Gamestate.volume
	sensitivity_slider.value = Gamestate.mouse_sensitivity

	move_forward.text = Gamestate.move_forward
	move_backward.text = Gamestate.move_backward
	move_left.text = Gamestate.move_left
	move_right.text = Gamestate.move_right
	interact.text = Gamestate.interact
	toggle_menu.text = Gamestate.toggle_menu
	drop_item.text = Gamestate.drop_item
	end_day.text = Gamestate.end_day

	volume_slider_label.text = str(int(Gamestate.volume)) + "%"
	sensitivity_slider_label.text =str(round(Gamestate.mouse_sensitivity))



func create_new_game(): # called when the new game button is pressed
	#reset gamestate
	Gamestate.cash = 0 # 0 dolar
	Gamestate.rating = 1 # 1 star
	Gamestate.rating_points = 0 # 0 rating points
	Gamestate.current_day = 0 # day 0 indicates tutorial, day 1 is the first day of the game
	Gamestate.initialize_unlocked_content() # reset unlocked content to only the starting content
	#save the new game state to the save file
	var file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	file.store_var(Gamestate.cash)
	file.store_var(Gamestate.rating)
	file.store_var(Gamestate.rating_points)
	file.store_var(Gamestate.current_day)
	file.store_var(Gamestate.unlocked_content)
	file.store_var(Gamestate.restaurant_name)
	file.store_var(Gamestate.chef_name)
	file.close()

	Scenechange.change_scene("res://scenes/main_level.tscn")

func toggle_confirmation_modal():
	confirmation_modal.visible = !confirmation_modal.visible
	
# loads the game by reading the save file and setting the variables from the file.
func load_game():
	var file = FileAccess.open("user://savegame.save", FileAccess.READ) # open the save file for reading
	Gamestate.cash = file.get_var()
	Gamestate.rating = file.get_var()
	Gamestate.rating_points = file.get_var()
	Gamestate.current_day = file.get_var()
	Gamestate.unlocked_content = file.get_var()
	Gamestate.restaurant_name = file.get_var()
	Gamestate.chef_name = file.get_var()
	Gamestate.apply_name_debug_unlocks()

	file.close()

	Scenechange.change_scene("res://scenes/main_level.tscn")

# checks if the save file exists by trying to open it for reading, if it opens successfully, the file exists, if it fails to open, the file does not exist.
func does_save_file_exist():
	var file = FileAccess.open("user://savegame.save", FileAccess.READ)
	if file:
		file.close()
		return true
	else:
		return false

# starts the process of starting a new game, if a save file already exists, it will ask for confirmation before starting a new game and overwriting the existing save file, if no save file exists, it will go straight to taking the name entry for the new game.
func start_new_game():
	if does_save_file_exist():
		toggle_confirmation_modal()
		confirm_yes_button.pressed.connect(take_name_entry)
		confirm_no_button.pressed.connect(toggle_confirmation_modal)
	else:
		take_name_entry()

# shows the name entry modal
func take_name_entry():
	name_entry_modal.visible = true
	confirmation_modal.visible = false
	name_confirm_button.pressed.connect(create_new_game_with_name)

# creates a new game with the entered names, if the names are empty, it will not start the game and will wait for valid names to be entered.
func create_new_game_with_name():
	if chef_name.text.strip_edges() == "" or restauraunt_name.text.strip_edges() == "":
		return

	Gamestate.chef_name = chef_name.text.strip_edges()
	Gamestate.restaurant_name = restauraunt_name.text.strip_edges()

	create_new_game()

# opens the settings modal and syncs the current settings values from the gamestate to the UI elements in the settings modal.
func open_settings():
	_sync_settings_ui_from_gamestate()
	settings_modal.visible = true

# closes the settings modal without saving any changes
func close_settings():
	settings_modal.visible = false

# takes the values from the settings UI elements and saves them to the gamestate, then saves the gamestate to the save file so the settings persist, and finally closes the settings modal.
func submit_settings():
	Gamestate.fullscreen = fullscreen_toggle.button_pressed
	Gamestate.mouse_sensitivity = sensitivity_slider.value
	Gamestate.volume = volume_slider.value

	Gamestate.move_forward = _normalize_keybind_or_fallback(move_forward.text, Gamestate.move_forward)
	Gamestate.move_backward = _normalize_keybind_or_fallback(move_backward.text, Gamestate.move_backward)
	Gamestate.move_left = _normalize_keybind_or_fallback(move_left.text, Gamestate.move_left)
	Gamestate.move_right = _normalize_keybind_or_fallback(move_right.text, Gamestate.move_right)
	Gamestate.interact = _normalize_keybind_or_fallback(interact.text, Gamestate.interact)
	Gamestate.toggle_menu = _normalize_keybind_or_fallback(toggle_menu.text, Gamestate.toggle_menu)
	Gamestate.drop_item = _normalize_keybind_or_fallback(drop_item.text, Gamestate.drop_item)
	Gamestate.end_day = _normalize_keybind_or_fallback(end_day.text, Gamestate.end_day)

	Gamestate.save_settings()
	close_settings()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Set the state
	Gamestate.current_state = Gamestate.States.MENU
	#check if save file exists, if not create it
	if not does_save_file_exist():
		load_button.disabled = true

	# hook up all the various buttons and UI elements to their respective functions
	load_button.pressed.connect(load_game)
	new_game_button.pressed.connect(start_new_game)
	quit_button.pressed.connect(get_tree().quit)
	settings_button.pressed.connect(open_settings)
	submit_settings_button.pressed.connect(submit_settings)
	cancel_settings_button.pressed.connect(close_settings)
	volume_slider.value_changed.connect(func(value):
		volume_slider_label.text = str(int(value)) + "%"
	)
	sensitivity_slider.value_changed.connect(func(value):
		sensitivity_slider_label.text = str(round(value))
	)
	pass # Replace with function body.
