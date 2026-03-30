extends Control

var unlockable_recipes = [] # list of content ids for the recipes that can be unlocked right now
var unlockable_stations = [] # list of content ids for the stations that can be unlocked right now
@onready var shop_entry_container: GridContainer = $ShopEntryContainer # container that holds each shop entry
@onready var unlocked_everything_label: Label = $UnlockedEverythingLabel # label that is shown when there is nothing else to unlock.
@onready var cash_label: Label = $CashLabel # label that displays the player's current cash
@onready var continue_button: Button = $ContinueButton # button that continues to the next day after we're done shopping
@export var shop_entry_scene: String = "res://scenes/prefabs/ShopEntry.tscn" # the scene that represents a single entry in the shop

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cash_label.text = "Cash: $%d" % Gamestate.cash # set the cash label to show the player's current cash
	update_shop_entries() # populate the shop with the appropriate entries for the current game state
	continue_button.pressed.connect(on_continue_pressed) # connect the continue button to the function that continues to the next day

func update_shop_entries() -> void:
	for child in shop_entry_container.get_children(): # clear existing shop entries
		child.queue_free()
	unlockable_recipes = Gamestate.get_unlockable_now("recipe", false) # get all unlockable recipes
	unlockable_stations = Gamestate.get_unlockable_now("station", false) # get all unlockable stations

	for content_id in unlockable_recipes:
		var entry = load(shop_entry_scene).instantiate() as Control # create a new shop entry
		entry.content_id = content_id # set the content id of the shop entry so it knows what content it represents when we try to unlock it
		entry.display_name = content_id # set the content ID name as the display name
		entry.content_type = "recipe" # set the content type so the shop entry knows what type of content it is representing when we try to unlock it
		shop_entry_container.add_child(entry) # add the shop entry to the container to display it in the shop
	
	# same story for stations
	for content_id in unlockable_stations:
		var entry = load(shop_entry_scene).instantiate() as Control
		entry.content_id = content_id
		entry.display_name = content_id
		entry.content_type = "station"
		shop_entry_container.add_child(entry)
	
	# if there is nothing to unlock, show the "you've unlocked everything" label, otherwise hide it.
	if unlockable_recipes.size() == 0 and unlockable_stations.size() == 0:
		unlocked_everything_label.show()
	else:
		unlocked_everything_label.hide()

# this function is called by the shop entry when we successfully unlock content, it updates the shop entries and cash display to reflect the newly unlocked content and the cash spent on unlocking it.
func unlock_content(content_id: String) -> void:
	if Gamestate.unlock_content(content_id):
		update_shop_entries() # update the shop entries to reflect the newly unlocked content
		cash_label.text = "Cash: $%d" % Gamestate.cash

# this function is called when we press the continue button, it increments the day, saves the game, and goes back to the main level scene to start the next day.
func on_continue_pressed() -> void:
	continue_button.disabled = true # disable the continue button to prevent multiple presses
	Gamestate.current_day += 1
	Gamestate.save_game()
	Scenechange.change_scene("res://scenes/main_level.tscn")
