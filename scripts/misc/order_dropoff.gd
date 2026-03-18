extends StaticBody3D

@export var order_manager: OrderManager

func can_interact(_interacting_player: Player) -> bool:
	return order_manager.get_pending_orders().size() > 0 # no point interacting if there are no  orders to submit to.

func get_interaction_text(interacting_player: Player) -> String:
	if order_manager.get_active_order() != null: # is there an active order
		#check if the player is holding an item.
		if interacting_player.inventory.held_item != null and interacting_player.inventory.held_item.item != null:
			return "Press E to submit" + interacting_player.inventory.held_item.item.Name # interaction text.
		else:
			return ""
	else: # there was no active order, player needs to select one first.
		return "Select an order to work on"

func interact(interacting_player: Player) -> void:
	var active_order = order_manager.get_active_order() # current selected order
	var held_item = interacting_player.inventory.held_item.item # currently selected/held item
	if active_order != null and held_item != null: # if there is both an active order and a held item
		interacting_player.inventory.take_item(held_item, 1) # take one of the held item from the inventory
		order_manager.take_order(held_item) # send item to the order manager 
	else: return
