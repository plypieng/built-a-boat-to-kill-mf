@tool
class_name SeaSkyRig
extends Node3D

const SeaVisualProfileLibrary = preload("res://scenes/shared/environment/sea_visual_profile_library.gd")
const SEA_SKY_SHADER := preload("res://scenes/shared/environment/sea_sky.gdshader")

@export var preset_id: StringName = &"open_ocean"
@export var sun_rotation_degrees := Vector3(-42.0, 28.0, 0.0)
@export_range(0.0, 4.0, 0.01) var base_sun_energy := 1.0

var _world_environment: WorldEnvironment
var _sun_light: DirectionalLight3D
var _sky_material: ShaderMaterial

func _ready() -> void:
	_ensure_nodes()
	if not Engine.is_editor_hint() or preset_id != StringName():
		apply_named_preset(String(preset_id))

func get_world_environment() -> WorldEnvironment:
	_ensure_nodes()
	return _world_environment

func get_sun_light() -> DirectionalLight3D:
	_ensure_nodes()
	return _sun_light

func get_sun_direction() -> Vector3:
	_ensure_nodes()
	return _sun_light.global_transform.basis.z.normalized()

func apply_named_preset(next_preset_id: String) -> void:
	var target_id := next_preset_id if not next_preset_id.is_empty() else "open_ocean"
	preset_id = StringName(target_id)
	apply_profile(SeaVisualProfileLibrary.get_profile(target_id), 0.0, 1.0)

func apply_profile(profile: Dictionary, storm_strength: float = 0.0, blend: float = 1.0) -> void:
	_ensure_nodes()

	var t := clampf(blend, 0.0, 1.0)
	var environment := _world_environment.environment
	if environment == null:
		environment = Environment.new()
		_world_environment.environment = environment
		_attach_sky(environment)

	if environment.sky == null or environment.sky.sky_material == null:
		_attach_sky(environment)

	var top_color: Color = profile.get("sky_top_color", Color(0.17, 0.44, 0.72))
	var horizon_color: Color = profile.get("sky_horizon_color", profile.get("horizon_color", Color(0.73, 0.84, 0.90)))
	var ground_horizon: Color = profile.get("ground_horizon_color", horizon_color.darkened(0.55))
	var ground_bottom: Color = profile.get("ground_bottom_color", Color(0.05, 0.10, 0.15))
	var deep_color: Color = profile.get("deep_color", Color(0.02, 0.14, 0.25))
	var shallow_color: Color = profile.get("shallow_color", Color(0.08, 0.39, 0.49))
	var fog_density := maxf(0.0, float(profile.get("fog_density", 0.0)) + storm_strength * 0.004)

	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_energy = lerpf(environment.ambient_light_energy, float(profile.get("ambient_light_energy", 0.78)) - storm_strength * 0.16, t)
	environment.ambient_light_color = environment.ambient_light_color.lerp(profile.get("ambient_light_color", horizon_color.lerp(shallow_color, 0.34)), t)
	environment.fog_enabled = fog_density > 0.002
	environment.fog_density = lerpf(environment.fog_density, fog_density, t)
	environment.background_color = environment.background_color.lerp(profile.get("background", horizon_color), t)

	_sun_light.rotation_degrees = _sun_light.rotation_degrees.lerp(sun_rotation_degrees, t)
	_sun_light.light_color = _sun_light.light_color.lerp(profile.get("sun_color", Color(1.0, 0.94, 0.80)), t)
	_sun_light.light_energy = lerpf(_sun_light.light_energy, base_sun_energy * (float(profile.get("sun_energy", 1.0)) - storm_strength * 0.10), t)

	_set_color_parameter("sky_top_color", top_color.darkened(storm_strength * 0.08), t)
	_set_color_parameter("sky_horizon_color", horizon_color.lightened(maxf(0.0, 0.18 - storm_strength * 0.06)), t)
	_set_color_parameter("ground_horizon_color", ground_horizon.darkened(storm_strength * 0.08), t)
	_set_color_parameter("ground_bottom_color", ground_bottom.lerp(deep_color.darkened(0.60), t), t)
	_set_color_parameter("sun_disc_color", profile.get("sun_disc_color", profile.get("sun_color", Color(1.0, 0.94, 0.80))), t)
	_set_color_parameter("sun_aura_color", profile.get("sun_aura_color", horizon_color.lightened(0.18)), t)
	_set_float_parameter("energy_multiplier", float(profile.get("sky_energy", 0.76)) - storm_strength * 0.06, t)
	_set_float_parameter("sun_disc_size", float(profile.get("sun_disc_size", 0.024)), t)
	_set_float_parameter("sun_aura_strength", clampf(float(profile.get("sun_aura_strength", 0.26)) - storm_strength * 0.06, 0.04, 1.0), t)
	_set_float_parameter("sun_scatter_strength", float(profile.get("sun_scatter_strength", 0.32)), t)
	_set_float_parameter("haze_amount", clampf(float(profile.get("haze_amount", 0.18)) + storm_strength * 0.10, 0.0, 1.0), t)
	_set_float_parameter("cloud_band_strength", clampf(float(profile.get("cloud_band_strength", 0.22)) + storm_strength * 0.18, 0.0, 1.0), t)
	_sky_material.set_shader_parameter("sun_direction", get_sun_direction())

func _ensure_nodes() -> void:
	if _world_environment == null:
		_world_environment = get_node_or_null("WorldEnvironment") as WorldEnvironment
		if _world_environment == null:
			_world_environment = WorldEnvironment.new()
			_world_environment.name = "WorldEnvironment"
			add_child(_world_environment)
	if _world_environment.environment == null:
		_world_environment.environment = Environment.new()
	if _sun_light == null:
		_sun_light = get_node_or_null("SunLight") as DirectionalLight3D
		if _sun_light == null:
			_sun_light = DirectionalLight3D.new()
			_sun_light.name = "SunLight"
			add_child(_sun_light)
	_sun_light.rotation_degrees = sun_rotation_degrees
	_sun_light.light_energy = base_sun_energy
	_attach_sky(_world_environment.environment)

func _attach_sky(environment: Environment) -> void:
	if environment == null:
		return
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	if environment.sky == null:
		environment.sky = Sky.new()
	if _sky_material == null:
		_sky_material = ShaderMaterial.new()
		_sky_material.shader = SEA_SKY_SHADER
	if environment.sky.sky_material == null:
		environment.sky.sky_material = _sky_material
	elif environment.sky.sky_material is ShaderMaterial:
		_sky_material = environment.sky.sky_material as ShaderMaterial
		if _sky_material.shader == null:
			_sky_material.shader = SEA_SKY_SHADER

func _set_float_parameter(parameter_name: StringName, target: float, blend: float) -> void:
	var current_variant: Variant = _sky_material.get_shader_parameter(parameter_name)
	var current: float = current_variant if current_variant is float else 0.0
	_sky_material.set_shader_parameter(parameter_name, lerpf(current, target, blend))

func _set_color_parameter(parameter_name: StringName, target: Color, blend: float) -> void:
	var current_variant: Variant = _sky_material.get_shader_parameter(parameter_name)
	var current: Color = current_variant if current_variant is Color else Color.BLACK
	_sky_material.set_shader_parameter(parameter_name, current.lerp(target, blend))
