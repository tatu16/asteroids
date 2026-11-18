class_name Projectile extends Area2D

@export_group("Particles")
@export var break_particles_scene: PackedScene

@export_group("Movement")
@export var direction: Vector2 = Vector2.RIGHT
@export var speed: float = 600.0
@export var acceleration: float = 0.0
@export var max_speed: float = 0.0

@export_group("Combat")
@export var damage: float = 10.0
@export var shooter_peer_id: int = -1
@export var shooter_is_enemy: bool = false

var destroyed: bool = false

func _ready() -> void:
    add_to_group("projectiles")
    body_entered.connect(_on_body_entered)
    area_entered.connect(_on_area_entered)

func clear_projectile(spawn_particles: bool = true) -> void:
    if destroyed:
        return
        
    destroyed = true
    if spawn_particles:
        spawn_break_particles()
    queue_free()

func spawn_break_particles() -> void:
    if break_particles_scene == null:
        return
        
    var particles = break_particles_scene.instantiate() as GPUParticles2D
    if particles == null:
        return
        
    get_tree().current_scene.add_child(particles)
    particles.global_position = global_position
    
    var return_direction = -direction.normalized()
    particles.rotation = return_direction.angle()
    particles.one_shot = true
    particles.emitting = true

    get_tree().create_timer(particles.lifetime + 0.1).timeout.connect(particles.queue_free)

func _physics_process(delta: float) -> void:
    apply_acceleration(delta)
    global_position += direction * speed * delta
    rotation = direction.angle() + GameManager.SPRITE_ROTATION_OFFSET

func apply_acceleration(delta: float) -> void:
    speed = maxf(speed + acceleration * delta, 0.0)
    if max_speed > 0.0:
        speed = minf(speed, max_speed)

func _on_body_entered(body: Node2D) -> void:
    if not multiplayer.is_server() or destroyed:
        return
        
    if not is_instance_valid(body):
        return

    # enemy projectile hits wall
    if shooter_is_enemy and body.is_in_group("wall"):
        return
    
    # enemy projectile hits another enemy
    if shooter_is_enemy and body.is_in_group("enemies"):
        return
    
    # player projectile hits another player
    if not shooter_is_enemy and body is Player:
        return
        
    if body is Enemy:
        if not shooter_is_enemy:
            body.take_damage(damage, shooter_peer_id, direction)
            clear_projectile(false)
            return
    elif body is Player:
        if shooter_is_enemy:
            body.take_damage(damage)
    
    clear_projectile()
            
func _on_area_entered(area: Area2D) -> void:
    if not multiplayer.is_server() or destroyed:
        return
        
    if shooter_is_enemy and area.is_in_group("player_shields"):
        clear_projectile()
        return
        
    if not area is Projectile:
        return
        
    var other_projectile := area as Projectile
    
    # player projectile hits enemy projectile
    if not shooter_is_enemy and other_projectile.shooter_is_enemy:
        other_projectile.clear_projectile()
        clear_projectile()
