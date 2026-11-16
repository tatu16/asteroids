class_name PowerupSpawner
extends MultiplayerSpawner

func _ready() -> void:
    spawn_function = _spawn_powerup
    
func spawn_powerup(scene: PackedScene, spawn_position: Vector2) -> void:
    if not multiplayer.is_server():
        return
    if scene == null:
        return

    call_deferred(
        "_spawn_powerup_deferred",
        scene,
        spawn_position
    )

func _spawn_powerup_deferred(
    scene: PackedScene,
    spawn_position: Vector2
) -> void:
    spawn({
        "scene_path": scene.resource_path,
        "position": spawn_position
    })
    
func _spawn_powerup(data: Dictionary) -> Node:
    var scene := load(data["scene_path"]) as PackedScene
    if scene == null:
        push_error("Could not load power-up scene")
        return null

    var powerup = scene.instantiate() as PowerUp
    powerup.position = data["position"]
    return powerup
