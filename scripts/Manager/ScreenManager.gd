extends Node3D
class_name ScreenManager

@onready var viewport: SubViewport = $SubViewport # reference to the subviewport projected on the quad
@onready var order_container: GridContainer = $SubViewport/GridContainer # reference to the container in the subviewport where order UIs will be added
@onready var screen_quad: MeshInstance3D = $Quad # reference to the quad mesh where the subviewport is projected
@onready var screen_area: Area3D = $Quad/Area3D # reference to the area on the quad used for raycasting to detect mouse hover and clicks
const OrderUIScene: PackedScene = preload("res://scenes/prefabs/OrderOnScreenUI.tscn") # prefab scene for the order UI elements that will be added to the screen

# mouse hovering variables
var is_hovering: bool = false
var last_event_pos2D: Vector2 = Vector2.ZERO
var last_event_time: float = -1.0

# updates the order UIs on the screen based on the current pending orders. 
# It adds new UIs for new orders, updates existing UIs for existing orders, and removes UIs for orders that are no longer pending.
func update_screen(pending_orders: Array[Order]) -> void:
	#Check if order is already on the screen.
	var displayed_order_ids = []
	for child in order_container.get_children():
		var idNode = child.get_child(4) # this would find every order that is already on the screen.
		if idNode:
			var found = false
			for o in pending_orders: # match the order UI to the order instance. 
				if o == null:
					continue
				if idNode.name == str(o.id):
					found = true
					#update the order with the latest info from the order instance.
					var ui = child
					var recipeNameLabel: RichTextLabel = ui.get_child(2)
					var ingredientsLabel: RichTextLabel = ui.get_child(3)
					recipeNameLabel.text = o.recipe.result.Name
					var ingredientsText = ""
					for ingredient in o.recipe.ingredients:
						ingredientsText += "- " + ingredient.Name + "\n"
					ingredientsLabel.text = ingredientsText

					#update color based on order status
					if o.status == Order.OrderStatus.ACTIVE:
						var colorRect: ColorRect = ui.get_child(1)
						colorRect.color = Color(0.0, 155, 0.0, 1.0)
					else:
						var colorRect: ColorRect = ui.get_child(1)
						colorRect.color = Color(255, 0.0, 0.0, 1.0)
					displayed_order_ids.append(o.id)
					break
			#if the order is not in our pending orders list but is on the screen, this would suggest it has been completed or removed, so we can remove it from the screen.
			if not found:
				child.queue_free()
	
	# go over each order, check if it was found on the screen, if not, create it.
	for o in pending_orders:
		if o == null:
			continue
		if not displayed_order_ids.has(o.id): # not found on screen, need to add it.
			var ui = OrderUIScene.instantiate() # create new order UI scene and initialize it.
			var recipeNameLabel: RichTextLabel = ui.get_child(2)
			var ingredientsLabel: RichTextLabel = ui.get_child(3)
			var uiIDStorage: Node = ui.get_child(4)
			uiIDStorage.name = str(o.id)
			recipeNameLabel.text = o.recipe.result.Name
			var ingredientsText = ""
			for ingredient in o.recipe.ingredients:
				ingredientsText += "- " + ingredient.Name + "\n"
			ingredientsLabel.text = ingredientsText
			ui.name = "Order" + str(o.id)
			order_container.add_child(ui)

# handle the raycast from the player.
func handle_ray_result(result: Dictionary) -> void:
	#if there is a result, and the result hit the screen area.
	if result and result.collider == screen_area:
		# process the hit position to determine where on the screen the mouse is.
		is_hovering = true
		process_hit_position(result.position)
	else:
		is_hovering = false

# determine where on the screen the mouse interacted with.
func process_hit_position(hit_position: Vector3) -> void:
	var quad_mesh_size = screen_quad.mesh.size # size of quad
	var local_pos = screen_quad.global_transform.affine_inverse() * hit_position # convert the hit position to local space of the quad

	var pos2D = Vector2(local_pos.x, -local_pos.y) # flip the y coordinate because of how the quad is oriented

	pos2D.x = (pos2D.x / quad_mesh_size.x) + 0.5 # convert from local space to 0 to 1
	pos2D.y = (pos2D.y / quad_mesh_size.y) + 0.5

	pos2D.x *= viewport.size.x # convert to viewport coordinates
	pos2D.y *= viewport.size.y # convert to viewport coordinates
	pos2D = pos2D.clamp(Vector2.ZERO, Vector2(viewport.size) - Vector2.ONE) # ensure the position is within the viewport bounds

	var now = Time.get_ticks_msec() / 1000.0 #hovering variables

	var motion_event := InputEventMouseMotion.new()
	motion_event.position = pos2D
	motion_event.global_position = pos2D

	if last_event_time > 0.0:
		motion_event.relative = pos2D - last_event_pos2D
		motion_event.velocity = motion_event.relative / (now - last_event_time)
	else:
		motion_event.relative = Vector2.ZERO
		motion_event.velocity = Vector2.ZERO

	#forward the event to the viewport so that it can be processed by the UI elements.
	viewport.push_input(motion_event, true)

	last_event_pos2D = pos2D
	last_event_time = now

# forward mouse button events to the viewport when hovering over the screen
func forward_mouse_button(event: InputEventMouseButton) -> void:
	if not is_hovering:
		return

	var button_event := InputEventMouseButton.new()
	button_event.button_index = event.button_index
	button_event.pressed = event.pressed
	button_event.button_mask = event.button_mask
	button_event.double_click = event.double_click
	button_event.factor = event.factor
	button_event.position = last_event_pos2D
	button_event.global_position = last_event_pos2D

	viewport.push_input(button_event, true)
