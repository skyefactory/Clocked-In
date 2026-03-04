extends Node
class_name StateManager

var is_paused: bool = false

signal paused

func _process(_delta: float) -> void:
    check_for_input()

func check_for_input() -> void:
    if Input.is_action_just_released("pause"):
        toggle_pause()
    return

func toggle_pause():
    is_paused = not is_paused
    if is_paused: Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    else: Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    paused.emit(is_paused)

func quit():
    get_tree().quit()
