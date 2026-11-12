shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.35, 1.0, 0.2, 1.0);
uniform float glow_strength : hint_range(0.0, 5.0) = 2.0;
uniform float glow_opacity : hint_range(0.0, 1.0) = 0.8;
uniform float glow_size : hint_range(0.0, 8.0) = 4.0;

void vertex() {
    VERTEX += sign(VERTEX) * glow_size;
}

void fragment() {
    vec2 texture_ratio = vec2(1.0) / (vec2(1.0) + 2.0 * glow_size * TEXTURE_PIXEL_SIZE);
    vec2 texture_uv = (UV - vec2(0.5)) / texture_ratio + vec2(0.5);
    vec4 base = vec4(0.0);
    if (all(greaterThanEqual(texture_uv, vec2(0.0))) &&
            all(lessThanEqual(texture_uv, vec2(1.0)))) {
        base = texture(TEXTURE, texture_uv);
    }

    float surrounding_alpha = 0.0;

    for (int i = 0; i < 16; i++) {
        float angle = float(i) * 0.3926991;
        vec2 direction = vec2(cos(angle), sin(angle));
        for (int radius = 1; radius <= 5; radius++) {
            float distance = float(radius) * 0.2;
            vec2 sample_uv = texture_uv +
                    direction * TEXTURE_PIXEL_SIZE * glow_size * distance;
            if (all(greaterThanEqual(sample_uv, vec2(0.0))) &&
                    all(lessThanEqual(sample_uv, vec2(1.0)))) {
                float sample_alpha = texture(TEXTURE, sample_uv).a;
                float weight = 1.0 - distance;
                surrounding_alpha += sample_alpha * weight;
            }
        }
    }

    surrounding_alpha /= 16.0 * 2.5;
    float halo_alpha = surrounding_alpha * (1.0 - base.a) * glow_opacity;
    vec3 color = base.rgb + glow_color.rgb * halo_alpha * glow_strength;
    COLOR = vec4(color, base.a + halo_alpha * glow_color.a);
}
