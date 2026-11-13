class_name WeaponData extends Resource

enum FireMode {
    SINGLE,
    SPREAD,
    BURST,
    RAPID
}

@export_group("Identity")
@export var weapon_name: String = "Unnamed"
@export var projectile_scene: PackedScene

@export_group("Combat")
@export var damage: float = 10.0
@export var fire_rate: float = 5.0
@export var projectile_speed: float = 600.0
@export var projectile_acceleration: float = 0.0
@export var projectile_max_speed: float = 0.0

@export_group("Projectile")
@export var projectile_count: int = 1
@export var spread: float = 10.0
@export var fire_mode: FireMode = FireMode.SINGLE
