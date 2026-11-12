shader_type canvas_item;
render_mode blend_add;

uniform vec4 glow_color : source_color = vec4(0.35, 1.0, 0.2, 1.0);
uniform float glow_strength : hint_range(0.0, 5.0) = 2.0;
uniform float glow_opacity : hint_range(0.0, 1.0) = 0.8;
uniform float glow_size : hint_range(0.0, 8.0) = 4.0;

void fragment() {
    float glow_alpha = 0.0;

    for (int i = 0; i < 16; i++) {
        float angle = float(i) * 0.3926991;
        vec2 direction = vec2(cos(angle), sin(angle));
        for (int radius = 1; radius <= 5; radius++) {
            float distance = float(radius) * 0.2;
            vec2 sample_uv = UV +
                    direction * TEXTURE_PIXEL_SIZE * glow_size * distance;
            float sample_alpha = texture(TEXTURE, sample_uv).a;
            float weight = 1.0 - distance;
            glow_alpha += sample_alpha * weight;
        }
    }

    glow_alpha /= 16.0 * 2.5;
    COLOR = vec4(glow_color.rgb * glow_strength,
            glow_alpha * glow_opacity * glow_color.a);
}
