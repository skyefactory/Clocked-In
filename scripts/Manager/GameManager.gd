extends Node
class_name GameManager

var is_paused: bool = false

signal paused # is the game paused
signal show_day_end_confirmation() # signal to show the day end confirmation screen after the day ends and payouts are calculated.


var orders_perfect: Array[Order] = [] # all completed orders for the day
var orders_late: Array[Order] = [] # all late orders for the day
var orders_wrong: Array[Order] = [] # all wrong orders for the day
var all_completed_orders: Array[Order] = [] # all completed orders for the day, used for calculating efficiency and payout

var payout = 0.0 # net payout for the day based on completed orders, used for calculating cash earned at the end of the day and shown in the day end summary screen.
var potential_payout = 0.0 # gross payout for the day if all orders were perfect, used for calculating efficiency and shown in the day end summary screen.
var efficiency = 0.0 

var is_day_over: bool = false # is the day over
var all_orders_completed: bool = false # are all the orders complte for the day

const POINTS_TO_RATING: Array[int] = [0,75,275,450,600] # rating points required to reach each rating 1-5
const ORDER_PAYOUT_PER_RATING: Array[float] = [4.2,4.8,5.4,6.0,6.6] # payout multiplier based on the current rating 1-5

# stations 
@export var griddle_1: Node
@export var griddle_2: Node
@export var drink_machine_1: Node
@export var drink_machine_2: Node
@export var fryer_1: Node
@export var fryer_2: Node
@export var drink_machine_table: Node

#supplies
@export var patty_supply: Node
@export var bun_supply: Node
@export var cheese_supply: Node
@export var lettuce_supply: Node
@export var tomato_supply: Node
@export var bacon_supply: Node
@export var frozen_fries_supply: Node
@export var empty_cup_supply: Node

# environment and lighting
@export var world_environment: WorldEnvironment
@export var sun: DirectionalLight3D
var environment: Environment
var sky_material: ProceduralSkyMaterial

# used for day / night cycle, changes the sky and sun based on the time of day.
const DAY_SKY_TOP: Color = Color(0.32, 0.66, 0.98)
const DAY_SKY_HORIZON: Color = Color(0.86, 0.93, 1.0)
const DAY_GROUND_HORIZON: Color = Color(0.39, 0.49, 0.28)
const DAY_GROUND_BOTTOM: Color = Color(0.16, 0.21, 0.14)

const NIGHT_SKY_TOP: Color = Color(0.015, 0.03, 0.08)
const NIGHT_SKY_HORIZON: Color = Color(0.06, 0.09, 0.17)
const NIGHT_GROUND_HORIZON: Color = Color(0.05, 0.06, 0.08)
const NIGHT_GROUND_BOTTOM: Color = Color(0.01, 0.015, 0.025)

const DAY_SUN_COLOR: Color = Color(1.0, 0.97, 0.91)
const NIGHT_SUN_COLOR: Color = Color(0.35, 0.42, 0.58)

@export var restauraunt_name_label: Label3D

#show / hide nodes based on if they are unlocked in the game state. This is used for showing new stations and supplies as they are unlocked.
func show_hide_unlocked_content() -> void:
	var supplies = Gamestate.get_available_supplies()

	set_node_unlocked_state(griddle_1, Gamestate.unlocked_content.has("Griddle"))
	set_node_unlocked_state(griddle_2, Gamestate.unlocked_content.has("Second Griddle"))
	set_node_unlocked_state(drink_machine_1, Gamestate.unlocked_content.has("Drink Machine"))
	set_node_unlocked_state(drink_machine_table, Gamestate.unlocked_content.has("Drink Machine")) # the drink machine table is just a visual element, so it unlocks with the drink machine
	set_node_unlocked_state(drink_machine_2, Gamestate.unlocked_content.has("Second Drink Machine"))
	set_node_unlocked_state(fryer_1, Gamestate.unlocked_content.has("Fryer"))
	set_node_unlocked_state(fryer_2, Gamestate.unlocked_content.has("Second Fryer"))


	set_node_unlocked_state(patty_supply, supplies.has("RAWPATTY"))
	set_node_unlocked_state(bun_supply, supplies.has("BUNS"))
	set_node_unlocked_state(cheese_supply, supplies.has("CHEESE"))
	set_node_unlocked_state(lettuce_supply, supplies.has("LETTUCE"))
	set_node_unlocked_state(tomato_supply, supplies.has("TOMATO"))
	set_node_unlocked_state(bacon_supply, supplies.has("RAWBACON"))
	set_node_unlocked_state(frozen_fries_supply, supplies.has("FROZENFRIES"))
	set_node_unlocked_state(empty_cup_supply, supplies.has("EMPTYCUP"))

# helper function to show or hide a node and its collision shapes based on whether it is unlocked or not. This is used for stations and supplies that are unlocked as the player progresses through the game.
func set_node_unlocked_state(target: Node, unlocked: bool) -> void:
	if target == null:
		return

	if target.has_method("show") and target.has_method("hide"):
		if unlocked:
			target.show()
		else:
			target.hide()

	target.process_mode = Node.PROCESS_MODE_INHERIT if unlocked else Node.PROCESS_MODE_DISABLED
	set_collision_shapes_disabled(target, not unlocked)

func on_time_changed(hour: int, minute: int, pm: bool, _spedup: bool) -> void:
	var normalized_time = _to_day_fraction(hour, minute, pm)
	_apply_day_night(normalized_time)

# convert time to 24 hour, then to a fraction of the day (0.0-1.0)
func _to_day_fraction(hour: int, minute: int, pm: bool) -> float:
	var h12 = hour
	if h12 == 0: # hour 0 is 12pm
		h12 = 12

	var h24 = 0  # convert to 24 hour time
	if h12 == 12:
		h24 = 12 if pm else 0
	else:
		h24 = h12 + (12 if pm else 0)
	# convert to fraction of the day
	return float(h24 * 60 + minute) / 1440.0

func _apply_day_night(day_fraction: float) -> void:
	# Peak daylight at noon, darkest at midnight.
	#sin function provides a smooth wave. Subtracting 0.25 shifts the wave so that peak daylight is at noon.
	#then it is changed from -1,1 to 0,1. 
	var daylight = clamp((sin((day_fraction - 0.25) * TAU) + 1.0) * 0.5, 0.0, 1.0)
	var sunrise_sunset = 1.0 - abs(daylight * 2.0 - 1.0)

	if sky_material != null:
		#mixes the day and night color based on the current daylight value.
		sky_material.sky_top_color = NIGHT_SKY_TOP.lerp(DAY_SKY_TOP, daylight)
		sky_material.sky_horizon_color = NIGHT_SKY_HORIZON.lerp(DAY_SKY_HORIZON, daylight)
		sky_material.ground_horizon_color = NIGHT_GROUND_HORIZON.lerp(DAY_GROUND_HORIZON, daylight)
		sky_material.ground_bottom_color = NIGHT_GROUND_BOTTOM.lerp(DAY_GROUND_BOTTOM, daylight)
		sky_material.energy_multiplier = lerp(0.14, 1.0, daylight)

	if sun != null:
		sun.rotation_degrees.x = day_fraction * 360.0 + 90.0 # rotate the sun based on the time of day, with an offset so that it starts at the horizon at 6am.
		sun.light_energy = lerp(0.02, 1.2, daylight)
		# Slightly warmer tint near sunrise/sunset. 
		var warm_tint = Color(1.0, 0.80, 0.62)
		var base_tint = NIGHT_SUN_COLOR.lerp(DAY_SUN_COLOR, daylight)
		sun.light_color = base_tint.lerp(warm_tint, sunrise_sunset * 0.35)
	
#disable collisions on a node and all its children, used for hiding locked stations and supplies.
func set_collision_shapes_disabled(root: Node, disabled: bool) -> void:
	for child in root.get_children():
		if child is CollisionShape3D:
			child.disabled = disabled
		elif child is CollisionPolygon3D:
			child.disabled = disabled

		set_collision_shapes_disabled(child, disabled)

func _process(_delta: float) -> void:
	check_for_input()
	if is_day_over and all_orders_completed:
		calculate_payouts() # calculate the payout for the day based on the completed orders
		calculate_rating_points() # calculate the rating points earned for the day based on the completed orders
		calculate_rating() # calculate the new rating based on the updated rating points
		is_day_over = false # reset the day over flag for the next day
		all_orders_completed = false # reset the all orders completed flag for the next day
		show_day_end_confirmation.emit() # emit a signal to show the day end confirmation screen
		Gamestate.last_day_perfect_orders = orders_perfect.duplicate() # store the perfect orders for the day in the game state for use in the day end summary screen
		Gamestate.last_day_late_orders = orders_late.duplicate() # store the late orders for the day in the game state for use in the day end summary screen
		Gamestate.last_day_wrong_orders = orders_wrong.duplicate() # store the wrong orders for the day in the game state for use in the day end summary screen
		Gamestate.last_day_payout = payout # store the payout for the day in the game state for use in the day end summary screen


func _ready() -> void:
	# Set up environment and sky material references for day/night cycle.
	if world_environment != null:
		environment = world_environment.environment
		if environment != null and environment.sky != null and environment.sky.sky_material is ProceduralSkyMaterial:
			sky_material = environment.sky.sky_material as ProceduralSkyMaterial
		else:
			push_warning("WorldEnvironment sky material is missing or is not ProceduralSkyMaterial.")
	else:
		push_warning("world_environment is not assigned on GameManager.")

	# Initialize game state for the start of the day.
	Gamestate.current_state = Gamestate.States.KITCHEN
	Gamestate.last_day_perfect_orders = []
	Gamestate.last_day_late_orders = [] 
	Gamestate.last_day_wrong_orders = []
	Gamestate.last_day_payout = 0.0

	#clear all variables that should be reset at the start of the game
	orders_perfect.clear()
	orders_late.clear()
	orders_wrong.clear()
	all_completed_orders.clear()
	payout = 0.0
	potential_payout = 0.0
	efficiency = 0.0
	is_day_over = false
	all_orders_completed = false

	show_hide_unlocked_content()
	# Match DayTimer starting value so lighting is correct on scene load.
	on_time_changed(7, 45, false, false)

	restauraunt_name_label.text = Gamestate.restaurant_name

# checks for pause key
func check_for_input() -> void:
	if Input.is_action_just_released("pause"):
		toggle_pause()

func calculate_payouts() -> void:
	payout = 0 # actual payout
	potential_payout = 0 # potential payout if all orders were perfect, used for calculating efficiency.
	var base_payout = ORDER_PAYOUT_PER_RATING[Gamestate.rating - 1] # base payout for the current rating, used to calculate potential payout and actual payout.
	for order in all_completed_orders:
		var was_late = orders_late.has(order) # was the order late
		var was_wrong = orders_wrong.has(order) # was the order wrong

		potential_payout += base_payout # add the base payout to the potential payout
		#was the order both late and wrong?
		if was_late and was_wrong:
			payout += base_payout * 0.3 # apply a 70% penalty to the payout for this order since it was both late and wrong.
		#was the order either late or wrong (but not both)?
		elif was_late or was_wrong:
			payout += base_payout * 0.6 # apply a 40% penalty to the payout for this order since it was either late or wrong, but not both.
		# was the order perfect?
		else:
			payout += base_payout

	if payout > 0 and potential_payout > 0: # calculate efficiency as the ratio of payout to potential payout
		efficiency = payout / potential_payout
	else:
		efficiency = 0.0
	
# calculate rating points based on the completed orders for the day. 
# Perfect orders are worth 3 points, while late or wrong orders lose 3 points.
# Orders that are both late and wrong lose 6 points.
func calculate_rating_points() -> void:
	var points_earned = 0
	for order in all_completed_orders:
		var was_late = orders_late.has(order)
		var was_wrong = orders_wrong.has(order)
		if was_late and was_wrong:
			points_earned -= 12
		elif was_late or was_wrong:
			points_earned -= 6
		else:
			points_earned += 4
	
	Gamestate.rating_points += points_earned

# calculate the player's rating based on their current rating points. 
# The player's rating increases by 1 for each threshold of points reached in POINTS_TO_RATING.
func calculate_rating() -> void:
	var new_rating = 1 # start at rating 1
	for i in range(POINTS_TO_RATING.size()): # go over each rating threshold
		if Gamestate.rating_points >= POINTS_TO_RATING[i]: # do we have enough points to reach this rating?
			new_rating = i + 1 # if so, set the new rating to this rating (i+1 since ratings start at 1 but our index starts at 0)
	if new_rating != Gamestate.rating: # if our rating has changed, update it and print the new rating.
		Gamestate.rating = new_rating

# toggles the paused state and shows/hides the mouse cursor accordingly. Also emits a signal to notify other nodes of the pause state change.
func toggle_pause() -> void:
	is_paused = not is_paused
	if is_paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	paused.emit(is_paused)

# quits the app
func quit() -> void:
	get_tree().quit()

func record_completed_order(order: Order, wrong: bool = false) -> void:
	if order == null: # null check
		push_warning("Tried to record a null completed order.")
		return
	# catagorize the completed order as perfect, late, or wrong and add it to the appropriate lists for the day.
	all_completed_orders.append(order)
	if order.isLate:
		orders_late.append(order)
	if wrong:
		orders_wrong.append(order)
	if not wrong and not order.isLate:
		orders_perfect.append(order)

	order.status = Order.OrderStatus.COMPLETED

#helper function to get all completed orders
func get_completed_orders() -> Array[Order]:
	return all_completed_orders

func on_day_start() -> void:
	orders_perfect.clear() # clear the perfect orders for the day
	orders_late.clear() # clear the late orders for the day 
	orders_wrong.clear() # clear the wrong orders for the day
	all_completed_orders.clear() # clear all completed orders for the day
	payout = 0.0 # reset payout for the day
	potential_payout = 0.0 # reset potential payout for the day
	efficiency = 0.0 # reset efficiency for the day

func on_day_end():
	is_day_over = true

func on_all_orders_completed() -> void:
	all_orders_completed = true
