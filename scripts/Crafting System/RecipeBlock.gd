extends Control
class_name RecipeBlock

@onready var custom_tooltip = $Tooltip # tooltip node - tooltip shows ingredients and whether the player has them or not
@onready var tooltip_label = $Tooltip/TooltipLabel # tooltip label
@onready var button = $StartCraftingButton # button to start crafting
@onready var unavailable_overlay: TextureRect = $UnavailableCrossover # overlay to show when the recipe is unavailable
@onready var crafting_status: TextureRect = $CraftingStatus # overlay to show when the recipe is craftable or crafting, uses different textures to indicate which one it is.
@onready var recipe_name_label: Label = $RecipeName # label to show the name of the recipe
#@onready var craft_timer: Label = $CraftTimer
@onready var available_texture: Texture2D = preload("res://others/textures/available_to_craft.png") #available to craft
@onready var crafting_texture: Texture2D = preload("res://others/textures/crafting_finished.png") #currently crafting or ready to collect

var recipe_ref: Recipe # reference to the recipe this block represents, used for accessing the recipe's data when we click on the block to start crafting or collect the item or whatever.


func _ready():
	button.mouse_entered.connect(_on_mouse_entered)
	button.mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	print("mouse enter")
	custom_tooltip.visible = true

func _on_mouse_exited():
	print("mouse exit")
	custom_tooltip.visible = false

# set the tooltip text, based on ingredients and the ones we're missing.
func set_tt_text(ingredients: Array[ItemData], missing: Array[ItemData]) -> void:
	var text = "[color=white]Ingredients:[/color]\n"
	for ingredient in ingredients:
		if ingredient in missing:
			text += "[outline_size=1][outline_color=black][color=#FF5555][b]- " + ingredient.Name + " (missing)[/b][/color][/outline_color][/outline_size]\n"
			missing.erase(ingredient) # remove this ingredient from the missing list so that if there are duplicates it doesn't mark them all as missing.
		else:
			text += "- " + ingredient.Name + "\n"
	tooltip_label.text = text

# set the recipe reference.
func set_recipe(recipe: Recipe) -> void:
	recipe_name_label.text = recipe.result.Name
	set_tt_text(recipe.ingredients, []) # Initially set tooltip with no missing ingredients. This will be updated later based on the player's inventory.
	recipe_ref = recipe

# set the status of the recipe block (craftable, crafting, unavailable, ready) and update the UI accordingly.
func set_status(status: int) -> void:
	match status:
		0: #craftable
			button.disabled = false
			unavailable_overlay.visible = false
			crafting_status.visible = true
			crafting_status.texture = available_texture

		1: #crafting
			button.disabled = false
			unavailable_overlay.visible = false
			crafting_status.visible = true
			crafting_status.texture = crafting_texture

		2: #unavailable
			button.disabled = true
			unavailable_overlay.visible = true
			crafting_status.visible = true
			crafting_status.texture = available_texture
		4: #ready
			button.disabled = false
			unavailable_overlay.visible = false
			crafting_status.visible = true
			crafting_status.texture = crafting_texture
