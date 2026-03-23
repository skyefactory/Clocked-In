extends Control

@onready var cost_label = $Button/CostLabel
@onready var item_name_label = $Button/ItemNameLabel
@onready var button = $Button
@onready var shop_controller = get_parent().get_parent() as Control # the UpgradesShop node, used to call the unlock_content function after purchase
@export var content_id: String = "" # the content id of the item or recipe this shop entry represents
@export var display_name: String = "" # the name of the item or recipe to display in the shop entry
@export var content_type: String = "" # the type of content this entry represents, used for filtering in the shop. Should be "station" or "recipe".

var cost = 0

func _ready() -> void:
	cost = Gamestate.get_cash_cost(content_id)
	item_name_label.text = display_name + " " + content_type.capitalize()

	if cost > Gamestate.cash:
		button.disabled = true
		cost_label.text = "[color=red]$%d[/color]" % cost
	else:
		button.disabled = false
		cost_label.text = "[color=green]$%d[/color]" % cost
	
	button.pressed.connect(shop_controller.unlock_content.bind(content_id))

