extends Area3D
class_name WorldItem


@export var Data: ItemData # The item data of this world item, this will be used to determine what item this is when the player interacts with it
@export var Quantity: int = 1 # The quantity of the item in this world item, this will be used to determine how many of the item the player picks up when they interact with it

var is_player_in_range: bool = false # whether the player is in range to pick up this item
var player: Player # reference to the player, used for adding the item to the player's inventory when they interact with it

signal show_interact_label(show: bool, text: String) # signal for showing the interact label

func _ready() -> void:
    body_entered.connect(_on_body_entered) # connect the body entered signal to the function that checks if the player is in range
    body_exited.connect(_on_body_exited) # connect the body exited signal to the function that checks if the player is no longer in range

func _on_body_entered(body: Node) -> void:
    if body is Player: # check if the body that entered is the player
        is_player_in_range = true
        player = body
        if Data:
            show_interact_label.emit(true, "Press E to pick up " + Data.Name) # show the interact label with the name of the item

func _on_body_exited(body: Node) -> void:
    if body is Player: # check if the body that exited is the player
        is_player_in_range = false
        player = null
        show_interact_label.emit(false, "") # hide the interact label