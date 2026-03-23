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

@onready var day_label: Label = $DayCompletedLabel

@onready var perfect_orders_label: RichTextLabel = $Summary/OrderInfo/PerfectOrdersLabel
@onready var late_orders_label: RichTextLabel = $Summary/OrderInfo/LateOrdersLabel
@onready var incorrect_orders_label: RichTextLabel = $Summary/OrderInfo/IncorrectOrdersLabel

@onready var new_rating_label: RichTextLabel = $Summary/RatingInfo/NewRatingLabel

@onready var rent_label: RichTextLabel = $Summary/CashflowInfo/RentLabel
@onready var supplies_cost_label: RichTextLabel = $Summary/CashflowInfo/SuppliesCostLabel
@onready var income_label: RichTextLabel = $Summary/CashflowInfo/IncomeLabel
@onready var cashflow_label: RichTextLabel = $Summary/CashflowInfo/CashflowLabel

@onready var cash_label: RichTextLabel = $Summary/StatsInfo/CashLabel
@onready var rating_label: RichTextLabel = $Summary/StatsInfo/RatingLabel
@onready var continue_button: Button = $Summary/StatsInfo/ContinueButton

@onready var upgrades_screen: Control = get_parent().get_node("UpgradesShop") as Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	perfect_orders = Gamestate.last_day_perfect_orders.size()
	late_orders = Gamestate.last_day_late_orders.size()
	wrong_orders = Gamestate.last_day_wrong_orders.size()
	
	rating = Gamestate.rating
	
	supplies_cost = Gamestate.get_total_supplies_cost()
	payout = Gamestate.last_day_payout
	cashflow = payout - supplies_cost - rent

	Gamestate.cash += cashflow # update the player's total cash with the cashflow from the day
	is_bankrupt = Gamestate.cash < 0 # check if the player is bankrupt after updating cash
	
	set_labels()

	if is_bankrupt:
		continue_button.text = "Game Over"
		if FileAccess.file_exists("user://savegame.save"):
			var err = DirAccess.remove_absolute("user://savegame.save")
			if err != OK:
				push_warning("Failed to delete save file: " + str(err))
		continue_button.pressed.connect(game_over)
	else:
		continue_button.pressed.connect(show_upgrades_screen)

func show_upgrades_screen():
	hide()
	upgrades_screen.show()


func game_over():
	Scenechange.change_scene("res://scenes/menu.tscn")

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

func get_stars_by_number(num: int) -> String:
	var stars = ""
	for i in range(num):
		stars += "★"
	return stars

func get_cashflow(cashflow_in:float) -> String:
	if cashflow_in > 0:
		return "[color=green]$%.2f[/color]" % cashflow_in
	elif cashflow_in < 0:
		return "[color=red]$%.2f[/color]" % cashflow_in
	else:
		return "[color=white]$0.00[/color]"
