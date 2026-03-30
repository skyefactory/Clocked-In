extends Node

enum States {
	MENU,
	KITCHEN,
	GAMEOVER
}
var current_state = null

var cash = 0 # player cash
var rating = 1 # player rating
var rating_points = 0 # player rating points
var current_day = 0 # current day
var unlocked_content: Dictionary = {}

var chef_name: String = "" # the name of the player's chef
var restaurant_name: String = "" # the name of the player's restaurant

const DEBUG_CHEF_NAME: String = "Skye"
const DEBUG_RESTAURANT_NAME: String = "Skye's Burgers"
const DEBUG_UNLOCK_CONTENT_IDS: Array[String] = [
	"Fryer",
	"Drink Machine",
	"Cheeseburger",
	"Bacon Cheeseburger",
	"Soda",
	"COFFEE",
	"Fries"
]

var last_day_perfect_orders: Array = [] # perfect orders from the last day
var last_day_late_orders: Array = [] # late orders from the last day
var last_day_wrong_orders: Array = [] # wrong orders from the last day
var last_day_payout: float = 0.0 # payout from the last day

#SETTINGS	
var fullscreen: bool = false
var mouse_sensitivity: float = 1.0
var volume: float = 100.0
#CONTROL SETTINGS
var move_forward: String = "W"
var move_backward: String = "S"
var move_left: String = "A"
var move_right: String = "D"
var interact: String = "E"
var toggle_menu: String = "Escape"
var drop_item: String = "Q"
var end_day: String = "F"

# Type: station or recipe
# starts_unlcoked: whether the content is unlocked at the start of the game
# requires_all: list of ids that must be unlocked before this content can be unlocked
# cash_cost: how much cash is required to unlock this content
# grants_supplies: list of supply ids that are granted to the player when this content is

var content_defs = {
	# Stations
	"Assembler": {"type": "station", "starts_unlocked": true, "requires_all": [], "cash_cost": 0, "grants_supplies": []},
	"Griddle": {"type": "station", "starts_unlocked": true, "requires_all": [], "cash_cost": 0, "grants_supplies": []},
	"Second Griddle": {"type": "station", "starts_unlocked": false, "requires_all": ["Griddle"], "cash_cost": 120, "grants_supplies": []},
	"Drink Machine": {"type": "station", "starts_unlocked": false, "requires_all": ["Griddle"], "cash_cost": 160, "grants_supplies": []},
	"Second Drink Machine": {"type": "station", "starts_unlocked": false, "requires_all": ["Drink Machine"], "cash_cost": 280, "grants_supplies": []},
	"Fryer": {"type": "station", "starts_unlocked": false, "requires_all": ["Drink Machine"], "cash_cost": 120, "grants_supplies": []},
	"Second Fryer": {"type": "station", "starts_unlocked": false, "requires_all": ["Fryer"], "cash_cost": 320, "grants_supplies": []},
	
	# Recipes
	"Plain Burger": {"type": "recipe", "starts_unlocked": true, "requires_all": [], "cash_cost": 0, "grants_supplies": ["BUNS", "RAWPATTY"]},
	"Double Burger": {"type": "recipe", "starts_unlocked": true, "requires_all": [], "cash_cost": 0, "grants_supplies": ["BUNS", "RAWPATTY"]},
	"Cheeseburger": {"type": "recipe", "starts_unlocked": false, "requires_all": ["Plain Burger", "Griddle"], "cash_cost": 10, "grants_supplies": ["BUNS", "RAWPATTY", "CHEESE"]},
	"Double Cheeseburger": {"type": "recipe", "starts_unlocked": false, "requires_all": ["Double Burger", "Griddle"], "cash_cost": 20, "grants_supplies": ["BUNS", "RAWPATTY", "CHEESE"]},
	"Bacon Cheeseburger": {"type": "recipe", "starts_unlocked": false, "requires_all": ["Cheeseburger", "Griddle"], "cash_cost": 30, "grants_supplies": ["BUNS", "RAWPATTY", "CHEESE", "RAWBACON"]},
	"Double Bacon Cheeseburger": {"type": "recipe", "starts_unlocked": false, "requires_all": ["Double Cheeseburger", "Griddle"], "cash_cost": 40, "grants_supplies": ["BUNS", "RAWPATTY", "CHEESE", "RAWBACON"]},
	"BLT": {"type": "recipe", "starts_unlocked": false, "requires_all": ["Bacon Cheeseburger", "Griddle"], "cash_cost": 50, "grants_supplies": ["BUNS", "LETTUCE", "TOMATO", "RAWBACON"]},
	"Fries": {"type": "recipe", "starts_unlocked": false, "requires_all": ["Fryer"], "cash_cost": 20, "grants_supplies": ["FROZENFRIES"]},
	"Soda": {"type": "recipe", "starts_unlocked": false, "requires_all": ["Drink Machine"], "cash_cost": 10, "grants_supplies": ["EMPTYCUP"]},
	"Beer": {"type": "recipe", "starts_unlocked": false, "requires_all": ["Drink Machine"], "cash_cost": 10, "grants_supplies": ["EMPTYCUP"]},
	"COFFEE": {"type": "recipe", "starts_unlocked": false, "requires_all": ["Drink Machine"], "cash_cost": 10, "grants_supplies": ["EMPTYCUP"]}
}#buns, raw patty, cheese, raw bacon, lettuce, tomato, frozen fries, empty cup

const supplies_cost:int = 6 # how much it costs to keep a stock of each supply for a day.

func get_total_supplies_cost() -> int:
	var total_cost = 0
	var supplies = get_available_supplies()
	for supply in supplies:
		total_cost += supplies_cost
	return total_cost

func _ready() -> void:
	initialize_unlocked_content()
	load_settings()
	apply_settings()


# set unlocked content to the unlocks with start unlocked as true
func initialize_unlocked_content() -> void:
	unlocked_content.clear() # clear unlocked content
	for content_id in content_defs.keys(): # for each content definition
		if content_defs[content_id].get("starts_unlocked", false): # if it has starts unlocked as true
			unlocked_content[content_id] = true # add it to unlocked content
	apply_name_debug_unlocks()

func apply_name_debug_unlocks() -> void:
	if chef_name != DEBUG_CHEF_NAME or restaurant_name != DEBUG_RESTAURANT_NAME:
		return

	for content_id in DEBUG_UNLOCK_CONTENT_IDS:
		if has_content(content_id):
			unlocked_content[content_id] = true

#does this content exist
func has_content(content_id: String) -> bool:
	return content_defs.has(content_id)

# is this content currently unlocked
func is_unlocked(content_id: String) -> bool:
	return unlocked_content.has(content_id)

# get the cash cost to unlock this content, returns 0 if the content doesn't exist or has no cash cost.
func get_cash_cost(content_id: String) -> int:
	if not has_content(content_id):
		return 0
	return int(content_defs[content_id].get("cash_cost", 0))

# can this content be unlocked (are all dependencies unlocked and is it not already unlocked)
func can_unlock(content_id: String, care_cash: bool = true) -> bool:
	if not has_content(content_id): # does the content exist
		return false
	if is_unlocked(content_id): # is it already unlocked
		return false
	if care_cash and cash < get_cash_cost(content_id): # is there enough cash
		return false
	var requires_all: Array = content_defs[content_id].get("requires_all", []) # are all dependencies unlocked
	for dependency in requires_all:
		if not is_unlocked(str(dependency)):
			return false
	return true # we can unlock this content

# attempt to unlock this content, returns true if successful
func unlock_content(content_id: String) -> bool:
	if not can_unlock(content_id): # can we unlock this content
		return false
	cash -= get_cash_cost(content_id) # pay the cash cost
	unlocked_content[content_id] = true # add this content to unlocked content
	return true

# returns what can be unlocked right now.
func get_unlockable_now(content_type: String = "", care_cash: bool = true) -> Array[String]:
	var unlockable: Array[String] = []
	for content_id in content_defs.keys(): # for each content
		if content_type != "" and content_defs[content_id].get("type", "") != content_type: # if a content type is specified and this content doesn't match, skip it
			continue
		if can_unlock(content_id, care_cash): # if we can unlock this content
			unlockable.append(content_id)
	unlockable.sort() # sort the unlockable content alphabetically
	return unlockable

# gets the supplies granted by content
func get_granted_supplies(content_id: String) -> Array[String]:
	if not has_content(content_id):
		return []

	var raw_supplies: Array = content_defs[content_id].get("grants_supplies", [])
	var granted_supplies: Array[String] = []
	for supply_id in raw_supplies:
		granted_supplies.append(str(supply_id))
	return granted_supplies

#  content_type should be "station" or "recipe" or left blank to check all types. 
# returns a sorted list of unlocked content of the given type.
func get_unlocked_by_type(content_type: String) -> Array[String]:
	var unlocked: Array[String] = []
	for content_id in unlocked_content.keys(): # for each unlocked content
		if content_defs[content_id].get("type", "") == content_type: # if this content matches the specified type
			unlocked.append(content_id) # add it to the list of unlocked content of this type
	unlocked.sort() # sort the unlocked content alphabetically
	return unlocked

#returns all supplies that should be available based on the unlocked content
func get_available_supplies() -> Array[String]:
	var all_supplies: Array[String] = []
	for recipe_id in get_unlocked_by_type("recipe"): # for each unlocked recipe
		for supply_id in get_granted_supplies(recipe_id): # for each supply granted by this recipe
			if not all_supplies.has(supply_id): # if we don't already have this supply in the list
				all_supplies.append(supply_id) # add it to the list of available supplies
	all_supplies.sort() # sort the available supplies alphabetically
	return all_supplies


# save the game by writing all the relevant variables to a save file. This will be called when the player finishes a day or when they get a game over.
func save_game() -> void:
	var file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	
	file.store_var(cash)
	file.store_var(rating)
	file.store_var(rating_points)
	file.store_var(current_day)
	file.store_var(unlocked_content)
	file.store_var(restaurant_name)
	file.store_var(chef_name)

	file.close()

func save_settings() -> void:
	var file = FileAccess.open("user://settings.save", FileAccess.WRITE)
	if file == null:
		return
	
	file.store_var(fullscreen)
	file.store_var(mouse_sensitivity)
	file.store_var(volume)
	file.store_var(move_forward)
	file.store_var(move_backward)
	file.store_var(move_left)
	file.store_var(move_right)
	file.store_var(interact)
	file.store_var(toggle_menu)
	file.store_var(drop_item)
	file.store_var(end_day)

	file.close()

	apply_settings()

func rebind_control(action: String, new_key: String) -> bool:
	if not InputMap.has_action(action):
		return false

	var normalized_key = new_key.strip_edges()
	if normalized_key == "":
		return false

	var event = InputEventKey.new()
	var keycode = OS.find_keycode_from_string(normalized_key)
	if keycode == 0:
		return false

	InputMap.action_erase_events(action) # remove existing keybinds for this action only if replacement is valid
	event.keycode = keycode
	event.pressed = true
	InputMap.action_add_event(action, event) # add the new keybind for this action
	return true

func _read_setting_or_default(file: FileAccess, default_value):
	if file.get_position() >= file.get_length():
		return default_value

	var value = file.get_var()
	if typeof(value) != typeof(default_value):
		return default_value

	return value

func load_settings() -> void:
	var file = FileAccess.open("user://settings.save", FileAccess.READ)
	
	if file == null:
		return
	
	fullscreen = _read_setting_or_default(file, fullscreen)
	mouse_sensitivity = _read_setting_or_default(file, mouse_sensitivity)
	volume = _read_setting_or_default(file, volume)
	move_forward = _read_setting_or_default(file, move_forward)
	move_backward = _read_setting_or_default(file, move_backward)
	move_left = _read_setting_or_default(file, move_left)
	move_right = _read_setting_or_default(file, move_right)
	interact = _read_setting_or_default(file, interact)
	toggle_menu = _read_setting_or_default(file, toggle_menu)
	drop_item = _read_setting_or_default(file, drop_item)
	end_day = _read_setting_or_default(file, end_day)

	file.close()

func apply_settings() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	AudioServer.set_bus_volume_db(0, linear_to_db(clampf(volume, 0.0, 1.0)))
	
	rebind_control("move_forward", move_forward)
	rebind_control("move_backward", move_backward)
	rebind_control("move_left", move_left)
	rebind_control("move_right", move_right)
	rebind_control("interact", interact)
	rebind_control("toggle_menu", toggle_menu)
	rebind_control("drop_item", drop_item)
	rebind_control("end_day", end_day)
	


