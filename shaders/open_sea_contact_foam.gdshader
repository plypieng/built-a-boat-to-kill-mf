shader_type spatial;
render_mode cull_disabled, unshaded, blend_mix, depth_draw_never;

uniform vec4 core_color : source_color = vec4(0.90, 0.96, 1.0, 1.0);
uniform vec4 edge_color : source_color = vec4(0.58, 0.76, 0.84, 1.0);
uniform float intensity = 0.35;
uniform float foam_radius = 0.68;
uniform float foam_width = 0.18;
uniform float soft_fill = 0.18;
uniform float breakup_strength = 0.28;
uniform float scroll_speed = 0.55;
uniform sampler2D foam_mask_texture : source_color;
uniform sampler2D foam_color_texture : source_color;
uniform bool use_foam_mask = false;
uniform bool use_foam_color = false;
uniform float mask_tiling = 0.080;
uniform vec2 mask_scroll = vec2(0.060, -0.040);
uniform float mask_contrast = 1.20;

varying vec2 v_world_xz;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_xz = world_pos.xz;
	float bob = sin((world_pos.x + TIME * 2.6) * 0.18) * cos((world_pos.z - TIME * 2.2) * 0.16);
	VERTEX.y += bob * 0.022 * intensity;
}

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float radius = length(centered) * 2.0;
	float ring = 1.0 - smoothstep(foam_width * 0.28, foam_width, abs(radius - foam_radius));
	float noise = sin(v_world_xz.x * 0.16 + TIME * scroll_speed) * cos(v_world_xz.y * 0.22 - TIME * (scroll_speed * 1.14));
	vec2 mask_uv = v_world_xz * mask_tiling + TIME * mask_scroll;
	float texture_mask = 1.0;
	if (use_foam_mask) {
		texture_mask = texture(foam_mask_texture, mask_uv).r;
		texture_mask = clamp((texture_mask - 0.5) * mask_contrast + 0.5, 0.0, 1.0);
	}
	float breakup = clamp(0.7 + noise * breakup_strength, 0.0, 1.0) * mix(0.65, 1.0, texture_mask);
	ring *= breakup;
	float fill = (1.0 - smoothstep(0.0, foam_radius * 0.96, radius)) * soft_fill * (0.72 + noise * 0.18) * mix(0.72, 1.0, texture_mask);
	float edge_fade = 1.0 - smoothstep(0.92, 1.22, radius);
	float alpha = clamp((ring * 0.88 + fill) * intensity * edge_fade, 0.0, 1.0);
	vec3 tint = mix(edge_color.rgb, core_color.rgb, clamp(ring * 0.95 + fill * 0.6, 0.0, 1.0));
	if (use_foam_color) {
		vec3 texture_tint = texture(foam_color_texture, mask_uv * 0.72).rgb;
		tint = mix(tint, texture_tint, 0.26);
	}
	ALBEDO = tint;
	ALPHA = alpha;
	EMISSION = tint * alpha * 0.18;
}
