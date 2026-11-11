extends Enemy

@export var wave_projectile_scene: PackedScene = preload("res://scenes/projectiles/wave.tscn")
@export var wave_projectile_speed: float = 180.0
@export var wave_projectile_acceleration: float = 0.0
@export var wave_projectile_max_speed: float = 0.0
@export var wave_projectile_damage: float = 12.0
@export var projectile_distance: float = 120.0

func _physics_process(_delta: float) -> void:
    if not multiplayer.is_server():
        return

    var closest_player := get_closest_player() as Player
    if closest_player == null:
        return

    if global_position.distance_to(closest_player.global_position) > projectile_distance:
        move_towards_player(closest_player)
        return

    velocity = Vector2.ZERO
    move_and_slide()
    shoot_wave_at_player(closest_player)

func shoot_wave_at_player(player: Player) -> void:
    if not can_attack or projectile_spawner == null:
        return

    can_attack = false
    play_attack_animation()
    var projectile_path := wave_projectile_scene.resource_path
    var projectile_data := {
        "position": global_position,
        "direction": global_position.direction_to(player.global_position),
        "speed": wave_projectile_speed,
        "damage": wave_projectile_damage,
        "projectile_path": projectile_path,
        "shooter_is_enemy": true,
        "shooter_path": get_path()
    }
    if wave_projectile_acceleration != 0.0:
        projectile_data["acceleration"] = wave_projectile_acceleration
    if wave_projectile_max_speed > 0.0:
        projectile_data["max_speed"] = wave_projectile_max_speed
    projectile_spawner.spawn(projectile_data)

    await get_tree().create_timer(attack_cooldown).timeout
    can_attack = true
    play_default_animation()
