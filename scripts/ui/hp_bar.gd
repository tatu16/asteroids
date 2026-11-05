extends PanelContainer

@onready var hp_bar = %TextureProgressBar

func _ready() -> void:
    GameManager.player_damaged.connect(update_hp)
    GameManager.player_healed.connect(update_hp)

func update_hp(player: Player, _amount: float, new_hp: float) -> void:
    hp_bar.value = new_hp
    
