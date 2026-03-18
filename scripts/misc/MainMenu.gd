extends Control

@onready var new_game_button = $New
@onready var load_button = $Load
@onready var quit_button = $Quit
@onready var confirmation_modal = $ConfirmationModal
@onready var confirm_yes_button = $ConfirmationModal/ConfirmYes
@onready var confirm_no_button = $ConfirmationModal/ConfirmNo

func create_new_game(): # called when the new game button is pressed
	#reset gamestate
	Gamestate.cash = 0 # 0 dolar
	Gamestate.rating = 1 # 1 star
	Gamestate.rating_points = 0 # 0 rating points
	Gamestate.current_day = 0 # day 0 indicates tutorial, day 1 is the first day of the game
	Gamestate.unlocked_content.clear()

	#save the new game state to the save file
	var file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	file.store_var(Gamestate.cash)
	file.store_var(Gamestate.rating)
	file.store_var(Gamestate.rating_points)
	file.store_var(Gamestate.current_day)
	file.store_var(Gamestate.unlocked_content)
	file.close()

	Scenechange.change_scene("res://scenes/main_level.tscn")

func toggle_confirmation_modal():
	confirmation_modal.visible = !confirmation_modal.visible
	

func load_game():
	var file = FileAccess.open("user://savegame.save", FileAccess.READ) # open the save file for reading
	Gamestate.cash = file.get_var()
	Gamestate.rating = file.get_var()
	Gamestate.rating_points = file.get_var()
	Gamestate.current_day = file.get_var()
	Gamestate.unlocked_content = file.get_var()

	file.close()

	Scenechange.change_scene("res://scenes/main_level.tscn")

func does_save_file_exist():
	var file = FileAccess.open("user://savegame.save", FileAccess.READ)
	if file:
		file.close()
		return true
	else:
		return false
	
func start_new_game():
	if does_save_file_exist():
		toggle_confirmation_modal()
		confirm_yes_button.pressed.connect(create_new_game)
		confirm_no_button.pressed.connect(toggle_confirmation_modal)
	else:
		create_new_game()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Set the state
	Gamestate.current_state = Gamestate.States.MENU
	#check if save file exists, if not create it
	if not does_save_file_exist():
		load_button.disabled = true

	load_button.pressed.connect(load_game)
	new_game_button.pressed.connect(start_new_game)
	quit_button.pressed.connect(get_tree().quit)
	pass # Replace with function body.
