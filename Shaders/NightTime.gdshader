shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D mask_noise_tex : repeat_enable, filter_linear;

// Night effect
uniform float darkness : hint_range(0.0, 1.0) = 0.42;
uniform vec3 night_tint : source_color = vec3(0.78, 0.86, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.20;
uniform float desaturation : hint_range(0.0, 1.0) = 0.10;

// Campfire protected area
uniform vec2 focus_center = vec2(0.5, 0.5);
uniform float inner_radius : hint_range(0.0, 1.0) = 0.08;
uniform float outer_radius : hint_range(0.0, 1.0) = 0.22;
uniform float center_relief : hint_range(0.0, 1.0) = 0.95;

// Noise on the outer ring only
uniform float noise_scale = 3.0;
uniform vec2 noise_scroll = vec2(0.015, -0.01);
uniform float noise_rotation_speed = 0.4;
uniform float ring_noise_strength : hint_range(0.0, 1.0) = 0.35;
uniform float ring_band_width : hint_range(0.0, 0.3) = 0.06;

// Preserve brighter pixels a bit more
uniform float lit_preservation : hint_range(0.0, 1.0) = 0.45;
uniform float lit_threshold : hint_range(0.0, 1.0) = 0.58;

// Optional vignette
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.08;

vec3 desaturate_color(vec3 c, float amount) {
    float luma = dot(c, vec3(0.299, 0.587, 0.114));
    return mix(c, vec3(luma), amount);
}

vec2 rotate_vec2(vec2 v, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return vec2(
        c * v.x - s * v.y,
        s * v.x + c * v.y
    );
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec4 src = texture(screen_tex, uv);
    vec3 base = src.rgb;

    // Preserve pixels that are already bright
    float luminance = dot(base, vec3(0.299, 0.587, 0.114));
    float lit_mask = smoothstep(lit_threshold, 1.0, luminance);

    // Base radial mask around campfire
    float d = distance(uv, focus_center);
    float center_mask = 1.0 - smoothstep(inner_radius, outer_radius, d);

    // Select only the outer falloff ring for noise modulation
    float outer_band = smoothstep(inner_radius, outer_radius, d) *
                       (1.0 - smoothstep(outer_radius, outer_radius + ring_band_width, d));

    // Build rotating/scolling noise UV around the focus center
    vec2 local_uv = uv - focus_center;
    float angle = TIME * noise_rotation_speed;
    vec2 rotated_uv = rotate_vec2(local_uv, angle);
    vec2 noise_uv = rotated_uv * noise_scale + TIME * noise_scroll;

    float noise_val = texture(mask_noise_tex, noise_uv).r;

    // Only modulate the edge band, leave center stable
    float ring_multiplier = mix(1.0, 0.65 + noise_val * 0.7, ring_noise_strength * outer_band);
    float noisy_center_mask = center_mask * ring_multiplier;

    float relief = max(noisy_center_mask * center_relief, lit_mask * lit_preservation);

    float applied_darkness = darkness * (1.0 - relief);
    float applied_tint = tint_strength * (1.0 - relief);
    float applied_desat = desaturation * (1.0 - relief);

    vec3 col = desaturate_color(base, applied_desat);
    col *= (1.0 - applied_darkness);
    col = mix(col, col * night_tint, applied_tint);

    float edge = distance(uv, vec2(0.5));
    float vignette = smoothstep(0.30, 0.78, edge);
    col *= 1.0 - vignette * vignette_strength;

    COLOR = vec4(col, src.a);
}
