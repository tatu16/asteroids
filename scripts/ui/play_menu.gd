extends Control

@export var character_registry: CharacterRegistry

@onready var character_container: FlowContainer = %CharacterContainer
@onready var play_button: Button = %PlayButton

const SELECT_CHARACTER: PackedScene = preload("res://scenes/menus/select_character.tscn")

var prev_selected: Button

func _ready() -> void:
    load_characters()
    GameManager.character_selected.connect(_on_character_selected)
    
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

func _on_character_selected(button: Button) -> void:
    if prev_selected == null:
        prev_selected = button
    if not button == prev_selected:
        prev_selected.button_pressed = false
    prev_selected = button


func _on_return_button_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
