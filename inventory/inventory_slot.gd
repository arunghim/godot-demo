extends Control
class_name InventorySlot

@export var icon_slot: TextureRect

signal on_item_dropped(from_slot_id, to_slot_id)
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

func _get_drag_data(_at_position: Vector2) -> Variant:
	if slot_filled:
		var preview: TextureRect = TextureRect.new()
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.size = icon_slot.size
		preview.pivot_offset = icon_slot.size / 2.0
		preview.rotation = 2.0
		preview.texture = icon_slot.texture
		set_drag_preview(preview)
		return {"Type": "Item", "ID": inventory_slot_id}
	return false

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data["Type"] == "Item"

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	on_item_dropped.emit(data["ID"], inventory_slot_id)
