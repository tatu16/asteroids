extends MultiplayerSpawner

@export var object_scenes: Array[PackedScene]
@export var wall_scene: PackedScene

@export_group("Object spawning")
@export var spawn_interval: float = 8.0
@export var maximum_objects: int = 20
@export var minimum_group_size: int = 2
@export var maximum_group_size: int = 4
@export var minimum_player_distance: float = 180.0
@export var xp_orb_spawner: MultiplayerSpawner
@export var powerup_spawner: MultiplayerSpawner

@export_group("Arena")
@export var arena_size := Vector2(1920.0, 1080.0)
@export var wall_thickness: float = 64.0

@onready var spawn_timer: Timer = $SpawnTimer

var alive_objects: Array[Node] = []

func _ready() -> void:
    spawn_function = _spawn_object
    spawn_timer.timeout.connect(_on_spawn_timer_timeout)

    if not multiplayer.is_server():
        return

    _spawn_boundary_walls()
    spawn_timer.wait_time = spawn_interval
    spawn_timer.start()

func _spawn_object(data: Dictionary) -> Node:
    var scene: PackedScene
    if data["kind"] == "wall":
        scene = wall_scene
    else:
        var scene_index: int = data["scene_index"]
        scene = object_scenes[scene_index]

    var object := scene.instantiate() as Node2D
    object.position = data["position"]
    if data["kind"] == "wall":
        object.set("arena_size", data["arena_size"])
    object.add_to_group("objects")

    if data["kind"] == "object" and multiplayer.is_server():
        alive_objects.append(object)
        object.tree_exited.connect(
            func(): alive_objects.erase(object)
        )
        object.xp_orb_spawner = xp_orb_spawner
        object.powerup_spawner = powerup_spawner

    return object

func _on_spawn_timer_timeout() -> void:
    if not multiplayer.is_server():
        return

    _remove_dead_objects()
    var free_slots := maximum_objects - alive_objects.size()
    if free_slots <= 0 or object_scenes.is_empty():
        return

    var group_size := mini(
        randi_range(minimum_group_size, maximum_group_size),
        free_slots
    )
    var center := _random_position_away_from_players()
    for index in group_size:
        var position := center + Vector2(
            randf_range(-80.0, 80.0),
            randf_range(-80.0, 80.0)
        )
        spawn({
            "kind": "object",
            "scene_index": randi_range(0, object_scenes.size() - 1),
            "position": position
        })

func _spawn_boundary_walls() -> void:
    if wall_scene == null:
        push_error("ObjectSpawner requires a wall scene.")
        return

    spawn({
        "kind": "wall",
        "position": Vector2.ZERO,
        "arena_size": arena_size
    })

func _random_position_away_from_players() -> Vector2:
    var players := get_tree().get_nodes_in_group("players")
    for attempt in 20:
        var position := Vector2(
            randf_range(-arena_size.x / 2.0 + wall_thickness, arena_size.x / 2.0 - wall_thickness),
            randf_range(-arena_size.y / 2.0 + wall_thickness, arena_size.y / 2.0 - wall_thickness)
        )
        var is_clear := true
        for player in players:
            if player is Node2D and player.position.distance_to(position) < minimum_player_distance:
                is_clear = false
                break
        if is_clear:
            return position

    return Vector2.ZERO

func _remove_dead_objects() -> void:
    alive_objects = alive_objects.filter(
        func(object): return is_instance_valid(object)
    )

func start_spawning() -> void:
    if not multiplayer.is_server():
        return
    spawn_timer.start()

func stop_spawning() -> void:
    if not multiplayer.is_server():
        return
    spawn_timer.stop()
