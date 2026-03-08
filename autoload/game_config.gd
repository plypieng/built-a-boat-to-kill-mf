extends Node

const DEFAULT_HOST := "127.0.0.1"
const DEFAULT_PORT := 7000
const MAX_PLAYERS := 4
const DEFAULT_PLAYER_NAME := "Captain"
const DEFAULT_RUN_SEED := 424242

var _one_shot_flags := {}
var _hosted_server_pid := -1

func is_server_mode() -> bool:
	if OS.has_feature("dedicated_server"):
		return true
	return "--server" in OS.get_cmdline_user_args()

func parse_cmdline_overrides() -> Dictionary:
	var overrides := {
		"host": DEFAULT_HOST,
		"port": DEFAULT_PORT,
		"player_name": DEFAULT_PLAYER_NAME,
		"seed": DEFAULT_RUN_SEED,
		"parent_pid": 0,
		"capture_frame_path": "",
		"capture_frame_delay_ms": 0,
		"autoconnect": false,
		"autohost": false,
		"quit_after_connect_ms": 0,
		"autodrive_ms": 0,
		"autodrive_throttle": 1.0,
		"autodrive_steer": 0.0,
		"autobrace": false,
		"autobrace_distance": 7.5,
		"autorun_demo": false,
		"autorun_role": "",
		"autoforce_overboard": false,
		"autobuild_role": "",
		"autohangar_role": "",
		"autoclaim_station": "",
		"autocontinue_to_dock": false,
	}

	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--host="):
			overrides["host"] = arg.trim_prefix("--host=").strip_edges()
		elif arg.begins_with("--port="):
			overrides["port"] = max(1, arg.trim_prefix("--port=").to_int())
		elif arg.begins_with("--name="):
			overrides["player_name"] = arg.trim_prefix("--name=").strip_edges()
		elif arg.begins_with("--seed="):
			overrides["seed"] = arg.trim_prefix("--seed=").to_int()
		elif arg.begins_with("--parent-pid="):
			overrides["parent_pid"] = arg.trim_prefix("--parent-pid=").to_int()
		elif arg.begins_with("--capture-frame-path="):
			overrides["capture_frame_path"] = arg.trim_prefix("--capture-frame-path=").strip_edges()
		elif arg.begins_with("--capture-frame-delay-ms="):
			overrides["capture_frame_delay_ms"] = max(0, arg.trim_prefix("--capture-frame-delay-ms=").to_int())
		elif arg == "--autoconnect":
			overrides["autoconnect"] = true
		elif arg == "--autohost":
			overrides["autohost"] = true
		elif arg.begins_with("--quit-after-connect-ms="):
			overrides["quit_after_connect_ms"] = max(0, arg.trim_prefix("--quit-after-connect-ms=").to_int())
		elif arg.begins_with("--autodrive-ms="):
			overrides["autodrive_ms"] = max(0, arg.trim_prefix("--autodrive-ms=").to_int())
		elif arg.begins_with("--autodrive-throttle="):
			overrides["autodrive_throttle"] = clampf(arg.trim_prefix("--autodrive-throttle=").to_float(), -1.0, 1.0)
		elif arg.begins_with("--autodrive-steer="):
			overrides["autodrive_steer"] = clampf(arg.trim_prefix("--autodrive-steer=").to_float(), -1.0, 1.0)
		elif arg == "--autobrace":
			overrides["autobrace"] = true
		elif arg.begins_with("--autobrace-distance="):
			overrides["autobrace_distance"] = maxf(1.0, arg.trim_prefix("--autobrace-distance=").to_float())
		elif arg == "--autorun-demo":
			overrides["autorun_demo"] = true
		elif arg.begins_with("--autorun-role="):
			overrides["autorun_role"] = arg.trim_prefix("--autorun-role=").strip_edges().to_lower()
		elif arg == "--autoforce-overboard":
			overrides["autoforce_overboard"] = true
		elif arg.begins_with("--autobuild-role="):
			overrides["autobuild_role"] = arg.trim_prefix("--autobuild-role=").strip_edges().to_lower()
		elif arg.begins_with("--autohangar-role="):
			overrides["autohangar_role"] = arg.trim_prefix("--autohangar-role=").strip_edges().to_lower()
		elif arg.begins_with("--autoclaim-station="):
			overrides["autoclaim_station"] = arg.trim_prefix("--autoclaim-station=").strip_edges().to_lower()
		elif arg == "--autocontinue-to-dock":
			overrides["autocontinue_to_dock"] = true

	return overrides

func claim_one_shot_flag(flag_name: String) -> bool:
	if flag_name.is_empty():
		return true
	if bool(_one_shot_flags.get(flag_name, false)):
		return false
	_one_shot_flags[flag_name] = true
	return true

func register_hosted_server_pid(pid: int) -> void:
	_hosted_server_pid = pid

func clear_hosted_server_pid() -> void:
	_hosted_server_pid = -1

func shutdown_hosted_server() -> void:
	if _hosted_server_pid <= 0:
		return
	OS.kill(_hosted_server_pid)
	_hosted_server_pid = -1

func _exit_tree() -> void:
	shutdown_hosted_server()
