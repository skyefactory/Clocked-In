extends CharacterBody3D
class_name Player
@onready var inventory: Inventory = $Inventory
@export var screen_manager: ScreenManager
@export var test_icon: Texture2D
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

var current_world_item: WorldItem

func _ready() -> void: # capture the mouse
	capture_mouse()

func raycast_from_crosshair() -> void:
	#get the exact center of the screen, this is where the crosshair is
	var viewport_size = get_viewport().size
	var screen_center = viewport_size / 2
	
	#send out a ray from the center of the screen relative to where the camera is
	var ray_origin = camera.project_ray_origin(screen_center)
	var ray_direction = camera.project_ray_normal(screen_center)

	var query = PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_origin + ray_direction * 1000.0
	)

	query.collide_with_areas = true
	query.collide_with_bodies = true
	#check what the ray intersected with.

	var result = get_world_3d().direct_space_state.intersect_ray(query)

	screen_manager.handle_ray_result(result)

func _input(event):
	if event is InputEventMouseButton:
		screen_manager.forward_mouse_button(event)

# handle mouse look input
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		look_dir = event.relative * 0.001
		if mouse_captured: _rotate_camera()

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
	raycast_from_crosshair()
	move_and_slide()

# drops the currently held item into the world as a pickup. 
# The item is removed from the inventory and an instance of the item's WorldModel 
# is created in the world at the player's position.
func drop_item():
	# get the currently held item from the inventory and remove it from the inventory
	var slot = inventory.remove_selected_item() 
	if slot == null: # if the return is null, do nothing (this should not happen)
		return
	
	# create an instance of the item's WorldModel and add it to the world
	var world_scene = slot.item.WorldModel
	var world_item = world_scene.instantiate()
	get_tree().current_scene.add_child(world_item)

	# set the data and quantity of the world item to match the item that was in the inventory
	world_item.Data = slot.item
	world_item.Quantity = slot.quantity
	# set the position of the world item to be in front of the player
	world_item.global_position = global_position + forward * 2.0

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
