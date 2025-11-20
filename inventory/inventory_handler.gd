extends Control
class_name InventoryHandler

@export var player_body: CharacterBody3D
@export var inventory_slot_prefab: PackedScene = preload("res://inventory/inventory_slot.tscn")
@export var inventory_slot_count: int = 45
@export var hotbar_slot_count: int = 9

var inventory_slots: Array[InventorySlot] = []
var hotbar_slots: Array[InventorySlot] = []
var inventory_grid: GridContainer
var hotbar_grid: GridContainer

func _ready() -> void:
	inventory_grid = $GridContainer
	inventory_grid.columns = 9
	hotbar_grid = $"../HotbarUI/GridContainer"
	hotbar_grid.columns = 9

	for i in range(inventory_slot_count):
		var slot = inventory_slot_prefab.instantiate() as InventorySlot
		slot.inventory_slot_id = i
		slot.set_meta("list_name", "inventory")
		slot.on_item_dropped.connect(_item_dropped_on_slot)
		inventory_grid.add_child(slot)
		inventory_slots.append(slot)

	for i in range(hotbar_slot_count):
		var slot = inventory_slot_prefab.instantiate() as InventorySlot
		slot.inventory_slot_id = i
		slot.set_meta("list_name", "hotbar")
		slot.on_item_dropped.connect(_item_dropped_on_slot)
		hotbar_grid.add_child(slot)
		hotbar_slots.append(slot)

func _pickup_item(item: ItemData) -> void:
	for slot in inventory_slots:
		if not slot.slot_filled:
			slot._fill_slot(item)
			break

func _item_dropped_on_slot(from_id: int, to_id: int, from_list: String, to_list: String) -> void:
	var from_array = inventory_slots if from_list == "inventory" else hotbar_slots
	var to_array = inventory_slots if to_list == "inventory" else hotbar_slots
	var from_slot = from_array[from_id]
	var to_slot = to_array[to_id]
	var temp_item = to_slot.slot_data
	to_slot._fill_slot(from_slot.slot_data)
	from_slot._fill_slot(temp_item)
	
