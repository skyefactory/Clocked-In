extends Control

#OrderInfo
var perfect_orders: int = 0
var late_orders: int = 0
var wrong_orders: int = 0

#RatingInfo
var rating: int = 1

#CashflowInfo
var supplies_cost: float = 0.0
const rent: float = 50.0
var payout: float = 0.0
var cashflow: float = 0.0

var is_bankrupt: bool = false

@onready var day_label: Label = $DayCompletedLabel # reference to the label that shows the day number in the summary screen.

@onready var perfect_orders_label: RichTextLabel = $Summary/OrderInfo/PerfectOrdersLabel # reference to the label that shows the number of perfect orders in the summary screen.
@onready var late_orders_label: RichTextLabel = $Summary/OrderInfo/LateOrdersLabel # reference to the label that shows the number of late orders in the summary screen.
@onready var incorrect_orders_label: RichTextLabel = $Summary/OrderInfo/IncorrectOrdersLabel # reference to the label that shows the number of incorrect orders in the summary screen.

@onready var new_rating_label: RichTextLabel = $Summary/RatingInfo/NewRatingLabel # reference to the label that shows the new rating in the summary screen.

@onready var rent_label: RichTextLabel = $Summary/CashflowInfo/RentLabel # reference to the label that shows the rent payment in the summary screen.
@onready var supplies_cost_label: RichTextLabel = $Summary/CashflowInfo/SuppliesCostLabel # reference to the label that shows the supplies cost in the summary screen.
@onready var income_label: RichTextLabel = $Summary/CashflowInfo/IncomeLabel # reference to the label that shows the income in the summary screen.
@onready var cashflow_label: RichTextLabel = $Summary/CashflowInfo/CashflowLabel # reference to the label that shows the cashflow in the summary screen.

@onready var cash_label: RichTextLabel = $Summary/StatsInfo/CashLabel # reference to the label that shows the player's total cash after the day's cashflow is applied in the summary screen.
@onready var rating_label: RichTextLabel = $Summary/StatsInfo/RatingLabel # reference to the label that shows the player's overall rating after the day's new rating is applied in the summary screen.
@onready var continue_button: Button = $Summary/StatsInfo/ContinueButton # reference to the button that continues to the next screen after the player has reviewed the summary screen.

@onready var upgrades_screen: Control = get_parent().get_node("UpgradesShop") as Control # reference to the upgrades screen so that we can show it when we click the continue button on the summary screen.

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	perfect_orders = Gamestate.last_day_perfect_orders.size() # get the number of perfect orders from the gamestate, which is determined by the orders that were completed on time with all the correct ingredients.
	late_orders = Gamestate.last_day_late_orders.size() # get the number of late orders from the gamestate, which is determined by the orders that were completed but were late (missed the deadline)
	wrong_orders = Gamestate.last_day_wrong_orders.size() # get the number of wrong orders from the gamestate, which is determined by the orders that were completed but had incorrect ingredients or were missing critical ingredients that made the order unacceptable.
	
	rating = Gamestate.rating # get the player's overall restaurant rating from the gamestate
	
	supplies_cost = Gamestate.get_total_supplies_cost() # get the total cost of the supplies that were used during the day from the gamestate, which is calculated by adding up the cost of all the unlocked supplies
	payout = Gamestate.last_day_payout # get the total payout from the gamestate, which is calculated by adding up the earnings from all completed orders
	cashflow = payout - supplies_cost - rent # calculate the cashflow for the day by subtracting the supplies cost and rent from the payout

	Gamestate.cash += cashflow # update the player's total cash with the cashflow from the day
	is_bankrupt = Gamestate.cash < 0 # check if the player is bankrupt after updating cash
	
	set_labels()

	if is_bankrupt: # if the player is bankrupt, change the continue button text to "Game Over" and connect it to the game over function, which will take them back to the main menu. 
	#also, delete the save file so that they have to start over if they want to play again.
		continue_button.text = "Game Over"
		if FileAccess.file_exists("user://savegame.save"):
			var err = DirAccess.remove_absolute("user://savegame.save")
			if err != OK:
				push_warning("Failed to delete save file: " + str(err))
		continue_button.pressed.connect(game_over)
	else:
		continue_button.pressed.connect(show_upgrades_screen)

# show the upgrades screen when the continue button is pressed, and hide the summary screen.
func show_upgrades_screen():
	hide()
	upgrades_screen.show()

# end the game and return to the main menu when the player clicks the continue button while bankrupt.
func game_over():
	Scenechange.change_scene("res://scenes/menu.tscn")

# set all the labels on the summary screen based on the day's performance and the player's updated stats.
func set_labels():
	day_label.text = "Day %d Completed" % Gamestate.current_day

	perfect_orders_label.text = "Perfect Orders - - - - - - - - - - - - - - %d" % perfect_orders
	late_orders_label.text = "Late Orders - - - - - - - - - - - - - - %d" % late_orders
	incorrect_orders_label.text = "Incorrect Orders - - - - - - - - - - - - %d" % wrong_orders


	new_rating_label.text = "New Rating - - - - - - - - - - - - - - - [color=yellow]%s[/color]" % get_stars_by_number(rating)

	rent_label.text = "Rent Payment - - - - - - - - - - - - - - [color=red]$%.2f[/color]" % rent
	supplies_cost_label.text = "Supplies Cost - - - - - - - - - - - - - - - [color=red]$%.2f[/color]" % supplies_cost
	income_label.text = "Income - - - - - - - - - - - - - - [color=green]$%.2f[/color]" % payout
	cashflow_label.text = "Cashflow - - - - - - - - - - - - - " + get_cashflow(cashflow)

	cash_label.text = "Cash: $%d" % Gamestate.cash
	rating_label.text = "Rating: [color=yellow]%s[/color]" % get_stars_by_number(Gamestate.rating)

# helper function to convert a number rating into a string of stars for display on the summary screen.
func get_stars_by_number(num: int) -> String:
	var stars = ""
	for i in range(num):
		stars += "★"
	return stars

# helper function to format the cashflow number with a plus sign and green color for positive cashflow, a minus sign and red color for negative cashflow, and white color for zero cashflow.
func get_cashflow(cashflow_in:float) -> String:
	if cashflow_in > 0:
		return "[color=green]$%.2f[/color]" % cashflow_in
	elif cashflow_in < 0:
		return "[color=red]$%.2f[/color]" % cashflow_in
	else:
		return "[color=white]$0.00[/color]"
