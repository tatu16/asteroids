class_name Character 
extends CharacterBody2D

@export var character_data: CharacterData

var character_name: String
var max_hp: float
var max_boost: float
var boost_multiplier: float
var boost_recovery: float
var boost_drain: float

var rotation_speed: float
var linear_drag: float
var angular_drag: float
var max_speed: float
var acceleration: float

var default_weapon: PackedScene

var current_hp: float
var boost_energy: float
var current_weapons: Array[Weapon] = []

func _ready() -> void:
    if character_data:
        load_character_data()
        
    current_hp = max_hp
    boost_energy = max_boost
    
    if default_weapon:
        add_weapon(default_weapon)
        
func add_weapon(weapon_scene: PackedScene) -> void:
    var weapon = weapon_scene.instantiate() as Weapon
    add_child(weapon)
    current_weapons.append(weapon)
    
func load_character_data() -> void:
    character_name = character_data.character_name
    max_hp = character_data.max_hp
    max_boost = character_data.max_boost
    boost_multiplier = character_data.boost_multiplier
    boost_recovery = character_data.boost_recovery
    boost_drain = character_data.boost_drain
    
    rotation_speed = character_data.rotation_speed
    linear_drag = character_data.linear_drag
    angular_drag = character_data.angular_drag
    max_speed = character_data.max_speed
    acceleration = character_data.acceleration
    
    default_weapon = character_data.default_weapon
    
