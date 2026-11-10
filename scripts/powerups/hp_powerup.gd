extends PowerUp

@export var hp: float = 20

func apply_effect(player: Player) -> void:
     GameManager.heal_player(player, hp)
