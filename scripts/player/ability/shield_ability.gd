class_name PlayerShield
extends PlayerAbility

@export var minimum_active_time: float = 0.5
@export var cooldown_time: float = 1.0
@export var empty_energy_cooldown: float = 3.0

var active_timer: float = 0.0
var cooldown_timer: float = 0.0

func process_ability(delta: float) -> void:
    active_timer = maxf(active_timer - delta, 0.0)
    cooldown_timer = maxf(cooldown_timer - delta, 0.0)

    var requested := Input.is_action_pressed("ability")
    
    if active:
        player.ability_energy = maxf(
            player.ability_energy - player.ability_drain * delta,
            0.0
        )
        if player.ability_energy <= 0.0:
            deactivate(true)
        elif not requested and active_timer <= 0.0:
            deactivate()
    else:
        player.ability_energy = minf(
            player.ability_energy + player.ability_recovery * delta,
            player.max_ability
        )
        if requested and player.ability_energy > 0.0 and cooldown_timer <= 0.0:
            activate()
            
    GameManager.use_ability_player(player, player.ability_energy)


func activate() -> void:
    if active:
        return

    active_timer = minimum_active_time
    set_active(true)
    add_to_group("player_shields")

func deactivate(energy_empty: bool = false) -> void:
    if not active:
        return

    set_active(false)
    remove_from_group("player_shields")
    
    if energy_empty:
        cooldown_timer = empty_energy_cooldown
    else:
        cooldown_timer = cooldown_time
