shader_type canvas_item;

uniform float amount : hint_range(0.0, 1.0) = 1.0;
uniform float dimming : hint_range(0.0, 1.0) = 0.18;
uniform float contrast : hint_range(0.5, 1.5) = 0.95;

void fragment() {
    vec4 c = COLOR;

    float luma = dot(c.rgb, vec3(0.299, 0.587, 0.114));
    vec3 grey = vec3(luma);

    vec3 rgb = mix(c.rgb, grey, amount);
    rgb *= 1.0 - (dimming * amount);
    rgb = (rgb - 0.5) * mix(1.0, contrast, amount) + 0.5;

    COLOR = vec4(rgb, c.a);
}