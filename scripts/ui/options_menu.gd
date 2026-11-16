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
    
    original_values[resolution_option] = resolution_option.selected
    original_values[windowmode_option] = windowmode_option.selected
    
    
func check_for_changes() -> bool:
    for option in original_values:
        if option.selected != original_values[option]:
            return true

    return false
    
func apply_resolution(index: int) -> void:
    if index >= 0:
        var resolution = resolutions[index]
        DisplayServer.window_set_size(resolution)

func apply_windowmode(index: int) -> void:
    match index:
        0: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        1: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
        2: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_close_button_pressed() -> void:
    if check_for_changes():
        var confirm = confirm_menu_scene.instantiate()
        confirm.confirmation_text = "Close without saving?"
        confirm.confirmation_result.connect(_on_confirmation_result)
        add_child(confirm)
        return
    self.queue_free()

func _on_confirmation_result(confirmed: bool) -> void:
    if confirmed:
        self.queue_free()
    else:
        print("close cancelled")

func _on_apply_button_pressed() -> void:
    var windowmode_index = windowmode_option.selected
    var resolution_index = resolution_option.selected
    
    apply_resolution(resolution_index)
    apply_windowmode(windowmode_index)
    
    for option in original_values:
        original_values[option] = option.selected
