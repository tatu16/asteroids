extends Control

signal return_requested

@export var character_registry: CharacterRegistry

@onready var character_container: FlowContainer = %CharacterContainer
@onready var play_button: Button = %PlayButton
@onready var connect_text: TextEdit = %ConnectTextEdit
@onready var host_button: Button = %HostButton
@onready var join_button: Button = %JoinButton
@onready var leave_button: Button = %LeaveButton
@onready var player_list: ItemList = %PlayerListList

const SELECT_CHARACTER: PackedScene = preload("res://scenes/menus/select_character.tscn")
const JOIN_LOBBY_SCENE: PackedScene = preload("res://scenes/menus/join_menu.tscn")

var prev_selected: Button

func _ready() -> void:
    load_characters()
    GameManager.character_selected.connect(_on_character_selected)
    Lobby.player_connected.connect(_on_player_connected)

func load_characters() -> void:
    if character_registry == null:
        print("character registry is missing!")
        return
    
    for data in character_registry.characters:
        if data == null:
            print("no character data")
            continue
            
        print("loading: ", data.character_name)
        var character_button = SELECT_CHARACTER.instantiate()
        character_button.character_data = data
        character_container.add_child(character_button)

func _on_play_button_pressed() -> void:
    if GameManager.selected_character:
        if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
            Lobby.load_game.rpc("res://scenes/world.tscn")
        else:
            get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_character_selected(button: Button) -> void:
    if prev_selected != null and prev_selected != button:
        prev_selected.button_pressed = false

    prev_selected = button

func _on_return_button_pressed() -> void:
    Lobby.leave_lobby()
    return_requested.emit()
    if get_parent() == get_tree().root:
        get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
    else:
        queue_free()

func _on_join_button_pressed() -> void:
    var join_menu = JOIN_LOBBY_SCENE.instantiate()
    add_child(join_menu)

func _on_host_button_pressed() -> void:
    var error = Lobby.create_game()
    if error != OK:
        print("Failed to create lobby: ", error)
        return
    connect_text.text = "%s:%s" % [Lobby.get_local_ip(), Lobby.current_port]

func set_lobby_view() -> void:
    host_button.disabled = true
    join_button.disabled = true
    leave_button.disabled = false
    connect_text.text = ""

func set_normal_view() -> void:
    host_button.disabled = false
    join_button.disabled = false
    leave_button.disabled = true
    connect_text.text = ""

func update_player_list() -> void:
    print(Lobby.player_info)
    player_list.clear()
    for player in Lobby.player_info:
        player_list.add_item(player, null, true)

func _on_player_connected(peer_id, player_info):
    print(peer_id, player_info)
    set_lobby_view()
    update_player_list()

func _on_leave_button_pressed() -> void:
    Lobby.leave_lobby()
    set_normal_view()
