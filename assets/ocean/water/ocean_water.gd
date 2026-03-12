# Adapted from https://github.com/Lucactus22/GodotOceanWaves_bouyancy/tree/main
@tool
class_name RunOceanRenderer
extends MeshInstance3D
## Handles updating the displacement/normal maps for the water material as well as
## managing wave generation pipelines.

const DEFAULT_WATER_MAT := preload("res://assets/ocean/materials/ocean_water.tres")
const FOAM_NOISE_TEX := preload("res://assets/third_party/ambientcg/Foam001_Opacity.jpg")
const WATER_MESH_HIGH8K := preload("res://assets/ocean/water/clipmap_high_8k.obj")
const WATER_MESH_HIGH := preload("res://assets/ocean/water/clipmap_high.obj")
const WATER_MESH_LOW := preload("res://assets/ocean/water/clipmap_low.obj")
const DEFAULT_TILE_LENGTHS := [
	Vector2(420.0, 420.0),
	Vector2(140.0, 140.0),
	Vector2(60.0, 60.0),
	Vector2(26.0, 26.0),
]
const DEFAULT_DISPLACEMENT_SCALES := [0.78, 0.46, 0.14, 0.10]
const DEFAULT_NORMAL_SCALES := [0.72, 0.50, 0.18, 0.14]

enum MeshQuality { LOW, HIGH, HIGH8K }

# ----- Config Variables ----- #
@export_group('Wave Parameters')
@export_color_no_alpha var water_color : Color = Color(0.1, 0.15, 0.18) :
	set(value): water_color = value; RenderingServer.global_shader_parameter_set(&'water_color', water_color.srgb_to_linear())

@export_color_no_alpha var foam_color : Color = Color(0.73, 0.67, 0.62) :
	set(value): foam_color = value; RenderingServer.global_shader_parameter_set(&'foam_color', foam_color.srgb_to_linear())

## The parameters for wave cascades. Each parameter set represents one cascade.
## Recreates all compute piplines whenever a cascade is added or removed!
@export var parameters : Array[WaveCascadeParameters] :
	set(value):
		var new_size := len(value)
		# All below logic is basically just required for using in the editor!
		for i in range(new_size):
			# Ensure all values in the array have an associated cascade
			if not value[i]: value[i] = WaveCascadeParameters.new()
			if not value[i].is_connected(&'scale_changed', _update_scales_uniform):
				value[i].scale_changed.connect(_update_scales_uniform)
			value[i].spectrum_seed = Vector2i(rng.randi_range(-10000, 10000), rng.randi_range(-10000, 10000))
			value[i].time = 120.0 + PI*i # We make sure to choose a time offset such that cascades don't interfere!
			parameters = value
			_setup_wave_generator()
			_update_scales_uniform()

@export_group('Performance Parameters')
@export_enum('128x128:128', '256x256:256', '512x512:512', '1024x1024:1024') var map_size := 1024 :
	set(value):
		map_size = value
		_setup_wave_generator()

@export var mesh_quality := MeshQuality.HIGH8K :
	set(value):
		mesh_quality = value
		if mesh_quality == MeshQuality.LOW:
			mesh = WATER_MESH_LOW
		if mesh_quality == MeshQuality.HIGH:
			mesh = WATER_MESH_HIGH
		if mesh_quality == MeshQuality.HIGH8K:
			mesh = WATER_MESH_HIGH8K

## How many times the wave simulation should update per second.
## Note: This doesn't reduce the frame stutter caused by FFT calculation, only
##       minimizes GPU time taken by it!
@export_range(0, 60) var updates_per_second := 50.0 :
	set(value):
		next_update_time = next_update_time - (1.0/(updates_per_second + 1e-10) - 1.0/(value + 1e-10))
		updates_per_second = value

@export var displacement_updates_per_second := 10
@export var sea_surface_y := -0.12

# ----- Bookkeeping Variables ----- #
var wave_generator : WaveGenerator :
	set(value):
		if wave_generator: wave_generator.queue_free()
		wave_generator = value
		add_child(wave_generator)
var rng = RandomNumberGenerator.new()
var time := 0.0
var next_update_time := 0.0

var displacement_maps := Texture2DArrayRD.new()
var normal_maps := Texture2DArrayRD.new()

var _accumulator = 0.0;
var _displacement_update_rate: float;
var _img: Image = null;
var _img_height: int;
var _img_width: int;
var map_scales : PackedVector4Array;
var _last_spectrum_key := ""

# ------ Public Interface ----- #
func get_wave_height(global_position: Vector3) -> float:
	if _img == null or map_scales.is_empty():
		return 0.0
	var uv: Vector2 = Vector2(global_position.x, global_position.z)
	var displacement: Vector3 = Vector3.ZERO
	
	# TODO: Do once for each cascade for best accuracy
	var i = 0;
	var scales: Vector4 = map_scales[i]
	var sample_uv: Vector2 = uv * Vector2(scales.x, scales.y)
	displacement += _sample_displacement(i, sample_uv) * scales.z
	
	return displacement.y

func apply_sea_state(biome_id: String, profile: Dictionary, hazard_level: float, boat_position: Vector3, _time_seconds: float) -> void:
	global_position = Vector3(boat_position.x, sea_surface_y, boat_position.z)
	_apply_palette(profile, hazard_level)

	var spectrum_key := "%s:%d:%d:%d" % [
		biome_id,
		int(round(hazard_level * 8.0)),
		int(round(float(profile.get("wave_speed", 1.0)) * 10.0)),
		int(round(float(profile.get("wave_amp", 0.24)) * 100.0)),
	]
	if spectrum_key != _last_spectrum_key:
		_reconfigure_cascades(profile, hazard_level)
		_last_spectrum_key = spectrum_key

func apply_sun_state(sun_direction: Vector3, sun_color: Color, sun_glint_strength: float, sun_glint_focus: float, sun_horizon_fade: float) -> void:
	var water_material := material_override as ShaderMaterial
	if water_material == null:
		return
	water_material.set_shader_parameter("sun_direction", sun_direction)
	water_material.set_shader_parameter("sun_color", sun_color)
	water_material.set_shader_parameter("sun_glint_strength", sun_glint_strength)
	water_material.set_shader_parameter("sun_glint_focus", sun_glint_focus)
	water_material.set_shader_parameter("sun_horizon_fade", sun_horizon_fade)

# ------ Private Methods ----- #
func _init() -> void:
	rng.set_seed(1234) # This seed gives big waves!

func _ready() -> void:
	_ensure_default_parameters()
	if material_override == null:
		material_override = DEFAULT_WATER_MAT.duplicate()
	elif material_override is ShaderMaterial:
		material_override = (material_override as ShaderMaterial).duplicate()

	map_scales.resize(len(parameters))
	_configure_material()

	RenderingServer.global_shader_parameter_set(&'water_color', water_color.srgb_to_linear())
	RenderingServer.global_shader_parameter_set(&'foam_color', foam_color.srgb_to_linear())

	if wave_generator == null:
		_setup_wave_generator()
	if wave_generator != null:
		_img = wave_generator.retrieve_displacement_map(0, _img)
		_img_height = _img.get_height()
		_img_width = _img.get_width()
	_displacement_update_rate = 1.0 / maxf(1.0, float(displacement_updates_per_second))

func _process(delta : float) -> void:
	# TODO: These should probably be the same update
	# Update waves once every 1.0/updates_per_second.
	if updates_per_second == 0 or time >= next_update_time:
		var target_update_delta := 1.0 / (updates_per_second + 1e-10)
		var update_delta := delta if updates_per_second == 0 else target_update_delta + (time - next_update_time)
		next_update_time = time + target_update_delta
		_update_water(update_delta)
	time += delta
	
	# Resample displacement
	_accumulator += delta;
	if _accumulator >= _displacement_update_rate:
		_accumulator -= _displacement_update_rate
		_img = wave_generator.retrieve_displacement_map(0, _img)

func _setup_wave_generator() -> void:
	if parameters.size() <= 0: return
	for param in parameters:
		param.should_generate_spectrum = true

	wave_generator = WaveGenerator.new()
	wave_generator.map_size = map_size
	wave_generator.init_gpu(maxi(2, parameters.size())) # FIXME: This is needed because my RenderContext API sucks...

	displacement_maps.texture_rd_rid = RID()
	normal_maps.texture_rd_rid = RID()
	displacement_maps.texture_rd_rid = wave_generator.descriptors[&'displacement_map'].rid
	normal_maps.texture_rd_rid = wave_generator.descriptors[&'normal_map'].rid

	RenderingServer.global_shader_parameter_set(&'num_cascades', parameters.size())
	RenderingServer.global_shader_parameter_set(&'displacements', displacement_maps)
	RenderingServer.global_shader_parameter_set(&'normals', normal_maps)

func _update_scales_uniform() -> void:
	map_scales.resize(len(parameters))
	for i in len(parameters):
		var params := parameters[i]
		var uv_scale := Vector2.ONE / params.tile_length
		map_scales[i] = Vector4(uv_scale.x, uv_scale.y, params.displacement_scale, params.normal_scale)
	
	var water_material := material_override as ShaderMaterial
	if water_material != null:
		water_material.set_shader_parameter(&'map_scales', map_scales)

func _update_water(delta : float) -> void:
	if wave_generator == null: _setup_wave_generator()
	wave_generator.update(delta, parameters)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		displacement_maps.texture_rd_rid = RID()
		normal_maps.texture_rd_rid = RID()

func _sample_displacement(cascade: int, uv: Vector2) -> Vector3:
	# Wrap UVs
	uv.x = wrapf(uv.x, 0.0, 1.0)
	uv.y = wrapf(uv.y, 0.0, 1.0)
	
	# Calculate coordinates
	var x: float = uv.x * (_img_width - 1)
	var y: float = uv.y * (_img_width - 1)
	
	var x0 := int(floor(x))
	var y0 := int(floor(y))
	var x1 = min(x0 + 1, _img_width - 1)
	var y1 = min(y0 + 1, _img_width - 1)
	
	var fx := x - x0
	var fy := y - y0
	
	# Get cached pixel data
	var c00: Color = _img.get_pixel(x0, y0) # _cached_displacements[y0 * img_width + x0]
	var c10: Color = _img.get_pixel(x1, y0) # _cached_displacements[y0 * img_width + x1]
	var c01: Color = _img.get_pixel(x0, y1) #_cached_displacements[y1 * img_width + x0]
	var c11: Color = _img.get_pixel(x1, y1) #_cached_displacements[y1 * img_width + x1]
	
	# Bilinear interpolation
	var col_x0 := c00.lerp(c10, fx)
	var col_x1 := c01.lerp(c11, fx)
	var col := col_x0.lerp(col_x1, fy)
	
	return Vector3(col.r, col.g, col.b)

func _configure_material() -> void:
	var water_material := material_override as ShaderMaterial
	if water_material == null:
		return
	water_material.set_shader_parameter("foam_noise_tex", FOAM_NOISE_TEX)
	_update_scales_uniform()

func _ensure_default_parameters() -> void:
	if not parameters.is_empty():
		return
	var defaults: Array[WaveCascadeParameters] = []
	for i in range(DEFAULT_TILE_LENGTHS.size()):
		var cascade := WaveCascadeParameters.new()
		cascade.tile_length = DEFAULT_TILE_LENGTHS[i]
		cascade.displacement_scale = DEFAULT_DISPLACEMENT_SCALES[i]
		cascade.normal_scale = DEFAULT_NORMAL_SCALES[i]
		cascade.wind_speed = 6.0
		cascade.wind_direction = 15.0
		cascade.fetch_length = 220.0
		cascade.swell = [1.8, 1.1, 0.55, 0.0][i]
		cascade.spread = [0.52, 0.56, 0.64, 0.72][i]
		cascade.detail = [0.92, 0.96, 1.0, 1.0][i]
		cascade.whitecap = [0.34, 0.42, 0.28, 0.0][i]
		cascade.foam_amount = [0.18, 0.72, 0.18, 0.92][i]
		defaults.append(cascade)
	parameters = defaults

func _apply_palette(profile: Dictionary, hazard_level: float) -> void:
	var deep_color: Color = profile.get("deep_color", Color(0.02, 0.14, 0.25))
	var shallow_color: Color = profile.get("shallow_color", Color(0.08, 0.39, 0.49))
	var clarity := float(profile.get("clarity", 0.6))
	var reflection_strength := float(profile.get("reflection_strength", 0.5))
	var chop_strength := float(profile.get("chop_strength", 0.18))

	water_color = deep_color.lerp(shallow_color, 0.24)
	foam_color = profile.get("foam_color", Color(0.92, 0.97, 0.99))

	var water_material := material_override as ShaderMaterial
	if water_material == null:
		return
	water_material.set_shader_parameter(
		"depth_color_consumption",
		Vector3(
			6.0 + (1.0 - clarity) * 8.0,
			18.0 + (1.0 - clarity) * 12.0,
			30.0 + (1.0 - clarity) * 18.0
		)
	)
	water_material.set_shader_parameter("roughness", clampf(0.54 - reflection_strength * 0.26 + hazard_level * 0.08, 0.22, 0.62))
	water_material.set_shader_parameter("normal_strength", clampf(0.70 + chop_strength * 0.75 + hazard_level * 0.22, 0.70, 1.28))
	water_material.set_shader_parameter("sun_color", profile.get("sun_color", Color(1.0, 0.94, 0.80)))
	water_material.set_shader_parameter("sun_glint_strength", clampf(float(profile.get("sun_glint_strength", reflection_strength)) + hazard_level * 0.08, 0.0, 1.6))
	water_material.set_shader_parameter("sun_glint_focus", float(profile.get("sun_glint_focus", 110.0)))
	water_material.set_shader_parameter("sun_horizon_fade", float(profile.get("sun_horizon_fade", 0.18)))

func _reconfigure_cascades(profile: Dictionary, hazard_level: float) -> void:
	if parameters.size() < 4:
		_ensure_default_parameters()

	var wave_amp := float(profile.get("wave_amp", 0.24))
	var wave_speed := float(profile.get("wave_speed", 1.0))
	var chop_strength := float(profile.get("chop_strength", 0.18))
	var length_scale := lerpf(1.06, 0.92, clampf((wave_speed - 0.84) / 0.36, 0.0, 1.0))
	var wind_speed := 3.8 + wave_speed * 3.2 + hazard_level * 4.8
	var fetch_length := 160.0 + wave_speed * 80.0 + hazard_level * 240.0
	var base_direction := 12.0 + hazard_level * 16.0

	var settings := [
		{
			"tile_length": DEFAULT_TILE_LENGTHS[0] * length_scale,
			"displacement_scale": clampf(wave_amp * 2.55, 0.32, 1.12),
			"normal_scale": clampf(wave_amp * 2.10, 0.28, 0.98),
			"wind_speed": wind_speed * 0.82,
			"wind_direction": base_direction,
			"fetch_length": fetch_length,
			"swell": lerpf(1.5, 2.0, hazard_level),
			"spread": 0.52,
			"detail": 0.90,
			"whitecap": clampf(0.26 + chop_strength * 0.36, 0.18, 0.48),
			"foam_amount": clampf(0.12 + chop_strength * 0.45, 0.08, 0.36),
		},
		{
			"tile_length": DEFAULT_TILE_LENGTHS[1] * length_scale,
			"displacement_scale": clampf(wave_amp * 1.30 + chop_strength * 0.38, 0.22, 0.68),
			"normal_scale": clampf(wave_amp * 1.05 + chop_strength * 0.42, 0.20, 0.64),
			"wind_speed": wind_speed,
			"wind_direction": base_direction + 8.0,
			"fetch_length": fetch_length,
			"swell": lerpf(1.0, 1.4, hazard_level),
			"spread": 0.56,
			"detail": 0.96,
			"whitecap": clampf(0.34 + chop_strength * 0.44 + hazard_level * 0.06, 0.28, 0.62),
			"foam_amount": clampf(0.46 + chop_strength * 1.35 + hazard_level * 0.32, 0.42, 1.30),
		},
		{
			"tile_length": DEFAULT_TILE_LENGTHS[2] * length_scale,
			"displacement_scale": clampf(chop_strength * 0.32 + wave_amp * 0.18, 0.08, 0.24),
			"normal_scale": clampf(chop_strength * 0.42 + wave_amp * 0.16, 0.10, 0.28),
			"wind_speed": wind_speed * 1.18,
			"wind_direction": base_direction - 12.0,
			"fetch_length": fetch_length * 0.78,
			"swell": 0.55,
			"spread": 0.64,
			"detail": 1.0,
			"whitecap": clampf(0.22 + chop_strength * 0.34, 0.10, 0.42),
			"foam_amount": clampf(0.16 + hazard_level * 0.24, 0.08, 0.40),
		},
		{
			"tile_length": DEFAULT_TILE_LENGTHS[3] * length_scale,
			"displacement_scale": clampf(chop_strength * 0.22, 0.04, 0.16),
			"normal_scale": clampf(chop_strength * 0.48 + 0.08, 0.10, 0.32),
			"wind_speed": wind_speed * 1.34,
			"wind_direction": base_direction + 20.0,
			"fetch_length": fetch_length * 0.58,
			"swell": 0.0,
			"spread": 0.74,
			"detail": 1.0,
			"whitecap": 0.0,
			"foam_amount": clampf(0.82 + hazard_level * 0.68, 0.82, 1.56),
		},
	]

	for i in range(min(parameters.size(), settings.size())):
		var cascade: WaveCascadeParameters = parameters[i]
		var values: Dictionary = settings[i]
		cascade.tile_length = values["tile_length"]
		cascade.displacement_scale = values["displacement_scale"]
		cascade.normal_scale = values["normal_scale"]
		cascade.wind_speed = values["wind_speed"]
		cascade.wind_direction = values["wind_direction"]
		cascade.fetch_length = values["fetch_length"]
		cascade.swell = values["swell"]
		cascade.spread = values["spread"]
		cascade.detail = values["detail"]
		cascade.whitecap = values["whitecap"]
		cascade.foam_amount = values["foam_amount"]
