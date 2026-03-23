extends Control

var unlockable_recipes = [] # list of content ids for the recipes that can be unlocked right now
var unlockable_stations = [] # list of content ids for the stations that can be unlocked right now
@onready var shop_entry_container: GridContainer = $ShopEntryContainer
@onready var unlocked_everything_label: Label = $UnlockedEverythingLabel
@onready var cash_label: Label = $CashLabel
@onready var continue_button: Button = $ContinueButton
@export var shop_entry_scene: String = "res://scenes/prefabs/ShopEntry.tscn"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cash_label.text = "Cash: $%d" % Gamestate.cash
	update_shop_entries()
	continue_button.pressed.connect(on_continue_pressed)

func update_shop_entries() -> void:
	for child in shop_entry_container.get_children(): # clear existing shop entries
		child.queue_free()
	unlockable_recipes = Gamestate.get_unlockable_now("recipe", false)
	unlockable_stations = Gamestate.get_unlockable_now("station", false)

	for content_id in unlockable_recipes:
		var entry = load(shop_entry_scene).instantiate() as Control
		entry.content_id = content_id
		entry.display_name = content_id
		entry.content_type = "recipe"
		shop_entry_container.add_child(entry)
	
	for content_id in unlockable_stations:
		var entry = load(shop_entry_scene).instantiate() as Control
		entry.content_id = content_id
		entry.display_name = content_id
		entry.content_type = "station"
		shop_entry_container.add_child(entry)
	
	if unlockable_recipes.size() == 0 and unlockable_stations.size() == 0:
		unlocked_everything_label.show()
	else:
		unlocked_everything_label.hide()

func unlock_content(content_id: String) -> void:
	if Gamestate.unlock_content(content_id):
		update_shop_entries() # update the shop entries to reflect the newly unlocked content
		cash_label.text = "Cash: $%d" % Gamestate.cash

func on_continue_pressed() -> void:
	continue_button.disabled = true # disable the continue button to prevent multiple presses
	Gamestate.current_day += 1
	Gamestate.save_game()
	Scenechange.change_scene("res://scenes/main_level.tscn")
