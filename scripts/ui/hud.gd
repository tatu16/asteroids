extends CanvasLayer

@onready var time_label: Label = %TimeLabel
@onready var level_bar: TextureProgressBar = %Level
@onready var level_label: Label = %LevelLabel
@onready var xp_label: Label = %XPLabel
@onready var score_label: Label = %Score
@onready var coins_label: Label = %Coins

var spectator_panel: Control = null
var respawn_timer_label: Label = null
var spectating_label: Label = null
var respawn_countdown: float = -1.0
var guide_overlay: Control = null

const SPECTATOR_OVERLAY_SCENE: PackedScene = preload("res://scenes/ui/spectator_overlay.tscn")
const GUIDE_OVERLAY_SCENE: PackedScene = preload("res://scenes/ui/guide_overlay.tscn")

func _ready() -> void:
    GameManager.score_changed.connect(update_score)
    GameManager.coins_changed.connect(update_coins)

    spectator_panel = SPECTATOR_OVERLAY_SCENE.instantiate()
    $Control.add_child(spectator_panel)
    spectator_panel.visible = false
    respawn_timer_label = spectator_panel.get_node(
        "PanelContainer/MarginContainer/VBoxContainer/TimerLabel")
    spectating_label = spectator_panel.get_node(
        "PanelContainer/MarginContainer/VBoxContainer/SpectatingLabel")
    
    guide_overlay = GUIDE_OVERLAY_SCENE.instantiate()
    $Control.add_child(guide_overlay)
    guide_overlay.visible = true
    await get_tree().create_timer(10.0).timeout
    guide_overlay.visible = false

func _process(delta: float) -> void:
    var world = get_tree().root.find_child("World", true, false)
    if world != null and world.is_paused:
        return
        
    if respawn_countdown > 0.0:
        respawn_countdown = maxf(respawn_countdown - delta, 0.0)
        if respawn_timer_label != null:
            respawn_timer_label.text = "Respawning in: %ds" % ceili(respawn_countdown)
            if respawn_countdown <= 0.0:
                respawn_timer_label.text = "Respawning..."

func show_spectator_overlay(target_name: String, countdown: float = -1.0) -> void:
    if spectator_panel == null:
        return
    spectator_panel.visible = true
    update_spectating_name(target_name)
    if countdown >= 0.0:
        respawn_countdown = countdown
        respawn_timer_label.visible = true
        respawn_timer_label.text = "Respawning in: %ds" % ceili(countdown)
    else:
        respawn_countdown = -1.0
        respawn_timer_label.visible = false

func update_spectating_name(target_name: String) -> void:
    if spectating_label != null:
        if target_name.is_empty():
            spectating_label.text = "SPECTATING"
        else:
            spectating_label.text = "SPECTATING: %s" % target_name

func hide_spectator_overlay() -> void:
    if spectator_panel != null:
        spectator_panel.visible = false
    respawn_countdown = -1.0

func update_time(time: int) -> void:
    var minutes := time / 60
    var seconds := time % 60
    time_label.text = "%02d:%02d" % [minutes, seconds]

func update_xp(current_xp: float, xp_required: float, level: int) -> void:
    level_bar.max_value = xp_required
    level_bar.value = current_xp
    level_label.text = "Lv: %d" % level
    xp_label.text = "%d / %d XP" % [current_xp, xp_required]

func update_score(score: int) -> void:
    score_label.text = "Score: %d" % score

func update_coins(coins: int) -> void:
    coins_label.text = "Coins: %d" % coins
