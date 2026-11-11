extends Enemy

@export var grab_distance: float = 30.0

var grabbed_player: Player
var grab_player: bool = false

func attack_grabbed_player() -> void:
    var target := grabbed_player.global_transform.origin
    var direction := global_transform.origin.direction_to(target)
    velocity = direction * 999
    move_and_slide()
    attack_player(grabbed_player)

func _physics_process(_delta: float) -> void:
    if not multiplayer.is_server():
        return
        
    if grab_player:
        attack_grabbed_player()
        return

    var closest_player := get_closest_player() as Player
    if closest_player == null:
        return

    if global_position.distance_to(closest_player.global_position) > grab_distance:
        move_towards_player(closest_player)
        return
        
    grab_player = true
    grabbed_player = closest_player
