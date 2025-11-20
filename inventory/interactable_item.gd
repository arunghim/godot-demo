extends Node3D
class_name InteractableItem

@export var item_highlight_mesh: MeshInstance3D
@export var item_data: ItemData

func gain_focus():
	item_highlight_mesh.visible = true

func lose_focus():
	item_highlight_mesh.visible = false
