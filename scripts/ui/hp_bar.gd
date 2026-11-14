extends Control

@onready var hp_bar: TextureProgressBar = %TextureProgressBar
@onready var hp_label: Label = %HPLabel

func _ready() -> void:
    GameManager.player_damaged.connect(update_hp)
    GameManager.player_healed.connect(update_hp)

func update_hp(player: Player, _amount: float, new_hp: float) -> void:
    if not player.is_multiplayer_authority():
        return
    hp_bar.max_value = player.max_hp
    hp_bar.value = new_hp

    var percentage := (new_hp / player.max_hp) * 100.0
    hp_label.text = "%d%%" % int(percentage)
