extends StaticBody3D
class_name Griddle

@export var player: Player

var slots = {
	#ItemData, item in, the item being cooked
	#Timer, the timer for how long the item has been cooking for, goes to time_to_cook on the item data
	#Result ItemData, the cook_result from the item data, used to know what item to give the player when cooking is done.
	#Status, status
	#FloatingUI instance, reference to the floating UI above this slot, used for updating the UI when the status changes
}
enum SlotStatus {
	COOKING, #slot has an item, and it is actively cooking
	READY, #slot has an item, but it is done cooking and waiting for the player to take it
	EMPTY, #slot is empty and can be used for cooking an item
}

const num_slots = 4

func initialize_slots() -> void:
	for i in range(1, num_slots+1):
		slots[i] = [null, 0.0, null, SlotStatus.EMPTY, null]

func _ready() -> void:
	initialize_slots()
	debug_print_slots()

func debug_print_slots() -> void:
	for i in range(1, num_slots+1):
		var slot = slots[i]
		print("Slot ", i, ": Item: ", slot[0].Name if slot[0] else "None", ", Timer: ", slot[1], ", Result: ", slot[2].Name if slot[2] else "None", ", Status: ", SlotStatus.find_key(slot[3]))

func is_open_slot() -> int:
	for i in range(1, num_slots+1):
		if slots[i][3] == SlotStatus.EMPTY:
			return i
	return -1

func is_held_item_cookable() -> bool:
	return player.inventory.held_item and player.inventory.held_item.item and player.inventory.held_item.item.isCookable()

func can_interact(_interacting_player: Player) -> bool:
	if is_held_item_cookable():
		if is_open_slot() != -1:
			return true
		return false
	return false

func get_interaction_text(_interacting_player: Player) -> String:
	if is_held_item_cookable():
		if is_open_slot() != -1:
			return "Press E to cook %s" % player.inventory.held_item.item.Name
		return "No open slots to cook %s" % player.inventory.held_item.item.Name
	return ""

func interact(_interacting_player: Player) -> void:
	pass
