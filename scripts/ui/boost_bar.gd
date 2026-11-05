extends Control

@onready var boost_bar: TextureProgressBar = %TextureProgressBar
@onready var boost_label: Label = %BoostLabel

func _ready() -> void:
    GameManager.player_boost.connect(update_boost)

func update_boost(player: Player, amount_left: float) -> void:
    boost_bar.max_value = player.max_boost
    boost_bar.value = amount_left

    var percentage := (amount_left / player.max_boost) * 100.0
    boost_label.text = "%d%%" % int(percentage)
