extends Node

const DEFAULT_HOST := "127.0.0.1"
const DEFAULT_PORT := 7000
const MAX_PLAYERS := 4
const DEFAULT_PLAYER_NAME := "Captain"
const DEFAULT_RUN_SEED := 424242

func is_server_mode() -> bool:
	if OS.has_feature("dedicated_server"):
		return true
	if DisplayServer.get_name() == "headless":
		return true
	return "--server" in OS.get_cmdline_user_args()

func parse_cmdline_overrides() -> Dictionary:
	var overrides := {
		"host": DEFAULT_HOST,
		"port": DEFAULT_PORT,
		"player_name": DEFAULT_PLAYER_NAME,
		"seed": DEFAULT_RUN_SEED,
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

	return overrides

