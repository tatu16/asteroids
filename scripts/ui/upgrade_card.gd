extends Control

@onready var upgrade_label: Label = %UpgradeLabel
@onready var description_label: Label = %DescriptionLabel
@onready var current_level_label: Label = %CurrentLevel
@onready var upgrade_image: TextureRect = %UpgradeImage

var upgrade_id: String

func setup(upgrade: Dictionary) -> void:
    upgrade_id = upgrade["id"]
    upgrade_label.text = upgrade["name"]
    description_label.text = upgrade["description"]
    current_level_label.text = "Lv. %d" % upgrade["level"]
    upgrade_image.texture = upgrade["image"]

func _on_button_pressed() -> void:
    var menu = get_tree().get_first_node_in_group("upgrade_menu")
    if menu:
        menu.finish_upgrade(upgrade_id)
