extends Enemy

@export var player_close_distance: float = 200.0

func _ready() -> void:
    super._ready()
    stop_moving_while_shooting = false

# Watcher tries to move away from players that are too close
func move_towards_player(player: Player) -> void:
    var flee_direction: Vector2 = Vector2.ZERO
    var found_close_player: bool = false

    for candidate in get_tree().get_nodes_in_group("players"):
        if not (candidate is Player) or (candidate as Player).is_dead:
            continue

        var away_direction: Vector2 = global_position - candidate.global_position
        var distance := away_direction.length()
        if distance >= player_close_distance:
            continue

        found_close_player = true
        if distance > 0.001:
            var weight := 1.0 - distance / player_close_distance
            flee_direction += away_direction.normalized() * weight

    if found_close_player:
        if flee_direction.length_squared() < 0.0001:
            flee_direction = global_position - player.global_position
        if flee_direction.length_squared() < 0.0001:
            flee_direction = Vector2.RIGHT

        velocity = flee_direction.normalized() * move_speed
        move_and_slide()
    else:
        super.move_towards_player(player)
