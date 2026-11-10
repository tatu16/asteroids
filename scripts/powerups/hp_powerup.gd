extends PowerUp

@export var hp: float = 20

func _ready() -> void:
    pickup_text = "+%s HP" % hp
    pickup_color = Color("e6002cff")
    super._ready()

func apply_effect(player: Player) -> void:
     GameManager.heal_player(player, hp)
