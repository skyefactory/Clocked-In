extends RigidBody3D

@onready var player = get_node("/root/Main/Player")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_collision_exception_with(player) # prevents this rigidbody from colliding with the player, allowing the player to pass through it without physics interference.