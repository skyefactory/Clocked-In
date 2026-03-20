extends Resource
class_name ItemData

@export var ID: int # Unique ID for the item, used for comparing 
@export var Name: String # Name of the item, used for display purposes
@export var Icon: Texture2D # Icon showed in the inventory / hotbar UI
@export var Description: String # Description of the item, not sure where to use this yet, maybe in a tooltip
@export var MaxStackSize: int # Maxiumum number of items that can be stacked, if item is not stackable set this to 1
@export var WorldModelPath: String # The in game/ in world representation of the item.
# used when the item is dropped in the world or when the player is holding it in their hand

@export var cook_result: ItemData = null # If this item is cookable, this variable will hold the resulting item after cooking, if not cookable this will be null
# i.e. if this is a uncooked burger patty, cook_result will be the cooked burger patty item data, if this is a cooked burger patty, 
#cook_result will be null since it cannot be cooked any further
# this field would allow us to control what sort if kitchen appliances the player can interact with, 
#if the player is holding an uncooked patty, they can interact with a griddle to cook it, 
#if they are holding a cooked patty, they cannot interact with the griddle since there is no cook result for the cooked patty
@export var time_to_cook: float = 0.0 # Time in seconds it takes to cook this item, if this item is not cookable this should be set to 0

@export var fry_result: ItemData = null # Similar to cook_result but for frying, if this item can be fried this variable will hold the resulting item after frying, if not fryable this will be null
@export var time_to_fry: float = 0.0 # Time in seconds it takes to fry this item, if this item is not fryable this should be set to 0

func isCookable() -> bool: # quick check to see if cookable. Can be used for interactions with kitchen items.
	return cook_result != null

func isFryable() -> bool: # quick check to see if fryable. Can be used for interactions with kitchen items.
	return fry_result != null
