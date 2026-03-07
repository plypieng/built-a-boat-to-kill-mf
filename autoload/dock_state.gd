extends Node

signal profile_changed(snapshot: Dictionary)
signal boat_blueprint_changed(snapshot: Dictionary)

const PROFILE_SAVE_PATH := "user://dock_profile.json"
const BOAT_BLUEPRINT_SAVE_PATH := "user://shared_boat_blueprint.json"
const DEFAULT_PROFILE := {
	"total_gold": 0,
	"total_salvage": 0,
	"total_runs": 0,
	"successful_runs": 0,
	"last_run": {},
}
const DEFAULT_BOAT_BLUEPRINT := {
	"version": 1,
	"next_block_id": 6,
	"blocks": [
		{
			"id": 1,
			"type": "core",
			"cell": [0, 0, 0],
			"rotation_steps": 0,
		},
		{
			"id": 2,
			"type": "hull",
			"cell": [0, 0, 1],
			"rotation_steps": 0,
		},
		{
			"id": 3,
			"type": "hull",
			"cell": [1, 0, 0],
			"rotation_steps": 0,
		},
		{
			"id": 4,
			"type": "engine",
			"cell": [0, 0, -1],
			"rotation_steps": 0,
		},
		{
			"id": 5,
			"type": "cargo",
			"cell": [-1, 0, 0],
			"rotation_steps": 0,
		},
	],
}

var profile: Dictionary = {}
var boat_blueprint: Dictionary = {}

func _ready() -> void:
	_load_profile()
	_load_boat_blueprint()

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

func get_boat_blueprint() -> Dictionary:
	return boat_blueprint.duplicate(true)

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
	if not FileAccess.file_exists(PROFILE_SAVE_PATH):
		emit_signal("profile_changed", get_profile_snapshot())
		return

	var file := FileAccess.open(PROFILE_SAVE_PATH, FileAccess.READ)
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
	var file := FileAccess.open(PROFILE_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return

	file.store_string(JSON.stringify(profile, "\t"))

func save_boat_blueprint(snapshot: Dictionary) -> void:
	boat_blueprint = _normalize_boat_blueprint(snapshot)
	_save_boat_blueprint()
	emit_signal("boat_blueprint_changed", get_boat_blueprint())

func _load_boat_blueprint() -> void:
	boat_blueprint = _normalize_boat_blueprint(DEFAULT_BOAT_BLUEPRINT)
	if not FileAccess.file_exists(BOAT_BLUEPRINT_SAVE_PATH):
		emit_signal("boat_blueprint_changed", get_boat_blueprint())
		return

	var file := FileAccess.open(BOAT_BLUEPRINT_SAVE_PATH, FileAccess.READ)
	if file == null:
		emit_signal("boat_blueprint_changed", get_boat_blueprint())
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		boat_blueprint = _normalize_boat_blueprint(parsed)

	emit_signal("boat_blueprint_changed", get_boat_blueprint())

func _save_boat_blueprint() -> void:
	var file := FileAccess.open(BOAT_BLUEPRINT_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return

	file.store_string(JSON.stringify(boat_blueprint, "\t"))

func _normalize_boat_blueprint(snapshot: Dictionary) -> Dictionary:
	var normalized := DEFAULT_BOAT_BLUEPRINT.duplicate(true)
	var version := int(snapshot.get("version", normalized.get("version", 1)))
	var next_block_id := int(snapshot.get("next_block_id", normalized.get("next_block_id", 1)))
	var normalized_blocks: Array = []
	var seen_cells := {}
	var seen_ids := {}

	for entry in Array(snapshot.get("blocks", [])):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var block_id := int(entry.get("id", 0))
		if block_id <= 0 or seen_ids.has(block_id):
			continue
		var cell := _normalize_cell(entry.get("cell", [0, 0, 0]))
		var cell_key := _cell_to_key(cell)
		if seen_cells.has(cell_key):
			continue

		var block_type := str(entry.get("type", "structure")).strip_edges().to_lower()
		var rotation_steps := wrapi(int(entry.get("rotation_steps", 0)), 0, 4)
		normalized_blocks.append({
			"id": block_id,
			"type": block_type,
			"cell": cell,
			"rotation_steps": rotation_steps,
		})
		seen_ids[block_id] = true
		seen_cells[cell_key] = true
		next_block_id = maxi(next_block_id, block_id + 1)

	if normalized_blocks.is_empty():
		normalized_blocks = Array(DEFAULT_BOAT_BLUEPRINT.get("blocks", [])).duplicate(true)
		next_block_id = int(DEFAULT_BOAT_BLUEPRINT.get("next_block_id", 1))
		version = maxi(version, 1)

	normalized["version"] = maxi(1, version)
	normalized["next_block_id"] = maxi(1, next_block_id)
	normalized["blocks"] = normalized_blocks
	return normalized

func _normalize_cell(cell_value: Variant) -> Array:
	if cell_value is Vector3i:
		var cell_vec := cell_value as Vector3i
		return [cell_vec.x, cell_vec.y, cell_vec.z]
	if typeof(cell_value) == TYPE_ARRAY and cell_value.size() >= 3:
		return [
			int(cell_value[0]),
			int(cell_value[1]),
			int(cell_value[2]),
		]
	if typeof(cell_value) == TYPE_DICTIONARY:
		return [
			int(cell_value.get("x", 0)),
			int(cell_value.get("y", 0)),
			int(cell_value.get("z", 0)),
		]
	return [0, 0, 0]

func _cell_to_key(cell: Array) -> String:
	return "%d:%d:%d" % [int(cell[0]), int(cell[1]), int(cell[2])]
