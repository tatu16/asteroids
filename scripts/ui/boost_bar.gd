extends Control

@onready var boost_bar = %TextureProgressBar

func _ready() -> void:
    GameManager.player_boost.connect(update_boost)

func update_boost(player: Player, amount_left: float) -> void:
    boost_bar.value = amount_left
    
