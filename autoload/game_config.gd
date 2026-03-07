extends Node

const DEFAULT_HOST := "127.0.0.1"
const DEFAULT_PORT := 7000
const MAX_PLAYERS := 4
const DEFAULT_PLAYER_NAME := "Captain"
const DEFAULT_RUN_SEED := 424242

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
		"autoconnect": false,
		"quit_after_connect_ms": 0,
		"autodrive_ms": 0,
		"autodrive_throttle": 1.0,
		"autodrive_steer": 0.0,
		"autobrace": false,
		"autobrace_distance": 7.5,
		"autorun_demo": false,
		"autoclaim_station": "",
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
		elif arg == "--autoconnect":
			overrides["autoconnect"] = true
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
		elif arg.begins_with("--autoclaim-station="):
			overrides["autoclaim_station"] = arg.trim_prefix("--autoclaim-station=").strip_edges().to_lower()

	return overrides
