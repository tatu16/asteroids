class_name Enemy extends CharacterBody2D

@export var max_hp: float = 100
@export var move_speed: float = 50
@export var damage: float = 5.0
@export var attack_cooldown: float = 1.0
@export var attack_distance: float = 300.0
@export var xp: float = 1

@export_group("Projectile")
@export var shoot_projectiles: bool = false
@export var projectile_scene: PackedScene = preload("res://scenes/projectiles/bolt.tscn")
@export var projectile_speed: float = 250.0
@export var projectile_acceleration: float = 0.0
@export var projectile_max_speed: float = 0.0
@export var projectile_damage: float = 10.0

@export_group("Powerup Drops")
@export var drop_chance: float = 0.25
@export var powerup_pool: Array[PackedScene] = [
    preload("res://scenes/powerups/hp_powerup.tscn"),
    preload("res://scenes/powerups/ability_powerup.tscn")
]

var stop_moving_while_shooting = true
var powerup_spawner: PowerupSpawner
var projectile_spawner: MultiplayerSpawner
var xp_orb_spawner: MultiplayerSpawner
var hp: float = 999
var can_attack = true

@onready var animated_sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

func _ready() -> void:
    add_to_group("enemies")
    hp = max_hp
    play_default_animation()
    
func die(attacker_peer_id: int) -> void:
    if not multiplayer.is_server():
        return
        
    SaveManager.add_run_stat(
        attacker_peer_id,
        SaveManager.Stat.ENEMIES_KILLED
    )
    SaveManager.add_run_stat(
        attacker_peer_id,
        SaveManager.Stat.SCORE
    )
    GameManager.add_score(1)
    
    if xp_orb_spawner:
        xp_orb_spawner.spawn_xp_orb(xp,global_position)
    
    drop_powerup()
    queue_free()
    
func drop_powerup() -> void:
    if not multiplayer.is_server():
        return
    if randf() > drop_chance:
        return
    if powerup_pool.is_empty() or powerup_spawner == null:
        return

    var powerup_scene = powerup_pool.pick_random()
    powerup_spawner.spawn_powerup(
        powerup_scene,
        global_position
    )
    
func take_damage(amount: float, attacker_peer_id: int) -> void:
    if not multiplayer.is_server():
        return
    
    hp -= amount
    SaveManager.add_run_stat(
        attacker_peer_id,
        SaveManager.Stat.DAMAGE_DEALT,
        amount
    )
    if(hp <= 0):
        die(attacker_peer_id)
        
func attack_player(player: Player) -> void:
    if not can_attack:
        return
        
    can_attack = false
    play_attack_animation()
    player.take_damage(damage)
    await get_tree().create_timer(attack_cooldown).timeout
    can_attack = true
    play_default_animation()
        
func get_closest_player():
    var all_players = get_tree().get_nodes_in_group("players")
    var closest_player = null
    
    if all_players.size() > 0:
        closest_player = all_players[0]
        for player in all_players:
            var distance_to_this_player = global_position.distance_squared_to(player.global_position)
            var distance_to_closest_player = global_position.distance_squared_to(closest_player.global_position)
            if (distance_to_this_player < distance_to_closest_player):
                closest_player = player
                
    return closest_player
    
func _physics_process(delta: float) -> void:
    if not multiplayer.is_server():
        return
        
    var closest_player = get_closest_player()
    if closest_player == null:
        return
        
    var distance_to_player := global_position.distance_to(closest_player.global_position)
    if shoot_projectiles and distance_to_player <= attack_distance:
        shoot_at_player(closest_player)
        if stop_moving_while_shooting:
            velocity = Vector2.ZERO
            move_and_slide()
            return
        
    move_towards_player(closest_player)
    
    for i in get_slide_collision_count():
        var collision = get_slide_collision(i)
        var body = collision.get_collider()
        if body is Player:
            attack_player(body)
  
func move_towards_player(player: Player) -> void:
    var direction = global_position.direction_to(
        player.global_position
    )
    velocity = direction * move_speed
    move_and_slide()

func shoot_at_player(player: Player) -> void:
    if not multiplayer.is_server():
        return
    if not can_attack or projectile_spawner == null:
        return
        
    can_attack = false
    play_attack_animation()
    var direction = global_position.direction_to(player.global_position)
    var projectile_path := ""
    if projectile_scene == null:
        push_error("Enemy projectile_scene is null; using the default bolt")
    else:
        projectile_path = projectile_scene.resource_path
        
    var projectile_data := {
        "position": global_position,
        "direction": direction,
        "speed": projectile_speed,
        "damage": projectile_damage,
        "projectile_path": projectile_path,
        "shooter_is_enemy": true,
        "shooter_path": get_path()
    }
    if projectile_acceleration != 0.0:
        projectile_data["acceleration"] = projectile_acceleration
    if projectile_max_speed > 0.0:
        projectile_data["max_speed"] = projectile_max_speed
    projectile_spawner.spawn(projectile_data)

    await get_tree().create_timer(attack_cooldown).timeout
    can_attack = true
    play_default_animation()

func play_attack_animation() -> void:
    if animated_sprite == null or animated_sprite.sprite_frames == null:
        return
    if not animated_sprite.sprite_frames.has_animation(&"attack"):
        return
    if animated_sprite.sprite_frames.get_frame_count(&"attack") == 0:
        return
    animated_sprite.play(&"attack")

func play_default_animation() -> void:
    if animated_sprite == null or animated_sprite.sprite_frames == null:
        return
    if animated_sprite.sprite_frames.has_animation(&"default"):
        animated_sprite.play(&"default")
