shader_type canvas_item;

uniform bool active = false;
uniform vec4 flash_color : source_color = vec4(1.0, 0.85, 0.75, 1.0);
uniform float flash_strength : hint_range(0.0, 1.0) = 0.3;

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);
    if (active) {
        vec3 blended_color = mix(
            texture_color.rgb,
            flash_color.rgb,
            flash_strength * flash_color.a
        );
        COLOR = vec4(blended_color, texture_color.a);
    } else {
        COLOR = texture_color;
    }
}