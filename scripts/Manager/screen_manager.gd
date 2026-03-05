extends Node3D
class_name ScreenManager

@onready var viewport: SubViewport = $SubViewport
@onready var order_container: GridContainer = $SubViewport/GridContainer
@onready var screen_quad: MeshInstance3D = $Quad
@onready var screen_area: Area3D = $Quad/Area3D
const OrderUIScene: PackedScene = preload("res://scenes/OrderOnScreenUI.tscn")

var is_hovering: bool = false
var last_event_pos2D: Vector2 = Vector2.ZERO
var last_event_time: float = -1.0

func update_screen(pending_orders: Array[Order]) -> void:
	#Check if order is already on the screen.
	var displayed_order_ids = []
	for child in order_container.get_children():
		var idNode = child.get_child(4)
		if idNode:
			var found = false
			for o in pending_orders:
				if idNode.name == str(o.id):
					found = true
					#update the order if needed
					var ui = child
					var recipeNameLabel: RichTextLabel = ui.get_child(2)
					var ingredientsLabel: RichTextLabel = ui.get_child(3)
					recipeNameLabel.text = o.recipe.result.Name
					var ingredientsText = ""
					for ingredient in o.recipe.ingredients:
						ingredientsText += "- " + ingredient.Name + "\n"
					ingredientsLabel.text = ingredientsText
					if o.status == Order.OrderStatus.ACTIVE:
						var colorRect: ColorRect = ui.get_child(1)
						colorRect.color = Color(0.0, 155, 0.0, 1.0)
					else:
						var colorRect: ColorRect = ui.get_child(1)
						colorRect.color = Color(255, 0.0, 0.0, 1.0)
					displayed_order_ids.append(o.id)
					break
			#if the order is not in the pending orders, remove it from the screen.
			if not found:
				child.queue_free()
	for o in pending_orders:
		if not displayed_order_ids.has(o.id):
			var ui = OrderUIScene.instantiate()
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

func handle_ray_result(result: Dictionary) -> void:
	if result and result.collider == screen_area:
		is_hovering = true
		process_hit_position(result.position)
	else:
		is_hovering = false


func process_hit_position(hit_position: Vector3) -> void:
	var quad_mesh_size = screen_quad.mesh.size
	var local_pos = screen_quad.global_transform.affine_inverse() * hit_position

	var pos2D = Vector2(local_pos.x, -local_pos.y)

	pos2D.x = (pos2D.x / quad_mesh_size.x) + 0.5
	pos2D.y = (pos2D.y / quad_mesh_size.y) + 0.5

	pos2D.x *= viewport.size.x
	pos2D.y *= viewport.size.y
	pos2D = pos2D.clamp(Vector2.ZERO, Vector2(viewport.size) - Vector2.ONE)

	var now = Time.get_ticks_msec() / 1000.0

	var motion_event := InputEventMouseMotion.new()
	motion_event.position = pos2D
	motion_event.global_position = pos2D

	if last_event_time > 0.0:
		motion_event.relative = pos2D - last_event_pos2D
		motion_event.velocity = motion_event.relative / (now - last_event_time)
	else:
		motion_event.relative = Vector2.ZERO
		motion_event.velocity = Vector2.ZERO

	viewport.push_input(motion_event, true)

	last_event_pos2D = pos2D
	last_event_time = now


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
