class_name Weapon
extends Node

var weapon_data: WeaponData
var owner_character: Character
var projectile_spawner: MultiplayerSpawner

var cooldown: float = 0.0
var attack_speed_multiplier: float = 1.0
var projectile_count_bonus: int = 0
var damage_multiplier: float = 1.0

func _process(delta: float) -> void:
    cooldown = maxf(cooldown - delta, 0.0)

func try_fire(direction: Vector2) -> void:
    if cooldown > 0.0:
        return
    if weapon_data == null:
        return
    if weapon_data.fire_rate <= 0.0:
        return
        
    shoot(direction.normalized())
    cooldown = 1.0 / (weapon_data.fire_rate * attack_speed_multiplier)

func shoot(direction: Vector2) -> void:
    if not multiplayer.is_server():
        return
        
    if weapon_data.projectile_scene == null:
        push_error("weapon_data.projectile_scene == null")
        return

    if projectile_spawner == null:
        push_error("ProjectileSpawner not assigned!")
        return
        
    var projectile_count := weapon_data.projectile_count + projectile_count_bonus
    for i in projectile_count:
        var spread_angle := 0.0
        if i > 0:
            var extra_projectiles := projectile_count - 1
            var spread_position := float(i - 1) / maxi(extra_projectiles - 1, 1)
            spread_angle = deg_to_rad(
                lerpf(-weapon_data.spread, weapon_data.spread, spread_position)
            )
        var shot_direction = direction.rotated(spread_angle)
        var peer_id = owner_character.get_multiplayer_authority()
        
        var projectile_data := {
            "position": owner_character.global_position,
            "direction": shot_direction,
            "speed": weapon_data.projectile_speed,
            "damage": weapon_data.damage * damage_multiplier,
            "projectile_path": weapon_data.projectile_scene.resource_path,
            "shooter_peer_id": peer_id,
            "shooter_is_enemy": false
        }
        if weapon_data.projectile_acceleration != 0.0:
            projectile_data["acceleration"] = weapon_data.projectile_acceleration
        if weapon_data.projectile_max_speed > 0.0:
            projectile_data["max_speed"] = weapon_data.projectile_max_speed
        projectile_spawner.spawn(projectile_data)
        
        SaveManager.add_run_stat(
            peer_id, 
            SaveManager.Stat.PROJECTILES_SHOT, 
            1
        )
