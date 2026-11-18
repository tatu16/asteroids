class_name game_object extends Area2D

@export var break_particles_scene: PackedScene

@export_group("xp")
@export var xp_orb_scene = preload("res://scenes/misc/xp_orb.tscn")
@export var xp_chance: float = 0.1
@export var xp_min: float = 1.0
@export var xp_max: float = 3.0

@export_group("powerup")
@export var powerup_chance: float = 0.05
@export var powerup_pool: Array[PackedScene] = [
    preload("res://scenes/powerups/hp_powerup.tscn"),
    preload("res://scenes/powerups/ability_powerup.tscn")
]

var powerup_spawner: PowerupSpawner
var xp_orb_spawner: MultiplayerSpawner

func _ready() -> void:
    area_entered.connect(_on_area_entered)

func drop_powerup() -> void:
    if randf() > powerup_chance:
        return
    if powerup_pool.is_empty() or powerup_spawner == null:
        return
    var powerup_scene = powerup_pool.pick_random()
    powerup_spawner.spawn_powerup(
        powerup_scene,
        global_position
    )
    
func drop_xp() -> void:
    if randf() > xp_chance:
        return
    var xp_amount = randf_range(xp_min, xp_max)
    if xp_orb_spawner:
        xp_orb_spawner.spawn_xp_orb(xp_amount,global_position)

func clear_object(area: Node2D):
    spawn_break_particles(area)
    drop_xp()
    drop_powerup()
    queue_free()
    
func spawn_break_particles(projectile: Projectile) -> void:
    var particles = break_particles_scene.instantiate() as GPUParticles2D

    get_tree().current_scene.add_child(particles)
    particles.global_position = global_position

    var opposite_direction = projectile.direction.normalized()
    particles.rotation = opposite_direction.angle()
    particles.one_shot = true
    particles.emitting = true

    get_tree().create_timer(particles.lifetime + 0.1).timeout.connect(particles.queue_free)

func _on_area_entered(area: Node2D) -> void:
    if not multiplayer.is_server():
        return
        
    if not is_instance_valid(area) or not is_instance_of(area, Projectile):
        return
        
    area = area as Projectile
    if area.shooter_is_enemy:
        return
    
    clear_object(area)
    area.clear_projectile()
