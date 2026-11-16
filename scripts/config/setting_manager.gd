extends Node

const SETTINGS_PATH = "user://settings.json"

enum Settings {
    RESOLUTION,
    WINDOW_MODE
}

const DEFAULT_SETTINGS = {
    Settings.RESOLUTION: 2,
    Settings.WINDOW_MODE: 0
}

var current_settings: Dictionary = {}

func _ready() -> void:
    load_settings()
    apply_all_settings()

func load_settings() -> void:
    current_settings = DEFAULT_SETTINGS.duplicate()
    
    if not FileAccess.file_exists(SETTINGS_PATH):
        return

    var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
    if file == null:
        push_warning("Could not open settings file.")
        return

    var saved_settings = file.get_var()
    file.close()

    if saved_settings is Dictionary:
        for setting in Settings.values():
            if saved_settings.has(setting):
                current_settings[setting] = saved_settings[setting]

func save_settings() -> void:
    var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)

    if file == null:
        push_error("Could not save settings.")
        return

    file.store_var(current_settings)
    file.close()

func get_setting(setting: Settings) -> Variant:
    return current_settings.get(setting, DEFAULT_SETTINGS.get(setting))

func set_setting(setting: Settings, value: Variant) -> void:
    current_settings[setting] = value

func apply_resolution(index: int) -> void:
    var resolutions: Array[Vector2i] = [
        Vector2i(1280, 720),
        Vector2i(1600, 900),
        Vector2i(1920, 1080),
        Vector2i(2560, 1440)
    ]

    if index < 0 or index >= resolutions.size():
        return

    DisplayServer.window_set_size(resolutions[index])

func apply_window_mode(index: int) -> void:
    match index:
        0: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        1: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
        2: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

func apply_all_settings() -> void:
    apply_resolution(get_setting(Settings.RESOLUTION))
    apply_window_mode(get_setting(Settings.WINDOW_MODE))
