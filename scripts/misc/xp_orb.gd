class_name XPOrb
extends Area2D

@export var xp_value: float = 5.0

func _on_ready() -> void:
    if not multiplayer.is_server():
        return
        
    monitoring = true
    body_entered.connect(_on_body_entered)
    
func _on_body_entered(body: Node2D) -> void:
    if not multiplayer.is_server():
        return
        
    if body is Player:
        collect(body)

func collect(player: Player) -> void:
    if not multiplayer.is_server():
        return
    
    SaveManager.add_run_stat(
        player.get_multiplayer_authority(),
        SaveManager.Stat.XP_COLLECTED,
        xp_value
    )
    
    player.gain_xp(xp_value)
    queue_free()
