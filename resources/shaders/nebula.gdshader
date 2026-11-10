
shader_type canvas_item;

uniform vec2 camera_position = vec2(0.0);
uniform float zoom = 1.0;
uniform vec2 world_scale = vec2(1920.0, 1080.0);

// Animation
uniform float timeScaleFactor = 0.018;

// Noise texture
uniform sampler2D noise_texture : repeat_enable, filter_linear;

// Color controls
uniform vec4 colour_muiltiplier : source_color = vec4(1.0);
uniform vec4 colour_muiltiplier2 : source_color = vec4(1.0);

// Cloud settings
uniform float brightness = 1.2;
uniform float clouds_resolution = 8.0;
uniform float clouds_intesity = 0.15;
uniform float waveyness = 1.5;
uniform float fragmentation = 9.0;
uniform float distortion = 2.0;
uniform float clouds_alpha = 0.5;
uniform float movement = 1.0;
uniform float blur = 1.5;
uniform float blur2 = 0.014;

// Parallax
uniform float bg_speed = 0.12;
uniform float mid_speed = 0.30;
uniform float fg_speed = 0.45;

// Pixel art
uniform float pixel_size = 1.0;
uniform float color_steps : hint_range(2.0, 16.0) = 5.0;
uniform float pixel_dither : hint_range(0.0, 0.2) = 0.035;

// Transition controls
uniform float cloud_softness : hint_range(0.1, 2.0) = 1.0;
uniform float color_blend : hint_range(0.1, 1.0) = 0.65;
uniform bool quantize_clouds = false;

// Additional palette colors
uniform vec4 color_purple : source_color =
    vec4(0.16, 0.025, 0.38, 1.0);

uniform vec4 color_blue : source_color =
    vec4(0.025, 0.10, 0.38, 1.0);

uniform vec4 color_cyan : source_color =
    vec4(0.015, 0.30, 0.42, 1.0);

uniform vec4 color_pink : source_color =
    vec4(0.42, 0.035, 0.28, 1.0);

uniform vec4 color_magenta : source_color =
    vec4(0.30, 0.035, 0.42, 1.0);

uniform vec4 color_orange : source_color =
    vec4(0.42, 0.12, 0.045, 1.0);

uniform vec4 color_lavender : source_color =
    vec4(0.30, 0.20, 0.48, 1.0);


float localTime() {
    return TIME * timeScaleFactor;
}

mat2 makem2(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat2(vec2(c, -s), vec2(s, c));
}

float noise(vec2 x) {
    return texture(noise_texture, x * blur2).r;
}

float noisey(vec2 y) {
    return texture(noise_texture, y * blur2).g;
}

float fine_noise(vec2 p) {
    return texture(noise_texture, p * blur2).b;
}

float fine_noise2(vec2 p) {
    return texture(noise_texture, p * blur2).a;
}

vec2 gradn(vec2 p) {
    float ep = 0.09;

    float gradx =
        noise(vec2(p.x + ep, p.y)) -
        noise(vec2(p.x - ep, p.y));

    float grady =
        noisey(vec2(p.x, p.y + ep)) -
        noisey(vec2(p.x, p.y - ep));

    // Fine turbulence modifies the gradient.
    vec2 fine_gradient = vec2(
        fine_noise(p + vec2(ep, 0.0)) -
        fine_noise(p - vec2(ep, 0.0)),

        fine_noise2(p + vec2(0.0, ep)) -
        fine_noise2(p - vec2(0.0, ep))
    );

    return vec2(gradx, grady) +
        fine_gradient * 0.45;
}

float flow(vec2 p) {
    float z = 2.0;
    float rz = 0.0;
    vec2 bp = p;

    for (float i = 1.0; i < 7.0; i++) {
        p += localTime() * 0.15;
        bp += localTime() * 0.5;

        vec2 gr = gradn(i * p * 0.34 + localTime());

        gr *= makem2(
            localTime() * 0.5 -
            (0.05 * p.x + 0.03 * p.y) * 20.0
        );

        p += gr * waveyness;

        float large_detail = noise(p);
        float medium_detail = noisey(p * 1.4);
        float fine_detail = fine_noise(p * 2.0);
        
        float combined_noise =
            large_detail * 0.55 +
            medium_detail * 0.30 +
            fine_detail * 0.15;

        rz += (
            sin(combined_noise * fragmentation) * distortion
            + clouds_alpha
        ) / z;

        p = mix(bp, p, movement);

        z *= blur;
        p *= 2.0;
        bp *= 1.9;
    }

    return rz;
}

float rand(vec2 st) {
    return fract(
        sin(dot(st.xy, vec2(12.9898, 78.233)))
        * 43758.5453
    );
}

// Smooth multicolor palette
vec3 get_palette(float t) {
    vec3 result = color_purple.rgb;

    result = mix(result, color_blue.rgb,
        smoothstep(0.08, 0.24, t));

    result = mix(result, color_cyan.rgb,
        smoothstep(0.22, 0.40, t));

    result = mix(result, color_lavender.rgb,
        smoothstep(0.38, 0.55, t));

    result = mix(result, color_pink.rgb,
        smoothstep(0.52, 0.68, t));

    result = mix(result, color_magenta.rgb,
        smoothstep(0.65, 0.79, t));

    result = mix(result, color_orange.rgb,
        smoothstep(0.76, 0.90, t));

    return result;
}

void fragment() {
    // Pixelated coordinates
    vec2 pixel_uv = floor(
        UV * world_scale / pixel_size
    ) * pixel_size / world_scale;

    // Camera movement and zoom
    vec2 world_pos = camera_position +
        (pixel_uv - vec2(0.5)) * world_scale / zoom;

    vec2 p = world_pos * 0.0025 * clouds_resolution;

    // Parallax layers
    float bg_rz = flow(
        p * bg_speed +
        vec2(TIME * 0.012, TIME * 0.006)
    );

    float mid_rz = flow(
        p * mid_speed +
        vec2(-TIME * 0.018, TIME * 0.011)
    );

    float fg_rz = flow(
        p * fg_speed +
        vec2(TIME * 0.025, -TIME * 0.016)
    );

    // Organic cloud formations
    float cloud_bg = 1.0 - smoothstep(
        0.35, 1.45, abs(bg_rz)
    );

    float cloud_mid = 1.0 - smoothstep(
        0.40, 1.50, abs(mid_rz)
    );

    float cloud_fg = 1.0 - smoothstep(
        0.45, 1.55, abs(fg_rz)
    );

    // Background dominates, foreground becomes subtle
    float cloud_shape =
        cloud_bg * 0.60 +
        cloud_mid * 0.30 +
        cloud_fg * 0.10;

    cloud_shape = clamp(cloud_shape, 0.0, 1.0);

    // Optional intensity quantization
    if (quantize_clouds) {
        float steps = max(color_steps, 2.0);

        cloud_shape = floor(
            cloud_shape * steps + 0.5
        ) / steps;
    }

    // Smooth color variation
    float color_noise = noise(p * 0.35);
    float color_noise2 = noise(p * 0.18 + 15.0);
    float fine_color = noise(p * 0.12 + 30.0);

    // Combine multiple noise frequencies.
    float palette_position =
        color_noise * 0.45 +
        color_noise2 * 0.35 +
        fine_color * 0.20;

    // Let cloud density influence color placement.
    palette_position = clamp(
        palette_position * 0.75 +
        cloud_shape * 0.25,
        0.0,
        1.0
    );

    vec3 nebula_color = get_palette(palette_position);

    // Cloud brightness
    float cloud_intensity = pow(cloud_shape, 2.0) * 0.45;

    cloud_intensity *= smoothstep(
        0.05,
        0.55,
        cloud_shape
    );

    vec3 final_col =
        nebula_color *
        cloud_intensity *
        brightness;

    // Subtle pixel dithering
    float dither = rand(
        floor(UV * vec2(1920.0, 1080.0) / pixel_size)
    );

    final_col += (dither - 0.5) * pixel_dither;
    final_col *= colour_muiltiplier.rgb;
    float final_alpha = clamp(cloud_intensity * 0.8, 0.0, 0.85);

    COLOR = vec4(final_col, final_alpha) * colour_muiltiplier2;
}
