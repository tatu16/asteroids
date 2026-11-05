extends Node2D

@onready var timer: Timer = $Timer
@onready var hud: CanvasLayer = $Hud

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")

var elapsed_time: int = 0
var is_paused: bool = false

func _ready() -> void:
    var player = PLAYER_SCENE.instantiate() as Player
    player.character_data = GameManager.selected_character
    add_child(player)

    GameManager.player_died.connect(_on_player_died)
    
    timer.timeout.connect(_on_timer_timeout)
    if multiplayer.is_server():
        start_game()
        
func start_game() -> void:
    if not multiplayer.is_server():
        return
        
    elapsed_time = 0
    is_paused = false
    
    update_timer.rpc(elapsed_time)
    timer.start()
    
func _on_timer_timeout() -> void:
    if not multiplayer.is_server():
        return
        
    elapsed_time += 1
    update_timer.rpc(elapsed_time)
    
@rpc("authority", "call_local", "reliable")
func update_timer(time: int) -> void:
    hud.update_time(time)
    
@rpc("any_peer", "call_remote", "reliable")
func pause_game() -> void:
    if not multiplayer.is_server() or is_paused:
        return
        
    is_paused = true
    timer.stop()
    set_game_paused.rpc(true)
    
func continue_game() -> void:
    if not multiplayer.is_server() or not is_paused:
        return
        
    is_paused = false
    timer.start()
    set_game_paused.rpc(false)
    
@rpc("authority", "call_local", "reliable")
func set_game_paused(paused: bool) -> void:
    is_paused = paused
    
func end_game() -> void:
    if not multiplayer.is_server():
        return
        
    timer.stop()
    GameManager.end_game()

func _on_player_died(player: Player) -> void:
    print("player died: ", player)
