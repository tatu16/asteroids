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

func _ready() -> void:
    if character_data:
        load_character_data()
        
    current_hp = max_hp
    ability_energy = max_ability
    
    if default_weapon:
        add_weapon(default_weapon)
        
func add_weapon(weapon_data: WeaponData) -> void:
    var weapon = Weapon.new()
    weapon.weapon_data = weapon_data
    weapon.owner_character = self

    add_child(weapon)
    current_weapons.append(weapon)
    
func take_damage(amount: float) -> void:
    if self is Player:
        GameManager.damage_player(self, amount)
    else:
        current_hp = maxf(current_hp - amount, 0.0)

func load_character_data() -> void:
    character_name = character_data.character_name
    var ship_sprite := get_node_or_null("Visuals/ShipSprite") as Sprite2D
    if ship_sprite != null and character_data.ship_texture != null:
        set_ship_texture(character_data.ship_texture)

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

func set_ability_visual(enabled: bool) -> void:
    if character_data == null or character_data.ability_ship_texture == null:
        return
    set_ship_texture(
        character_data.ability_ship_texture if enabled
        else character_data.ship_texture
    )

func set_ship_texture(texture: Texture2D) -> void:
    var ship_sprite := get_node_or_null("Visuals/ShipSprite") as Sprite2D
    if ship_sprite == null or texture == null:
        return

    var atlas_texture := AtlasTexture.new()
    atlas_texture.atlas = texture
    atlas_texture.region = character_data.ship_region
    ship_sprite.texture = atlas_texture
    
