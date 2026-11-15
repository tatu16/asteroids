extends Node

signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

const DEFAULT_PORT = 7000
const DEFAULT_SERVER_IP = "127.0.0.1"
const MAX_CONNECTIONS = 20

var players = {} # contains player's unique IDs
var player_info = {"name": "Name"}
var players_loaded = 0
var current_port: int = DEFAULT_PORT

func get_local_ip() -> String:
    for address in IP.get_local_addresses():
        if address.count(".") == 3 and not address.begins_with("127."):
            return address
    return DEFAULT_SERVER_IP

func _ready():
    multiplayer.peer_connected.connect(_on_player_connected)
    multiplayer.peer_disconnected.connect(_on_player_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_ok)
    multiplayer.connection_failed.connect(_on_connected_fail)
    multiplayer.server_disconnected.connect(_on_server_disconnected)

    server_disconnected.connect(_return_to_menu)

func join_game(address = "", port = DEFAULT_PORT):
    if address.is_empty():
        address = DEFAULT_SERVER_IP
        
    var peer = ENetMultiplayerPeer.new()
    var error = peer.create_client(address, int(port))
    if error != OK:
        print("Failed to create client: ", error)
        return error
        
    multiplayer.multiplayer_peer = peer
    
    print("Attempting to connect to %s:%s" % [address, port])
    return OK

func create_game():
    var peer: ENetMultiplayerPeer
    var port: int
    var error: Error = ERR_CANT_CREATE

    for attempt in 100:
        peer = ENetMultiplayerPeer.new()
        port = randi_range(10000, 50000)
        error = peer.create_server(port, MAX_CONNECTIONS)
        if error == OK:
            break
        print("Port %s is unavailable, retrying" % port)

    if error != OK:
        print("Failed to create server after 100 attempts: ", error)
        return error

    current_port = port
    multiplayer.multiplayer_peer = peer
    players[1] = player_info.duplicate()
    player_connected.emit(1, player_info)
    print("created a game to port = %s" % port)
    return OK

func set_player_character(char_path: String) -> void:
    player_info["character_path"] = char_path
    var my_id = multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1
    if not players.has(my_id):
        players[my_id] = player_info.duplicate()
    players[my_id]["character_path"] = char_path
    if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
        if multiplayer.is_server():
            _update_player_character.rpc(char_path)
        else:
            _update_player_character.rpc_id(1, char_path)

@rpc("any_peer", "reliable")
func _update_player_character(char_path: String) -> void:
    var sender_id = multiplayer.get_remote_sender_id()
    if sender_id == 0:
        sender_id = multiplayer.get_unique_id()
    if not players.has(sender_id):
        players[sender_id] = {}
    players[sender_id]["character_path"] = char_path

func remove_multiplayer_peer() -> void:
    if multiplayer.has_multiplayer_peer():
        multiplayer.multiplayer_peer.close()
        
    multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
    players.clear()
    players_loaded = 0

@rpc("call_local", "reliable")
func load_game(game_scene_path):
    get_tree().change_scene_to_file(game_scene_path)

@rpc("any_peer", "call_local", "reliable")
func player_loaded():
    if multiplayer.is_server():
        players_loaded += 1
        if players_loaded == players.size():
            $/root/Game.start_game()
            players_loaded = 0

@rpc("any_peer", "reliable")
func _register_player(new_player_info):
    var new_player_id = multiplayer.get_remote_sender_id()
    print("Registering player: ", new_player_id)
    players[new_player_id] = new_player_info
    player_connected.emit(new_player_id, new_player_info)

func leave_lobby() -> void:
    if not multiplayer.has_multiplayer_peer():
        return
    
    # notify clients that host is leaving
    if multiplayer.is_server():
        _host_is_leaving.rpc()
        await get_tree().create_timer(0.25).timeout
    remove_multiplayer_peer()
    server_disconnected.emit()
    print("Left lobby")

@rpc("authority", "call_remote", "reliable")
func _host_is_leaving() -> void:
    print("Host is leaving the lobby")
    remove_multiplayer_peer()
    server_disconnected.emit()

func _on_player_disconnected(id):
    print("Player disconnected: %s" % id)
    players.erase(id)
    player_disconnected.emit(id)

func _on_connected_ok():
    print("Connected to server")
    var peer_id = multiplayer.get_unique_id()
    players[peer_id] = player_info.duplicate()
    player_connected.emit(peer_id, player_info)
    _register_player.rpc_id(1, player_info)

func _on_connected_fail():
    print("Failed to connect the server")
    remove_multiplayer_peer()

func _on_server_disconnected():
    print("Server disconnected")
    remove_multiplayer_peer()
    players.clear()
    server_disconnected.emit()

func _on_player_connected(id):
    print("Player connected: %s" % id)
    _register_player.rpc_id(id, player_info)
    
func _return_to_menu() -> void:
    get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
