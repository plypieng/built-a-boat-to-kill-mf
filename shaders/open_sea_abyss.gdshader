shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled;

uniform vec4 top_color : source_color = vec4(0.08, 0.23, 0.30, 1.0);
uniform vec4 mid_color : source_color = vec4(0.03, 0.10, 0.16, 1.0);
uniform vec4 deep_color : source_color = vec4(0.01, 0.03, 0.07, 1.0);
uniform vec2 world_center = vec2(0.0, 0.0);
uniform float ocean_radius = 560.0;
uniform float top_y = -0.12;
uniform float bottom_y = -220.0;
uniform float side_fade = 0.34;
uniform float noise_scale = 0.0034;
uniform float noise_strength = 0.08;

varying vec3 v_world_pos;

float hash_noise(vec2 p) {
	return sin(p.x * 0.73 + p.y * 1.13) * cos(p.x * 0.37 - p.y * 0.61);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float depth_ratio = clamp((top_y - v_world_pos.y) / max(0.001, top_y - bottom_y), 0.0, 1.0);
	float radial_ratio = clamp(distance(v_world_pos.xz, world_center) / max(1.0, ocean_radius), 0.0, 1.0);
	float edge_shadow = smoothstep(0.35, 1.0, radial_ratio);
	float breakup = hash_noise(v_world_pos.xz * noise_scale) * 0.5 + 0.5;
	float breakup_mix = (breakup - 0.5) * noise_strength;

	vec3 color = mix(top_color.rgb, mid_color.rgb, smoothstep(0.04, 0.46, depth_ratio));
	color = mix(color, deep_color.rgb, smoothstep(0.38, 1.0, depth_ratio));
	color = mix(color, deep_color.rgb, edge_shadow * side_fade + breakup_mix);

	ALBEDO = color;
	ROUGHNESS = 0.96;
}
