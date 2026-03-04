extends Node
class_name GameManager

var pending_orders: Array[Order] = [] # pending orders
var completed_orders: Array[Order] = [] # completed orders
var recipes: Array[Recipe] = [] # collection of all recipes
var day_started: bool = false
@export var recipes_path: String # location of recipe resources
@export var order_time_min: int = 15 # minimum time between new orders
@export var order_time_max: int = 30 # maximum time between new orders
var accum = 0.0
var timer = 0

func pick_random_time() -> int:
    return randi_range(order_time_min, order_time_max)

signal update_orders_ui #emitted whenever an order is added/removed from pending orders

#load all the recipes from recipes_path into the recipes array
func load_recipes() -> void:
    var dir = DirAccess.open(recipes_path) # open the path
    if dir: # if the path was opened OK
        dir.list_dir_begin() # begin listing the dir
        var file_name = dir.get_next() # get the filename

        while file_name != "": # if filename is not empty
            if file_name.ends_with(".tres"): # if it is a resource file
                #load the resource
                var recipe_resource = ResourceLoader.load(recipes_path + "/" + file_name)
                #check that it is a recipe
                if recipe_resource is Recipe:
                    #add it to our recipes
                    recipes.append(recipe_resource)
            #get the next file
            file_name = dir.get_next()
        return
    # If we failed to open the directory, print an error
    push_error("Failed to load recipes from path: " + recipes_path)

func _ready() -> void:
    #randomize rng and load recipes
    randomize()
    load_recipes()
func _process(_delta: float) -> void:
    if day_started:
        if timer == 0:
            timer = pick_random_time()
        accum += _delta
        if(accum >= timer):
            var order = new_order()
            if order:
                pending_orders.append(order)
                update_orders_ui.emit(pending_orders)
            accum = 0.0
            timer = pick_random_time()
    
    if Input.is_action_just_released("debug_order"):
        var order = new_order()
        if order:
            pending_orders.append(order)
            update_orders_ui.emit(pending_orders)
        
    pass
func new_order() -> Order:
    var recipe = pick_random_recipe()
    if recipe:
        var order = Order.new()
        order.recipe = recipe
        order.id = pending_orders.size() + completed_orders.size()
        return order
    push_warning("No recipes available to create an order.")
    return null

func print_order(order: Order) -> void:
    print("ID:", order.id, " Status:", order.status, " Recipe Name:", order.recipe.result.Name, " Ingredients:", order.recipe.ingredients)

func complete_order(order:Order = null, id: int = -1) -> void:
    if order == null and id != -1:
        for o in pending_orders:
            if o.id == id:
                order = o
                break
    if order:
        pending_orders.erase(order)
        completed_orders.append(order)
        order.status = Order.OrderStatus.COMPLETED
        update_orders_ui.emit(pending_orders)
    else:
        push_warning("Order not found to complete." + str(id) + " " + str(order))
    pass

func mark_order_as_late(order:Order = null, id: int = -1) -> void:
    if order == null and id != -1:
        for o in pending_orders:
            if o.id == id:
                order = o
                break
    if order:
        order.isLate = true
        update_orders_ui.emit(pending_orders)
    else:
        push_warning("Order not found to mark as late." + str(id) + " " + str(order))

#helper function to pick a random recipe
func pick_random_recipe() -> Recipe:
    if recipes.size() == 0:
        push_warning("No recipes available to pick from.")
        return null
    
    return recipes.pick_random()
#helper function to get all pending orders
func get_pending_orders() -> Array[Order]:
    return pending_orders
#helper function to get all completed orders
func get_completed_orders() -> Array[Order]:
    return completed_orders
#helper function to get the currently active order
func get_active_order() -> Order:
    for order in pending_orders:
        if order.status == Order.OrderStatus.ACTIVE:
            return order
    return null
# when timer reaches 8 am, start the day and generate some initial orders
func on_day_start() -> void:
    for i in range(2): # create 2 initial orders at the start of the day
        var order = new_order()
        pending_orders.append(order)
    day_started = true
    update_orders_ui.emit(pending_orders)

