shader_type spatial;
render_mode cull_disabled, unshaded, blend_mix, depth_draw_never;

uniform vec4 core_color : source_color = vec4(0.84, 0.94, 0.98, 1.0);
uniform vec4 edge_color : source_color = vec4(0.36, 0.60, 0.72, 1.0);
uniform float wake_strength = 0.0;
uniform float noise_scale = 1.0;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float ripple = sin((world_pos.z + TIME * 3.8) * 2.1 * noise_scale + world_pos.x * 3.4) * 0.03;
	VERTEX.y += ripple * wake_strength;
}

void fragment() {
	float along = 1.0 - UV.y;
	float width = 1.0 - smoothstep(0.12, 1.0, abs(UV.x - 0.5) * 2.0);
	float tail = smoothstep(0.0, 0.22, along) * (1.0 - smoothstep(0.82, 1.0, along));
	float froth = width * tail * wake_strength;
	vec3 tint = mix(edge_color.rgb, core_color.rgb, width);
	ALBEDO = tint;
	ALPHA = clamp(froth * 0.92, 0.0, 1.0);
	EMISSION = tint * froth * 0.22;
}
