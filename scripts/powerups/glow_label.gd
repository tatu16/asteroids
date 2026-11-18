extends Node2D

@onready var label: Label = %Label
@onready var glow_label: Label = %GlowLabel


func show_text(
    message: String,
    color: Color = Color.WHITE,
    start_position: Vector2 = Vector2.ZERO,
    font_size: int = 0
) -> void:

    global_position = start_position

    glow_label.material = null
    glow_label.text = message

    glow_label.add_theme_color_override(
        "font_color",
        Color(color.r, color.g, color.b, 0.15)
    )

    glow_label.add_theme_color_override(
        "font_outline_color",
        Color(color.r, color.g, color.b, 0.85)
    )

    # Scale outline/shadow sizes relative to font size so the glow
    # stays proportional and doesn't overwhelm larger text.
    var base_size := font_size if font_size > 0 else 16
    var glow_outline  := maxi(3, base_size / 4)
    var glow_shadow   := maxi(2, base_size / 5)
    var label_outline := maxi(2, base_size / 6)
    var label_shadow  := maxi(1, base_size / 10)

    if font_size > 0:
        glow_label.add_theme_font_size_override("font_size", font_size)
        label.add_theme_font_size_override("font_size", font_size)

    glow_label.add_theme_constant_override("outline_size", glow_outline)

    glow_label.add_theme_color_override(
        "font_shadow_color",
        Color(color.r, color.g, color.b, 0.45)
    )

    glow_label.add_theme_constant_override("shadow_outline_size", glow_shadow)
    glow_label.add_theme_constant_override("shadow_offset_x", 0)
    glow_label.add_theme_constant_override("shadow_offset_y", 0)

    glow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    glow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    glow_label.z_index = -1

    label.text = message
    label.add_theme_color_override("font_color", color)

    label.add_theme_color_override(
        "font_outline_color",
        Color(0.015, 0.015, 0.025, 1.0)
    )

    label.add_theme_constant_override("outline_size", label_outline)

    label.add_theme_color_override(
        "font_shadow_color",
        Color(0.0, 0.0, 0.0, 0.7)
    )

    label.add_theme_constant_override("shadow_outline_size", label_shadow)
    label.add_theme_constant_override("shadow_offset_x", 1)
    label.add_theme_constant_override("shadow_offset_y", 2)

    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

    # Start slightly squashed, slightly transparent.
    scale = Vector2(0.6, 0.4)
    modulate.a = 0.0

    var drift_x = randf_range(-28.0, 28.0)
    var float_position = start_position + Vector2(drift_x, -72.0)

    var tween := create_tween()
    tween.set_parallel(true)

    # Pop: squash -> overshoot wide -> settle.
    tween.tween_property(
        self,
        "scale",
        Vector2(1.35, 1.35),
        0.12
    ).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

    # Fade in fast.
    tween.tween_property(
        self,
        "modulate:a",
        1.0,
        0.08
    )

    # Settle to natural size.
    tween.tween_property(
        self,
        "scale",
        Vector2.ONE,
        0.18
    ).set_delay(0.12).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

    # Float upwards with slight arc via drift.
    tween.tween_property(
        self,
        "global_position",
        float_position,
        0.9
    ).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

    # Hold readable, then fade out.
    tween.tween_property(
        self,
        "modulate:a",
        0.0,
        0.28
    ).set_delay(0.62)

    tween.chain().tween_callback(queue_free)
