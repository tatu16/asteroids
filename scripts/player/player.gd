class_name Player extends Character

@onready var visuals = $Visuals

var current_speed: float = 0.0
var current_level: int = 0
var boost_active: bool = false
var angular_velocity: float = 0.0
var current_xp: float = 0.0
var xp_to_next_level: float = 10.0
var is_dead: bool = false

func _physics_process(delta: float) -> void:
    if is_multiplayer_authority():
        handle_movement(delta)
        handle_rotation(delta)
        handle_shooting()
    move_and_slide()

func handle_shooting() -> void:
    if not Input.is_action_pressed("shoot"):
        return
    var direction = global_position.direction_to(get_global_mouse_position())
    for weapon in current_weapons:
        weapon.try_fire(direction)

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
            
    var speed_multiplier := boost_multiplier if boost_active else 1.0
    var target_speed := max_speed * speed_multiplier

    var acceleration_force := acceleration
    if boost_active:
        acceleration_force *= boost_multiplier

    if direction != Vector2.ZERO:
        if velocity.dot(direction) < 0.0:
            acceleration_force *= 3.0

        var target_velocity := direction * target_speed
        velocity = velocity.move_toward(
            target_velocity,
            acceleration_force * delta
        )
    else:
        velocity = velocity.move_toward(
            Vector2.ZERO,
            linear_drag * delta
        )
    
func handle_rotation(delta: float) -> void:
    visuals.rotation = global_position.direction_to(
        get_global_mouse_position()
    ).angle() + GameManager.SPRITE_ROTATION_OFFSET

func gain_xp(amount: float) -> void:
    if not multiplayer.is_server():
        return
    
    var levels_gained := 0
        
    current_xp += amount
    while current_xp >= xp_to_next_level:
        current_xp -= xp_to_next_level
        current_level += 1
        xp_to_next_level *= 1.5
        levels_gained += 1
        
    GameManager.update_player_xp.rpc(
        get_multiplayer_authority(), 
        current_xp,
        xp_to_next_level,
        current_level
    )
    
    for i in range(levels_gained):
        GameManager.player_levelup.emit(self)
        
func level_up() -> void:
    current_level += 1
    xp_to_next_level *= 1.5
    print("Level up! Current level: ", current_level)
    GameManager.player_levelup.emit(self)

func _on_ready() -> void:
    add_to_group("players")
