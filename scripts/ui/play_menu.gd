extends Control

@export var character_registry: CharacterRegistry

@onready var character_container: FlowContainer = %CharacterContainer
@onready var play_button: Button = %PlayButton

const SELECT_CHARACTER: PackedScene = preload("res://scenes/menus/select_character.tscn")

func _ready() -> void:
    load_characters()
    
func load_characters() -> void:
    if character_registry == null:
        print("character registry is missing!")
        return
    
    for data in character_registry.characters:
        if data == null:
            print("no character data")
            continue
        print("loading: ", data.character_name)
        var character_button = SELECT_CHARACTER.instantiate()
        character_button.character_data = data
        character_container.add_child(character_button)
        
        
func _on_play_button_pressed() -> void:
    if GameManager.selected_character:
        get_tree().change_scene_to_file("res://scenes/world.tscn")
