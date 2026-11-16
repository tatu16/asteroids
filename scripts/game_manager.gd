extends Node

signal player_died(player: Player)
signal player_add_ability(player: Player, amount: float)
signal player_use_ability(player: Player, amount_left: float)
signal player_damaged(player: Player, damage: float, new_hp)
signal player_healed(player: Player, heal: float, new_hp: float)
signal player_levelup(player: Player)
signal player_xp_changed(peer_id: int, current_xp: float, xp_required: float, level: int)
signal score_changed(new_score: int)
signal coins_changed(new_coins: int)
signal game_ended()
signal character_selected(button: Button)

const SPRITE_ROTATION_OFFSET := deg_to_rad(90)
var selected_character: CharacterData
var score: int = 0
var coins: int = 0

func use_ability_player(player: Player, amount_left: float) -> void:
    if not multiplayer.is_server():
        return
    update_player_ability.rpc(player.get_path(), amount_left)

func add_player_ability(player: Player, amount: float) -> void:
    if not multiplayer.is_server():
        return
    apply_player_ability.rpc(player.get_path(), amount)

@rpc("authority", "call_local", "unreliable")
func update_player_ability(player_path: NodePath, amount_left: float) -> void:
    var player = get_node_or_null(player_path) as Player
    if player == null:
        return
    player_use_ability.emit(player, amount_left)

@rpc("authority", "call_local", "unreliable")
func apply_player_ability(player_path: NodePath, amount: float) -> void:
    var player = get_node_or_null(player_path) as Player
    if player == null:
        return
    player_add_ability.emit(player, amount)

func damage_player(player: Player, damage: float) -> void:
    if not multiplayer.is_server():
        return
    if player.current_hp <= 0.0 or player.is_dead or player.is_invulnerable:
        return
        
    var peer_id = player.get_multiplayer_authority()
    SaveManager.add_run_stat(
        peer_id,
        SaveManager.Stat.DAMAGE_TAKEN,
        damage
    )
    
    apply_player_damage.rpc(player.get_path(), damage)

@rpc("authority", "call_local", "reliable")
func apply_player_damage(player_path: NodePath, damage: float) -> void:
    var player = get_node_or_null(player_path) as Player
    if player == null:
        return
    if player.current_hp <= 0.0 or player.is_dead or player.is_invulnerable:
        return

    player.current_hp = maxf(player.current_hp - damage, 0.0)
    player_damaged.emit(player, damage, player.current_hp)
    if player.current_hp <= 0.0:
        player.die()
        player_died.emit(player)

func heal_player(player: Player, heal: float) -> void:
    if not multiplayer.is_server():
        return
    apply_player_heal.rpc(player.get_path(), heal)

@rpc("authority", "call_local", "reliable")
func apply_player_heal(player_path: NodePath, heal: float) -> void:
    var player = get_node_or_null(player_path) as Player
    if player == null:
        return
        
    player.current_hp = minf(player.current_hp + heal, player.max_hp)
    player_healed.emit(player, heal, player.current_hp)

@rpc("authority", "call_local", "reliable")
func update_player_xp(peer_id: int, current_xp: float, xp_required: float, level: int) -> void:
    player_xp_changed.emit(
        peer_id,
        current_xp,
        xp_required,
        level
    )

func add_score(points: int) -> void:
    if not multiplayer.is_server():
        return
    score += points
    update_score.rpc(score)

func add_coins(amount: int) -> void:
    if not multiplayer.is_server():
        return
    coins += amount
    update_coins.rpc(coins)

@rpc("authority", "call_local", "reliable")
func update_score(new_score: int) -> void:
    score = new_score
    score_changed.emit(score)

@rpc("authority", "call_local", "reliable")
func update_coins(new_coins: int) -> void:
    coins = new_coins
    coins_changed.emit(coins)

func end_game() -> void:
    game_ended.emit()

func reset() -> void:
    if not multiplayer.is_server():
        return
    score = 0
    coins = 0
    update_score.rpc(score)
    update_coins.rpc(coins)
