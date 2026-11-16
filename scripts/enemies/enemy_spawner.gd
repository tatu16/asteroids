
extends Node

@export var enemy_scenes: Array[PackedScene]
@export var multiplayer_spawner: MultiplayerSpawner
@export var projectile_spawner: MultiplayerSpawner
@export var xp_orb_spawner: MultiplayerSpawner
@export var powerup_spawner: MultiplayerSpawner
@export var enemies_container: Node2D

@export_group("Spawning")
@export var starting_spawn_interval: float = 3.0
@export var minimum_spawn_interval: float = 0.5
@export var spawn_interval_decrease: float = 0.35

@export_group("Spawn Batches")
@export var spawn_batch_interval: int = 240
@export var maximum_spawn_batch: int = 2

@export_group("Enemy Limit")
@export var starting_enemy_cap: int = 8
@export var enemy_cap_increase: int = 2
@export var enemy_cap_interval: int = 30
@export var maximum_enemy_cap: int = 100

@export_group("Difficulty")
@export var stat_scale_interval: float = 60.0
@export var hp_increase_per_interval: float = 0.15
@export var damage_increase_per_interval: float = 0.10
@export var speed_increase_per_interval: float = 0.05

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
    enemy.apply_difficulty_scaling(
        data.get("hp_multiplier", 1.0),
        data.get("damage_multiplier", 1.0),
        data.get("speed_multiplier", 1.0)
    )
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

    var player_count := _get_player_count()
    var intervals_passed = int(time / enemy_cap_interval)
    enemy_cap = mini(
        (starting_enemy_cap + intervals_passed * enemy_cap_increase)
        * player_count,
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
    
    var batch_multiplier := mini(
        1 + int(elapsed_time / maxi(spawn_batch_interval, 1)),
        maximum_spawn_batch
    )
    
    var available_slots := maxi(
        enemy_cap - alive_enemies.size(),
        0
    )
    
    var enemies_to_spawn := mini(
        _get_player_count() * batch_multiplier,
        available_slots
    )

    for _i in range(enemies_to_spawn):
        spawn_enemy()

func _remove_dead_enemies() -> void:
    alive_enemies = alive_enemies.filter(
        func(enemy): return is_instance_valid(enemy)
    )

func spawn_enemy() -> void:
    if enemy_scenes.is_empty():
        return

    var players = get_tree().get_nodes_in_group("players")
    var alive_players = players.filter(
        func(p): return is_instance_valid(p) and not (p as Player).is_dead
    )
    if alive_players.is_empty():
        return

    var target = alive_players.pick_random() as Node2D

    var offset = Vector2.RIGHT.rotated(randf() * TAU) * spawn_distance
    var spawn_position = target.global_position + offset
    
    var scene_index = randi_range(0, enemy_scenes.size() - 1)
    var difficulty_intervals := elapsed_time / maxf(stat_scale_interval, 0.001)
    var hp_multiplier := 1.0 + difficulty_intervals * hp_increase_per_interval
    var damage_multiplier := (
        1.0 + difficulty_intervals * damage_increase_per_interval
    )
    var speed_multiplier := (
        1.0 + difficulty_intervals * speed_increase_per_interval
    )
    multiplayer_spawner.spawn({
        "scene_index": scene_index,
        "position": enemies_container.to_local(spawn_position),
        "hp_multiplier": hp_multiplier,
        "damage_multiplier": damage_multiplier,
        "speed_multiplier": speed_multiplier
    })

func _get_player_count() -> int:
    var player_count := 0
    for group_name in ["players", "dead_players"]:
        for player in get_tree().get_nodes_in_group(group_name):
            if is_instance_valid(player) and not player.is_queued_for_deletion():
                player_count += 1
    return maxi(player_count, 1)
