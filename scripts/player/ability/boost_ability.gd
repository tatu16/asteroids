class_name BoostAbility
extends PlayerAbility

@export var minimum_active_time: float = 0.5
@export var cooldown_time: float = 1.0

var active_timer: float = 0.0
var cooldown_timer: float = 0.0

func process_ability(delta: float) -> void:
    var requested := Input.is_action_pressed("ability") and player.ability_energy > 0.0
    set_active(requested)

    if active:
        player.ability_energy = maxf(
            player.ability_energy - player.ability_drain * delta,
            0.0
        )
    else:
        player.ability_energy = minf(
            player.ability_energy + player.ability_recovery * delta,
            player.max_ability
        )

    GameManager.use_ability_player(player, player.ability_energy)

func movement_multiplier() -> float:
    return player.ability_multiplier if active else 1.0
