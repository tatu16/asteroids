class_name Character 
extends CharacterBody2D

var character_data: CharacterData

var character_name: String
var max_hp: float
var max_ability: float
var ability_multiplier: float
var ability_recovery: float
var ability_drain: float

var rotation_speed: float
var linear_drag: float
var angular_drag: float
var max_speed: float
var acceleration: float

var default_weapon: WeaponData

var current_hp: float
var ability_energy: float
var current_weapons: Array[Weapon] = []
var flash_id: int = 0

const glow_label_scene: PackedScene = preload("res://scenes/misc/glow_label.tscn")

@onready var sprite: Sprite2D = get_node_or_null("Visuals/ShipSprite") as Sprite2D

func _ready() -> void:
    if character_data:
        load_character_data()
        
    current_hp = max_hp
    ability_energy = max_ability
    
    if default_weapon:
        add_weapon(default_weapon)
        
    if sprite and sprite.material:
            sprite.material = sprite.material.duplicate()
        
func add_weapon(weapon_data: WeaponData) -> void:
    var weapon = Weapon.new()
    weapon.weapon_data = weapon_data
    weapon.owner_character = self

    add_child(weapon)
    current_weapons.append(weapon)
    
func damage_feedback(amount: float) -> void:
    if not is_instance_valid(sprite) or sprite.material == null:
        return
        
    var glow_label = glow_label_scene.instantiate()
    get_tree().current_scene.add_child(glow_label)
    var spawn_pos = global_position + Vector2(0.0, -24.0)
    var display = str(roundi(amount)) if fmod(amount, 1.0) == 0.0 else ("%.1f" % amount)
    glow_label.show_text(
        display,
        Color(1.0, 0.218, 0.349, 1.0),
        spawn_pos,
        18
    )
        
    flash_id += 1
    var current_flash_id := flash_id
    
    sprite.material.set_shader_parameter("active", true)
    await get_tree().create_timer(0.15).timeout
    if not is_instance_valid(self):
        return

    if current_flash_id != flash_id:
        return

    if is_instance_valid(sprite) and sprite.material != null:
        sprite.material.set_shader_parameter("active", false)
    
func take_damage(amount: float) -> void:
    if self is Player:
        GameManager.damage_player(self, amount)
        damage_feedback(amount)
    else:
        current_hp = maxf(current_hp - amount, 0.0)

func load_character_data() -> void:
    character_name = character_data.character_name
    var ship_sprite := get_node_or_null("Visuals/ShipSprite") as Sprite2D
    if ship_sprite != null and character_data.ship_texture != null:
        var atlas_texture := AtlasTexture.new()
        atlas_texture.atlas = character_data.ship_texture
        atlas_texture.region = character_data.ship_region
        ship_sprite.texture = atlas_texture

    max_hp = character_data.max_hp
    max_ability = character_data.max_ability
    ability_multiplier = character_data.ability_multiplier
    ability_recovery = character_data.ability_recovery
    ability_drain = character_data.ability_drain
    
    rotation_speed = character_data.rotation_speed
    linear_drag = character_data.linear_drag
    angular_drag = character_data.angular_drag
    max_speed = character_data.max_speed
    acceleration = character_data.acceleration
    
    default_weapon = character_data.default_weapon
    
