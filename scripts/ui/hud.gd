extends CanvasLayer

@onready var time_label: Label = %TimeLabel

func _ready() -> void:
    pass # Replace with function body.

func update_time(time: int) -> void:
    var minutes := time / 60
    var seconds := time % 60
    time_label.text = "%02d:%02d" % [minutes, seconds]
