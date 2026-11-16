extends Node2D

@onready var players_container: Node2D = $Players
@onready var timer: Timer = $Timer
@onready var hud: CanvasLayer = $Hud
@onready var projectile_spawner: MultiplayerSpawner = $ProjectileSpawner
@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner
@onready var enemy_spawner = $EnemySpawner
@onready var object_spawner = $ObjectSpawner

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const UPGRADE_MENU: PackedScene = preload("res://scenes/menus/upgrade_menu.tscn")
const GAME_OVER_MENU: PackedScene = preload("res://scenes/menus/game_over.tscn")
const PAUSE_MENU: PackedScene = preload("res://scenes/menus/pause_menu.tscn")

var elapsed_time: int = 0
var is_paused: bool = false
var game_finished: bool = false
var pending_upgrades: Dictionary = {}

@export var respawn_time: float = 20.0

func _ready() -> void:
    add_to_group("world")
    
    player_spawner.spawn_function = _spawn_player_replica
    
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    
    GameManager.player_died.connect(_on_player_died)
    GameManager.player_levelup.connect(_on_player_levelup)
    GameManager.player_xp_changed.connect(_on_player_xp_changed)
    
    timer.timeout.connect(_on_timer_timeout)
    
    if multiplayer.is_server():
        spawn_player(1)
        for peer_id in multiplayer.get_peers():
            spawn_player(peer_id)
        start_game()
    else:
        call_deferred("_request_join_game")

func _spawn_player_replica(data: Dictionary) -> Node:
    var peer_id: int = data["peer_id"]
    var character_path: String = data.get("character_path", "")
    
    var player = PLAYER_SCENE.instantiate() as Player
    player.name = str(peer_id)
    player.set_multiplayer_authority(peer_id)
    player.projectile_spawner = projectile_spawner
    
    var char_data: CharacterData = null
    if not character_path.is_empty() and ResourceLoader.exists(character_path):
        char_data = load(character_path) as CharacterData
    
    if char_data == null:
        char_data = GameManager.selected_character
    
    player.character_data = char_data
    
    return player

func get_player(peer_id: int) -> Player:
    if players_container != null:
        return players_container.get_node_or_null(str(peer_id)) as Player
    return get_node_or_null(str(peer_id)) as Player

func _on_peer_connected(peer_id: int) -> void:
    print(
        "Peer connected | Local ID: ",
        multiplayer.get_unique_id(),
        " | Server: ",
        multiplayer.is_server(),
        " | Connected peer: ",
        peer_id
    )

func _on_peer_disconnected(peer_id: int) -> void:
    if not multiplayer.is_server():
        return
        
    print("Player disconnect: ", peer_id)
    var player := get_player(peer_id)
    if player != null and is_instance_valid(player):
        player.remove_from_group("players")
        player.remove_from_group("dead_players")
        player.is_dead = true
        player.queue_free()
        
    pending_upgrades.erase(peer_id)
    if is_paused and pending_upgrades.is_empty():
        continue_game()

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
    pending_upgrades.clear()
    
    enemy_spawner.update_difficulty(elapsed_time)
    enemy_spawner.start_spawning()
    
    update_timer.rpc(elapsed_time)
    timer.start()
    
func spawn_player(peer_id: int) -> void:
    if get_player(peer_id) != null:
        return
        
    var character_path := ""
    if Lobby.players.has(peer_id) and Lobby.players[peer_id].has("character_path"):
        character_path = Lobby.players[peer_id]["character_path"]
    elif peer_id == 1 and GameManager.selected_character != null:
        character_path = GameManager.selected_character.resource_path
    elif GameManager.selected_character != null:
        character_path = GameManager.selected_character.resource_path

    var spawn_data := {
        "peer_id": peer_id,
        "character_path": character_path
    }
    player_spawner.spawn(spawn_data)
    
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
    object_spawner.stop_spawning()
    set_game_paused.rpc(true)

@rpc("any_peer", "call_remote", "reliable")
func request_pause_game() -> void:
    if not multiplayer.is_server():
        return
    pause_game()
    
func continue_game() -> void:
    if not multiplayer.is_server() or not is_paused:
        return
    
    # prevent continuing while another player selecting upgrade
    if not pending_upgrades.is_empty():
        return
        
    is_paused = false
    timer.start()
    enemy_spawner.start_spawning()
    object_spawner.start_spawning()
    set_game_paused.rpc(false)
    
@rpc("authority", "call_local", "reliable")
func set_game_paused(paused: bool) -> void:
    is_paused = paused
    for group_name in ["players", "dead_players", "enemies", "projectiles", "xp_orbs", "powerups"]:
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
        var player = get_player(peer_id)
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
    var all_player_nodes := []
    if players_container != null:
        all_player_nodes = players_container.get_children()
    else:
        all_player_nodes = get_tree().get_nodes_in_group("dead_players") + get_tree().get_nodes_in_group("players")
        
    if all_player_nodes.is_empty():
        return false
        
    return get_tree().get_nodes_in_group("players").is_empty()

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
        return
        
    start_player_respawn(peer_id)

func start_player_respawn(peer_id: int) -> void:
    if not multiplayer.is_server():
        return
        
    if peer_id == multiplayer.get_unique_id():
        notify_respawn_timer(respawn_time)
    else:
        notify_respawn_timer.rpc_id(peer_id, respawn_time)
        
    await get_tree().create_timer(respawn_time, false).timeout
    
    if game_finished:
        return
        
    if are_all_players_dead():
        return
        
    var player = get_player(peer_id)
    if player == null or not is_instance_valid(player):
        return
        
    var alive_players: Array[Node] = get_tree().get_nodes_in_group("players")
    var spawn_pos := Vector2.ZERO
    if not alive_players.is_empty():
        var buddy := alive_players.pick_random() as Node2D
        if buddy != null:
            spawn_pos = buddy.global_position + Vector2.RIGHT.rotated(randf() * TAU) * 120.0
            
    server_respawn_player.rpc(peer_id, spawn_pos)

@rpc("authority", "call_local", "reliable")
func notify_respawn_timer(duration: float) -> void:
    var my_id = multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1
    var my_player = get_player(my_id)
    if my_player != null and is_instance_valid(my_player) and my_player.is_multiplayer_authority():
        my_player.start_respawn_countdown(duration)

@rpc("authority", "call_local", "reliable")
func server_respawn_player(peer_id: int, spawn_pos: Vector2) -> void:
    var player = get_player(peer_id)
    if player != null and is_instance_valid(player):
        player.respawn(spawn_pos)

@rpc("authority", "call_local", "reliable")
func show_game_over_menu() -> void:
    if hud != null:
        hud.hide_spectator_overlay()
    if hud.get_node_or_null("GameOverMenu"):
        return

    var menu = GAME_OVER_MENU.instantiate()
    menu.name = "GameOverMenu"
    hud.add_child(menu)
    
func _on_player_levelup(player: Player) -> void:
    if not multiplayer.is_server():
        return
        
    var peer_id = player.get_multiplayer_authority()
    pending_upgrades[peer_id] = pending_upgrades.get(peer_id, 0) + 1
    print("Player leveled up: ", player.name)
    SaveManager.add_run_stat(
        peer_id,
        SaveManager.Stat.LEVEL_UP
    )
    pause_game()
    if pending_upgrades[peer_id] > 1:
        return
    if peer_id == multiplayer.get_unique_id():
        show_upgrade_menu()
    else:
        rpc_id(peer_id, "show_upgrade_menu")

@rpc("authority", "call_remote", "reliable")
func show_upgrade_menu() -> void:
    var existing_menu = hud.get_node_or_null("UpgradeMenu")
    if existing_menu != null:
        if existing_menu.is_queued_for_deletion():
            await get_tree().process_frame
            show_upgrade_menu()
        return
    var menu = UPGRADE_MENU.instantiate()
    menu.name = "UpgradeMenu"
    hud.add_child(menu)
    menu.upgrade_finished.connect(_on_upgrade_finished)

func _show_upgrade_menu_for_peer(peer_id: int) -> void:
    if peer_id == multiplayer.get_unique_id():
        show_upgrade_menu()
    else:
        rpc_id(peer_id, "show_upgrade_menu")

func _on_upgrade_finished() -> void:
    pass

@rpc("any_peer", "reliable")
func request_upgrade(player_path: NodePath, upgrade_id: String) -> void:
    if not multiplayer.is_server():
        return
    var peer_id := multiplayer.get_remote_sender_id()
    if peer_id == 0:
        peer_id = multiplayer.get_unique_id()
    var player := get_node_or_null(player_path) as Player
    if player == null:
        player = get_player(peer_id)
    if player == null or player.get_multiplayer_authority() != peer_id:
        return
    if upgrade_id not in [
        "attack_speed",
        "projectile_count",
        "damage",
        "max_hp",
        "boost",
    ]:
        push_error("Unknown upgrade requested: " + upgrade_id)
        return
    if upgrade_id == "boost" and not player.supports_upgrade(upgrade_id):
        push_error("Upgrade is not available for player: " + upgrade_id)
        return
    if not player.can_upgrade(upgrade_id):
        push_error("Upgrade is already at maximum level: " + upgrade_id)
        return
    player.apply_upgrade(upgrade_id)
    sync_player_upgrade.rpc(player_path, upgrade_id)
    pending_upgrades[peer_id] -= 1
    if pending_upgrades[peer_id] > 0:
        call_deferred("_show_upgrade_menu_for_peer", peer_id)
    else:
        pending_upgrades.erase(peer_id)
        if pending_upgrades.is_empty():
            continue_game()

@rpc("authority", "call_local", "reliable")
func sync_player_upgrade(player_path: NodePath, upgrade_id: String) -> void:
    if multiplayer.is_server():
        return
    var player := get_node_or_null(player_path) as Player
    if player == null and players_container != null:
        var player_node_name = str(player_path).get_file()
        player = players_container.get_node_or_null(player_node_name) as Player
    if player == null:
        return
    player.apply_upgrade(upgrade_id)

@rpc("any_peer", "call_remote", "reliable")
func request_continue_game() -> void:
    if not multiplayer.is_server():
        return
        
    # Allow continue from peer that is in the same lobby
    var sender_id := multiplayer.get_remote_sender_id()
    if not Lobby.players.has(sender_id):
        return
        
    continue_game()

func _on_player_xp_changed(peer_id: int, current_xp: float, xp_required: float, level: int) -> void:
    if peer_id != multiplayer.get_unique_id():
        return
    hud.update_xp(current_xp, xp_required, level)

func exit_game() -> void:
    if multiplayer.is_server():
        # only save if the game has not ended already
        if not game_finished:
            # save host's stats
            var host_stats = SaveManager.get_run_stats(1)
            if not host_stats.is_empty():
                SaveManager.add_finished_run(host_stats)
            
            # send stats to peers
            for peer_id in multiplayer.get_peers():
                var stats = SaveManager.get_run_stats(peer_id)
                if not stats.is_empty():
                    receive_run_stats.rpc_id(peer_id, stats)
        await Lobby.leave_lobby()
    else:
        request_exit_game.rpc_id(1)
    
@rpc("any_peer", "reliable")
func request_exit_game() -> void:
    if not multiplayer.is_server():
        return

    var peer_id = multiplayer.get_remote_sender_id()
    # don't save twice if the game is already ended
    if not game_finished:
        var stats = SaveManager.get_run_stats(peer_id)
        if not stats.is_empty():
            receive_run_stats.rpc_id(peer_id, stats)

    _client_leave_game.rpc_id(peer_id)


@rpc("authority", "call_remote", "reliable")
func _client_leave_game() -> void:
    Lobby.remove_multiplayer_peer()
    Lobby.server_disconnected.emit()

func _request_join_game() -> void:
    if not multiplayer.has_multiplayer_peer():
        return
    if multiplayer.has_multiplayer_peer():
        request_join_game.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func request_join_game() -> void:
    if not multiplayer.is_server():
        return

    # wait for lobby to register player
    var peer_id := multiplayer.get_remote_sender_id()
    for i in range(120):
        if Lobby.players.has(peer_id):
            break
        await get_tree().process_frame

    if not Lobby.players.has(peer_id):
        print("join failed: player no peer_id")
        return
    
    if Lobby.players[peer_id].get("character_path", "").is_empty():
        print("no character selected")
        return

    if get_player(peer_id) != null:
        print("player already exists")
        return
        
    spawn_player(peer_id)
    
    # synchronize game state
    update_timer.rpc_id(peer_id, elapsed_time)
    set_game_paused.rpc_id(peer_id, is_paused)
