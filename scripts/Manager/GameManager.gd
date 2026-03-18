extends Node
class_name GameManager

var is_paused: bool = false

signal paused

var orders_perfect: Array[Order] = [] # all completed orders for the day
var orders_late: Array[Order] = [] # all late orders for the day
var orders_wrong: Array[Order] = [] # all wrong orders for the day
var all_completed_orders: Array[Order] = [] # all completed orders for the day, used for calculating efficiency and payout

var payout = 0.0
var potential_payout = 0.0
var efficiency = 0.0

const POINTS_TO_RATING: Array[int] = [0,20,50,100,200] # rating points required to reach each rating 1-5
const ORDER_PAYOUT_PER_RATING: Array[float] = [3.0,3.25,3.50,3.75,4.0] # payout multiplier based on the current rating 1-5

func _process(_delta: float) -> void:
	check_for_input()

func _ready() -> void:
	Gamestate.current_state = Gamestate.States.KITCHEN
	
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
			points_earned -= 6
		elif was_late or was_wrong:
			points_earned -= 3
		else:
			points_earned += 3
	
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
		print("New rating: " + str(Gamestate.rating))

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
	print("Perfect Orders: ", orders_perfect.size(), " Late Orders: ", orders_late.size(), " Wrong Orders: ", orders_wrong.size())

# helper function to print an order's details for debugging purposes
func print_order(order: Order , additional_info: String = "") -> void:
	print(additional_info + "\nOrder ID#: " + str(order.id) + "\n Status: " + str(order.status) + "\n Is Late: " + str(order.isLate) + "\n Recipe Name: " + order.recipe.result.Name + "\n Ingredients: ")
	for ingredient in order.recipe.ingredients:
		print("\n- " + ingredient.Name)

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
