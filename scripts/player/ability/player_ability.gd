class_name PlayerAbility
extends Area2D

var player: Player
var active: bool = false

func _ready() -> void:
    visible = false
    monitoring = false
    var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
    if collision_shape != null:
        collision_shape.disabled = true

func initialize(owner: Player) -> void:
    player = owner

func process_ability(_delta: float) -> void:
    pass

func movement_multiplier() -> float:
    return 1.0

func set_active(next_active: bool) -> void:
    if active == next_active:
        return
    set_active_remote.rpc(next_active)

@rpc("authority", "call_local", "unreliable")
func set_active_remote(next_active: bool) -> void:
    active = next_active
    visible = active
    monitoring = active
    var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
    if collision_shape != null:
        collision_shape.disabled = not active
