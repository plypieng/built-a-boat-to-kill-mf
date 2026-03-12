shader_type sky;

uniform vec3 sky_top_color : source_color = vec3(0.17, 0.44, 0.72);
uniform vec3 sky_horizon_color : source_color = vec3(0.73, 0.84, 0.90);
uniform vec3 ground_horizon_color : source_color = vec3(0.24, 0.36, 0.42);
uniform vec3 ground_bottom_color : source_color = vec3(0.05, 0.10, 0.15);
uniform vec3 sun_disc_color : source_color = vec3(1.0, 0.94, 0.82);
uniform vec3 sun_aura_color : source_color = vec3(0.96, 0.82, 0.62);
uniform vec3 sun_direction = vec3(0.0, 0.72, 0.69);
uniform float energy_multiplier : hint_range(0.0, 4.0) = 0.82;
uniform float sun_disc_size : hint_range(0.001, 0.08) = 0.024;
uniform float sun_aura_strength : hint_range(0.0, 1.0) = 0.26;
uniform float sun_scatter_strength : hint_range(0.0, 1.0) = 0.32;
uniform float haze_amount : hint_range(0.0, 1.0) = 0.18;
uniform float cloud_band_strength : hint_range(0.0, 1.0) = 0.22;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += noise(p) * amplitude;
		p = p * 2.03 + vec2(13.7, 9.2);
		amplitude *= 0.5;
	}
	return value;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	vec3 sun_dir = normalize(sun_direction);
	float horizon = 1.0 - smoothstep(0.0, 0.55, abs(dir.y));
	float up = clamp(dir.y * 0.5 + 0.5, 0.0, 1.0);
	float down = clamp(-dir.y, 0.0, 1.0);

	vec3 base = mix(ground_bottom_color, ground_horizon_color, smoothstep(0.0, 0.32, down));
	base = mix(base, sky_horizon_color, smoothstep(-0.06, 0.12, dir.y));
	base = mix(base, sky_top_color, smoothstep(0.12, 0.92, up));

	float azimuth = atan(dir.x, dir.z);
	float latitude = acos(clamp(dir.y, -1.0, 1.0));
	vec2 cloud_uv = vec2(azimuth * 0.55, latitude * 2.4);
	float cloud_noise = fbm(cloud_uv * vec2(2.4, 3.8) + vec2(0.0, TIME * 0.004));
	float cloud_mask = smoothstep(0.36, 0.74, cloud_noise) * horizon;
	base = mix(base, mix(base, sky_horizon_color, 0.35), cloud_mask * cloud_band_strength);

	float sun_dot = clamp(dot(dir, sun_dir), 0.0, 1.0);
	float disc = smoothstep(cos(sun_disc_size), cos(sun_disc_size * 0.52), sun_dot);
	float aura = pow(sun_dot, mix(18.0, 5.0, haze_amount)) * sun_aura_strength;
	float scatter = pow(max(sun_dot, 0.0), 3.0) * sun_scatter_strength * (0.35 + horizon * 0.65 + haze_amount);

	vec3 color = base;
	color += sun_aura_color * aura;
	color += mix(sun_aura_color, sun_disc_color, 0.55) * scatter;
	color = mix(color, sun_disc_color, disc);

	COLOR = color * energy_multiplier;
}
