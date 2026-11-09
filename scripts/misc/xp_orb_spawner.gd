extends MultiplayerSpawner

const XP_ORB_SCENE: PackedScene = preload(
    "res://scenes/misc/xp_orb.tscn"
)

func _ready() -> void:
    spawn_function = _spawn_xp_orb
    
func spawn_xp_orb(xp_value: float, spawn_position: Vector2) -> void:
    if not multiplayer.is_server():
        return

    spawn({
        "xp_value": xp_value,
        "position": spawn_position
    })

func _spawn_xp_orb(data: Dictionary) -> Node:
    var orb = XP_ORB_SCENE.instantiate() as XPOrb
    orb.xp_value = data["xp_value"]
    orb.global_position = data["position"]
    return orb
