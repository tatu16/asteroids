extends Enemy

@export var grab_distance: float = 30.0
@export var grab_duration: float = 1.0

var grabbed_player: Player
var grab_player: bool = false
var grab_time_left: float = 0.0
var grab_offset := Vector2.ZERO

func attack_grabbed_player(delta: float) -> void:
    if not is_instance_valid(grabbed_player) or grabbed_player.is_dead:
        grab_player = false
        grabbed_player = null
        return

    grab_time_left = maxf(grab_time_left - delta, 0.0)
    if grab_time_left <= 0.0:
        grab_player = false
        grabbed_player = null
        return

    global_position = grabbed_player.global_position + grab_offset
    velocity = Vector2.ZERO
    attack_player(grabbed_player)

func _physics_process(delta: float) -> void:
    if not multiplayer.is_server():
        return
        
    if grab_player:
        attack_grabbed_player(delta)
        return

    var closest_player := get_closest_player() as Player
    if closest_player == null:
        return

    if global_position.distance_to(closest_player.global_position) > grab_distance:
        move_towards_player(closest_player)
        return
        
    grab_player = true
    grabbed_player = closest_player
    grab_time_left = grab_duration
    grab_offset = global_position - closest_player.global_position
