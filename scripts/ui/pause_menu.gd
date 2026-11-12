extends CanvasLayer

@onready var continue_btn = %ContinueButton
@onready var options_btn = %OptionsButton
@onready var exit_game_btn = %ExitGameButton

const confirm_menu_scene: PackedScene = preload("res://scenes/menus/confirm_menu.tscn")

func _on_continue_button_pressed() -> void:
    var world := get_tree().current_scene
    if world == null or not world.has_method("continue_game"):
        push_error("Pause menu could not find the active game world")
        return

    if multiplayer.is_server():
        world.continue_game()
    else:
        world.request_continue_game.rpc_id(1)
    queue_free()

func _on_options_button_pressed() -> void:
    pass

func _on_exit_game_button_pressed() -> void:
    var confirm = confirm_menu_scene.instantiate()
    confirm.confirmation_text = "Are you sure you want to\nleave the game?"
    confirm.confirmation_result.connect(_on_confirmation_result)
    add_child(confirm)

func _on_confirmation_result(confirmed: bool) -> void:
    if confirmed:
        get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
    else:
        print("Exit cancelled")
