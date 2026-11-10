class_name PowerUp
extends Area2D


func _ready() -> void:
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
    print("collect powerup")
    apply_effect(player)
    queue_free()

# overridden on children classes
func apply_effect(player: Player) -> void:
    pass
