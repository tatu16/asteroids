extends Projectile

@export var wave_amplitude: float = 90.0
@export var wave_frequency: float = 7.0

var elapsed_time: float = 0.0

func _physics_process(delta: float) -> void:
    if not multiplayer.is_server():
        return

    elapsed_time += delta
    apply_acceleration(delta)
    var wave_velocity := direction.rotated(PI / 2.0) * sin(elapsed_time * wave_frequency) * wave_amplitude
    global_position += (direction * speed + wave_velocity) * delta
    rotation = direction.angle() + GameManager.SPRITE_ROTATION_OFFSET