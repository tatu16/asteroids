extends CanvasLayer

@onready var continue_btn = %ContinueButton
@onready var options_btn = %OptionsButton
@onready var exit_game_btn = %ExitGameButton

const confirm_menu_scene: PackedScene = preload("res://scenes/menus/confirm_menu.tscn")

func _on_continue_button_pressed() -> void:
    GameManager.
    queue_free()

func _on_options_button_pressed() -> void:
    pass

func _on_exit_game_button_pressed() -> void:
    var confirm = confirm_menu_scene.instantiate()
    add_child(confirm)
