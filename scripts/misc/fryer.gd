extends StaticBody3D
class_name Fryer

@export var player: Player
@onready var slot_cooking: Node3D = $SlotCooking
@onready var slot_ready: Node3D = $SlotReady
@onready var ui = $FloatingTimer
@onready var mesh_cooking: Node3D = $FRYER_basket_in
@onready var mesh_ready: Node3D = $FRYER

var slot = null

enum Status{
	COOKING, #slot has an item, and it is actively cooking
	READY, #slot has an item, but it is done cooking and waiting for the player to take it
	EMPTY, #slot is empty and can be used for cooking an item
}
var status = Status.EMPTY
var timer = 0.0
var item: ItemData = null

var slot_world_item_path: String = ""
var slot_world_item_instance: WorldItem = null

func is_held_item_fryable() -> bool:
	return player.inventory.held_item and player.inventory.held_item.item and player.inventory.held_item.item.isFryable()

func _ready() -> void:
	ui.hide()

func can_interact(_interacting_player: Player) -> bool:
	# Allow interaction when loading raw food, and when cooked food is ready to collect.
	return (status == Status.EMPTY and is_held_item_fryable()) or status == Status.READY

func get_interaction_text(_interacting_player: Player) -> String:
	if status == Status.EMPTY and is_held_item_fryable():
		return "Press E to fry " + player.inventory.held_item.item.Name
	if status == Status.READY and item:
		return "Press E to take " + item.Name
	
	return ""

func despawn_world_item() -> void:
	if slot_world_item_instance and is_instance_valid(slot_world_item_instance):
		slot_world_item_instance.queue_free()
		slot_world_item_instance = null

func spawn_world_item(item_data: ItemData, pickup_allowed: bool, connect_depleted: bool) -> void:
		# is the item valid
	if item_data == null:
		push_error("Cannot spawn fryer world item: item_data is null")
		return

	var world_model_path = item_data.WorldModelPath
	# is the world model path valid?
	if world_model_path == null or world_model_path == "":
		push_error("Cannot spawn fryer world item: missing WorldModelPath")
		return

	var world_item_scene = ResourceLoader.load(world_model_path) as PackedScene
	# did the scene load OK?
	if world_item_scene == null:
		push_error("Failed to load world model scene at path: " + world_model_path)
		return

	var world_item = world_item_scene.instantiate() as WorldItem
	# did the scene root instantiate and is it a WorldItem?
	if world_item == null:
		push_error("Fryer slot scene root is not a WorldItem")
		return

	var scene_root = get_tree().get_current_scene()
	# is the scene root valid?
	if scene_root == null:
		push_error("current scene is null")
		return

	scene_root.add_child(world_item)
	world_item.Data = item_data
	world_item.Quantity = 1
	world_item.PickupAllowed = pickup_allowed
	world_item.global_position = slot.global_position

	slot_world_item_path = world_model_path
	slot_world_item_instance = world_item

	if connect_depleted:
		world_item.depleted.connect(on_world_item_depleted)

func on_world_item_depleted(_world_item: WorldItem) -> void:
	status = Status.EMPTY
	timer = 0.0
	item = null
	slot_world_item_path = ""
	slot_world_item_instance = null

func interact(_interacting_player: Player) -> void:
	if can_interact(_interacting_player):
		if status == Status.EMPTY:
			var held_item = player.inventory.held_item.item
			item = held_item
			status = Status.COOKING
			timer = 0.0
			slot_world_item_path = held_item.WorldModelPath
			slot = slot_cooking
			mesh_cooking.show()
			mesh_ready.hide()
			despawn_world_item() # despawn any existing world item just in case
			spawn_world_item(held_item, false, false) # spawn the raw item as a world item that cannot be picked up
			player.inventory.take_item(held_item, 1) # take the item from the player's inventory
		elif status == Status.READY and slot_world_item_instance and is_instance_valid(slot_world_item_instance):
			slot_world_item_instance.interact(_interacting_player)

func update_ui() -> void:
	match status:
		Status.COOKING:
			ui.progress_bar.value = timer / item.time_to_fry * 100.0
			ui.show()
		Status.READY:
			ui.hide()
		Status.EMPTY:
			ui.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if status == Status.COOKING:
		slot = slot_cooking
		mesh_cooking.show()
		mesh_ready.hide()
		if item == null:
			status = Status.EMPTY
			despawn_world_item()
		
		timer += delta
		if timer >= item.time_to_fry:
			status = Status.READY
			slot = slot_ready
			mesh_cooking.hide()
			mesh_ready.show()
			despawn_world_item()
			var cooked_item: ItemData = item.fry_result
			if cooked_item == null:
				push_error("Fry result is missing for item: " + item.Name)
				status = Status.EMPTY
				item = null
				timer = 0.0
				slot_world_item_path = ""
				return
			status = Status.READY
			item = cooked_item
			timer = 0.0
			spawn_world_item(cooked_item, true, true) # spawn the cooked item as a world item that can be picked up
	else:
		slot = slot_ready
		mesh_cooking.hide()
		mesh_ready.show()
	
	update_ui()

	pass
