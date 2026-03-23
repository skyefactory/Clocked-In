extends Control

@onready var new_game_button = $New #button to start a new game
@onready var load_button = $Load #button to load an existing game
@onready var quit_button = $Quit #button to quit the game

@onready var confirmation_modal = $ConfirmationModal # modal that asks the player to confirm if they want to start a new game when they already have a save file
@onready var confirm_yes_button = $ConfirmationModal/ConfirmYes # button to confirm starting a new game and overwriting the existing save file
@onready var confirm_no_button = $ConfirmationModal/ConfirmNo # button to cancel starting a new game and keep the existing save file

@onready var name_entry_modal = $NameEntryModal # modal that asks the player to enter their restaurant and chef name when starting a new game, this only shows up if they don't have an existing save file, if they do have a save file it will just use the names from the save file.
@onready var restauraunt_name: LineEdit = $NameEntryModal/RestaurauntName # line edit for the player to enter their restaurant name when starting a new game
@onready var chef_name: LineEdit = $NameEntryModal/ChefName # line edit for the player to enter their chef name when starting a new game
@onready var name_confirm_button = $NameEntryModal/Confirm # button to confirm the entered names and start the new game

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
	Gamestate.restauraunt_name = file.get_var()
	Gamestate.chef_name = file.get_var()

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
