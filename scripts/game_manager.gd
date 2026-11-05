extends Node

signal player_died(player: Player)
signal player_boost(player: Player, amount_left: float)
signal player_damaged(player: Player, damage: float, new_hp)
signal player_healed(player: Player, heal: float, new_hp: float)
signal player_levelup(player: Player)
signal score_changed(new_score: int)
signal game_ended()

var selected_character: CharacterData
var score: int = 0

func boost_player(player: Player, amount_left: float):
    player_boost.emit(player, amount_left)

func damage_player(player: Player, damage: float) -> void:
    if player.current_hp <= 0.0:
        return
        
    player.current_hp = maxf(player.current_hp - damage, 0.0)
    player_damaged.emit(player, damage, player.current_hp)
    if player.current_hp <= 0.0:
        player_died.emit(player)

func heal_player(player: Player, heal: float) -> void:
    player.current_hp = minf(player.current_hp + heal, player.max_hp)
    player_healed.emit(player, heal, player.current_hp)

func levelup_player(player: Player):
    player.current_level += 1
    player_levelup.emit(player)

func add_score(points) -> void:
    score += points
    score_changed.emit(score)

func end_game() -> void:
    game_ended.emit()

func reset() -> void:
    score = 0
