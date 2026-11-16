extends CanvasLayer

@onready var restart_button = %RestartButton
@onready var mainmenu_button = %MainMenuButton
@onready var score_label = %ScoreLabel
@onready var survival_time_label = %SurvivalTimeLabel
@onready var damage_dealt_label = %DamageDealtLabel
@onready var damage_taken_label = %DamageTakenLabel
@onready var projectile_label = %ProjectileLabel
@onready var level_label = %LevelLabel
@onready var enemies_killed_label = %EnemiesKilledLabel
@onready var xp_label = %XPLabel
@onready var deaths_label = %DeathsLabel
@onready var best_run_label = %BestRunLabel
@onready var highest_level_label = %HighestLevelLabel

func _on_main_menu_button_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")

func _on_restart_button_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_ready() -> void:
    update_results()
    
func update_results() -> void:
    var stats = SaveManager.last_run_stats
    score_label.text = "Score: %s" % stats.get(SaveManager.Stat.SCORE, 0)
    survival_time_label.text = "Time Survived: %s" % _format_time(
        int(stats.get(SaveManager.Stat.TIME_SURVIVED, 0))
    )
    damage_dealt_label.text = "Damage Dealt: %s" % stats.get(SaveManager.Stat.DAMAGE_DEALT, 0)
    damage_taken_label.text = "Damage Taken: %s" % stats.get(SaveManager.Stat.DAMAGE_TAKEN, 0)
    projectile_label.text = "Projectiles: %s" % stats.get(SaveManager.Stat.PROJECTILES_SHOT, 0)
    level_label.text = "Levels Gained: %s" % stats.get(SaveManager.Stat.LEVEL_UP, 0)
    enemies_killed_label.text = "Enemies Killed: %s" % stats.get(SaveManager.Stat.ENEMIES_KILLED, 0)
    xp_label.text = "XP Collected: %s" % stats.get(SaveManager.Stat.XP_COLLECTED, 0)
    deaths_label.text = "Deaths: %s" % stats.get(SaveManager.Stat.PLAYERS_DIED, 0)
    best_run_label.text = "Longest Run: %s" % _format_time(
        int(SaveManager.total_stats.get(SaveManager.Stat.LONGEST_RUN, 0))
    )
    highest_level_label.text = "Highest Level: %s" % SaveManager.total_stats.get(
        SaveManager.Stat.HIGHEST_LEVEL,
        0
    )

func _format_time(total_seconds: int) -> String:
    var minutes := total_seconds / 60
    var seconds := total_seconds % 60
    return "%02d:%02d" % [minutes, seconds]
    
