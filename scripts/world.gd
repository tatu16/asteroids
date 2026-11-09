extends Node2D

@onready var projectile_spawner: MultiplayerSpawner = $ProjectileSpawner
@onready var timer: Timer = $Timer
@onready var hud: CanvasLayer = $Hud
@onready var enemy_spawner = $EnemySpawner

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const UPGRADE_MENU: PackedScene = preload("res://scenes/menus/upgrade_menu.tscn")

var elapsed_time: int = 0
var is_paused: bool = false
var game_finished: bool = false

func _ready() -> void:
    GameManager.player_died.connect(_on_player_died)
    GameManager.player_levelup.connect(_on_player_levelup)
    GameManager.player_xp_changed.connect(_on_player_xp_changed)
    
    timer.timeout.connect(_on_timer_timeout)
    
    if multiplayer.is_server():
        spawn_player(1)
        for peer_id in multiplayer.get_peers():
            spawn_player(peer_id)
        start_game()
        
func start_game() -> void:
    if not multiplayer.is_server():
        return
        
    SaveManager.reset_run_stats()
        
    elapsed_time = 0
    is_paused = false
    
    enemy_spawner.update_difficulty(elapsed_time)
    enemy_spawner.start_spawning()
    
    update_timer.rpc(elapsed_time)
    timer.start()
    
func spawn_player(peer_id: int) -> void:
    var player = PLAYER_SCENE.instantiate() as Player
    player.character_data = GameManager.selected_character
    player.name = str(peer_id)
    player.set_multiplayer_authority(peer_id)
    player.projectile_spawner = projectile_spawner
    add_child(player)
    
func _on_timer_timeout() -> void:
    if not multiplayer.is_server():
        return
        
    elapsed_time += 1
    update_timer.rpc(elapsed_time)
    enemy_spawner.update_difficulty(elapsed_time)
    
@rpc("authority", "call_local", "reliable")
func update_timer(time: int) -> void:
    hud.update_time(time)
    
func pause_game() -> void:
    if not multiplayer.is_server() or is_paused:
        return
        
    is_paused = true
    timer.stop()
    enemy_spawner.stop_spawning()
    set_game_paused.rpc(true)
    
func continue_game() -> void:
    if not multiplayer.is_server() or not is_paused:
        return
        
    is_paused = false
    timer.start()
    enemy_spawner.start_spawning()
    set_game_paused.rpc(false)
    
@rpc("authority", "call_local", "reliable")
func set_game_paused(paused: bool) -> void:
    is_paused = paused
    
func end_game() -> void:
    if not multiplayer.is_server() or game_finished:
        return
       
    game_finished = true
    timer.stop()
    enemy_spawner.stop_spawning()
    for peer_id in SaveManager.run_stats.keys():
        SaveManager.add_run_stat(
            peer_id,
            SaveManager.Stat.TIME_SURVIVED,
            elapsed_time
        )
        var stats = SaveManager.get_run_stats(peer_id)
        if peer_id == 1:
            receive_run_stats(stats)
        else:
            receive_run_stats.rpc_id(peer_id, stats)
    GameManager.end_game()

@rpc("authority", "call_remote", "reliable")
func receive_run_stats(stats: Dictionary) -> void:
    if multiplayer.get_remote_sender_id() != 1:
        return
    SaveManager.add_finished_run(stats)

func _on_player_died(player: Player) -> void:
    if not multiplayer.is_server():
        return
        
    var peer_id = player.get_multiplayer_authority()
    SaveManager.add_run_stat(
        peer_id,
        SaveManager.Stat.PLAYERS_DIED
    )
    print("player died: ", player)

func _on_player_levelup(player: Player) -> void:
    if not multiplayer.is_server():
        return
        
    print("Player leveled up: ", player.name)
    pause_game()
    var peer_id = player.get_multiplayer_authority()
    SaveManager.add_run_stat(
        peer_id, 
        SaveManager.Stat.LEVEL_UP, 
        player.current_level
    )
    if peer_id == multiplayer.get_unique_id():
        show_upgrade_menu()
    else:
        rpc_id(peer_id, "show_upgrade_menu")

@rpc("authority", "call_remote", "reliable")
func show_upgrade_menu() -> void:
    var menu = UPGRADE_MENU.instantiate()
    hud.add_child(menu)
    menu.upgrade_finished.connect(_on_upgrade_finished)

func _on_upgrade_finished() -> void:
    if multiplayer.is_server():
        continue_game()
    else:
        request_continue_game.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func request_continue_game() -> void:
    if not multiplayer.is_server():
        return
    continue_game()

func _on_player_xp_changed(peer_id: int, current_xp: float, xp_required: float, level: int) -> void:
    if peer_id != multiplayer.get_unique_id():
        return
    print(SaveManager.get_run_stats(peer_id))
    hud.update_xp(current_xp, xp_required, level)
