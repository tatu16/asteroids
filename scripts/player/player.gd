class_name Player extends Character

@export var reference_resolution := Vector2(1920.0, 1080.0)

@onready var visuals = $Visuals
@onready var camera = $Camera2D

var projectile_spawner: MultiplayerSpawner
var abilities: Array[PlayerAbility] = []
var current_speed: float = 0.0
var current_level: int = 0
var angular_velocity: float = 0.0
var current_xp: float = 0.0
var xp_to_next_level: float = 10.0
var is_dead: bool = false
var zoom_min: float = 0.8
var zoom_max: float = 1.5
var zoom_speed: float = 0.1
var base_zoom := Vector2.ONE

func _ready() -> void:
    super()
    if character_data == null:
        return

    for ability_scene in character_data.abilities:
        var ability := ability_scene.instantiate() as PlayerAbility
        if ability == null:
            push_error(
                "Character ability scene must use PlayerAbility: "
                + ability_scene.resource_path
            )
            continue

        ability.set_multiplayer_authority(get_multiplayer_authority())
        ability.initialize(self)
        add_child(ability)
        abilities.append(ability)

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
        weapon.projectile_spawner = projectile_spawner
        weapon.try_fire(direction)

func handle_movement(delta: float) -> void:
    var direction := Input.get_vector(
        "move_left",
        "move_right",
        "move_up",
		"move_down"
    )
    
    for ability in abilities:
        ability.process_ability(delta)

    var speed_multiplier := 1.0
    for ability in abilities:
        speed_multiplier *= ability.movement_multiplier()
    var target_speed := max_speed * speed_multiplier

    var acceleration_force := acceleration * speed_multiplier

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
    base_zoom = camera.zoom

func _update_ability(player: Player, amount: float) -> void:
    if player != self:
        return
    ability_energy = minf(ability_energy + amount, max_ability)
    GameManager.use_ability_player(self, ability_energy)
    
    
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            zoom_camera(-zoom_speed)
        elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
            zoom_camera(zoom_speed)

func zoom_camera(amount: float) -> void:
    var new_zoom := clampf(
        camera.zoom.x + amount,
        zoom_min,
        zoom_max
    )
    camera.zoom = Vector2(new_zoom, new_zoom)
