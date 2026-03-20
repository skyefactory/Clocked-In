extends StaticBody3D

var opened = false
@onready var animator: AnimationPlayer = get_parent().get_parent().get_node("AnimationPlayer")

func can_interact(_interacting_player: Player) -> bool:
	return animator != null # does the animation player exist.

func get_interaction_text(_interacting_player: Player) -> String:
	if opened:
		return "Press E to close fridge" # if open , we close it
	else:		
		return "Press E to open fridge" # if closed, we open it

func interact(_interacting_player: Player) -> void:
	if animator != null:
		if opened:
			animator.play_backwards("open") # if open , we close it
			opened = false
		else:
			animator.play("open") # if closed, we open it
			opened = true

			
