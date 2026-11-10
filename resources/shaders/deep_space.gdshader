
shader_type canvas_item;

uniform vec2 camera_position = vec2(0.0);
uniform float zoom = 1.0;
uniform vec2 viewport_size = vec2(1920.0, 1080.0);
uniform vec2 world_scale = vec2(1920.0, 1080.0);

// Base palette
uniform vec4 space_color : source_color =
    vec4(0.008, 0.012, 0.035, 1.0);

uniform vec4 blue_glow : source_color =
    vec4(0.025, 0.055, 0.16, 1.0);

uniform vec4 purple_glow : source_color =
    vec4(0.09, 0.025, 0.14, 1.0);

uniform vec4 cyan_glow : source_color =
    vec4(0.015, 0.09, 0.14, 1.0);

// Pixel art controls
uniform float pixel_size : hint_range(1.0, 16.0) = 1.5;
uniform float glow_strength : hint_range(0.0, 2.0) = 0.65;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.45;

// Animation
uniform float animation_speed : hint_range(0.0, 0.1) = 0.008;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    f = f * f * (3.0 - 2.0 * f);

    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));

    return mix(
        mix(a, b, f.x),
        mix(c, d, f.x),
        f.y
    );
}

void fragment() {
    // Pixelated screen coordinates
    vec2 uv = SCREEN_UV;
    // Resolution-independent pixel grid.
    vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;

    vec2 pixel_uv = uv;
    if (pixel_size > 1.0) {
        pixel_uv = floor(
            uv * resolution / pixel_size
        ) * pixel_size / resolution;
    }

    // Camera-relative world coordinates
    vec2 world_pos = camera_position +
        (pixel_uv - vec2(0.5)) * world_scale / zoom;

    float t = TIME * animation_speed;

    // Pixelated atmospheric formations
    // Atmospheric formations
    float n1 = noise(world_pos * 0.006 + vec2(t, 0.0));
    float n2 = noise(world_pos * 0.012 + vec2(0.0, -t));

    // Large color regions
    float blue = exp(
        -length((uv - vec2(0.25, 0.42)) *
        vec2(1.0, 1.3)) * 3.0
    );

    float purple = exp(
        -length((uv - vec2(0.78, 0.68)) *
        vec2(1.2, 1.0)) * 3.5
    );

    float cyan = exp(
        -length((uv - vec2(0.55, 0.22)) *
        vec2(1.4, 1.2)) * 4.0
    );

    // Quantized cloud variation
    float cloud = n1 * 0.75 + n2 * 0.25;
    vec3 col = space_color.rgb;

    col += blue_glow.rgb * blue * glow_strength;
    col += purple_glow.rgb * purple * glow_strength;
    col += cyan_glow.rgb * cyan * glow_strength;

    col += blue_glow.rgb * cloud * 0.07;

    // Vignette
    float vignette = smoothstep(
        0.15,
        0.95,
        distance(uv, vec2(0.5))
    );

    col *= mix(
        1.0 - vignette_strength,
        1.0,
        vignette
    );

    COLOR = vec4(col, 1.0);
}