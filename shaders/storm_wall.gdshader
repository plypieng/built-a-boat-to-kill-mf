shader_type spatial;
render_mode cull_disabled, unshaded, blend_mix, depth_draw_opaque;

uniform vec4 wall_color : source_color = vec4(0.08, 0.11, 0.14, 1.0);
uniform vec4 rim_color : source_color = vec4(0.28, 0.34, 0.40, 1.0);
uniform float intensity = 0.75;
uniform float scroll_speed = 0.4;

void fragment() {
	float vertical = smoothstep(0.02, 0.18, UV.y) * (1.0 - smoothstep(0.70, 1.0, UV.y));
	float band = 0.5 + 0.5 * sin((UV.y * 8.0 + TIME * scroll_speed) * 6.28318);
	float rim = smoothstep(0.75, 1.0, UV.y);
	vec3 tint = mix(wall_color.rgb, rim_color.rgb, rim * 0.4 + band * 0.08);
	ALBEDO = tint;
	ALPHA = clamp(vertical * intensity, 0.0, 1.0);
	EMISSION = rim_color.rgb * rim * intensity * 0.05;
}
