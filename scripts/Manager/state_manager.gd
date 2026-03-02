extends Node
class_name StateManager

var is_paused: bool = false

signal paused

func _process(_delta: float) -> void:
    check_pause_input()

func check_pause_input() -> void:
    if Input.is_action_pressed("pause"):
        is_paused = not is_paused
        paused.emit(is_paused)
    return

func toggle_pause():
    is_paused = not is_paused
    paused.emit(is_paused)

func quit():
    get_tree().quit()
