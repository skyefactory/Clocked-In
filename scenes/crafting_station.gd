extends Control
class_name CraftingStation

@export var assembler: bool = false
@export var filler: bool = false
@export var recipes_path: String = "res://scenes/items/recipes/"
var recipes: Array[Recipe] = []

func load_recipes() -> void:
    var dir = DirAccess.open(recipes_path) # open the path
    if dir: # if the path was opened OK
        dir.list_dir_begin() # begin listing the dir
        var file_name = dir.get_next() # get the filename

        while file_name != "": # if filename is not empty
            if file_name.ends_with(".tres"): # if it is a resource file
                #load the resource
                var recipe_resource = ResourceLoader.load(recipes_path + "/" + file_name)
                #check that it is a recipe
                if recipe_resource is Recipe and ((assembler and recipe_resource.assembler) or (filler and recipe_resource.filler)):
                    #add it to our recipes
                    recipes.append(recipe_resource)
            #get the next file
            file_name = dir.get_next()
        return
    # If we failed to open the directory, print an error
    push_error("Failed to load recipes from path: " + recipes_path)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    load_recipes() # Load the recipes when the node is ready
