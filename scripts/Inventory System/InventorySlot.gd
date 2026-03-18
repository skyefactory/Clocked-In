extends Resource
class_name InventorySlot

@export var item: ItemData = null # The item data of the item in this inventory slot, if the slot is empty this will be null
@export var quantity: int = 0 # The quantity of the item in this inventory slot