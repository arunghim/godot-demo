extends Area3D

@export var item_types: Array[ItemData] = []
var nearby_entities: Array[InteractableItem] = []
signal on_item_picked_up(item)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		pickup_nearest_item()


func pickup_nearest_item():
	var nearest_item: InteractableItem = null
	var nearest_item_distance: float = INF

	for item in nearby_entities:
		if item.global_position.distance_to(global_position) < nearest_item_distance:
			nearest_item_distance = item.global_position.distance_to(global_position)
			nearest_item = item

	if nearest_item != null:
		if nearest_item.item_data != null:
			on_item_picked_up.emit(nearest_item.item_data)
		else:
			var item_prefab = nearest_item.scene_file_path
			for i in range(item_types.size()):
				if (
					item_types[i].item_model_prefab != null
					and item_types[i].item_model_prefab.resource_path == item_prefab
				):
					on_item_picked_up.emit(item_types[i])
					break

		nearest_item.queue_free()
		nearby_entities.remove_at(nearby_entities.find(nearest_item))
	else:
		printerr("No valid nearest item found.")


func on_object_entered_area(entity: Node3D):
	if entity is InteractableItem:
		entity.gain_focus()
		nearby_entities.append(entity)


func on_object_exited_area(entity: Node3D):
	if entity is InteractableItem and nearby_entities.has(entity):
		entity.lose_focus()
		nearby_entities.remove_at(nearby_entities.find(entity))
