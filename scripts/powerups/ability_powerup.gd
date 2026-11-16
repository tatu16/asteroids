extends PowerUp

@export var ability: float = 100

func _ready() -> void:
    pickup_text = "+%s Ability" % ability
    pickup_color = Color("e7c700ff")
    super._ready()

func apply_effect(player: Player) -> void:
     GameManager.add_player_ability(player, ability)
