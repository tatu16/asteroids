extends CanvasLayer

signal confirmation_result(confirmed: bool)

@export var confirmation_text: String = "Are you sure?"
@onready var confirm_button: Button = %ConfirmButton
@onready var return_button: Button = %ReturnButton
@onready var confirmation_label: Label = %Label

func _on_confirm_button_pressed() -> void:
    confirmation_result.emit(true)
    queue_free()

func _on_return_button_pressed() -> void:
    confirmation_result.emit(false)
    queue_free()

func _ready() -> void:
    confirmation_label.text = confirmation_text
