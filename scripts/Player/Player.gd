extends CharacterBody3D
class_name Player
@onready var inventory: Inventory = $Inventory
@export var screen_manager: ScreenManager
@onready var camera: Camera3D = $Camera # reference to player camera

# Main movement code was adapted from https://github.com/rbarongr/GodotFirstPersonController/tree/main


@export_range(1, 35, 1) var speed: float = 10 # m/s. move speed
@export_range(10, 400, 1) var acceleration: float = 100 # m/s^2. acceleration speed

@export_range(0.1, 3.0, 0.1) var jump_height: float = 1 # m , jump height
@export_range(0.1, 3.0, 0.1, "or_greater") var camera_sens: float = 1 # mouse sensitivity

var jumping: bool = false # is jumping
var mouse_captured: bool = false # is mouse captured

# gravity value, pulled from project settings
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") 

var move_dir: Vector2 # Input direction for movement
var look_dir: Vector2 # Input direction for look/aim

var walk_vel: Vector3 # Walking velocity 
var grav_vel: Vector3 # Gravity velocity 
var jump_vel: Vector3 # Jumping velocity

var forward: Vector3 # forward direction for dropping items and moving

var current_interactable: Node # currently active interactable target.

signal interact_target(show_label, text)

func _ready() -> void: # capture the mouse
	capture_mouse()

func raycast_from_crosshair() ->PhysicsRayQueryParameters3D:

	var active_viewport := camera.get_viewport()
	var screen_center := active_viewport.get_visible_rect().get_center()
	
	#send out a ray from the center of the screen relative to where the camera is
	var ray_origin = camera.project_ray_origin(screen_center)
	var ray_direction = camera.project_ray_normal(screen_center)
	# set up the ray query parameters
	var query = PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_origin + ray_direction * 1000.0
	)
	return query


func screen_raycast_from_crosshair() -> void:
	var query = raycast_from_crosshair() # set up the ray query parameters for a raycast from the center of the screen

	query.collide_with_areas = true # we want to only detect areas, as world items are areas and we don't want physics interference from rigidbodies getting in the way of ray detection.
	query.collide_with_bodies = false # ignore physics bodies, we will add a collision exception to all physics bodies for the player to prevent interference with ray detection.
	query.collision_mask = 2
	#check what the ray intersected with.

	var result = get_world_3d().direct_space_state.intersect_ray(query) # perform the raycast and get the result

	screen_manager.handle_ray_result(result) # forward the raycast result to the screen manager so that it can determine if we are hovering over the screen and where the hit position is for UI interaction.

func _input(event):
	if event is InputEventMouseButton:
		# Refresh the hit position in the same input tick as the click.
		screen_raycast_from_crosshair()
		screen_manager.forward_mouse_button(event)
	
	#check to see if we have a current interactable and if the interact button was pressed
	if event.is_action_pressed("interact") and current_interactable and is_instance_valid(current_interactable):
		Interactable.interact(current_interactable, self)

# handle mouse look input
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		look_dir = event.relative * 0.001
		if mouse_captured: 
			_rotate_camera()

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("release_mouse"): # toggle mouse capture on and off
		if mouse_captured: release_mouse()
		else: capture_mouse()
	# check for jump input
	if Input.is_action_just_pressed("jump"): jumping = true  
	# check for drop item input
	if Input.is_action_just_pressed("drop_item"): drop_item()

	# calculate final velocity vector and move the player
	velocity = _walk(delta) + _gravity(delta) + _jump(delta)
	#screen_raycast_from_crosshair()
	
	# Check for interactable in view
	var interact_result = interactable_in_view()
	if interact_result:
		set_interactable(interact_result)
	elif current_interactable: # if there is no interactable in view but we have a current interactable, clear it.
		clear_interactable(current_interactable)
	move_and_slide()

# drops the currently held item into the world as a pickup. 
# The item is removed from the inventory and an instance of the item's WorldModel 
# is created in the world at the player's position.
func drop_item():
	# remove the currently held item
	var slot = inventory.remove_selected_item()
	if slot == null:
		return

	# instantiate the WorldItem scene
	var path = slot.item.WorldModelPath
	var world_item_scene = ResourceLoader.load(path) as PackedScene
	if world_item_scene == null:
		push_error("Failed to load world model scene at path: " + path)
		return
	var world_item = world_item_scene.instantiate() as WorldItem
	if world_item == null:
		push_error("Dropped scene root is not a WorldItem!")
		return

	# get the scene root
	var scene_root = get_tree().get_current_scene()
	if scene_root == null:
		push_error("Cannot drop item: current scene is null")
		return

	# add the world item to the scene
	scene_root.add_child(world_item)

	# assign data and quantity
	world_item.Data = slot.item
	world_item.Quantity = slot.quantity

	# place in front of the player
	world_item.global_position = global_position + forward * 2.00

#checks to see if it is colliding with a collider on layer 3 to determine if we are looking at an item we can interact with.
func interactable_in_view(max_distance: float = 4.0) -> Node:
	var query = raycast_from_crosshair() # set up the ray query parameters for a raycast from the center of the screen
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.collision_mask = 4 # only collide with layer 3

	var result = get_world_3d().direct_space_state.intersect_ray(query) # perform the raycast and get the result

	if result and result.collider:
		var hit_distance = camera.global_position.distance_to(result.position)
		if hit_distance <= max_distance: #debugging
			return result.collider
	return null



# capture mouse
func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true
#release mouse
func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false
# rotate the camera based on mouse input
func _rotate_camera(sens_mod: float = 1.0) -> void:
	camera.rotation.y -= look_dir.x * camera_sens * sens_mod
	camera.rotation.x = clamp(camera.rotation.x - look_dir.y * camera_sens * sens_mod, -1.5, 1.5)

#calculate movement velocity
func _walk(delta: float) -> Vector3:
	move_dir = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_backwards")
	forward = camera.global_transform.basis * Vector3(move_dir.x, 0, move_dir.y)
	var walk_dir: Vector3 = Vector3(forward.x, 0, forward.z).normalized()
	walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), acceleration * delta)
	return walk_vel

# calculate gravity velocity
func _gravity(delta: float) -> Vector3:
	grav_vel = Vector3.ZERO if is_on_floor() else grav_vel.move_toward(Vector3(0, velocity.y - gravity, 0), gravity * delta)
	return grav_vel
# calculate jump velocity
func _jump(delta: float) -> Vector3:
	if jumping:
		if is_on_floor(): jump_vel = Vector3(0, sqrt(4 * jump_height * gravity), 0)
		jumping = false
		return jump_vel
	jump_vel = Vector3.ZERO if is_on_floor() or is_on_ceiling_only() else jump_vel.move_toward(Vector3.ZERO, gravity * delta)
	return jump_vel

func set_interactable(target: Node) -> void:
	if not is_instance_valid(target):
		return
	
	if not Interactable.can_interact(target, self):
		clear_interactable(target)
		return
	if current_interactable != target:
		current_interactable = target
		emit_signal("interact_target", true, Interactable.interaction_text(target, self))

func clear_interactable(target: Node) -> void:
	# Clear if it matches, or if current is invalid
	if current_interactable == target or (current_interactable and not is_instance_valid(current_interactable)):
		current_interactable = null
		emit_signal("interact_target", false, "")
