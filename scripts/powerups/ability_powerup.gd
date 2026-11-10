extends PowerUp

@export var ability: float = 100

func apply_effect(player: Player) -> void:
     GameManager.add_player_ability(player, ability)
