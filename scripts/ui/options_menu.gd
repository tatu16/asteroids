extends CanvasLayer

@onready var apply_button: Button = %ApplyButton
@onready var close_button: Button = %CloseButton
@onready var resolution_option: OptionButton = %Resolution
@onready var windowmode_option: OptionButton = %WindowMode

const confirm_menu_scene = preload("res://scenes/menus/confirm_menu.tscn")

var original_values: Dictionary = {}
var resolutions: Array[Vector2i] = [
    Vector2i(1280, 720),
    Vector2i(1600, 900),
    Vector2i(1920, 1080),
    Vector2i(2560, 1440),
]

func _ready() -> void:
    for resolution in resolutions:
        resolution_option.add_item(
            str(resolution.x) + "x" + str(resolution.y)
        )

    windowmode_option.add_item("Windowed")
    windowmode_option.add_item("Fullscreen")
    windowmode_option.add_item("Borderless Fullscreen")
    
    resolution_option.select(SettingManager.get_setting(SettingManager.Settings.RESOLUTION))
    windowmode_option.select(SettingManager.get_setting(SettingManager.Settings.WINDOW_MODE))
   
    update_original_values()
    
func update_original_values() -> void:
    original_values = {
        resolution_option: resolution_option.selected,
        windowmode_option: windowmode_option.selected
    }


func check_for_changes() -> bool:
    for option in original_values: 
        if option.selected != original_values[option]:
            return true
    return false
    
func _on_close_button_pressed() -> void:
    if check_for_changes():
        var confirm = confirm_menu_scene.instantiate()
        confirm.confirmation_text = "Close without saving?"
        confirm.confirmation_result.connect(_on_confirmation_result)
        add_child(confirm)
        return
        
    queue_free()

func _on_confirmation_result(confirmed: bool) -> void:
    if confirmed:
        queue_free()

func _on_apply_button_pressed() -> void:
    SettingManager.set_setting(SettingManager.Settings.RESOLUTION,resolution_option.selected)
    SettingManager.set_setting(SettingManager.Settings.WINDOW_MODE,windowmode_option.selected)

    SettingManager.apply_all_settings()
    SettingManager.save_settings()
    update_original_values()
