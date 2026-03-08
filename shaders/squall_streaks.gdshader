shader_type spatial;
render_mode cull_disabled, unshaded, blend_mix, depth_draw_never;

uniform vec4 streak_color : source_color = vec4(0.78, 0.90, 1.0, 1.0);
uniform float intensity = 0.0;
uniform float scroll_speed = 2.4;
uniform float density = 12.0;

void fragment() {
	float streaks = abs(sin((UV.x * density + TIME * scroll_speed) * 6.28318));
	streaks = pow(streaks, 12.0);
	float vertical = smoothstep(0.0, 0.1, UV.y) * (1.0 - smoothstep(0.72, 1.0, UV.y));
	float alpha = streaks * vertical * intensity * 0.7;
	ALBEDO = streak_color.rgb;
	ALPHA = clamp(alpha, 0.0, 1.0);
	EMISSION = streak_color.rgb * alpha * 0.2;
}
