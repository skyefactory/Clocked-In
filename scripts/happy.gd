extends StaticBody3D

@export var target_pos: Vector3
@export var ret: bool
func can_interact(_interacting_player: Player) -> bool:
	return true

func get_interaction_text(_interacting_player: Player) -> String:
	if !ret:
		return "quit your job"
	else:
		return "fill out job application"

func interact(_interacting_player: Player) -> void:
	_interacting_player.global_transform.origin = target_pos
	
