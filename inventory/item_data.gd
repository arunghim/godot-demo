extends Resource
class_name ItemData

enum EquipType { NONE, HEAD, CHEST, GLOVES, LEGS, BOOTS, MAIN_HAND, OFF_HAND, WAIST, BACK, NECK, FINGER }
enum WeaponType { NONE, SWORD, AXE, PICKAXE, BOW, MACE, HAMMER }
enum DamageType { NONE, PIERCE, SLASH, BLUNT }

@export var item_name: String
@export var item_description: String
@export var item_model_prefab: PackedScene
@export var icon: Texture2D
@export var equip_type: EquipType = EquipType.NONE
@export var weapon_type: WeaponType = WeaponType.NONE
@export var damage_type: DamageType = DamageType.NONE
@export var is_two_handed: bool = false
@export var stack_size: int = 1
