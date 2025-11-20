extends Control
class_name InventorySlot

@export var icon_slot: TextureRect
signal on_item_dropped(from_slot_id, to_slot_id, from_list, to_list)
var inventory_slot_id: int = -1
var slot_filled: bool = false
var slot_data: ItemData

func _fill_slot(data: ItemData):
	slot_data = data
	if slot_data != null:
		slot_filled = true
		icon_slot.texture = data.icon
	else:
		slot_filled = false
		icon_slot.texture = null

func _get_drag_data(_pos: Vector2) -> Variant:
	if slot_filled:
		var preview = icon_slot.duplicate() as TextureRect
		set_drag_preview(preview)
		
		return {"ID": inventory_slot_id, "List": get_meta("list_name")}
	
	return false

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("ID") and data.has("List")

func _drop_data(_pos: Vector2, data: Variant) -> void:
	on_item_dropped.emit(data["ID"], inventory_slot_id, data["List"], get_meta("list_name"))
