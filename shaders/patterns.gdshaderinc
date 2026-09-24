// patterns.gdshaderinc

// Mode 1: Primary hypnotic pattern
vec4 pattern_primary(vec2 p, float t) {
    float l = length(p) - 1.0;
    return 0.5 + tanh(0.1 / max(l * 10.0, -l) - sin(l + p.y * max(1.0, -l * 10.0) + t + vec4(0.0, 1.0, 2.0, 1.0))) / 2.0;
}

// Mode 2: Alternate pattern for white regions
vec4 pattern_alternate(vec2 p, float t, float alt_speed) {
    float l = length(p) - 1.0;
    float time_alt = t * alt_speed;
    vec4 c = vec4(2.0, 0.5, 0.0, 1.0);
    return 0.5 + tanh(0.2 / max(l * 5.0, -l) - cos(l * 2.0 - p.x * max(2.0, -l * 5.0) - time_alt + c)) / 2.0;
}

// Triplanar helper evaluating both patterns and blending via mask
vec3 evaluate_dual_pattern(vec3 world_pos, vec3 normal, float uv_scale, float time, float alt_speed, float mask) {
    vec3 n = normalize(normal);
    vec3 w = abs(n);
    w /= (w.x + w.y + w.z);
    
    vec3 p = world_pos * uv_scale;

    // Triplanar sample: Primary Pattern
    vec4 xz_a = pattern_primary(p.xz, time);
    vec4 xy_a = pattern_primary(p.xy, time);
    vec4 yz_a = pattern_primary(p.yz, time);
    vec4 res_a = xz_a * w.y + xy_a * w.z + yz_a * w.x;

    // Triplanar sample: Alternate Pattern
    vec4 xz_b = pattern_alternate(p.xz, time, alt_speed);
    vec4 xy_b = pattern_alternate(p.xy, time, alt_speed);
    vec4 yz_b = pattern_alternate(p.yz, time, alt_speed);
    vec4 res_b = xz_b * w.y + xy_b * w.z + yz_b * w.x;

    // Mix primary (black = 0.0) and alternate (white = 1.0)
    return mix(res_a.rgb, res_b.rgb, mask);
}