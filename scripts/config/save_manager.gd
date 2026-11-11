extends Node

const SAVE_PATH = "user://stats.save"

enum Stat {
    ENEMIES_KILLED,
    DAMAGE_DEALT,
    DAMAGE_TAKEN,
    PROJECTILES_SHOT,
    XP_COLLECTED,
    TIME_SURVIVED,
    PLAYERS_DIED,
    GAMES_PLAYED,
    LEVEL_UP,
    LONGEST_RUN,
    HIGHEST_LEVEL,
    SCORE,
}

# Player's last run's stats
var last_run_stats: Dictionary = {}
# Server-side run stats
var run_stats: Dictionary = {}
# Client-side lifetime stats
var total_stats: Dictionary = {}

func create_player_stats() -> Dictionary:
    var stats := {}
    for stat in Stat.values():
        stats[stat] = 0

    return stats

# SERVER: Initialize a player's run stats
func add_player(peer_id: int) -> void:
    if not multiplayer.is_server():
        return
    run_stats[peer_id] = create_player_stats()

# SERVER: Track a player's stats
func add_run_stat(peer_id: int, stat: Stat, amount: float = 1.0) -> void:
    if not multiplayer.is_server():
        return
    if not run_stats.has(peer_id):
        return

    run_stats[peer_id][stat] += amount

# SERVER: Reset all run stats
func reset_run_stats() -> void:
    if not multiplayer.is_server():
        return
        
    run_stats.clear()
    add_player(1)
    for peer_id in multiplayer.get_peers():
        add_player(peer_id)

# SERVER: Get an individual player's run stats
func get_run_stats(peer_id: int) -> Dictionary:
    if not run_stats.has(peer_id):
        return {}

    return run_stats[peer_id].duplicate()

# CLIENT: Add finished run stats to lifetime stats
func add_finished_run(stats: Dictionary) -> void:
    if total_stats.is_empty():
        total_stats = create_player_stats()

    total_stats[Stat.GAMES_PLAYED] += 1
    for stat in Stat.values():
        if stat == Stat.GAMES_PLAYED:
            continue

        if stat == Stat.LONGEST_RUN or stat == Stat.HIGHEST_LEVEL:
            total_stats[stat] = maxi(
                total_stats[stat],
                stats.get(stat, 0)
            )
        else:
            total_stats[stat] += stats.get(stat, 0)

    save()

# CLIENT: Save lifetime stats
func save() -> void:
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_error("Could not save stats!")
        return

    file.store_var(total_stats)
    file.close()

# CLIENT: Load lifetime stats
func load_save() -> void:
    total_stats = create_player_stats()
    
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return

    var saved_stats = file.get_var()
    file.close()
    if saved_stats is Dictionary:
        for stat in Stat.values():
            total_stats[stat] = saved_stats.get(stat, 0)

func _ready() -> void:
    load_save()
