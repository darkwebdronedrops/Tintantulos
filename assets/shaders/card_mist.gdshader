shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float particle_count : hint_range(50.0, 500.0) = 200.0;
uniform vec4 color_primary : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 color_secondary : source_color = vec4(0.3, 0.3, 0.3, 1.0);
uniform float speed : hint_range(0.5, 3.0) = 2.0;
uniform float spread : hint_range(0.5, 2.0) = 1.2;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    vec2 center = vec2(0.5, 0.5);
    vec2 from_center = uv - center;
    float dist = length(from_center);
    
    // Particle grid
    vec2 grid_uv = uv * particle_count;
    vec2 grid_id = floor(grid_uv);
    vec2 grid_fract = fract(grid_uv);
    
    float rand = hash(grid_id);
    float rand2 = hash(grid_id + vec2(1.0, 0.0));
    float rand3 = hash(grid_id + vec2(0.0, 1.0));
    
    // Burst outward then fade
    float burst_phase = smoothstep(0.0, 0.3, progress) * (1.0 - smoothstep(0.5, 1.0, progress));
    
    // Particle movement - outward burst
    float angle = rand * 6.283;
    float dist_offset = rand2 * spread * burst_phase;
    vec2 particle_center = vec2(0.5) + vec2(cos(angle), sin(angle)) * dist_offset;
    
    // Wobble
    float wobble = sin(TIME * speed + rand3 * 10.0) * 0.02 * burst_phase;
    particle_center += vec2(cos(angle + 1.57), sin(angle + 1.57)) * wobble;
    
    // Particle shape
    float particle_dist = length(uv - particle_center);
    float particle_size = 0.008 + rand3 * 0.012;
    float particle_alpha = 1.0 - smoothstep(0.0, particle_size, particle_dist);
    
    // Fade near edges of burst life
    float life_alpha = 1.0 - smoothstep(0.4, 1.0, progress);
    
    // Color mix
    vec3 final_color = mix(color_primary.rgb, color_secondary.rgb, rand);
    float final_alpha = particle_alpha * life_alpha * burst_phase * 0.7;
    
    COLOR = vec4(final_color, final_alpha);
}
