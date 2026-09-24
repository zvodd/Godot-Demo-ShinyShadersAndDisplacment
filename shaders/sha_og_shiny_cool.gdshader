shader_type spatial;
render_mode unshaded;

varying vec3 v_pos;
varying vec3 v_nor;

uniform float uv_scale : hint_range(0.1, 10.0) = 1.0;
uniform sampler2D albedo_texture : source_color;
uniform float alt_speed = 2.0;

void vertex() {
    v_pos = VERTEX;
    v_nor = NORMAL;
}

// Mode 1: Original hypnotic pattern
vec4 pattern(vec2 p, float t) {
    float l = length(p) - 1.0;
    return 0.5 + tanh(0.1 / max(l * 10.0, -l) - sin(l + p.y * max(1.0, -l * 10.0) + t + vec4(0.0, 1.0, 2.0, 1.0))) / 2.0;
}

// Mode 2: Alternate mode active in white regions (faster, color-shifted, glitchy wave)
vec4 pattern_alt(vec2 p, float t) {
    float l = length(p) - 1.0;
    float time_alt = t * alt_speed;
    vec4 c = vec4(2.0, 0.5, 0.0, 1.0); // Shifted color channels
    return 0.5 + tanh(0.2 / max(l * 5.0, -l) - cos(l * 2.0 - p.x * max(2.0, -l * 5.0) - time_alt + c)) / 2.0;
}

void fragment() {
    // Sample mask texture using standard UVs
    vec4 tex_val = texture(albedo_texture, UV);
    // Convert RGB to grayscale lightness
    float mask = dot(tex_val.rgb, vec3(0.299, 0.587, 0.114));

    // Triplanar setup
    vec3 n = normalize(v_pos);
    vec3 w = abs(n);
    w /= (w.x + w.y + w.z);
    vec3 p = v_pos * uv_scale;

    // Primary pattern triplanar
    vec4 xz_a = pattern(p.xz, TIME);
    vec4 xy_a = pattern(p.xy, TIME);
    vec4 yz_a = pattern(p.yz, TIME);
    vec4 res_a = xz_a * w.y + xy_a * w.z + yz_a * w.x;

    // Alternate pattern triplanar
    vec4 xz_b = pattern_alt(p.xz, TIME);
    vec4 xy_b = pattern_alt(p.xy, TIME);
    vec4 yz_b = pattern_alt(p.yz, TIME);
    vec4 res_b = xz_b * w.y + xy_b * w.z + yz_b * w.x;

    // Transition between Primary (Black) and Alternate (White) based on the mask
    vec3 final_pattern = mix(res_a.rgb, res_b.rgb, mask);

    // Fresnel effect applied on top
    float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 5.0);
    ALBEDO = mix(final_pattern, vec3(0.9, 0.1, 0.5), fresnel);
}