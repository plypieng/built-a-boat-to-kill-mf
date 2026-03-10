extends RefCounted

static var _wood_texture: Texture2D

static func apply_wood(material: StandardMaterial3D, base_color: Color, roughness: float = 0.52) -> void:
	if material == null:
		return
	material.albedo_texture = _get_wood_texture()
	material.albedo_color = _derive_wood_tint(base_color)
	material.roughness = roughness
	material.metallic = 0.0
	material.uv1_scale = Vector3(0.74, 0.74, 0.74)

static func _get_wood_texture() -> Texture2D:
	if _wood_texture != null:
		return _wood_texture

	var width := 96
	var height := 96
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var dark_tone := Color(0.31, 0.20, 0.11, 1.0)
	var light_tone := Color(0.78, 0.58, 0.33, 1.0)
	for y in range(height):
		for x in range(width):
			var xf := float(x) / float(width)
			var yf := float(y) / float(height)
			var grain := 0.5 + 0.5 * sin(xf * TAU * 10.0 + sin(yf * TAU * 1.4) * 1.6)
			var fine_grain := 0.5 + 0.5 * sin(xf * TAU * 24.0 + yf * TAU * 0.8)
			var plank_seam := 0.0
			if x % 24 <= 1:
				plank_seam = 0.18
			var tone := clampf(0.28 + grain * 0.46 + fine_grain * 0.12 - plank_seam, 0.0, 1.0)
			image.set_pixel(x, y, dark_tone.lerp(light_tone, tone))
	image.generate_mipmaps()
	_wood_texture = ImageTexture.create_from_image(image)
	return _wood_texture

static func _derive_wood_tint(base_color: Color) -> Color:
	var wood_base := Color(0.68, 0.50, 0.30, 1.0)
	return wood_base.lerp(base_color, 0.24)
