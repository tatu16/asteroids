class_name Player extends Character

@onready var visuals = $Visuals

var current_speed: float = 0.0
var current_level: int = 0
var boost_active: bool = false
var angular_velocity: float = 0.0

func _physics_process(delta: float) -> void:
    handle_movement(delta)
    handle_rotation(delta)

    move_and_slide()

func handle_movement(delta: float) -> void:
    var direction := Input.get_vector(
        "move_left",
        "move_right",
        "move_up",
		"move_down"
    )
    
    boost_active = Input.is_action_pressed("boost") and boost_energy > 0
    if boost_active:
        boost_energy = maxf(
            boost_energy - boost_drain * delta, 0.0)
    else:
        boost_energy = minf(
            boost_energy + boost_recovery * delta, max_boost)

    GameManager.boost_player(self, boost_energy)
            
    var acceleration_force = acceleration
    if boost_active:
        acceleration_force *= boost_multiplier
        
    velocity += direction * acceleration_force * delta
    
    if direction == Vector2.ZERO:
        velocity = velocity.move_toward(
            Vector2.ZERO,
            linear_drag * delta
        )
    velocity = velocity.limit_length(max_speed * (
        boost_multiplier if boost_active else 1.0
    ))
    
func handle_rotation(delta: float) -> void:
    visuals.rotation = global_position.direction_to(
        get_global_mouse_position()
    ).angle()
