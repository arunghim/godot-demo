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
var active_hotbar_index: int = -1

var equipped_items: Dictionary = {
	ItemData.EquipType.HEAD: null,
	ItemData.EquipType.CHEST: null,
	ItemData.EquipType.GLOVES: null,
	ItemData.EquipType.LEGS: null,
	ItemData.EquipType.BOOTS: null,
	ItemData.EquipType.MAIN_HAND: null,
	ItemData.EquipType.OFF_HAND: null,
	ItemData.EquipType.WAIST: null,  
	ItemData.EquipType.BACK: null,
	ItemData.EquipType.NECK: null,
	ItemData.EquipType.FINGER: null
}

func get_main_hand() -> ItemData:
	return equipped_items.get(ItemData.EquipType.MAIN_HAND)

func get_off_hand() -> ItemData:
	return equipped_items.get(ItemData.EquipType.OFF_HAND)

func _ready() -> void:
	if hotbar_ui != null:
		hotbar_grid = hotbar_ui.get_node("GridContainer") as GridContainer
	for i in range(item_slot_count):
		var slot = inventory_slot_prefab.instantiate() as InventorySlot
		inventory_grid.add_child(slot)
		slot.inventory_slot_id = i
		slot.on_item_dropped.connect(_item_dropped_on_slot)
		slot.on_item_equipped.connect(_on_slot_equipped)
		slot.gui_input.connect(Callable(self, "_on_slot_gui_input").bind(slot))
		inventory_slots.append(slot)
	for i in range(hotbar_slot_count):
		var slot = inventory_slot_prefab.instantiate() as InventorySlot
		if hotbar_grid != null:
			hotbar_grid.add_child(slot)
			slot.inventory_slot_id = item_slot_count + i
			slot.on_item_dropped.connect(_item_dropped_on_slot)
			slot.on_item_equipped.connect(_on_slot_equipped)
			slot.gui_input.connect(Callable(self, "_on_slot_gui_input").bind(slot))
			hotbar_slots.append(slot)

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode >= KEY_1 and event.keycode <= KEY_9:
		var index = int(event.keycode - KEY_1)
		_select_hotbar_slot(index)

func _select_hotbar_slot(index: int):
	if index < 0 or index >= hotbar_slots.size():
		return
	active_hotbar_index = index
	var slot = hotbar_slots[index]
	if slot.slot_data == null:
		return
	var item = slot.slot_data
	if item.equip_type == ItemData.EquipType.NONE:
		return
	if equipped_items.get(item.equip_type) == item:
		unequip_item(item.equip_type)
	else:
		_equip_hotbar_item(item)
	_update_all_slot_highlights()

func _equip_hotbar_item(item: ItemData):
	if item.equip_type == ItemData.EquipType.MAIN_HAND:
		if item.is_two_handed:
			unequip_item(ItemData.EquipType.MAIN_HAND)
			unequip_item(ItemData.EquipType.OFF_HAND)
			equipped_items[ItemData.EquipType.MAIN_HAND] = item
		else:
			equipped_items[ItemData.EquipType.MAIN_HAND] = item
	elif item.equip_type == ItemData.EquipType.OFF_HAND:
		var main_item = equipped_items.get(ItemData.EquipType.MAIN_HAND)
		if main_item != null and main_item.is_two_handed:
			return
		equipped_items[ItemData.EquipType.OFF_HAND] = item
	elif item.equip_type != ItemData.EquipType.NONE:
		equipped_items[item.equip_type] = item

func _on_slot_gui_input(event: InputEvent, slot: InventorySlot) -> void:
	if slot.slot_data == null:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_MIDDLE and slot.slot_data.current_stack > 1:
			_split_stack(slot)

func _split_stack(slot: InventorySlot):
	var total = slot.slot_data.current_stack
	if total <= 1:
		return

	var half = total / 2

	var new_stack_amount = half
	var remainder = total % 2
	if remainder != 0:
		new_stack_amount += 1

	var new_item = slot.slot_data.duplicate(true)
	new_item.current_stack = new_stack_amount

	slot.slot_data.current_stack = total - new_stack_amount

	_pickup_item(new_item)
	_update_all_slot_highlights()


func _item_dropped_on_slot(from_slot_id: int, to_slot_id: int):
	var from_slot = _get_slot_by_id(from_slot_id)
	var to_slot = _get_slot_by_id(to_slot_id)
	if from_slot == null or to_slot == null:
		return
	var from_item = from_slot.slot_data
	var to_item = to_slot.slot_data
	if from_item != null and to_item != null and from_item.item_name == to_item.item_name and from_item.max_stack_size > 1:
		var space_left = to_item.max_stack_size - to_item.current_stack
		var transfer_amount = min(space_left, from_item.current_stack)
		to_item.current_stack += transfer_amount
		from_item.current_stack -= transfer_amount
		to_slot._fill_slot(to_item, equipped_items.get(to_item.equip_type) == to_item)
		if from_item.current_stack <= 0:
			from_slot._fill_slot(null, false)
		else:
			from_slot._fill_slot(from_item, equipped_items.get(from_item.equip_type) == from_item)
	else:
		to_slot._fill_slot(from_item, from_item != null and equipped_items.get(from_item.equip_type) == from_item)
		from_slot._fill_slot(to_item, to_item != null and equipped_items.get(to_item.equip_type) == to_item)
	_update_all_slot_highlights()

func _on_slot_equipped(slot_id: int):
	var slot = _get_slot_by_id(slot_id)
	if slot == null or slot.slot_data == null:
		return
	var item = slot.slot_data
	if equipped_items.get(item.equip_type) == item:
		unequip_item(item.equip_type)
		_update_all_slot_highlights()
		return
	if item.equip_type == ItemData.EquipType.MAIN_HAND:
		if item.is_two_handed:
			unequip_item(ItemData.EquipType.MAIN_HAND)
			unequip_item(ItemData.EquipType.OFF_HAND)
			equipped_items[ItemData.EquipType.MAIN_HAND] = item
		else:
			equipped_items[ItemData.EquipType.MAIN_HAND] = item
	elif item.equip_type == ItemData.EquipType.OFF_HAND:
		var main_item = equipped_items.get(ItemData.EquipType.MAIN_HAND)
		if main_item != null and main_item.is_two_handed:
			return
		equipped_items[ItemData.EquipType.OFF_HAND] = item
	elif item.equip_type != ItemData.EquipType.NONE:
		equipped_items[item.equip_type] = item
	_update_all_slot_highlights()

func equip_item(item: ItemData):
	_on_slot_equipped(_get_slot_id_for_item(item))

func unequip_item(equip_type: int):
	var item = equipped_items.get(equip_type)
	if item == null:
		return
	var found_slot = false
	for slot in inventory_slots + hotbar_slots:
		if slot.slot_data == item:
			found_slot = true
			break
	if not found_slot:
		for slot in inventory_slots + hotbar_slots:
			if not slot.slot_filled:
				slot._fill_slot(item, false)
				break
	equipped_items[equip_type] = null
	_update_all_slot_highlights()

func _update_all_slot_highlights():
	for slot in inventory_slots + hotbar_slots:
		if slot.slot_data != null:
			slot._fill_slot(slot.slot_data, equipped_items.get(slot.slot_data.equip_type) == slot.slot_data)
		else:
			slot._fill_slot(null, false)

func _get_slot_id_for_item(item: ItemData) -> int:
	for slot in inventory_slots + hotbar_slots:
		if slot.slot_data == item:
			return slot.inventory_slot_id
	return -1

func _get_slot_by_id(slot_id: int) -> InventorySlot:
	for slot in inventory_slots + hotbar_slots:
		if slot.inventory_slot_id == slot_id:
			return slot
	return null

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data["Type"] == "Item"

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var slot = _get_slot_by_id(data["ID"])
	if slot == null or slot.slot_data == null:
		return
	if slot.slot_data.equip_type != ItemData.EquipType.NONE and equipped_items.get(slot.slot_data.equip_type) == slot.slot_data:
		unequip_item(slot.slot_data.equip_type)
	var dropped_item_data = slot.slot_data.duplicate(true)
	dropped_item_data.current_stack = slot.slot_data.current_stack
	var node = dropped_item_data.item_model_prefab.instantiate() as InteractableItem
	node.item_data = dropped_item_data
	player_body.get_parent().add_child(node)
	node.global_position = _get_world_mouse_position()
	slot._fill_slot(null, false)

func _pickup_item(item: ItemData):
	if item == null:
		return
	var all_slots = inventory_slots + hotbar_slots
	var remaining_stack = item.current_stack
	while remaining_stack > 0:
		var items_stacked = false
		for slot in all_slots:
			if slot.slot_filled and slot.slot_data.item_name == item.item_name and slot.slot_data.max_stack_size > 1:
				var space_left = slot.slot_data.max_stack_size - slot.slot_data.current_stack
				var add_amount = min(space_left, remaining_stack)
				if add_amount > 0:
					slot.slot_data.current_stack += add_amount
					remaining_stack -= add_amount
					items_stacked = true
					slot._fill_slot(slot.slot_data, equipped_items.get(slot.slot_data.equip_type) == slot.slot_data)
					if remaining_stack <= 0:
						return
		if items_stacked:
			continue
		var new_slot_found = false
		for slot in all_slots:
			if not slot.slot_filled:
				var copy = item.duplicate(true)
				copy.current_stack = min(item.max_stack_size, remaining_stack)
				slot._fill_slot(copy, equipped_items.get(copy.equip_type) == copy)
				remaining_stack -= copy.current_stack
				new_slot_found = true
				break
		if not new_slot_found and remaining_stack > 0:
			var dropped_item_data = item.duplicate(true)
			dropped_item_data.current_stack = remaining_stack
			var node = dropped_item_data.item_model_prefab.instantiate() as InteractableItem
			node.item_data = dropped_item_data
			player_body.get_parent().add_child(node)
			node.global_position = player_body.global_position + player_body.global_transform.basis.x * 2.0
			break

func pickup_interactable_item(interactable_item: InteractableItem):
	if interactable_item == null or interactable_item.item_data == null:
		return
	var item_data = interactable_item.item_data
	_pickup_item(item_data)
	interactable_item.queue_free()

func _get_world_mouse_position() -> Vector3:
	var mouse_pos = get_viewport().get_mouse_position()
	var cam = get_viewport().get_camera_3d()
	var start = cam.project_ray_origin(mouse_pos)
	var end = start + (cam.project_ray_normal(mouse_pos) * cam.global_position.distance_to(player_body.global_position) * 2.0)
	var space_state = player_body.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(start, end, collision_mask)
	var result = space_state.intersect_ray(query)
	if result:
		return result["position"] + Vector3(0, 0.5, 0)
	return start.lerp(end, 0.5) + Vector3(0, 0.5, 0)
