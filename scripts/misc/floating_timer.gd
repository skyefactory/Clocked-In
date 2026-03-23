extends CanvasLayer
class_name FloatingTimer
@onready var target = get_parent()
@export var player_camera: Camera3D
@onready var progress_bar = $Progress


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not target or not player_camera:
		return
	
	var world_pos = target.global_transform.origin # get the world position of the target node, which is the position of the node that this timer is associated with.
	var screen_pos = player_camera.unproject_position(world_pos) # convert the world position to screen space using the camera's unproject_position function, which gives us the position on the screen where we should draw the timer.
	if player_camera.is_position_behind(world_pos): # if the target position is behind the camera, we should hide the progress bar since it doesn't make sense to show it when the target is not visible.
		progress_bar.hide()
	else:
		progress_bar.show()
	progress_bar.position = screen_pos

