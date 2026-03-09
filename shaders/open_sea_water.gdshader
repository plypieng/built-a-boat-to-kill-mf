shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

uniform vec4 deep_color : source_color = vec4(0.05, 0.15, 0.24, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.08, 0.34, 0.46, 1.0);
uniform vec4 foam_color : source_color = vec4(0.82, 0.92, 0.97, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.28, 0.42, 0.52, 1.0);
uniform float wave_amplitude = 0.28;
uniform float wave_speed = 1.0;
uniform float chop_strength = 0.24;
uniform float storm_strength = 0.0;
uniform float foam_amount = 0.42;
uniform float detail_amplitude = 0.08;
uniform float whitecap_strength = 0.52;
uniform float trough_darkness = 0.18;
uniform float reflection_strength = 0.48;
uniform float glint_strength = 0.32;
uniform float clarity = 0.55;
uniform float fresnel_power = 3.2;
uniform sampler2D foam_mask_texture : source_color;
uniform bool use_foam_mask = false;
uniform float foam_mask_tiling = 0.014;
uniform vec2 foam_mask_scroll = vec2(0.014, -0.009);
uniform float foam_mask_influence = 0.36;
uniform float refraction_strength = 0.018;
uniform float refraction_blur = 1.4;
uniform float depth_fade_distance = 10.0;
uniform float depth_refraction_strength = 0.42;
uniform float contact_edge_foam = 0.32;
uniform float distance_haze = 0.18;

varying float v_height;
varying float v_foam;
varying float v_whitecap;
varying vec2 v_world_xz;
varying vec3 v_view_position;

float sample_wave_height(vec2 world_xz) {
	float swell_a = sin(world_xz.x * 0.046 + TIME * (0.88 * wave_speed));
	float swell_b = cos(world_xz.y * 0.039 - TIME * (0.74 * wave_speed));
	float cross = sin((world_xz.x + world_xz.y) * 0.026 + TIME * (0.52 * wave_speed));
	float chop = sin(world_xz.x * 0.19 - TIME * (1.70 * wave_speed)) * cos(world_xz.y * 0.16 + TIME * (1.26 * wave_speed));
	float detail = sin(world_xz.x * 0.38 + TIME * (2.20 * wave_speed)) * cos(world_xz.y * 0.31 - TIME * (1.85 * wave_speed));
	float wave = (swell_a * 0.55 + swell_b * 0.45 + cross * 0.38) * wave_amplitude;
	wave += chop * wave_amplitude * chop_strength;
	wave += detail * detail_amplitude * (0.4 + storm_strength * 0.9);
	return wave;
}

vec3 sample_wave_normal(vec2 world_xz) {
	float offset = 0.75;
	float left = sample_wave_height(world_xz - vec2(offset, 0.0));
	float right = sample_wave_height(world_xz + vec2(offset, 0.0));
	float down = sample_wave_height(world_xz - vec2(0.0, offset));
	float up = sample_wave_height(world_xz + vec2(0.0, offset));
	vec3 tangent_x = normalize(vec3(offset * 2.0, right - left, 0.0));
	vec3 tangent_z = normalize(vec3(0.0, up - down, offset * 2.0));
	return normalize(cross(tangent_z, tangent_x));
}

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float wave = sample_wave_height(world_pos.xz);
	float cross = sin((world_pos.x + world_pos.z) * 0.026 + TIME * (0.52 * wave_speed));
	float chop = sin(world_pos.x * 0.19 - TIME * (1.70 * wave_speed)) * cos(world_pos.z * 0.16 + TIME * (1.26 * wave_speed));
	float detail = sin(world_pos.x * 0.38 + TIME * (2.20 * wave_speed)) * cos(world_pos.z * 0.31 - TIME * (1.85 * wave_speed));
	VERTEX.y += wave;
	NORMAL = sample_wave_normal(world_pos.xz);
	v_world_xz = world_pos.xz;
	v_view_position = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_height = wave;
	v_foam = clamp(abs(chop) * (0.34 + storm_strength * 0.56) + abs(cross) * 0.12, 0.0, 1.0);
	v_whitecap = clamp(abs(detail) * 0.6 + abs(chop) * 0.55 + storm_strength * 0.35, 0.0, 1.0);
}

void fragment() {
	float height_mix = clamp(v_height * 2.3 + 0.5, 0.0, 1.0);
	vec3 water_color = mix(deep_color.rgb, shallow_color.rgb, height_mix);
	vec3 surface_normal = normalize(NORMAL);
	float foam_mask = 1.0;
	if (use_foam_mask) {
		vec2 mask_uv_a = v_world_xz * foam_mask_tiling + TIME * foam_mask_scroll;
		vec2 mask_uv_b = v_world_xz * (foam_mask_tiling * 0.63) - TIME * (foam_mask_scroll * 0.72);
		float mask_a = texture(foam_mask_texture, mask_uv_a).r;
		float mask_b = texture(foam_mask_texture, mask_uv_b).g;
		foam_mask = clamp(mix(mask_a, mask_b, 0.5) * 1.35, 0.0, 1.0);
	}
	float foam_mask_mix = mix(1.0 - foam_mask_influence, 1.0 + foam_mask_influence, foam_mask);
	water_color = mix(water_color, deep_color.rgb * (1.0 - trough_darkness), clamp(-v_height * 2.2, 0.0, 1.0));
	water_color = mix(water_color, shallow_color.rgb * 1.12, clamp(v_height * 1.8 + 0.24, 0.0, 1.0) * clarity * 0.26);
	vec2 distortion = surface_normal.xz * refraction_strength * mix(0.65, 1.35, storm_strength);
	vec2 refract_uv = clamp(SCREEN_UV + distortion, vec2(0.001), vec2(0.999));
	vec3 refracted_scene = textureLod(screen_texture, refract_uv, refraction_blur).rgb;
	float scene_depth_raw = texture(depth_texture, refract_uv).r;
	float water_depth = max(-v_view_position.z, 0.001);
	float depth_delta = depth_fade_distance;
	if (scene_depth_raw < 0.9999) {
		vec4 scene_view = INV_PROJECTION_MATRIX * vec4(refract_uv * 2.0 - 1.0, scene_depth_raw, 1.0);
		scene_view.xyz /= scene_view.w;
		float scene_depth = max(-scene_view.z, water_depth);
		depth_delta = max(scene_depth - water_depth, 0.0);
	}
	float depth_factor = clamp(depth_delta / depth_fade_distance, 0.0, 1.0);
	float contact_edge = 1.0 - smoothstep(0.0, depth_fade_distance * 0.35, depth_delta);
	vec3 refracted_mix = mix(refracted_scene, water_color, 0.58 + storm_strength * 0.12);
	water_color = mix(refracted_mix, water_color, 0.62 + depth_factor * depth_refraction_strength);
	water_color = mix(water_color, foam_color.rgb, v_foam * foam_amount * foam_mask_mix);
	water_color = mix(water_color, foam_color.rgb, v_whitecap * whitecap_strength * (0.25 + storm_strength * 0.55) * foam_mask_mix);
	water_color = mix(water_color, foam_color.rgb, contact_edge * contact_edge_foam * mix(0.72, 1.18, foam_mask));
	water_color = mix(water_color, horizon_color.rgb, (1.0 - depth_factor) * distance_haze * 0.18);
	float fresnel = pow(1.0 - max(dot(surface_normal, normalize(VIEW)), 0.0), fresnel_power);
	float crest_glint = pow(clamp(v_whitecap, 0.0, 1.0), 2.4) * (0.35 + storm_strength * 0.65) * glint_strength * mix(0.74, 1.18, foam_mask);
	vec3 reflected_color = mix(horizon_color.rgb, foam_color.rgb, clamp(v_whitecap * 0.32 + storm_strength * 0.18, 0.0, 0.65));
	ALBEDO = mix(water_color, reflected_color, fresnel * reflection_strength);
	ROUGHNESS = mix(0.06, 0.24, storm_strength * 0.78 + (1.0 - clarity) * 0.25);
	SPECULAR = 0.78;
	EMISSION = foam_color.rgb * v_foam * (0.08 + storm_strength * 0.08) + reflected_color * crest_glint * 0.14;
}
