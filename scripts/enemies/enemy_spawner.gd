
extends Node

@export var enemy_scenes: Array[PackedScene]
@export var multiplayer_spawner: MultiplayerSpawner
@export var projectile_spawner: MultiplayerSpawner
@export var xp_orb_spawner: MultiplayerSpawner
@export var powerup_spawner: MultiplayerSpawner
@export var enemies_container: Node2D

@export_group("Spawning")
@export var starting_spawn_interval: float = 5.0
@export var minimum_spawn_interval: float = 0.8
@export var spawn_interval_decrease: float = 0.20

@export_group("Enemy Limit")
@export var starting_enemy_cap: int = 5
@export var enemy_cap_increase: int = 2
@export var enemy_cap_interval: int = 60
@export var maximum_enemy_cap: int = 40

@export_group("Spawn Position")
@export var spawn_distance: float = 900.0

@onready var spawn_timer: Timer = $SpawnTimer

var elapsed_time: int = 0
var alive_enemies: Array[Node] = []
var enemy_cap: int = 5

func _ready() -> void:
    spawn_timer.timeout.connect(_on_spawn_timer_timeout)
    if multiplayer_spawner == null:
        push_error("MultiplayerSpawner not found!")
        return
        
    multiplayer_spawner.spawn_function = _spawn_enemy_replica
    if multiplayer.is_server():
        enemy_cap = starting_enemy_cap
        spawn_timer.wait_time = starting_spawn_interval

func _spawn_enemy_replica(data: Dictionary) -> Node:
    var scene_index: int = data["scene_index"]
    var enemy = enemy_scenes[scene_index].instantiate() as Enemy
    
    enemy.set_multiplayer_authority(1)
    enemy.position = data["position"]
    enemy.projectile_spawner = projectile_spawner
    enemy.xp_orb_spawner = xp_orb_spawner
    enemy.powerup_spawner = powerup_spawner
    if multiplayer.is_server():
        alive_enemies.append(enemy)
        enemy.tree_exited.connect(
            func(): alive_enemies.erase(enemy)
        )

    return enemy

func start_spawning() -> void:
    if not multiplayer.is_server():
        return
    spawn_timer.start()

func stop_spawning() -> void:
    if not multiplayer.is_server():
        return
    spawn_timer.stop()

func update_difficulty(time: int) -> void:
    if not multiplayer.is_server():
        return
    elapsed_time = time

    var intervals_passed = int(time / enemy_cap_interval)
    enemy_cap = mini(
        starting_enemy_cap + intervals_passed * enemy_cap_increase,
        maximum_enemy_cap
    )

    spawn_timer.wait_time = maxf(
        starting_spawn_interval - time / 60.0 * spawn_interval_decrease,
        minimum_spawn_interval
    )

func _on_spawn_timer_timeout() -> void:
    if not multiplayer.is_server():
        return

    _remove_dead_enemies()
    if alive_enemies.size() >= enemy_cap:
        return

    spawn_enemy()

func _remove_dead_enemies() -> void:
    alive_enemies = alive_enemies.filter(
        func(enemy): return is_instance_valid(enemy)
    )

func spawn_enemy() -> void:
    if enemy_scenes.is_empty():
        return

    var players = get_tree().get_nodes_in_group("players")
    if players.is_empty():
        return

    var target = players.pick_random() as Node2D

    var offset = Vector2.RIGHT.rotated(randf() * TAU) * spawn_distance
    var spawn_position = target.global_position + offset
    
    var scene_index = randi_range(0, enemy_scenes.size() - 1)
    multiplayer_spawner.spawn({
        "scene_index": scene_index,
        "position": enemies_container.to_local(spawn_position)
    })
