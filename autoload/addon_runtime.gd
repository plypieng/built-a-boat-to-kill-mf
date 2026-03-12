extends Node

signal debug_draw_changed(enabled: bool)
signal runtime_camera_mode_changed(mode: String)
signal terrain_preview_changed(enabled: bool)
signal spatial_audio_effects_changed(enabled: bool)

const CAMERA_MODE_LEGACY := "legacy"
const CAMERA_MODE_PHANTOM := "phantom"
const CAMERA_MODE_OVERVIEW := "overview"
const SCENE_PALETTER_REQUIRES_DOTNET := "Scene Paletter requires the Godot .NET editor build because its plugin entrypoint is C#."

var debug_draw_enabled := false
var terrain_preview_enabled := false
var spatial_audio_effects_enabled := true
var runtime_camera_mode := CAMERA_MODE_LEGACY

var _console_registered := false


func _ready() -> void:
	_apply_spatial_audio_effects()
	call_deferred("_register_dev_console_commands")


func _register_dev_console_commands() -> void:
	if _console_registered:
		return
	var console := get_node_or_null("/root/DevConsole")
	if console == null:
		call_deferred("_register_dev_console_commands")
		return
	console.add_command("addon_status", Callable(self, "_command_addon_status"))
	console.add_command("debug_draw", Callable(self, "_command_debug_draw"))
	console.add_command("camera_mode", Callable(self, "_command_camera_mode"))
	console.add_command("terrain_preview", Callable(self, "_command_terrain_preview"))
	console.add_command("spatial_audio", Callable(self, "_command_spatial_audio"))
	console.add_command("scene_paletter_status", Callable(self, "_command_scene_paletter_status"))
	_console_registered = true


func set_debug_draw_enabled(enabled: bool) -> void:
	if debug_draw_enabled == enabled:
		return
	debug_draw_enabled = enabled
	debug_draw_changed.emit(debug_draw_enabled)


func set_runtime_camera_mode(mode: String) -> void:
	var normalized_mode := mode.to_lower().strip_edges()
	if normalized_mode not in [CAMERA_MODE_LEGACY, CAMERA_MODE_PHANTOM, CAMERA_MODE_OVERVIEW]:
		return
	if runtime_camera_mode == normalized_mode:
		return
	runtime_camera_mode = normalized_mode
	runtime_camera_mode_changed.emit(runtime_camera_mode)


func set_terrain_preview_enabled(enabled: bool) -> void:
	if terrain_preview_enabled == enabled:
		return
	terrain_preview_enabled = enabled
	terrain_preview_changed.emit(terrain_preview_enabled)


func set_spatial_audio_effects_enabled(enabled: bool) -> void:
	if spatial_audio_effects_enabled == enabled:
		return
	spatial_audio_effects_enabled = enabled
	_apply_spatial_audio_effects()
	spatial_audio_effects_changed.emit(spatial_audio_effects_enabled)


func _apply_spatial_audio_effects() -> void:
	var spatial_audio_script := load("res://addons/spatial_audio_extended/spatial_audio_player_3d.gd")
	if spatial_audio_script != null and spatial_audio_script.has_method("set_global_effects_disabled"):
		spatial_audio_script.set_global_effects_disabled(not spatial_audio_effects_enabled)


func describe_runtime_status() -> String:
	return "camera=%s | debug_draw=%s | terrain_preview=%s | spatial_audio=%s" % [
		runtime_camera_mode,
		"on" if debug_draw_enabled else "off",
		"on" if terrain_preview_enabled else "off",
		"on" if spatial_audio_effects_enabled else "off",
	]


func _resolve_toggle_argument(args: Array, current_value: bool) -> Variant:
	if args.is_empty():
		return not current_value
	var value := str(args[0]).to_lower().strip_edges()
	match value:
		"1", "on", "true", "enable", "enabled", "yes":
			return true
		"0", "off", "false", "disable", "disabled", "no":
			return false
		"toggle":
			return not current_value
		_:
			return null


func _command_addon_status() -> String:
	return describe_runtime_status()


func _command_debug_draw(...args) -> String:
	var resolved: Variant = _resolve_toggle_argument(args, debug_draw_enabled)
	if resolved == null:
		return "Usage: debug_draw [on|off|toggle]"
	set_debug_draw_enabled(bool(resolved))
	return "Debug Draw %s" % ("enabled" if debug_draw_enabled else "disabled")


func _command_camera_mode(...args) -> String:
	if args.is_empty():
		return "camera_mode %s | valid: legacy, phantom, overview" % runtime_camera_mode
	var mode := str(args[0]).to_lower().strip_edges()
	if mode not in [CAMERA_MODE_LEGACY, CAMERA_MODE_PHANTOM, CAMERA_MODE_OVERVIEW]:
		return "Usage: camera_mode [legacy|phantom|overview]"
	set_runtime_camera_mode(mode)
	return "Camera mode set to %s" % runtime_camera_mode


func _command_terrain_preview(...args) -> String:
	var resolved: Variant = _resolve_toggle_argument(args, terrain_preview_enabled)
	if resolved == null:
		return "Usage: terrain_preview [on|off|toggle]"
	set_terrain_preview_enabled(bool(resolved))
	return "Terrain preview %s" % ("enabled" if terrain_preview_enabled else "disabled")


func _command_spatial_audio(...args) -> String:
	var resolved: Variant = _resolve_toggle_argument(args, spatial_audio_effects_enabled)
	if resolved == null:
		return "Usage: spatial_audio [on|off|toggle]"
	set_spatial_audio_effects_enabled(bool(resolved))
	return "Spatial audio effects %s" % ("enabled" if spatial_audio_effects_enabled else "disabled")


func _command_scene_paletter_status() -> String:
	return SCENE_PALETTER_REQUIRES_DOTNET
