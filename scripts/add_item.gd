extends Area3D

@export var inv: Inventory
@export var id: int;
@export var item_name : String;
@export var item_icon: Texture2D;
@export var max_qty : int;
@export var qty : int;
@export var world_scene: PackedScene
signal show_prompt(text: String)
signal hide_prompt()

var player_inside: bool = false

func get_key_name(action_name: String) -> String:
	# Ensure the action exists to prevent errors
	if not InputMap.has_action(action_name):
		return ""

	var events: Array = InputMap.action_get_events(action_name)
	for event in events:
		if event is InputEventKey:
			# Use as_text_physical_keycode() for physical keys, or as_text() for logical keys
			# event.as_text() or event.as_text_physical_keycode() directly returns a string name
			return event.as_text_physical_keycode() if event.physical_keycode != 0 else event.as_text()
		elif event is InputEventMouseButton:
			return "Mouse Button " + str(event.button_index) # or use event.as_text()
		# Add more conditions for InputEventJoypadButton, etc.

	return "" # Return empty string if no relevant key is found

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		show_prompt.connect(player._on_show_prompt)
		hide_prompt.connect(player._on_hide_prompt)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player_inside = true
		print("Player entered")
		emit_signal("show_prompt",
			"Press " + get_key_name("interact") +
			" to pickup " + str(qty) + " " + item_name)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player_inside = false
		print("Player left")
		emit_signal("hide_prompt")

func _process(delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("interact"):
		add_new_item()

func add_new_item() -> void:
	var item = Item.new();
	
	item.ID = id;
	item.Name = item_name;
	item.Icon = item_icon;
	item.max_qty = max_qty;
	item.qty = qty;
	item.world_scene = world_scene
	if inv.add_inventory_item(item):
		queue_free() # Remove world object
