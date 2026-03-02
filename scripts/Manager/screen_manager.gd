extends Node3D
class_name ScreenManager

@onready var viewport: SubViewport = $SubViewport
@onready var screen_quad: MeshInstance3D = $Quad
@onready var screen_area: Area3D = $Quad/Area3D

var is_hovering: bool = false
var last_event_pos2D: Vector2 = Vector2.ZERO
var last_event_time: float = -1.0


func handle_ray_result(result: Dictionary) -> void:
    if result and result.collider == screen_area:
        is_hovering = true
        process_hit_position(result.position)
    else:
        is_hovering = false


func process_hit_position(hit_position: Vector3) -> void:
    var quad_mesh_size = screen_quad.mesh.size
    var local_pos = screen_quad.global_transform.affine_inverse() * hit_position

    var pos2D = Vector2(local_pos.x, -local_pos.y)

    pos2D.x = (pos2D.x / quad_mesh_size.x) + 0.5
    pos2D.y = (pos2D.y / quad_mesh_size.y) + 0.5

    pos2D.x *= viewport.size.x
    pos2D.y *= viewport.size.y

    var now = Time.get_ticks_msec() / 1000.0

    var motion_event := InputEventMouseMotion.new()
    motion_event.position = pos2D
    motion_event.global_position = pos2D

    if last_event_time > 0.0:
        motion_event.relative = pos2D - last_event_pos2D
        motion_event.velocity = motion_event.relative / (now - last_event_time)
    else:
        motion_event.relative = Vector2.ZERO
        motion_event.velocity = Vector2.ZERO

    viewport.push_input(motion_event)

    last_event_pos2D = pos2D
    last_event_time = now


func forward_mouse_button(event: InputEventMouseButton) -> void:
    if not is_hovering:
        return

    var button_event := InputEventMouseButton.new()
    button_event.button_index = event.button_index
    button_event.pressed = event.pressed
    button_event.position = last_event_pos2D
    button_event.global_position = last_event_pos2D

    viewport.push_input(button_event)