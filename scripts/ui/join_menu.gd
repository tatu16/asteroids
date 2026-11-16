extends CanvasLayer

@onready var ip_text: TextEdit = %IPTextEdit
@onready var port_text: TextEdit = %PortTextEdit

func _ready() -> void:
    Lobby.player_connected.connect(_on_player_connect)

func _on_return_button_pressed() -> void:
    queue_free()

func _on_connect_button_pressed() -> void:
    var ip_address = ip_text.text.strip_edges()
    if ip_address.is_empty():
        ip_address = Lobby.DEFAULT_SERVER_IP
    var port_str = port_text.text.strip_edges()
    var port = int(port_str) if not port_str.is_empty() and port_str.is_valid_int() else Lobby.DEFAULT_PORT
    Lobby.join_game(ip_address, port)
    # add timer for timeout

func _on_player_connect(peer_id, player_info):
    queue_free()
