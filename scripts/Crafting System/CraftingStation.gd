extends Control
class_name CraftingStation

@export var recipes_path: String = "res://scenes/items/recipes/" # path to folder containing the recipe resources.
@export var inventory: Inventory # reference to the player's inventory
@export var player: Player # reference to the player.
@export var game_manager: GameManager # reference to the game manager for pause state updates.
@export var recipe_block_scene: PackedScene = preload("res://scenes/prefabs/recipe_block.tscn") # prefab scene for the recipe blocks that will be added to the crafting station UI.
@export var station_name: String = "Assembling Station" # name of this station.
@onready var recipe_block_container: GridContainer = $GridContainer # reference to the container in the UI where the recipe blocks will be added.
@onready var station_name_label: Label = $StationName # reference to the label in the UI where the station name is displayed.
@onready var close_button: Button = $CloseButton # reference to the button in the UI used to close the crafting station UI.

@export var assembler: bool = false # type of station
@export var filler: bool = false #type of station
var recipes: Array[Recipe] = [] # recipe storage
var crafting_dict: Dictionary = {} # Dictionary that maps recipes to their status and crafting timer.
var was_visible_before_pause: bool = false

@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D # reference to the audio player for playing crafting sounds.

enum recipe_status {
	CRAFTABLE,
	CRAFTING,
	UNAVAILABLE,
	READY
}

func _process(delta):
	#closes the UI when the close button is pressed
	if close_button.is_pressed():
		self.hide()
		player.capture_mouse()
	
	# Update crafting timers
	for recipe in crafting_dict.keys():
		if crafting_dict[recipe]["status"] == recipe_status.CRAFTING: #check that this recipe is crafting currently.
			crafting_dict[recipe]["timer"] -= delta # tick down the stored timer
			update_recipe_block_timer(recipe, crafting_dict[recipe]["timer"]) # update the timer display on the recipe block UI for this recipe.
			if crafting_dict[recipe]["timer"] <= 0: # if it has reached 0, crafting is finished.
				#play the crafting finished sound
				audio_player.play()
				crafting_dict[recipe]["status"] = recipe_status.READY # set the status to ready so the player can collect the item.
				crafting_dict[recipe]["itemstorage"] = [] # clear the stored ingredients since crafting is finished and the player can no longer cancel and get them back.
				update_recipe_block_status(recipe) # update the UI for this recipe block to show that it is ready to collect.
		else:
			update_recipe_block_timer(recipe, -1) # if we're not crafting this item, clear the timer by passing -1.

# when a recipe block is clicked on. Depending on the status of the recipe, we either start crafting, cancel crafting, or collect the crafted item.
func on_recipe_button_pressed(recipe: Recipe) -> void:
	if crafting_dict[recipe]["status"] == recipe_status.CRAFTABLE: # this item is craftable, start crafting it.
		start_crafting(recipe)
	elif crafting_dict[recipe]["status"] == recipe_status.READY: # this item has been crafted, take it                    
		# Give the player the crafted item
		if inventory.add_inventory_item(recipe.result, 1) == 0: # add to inventory
		# Set the recipe status back to unavailable after crafting is done and item is collected.
			crafting_dict[recipe]["status"] = recipe_status.UNAVAILABLE # update status to unavailable.
	elif crafting_dict[recipe]["status"] == recipe_status.CRAFTING:
		cancel_crafting(recipe)
	
	update_crafting_status() # update the crafting status of all recipes after a button press in case the player's inventory has changed and that affects what they can craft.
	update_recipe_block_status(recipe) # update the UI for this recipe block to reflect the new status after the button press.
	
func update_recipe_block_timer(recipe: Recipe, remaining_time: float) -> void:
	for child in recipe_block_container.get_children():
		if child.recipe_ref == recipe:
			child.update_timer(remaining_time)
			break

#update recipe blocks with the current status. This is called whenever a recipe's status changes to update the UI to reflect the new status.
func update_recipe_block_status(recipe: Recipe) -> void:
	for child in recipe_block_container.get_children():
		if child.recipe_ref == recipe:
			child.set_status(crafting_dict[recipe]["status"])
			break

# start crafting a recipe: set the status to crafting, start the timer, and store the ingredients from the player's inventory.
func start_crafting(recipe: Recipe) -> void:
	var craft = crafting_dict[recipe]
	craft["timer"] = recipe.time_to_craft
	craft["status"] = recipe_status.CRAFTING
	for ingredient in recipe.ingredients:
		inventory.take_item(ingredient, 1) # remove the ingredients from the player's inventory when crafting starts.
		craft["itemstorage"].append(ingredient) # store the removed ingredients in the crafting dict in case we want to return them to the player if crafting is cancelled or something like that.

# cancel crafting: if we have not finished crafting, set the status back to unavailable, reset the timer, and return any stored ingredients back to the player's inventory.
func cancel_crafting(recipe: Recipe) -> void:
	var craft = crafting_dict[recipe]
	if craft["status"] == recipe_status.CRAFTING:
		craft["timer"] = 0
		craft["status"] = recipe_status.UNAVAILABLE
		for item in craft["itemstorage"]:
			inventory.add_inventory_item(item, 1) # return the stored ingredients to the player's inventory if crafting is cancelled.
		craft["itemstorage"] = [] # clear the stored ingredients since we have returned them to the player.

func initialize_recipes() -> void: #setup crafting dict with all recipes as keys and default values.
	for recipe in recipes:
		crafting_dict[recipe] = { #The dictionary used for crafting 
			"status": recipe_status.UNAVAILABLE,  # status of the item, used for determing crafting state
			"timer": 0.0, # timer for crafting, counts down when crafting is in progress.
			"result": null, # resulting item from crafting
			"itemstorage": [] # stores the ingredients during crafting. Destroyed when crafting is finished. Returned to player if crafting is cancelled.
		}

func load_recipes() -> void: #load all recipes from the specified path and add them to the recipes array.
	recipes.clear()
	var dir = DirAccess.open(recipes_path) # open the path
	if dir: # if the path was opened OK
		dir.list_dir_begin() # begin listing the dir
		var file_name = dir.get_next() # get the filename

		while file_name != "": # if filename is not empty
			if not dir.current_is_dir():
				var resource_path := recipes_path.path_join(file_name)
				# Exported builds may list remapped resources as *.remap.
				if resource_path.ends_with(".remap"):
					resource_path = resource_path.trim_suffix(".remap")

				var recipe_resource = ResourceLoader.load(resource_path)
				if recipe_resource is Recipe and ((assembler and recipe_resource.assemblable) or (filler and recipe_resource.drinkable)):
					recipes.append(recipe_resource)
			#get the next file
			file_name = dir.get_next()
		dir.list_dir_end()
		remove_not_unlocked_recipes()
		if recipes.is_empty():
			push_warning("No station recipes were loaded from path: " + recipes_path)
		return
	# If we failed to open the directory, print an error
	push_error("Failed to load recipes from path: " + recipes_path)

func remove_not_unlocked_recipes() -> void:
	var unlocked_recipes = Gamestate.get_unlocked_by_type("recipe")
	var recipes_to_remove: Array[Recipe] = []
	for recipe in recipes:
		if not unlocked_recipes.has(recipe.result.Name):
			recipes_to_remove.append(recipe)

	for recipe in recipes_to_remove:
		recipes.erase(recipe)

func debug_print_crafting_dict() -> void: # print the crafting dictionary for debugging purposes.
	pass

func debug_print_recipes() -> void: # print the loaded recipes for debugging purposes.
	pass

func update_crafting_status() -> void:
	for recipe in recipes: # for each recipe.
		var result = inventory.has_items(recipe.ingredients) # do we have all the ingredients for this recipe in our inventory?
		var can_craft = result["has_all"] # can we craft this recipe? (i.e. do we have all the ingredients for it?)
		
		# if we can craft it and it's not already crafting or ready, set it to craftable.
		if can_craft and (crafting_dict[recipe]["status"] != recipe_status.CRAFTING && crafting_dict[recipe]["status"] != recipe_status.READY): # if we can craft and it's not already crafting, set it to craftable.
			crafting_dict[recipe]["status"] = recipe_status.CRAFTABLE
		# if we can't craft it and it's not already crafting or ready, set it to unavailable.
		elif not can_craft and (crafting_dict[recipe]["status"] != recipe_status.CRAFTING && crafting_dict[recipe]["status"] != recipe_status.READY): # if we can't craft and it's not already crafting, set it to unavailable.
			crafting_dict[recipe]["status"] = recipe_status.UNAVAILABLE
		update_recipe_block_status(recipe)

func initialize_ui() -> void:
	# Clear existing recipe blocks
	for child in recipe_block_container.get_children():
		child.queue_free()

	# Add a recipe block for each recipe
	for recipe in recipes:
		var block = recipe_block_scene.instantiate() as RecipeBlock
		recipe_block_container.add_child(block)
		block.set_recipe(recipe)
		block.set_status(crafting_dict[recipe]["status"])
		#connect the button press signal to the on_recipe_button_pressed function, passing the corresponding recipe as an argument.
		block.button.pressed.connect(on_recipe_button_pressed.bindv([recipe]))
	
	update_tooltip()
	update_crafting_status()
# Check all ingredients , for any item missing, tooltip should show that item in red.
func update_tooltip() -> void:
	for child in recipe_block_container.get_children():
		var res = inventory.has_items(child.recipe_ref.ingredients)
		child.set_tt_text(child.recipe_ref.ingredients, res["missing"])

func on_game_paused(paused: bool) -> void:
	if paused:
		was_visible_before_pause = visible
		if visible:
			hide()
	else:
		if was_visible_before_pause:
			show()
			player.release_mouse()
		was_visible_before_pause = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	station_name_label.text = station_name
	load_recipes() # Load the recipes when the node is ready
	initialize_recipes() # Initialize the crafting dictionary for all loaded recipes
	initialize_ui() 
	inventory.inventory_changed.connect(update_crafting_status) # Connect the inventory changed signal to update crafting status when the inventory changes.
	inventory.inventory_changed.connect(update_tooltip) # Connect the inventory changed signal to update the tooltip when the inventory changes.
	if game_manager == null:
		game_manager = get_node_or_null("../../GameManager") as GameManager
	if game_manager:
		game_manager.paused.connect(on_game_paused)
