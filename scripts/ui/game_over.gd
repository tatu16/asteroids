extends CanvasLayer


@onready var restart_button = %RestartButton
@onready var mainmenu_button = %MainMenuButton

func _on_main_menu_button_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")


func _on_restart_button_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/main.tscn")
