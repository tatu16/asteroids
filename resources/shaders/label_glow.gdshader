shader_type canvas_item;

uniform float offset : hint_range(0.0, 10.0) = 2.0;
uniform float glow_opacity : hint_range(0.0, 1.0) = 0.65;
uniform float glow_strength : hint_range(0.0, 3.0) = 1.5;

void fragment() {
    vec2 px = TEXTURE_PIXEL_SIZE * offset;

    float center = texture(TEXTURE, UV).a;
    float blur = 0.0;

    // Sample surrounding pixels.
    blur += texture(TEXTURE, UV + vec2(-px.x, -px.y)).a;
    blur += texture(TEXTURE, UV + vec2(0.0, -px.y)).a;
    blur += texture(TEXTURE, UV + vec2(px.x, -px.y)).a;

    blur += texture(TEXTURE, UV + vec2(-px.x, 0.0)).a;
    blur += texture(TEXTURE, UV + vec2(px.x, 0.0)).a;

    blur += texture(TEXTURE, UV + vec2(-px.x, px.y)).a;
    blur += texture(TEXTURE, UV + vec2(0.0, px.y)).a;
    blur += texture(TEXTURE, UV + vec2(px.x, px.y)).a;

    blur /= 8.0;

    // Only render the glow outside the actual letters.
    float halo = max(blur - center, 0.0);

    COLOR = vec4(
        COLOR.rgb,
        clamp(halo * glow_opacity * glow_strength, 0.0, 1.0)
    );
}