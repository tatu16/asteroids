extends Control

const options_scene: PackedScene = preload("res://scenes/menus/options_menu.tscn")
const play_menu_scene: PackedScene = preload("res://scenes/menus/play_menu.tscn")
const shop_menu_scene: PackedScene = preload("res://scenes/menus/shop_menu.tscn")

@onready var title: Label = $Title
@onready var main_buttons: VBoxContainer = $VBoxContainer

var current_sub_menu: Node = null

func _on_play_button_pressed() -> void:
    _open_sub_menu(play_menu_scene)

func _on_shop_button_pressed() -> void:
    _open_sub_menu(shop_menu_scene)

func _on_option_button_pressed() -> void:
    var options = options_scene.instantiate()
    add_child(options)

func _on_exit_game_button_pressed() -> void:
    get_tree().quit()

func _open_sub_menu(scene: PackedScene) -> void:
    if current_sub_menu != null and is_instance_valid(current_sub_menu):
        current_sub_menu.queue_free()

    var sub_menu = scene.instantiate()
    current_sub_menu = sub_menu
    add_child(sub_menu)

    # hide main menu elements while in sub-menu
    title.visible = false
    main_buttons.visible = false

    # listen for return / close
    if sub_menu.has_signal("return_requested"):
        sub_menu.return_requested.connect(_on_sub_menu_closed)
    sub_menu.tree_exited.connect(_on_sub_menu_tree_exited)

func _on_sub_menu_closed() -> void:
    title.visible = true
    main_buttons.visible = true
    current_sub_menu = null

func _on_sub_menu_tree_exited() -> void:
    title.visible = true
    main_buttons.visible = true
    current_sub_menu = null
