extends Control

@export var character_data: CharacterData

@onready var name_label: Label = %NameLabel

func _ready() -> void:
    if character_data == null:
        print("CharacterData not assigned")
        return
    name_label.text = character_data.character_name


func _on_select_button_pressed() -> void:
    if character_data == null:
        print("CharacterData is null")
        return
    print("selected name = %s" % character_data.character_name)
    GameManager.selected_character = character_data
