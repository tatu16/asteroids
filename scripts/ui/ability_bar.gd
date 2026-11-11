extends Control

@onready var ability_bar: TextureProgressBar = %TextureProgressBar
@onready var ability_label: Label = %AbilityLabel

func _ready() -> void:
    GameManager.player_use_ability.connect(update_ability)

func update_ability(player: Player, amount_left: float) -> void:
    ability_bar.max_value = player.max_ability
    ability_bar.value = amount_left

    var percentage := (amount_left / player.max_ability) * 100.0
    ability_label.text = "%d%%" % int(percentage)
