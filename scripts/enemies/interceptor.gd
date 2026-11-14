extends Enemy

@export var explosion_radius = 75.0
@export var explosion_damage = 20.0

#TODO: add explosion effect
func die(attacker_peer_id: int, hit_direction: Vector2 = Vector2.ZERO) -> void:
    for player in get_tree().get_nodes_in_group("players"):
        player = player as Player
        var distance: float = global_position.distance_to(player.global_position)
        print(distance)
        if distance >= explosion_radius:
            continue
        player.take_damage(explosion_damage)
        
    super.die(attacker_peer_id, hit_direction)
