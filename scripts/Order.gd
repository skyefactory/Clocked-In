extends RefCounted

#This is a custom class to hold Order information.
class_name Order

#Base recipie (Burger, etc)
var base: String
#Additions to the recipie
var variations: Array = []
#ID of this order
var id: int
#Status of the order, can be pending, active, or completed
var status: String = "pending"
var orderui: Control
var islate: bool = false

#Initialize the fields
func _init(_id: int, _base: String, _variations: Array, _orderui: Control):
	id = _id
	base = _base
	variations = _variations
	orderui = _orderui
