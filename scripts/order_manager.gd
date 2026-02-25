extends Node

@onready var OrderPanel = $"../GUIPanel3D/SubViewport/GridContainer"
const OrderUIScene: PackedScene = preload("res://scenes/OrderOnScreenUI.tscn")
var rng = RandomNumberGenerator.new()

# List of all current orders in the game
var orders: Array[Order] = []

# First entry is the "base" recipe, second entry is the "variants"
var Recipies = [
	["Burger", ["Cheese", "Double", "Lettuce", "Silly Sauce"]]
]

var day_started = false
var day_ended = false

# Keep track of the current active order
var active_order_id: int = -1

var accum = 0.0
var timer = 0

func pick_random_time() -> int:
	return rng.randi_range(20,40)

func _process(delta: float) -> void:
	if day_started:
		if timer == 0:
			timer = pick_random_time()
		accum += delta
		if(accum >= timer):
			createOrder()
			accum = 0.0
			timer = pick_random_time()
	

# ------------------------
# ORDER MANAGEMENT
# ------------------------

# Creates a new order and adds it to the orders list
func createOrder() -> Order:
	# Pick a recipe randomly
	var recipe = Recipies[randi() % Recipies.size()]
	
	# Pick random variations
	var num_variations = randi() % recipe[1].size() + 1
	var selected_variations: Array = []
	#Go through and add variations to the selected varionts.
	while selected_variations.size() < num_variations:
		#Make sure that no duplicate variations show up.
		var variation = recipe[1][randi() % recipe[1].size()]
		if variation not in selected_variations:
			selected_variations.append(variation)
	var orderUIInstance = OrderUIScene.instantiate()
	# Get UI labels
	var baseLabel: RichTextLabel = orderUIInstance.get_child(2)
	var variationLabel: RichTextLabel = orderUIInstance.get_child(3)
	var uiIDStorage: Node = orderUIInstance.get_child(4)
	
	uiIDStorage.name = str(orders.size())
	baseLabel.text = recipe[0]
	variationLabel.text = ""
	#Go over each variation and append it to the variation label
	for j in range(selected_variations.size()):
		variationLabel.text += str(selected_variations[j])
		# add a comma if its not the last item.
		if j < selected_variations.size() - 1:
			variationLabel.text += ", "
	# Create Order object
	OrderPanel.add_child(orderUIInstance)
	var order = Order.new(orders.size(), recipe[0], selected_variations, orderUIInstance)
	orders.append(order)
	return order

# Sets an order as active
func setActiveOrder(order_id: int) -> void:
	#Set the indicated ID as active, and clear any other previous active order
	for order in orders:
		if order.id == order_id:
			order.status = "active"
			active_order_id = order_id
		elif order.status == "active":
			order.orderui.get_child(0).button_pressed = false
			order.status = "pending"

# Marks an order as complete
func completeOrder(order_id: int) -> void:
	for order in orders:
		if order.id == order_id:
			order.status = "completed"
			if active_order_id == order_id:
				active_order_id = -1

# Returns the currently active order
func getActiveOrder() -> Order:
	for order in orders:
		if order.status == "active":
			return order
	return null

func setOrderAsLate(order_id: int) -> void:
	for order in orders:
		if order.id == order_id:
			order.islate = true

# ------------------------
# UI / DEBUG
# ------------------------
func print_orders() -> void:
	print("---- Orders ----")
	for order in orders:
		print("ID:", order.id, "Status:", order.status, "Base:", order.base, "Variations:", order.variations)
	print("----------------")


func _on_day_end() -> void:
	day_ended = true
	pass # Replace with function body.

func _on_day_start() -> void:
	day_started = true
	createOrder() #initial first order
	pass # Replace with function body.
