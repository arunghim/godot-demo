extends Node
class_name InventoryHandler

@export var player_body: CharacterBody3D
@export var item_slot_count: int = 45
@export var inventory_grid: GridContainer
@export var hotbar_ui: Control
@export var inventory_slot_prefab: PackedScene = preload("res://inventory/inventory_slot.tscn")
@export_flags_3d_physics var collision_mask: int

var inventory_slots: Array[InventorySlot] = []
var hotbar_slots: Array[InventorySlot] = []
var hotbar_slot_count: int = 9
var hotbar_grid: GridContainer

func _ready() -> void:
	if hotbar_ui != null:
		hotbar_grid = hotbar_ui.get_node("GridContainer") as GridContainer
	for i in range(item_slot_count):
		var slot = inventory_slot_prefab.instantiate() as InventorySlot
		inventory_grid.add_child(slot)
		slot.inventory_slot_id = i
		slot.on_item_dropped.connect(_item_dropped_on_slot)
		inventory_slots.append(slot)
	for i in range(hotbar_slot_count):
		var slot = inventory_slot_prefab.instantiate() as InventorySlot
		if hotbar_grid != null:
			hotbar_grid.add_child(slot)
			slot.inventory_slot_id = item_slot_count + i
			slot.on_item_dropped.connect(_item_dropped_on_slot)
			hotbar_slots.append(slot)

func _pickup_item(item: ItemData):
	for slot in inventory_slots:
		if not slot.slot_filled:
			slot._fill_slot(item)
			break

func _item_dropped_on_slot(from_slot_id: int, to_slot_id: int):
	var from_slot = _get_slot_by_id(from_slot_id)
	var to_slot = _get_slot_by_id(to_slot_id)
	var from_item = from_slot.slot_data
	var to_item = to_slot.slot_data
	to_slot._fill_slot(from_item)
	from_slot._fill_slot(to_item)

func _get_slot_by_id(slot_id: int) -> InventorySlot:
	for slot in hotbar_slots:
		if slot.inventory_slot_id == slot_id:
			return slot
	for slot in inventory_slots:
		if slot.inventory_slot_id == slot_id:
			return slot
	return null

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data["Type"] == "Item"

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var slot = _get_slot_by_id(data["ID"])
	if slot == null or slot.slot_data == null:
		return
	var new_item = slot.slot_data.item_model_prefab.instantiate() as Node3D
	player_body.get_parent().add_child(new_item)
	new_item.global_position = _get_world_mouse_position()
	slot._fill_slot(null)

func _get_world_mouse_position() -> Vector3:
	var mouse_pos = get_viewport().get_mouse_position()
	var cam = get_viewport().get_camera_3d()
	var ray_start = cam.project_ray_origin(mouse_pos)
	var ray_end = ray_start + cam.project_ray_normal(mouse_pos) * cam.global_position.distance_to(player_body.global_position) * 2.0
	var world3d = player_body.get_world_3d()
	var space_state = world3d.direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end, collision_mask)
	var result = space_state.intersect_ray(query)
	if result:
		return result["position"] + Vector3(0.0, 0.5, 0.0)
	return ray_start.lerp(ray_end, 0.5) + Vector3(0.0, 0.5, 0.0)
