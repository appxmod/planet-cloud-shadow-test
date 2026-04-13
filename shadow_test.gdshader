shader_type spatial;
render_mode unshaded,                  // Don't light the sphere itself
            depth_draw_always,         // Important for shadows
            cull_disabled;             // Render both sides if needed

// ==================== Uniforms ====================
uniform sampler2D noise_tex : source_color, filter_linear_mipmap, repeat_enable;

uniform vec4 cloud_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Not really visible, but useful for tweaking

uniform float scale = 2.0;              // Cloud size on sphere
uniform float density = 0.6;            // Overall cloud coverage (0.0 - 1.0)
uniform float sharpness = 0.8;          // How hard the cloud edges are

uniform vec2 scroll_speed = vec2(0.02, 0.01); // Cloud movement

// Optional: animate the clouds slowly
uniform float time_scale = 0.1;

// For very soft shadow edges (if you want)
uniform float shadow_softness : hint_range(0.0, 1.0) = 0.0;

// ==================== Helper Noise ====================
float fbm(vec2 uv) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < 5; i++) {
        value += amplitude * texture(noise_tex, uv * frequency).r;
        amplitude *= 0.5;
        frequency *= 2.1;
    }
    return value;
}

void fragment() {
    vec2 uv = UV * scale;
    
    // Animate clouds
    vec2 offset = TIME * scroll_speed * time_scale;
    
    // Layered noise for nice puffy clouds
    float noise = fbm(uv + offset);
    noise = fbm(uv * 1.7 + offset * 1.3) * 0.6 + noise * 0.4;
    
    // Remap to get nice cloud shapes
    float cloud = smoothstep(density - sharpness, density + sharpness, noise);
    
    // Final alpha for shadow
    float alpha = cloud * cloud_color.a;
    
    // Make the sphere itself invisible
    ALBEDO = vec3(1.0);
    ALPHA = alpha;
    if(alpha<0.8) discard;
    
    // This is the key for proper shadow casting with transparency
    ALPHA_SCISSOR_THRESHOLD = 0.3 + shadow_softness * 0.4;
}
