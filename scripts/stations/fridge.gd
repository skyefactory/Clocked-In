extends Moveable

var opened = false
@onready var animator: AnimationPlayer = get_parent().get_parent().get_node("AnimationPlayer")
@export var audio_player: AudioStreamPlayer3D
@export var fridge_open_sfx: AudioStream
@export var fridge_close_sfx: AudioStream
@export var fridge_idle_sfx: AudioStream


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
			audio_player.stream = fridge_close_sfx
			audio_player.play()
		else:
			animator.play("open") # if closed, we open it
			opened = true
			audio_player.stream = fridge_open_sfx
			audio_player.play()
			# wait for the open sound to finish before playing the idle sound
			await audio_player.finished
			if opened: # check if the fridge is still open before playing the idle sound
				audio_player.stream = fridge_idle_sfx
				audio_player.play()

			
