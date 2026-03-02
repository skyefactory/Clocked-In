extends Node
class_name Inventory

var slots: Array[InventorySlot] = [] # The inventory slots of the player, this will be used to store the items in the player's inventory`
var inventory_size: int = 9 # size of inventory
var selected_slot: int = -1 # current selected item in item list
signal inventory_changed # emitted when the inventory is changed. used for sending signals to the UI to update.
signal selected_item_changed # emitted when the player changes the inventory selection to update the ItemList.
var held_item: InventorySlot # reference to the currently held item. Updated every frame.

func _ready() -> void:
	for i in range(inventory_size):
		var slot = InventorySlot.new()
		slots.append(slot)
		emit_signal("inventory_changed")

func _process(_delta: float) -> void:
	handle_slot_input() # check for input to change selected slot
	if selected_slot >=0 and selected_slot < inventory_size: #update held item reference
		held_item = slots[selected_slot]
	pass

# check for input to change the selected slot.
func handle_slot_input() -> void:
	for i in range(inventory_size): # for each slot in the inventory
		if Input.is_action_just_pressed("slot_" + str(i+1)): #check if the slot_i action is pressed
			selected_slot = i # set the selected slot to i
			emit_signal("selected_item_changed", selected_slot) # emit signal to update the UI selection

#remove the item from the inventory. Returns the removed item so it can be dropped in the world or used in some way. 
#Returns null if there is no item in the selected slot.
func remove_selected_item() -> InventorySlot:
	if selected_slot < 0: # make sure a slot is selected
		return null
		
	var slot = slots[selected_slot] # get the selected slot
	if slot.item == null: # make sure there is an item in the selected slot
		return null
		
	var removed = slot # store the removed item to return later
	slots[selected_slot] = InventorySlot.new() # set the selected slot to a new empty slot
	selected_slot = -1 # reset the selected slot since there is no longer an item there
	emit_signal("selected_item_changed", selected_slot) # emit signal to update the UI selection
	emit_signal("inventory_changed") # emit signal to update the UI since the inventory has changed
	return removed # return the removed item so it can be dropped in the world or used in some way.

# adds an item to the inventory. 
#Returns the amount of the item that could not be added 
# (if the inventory is full or there are not enough slots for the quantity).
func add_inventory_item(item: ItemData, quantity: int) -> int:
	#assert statement to catch any invalid items or quantities being added to the inventory. 
	assert(item != null and quantity > 0, "Invalid item or quantity") 

	# first try to add the item to any existing stacks of the same item in the inventory. 
	# This will update the quantity of the item in those stacks and reduce the quantity that still needs to be added.
	var remaining: int = quantity
	remaining = add_item_to_stack(item, remaining) 

	# if there is nothing remaining, then we are done and can return 0 to 
	# indicate that the entire quantity was added successfully.
	if remaining <= 0:
		return 0
	# else we should look for empty slots in the inventory to add the remaining quantity of the item.
	for slot in range(inventory_size):
		if slots[slot].item != null: continue # skip any slots that are not empty
		slots[slot].item = item # set the item in the empty slot to the item we are adding
		if remaining > item.MaxStackSize: # if the remaining quantity is greater than the max stack size of the item, we should only add up to the max stack size in this slot
			slots[slot].quantity = item.MaxStackSize # set the quantity in the slot to the max stack size
			remaining -= item.MaxStackSize # reduce the remaining quantity by the max stack size since we added that much to this slot
		else:
			slots[slot].quantity = remaining # set the quantity in the slot to the remaining quantity we need to add
			emit_signal("inventory_changed") # emit signal to update the UI since the inventory has changed
			return 0 # return 0 to indicate that the entire quantity was added successfully
	return remaining # if we get here, then there were not enough empty slots to add the entire quantity, so we return the remaining quantity that could not be added.

#function to add items to existing stacks
func add_item_to_stack(item: ItemData, quantity: int) -> int:
	#assert statement to catch any invalid items or quantities being added to the inventory. 
	assert(item != null and quantity > 0, "Invalid item or quantity")
	var remaining: int = quantity

	# check if the item is stackable
	if item.MaxStackSize > 1:
		for slot in range(inventory_size): # for each slot in the inventory
			if slots[slot].item == null: # skip empty slots
				continue
			if slots[slot].item.ID != item.ID: # skip slots with different items
				continue
			if slots[slot].quantity >= item.MaxStackSize: #skip slots that are full already
				continue
			# check to see if adding the full amount of the pickup to this slot would exceed the max
			if slots[slot].quantity + remaining > item.MaxStackSize: 
				# determine the max amount we can add to this slot without exceeding the max stack 
				var amount_to_add: int = item.MaxStackSize - slots[slot].quantity
				# add that amount to the slot
				slots[slot].quantity += amount_to_add
				# reduce the remaining amount by the amount we added to the slot
				remaining -= amount_to_add
				# emit signal to update the UI since the inventory has changed
				emit_signal("inventory_changed")
				continue
			# we can add the entire remaining amount to this slot without exceeding the max stack
			slots[slot].quantity += remaining
			remaining = 0
			# emit signal to update the UI since the inventory has changed
			emit_signal("inventory_changed")
			#break since we have added all of the remaining quantity to the inventory
			break
	# return any remaining quantity that could not be added.
	return remaining
