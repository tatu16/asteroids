shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.89, 0.0, 0.11, 1.0);

uniform float glow_radius : hint_range(0.05, 1.0) = 0.65;
uniform float glow_intensity : hint_range(0.0, 5.0) = 1.5;
uniform float glow_opacity : hint_range(0.0, 1.0) = 0.6;
uniform float glow_softness : hint_range(0.1, 5.0) = 2.0;

void fragment() {
    vec2 centered_uv = UV - vec2(0.5);
    float dist = length(centered_uv);

    // Smooth radial falloff
    float normalized_dist = dist / glow_radius;
    float glow = exp(-pow(normalized_dist * glow_softness, 2.0) * 2.0);

    // Fade out at the outer radius
    glow *= 1.0 - smoothstep(0.7, 1.0, normalized_dist);

    COLOR = vec4(
        glow_color.rgb * glow_intensity,
        glow * glow_opacity * glow_color.a
    );
}