class_name Inventory
#https://www.youtube.com/watch?v=2F0BH1uZ87g
extends ItemList

@export var inventory_size: int = 9
@export var blank_icon: Texture2D
@export var player: Node3D
var selected_slot : int = -1
@onready var interact = %InteractLabel

var items : Array[Item]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in inventory_size:
		add_item(" ", blank_icon)
		items.append(null)
	
	item_clicked.connect(on_inventory_item_clicked);

func _process(delta: float) -> void:
	handle_slot_input();
	if Input.is_action_just_pressed("drop_item"): handle_drop()
		
func add_inventory_item(item : Item) -> bool:
	if item == null or item.qty <= 0: return false
	print(str(item.world_scene))
	var can_pickup : bool = add_stackable_item(item);
	if item.qty <= 0:
		return true;
	for i in inventory_size:
		if items[i] != null:
			continue;
		items[i] = item;
		set_item_icon(i, item.Icon);
		
		if(item.max_qty > 1):
			set_item_text(i,str(items[i].qty))
		return true
	return can_pickup

func add_stackable_item(item : Item) -> bool:
	if item.max_qty < 2:
		return false;
	
	var can_pickup : bool = false
	
	for i in inventory_size:
		if items[i] == null:
			continue
		if items[i].ID != item.ID || items[i].qty >= items[i].max_qty:
			continue
		if items[i].qty + item.qty > items[i].max_qty:
			var amount_to_remove : int = items[i].max_qty - items[i].qty;
			items[i].qty = items[i].max_qty;
			item.qty = item.qty - amount_to_remove;
			
			can_pickup = true;
			set_item_text(i, str(items[i].qty))
			continue
			
		items[i].qty = item.qty + items[i].qty;
		
		item.qty = 0;
		set_item_text(i, str(items[i].qty));
		return true;
	
	return can_pickup;

func remove_inventory_item(index : int) -> void:
	if index >= inventory_size || index < 0: return;
	items[index] = null
	set_item_icon(index,blank_icon);
	set_item_text(index, " ");
	
func get_inventory_item(index: int) -> Item:
	if index >= inventory_size || index < 0: return null;
	
	return items[index];

func on_inventory_item_clicked(index: int, pos: Vector2, mouse_button_index : int) -> void:
	if mouse_button_index == 2:
		var item = get_inventory_item(index)
		if item == null:
			print("No item")
			return;
		remove_inventory_item(index);
		print("dropped " + str(item.qty) + " " + str(item.Name))

func handle_slot_input() -> void:
	for i in inventory_size:
		if Input.is_action_just_pressed("slot_" + str(i+1)):
			select_slot(i);
			
func select_slot(index: int) -> void:
	if index >= inventory_size:
		return
		
	selected_slot = index
	select(index)

func handle_drop() -> void:
	if selected_slot == -1:
		print("selected slot is invalid")
		return
		
	var item = get_inventory_item(selected_slot)
	if item == null:
		print("item is null")
		return
		
	spawn_dropped_item(item)
	remove_inventory_item(selected_slot)
	selected_slot = -1
	
func spawn_dropped_item(item: Item) -> void:
	if item.world_scene == null: 
		print("item scene is null")
		return
	var dropped = item.world_scene.instantiate()
	dropped.id = item.ID
	dropped.item_name = item.Name
	dropped.item_icon = item.Icon
	dropped.max_qty = item.max_qty
	dropped.qty = item.qty
	dropped.world_scene = item.world_scene
	dropped.inv = self
	
	get_tree().current_scene.add_child(dropped)
	dropped.global_position = player.global_position
	print("item spawned")
