extends Node
class_name Inventory

var slots: Array[InventorySlot] = [] # The inventory slots of the player, this will be used to store the items in the player's inventory`
var inventory_size: int = 9 # size of inventory
var selected_slot: int = -1 # current selected item in item list
signal inventory_changed # emitted when the inventory is changed. used for sending signals to the UI to update.
signal selected_item_changed # emitted when the player changes the inventory selection to update the ItemList.
var held_item: InventorySlot = null # reference to the currently selected inventory slot.

func _ready() -> void:
	# Initialize the inventory with empty slots
	for i in range(inventory_size):
		var slot = InventorySlot.new()
		slots.append(slot)
		emit_signal("inventory_changed")
	update_held_item()

# this is used to automatically sync up the held item with the currently selected slot.
func update_held_item() -> void:
	if selected_slot >= 0 and selected_slot < inventory_size:
		held_item = slots[selected_slot]
	else:
		held_item = null

func _process(_delta: float) -> void:
	handle_slot_input() # check for input to change selected slot
	#clear any 0 quantity items from the inventory
	for i in range(inventory_size):
		if slots[i].item != null and slots[i].quantity <= 0:
			slots[i] = InventorySlot.new() # set the slot to a new empty slot
			emit_signal("inventory_changed") # emit signal to update the UI 
	update_held_item()
	pass

# check for input to change the selected slot.
func handle_slot_input() -> void:
	for i in range(inventory_size): # for each slot in the inventory
		if Input.is_action_just_pressed("slot_" + str(i+1)): #check if the slot_i action is pressed
			selected_slot = i # set the selected slot to i
			update_held_item()
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
	update_held_item()
	emit_signal("selected_item_changed", selected_slot) # emit signal to update the UI selection
	emit_signal("inventory_changed") # emit signal to update the UI since the inventory has changed
	return removed # return the removed item so it can be dropped in the world or used in some way.

# try to find the ID of a given item in the inventory, returns -1 if the item is not found in inventory.
func get_id_by_item(item: ItemData) -> int:
	for i in range(inventory_size):
		if slots[i].item != null and slots[i].item.ID == item.ID:
			return i
	return -1

# try and take an item from the inventory, reducing the quantity of that item in the inventory by the specified amount.
func take_item(item: ItemData, quantity: int) -> void:
	var slot_id = get_id_by_item(item) # get item slot if exists
	print("Taking item: ", item.Name, " Quantity: ", quantity, " from slot: ", slot_id)
	if slot_id != -1:
		if slots[slot_id].quantity >= quantity: # check that there is enough of the item in the inventory to take the specified quantity
			slots[slot_id].quantity -= quantity # take the quantity. If the item quantity reaches 0, it will be cleared from the inventory in the _process function.
			emit_signal("inventory_changed")
			return
		else:
			push_error("Tried to take more of an item than is in the inventory: " + item.Name) # push error if there was not enough in inventory.
	push_error("Tried to take item that is not in inventory: " + item.Name) #usually by this point we would have already verified the item was in the inventory, so push error

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

# Check if the inventory contains all the specified items
func has_items(required_items: Array[ItemData]) -> Dictionary:
	var missing: Array[ItemData] = [] # any items that were not found in the inventory.
	
	# Count how many of each item is required
	var required_counts: Dictionary = {} # maps ItemData.ID to required quantity
	for required_item in required_items:
		if not required_counts.has(required_item.ID):
			required_counts[required_item.ID] = 0
		required_counts[required_item.ID] += 1
	
	# Check if we have enough of each required item
	for item_id in required_counts.keys():
		var required_quantity = required_counts[item_id]
		var found_quantity: int = 0
		
		# Count how many of this item we have across all slots
		for slot in slots:
			if slot.item != null and slot.item.ID == item_id:
				found_quantity += slot.quantity
		
		# If we don't have enough, add the required instances to missing list
		if found_quantity < required_quantity:
			# Find an example of this item to add to missing list
			for required_item in required_items:
				if required_item.ID == item_id:
					# Add as many copies as we're missing
					for i in range(required_quantity - found_quantity):
						missing.append(required_item)
					break
	
	# return a dictionary. Key "has all" is true iff there are no missing items, and key "missing" is the list of any missing items.
	return {
		"has_all": missing.is_empty(),
		"missing": missing
	}

# singular version of has_items for checking if the inventory contains at least 1 of a specific item.
func has_item(item: ItemData) -> bool:
	for slot in slots:
		if slot.item != null and slot.item.ID == item.ID:
			return true
	return false

