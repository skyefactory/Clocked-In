extends Node3D
# This code is based on https://godotengine.org/asset-library/asset/2807

var is_hovering: bool = false
# The last processed input touch/mouse event. To calculate relative movement.
var last_event_pos2D = null
# The time of the last event in seconds since engine start.
var last_event_time: float = -1.0

#node references for the screen
@onready var node_viewport = $SubViewport #The viewport rendered on the 'screen'
@onready var node_quad = $Quad #the actual screen object
@onready var node_area = $Quad/Area3D #collision detection
@export var player: Node3D #reference to the player

func _physics_process(delta: float) -> void:
	_raycast_from_crosshair()
	
func _raycast_from_crosshair():
	#get the camera
	var camera := get_viewport().get_camera_3d()
	
	if camera == null:
		return
	#get the exact center of the screen, this is where the crosshair is
	var viewport_size = get_viewport().size
	var screen_center = viewport_size / 2
	
	#send out a ray from the center of the screen relative to where the camera is
	var ray_origin = camera.project_ray_origin(screen_center)
	var ray_direction = camera.project_ray_normal(screen_center)

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_origin + ray_direction * 1000.0
	)

	query.collide_with_areas = true
	query.collide_with_bodies = false
	#check what the ray intersected with.
	var result = space_state.intersect_ray(query)

	#check if the result has a collider, if so, does the collider match our screen collider?
	if result and result.collider == node_area:
		#Yes , it is our screen, process the collision
		is_hovering = true
		_process_hit_position(result.position)
	else:
		is_hovering = false	

func _process_hit_position(hit_position: Vector3):
	var quad_mesh_size = node_quad.mesh.size

	# turns the hit of the screen to coordinates that are local to the screen. This gives us x,y on the screen rather then world coords
	var local_pos = node_quad.global_transform.affine_inverse() * hit_position

	# Convert 3D → 2D
	var pos2D = Vector2(local_pos.x, -local_pos.y)

	# Normalize in terms of 0 to 1
	pos2D.x = (pos2D.x / quad_mesh_size.x) + 0.5
	pos2D.y = (pos2D.y / quad_mesh_size.y) + 0.5

	# Convert → viewport space - The viewport is a 2d space we are projecting on the quad/screen
	pos2D.x *= node_viewport.size.x
	pos2D.y *= node_viewport.size.y

	var now = Time.get_ticks_msec() / 1000.0

	# Create mouse motion event
	var motion_event := InputEventMouseMotion.new()
	motion_event.position = pos2D
	motion_event.global_position = pos2D

	if last_event_time > 0.0:
		motion_event.relative = pos2D - last_event_pos2D
		motion_event.velocity = motion_event.relative / (now - last_event_time)
	else:
		motion_event.relative = Vector2.ZERO
		motion_event.velocity = Vector2.ZERO

	node_viewport.push_input(motion_event)

	last_event_pos2D = pos2D
	last_event_time = now


func _input(event):
	if not is_hovering:
		return

	if event is InputEventMouseButton:
		var button_event := InputEventMouseButton.new()
		button_event.button_index = event.button_index
		button_event.pressed = event.pressed
		button_event.position = last_event_pos2D
		button_event.global_position = last_event_pos2D

		node_viewport.push_input(button_event)
