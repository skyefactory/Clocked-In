extends Button
@onready var rect: ColorRect = $"../ColorRect"
var ID: Node

var gameManager: GameManager

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# set the order manager reference
	gameManager = get_node("/root/Main/Managers/GameManager")
	ID = get_parent().get_child(4)


func _on_toggled(toggled_on: bool) -> void:
	
	if(!toggled_on): 
		gameManager.set_order_as_pending(int(ID.name))
		#rect.color = Color(255, 0.0, 0.0, 1.0)
	else: 
		gameManager.set_active_order(int(ID.name))

func _on_timer_finished() -> void:
	gameManager.mark_order_as_late(null, int(ID.name))
