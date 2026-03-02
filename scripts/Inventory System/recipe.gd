extends Resource
class_name Recipe

@export var ingredients: Array[ItemData] # The ingredients required for this recipe, the order of the ingredients does not matter
@export var result: ItemData # The resulting item of this recipe, this is what the player will get after crafting this recipe

#These fields control WHAT sort of crafting station the player needs to use to craft this recipe, 
#for example if assemblable is true and drinkable is false, 
#then the player would need to use the counter to craft this recipe, 
#if drinkable is true and assemblable is false, then the player would need to use the drink station 
#to craft this recipe
@export var assemblable: bool = false #used for determining if this recipe can be made at the counter
@export var drinkable: bool = false #used for determining if this recipe can be made at the drink station

func _init(ingredients_in: Array[ItemData] = [], result_in: ItemData = null) -> void:
    self.ingredients = ingredients_in
    self.result = result_in

