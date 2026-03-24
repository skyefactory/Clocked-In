extends Node
class_name OrderManager

signal update_orders_ui(pending_orders: Array[Order])
signal all_orders_completed()
const ORDERS_PER_RATING: Array[int] = [30,37,44,50,56] # number of orders based on the current rating 1-5
const HOURS_PER_DAY: int = 12 # number of hours in a day (8 am to 8 pm)

@export var game_manager: GameManager
@export var recipes_path: String

var pending_orders: Array[Order] = [] # pending orders
var recipes: Array[Recipe] = [] # collection of all recipes
var order_schedule: Array[Vector2i] = [] # schedule of when orders should be generated for the day
var next_scheduled_order_index: int = 0 # next order to be spawned
var next_order_id: int = 0 # incremental ID for orders to keep track of them, since multiple orders can have the same recipe.
var day_started: bool = false # flag to track if the day has started, used to control when orders can be spawned and when the day completion can be emitted.
var completion_emitted_for_day: bool = false # flag to ensure we only emit the all_orders_completed signal once per day

func _ready() -> void:
	randomize() # randomize the random number generator for picking random recipes
	load_recipes() # load recipes from the specified path
	schedule_orders_for_day() # schedule orders for the day based on the current rating

func _process(_delta: float) -> void:
	if Input.is_action_just_released("debug_order"):
		create_and_queue_order()
	

func schedule_orders_for_day() -> void:
	order_schedule.clear() # clear the order schedule
	next_scheduled_order_index = 0 # reset the next scheduled order index

	# get the total number of orders based on current rating
	var total_orders_for_day = ORDERS_PER_RATING[Gamestate.rating - 1] # get the number of orders for the current rating
	if total_orders_for_day <= 0:
		return

	# schedule orders evenly throughout the day. we will spawn them when their scheduled time comes up in on_time_changed.
	var minutes_per_order = (HOURS_PER_DAY * 60.0) / total_orders_for_day 
	for i in range(total_orders_for_day):
		var order_time = minutes_per_order * i
		var hour = int(order_time / 60) + 8
		var minute = int(fmod(order_time, 60.0))
		order_schedule.append(Vector2i(hour, minute))

# print the order schedule for debugging purposes
func print_schedule() -> void:
	pass

#load all recipes from the specified path and add them to the recipes array.
func load_recipes() -> void:
	recipes.clear() # clear the recipes array before loading new recipes
	var dir = DirAccess.open(recipes_path) # open the path
	if dir:
		dir.list_dir_begin() # begin listing the dir
		var file_name = dir.get_next() # get the filename

		while file_name != "": # if filename is not empty
			if not dir.current_is_dir(): # make sure it's not a directory
				var resource_path := recipes_path.path_join(file_name) # get the full resource path
				# Exported builds may list remapped resources as *.remap.
				if resource_path.ends_with(".remap"): 
					resource_path = resource_path.trim_suffix(".remap")
				# load the resource and check if it's a Recipe before adding it to the recipes array.
				var recipe_resource = ResourceLoader.load(resource_path)
				if recipe_resource is Recipe:
					recipes.append(recipe_resource)
			#get the next file
			file_name = dir.get_next()
		# end listing the dir
		dir.list_dir_end()
		# if we didn't load any recipes, print a warning.
		if recipes.is_empty():
			push_warning("No recipes were loaded from path: " + recipes_path)
		remove_not_unlocked_recipes() # remove any recipes that aren't unlocked based on the current game state
		return
	# If we failed to open the directory, print an error
	push_error("Failed to load recipes from path: " + recipes_path)

func remove_not_unlocked_recipes():
	var unlocked_recipes = Gamestate.get_unlocked_by_type("recipe") # get all unlocked recipes
	var recipes_to_remove: Array[Recipe] = [] # list of locked recipes to remove from the recipes array
	for recipe in recipes:
		if not unlocked_recipes.has(recipe.result.Name):
			recipes_to_remove.append(recipe)
	#remove any locked recipes from the recipes array
	for recipe in recipes_to_remove:
		recipes.erase(recipe)


# create a new order with a random recipe and return it.
func new_order() -> Order:
	var recipe = pick_random_recipe()
	if recipe == null:
		push_warning("No recipes available to create an order.")
		return null

	var order = Order.new()
	order.recipe = recipe
	order.id = next_order_id
	next_order_id += 1
	return order

# submit an order with the given item, checking if it matches the active order and marking it as completed if so.
func take_order(item: ItemData) -> void:
	var active_order = get_active_order()
	if active_order == null:
		push_warning("No active order to take.")
		return

	var was_wrong = item.ID != active_order.recipe.result.ID
	complete_order(active_order, was_wrong)


# remove the order from the list of pending orders and send it to the game manager to be recorded.
func complete_order(order: Order = null, wrong: bool = false, id: int = -1) -> void:
	if order == null and id != -1:
		order = get_order_by_id(id)
	if order == null:
		push_warning("Order not found to complete. " + str(id))
		return

	pending_orders.erase(order)
	if game_manager:
		game_manager.record_completed_order(order, wrong)
	else:
		order.status = Order.OrderStatus.COMPLETED

	update_orders_ui.emit(pending_orders)
	check_all_orders_completed()

# mark the order as late.
func mark_order_as_late(order: Order = null, id: int = -1) -> void:
	print("Marking order as late: " + str(id))
	if order == null and id != -1:
		order = get_order_by_id(id)
	if order == null:
		push_warning("Order not found to mark as late. " + str(id))
		return

	order.isLate = true
	update_orders_ui.emit(pending_orders)
	print("Order marked as late: " + str(order.id))

# set the specified order as the active order, setting any previously active order back to pending.
func set_active_order(id: int) -> void:
	var found = false
	for order in pending_orders:
		if order.id == id:
			order.status = Order.OrderStatus.ACTIVE
			found = true
			print("Order set as active: " + str(order.recipe.result.Name))
		elif order.status == Order.OrderStatus.ACTIVE:
			order.status = Order.OrderStatus.PENDING

	if found:
		update_orders_ui.emit(pending_orders)
	else:
		push_warning("Order not found to set as active: " + str(id))
# set the specified order as pending, used for when an active order is deselected without selecting a new one.
func set_order_as_pending(id: int) -> void:
	var found = false
	for order in pending_orders:
		if order.id == id:
			order.status = Order.OrderStatus.PENDING
			found = true
			break

	if found:
		update_orders_ui.emit(pending_orders)

# pick a random recipe from the recipes array and return it.
func pick_random_recipe() -> Recipe:
	if recipes.is_empty():
		push_warning("No recipes available to pick from.")
		return null

	return recipes.pick_random()

func get_pending_orders() -> Array[Order]:
	return pending_orders

func get_active_order() -> Order:
	for order in pending_orders:
		if order.status == Order.OrderStatus.ACTIVE:
			return order
	return null

func on_day_start() -> void:
	day_started = true # start the day
	completion_emitted_for_day = false
	pending_orders.clear() # clear the pending orders
	next_order_id = 0 # reset the order ID counter for the new day
	schedule_orders_for_day() # schedule orders for the day based on the current rating
	update_orders_ui.emit(pending_orders) # update the orders UI to show the new pending orders for the day
	spawn_due_orders(8, 0, false) # spawn any orders that are due at the start of the day (8:00 am)

func on_day_end() -> void:
	day_started = false
	check_all_orders_completed()

func on_time_changed(hour: int, minute: int, pm: bool, _spedup: bool) -> void:
	if not day_started:
		return

	spawn_due_orders(hour, minute, pm)

# this function is used for debugging to spawn an order immediately when the debug_order action is triggered.
func create_and_queue_order() -> void:
	var order = new_order()
	if order == null:
		return

	pending_orders.append(order)
	update_orders_ui.emit(pending_orders)
	check_all_orders_completed()

# spawn any orders that are scheduled based on the current time. 
func spawn_due_orders(hour: int, minute: int, pm: bool) -> void:
	# how many minutes since the start of the day.
	var current_day_minutes = get_minutes_since_day_start(hour, minute, pm)
	if current_day_minutes < 0:
		return
	# flag to track if we added orders
	var added_order = false
	# while we have scheduled orders
	while next_scheduled_order_index < order_schedule.size():
		# determine if an order is due to be spawned
		var scheduled_time = order_schedule[next_scheduled_order_index]
		var scheduled_day_minutes = ((scheduled_time.x - 8) * 60) + scheduled_time.y
		# if the scheduled order time is in the future, break out of the loop since we spawn orders in order and any future orders will also be in the future.
		if scheduled_day_minutes > current_day_minutes:
			break

		var order = new_order() # create the new order
		if order:
			pending_orders.append(order) # add the new order to the pending orders
			added_order = true # set the flag to true since we added an order
		next_scheduled_order_index += 1 # increment the next scheduled order index so that we check the next order in the schedule on the next iteration of the loop.

	if added_order:
		update_orders_ui.emit(pending_orders)

	check_all_orders_completed()
 
 # calculate how many minutes have passed since the start of the day (8:00 am) based on the current time. This is used to determine when orders should be spawned based on the order schedule.
func get_minutes_since_day_start(hour: int, minute: int, pm: bool) -> int:
	var normalized_hour = hour
	if normalized_hour == 0:
		normalized_hour = 12

	var minutes_since_midnight = (normalized_hour * 60) + minute
	if pm and normalized_hour != 12:
		minutes_since_midnight += 12 * 60
	elif not pm and normalized_hour == 12:
		minutes_since_midnight -= 12 * 60

	return minutes_since_midnight - (8 * 60)

func get_order_by_id(id: int) -> Order:
	for order in pending_orders:
		if order.id == id:
			return order
	return null

# check if all orders have been completed and emit the all_orders_completed signal if so. This is used to trigger the end of day sequence in the game manager.
func check_all_orders_completed() -> void:
	if completion_emitted_for_day:
		return

	if day_started:
		return

	# Only complete once every scheduled order has spawned and no pending orders remain.
	if next_scheduled_order_index >= order_schedule.size() and pending_orders.is_empty():
		completion_emitted_for_day = true
		all_orders_completed.emit()
