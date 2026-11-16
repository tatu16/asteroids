shader_type canvas_item;
render_mode blend_add;

uniform vec4 glow_color : source_color = vec4(0.35, 1.0, 0.2, 1.0);
uniform float glow_strength : hint_range(0.0, 5.0) = 2.0;
uniform float glow_opacity : hint_range(0.0, 1.0) = 0.8;
uniform float glow_size : hint_range(0.0, 8.0) = 4.0;
uniform vec4 outline_color : source_color = vec4(0.7, 1.0, 0.2, 1.0);
uniform float outline_strength : hint_range(0.0, 5.0) = 2.5;
uniform float outline_opacity : hint_range(0.0, 1.0) = 0.9;
uniform float outline_width : hint_range(0.0, 8.0) = 2.0;

void fragment() {
    float glow_alpha = 0.0;
    float outline_alpha = 0.0;
    float texture_alpha = texture(TEXTURE, UV).a;

    for (int i = 0; i < 16; i++) {
        float angle = float(i) * 0.3926991;
        vec2 direction = vec2(cos(angle), sin(angle));
        vec2 outline_uv = UV +
                direction * TEXTURE_PIXEL_SIZE * outline_width;
        outline_alpha = max(
            outline_alpha,
            texture(TEXTURE, outline_uv).a
        );
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
    outline_alpha *= 1.0 - texture_alpha;
    float glow_output_alpha = glow_alpha * glow_opacity * glow_color.a;
    float outline_output_alpha = (
        outline_alpha * outline_opacity * outline_color.a
    );
    vec3 output_color = (
        glow_color.rgb * glow_strength * glow_output_alpha
        + outline_color.rgb * outline_strength * outline_output_alpha
    );
    COLOR = vec4(
        output_color,
        max(glow_output_alpha, outline_output_alpha)
    );
}
