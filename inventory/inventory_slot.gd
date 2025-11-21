extends Control
class_name InventorySlot

@export var icon_slot: TextureRect
@export var equipped_highlight: Panel
@export var stack_label: Label

signal on_item_dropped(from_slot_id, to_slot_id)
signal on_item_equipped(slot_id)

var inventory_slot_id: int = -1
var slot_filled: bool = false
var slot_data: ItemData

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT and slot_filled:
			on_item_equipped.emit(inventory_slot_id)

func _fill_slot(data: ItemData, equipped: bool):
	slot_data = data
	equipped_highlight.visible = equipped
	if slot_data != null:
		slot_filled = true
		icon_slot.texture = data.icon
		stack_label.visible = data.current_stack > 1
		stack_label.text = str(data.current_stack)
	else:
		slot_filled = false
		icon_slot.texture = null
		stack_label.visible = false

func _get_drag_data(_at_position: Vector2) -> Variant:
	if slot_filled:
		var preview := TextureRect.new()
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.size = icon_slot.size
		preview.pivot_offset = icon_slot.size / 2.0
		preview.texture = icon_slot.texture
		set_drag_preview(preview)
		return {"Type": "Item", "ID": inventory_slot_id, "Stack": slot_data.current_stack}
	return false

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data["Type"] == "Item"

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	on_item_dropped.emit(data["ID"], inventory_slot_id)
