
shader_type canvas_item;

uniform float offset : hint_range(0.0, 20.0) = 5.0;
uniform float glow_opacity : hint_range(0.0, 1.0) = 0.65;
uniform float glow_strength : hint_range(0.0, 3.0) = 1.5;

void fragment() {
    vec2 px = TEXTURE_PIXEL_SIZE * offset;

    // Sample the text alpha in multiple directions.
    float alpha = 0.0;

    alpha += texture(TEXTURE, UV + vec2(-px.x, -px.y)).a;
    alpha += texture(TEXTURE, UV + vec2(0.0, -px.y)).a;
    alpha += texture(TEXTURE, UV + vec2(px.x, -px.y)).a;

    alpha += texture(TEXTURE, UV + vec2(-px.x, 0.0)).a;
    alpha += texture(TEXTURE, UV).a;
    alpha += texture(TEXTURE, UV + vec2(px.x, 0.0)).a;

    alpha += texture(TEXTURE, UV + vec2(-px.x, px.y)).a;
    alpha += texture(TEXTURE, UV + vec2(0.0, px.y)).a;
    alpha += texture(TEXTURE, UV + vec2(px.x, px.y)).a;

    alpha /= 9.0;

    COLOR = vec4(
        COLOR.rgb,
        alpha * glow_opacity * glow_strength
    );
}
