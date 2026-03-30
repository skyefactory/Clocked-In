extends RigidBody3D
class_name WorldItem

signal depleted(world_item: WorldItem)

@export var Data: ItemData # The item data of this world item, this will be used to determine what item this is when the player interacts with it
@export var Quantity: int = 1 # The quantity of the item in this world item, this will be used to determine how many of the item the player picks up when they interact with it
@export var PickupAllowed: bool = true # whether this world item can currently be picked up by player interaction


@onready var player: Player = get_node("/root/Restauraunt/Player")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	add_collision_exception_with(player) # prevents this rigidbody from colliding with the player, allowing the player to pass through it without physics interference.

func can_interact(_interacting_player: Player) -> bool:
	return PickupAllowed and Data != null

func get_interaction_text(_interacting_player: Player) -> String:
	if not PickupAllowed:
		return ""
	if Data:
		return "Press E to pick up %s" % Data.Name
	return "Press E to pick up"

func interact(_interacting_player: Player) -> void:
	if PickupAllowed:
		pickup()

# handles the logic for picking up this item.
func pickup() -> void:
	if not PickupAllowed:
		return
	if player and Data: # make sure there is a player reference and item data
		var remaining = player.inventory.add_inventory_item(Data, 1) # pick up only 1 item at a time
		if remaining == 0: # if the item was successfully added to inventory
			Quantity -= 1 # reduce the quantity in the world by 1
			if Quantity <= 0: # if no more items remain, remove this world item
				emit_signal("depleted", self)
				player.clear_interactable(self) # clear this item as the current interactable.
				if get_parent():
					get_parent().remove_child(self)
				queue_free()
