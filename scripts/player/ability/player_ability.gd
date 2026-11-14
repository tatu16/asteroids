class_name PlayerAbility
extends Area2D

var player: Player
var active: bool = false
var activation_particles: GPUParticles2D
@export var supported_upgrade_ids: Array[String] = []
@export var activation_particles_scene: PackedScene
@export var activation_particles_offset: Vector2 = Vector2.ZERO

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

func _process(_delta: float) -> void:
    if not active or activation_particles == null:
        return
    if activation_particles.one_shot and not activation_particles.emitting:
        activation_particles.restart()

func movement_multiplier() -> float:
    return 1.0

func set_active(next_active: bool) -> void:
    if active == next_active:
        return
    set_active_remote.rpc(next_active)

@rpc("authority", "call_local", "unreliable")
func set_active_remote(next_active: bool) -> void:
    if next_active and not active:
        spawn_activation_particles()
    elif not next_active and active:
        stop_activation_particles()
    active = next_active
    visible = active
    monitoring = active
    var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
    if collision_shape != null:
        collision_shape.disabled = not active

func spawn_activation_particles() -> void:
    if activation_particles_scene == null or player == null:
        return

    activation_particles = activation_particles_scene.instantiate() as GPUParticles2D
    if activation_particles == null:
        push_error(
            "Ability activation particles scene must use GPUParticles2D: "
            + activation_particles_scene.resource_path
        )
        return

    var particle_parent := player.get_node_or_null("Visuals") as Node2D
    if particle_parent == null:
        particle_parent = player

    if particle_parent == null:
        push_error("Unable to attach ability activation particles to the player")
        activation_particles = null
        return

    particle_parent.add_child(activation_particles)
    activation_particles.position = activation_particles_offset
    activation_particles.emitting = true

func stop_activation_particles() -> void:
    if activation_particles == null:
        return
    activation_particles.queue_free()
    activation_particles = null
