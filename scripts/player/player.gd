class_name Player extends Character

@onready var visuals = $Visuals
@onready var camera: Camera2D = $Camera2D

var projectile_spawner: MultiplayerSpawner
var abilities: Array[PlayerAbility] = []
var current_speed: float = 0.0
var current_level: int = 0
var angular_velocity: float = 0.0
var current_xp: float = 0.0
var xp_to_next_level: float = 10.0
var is_dead: bool = false
var spectate_target: Player = null
var is_spectating: bool = false
var is_invulnerable: bool = false
var upgrade_levels: Dictionary = {}

const MAX_UPGRADE_LEVELS: Dictionary = {
    "attack_speed": 10,
    "projectile_count": 5,
    "damage": 5,
    "max_hp": 10,
    "boost": 10,
}

func _ready() -> void:
    var peer_id := name.to_int()
    if peer_id > 0:
        set_multiplayer_authority(peer_id)
        var synchronizer := get_node_or_null("MultiplayerSynchronizer") as MultiplayerSynchronizer
        if synchronizer != null:
            synchronizer.set_multiplayer_authority(peer_id)

    super()
    
    if camera != null:
        camera.enabled = is_multiplayer_authority()
        if camera.enabled:
            camera.make_current()
    
    add_to_group("players")
    
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

    GameManager.player_add_ability.connect(_update_ability)
    GameManager.player_healed.emit(self, 0.0, current_hp)
    if multiplayer.is_server():
        GameManager.use_ability_player(self, ability_energy)
        GameManager.update_player_xp.rpc(
            get_multiplayer_authority(),
            current_xp,
            xp_to_next_level,
            current_level
        )

func _physics_process(delta: float) -> void:
    if is_dead:
        return
    if is_multiplayer_authority():
        handle_movement(delta)
        handle_rotation(delta)
        handle_shooting()
        move_and_slide()

func handle_shooting() -> void:
    if is_dead or not Input.is_action_pressed("shoot"):
        return
    var direction = global_position.direction_to(get_global_mouse_position())
    if multiplayer.is_server():
        fire_weapons(direction)
    else:
        var can_fire := false
        for weapon in current_weapons:
            if weapon.cooldown <= 0.0:
                can_fire = true
                weapon.cooldown = 1.0 / (weapon.weapon_data.fire_rate * weapon.attack_speed_multiplier)
        if can_fire:
            request_fire.rpc_id(1, direction)

@rpc("any_peer", "call_local", "reliable")
func request_fire(direction: Vector2) -> void:
    if not multiplayer.is_server() or is_dead:
        return
    var sender_id := multiplayer.get_remote_sender_id()
    if sender_id != 0 and sender_id != get_multiplayer_authority():
        return
    fire_weapons(direction)

func fire_weapons(direction: Vector2) -> void:
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

    current_xp += amount
    while current_xp >= xp_to_next_level:
        current_xp -= xp_to_next_level
        level_up()
        
    GameManager.update_player_xp.rpc(
        get_multiplayer_authority(), 
        current_xp,
        xp_to_next_level,
        current_level
    )
        
func level_up() -> void:
    if not multiplayer.is_server():
        return
    current_level += 1
    xp_to_next_level *= 1.5
    print("Level up! Current level: ", current_level)
    GameManager.player_levelup.emit(self)

func apply_upgrade(upgrade_id: String) -> void:
    match upgrade_id:
        "attack_speed":
            for weapon in current_weapons:
                weapon.attack_speed_multiplier *= 1.15
        "projectile_count":
            for weapon in current_weapons:
                weapon.projectile_count_bonus += 1
        "damage":
            for weapon in current_weapons:
                weapon.damage_multiplier *= 1.2
        "max_hp":
            max_hp += 20.0
            current_hp += 20.0
            GameManager.player_healed.emit(self, 20.0, current_hp)
        "boost":
            ability_multiplier *= 1.15
        _:
            push_error("Unknown player upgrade: " + upgrade_id)
            return
    upgrade_levels[upgrade_id] = get_upgrade_level(upgrade_id) + 1

func supports_upgrade(upgrade_id: String) -> bool:
    for ability in abilities:
        if upgrade_id in ability.supported_upgrade_ids:
            return true
    return false

func can_upgrade(upgrade_id: String) -> bool:
    return get_upgrade_level(upgrade_id) < MAX_UPGRADE_LEVELS.get(upgrade_id, -1)

func get_upgrade_max_level(upgrade_id: String) -> int:
    return MAX_UPGRADE_LEVELS.get(upgrade_id, -1)

func get_upgrade_level(upgrade_id: String) -> int:
    return upgrade_levels.get(upgrade_id, 1)

func _process(_delta: float) -> void:
    if is_spectating and is_multiplayer_authority():
        _update_spectating()

func _unhandled_input(event: InputEvent) -> void:
    if is_spectating and is_multiplayer_authority():
        if event.is_action_pressed("shoot"):
            spectate_next_alive_player()
        elif event.is_action_pressed("ability"):
            spectate_prev_alive_player()

func die() -> void:
    if is_dead:
        return
    is_dead = true
    if is_in_group("players"):
        remove_from_group("players")
    add_to_group("dead_players")
    
    collision_layer = 0
    collision_mask = 0
    velocity = Vector2.ZERO
    
    if visuals:
        visuals.visible = false

    if is_multiplayer_authority():
        start_spectating()

func start_spectating() -> void:
    is_spectating = true
    if camera != null:
        camera.top_level = true
        camera.enabled = true
        camera.make_current()
    spectate_next_alive_player()

func _update_spectating() -> void:
    if spectate_target == null or not is_instance_valid(spectate_target) or spectate_target.is_dead:
        spectate_next_alive_player()
        
    if spectate_target != null and is_instance_valid(spectate_target) and camera != null:
        camera.global_position = spectate_target.global_position
        camera.global_rotation = 0.0

func get_alive_players() -> Array[Player]:
    var alive: Array[Player] = []
    for node in get_tree().get_nodes_in_group("players"):
        var p := node as Player
        if p != null and is_instance_valid(p) and not p.is_dead and p != self:
            alive.append(p)
    return alive

func spectate_next_alive_player() -> void:
    var alive := get_alive_players()
    if alive.is_empty():
        spectate_target = null
        _update_hud_spectating("")
        return
        
    var current_idx := alive.find(spectate_target)
    var next_idx := (current_idx + 1) % alive.size()
    spectate_target = alive[next_idx]
    var target_name = spectate_target.character_name if spectate_target.character_name != "" else spectate_target.name
    _update_hud_spectating("%s (Player %s)" % [target_name, spectate_target.name])

func spectate_prev_alive_player() -> void:
    var alive := get_alive_players()
    if alive.is_empty():
        spectate_target = null
        _update_hud_spectating("")
        return
        
    var current_idx := alive.find(spectate_target)
    var prev_idx := (current_idx - 1 + alive.size()) % alive.size()
    spectate_target = alive[prev_idx]
    var target_name = spectate_target.character_name if spectate_target.character_name != "" else spectate_target.name
    _update_hud_spectating("%s (Player %s)" % [target_name, spectate_target.name])

func _update_hud_spectating(target_name: String) -> void:
    var world = get_tree().root.find_child("World", true, false)
    if world != null and world.hud != null:
        world.hud.update_spectating_name(target_name)

func start_respawn_countdown(duration: float) -> void:
    var world = get_tree().root.find_child("World", true, false)
    if world != null and world.hud != null:
        var target_name := ""
        if spectate_target != null and is_instance_valid(spectate_target):
            var char_name = spectate_target.character_name if spectate_target.character_name != "" else spectate_target.name
            target_name = "%s (Player %s)" % [char_name, spectate_target.name]
        world.hud.show_spectator_overlay(target_name, duration)

func stop_spectating() -> void:
    is_spectating = false
    spectate_target = null
    if camera != null:
        camera.top_level = false
        camera.position = Vector2.ZERO
        camera.rotation = 0.0
        camera.enabled = is_multiplayer_authority()
        if is_multiplayer_authority():
            camera.make_current()
    var world = get_tree().root.find_child("World", true, false)
    if world != null and world.hud != null:
        world.hud.hide_spectator_overlay()

func respawn(spawn_pos: Vector2) -> void:
    is_dead = false
    global_position = spawn_pos
    velocity = Vector2.ZERO
    current_hp = max_hp
    ability_energy = max_ability
    collision_layer = 2
    collision_mask = 5
    if visuals:
        visuals.visible = true
        visuals.modulate.a = 1.0
        
    if is_in_group("dead_players"):
        remove_from_group("dead_players")
    if not is_in_group("players"):
        add_to_group("players")
        
    if is_multiplayer_authority():
        stop_spectating()
        GameManager.player_healed.emit(self, 0.0, current_hp)
        GameManager.use_ability_player(self, ability_energy)
        
    is_invulnerable = true
    _flash_invulnerability()

func _flash_invulnerability() -> void:
    var tween := create_tween()
    if tween != null and visuals != null:
        for i in 3:
            tween.tween_property(visuals, "modulate:a", 0.3, 0.25)
            tween.tween_property(visuals, "modulate:a", 1.0, 0.25)
        tween.tween_callback(func(): is_invulnerable = false)
    else:
        await get_tree().create_timer(1.5, false).timeout
        is_invulnerable = false

func _update_ability(player: Player, amount: float) -> void:
    if player != self:
        return
    ability_energy = minf(ability_energy + amount, max_ability)
    GameManager.use_ability_player(self, ability_energy)
    
