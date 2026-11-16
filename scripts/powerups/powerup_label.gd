
extends Node2D

@onready var label: Label = %Label
@onready var glow_label: Label = %GlowLabel

var glow_material: ShaderMaterial

func _ready() -> void:
    glow_material = ShaderMaterial.new()
    glow_material.shader = preload("res://resources/shaders/label_glow.gdshader")
    glow_label.material = glow_material
    glow_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_text(
    message: String,
    color: Color = Color.WHITE,
    target_position: Vector2 = Vector2.ZERO
) -> void:

    # Main text.
    label.text = message
    label.add_theme_color_override("font_color", color)
    label.modulate = Color.WHITE

    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

    label.add_theme_color_override(
        "font_outline_color",
        Color(0.02, 0.02, 0.04, 0.9)
    )
    label.add_theme_constant_override("outline_size", 2)

    # Glow text.
    glow_label.text = message
    glow_label.add_theme_color_override("font_color", color)
    glow_label.modulate = Color.WHITE

    glow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    glow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

    glow_material.set_shader_parameter("glow_opacity", 0.65)
    glow_material.set_shader_parameter("glow_strength", 1.5)
    glow_material.set_shader_parameter("offset", 5.0)

    # Initial state.
    label.scale = Vector2(0.5, 0.5)
    glow_label.scale = Vector2(0.5, 0.5)

    label.modulate.a = 0.0
    glow_label.modulate.a = 0.0

    # Animation.
    var tween := create_tween()
    tween.set_parallel(true)

    # Pop text.
    for target in [label, glow_label]:
        tween.tween_property(
            target,
            "scale",
            Vector2(1.2, 1.2),
            0.15
        ).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

        tween.tween_property(
            target,
            "modulate:a",
            1.0,
            0.12
        )

        tween.tween_property(
            target,
            "scale",
            Vector2.ONE,
            0.15
        ).set_delay(0.15)

        tween.tween_property(
            target,
            "modulate:a",
            0.0,
            0.3
        ).set_delay(0.6)

    # Float upward.
    tween.tween_property(
        self,
        "global_position",
        target_position,
        0.9
    ).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

    tween.chain().tween_callback(queue_free)
