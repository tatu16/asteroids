class_name PowerUp
extends Area2D

const FLOATING_TEXT = preload("res://scenes/powerups/powerup_label.tscn")

@export var pickup_text := "+25 HP"
@export var pickup_color := Color("e2001dff")

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
    apply_effect(player)
    show_pickup_notification(player)
    queue_free()

# overridden on children classes
func apply_effect(player: Player) -> void:
    pass

func show_pickup_notification(player: Player) -> void:
    var notification = FLOATING_TEXT.instantiate()
    player.get_parent().add_child(notification)
    notification.global_position = global_position
    notification.show_text(
        pickup_text,
        pickup_color,
        notification.global_position + Vector2(0, -32)
    )
