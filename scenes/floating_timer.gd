extends CanvasLayer
class_name FloatingTimer
@onready var target = get_parent()
@export var player_camera: Camera3D
@onready var progress_bar = $Progress


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not target or not player_camera:
		return
	
	var world_pos = target.global_transform.origin
	var screen_pos = player_camera.unproject_position(world_pos)
	if player_camera.is_position_behind(world_pos):
		progress_bar.hide()
	else:
		progress_bar.show()
	progress_bar.position = screen_pos

