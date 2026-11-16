extends Enemy

@export var explosion_radius = 75.0
@export var explosion_damage = 20.0

func apply_difficulty_scaling(
    hp_multiplier: float,
    damage_multiplier: float,
    speed_multiplier: float
) -> void:
    super.apply_difficulty_scaling(
        hp_multiplier,
        damage_multiplier,
        speed_multiplier
    )
    explosion_damage *= damage_multiplier

#TODO: add explosion effect
func die(attacker_peer_id: int, hit_direction: Vector2 = Vector2.ZERO) -> void:
    for player in get_tree().get_nodes_in_group("players"):
        var p := player as Player
        if p == null or p.is_dead:
            continue
        var distance: float = global_position.distance_to(p.global_position)
        print(distance)
        if distance >= explosion_radius:
            continue
        p.take_damage(explosion_damage)
        
    super.die(attacker_peer_id, hit_direction)
