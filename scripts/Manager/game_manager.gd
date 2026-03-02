extends Node
class_name GameManager

@export var order_dropoff_area: Area3D

var active_orders: Array[Order] = []
var max_active_orders: int = 5
var completed_orders: Array[Order] = []


signal interaction_signal # emitted when the player moves in range of something interactable. Used to send signals to the UI to show interaction prompts.

func _ready() -> void:
    order_dropoff_area.body_entered.connect(on_order_dropoff_body_entered)
    order_dropoff_area.body_exited.connect(on_order_dropoff_body_exited)

func on_order_dropoff_body_entered(body: Node) -> void:
    if body.is_in_group("Player"):
        interaction_signal.emit(true, "Press E to drop off order")

func on_order_dropoff_body_exited(body: Node) -> void:
    if body.is_in_group("Player"):
        interaction_signal.emit(false)