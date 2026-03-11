shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

uniform vec3 albedo : source_color;
uniform vec3 albedo2 : source_color;
uniform vec4 color_deep : source_color;
uniform vec4 color_shallow : source_color;
uniform vec4 horizon_color : source_color = vec4(0.40, 0.57, 0.66, 1.0);
uniform vec3 edge_color : source_color;

uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.05;
uniform float reflection_strength : hint_range(0.0, 1.0) = 0.72;
uniform float fresnel_power : hint_range(0.5, 8.0) = 3.6;
uniform float refraction_strength : hint_range(0.0, 0.2) = 0.022;
uniform float whitecap_strength : hint_range(0.0, 1.0) = 0.18;
uniform float whitecap_cutoff : hint_range(0.0, 1.0) = 0.68;
uniform float crest_tint_strength : hint_range(0.0, 1.0) = 0.22;
uniform float trough_darkness : hint_range(0.0, 1.0) = 0.22;
uniform float distance_haze : hint_range(0.0, 1.0) = 0.03;
uniform float slope_shading_strength : hint_range(0.0, 1.0) = 0.12;

uniform sampler2D texture_normal;
uniform sampler2D texture_normal2;
uniform sampler2D wave;

uniform float wave_time = 0.0;
uniform vec2 wave_direction = vec2(2.0, 0.0);
uniform vec2 wave_2_direction = vec2(0.0, 1.0);
uniform vec2 wave_3_direction = vec2(0.82, 0.38);
uniform float time_scale : hint_range(0.0, 0.2, 0.005) = 0.025;
uniform float wave_speed = 0.25;
uniform float wave_group_strength : hint_range(0.0, 1.0) = 0.24;
uniform float chop_strength : hint_range(0.0, 1.0) = 0.18;
uniform float chop_scale : hint_range(0.5, 5.0) = 2.6;
uniform float crest_foam_bias : hint_range(0.0, 1.0) = 0.10;
uniform float noise_scale = 10.0;
uniform float height_scale = 0.15;
uniform float normal_tiling = 1.0;
uniform float beers_law = 0.18;
uniform float depth_offset = -0.4;
uniform float edge_scale = 0.24;
uniform float near = 0.5;
uniform float far = 100.0;

varying float v_wave_height;
varying vec3 v_world_pos;
varying vec3 v_view_pos;

float sample_wave_height(vec2 world_xz) {
	float time = wave_time * max(wave_speed, 0.001);
	vec2 dir_a = normalize(wave_direction);
	vec2 dir_b = normalize(wave_2_direction);
	vec2 dir_c = normalize(wave_3_direction);
	vec2 uv = world_xz / noise_scale;
	float group_phase = sin(dot(world_xz, dir_a) * 0.006 + time * 0.20) * 0.5 + 0.5;
	float group_cross = cos(dot(world_xz, dir_c) * 0.004 - time * 0.11) * 0.5 + 0.5;
	float group_mix = mix(0.84, 1.0 + wave_group_strength, clamp(group_phase * 0.65 + group_cross * 0.35, 0.0, 1.0));
	float swell_a = texture(wave, uv + dir_a * time).r - 0.5;
	float swell_b = texture(wave, uv * 0.62 + dir_b * time * 0.78).r - 0.5;
	float swell_c = texture(wave, uv * 0.38 + dir_c * time * 0.48).r - 0.5;
	float detail = texture(wave, uv * 1.75 + vec2(0.18, -0.14) * time).r - 0.5;
	float long_swell = sin(dot(world_xz, dir_c) * 0.018 + time * 0.45) * 0.55 + cos(dot(world_xz, dir_b) * 0.013 - time * 0.38) * 0.45;
	float wind_chop = (texture(wave, uv * chop_scale + dir_a * time * 2.40).r - 0.5) * (texture(wave, uv * (chop_scale * 1.37) - dir_b * time * 2.10).g - 0.5) * 4.0 * chop_strength;
	return (((swell_a * 0.44 + swell_b * 0.24 + swell_c * 0.18 + detail * 0.14) * 1.12 + long_swell * 0.36) * group_mix + wind_chop) * height_scale;
}

vec3 sample_wave_normal(vec2 world_xz) {
	float offset = 1.4;
	float left = sample_wave_height(world_xz - vec2(offset, 0.0));
	float right = sample_wave_height(world_xz + vec2(offset, 0.0));
	float down = sample_wave_height(world_xz - vec2(0.0, offset));
	float up = sample_wave_height(world_xz + vec2(0.0, offset));
	vec3 tangent_x = normalize(vec3(offset * 2.0, right - left, 0.0));
	vec3 tangent_z = normalize(vec3(0.0, up - down, offset * 2.0));
	return normalize(cross(tangent_z, tangent_x));
}

float fresnel_term(float amount, vec3 normal, vec3 view) {
	return pow(1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0), amount);
}

float edge_depth(float depth) {
	return near * far / (far + depth * (near - far));
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wave_height = sample_wave_height(v_world_pos.xz);
	VERTEX.y += v_wave_height;
	NORMAL = sample_wave_normal(v_world_pos.xz);
	v_view_pos = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 normal_uv_a = v_world_pos.xz / noise_scale * normal_tiling + TIME * wave_direction * time_scale;
	vec2 normal_uv_b = v_world_pos.xz / noise_scale * (normal_tiling * 1.45) - TIME * wave_2_direction * (time_scale * 1.18);
	vec3 normal_a = texture(texture_normal, normal_uv_a).rgb * 2.0 - 1.0;
	vec3 normal_b = texture(texture_normal2, normal_uv_b).rgb * 2.0 - 1.0;
	vec3 tangent_normal = normalize(mix(normal_a, normal_b, 0.5));
	NORMAL_MAP = tangent_normal * 0.5 + 0.5;

	float fresnel = fresnel_term(fresnel_power, NORMAL, VIEW);
	vec2 distortion = tangent_normal.xy * refraction_strength * (0.42 + fresnel * 0.35);
	vec2 refract_uv = clamp(SCREEN_UV + distortion, vec2(0.001), vec2(0.999));

	float scene_depth_raw = texture(DEPTH_TEXTURE, refract_uv).r;
	float scene_depth = PROJECTION_MATRIX[3][2] / (scene_depth_raw + PROJECTION_MATRIX[2][2]);
	scene_depth += v_view_pos.z;
	float depth_blend = clamp(1.0 - exp((scene_depth + depth_offset) * -beers_law), 0.0, 1.0);

	vec3 refracted_scene = textureLod(SCREEN_TEXTURE, refract_uv, 1.5 + depth_blend * 1.8).rgb;
	vec3 base_color = mix(color_shallow.rgb, color_deep.rgb, pow(depth_blend, 0.72));
	base_color = mix(base_color, color_deep.rgb * (1.0 - trough_darkness), clamp(-v_wave_height * 2.6, 0.0, 1.0));
	base_color = mix(base_color, albedo2, clamp(v_wave_height * 2.4 + 0.14, 0.0, 1.0) * crest_tint_strength);
	float slope = 1.0 - clamp(NORMAL.y, 0.0, 1.0);
	base_color = mix(base_color, color_deep.rgb, slope * slope_shading_strength);

	vec3 water_body = mix(refracted_scene * base_color, base_color, 0.66 + depth_blend * 0.18);
	vec3 reflected_color = mix(horizon_color.rgb, albedo2, 0.18 + slope * 0.16);
	vec3 color = mix(water_body, reflected_color, clamp(fresnel * reflection_strength * 1.08, 0.0, 1.0));

	float z_depth = edge_depth(texture(DEPTH_TEXTURE, SCREEN_UV).x);
	float z_pos = edge_depth(FRAGCOORD.z);
	float z_dif = max(z_depth - z_pos, 0.0);
	float edge_foam = 1.0 - smoothstep(0.0, edge_scale, z_dif);
	float crest = clamp(abs(v_wave_height / max(height_scale, 0.001)) * 0.55 + slope * 1.35 + crest_foam_bias, 0.0, 1.0);
	float whitecap = smoothstep(whitecap_cutoff, 1.0, crest);

	color = mix(color, edge_color, edge_foam * 0.42);
	color = mix(color, edge_color, whitecap * whitecap_strength);
	color = mix(color, horizon_color.rgb, fresnel * 0.14 + distance_haze * (1.0 - depth_blend) * 0.16);

	ALBEDO = clamp(color, vec3(0.0), vec3(1.0));
	METALLIC = metallic;
	ROUGHNESS = mix(0.035, roughness, 0.48 + depth_blend * 0.30);
	SPECULAR = 0.88;
}
