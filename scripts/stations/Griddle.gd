extends Moveable
class_name Griddle

@export var player: Player
# references to the 6 cooking slots and their associated floating timer UIs
@onready var slot1: Node3D = $Slot1
@onready var slot2: Node3D = $Slot2
@onready var slot3: Node3D = $Slot3
@onready var slot4: Node3D = $Slot4
@onready var slot5: Node3D = $Slot5
@onready var slot6: Node3D = $Slot6

@onready var slot1_timer = $Slot1/FloatingTimer
@onready var slot2_timer = $Slot2/FloatingTimer
@onready var slot3_timer = $Slot3/FloatingTimer
@onready var slot4_timer = $Slot4/FloatingTimer
@onready var slot5_timer = $Slot5/FloatingTimer
@onready var slot6_timer = $Slot6/FloatingTimer

@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D	


var slots = {
}
enum SlotStatus {
	COOKING, #slot has an item, and it is actively cooking
	READY, #slot has an item, but it is done cooking and waiting for the player to take it
	EMPTY, #slot is empty and can be used for cooking an item
}

const num_slots = 6

func initialize_slots() -> void:
	for i in range(1, num_slots+1): # initialize each slot with default values
		slots[i] = {
			"item": null,
			"timer": 0.0,
			"status": SlotStatus.EMPTY,
			"ui": null,
			"world_item": null,
			"world_item_instance": null
		}

		set_floating_ui_for_slot(i) # assign the floating UI instance for this slot

#assign each timer to its corresponding slot in the dictionary for easy access
func set_floating_ui_for_slot(slot_index: int) -> void:
	if not slots.has(slot_index):
		return
	
	match slot_index:
		1:
			slots[slot_index]["ui"] = slot1_timer
		2:
			slots[slot_index]["ui"] = slot2_timer
		3:
			slots[slot_index]["ui"] = slot3_timer
		4:
			slots[slot_index]["ui"] = slot4_timer
		5:
			slots[slot_index]["ui"] = slot5_timer
		6:
			slots[slot_index]["ui"] = slot6_timer
	
	slots[slot_index]["ui"].visible = false # hide the UI initially

#update the floating timers
func update_floating_ui_for_slot(slot_index: int) -> void:
	if not slots.has(slot_index):
		push_error("Invalid slot index: " + str(slot_index))
		return
	
	var slot = slots[slot_index]
	var ui: FloatingTimer = slot["ui"]
	if ui == null:
		push_error("Floating UI instance is null for slot " + str(slot_index))
		return
	
	match slot["status"]:
		SlotStatus.COOKING:
			ui.visible = true
			ui.progress_bar.value = (slot["timer"] / slot["item"].time_to_cook) * 100.0 # update the progress bar based on the cooking timer
		SlotStatus.READY:
			ui.visible = false # hide the timer when the item is ready
			ui.visible = false # hide the timer when the slot is empty

func _ready() -> void: # initialization
	initialize_slots()
	if player == null:
		push_error("Griddle player reference is not assigned.")

# helper function to check for an open slot, returns the index of the first open slot, or -1 if no open slots are available
func is_open_slot() -> int: # returns the index of an open slot, or -1 if no open slots are available
	for i in range(1, num_slots+1):
		if slots[i]["status"] == SlotStatus.EMPTY:
			return i
	return -1


func is_held_item_cookable() -> bool: # returns whether the currently held item is cookable or not by checking if the held item has item data and if that item data is cookable.
	return player.inventory.held_item and player.inventory.held_item.item and player.inventory.held_item.item.isCookable()

func can_interact(_interacting_player: Player) -> bool:
	if is_held_item_cookable(): # is the held item cookable 
		return true
	return false

func get_interaction_text(_interacting_player: Player) -> String:
	if is_held_item_cookable():
		if is_open_slot() != -1:
			return "Press E to cook %s" % player.inventory.held_item.item.Name
		return "No open slots to cook %s" % player.inventory.held_item.item.Name
	return ""

func interact(_interacting_player: Player) -> void:
	if can_interact(_interacting_player) and is_open_slot() != -1:
		var slot_index = is_open_slot() # get the first open slot index
		var held_item = player.inventory.held_item.item # get the held item data
		slots[slot_index]["item"] = held_item # item in the slot
		slots[slot_index]["timer"] = 0.0 # cooking timer starts at 0
		slots[slot_index]["status"] = SlotStatus.COOKING # set status
		slots[slot_index]["world_item"] = held_item.WorldModelPath # store the world model path
		despawn_slot_world_item(slot_index) # clear any existing world item in this slot just in case
		spawn_world_item_for_slot(slot_index, held_item, false, false) # spawn the raw item as a world item that cannot be picked up
		player.inventory.take_item(held_item, 1) # take the item from the player's inventory

# gets the transform of the 1 of the 6 slot areas
func get_slot_position(slot_index: int) -> Vector3:
	match slot_index:
		1:
			return slot1.global_position
		2:
			return slot2.global_position
		3:
			return slot3.global_position
		4:
			return slot4.global_position
		5:
			return slot5.global_position
		6:
			return slot6.global_position
	return slot1.global_position

# despawns the world item associated with a slot
func despawn_slot_world_item(slot_index: int) -> void:
	if not slots.has(slot_index):
		return

	var world_item: WorldItem = slots[slot_index]["world_item_instance"] # get the world item instance
	if world_item and is_instance_valid(world_item): # if the instance is valid, clear it
		world_item.queue_free()
	slots[slot_index]["world_item_instance"] = null # set as null

# spawns the world item associated with a slot.
func spawn_world_item_for_slot(slot_index: int, item_data: ItemData, pickup_allowed: bool, connect_depleted: bool) -> void:
	# is the item valid
	if item_data == null:
		push_error("Cannot spawn griddle world item: item_data is null for slot " + str(slot_index))
		return

	var world_model_path = item_data.WorldModelPath
	# is the world model path valid?
	if world_model_path == null or world_model_path == "":
		push_error("Cannot spawn griddle world item: missing WorldModelPath for slot " + str(slot_index))
		return

	var world_item_scene = ResourceLoader.load(world_model_path) as PackedScene
	# did the scene load OK?
	if world_item_scene == null:
		push_error("Failed to load world item scene for slot " + str(slot_index))
		return

	var world_item = world_item_scene.instantiate() as WorldItem
	# did the scene root instantiate and is it a WorldItem?
	if world_item == null:
		push_error("Griddle slot scene root is not a WorldItem for slot " + str(slot_index))
		return

	var scene_root = get_tree().get_current_scene()
	# is the scene root valid?
	if scene_root == null:
		push_error("current scene is null")
		return

	# add the world item to the scene, set its data and position it at the corresponding slot
	scene_root.add_child(world_item)
	world_item.Data = item_data
	world_item.Quantity = 1
	world_item.PickupAllowed = pickup_allowed
	world_item.global_position = get_slot_position(slot_index)

	var slot = slots[slot_index]
	slot["world_item"] = world_model_path
	slot["world_item_instance"] = world_item

	# hook the depleted signal if this item can be picked up, so that when the player picks it up we can clear the slot and update the UI.
	if connect_depleted:
		world_item.depleted.connect(_on_slot_world_item_depleted.bind(slot_index))

# clear the slot and update the UI when a world item is depleted (picked up by the player)
func _on_slot_world_item_depleted(world_item: WorldItem, slot_index: int) -> void:
	if not slots.has(slot_index):
		return

	var slot = slots[slot_index]
	if slot["world_item_instance"] != world_item:
		return
	#reset the slot to empty
	slot["item"] = null
	slot["timer"] = 0.0
	slot["status"] = SlotStatus.EMPTY
	slot["world_item"] = null
	slot["world_item_instance"] = null

func _process(delta: float) -> void:
	for i in range(1, num_slots+1): # go over each slot
		var slot = slots[i]
		update_floating_ui_for_slot(i) # update the floating UI for this slot based on its status
		if slot["status"] == SlotStatus.COOKING: # is the slot cooking an item?
			if slot["item"] == null: # is the item null ?
				slot["status"] = SlotStatus.EMPTY # if so, reset the slot to empty and continue
				despawn_slot_world_item(i) # despawn any world item that might still be there just in case
				continue

			slot["timer"] += delta # iterate the cooking timer
			if slot["timer"] >= slot["item"].time_to_cook: # has the item finished cooking?
				despawn_slot_world_item(i) # despawn the raw item world model if it is still there
				var cooked_item: ItemData = slot["item"].cook_result # get the cooked item data from the raw item data
				if cooked_item == null: # if there is no cook result, push an error and reset the slot to empty
					push_error("Cook result is missing for slot " + str(i))
					slot["item"] = null
					slot["timer"] = 0.0
					slot["status"] = SlotStatus.EMPTY
					slot["world_item"] = null
					continue

				slot["status"] = SlotStatus.READY # slot is ready
				slot["item"] = cooked_item # update the slot item to the cooked item
				slot["timer"] = 0.0
				spawn_world_item_for_slot(i, cooked_item, true, true) # spawn the cooked item as a world item that can be picked up
				audio_player.play() # play the cooking sound
