shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

#include "res://shaders/patterns.gdshaderinc"

// PBR Uniforms
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform float roughness : hint_range(0.0, 1.0) = 0.5;
uniform float specular : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float metallic : hint_range(0.0, 1.0, 0.01) = 0.0;

// Pattern Control Uniforms
uniform float uv_scale : hint_range(0.1, 10.0) = 1.0;
uniform float alt_speed : hint_range(0.0, 10.0) = 2.0;

// Tile / MultiMesh Displacement Uniforms
uniform vec3 point_center = vec3(0.0);
uniform float radius = 5.0;
uniform float offset_factor = 2.0;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
    // MultiMesh instance position displacement for tiling
    vec3 instance_position = MODEL_MATRIX[3].xyz;
    float distance_from_center = distance(instance_position.xz, point_center.xz);
    float factor = clamp(distance_from_center / radius, 0.0, 1.0);
    
    VERTEX.y += factor * offset_factor;

    // Pass world position and normal to fragment shader
    v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    v_world_normal = MODEL_NORMAL_MATRIX * NORMAL;
}

void fragment() {
    // 1. Sample Albedo Mask Texture
    vec4 albedo_tex = texture(texture_albedo, UV);
    vec3 mask_color = albedo.rgb * albedo_tex.rgb;
    float mask = dot(mask_color, vec3(0.299, 0.587, 0.114));

    // 2. Evaluate Dual Pattern via Included Function
    vec3 pattern_color = evaluate_dual_pattern(
        v_world_pos, 
        v_world_normal, 
        uv_scale, 
        TIME, 
        alt_speed, 
        mask
    );

    // 3. Fresnel Edge Highlight
    float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 5.0);
    vec3 final_color = mix(pattern_color, vec3(0.9, 0.1, 0.5), fresnel);

    // Output PBR channels
    ALBEDO = final_color;
    METALLIC = metallic;
    SPECULAR = specular;
    ROUGHNESS = roughness;
}