extends CanvasLayer

@onready var address_text: TextEdit = %AddressTextEdit

func _ready() -> void:
    Lobby.player_connected.connect(_on_player_connect)

func _on_return_button_pressed() -> void:
    queue_free()

func _on_connect_button_pressed() -> void:
    var address = address_text.text.strip_edges().split(":", true, 1)
    var ip_address: String = Lobby.DEFAULT_SERVER_IP
    var port: int = Lobby.DEFAULT_PORT
    if not address.is_empty():
        ip_address = address[0]
        if address[1].is_valid_int():
            port = int(address[1])
        else:
            port = Lobby.DEFAULT_PORT
    Lobby.join_game(ip_address, port)
    # add timer for timeout

func _on_player_connect(peer_id, player_info):
    queue_free()
