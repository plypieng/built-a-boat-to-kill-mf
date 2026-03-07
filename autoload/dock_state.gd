extends Node

signal profile_changed(snapshot: Dictionary)

const SAVE_PATH := "user://dock_profile.json"
const DEFAULT_PROFILE := {
	"total_gold": 0,
	"total_salvage": 0,
	"total_runs": 0,
	"successful_runs": 0,
	"last_run": {},
}

var profile: Dictionary = {}

func _ready() -> void:
	_load_profile()

func get_profile_snapshot() -> Dictionary:
	return profile.duplicate(true)

func get_total_gold() -> int:
	return int(profile.get("total_gold", 0))

func get_total_salvage() -> int:
	return int(profile.get("total_salvage", 0))

func get_total_runs() -> int:
	return int(profile.get("total_runs", 0))

func get_successful_runs() -> int:
	return int(profile.get("successful_runs", 0))

func get_last_run() -> Dictionary:
	return Dictionary(profile.get("last_run", {})).duplicate(true)

func record_run_result(run_seed: int, run_state: Dictionary) -> Dictionary:
	var phase := str(run_state.get("phase", "running"))
	if phase == "running":
		return {}

	var cargo_collected := int(run_state.get("cargo_count", 0))
	var cargo_secured := int(run_state.get("cargo_secured", 0))
	var last_run := {
		"seed": run_seed,
		"phase": phase,
		"title": str(run_state.get("result_title", "Run Complete")),
		"message": str(run_state.get("result_message", "")),
		"cargo_collected": cargo_collected,
		"cargo_secured": cargo_secured,
		"cargo_lost": maxi(0, cargo_collected - cargo_secured),
		"reward_gold": int(run_state.get("reward_gold", 0)),
		"reward_salvage": int(run_state.get("reward_salvage", 0)),
		"repair_actions": int(run_state.get("repair_actions", 0)),
		"repair_supplies_left": int(run_state.get("repair_supplies", 0)),
		"cache_recovered": bool(run_state.get("cache_recovered", false)),
		"timestamp": Time.get_datetime_string_from_system(false, true),
	}

	profile["total_runs"] = int(profile.get("total_runs", 0)) + 1
	if phase == "success":
		profile["successful_runs"] = int(profile.get("successful_runs", 0)) + 1
	profile["total_gold"] = int(profile.get("total_gold", 0)) + int(last_run.get("reward_gold", 0))
	profile["total_salvage"] = int(profile.get("total_salvage", 0)) + int(last_run.get("reward_salvage", 0))
	profile["last_run"] = last_run
	_save_profile()
	emit_signal("profile_changed", get_profile_snapshot())
	return last_run.duplicate(true)

func _load_profile() -> void:
	profile = DEFAULT_PROFILE.duplicate(true)
	if not FileAccess.file_exists(SAVE_PATH):
		emit_signal("profile_changed", get_profile_snapshot())
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		emit_signal("profile_changed", get_profile_snapshot())
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		for key in DEFAULT_PROFILE.keys():
			if parsed.has(key):
				profile[key] = parsed[key]

	if typeof(profile.get("last_run", {})) != TYPE_DICTIONARY:
		profile["last_run"] = {}

	emit_signal("profile_changed", get_profile_snapshot())

func _save_profile() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return

	file.store_string(JSON.stringify(profile, "\t"))
