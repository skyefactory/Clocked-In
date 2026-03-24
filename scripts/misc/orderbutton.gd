extends Button
class_name OrderButton
@onready var rect: ColorRect = $"../ColorRect"
@onready var timer = $"../Timer"
var ID: Node
@onready var audio_player: AudioStreamPlayer = $"../AudioStreamPlayer"
var orderManager: OrderManager

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# set the order manager reference
	orderManager = get_node("/root/Restauraunt/Managers/OrderManager")
	ID = get_parent().get_child(4)
	timer.timer_finished.connect(_on_timer_finished)

func _on_toggled(toggled_on: bool) -> void:	
	if(!toggled_on): 
			orderManager.set_order_as_pending(int(ID.name))
			audio_player.play()
	else: 
			orderManager.set_active_order(int(ID.name))
			audio_player.play()

func _on_timer_finished() -> void:
		orderManager.mark_order_as_late(null, int(ID.name))
