shader_type spatial;
render_mode cull_disabled, unshaded, blend_mix, depth_draw_never;

uniform vec4 ring_color : source_color = vec4(0.88, 0.96, 1.0, 1.0);
uniform vec4 mist_color : source_color = vec4(0.52, 0.72, 0.82, 1.0);
uniform float life_ratio = 0.0;
uniform float intensity = 1.0;

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float radius = length(centered) * 2.0;
	float ring_center = mix(0.1, 0.88, life_ratio);
	float ring = 1.0 - smoothstep(0.0, 0.12, abs(radius - ring_center));
	float mist = (1.0 - smoothstep(0.0, 1.0, radius)) * (1.0 - life_ratio);
	vec3 tint = mix(mist_color.rgb, ring_color.rgb, ring);
	ALBEDO = tint;
	ALPHA = clamp((ring * 0.85 + mist * 0.48) * intensity * (1.0 - life_ratio * 0.45), 0.0, 1.0);
	EMISSION = tint * (ring * 0.24 + mist * 0.08) * intensity;
}
