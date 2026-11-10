extends CanvasLayer

@onready var confirm_button: Button = %ConfirmButton
@onready var return_button: Button = %ReturnButton

func _on_confirm_button_pressed() -> void:
    GameManager.end_game()
    get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")

func _on_return_button_pressed() -> void:
    queue_free()
