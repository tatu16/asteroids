class_name Projectile extends Area2D

@export var direction: Vector2 = Vector2.RIGHT
@export var speed: float = 600.0
@export var damage: float = 10.0
@export var shooter_peer_id: int = -1
@export var shooter_is_enemy: bool = false

func _ready() -> void:
    add_to_group("projectiles")
    body_entered.connect(_on_body_entered)
    area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
    if not multiplayer.is_server():
        return
    global_position += direction * speed * delta
    rotation = direction.angle() + GameManager.SPRITE_ROTATION_OFFSET

func _on_body_entered(body: Node2D) -> void:
    if not multiplayer.is_server():
        return
        
    if not is_instance_valid(body):
        return
    
    # enemy projectile hits another enemy
    if shooter_is_enemy and body.is_in_group("enemies"):
        return
    
    # player projectile hits another player
    if not shooter_is_enemy and body is Player:
        if body.get_multiplayer_authority() == shooter_peer_id:
            return
        
    if body is Enemy:
        if not shooter_is_enemy:
            body.take_damage(damage, shooter_peer_id)
    elif body is Player:
        if shooter_is_enemy:
            body.take_damage(damage)
            
    queue_free()

func _on_area_entered(area: Area2D) -> void:
    if not multiplayer.is_server():
        return

    if shooter_is_enemy and area.is_in_group("player_shields"):
        queue_free()
        return
        
    if not area is Projectile:
        return

    # player's projectile hits enemy's projectile
    if not shooter_is_enemy and area.shooter_is_enemy:
        area.queue_free()
        queue_free()
