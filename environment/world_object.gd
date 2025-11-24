extends RigidBody3D
class_name WorldObject

@export var max_health: int = 1
@export var health: int = 1
@export var drop_scene: PackedScene
@export var drop_count: int = 1
@export var required_weapon_type: ItemData.WeaponType = ItemData.WeaponType.NONE

func _ready():
	health = max_health

func on_hit(weapon: ItemData):
	if weapon == null:
		return
	if required_weapon_type != ItemData.WeaponType.NONE and weapon.weapon_type != required_weapon_type:
		return
	health -= weapon.damage
	if health <= 0:
		_drop_items()
		queue_free()

func _drop_items():
	var drop_position = global_transform.origin
	for i in range(drop_count):
		var drop_instance = drop_scene.instantiate()
		drop_instance.global_transform.origin = drop_position + Vector3(randf()-0.5, 1, randf()-0.5)
		get_parent().add_child(drop_instance)
