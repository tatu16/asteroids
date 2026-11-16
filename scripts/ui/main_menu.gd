extends Control

const options_scene = preload("res://scenes/menus/options_menu.tscn")

func _on_play_button_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/menus/play_menu.tscn")

func _on_option_button_pressed() -> void:
    var options = options_scene.instantiate()
    add_child(options)

func _on_exit_game_button_pressed() -> void:
    get_tree().quit()

func _on_shop_button_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/menus/shop_menu.tscn")
