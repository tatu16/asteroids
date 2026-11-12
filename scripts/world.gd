extends Node2D

@onready var projectile_spawner: MultiplayerSpawner = $ProjectileSpawner
@onready var timer: Timer = $Timer
@onready var hud: CanvasLayer = $Hud
@onready var enemy_spawner = $EnemySpawner

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const UPGRADE_MENU: PackedScene = preload("res://scenes/menus/upgrade_menu.tscn")
const GAME_OVER_MENU: PackedScene = preload("res://scenes/menus/game_over.tscn")
const PAUSE_MENU: PackedScene = preload("res://scenes/menus/pause_menu.tscn")

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

func _unhandled_input(event: InputEvent) -> void:
    if not game_finished:
        if event.is_action_pressed("pause_menu"):
            var pause_menu = hud.get_node_or_null("PauseMenu")
            if pause_menu != null:
                pause_menu.queue_free()
                if multiplayer.is_server():
                    continue_game()
                else:
                    request_continue_game.rpc_id(1)
                return
            if is_paused:
                return
            var menu = PAUSE_MENU.instantiate()
            menu.name = "PauseMenu"
            hud.add_child(menu)

            if multiplayer.is_server():
                pause_game()
            else:
                request_pause_game.rpc_id(1)
        
func start_game() -> void:
    if not multiplayer.is_server():
        return
        
    SaveManager.reset_run_stats()
    GameManager.reset()
        
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

@rpc("any_peer", "call_remote", "reliable")
func request_pause_game() -> void:
    if not multiplayer.is_server():
        return
    pause_game()
    
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
    for group_name in ["players", "enemies", "projectiles", "xp_orbs", "powerups"]:
        for gameplay_node in get_tree().get_nodes_in_group(group_name):
            if not is_instance_valid(gameplay_node):
                continue
            gameplay_node.process_mode = (
                Node.PROCESS_MODE_DISABLED
                if paused
                else Node.PROCESS_MODE_INHERIT
            )
    
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
        SaveManager.add_run_stat(
            peer_id,
            SaveManager.Stat.LONGEST_RUN,
            elapsed_time
        )
        var player = get_node_or_null(str(peer_id)) as Player
        if player != null:
            SaveManager.add_run_stat(
                peer_id,
                SaveManager.Stat.HIGHEST_LEVEL,
                player.current_level
            )
        var stats = SaveManager.get_run_stats(peer_id)
        if peer_id == 1:
            SaveManager.last_run_stats = stats.duplicate()
            receive_run_stats(stats)
        else:
            receive_run_stats.rpc_id(peer_id, stats)
    GameManager.end_game()
    show_game_over_menu.rpc()

@rpc("authority", "call_remote", "reliable")
func receive_run_stats(stats: Dictionary) -> void:
    if not multiplayer.is_server() and multiplayer.get_remote_sender_id() != 1:
        return
    SaveManager.last_run_stats = stats.duplicate()
    SaveManager.add_finished_run(stats)

func are_all_players_dead() -> bool:
    var players = get_tree().get_nodes_in_group("players")
    if players.is_empty():
        return false
        
    for player in players:
        if not player.is_dead:
            return false
            
    return true

func _on_player_died(player: Player) -> void:
    if not multiplayer.is_server():
        return
        
    var peer_id = player.get_multiplayer_authority()
    SaveManager.add_run_stat(
        peer_id,
        SaveManager.Stat.PLAYERS_DIED
    )
    print("player died: ", player)
    if are_all_players_dead():
        end_game()

@rpc("authority", "call_local", "reliable")
func show_game_over_menu() -> void:
    if hud.get_node_or_null("GameOverMenu"):
        return

    var menu = GAME_OVER_MENU.instantiate()
    menu.name = "GameOverMenu"
    hud.add_child(menu)
    
func _on_player_levelup(player: Player) -> void:
    if not multiplayer.is_server():
        return
        
    print("Player leveled up: ", player.name)
    pause_game()
    var peer_id = player.get_multiplayer_authority()
    SaveManager.add_run_stat(
        peer_id,
        SaveManager.Stat.LEVEL_UP
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
    hud.update_xp(current_xp, xp_required, level)
