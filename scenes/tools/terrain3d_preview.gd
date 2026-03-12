@tool
extends Terrain3D

@export var regenerate_preview := false:
	set(value):
		if not value:
			return
		_clear_preview_regions()
		_build_preview_terrain()
		regenerate_preview = false


func _ready() -> void:
	_build_preview_terrain()


func _build_preview_terrain() -> void:
	if data == null:
		return
	if material == null:
		var terrain_material := Terrain3DMaterial.new()
		terrain_material.show_checkered = true
		material = terrain_material
	if assets == null:
		assets = Terrain3DAssets.new()
	if not data.get_regions_active().is_empty():
		return
	var image_size := Vector2i(256, 256)
	var height_image := Image.create(image_size.x, image_size.y, false, Image.FORMAT_RF)
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.024
	noise.fractal_octaves = 4
	noise.fractal_gain = 0.55
	height_image.lock()
	for y in range(image_size.y):
		for x in range(image_size.x):
			var uv := Vector2(float(x) / float(image_size.x), float(y) / float(image_size.y))
			var radial := clampf(1.0 - uv.distance_to(Vector2(0.5, 0.5)) * 1.85, 0.0, 1.0)
			var ridge := pow(radial, 2.2)
			var detail := noise.get_noise_2d(float(x), float(y)) * 0.24 + 0.5
			var height_value := clampf(ridge * detail, 0.0, 1.0)
			height_image.set_pixel(x, y, Color(height_value, 0.0, 0.0, 1.0))
	height_image.unlock()
	var imported_images: Array[Image] = []
	imported_images.resize(Terrain3DRegion.TYPE_MAX)
	imported_images[Terrain3DRegion.TYPE_HEIGHT] = height_image
	vertex_spacing = 2.2
	data.import_images(imported_images, Vector3.ZERO, -8.0, 22.0)
	data.calc_height_range(true)


func _clear_preview_regions() -> void:
	if data == null:
		return
	for region: Terrain3DRegion in data.get_regions_active():
		data.remove_region(region, false)
	data.update_maps(Terrain3DRegion.TYPE_MAX, true, false)
