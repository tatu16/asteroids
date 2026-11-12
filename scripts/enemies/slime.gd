extends Enemy

@export var wave_projectile_scene: PackedScene = preload("res://scenes/projectiles/wave.tscn")
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
        "direction": Vector2.ZERO,
        "speed": 0.0,
        "damage": wave_projectile_damage,
        "projectile_path": projectile_path,
        "shooter_is_enemy": true,
        "shooter_path": get_path()
    }
    projectile_spawner.spawn(projectile_data)

    await get_tree().create_timer(attack_cooldown).timeout
    can_attack = true
    play_default_animation()
