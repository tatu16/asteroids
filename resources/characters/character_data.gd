class_name CharacterData
extends Resource

@export_group("Identity")
@export var character_name: String = "Unnamed"
@export var portrait: Texture2D

@export_group("Visuals")
@export var ship_texture: Texture2D
@export var ability_ship_texture: Texture2D
@export var ship_region: Rect2 = Rect2(8, 11, 110, 132)

@export_group("Stats")
@export var max_hp: float = 100.0
@export var max_ability: float = 100.0
@export var armor: int = 5
@export var ability_multiplier: float = 1.2
@export var ability_recovery: float = 20.0
@export var ability_drain: float = 35.0

@export_group("Movement")
@export var rotation_speed: float = 3.0
@export var linear_drag: float = 100.0
@export var angular_drag: float = 2.0
@export var max_speed: float = 300.0
@export var acceleration: float = 200.0

@export_group("Weapons")
@export var default_weapon: WeaponData

@export_group("Ability")
@export var abilities: Array[PackedScene] = []
