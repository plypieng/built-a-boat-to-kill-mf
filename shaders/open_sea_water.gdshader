shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 deep_color : source_color = vec4(0.05, 0.15, 0.24, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.08, 0.34, 0.46, 1.0);
uniform vec4 foam_color : source_color = vec4(0.82, 0.92, 0.97, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.28, 0.42, 0.52, 1.0);
uniform float wave_amplitude = 0.28;
uniform float wave_speed = 1.0;
uniform float chop_strength = 0.24;
uniform float storm_strength = 0.0;
uniform float foam_amount = 0.42;

varying float v_height;
varying float v_foam;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float swell_a = sin(world_pos.x * 0.046 + TIME * (0.88 * wave_speed));
	float swell_b = cos(world_pos.z * 0.039 - TIME * (0.74 * wave_speed));
	float cross = sin((world_pos.x + world_pos.z) * 0.026 + TIME * (0.52 * wave_speed));
	float chop = sin(world_pos.x * 0.19 - TIME * (1.70 * wave_speed)) * cos(world_pos.z * 0.16 + TIME * (1.26 * wave_speed));
	float wave = (swell_a * 0.55 + swell_b * 0.45 + cross * 0.38) * wave_amplitude;
	wave += chop * wave_amplitude * chop_strength;
	VERTEX.y += wave;
	v_height = wave;
	v_foam = clamp(abs(chop) * (0.34 + storm_strength * 0.56) + abs(cross) * 0.12, 0.0, 1.0);
}

void fragment() {
	float height_mix = clamp(v_height * 2.3 + 0.5, 0.0, 1.0);
	vec3 water_color = mix(deep_color.rgb, shallow_color.rgb, height_mix);
	water_color = mix(water_color, foam_color.rgb, v_foam * foam_amount);
	float fresnel = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 2.8);
	ALBEDO = mix(water_color, horizon_color.rgb, fresnel * 0.36);
	ROUGHNESS = mix(0.10, 0.22, storm_strength * 0.8 + 0.12);
	SPECULAR = 0.72;
	EMISSION = foam_color.rgb * v_foam * (0.08 + storm_strength * 0.08);
}
