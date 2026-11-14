extends CanvasLayer

signal upgrade_finished

const UPGRADE_DEFINITIONS: Array[Dictionary] = [
    {
        "id": "attack_speed",
        "name": "Rapid Fire",
        "description": "Increase attack speed by 15%",
        "image": preload("res://assets/sprites/ui/ui_upgrade_card_speed.png"),
    },
    {
        "id": "projectile_count",
        "name": "Multishot",
        "description": "Fire one additional projectile",
        "image": preload("res://assets/sprites/ui/ui_upgrade_card_shot.png"),
    },
    {
        "id": "damage",
        "name": "Heavy Rounds",
        "description": "Increase projectile damage by 20%",
        "image": preload("res://assets/sprites/ui/ui_upgrade_card_shot.png"),
    },
    {
        "id": "max_hp",
        "name": "Reinforced Hull",
        "description": "Increase maximum health by 20",
        "image": preload("res://assets/sprites/ui/ui_upgrade_card_health.png"),
    },
    {
        "id": "boost",
        "name": "Afterburners",
        "description": "Increase boost speed by 15%",
        "image": preload("res://assets/sprites/ui/ui_upgrade_card_speed.png"),
        "ability_specific": true,
    },
]

@onready var card_container: GridContainer = %CardContainer

func _ready() -> void:
    add_to_group("upgrade_menu")
    _setup_cards()

func _setup_cards() -> void:
    var player := _get_player()
    var choices: Array[Dictionary] = []
    var maxed_choices: Array[Dictionary] = []
    for definition in UPGRADE_DEFINITIONS:
        if definition.get("ability_specific", false):
            if player == null or not player.supports_upgrade(definition["id"]):
                continue
        var upgrade: Dictionary = definition.duplicate()
        var level := _get_upgrade_level(upgrade["id"])
        var max_level := -1
        if player != null:
            max_level = player.get_upgrade_max_level(upgrade["id"])
        upgrade["level"] = level
        upgrade["max_level"] = max_level
        upgrade["is_maxed"] = max_level >= 0 and level >= max_level
        if upgrade["is_maxed"]:
            maxed_choices.append(upgrade)
        else:
            choices.append(upgrade)
    if choices.is_empty():
        choices = maxed_choices
    choices.shuffle()
    var cards := card_container.get_children()
    for index in cards.size():
        var card = cards[index]
        var upgrade: Dictionary = choices[index % choices.size()].duplicate()
        card.setup(upgrade)

func _get_player() -> Player:
    var world = get_tree().root.find_child("World", true, false)
    if world == null:
        return null
    if world.has_method("get_player"):
        return world.get_player(multiplayer.get_unique_id())
    var players = world.get_node_or_null("Players")
    if players != null:
        var p = players.get_node_or_null(str(multiplayer.get_unique_id())) as Player
        if p != null:
            return p
    return world.get_node_or_null(str(multiplayer.get_unique_id())) as Player

func _get_upgrade_level(upgrade_id: String) -> int:
    var player := _get_player()
    if player == null:
        return 1
    return player.get_upgrade_level(upgrade_id)

func finish_upgrade(upgrade_id: String) -> void:
    var world = get_tree().root.find_child("World", true, false)
    if world != null:
        var player = _get_player()
        if player != null:
            if multiplayer.is_server():
                world.request_upgrade(player.get_path(), upgrade_id)
            else:
                world.request_upgrade.rpc_id(1, player.get_path(), upgrade_id)
    upgrade_finished.emit()
    queue_free()
