shader_type spatial;
render_mode world_vertex_coords, depth_draw_always;
/**
 * Water lighting model roughly follows the 2019 GDC talk: "Wakes, Explosions and Lighting: Interactive Water Simulation in Atlas".
 * Source: https://gpuopen.com/gdc-presentations/2019/gdc-2019-agtd6-interactive-water-simulation-in-atlas.pdf
 */

#define MAX_CASCADES 8
#define REFLECTANCE 0.02

global uniform vec4 water_color : source_color;
global uniform vec4 foam_color : source_color;
uniform vec3 depth_color_consumption = vec3(7.5, 22.0, 38.0);

uniform float roughness : hint_range(0.0, 1.0) = 0.4;
uniform float normal_strength : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D foam_noise_tex : repeat_enable, filter_linear_mipmap;

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

group_uniforms cascade_data;
uniform vec4 map_scales[MAX_CASCADES];
global uniform uint num_cascades;
global uniform sampler2DArray displacements;
global uniform sampler2DArray normals : hint_normal;

uniform vec3 sun_direction = vec3(0.0, 0.72, 0.69);
uniform vec3 sun_color : source_color = vec3(1.0, 0.94, 0.80);
uniform float sun_glint_strength : hint_range(0.0, 2.0) = 0.72;
uniform float sun_glint_focus : hint_range(8.0, 256.0) = 110.0;
uniform float sun_horizon_fade : hint_range(0.0, 1.0) = 0.18;

varying float wave_height;
varying float foam_factor;
varying float fresnel;
varying float sun_glint_factor;

void vertex() {
	UV = VERTEX.xz;
	float distance_cam = length(VERTEX.xz - CAMERA_POSITION_WORLD.xz);
	if (distance_cam < 1024.0) {
		float distance_factor = min(exp(-(distance_cam - 512.0) * 0.007), 1.0);
		vec3 displacement = vec3(0.0);
		for (uint i = 0U; i < num_cascades; ++i) {
			vec4 scales = map_scales[i];
			displacement += texture(displacements, vec3(UV * scales.xy, float(i))).xyz * scales.z;
		}
		VERTEX += displacement * distance_factor;
		wave_height = displacement.y;
	} else {
		wave_height = 0.0;
	}
}

vec4 cubic_weights(float a) {
	float a2 = a * a;
	float a3 = a2 * a;

	float w0 = -a3 + a2 * 3.0 - a * 3.0 + 1.0;
	float w1 = a3 * 3.0 - a2 * 6.0 + 4.0;
	float w2 = -a3 * 3.0 + a2 * 3.0 + a * 3.0 + 1.0;
	float w3 = a3;
	return vec4(w0, w1, w2, w3) / 6.0;
}

vec4 texture_bicubic(in sampler2DArray sampler, in vec3 uvw) {
	vec2 dims = vec2(textureSize(sampler, 0).xy);
	vec2 dims_inv = 1.0 / dims;
	uvw.xy = uvw.xy * dims + 0.5;

	vec2 fuv = fract(uvw.xy);
	vec4 wx = cubic_weights(fuv.x);
	vec4 wy = cubic_weights(fuv.y);

	vec4 g = vec4(wx.xz + wx.yw, wy.xz + wy.yw);
	vec4 h = (vec4(wx.yw, wy.yw) / g + vec2(-1.5, 0.5).xyxy + floor(uvw.xy).xxyy) * dims_inv.xxyy;
	vec2 w = g.xz / (g.xz + g.yw);
	return mix(
		mix(texture(sampler, vec3(h.yw, uvw.z)), texture(sampler, vec3(h.xw, uvw.z)), w.x),
		mix(texture(sampler, vec3(h.yz, uvw.z)), texture(sampler, vec3(h.xz, uvw.z)), w.x),
		w.y
	);
}

void fragment() {
	float map_size = float(textureSize(normals, 0).x);
	float dist = length(VERTEX.xz);
	vec3 gradient = vec3(0.0);
	float foam_alpha = 0.0;
	for (uint i = 0U; i < num_cascades; ++i) {
		vec4 scales = map_scales[i];
		vec3 coords = vec3(UV * scales.xy, float(i));
		float ppm = map_size * min(scales.x, scales.y);
		gradient += mix(texture_bicubic(normals, coords), texture(normals, coords), min(1.0, ppm * 0.1)).xyw * vec3(scales.ww, 1.0);
		foam_alpha += texture(foam_noise_tex, UV * scales.xy).r;
	}
	foam_factor = smoothstep(0.0, 1.0, gradient.z * 0.75) * exp(-dist * 0.0075);

	float depth_tex = texture(depth_texture, SCREEN_UV).r;
	vec4 world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth_tex, 1.0);
	world_pos.xyz /= world_pos.w;
	float smooth_alpha = 1.0 - smoothstep(world_pos.z + 0.66, world_pos.z, VERTEX.z);
	ALPHA *= clamp(smooth_alpha, 0.0, 1.0);
	if (ALPHA < 0.9) {
		foam_factor = clamp(foam_factor + 0.5 - ALPHA, 0.0, 1.0);
	}

	float depth_visibility_range = clamp(max(depth_color_consumption.r, max(depth_color_consumption.g, depth_color_consumption.b)), 0.0, 200.0);
	float factor_translucency = 1.0 - smoothstep(world_pos.z + depth_visibility_range, world_pos.z, VERTEX.z);
	factor_translucency = clamp(factor_translucency, 0.35, 1.0);
	vec3 screen_albedo = texture(screen_texture, SCREEN_UV, 0.0).rgb;
	vec3 depth_water_color = mix(screen_albedo, water_color.rgb, factor_translucency);

	float smooth_red = smoothstep(world_pos.z + depth_color_consumption.r, world_pos.z, VERTEX.z);
	float smooth_green = smoothstep(world_pos.z + depth_color_consumption.g, world_pos.z, VERTEX.z);
	float smooth_blue = smoothstep(world_pos.z + depth_color_consumption.b, world_pos.z, VERTEX.z);
	vec3 color_shallow = max(vec3(smooth_red, smooth_green, smooth_blue) * depth_water_color, water_color.rgb);
	depth_water_color = mix(color_shallow, water_color.rgb, factor_translucency);
	ALBEDO = mix(depth_water_color, foam_color.rgb, foam_factor * foam_alpha * foam_alpha);
	fresnel = mix(pow(1.0 - dot(VIEW, NORMAL), 5.0 * exp(-2.69 * roughness)) / (1.0 + 22.7 * pow(roughness, 1.5)), 1.0, REFLECTANCE);
	ROUGHNESS = (1.0 - fresnel) * foam_factor + 0.4;

	gradient *= mix(0.015, normal_strength, exp(-dist * 0.0175));
	NORMAL = (VIEW_MATRIX * vec4(normalize(vec3(-gradient.x, 1.0, -gradient.y)), 0.0)).xyz;

	vec3 view_sun_dir = normalize(sun_direction);
	vec3 reflection_dir = reflect(-view_sun_dir, normalize(NORMAL));
	float spec_alignment = pow(max(dot(normalize(VIEW), reflection_dir), 0.0), sun_glint_focus);
	float horizon_gate = clamp(1.0 - sun_horizon_fade + max(view_sun_dir.y, 0.0), 0.0, 1.0);
	sun_glint_factor = spec_alignment * fresnel * sun_glint_strength * horizon_gate;
	ALBEDO += sun_color * sun_glint_factor * 0.22;
}

float smith_masking_shadowing(in float cos_theta, in float alpha) {
	float a = cos_theta / (alpha * sqrt(1.0 - cos_theta * cos_theta));
	float a_sq = a * a;
	return a < 1.6 ? (1.0 - 1.259 * a + 0.396 * a_sq) / (3.535 * a + 2.181 * a_sq) : 0.0;
}

float ggx_distribution(in float cos_theta, in float alpha) {
	float a_sq = alpha * alpha;
	float d = 1.0 + (a_sq - 1.0) * cos_theta * cos_theta;
	return a_sq / (PI * d * d);
}

void light() {
	vec3 halfway = normalize(LIGHT + VIEW);
	float dot_nl = max(dot(NORMAL, LIGHT), 2e-5);
	float dot_nv = max(dot(NORMAL, VIEW), 2e-5);

	float light_mask = smith_masking_shadowing(roughness, dot_nv);
	float view_mask = smith_masking_shadowing(roughness, dot_nl);
	float microfacet_distribution = ggx_distribution(dot(NORMAL, halfway), roughness);
	float geometric_attenuation = 1.0 / (1.0 + light_mask + view_mask);
	SPECULAR_LIGHT += fresnel * microfacet_distribution * geometric_attenuation / (4.0 * dot_nv + 0.1) * ATTENUATION;

	const vec3 sss_modifier = vec3(0.9, 1.15, 0.85);
	float sss_height = 1.0 * max(0.0, wave_height + 2.5) * pow(max(dot(LIGHT, -VIEW), 0.0), 4.0) * pow(0.5 - 0.5 * dot(LIGHT, NORMAL), 3.0);
	float sss_near = 0.5 * pow(dot_nv, 2.0);
	float lambertian = 0.5 * dot_nl;
	DIFFUSE_LIGHT += mix((sss_height + sss_near) * sss_modifier / (1.0 + light_mask) + lambertian, foam_color.rgb, foam_factor) * (1.0 - fresnel) * ATTENUATION * LIGHT_COLOR;
	SPECULAR_LIGHT += sun_color * sun_glint_factor * ATTENUATION * 0.35;
}
