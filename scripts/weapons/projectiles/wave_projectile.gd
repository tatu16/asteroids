extends Projectile

@export var wave_amplitude: float = 90.0
@export var wave_frequency: float = 7.0
@export var wave_max_size: float = 150.0
@export var wave_growth_speed: float = 2.5

var elapsed_time: float = 0.0
var wave_size: float = 0.0

func _ready() -> void:
    super()
    scale = Vector2.ZERO

# change scaling from physics tick based to something else? default = 60hz
func _physics_process(delta: float) -> void:
    if not multiplayer.is_server():
        return

    elapsed_time += delta
    wave_size = minf(wave_size + wave_growth_speed * delta, wave_max_size)
    scale = Vector2.ONE * wave_size
    apply_acceleration(delta)
    var wave_velocity := direction.rotated(PI / 2.0) * sin(elapsed_time * wave_frequency) * wave_amplitude
    global_position += (direction * speed + wave_velocity) * delta
    rotation = direction.angle() + GameManager.SPRITE_ROTATION_OFFSET
