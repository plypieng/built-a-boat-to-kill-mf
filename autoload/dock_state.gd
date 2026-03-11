extends Node

signal profile_changed(snapshot: Dictionary)
signal boat_blueprint_changed(snapshot: Dictionary)

const LEGACY_PROFILE_SAVE_PATH := "user://dock_profile.json"
const LOCAL_PROFILE_SAVE_PATH := "user://local_player_profile.json"
const HOST_WORKSHOP_SAVE_PATH := "user://host_workshop_state.json"
const BOAT_BLUEPRINT_SAVE_PATH := "user://shared_boat_blueprint.json"
const SCHEMA_VERSION := 2
const BOAT_BLUEPRINT_GEOMETRY_SCHEMA_VERSION := 2
const MATERIAL_ORDER := [
	"scrap_metal",
	"treated_planks",
	"rigging",
	"machined_parts",
	"boiler_parts",
	"shock_insulation",
]
const DEFAULT_UNLOCKED_BLOCKS := [
	"core",
	"hull",
	"deck_plate",
	"light_crane",
	"ladder_rig",
	"engine",
	"cargo",
	"utility",
	"structure",
]
const DEFAULT_LOCAL_PROFILE := {
	"schema_version": SCHEMA_VERSION,
	"total_gold": 0,
	"total_runs": 0,
	"successful_runs": 0,
	"last_run": {},
	"last_haul": {},
	"stash_items": {},
	"known_schematics": [],
}
const DEFAULT_HOST_WORKSHOP := {
	"schema_version": SCHEMA_VERSION,
	"available_gold": 0,
	"stock_items": {},
	"known_schematics": [],
	"unlocked_blocks": DEFAULT_UNLOCKED_BLOCKS,
	"last_unlock": {},
	"repair_debt": {
		"gold": 0,
		"items": {},
		"severity": "clear",
		"summary": "No repair debt.",
	},
}
const DEFAULT_BOAT_BLUEPRINT := {
	"geometry_schema_version": BOAT_BLUEPRINT_GEOMETRY_SCHEMA_VERSION,
	"version": 1,
	"next_block_id": 2,
	"blocks": [
		{
			"id": 1,
			"type": "core",
			"cell": [0, 0, 0],
			"rotation_steps": 0,
		},
	],
}

var local_profile: Dictionary = {}
var host_workshop_state: Dictionary = {}
var boat_blueprint: Dictionary = {}

func _ready() -> void:
	_load_local_profile()
	_load_host_workshop_state()
	_load_boat_blueprint()

func get_profile_snapshot() -> Dictionary:
	var stash_items := _normalize_material_dict(local_profile.get("stash_items", {}))
	var total_materials := _sum_material_dict(stash_items)
	return {
		"schema_version": SCHEMA_VERSION,
		"local_player_profile": get_local_profile_snapshot(),
		"host_workshop_state": get_host_workshop_snapshot(),
		"host_boat_blueprint": get_boat_blueprint(),
		"total_gold": int(local_profile.get("total_gold", 0)),
		"total_salvage": total_materials,
		"total_runs": int(local_profile.get("total_runs", 0)),
		"successful_runs": int(local_profile.get("successful_runs", 0)),
		"last_run": Dictionary(local_profile.get("last_run", {})).duplicate(true),
		"last_unlock": Dictionary(host_workshop_state.get("last_unlock", {})).duplicate(true),
		"unlocked_blocks": _normalize_unlocked_blocks(host_workshop_state.get("unlocked_blocks", DEFAULT_UNLOCKED_BLOCKS)),
		"local_last_haul": Dictionary(local_profile.get("last_haul", {})).duplicate(true),
		"local_stash_items": stash_items,
		"local_known_schematics": _normalize_schematic_list(local_profile.get("known_schematics", [])),
		"workshop_stock": _normalize_material_dict(host_workshop_state.get("stock_items", {})),
		"workshop_gold": int(host_workshop_state.get("available_gold", 0)),
		"host_known_schematics": _normalize_schematic_list(host_workshop_state.get("known_schematics", [])),
		"repair_debt": _normalize_repair_debt(host_workshop_state.get("repair_debt", {})),
	}

func get_host_progression_snapshot() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"host_workshop_state": get_host_workshop_snapshot(),
		"host_boat_blueprint": get_boat_blueprint(),
		"total_gold": int(host_workshop_state.get("available_gold", 0)),
		"total_salvage": _sum_material_dict(host_workshop_state.get("stock_items", {})),
		"total_runs": int(local_profile.get("total_runs", 0)),
		"successful_runs": int(local_profile.get("successful_runs", 0)),
		"last_run": Dictionary(local_profile.get("last_run", {})).duplicate(true),
		"last_unlock": Dictionary(host_workshop_state.get("last_unlock", {})).duplicate(true),
		"unlocked_blocks": _normalize_unlocked_blocks(host_workshop_state.get("unlocked_blocks", DEFAULT_UNLOCKED_BLOCKS)),
		"workshop_stock": _normalize_material_dict(host_workshop_state.get("stock_items", {})),
		"workshop_gold": int(host_workshop_state.get("available_gold", 0)),
		"host_known_schematics": _normalize_schematic_list(host_workshop_state.get("known_schematics", [])),
		"repair_debt": _normalize_repair_debt(host_workshop_state.get("repair_debt", {})),
	}

func get_local_profile_snapshot() -> Dictionary:
	var snapshot := DEFAULT_LOCAL_PROFILE.duplicate(true)
	snapshot["schema_version"] = SCHEMA_VERSION
	snapshot["total_gold"] = int(local_profile.get("total_gold", 0))
	snapshot["total_runs"] = int(local_profile.get("total_runs", 0))
	snapshot["successful_runs"] = int(local_profile.get("successful_runs", 0))
	snapshot["last_run"] = Dictionary(local_profile.get("last_run", {})).duplicate(true)
	snapshot["last_haul"] = Dictionary(local_profile.get("last_haul", {})).duplicate(true)
	snapshot["stash_items"] = _normalize_material_dict(local_profile.get("stash_items", {}))
	snapshot["known_schematics"] = _normalize_schematic_list(local_profile.get("known_schematics", []))
	return snapshot

func get_host_workshop_snapshot() -> Dictionary:
	var snapshot := DEFAULT_HOST_WORKSHOP.duplicate(true)
	snapshot["schema_version"] = SCHEMA_VERSION
	snapshot["available_gold"] = int(host_workshop_state.get("available_gold", 0))
	snapshot["stock_items"] = _normalize_material_dict(host_workshop_state.get("stock_items", {}))
	snapshot["known_schematics"] = _normalize_schematic_list(host_workshop_state.get("known_schematics", []))
	snapshot["unlocked_blocks"] = _normalize_unlocked_blocks(host_workshop_state.get("unlocked_blocks", DEFAULT_UNLOCKED_BLOCKS))
	snapshot["last_unlock"] = Dictionary(host_workshop_state.get("last_unlock", {})).duplicate(true)
	snapshot["repair_debt"] = _normalize_repair_debt(host_workshop_state.get("repair_debt", {}))
	return snapshot

func get_total_gold() -> int:
	return int(local_profile.get("total_gold", 0))

func get_total_salvage() -> int:
	return _sum_material_dict(local_profile.get("stash_items", {}))

func get_total_runs() -> int:
	return int(local_profile.get("total_runs", 0))

func get_successful_runs() -> int:
	return int(local_profile.get("successful_runs", 0))

func get_last_run() -> Dictionary:
	return Dictionary(local_profile.get("last_run", {})).duplicate(true)

func get_last_unlock() -> Dictionary:
	return Dictionary(host_workshop_state.get("last_unlock", {})).duplicate(true)

func get_unlocked_blocks() -> Array:
	return _normalize_unlocked_blocks(host_workshop_state.get("unlocked_blocks", DEFAULT_UNLOCKED_BLOCKS))

func get_boat_blueprint() -> Dictionary:
	return boat_blueprint.duplicate(true)

func get_local_resource_quantity(resource_id: String) -> int:
	var normalized_id := resource_id.strip_edges().to_lower()
	if normalized_id == "gold":
		return int(local_profile.get("total_gold", 0))
	return int(_normalize_material_dict(local_profile.get("stash_items", {})).get(normalized_id, 0))

func get_workshop_resource_quantity(resource_id: String) -> int:
	var normalized_id := resource_id.strip_edges().to_lower()
	if normalized_id == "gold":
		return int(host_workshop_state.get("available_gold", 0))
	return int(_normalize_material_dict(host_workshop_state.get("stock_items", {})).get(normalized_id, 0))

func remove_local_resource(resource_id: String, quantity: int) -> bool:
	var normalized_id := resource_id.strip_edges().to_lower()
	var amount := maxi(0, quantity)
	if normalized_id.is_empty() or amount <= 0:
		return false
	if normalized_id == "gold":
		var total_gold := int(local_profile.get("total_gold", 0))
		if total_gold < amount:
			return false
		local_profile["total_gold"] = total_gold - amount
		_save_local_profile()
		emit_signal("profile_changed", get_profile_snapshot())
		return true
	var stash_items := _normalize_material_dict(local_profile.get("stash_items", {}))
	if int(stash_items.get(normalized_id, 0)) < amount:
		return false
	stash_items[normalized_id] = int(stash_items.get(normalized_id, 0)) - amount
	local_profile["stash_items"] = stash_items
	_save_local_profile()
	emit_signal("profile_changed", get_profile_snapshot())
	return true

func add_host_workshop_resource(resource_id: String, quantity: int) -> Dictionary:
	var normalized_id := resource_id.strip_edges().to_lower()
	var amount := maxi(0, quantity)
	if normalized_id.is_empty() or amount <= 0:
		return {}
	if normalized_id == "gold":
		host_workshop_state["available_gold"] = int(host_workshop_state.get("available_gold", 0)) + amount
	else:
		var stock_items := _normalize_material_dict(host_workshop_state.get("stock_items", {}))
		stock_items[normalized_id] = int(stock_items.get(normalized_id, 0)) + amount
		host_workshop_state["stock_items"] = stock_items
	_save_host_workshop_state()
	emit_signal("profile_changed", get_profile_snapshot())
	return {
		"resource_id": normalized_id,
		"quantity": amount,
		"workshop_gold": int(host_workshop_state.get("available_gold", 0)),
		"workshop_stock": _normalize_material_dict(host_workshop_state.get("stock_items", {})),
	}

func unlock_workshop_block(block_id: String, recipe: Dictionary, label: String, description: String = "") -> Dictionary:
	var normalized_block_id := block_id.strip_edges().to_lower()
	if normalized_block_id.is_empty():
		return {}
	var unlocked_blocks := _normalize_unlocked_blocks(host_workshop_state.get("unlocked_blocks", DEFAULT_UNLOCKED_BLOCKS))
	if unlocked_blocks.has(normalized_block_id):
		return {}
	var workshop_gold := int(host_workshop_state.get("available_gold", 0))
	var gold_cost := maxi(0, int(recipe.get("gold", 0)))
	if workshop_gold < gold_cost:
		return {}
	var required_schematic := str(recipe.get("required_schematic", ""))
	var known_schematics := _normalize_schematic_list(host_workshop_state.get("known_schematics", []))
	if not required_schematic.is_empty() and not known_schematics.has(required_schematic):
		return {}
	var material_costs := _normalize_material_dict(recipe.get("materials", {}))
	if not _can_afford_material_costs(host_workshop_state.get("stock_items", {}), material_costs):
		return {}
	var stock_items := _normalize_material_dict(host_workshop_state.get("stock_items", {}))
	stock_items = _subtract_material_dict(stock_items, material_costs)
	host_workshop_state["stock_items"] = stock_items
	host_workshop_state["available_gold"] = workshop_gold - gold_cost
	unlocked_blocks.append(normalized_block_id)
	host_workshop_state["unlocked_blocks"] = _normalize_unlocked_blocks(unlocked_blocks)
	host_workshop_state["last_unlock"] = {
		"block_id": normalized_block_id,
		"label": label,
		"description": description,
		"cost_gold": gold_cost,
		"material_costs": material_costs,
		"required_schematic": required_schematic,
		"timestamp": Time.get_datetime_string_from_system(false, true),
	}
	_save_host_workshop_state()
	emit_signal("profile_changed", get_profile_snapshot())
	return Dictionary(host_workshop_state.get("last_unlock", {})).duplicate(true)

func apply_local_run_result(run_seed: int, run_state: Dictionary) -> Dictionary:
	var phase := str(run_state.get("phase", "running"))
	if phase == "running":
		return {}
	var cargo_collected := int(run_state.get("cargo_count", 0))
	var cargo_secured := int(run_state.get("cargo_secured", 0))
	var reward_gold := maxi(0, int(run_state.get("reward_gold", 0)))
	var reward_items := _normalize_material_dict(run_state.get("reward_items", {}))
	var reward_schematics := _normalize_schematic_list(run_state.get("reward_schematics", []))
	var loot_lost_items := _normalize_material_dict(run_state.get("loot_lost_items", {}))
	var repair_debt_delta := _normalize_repair_debt(run_state.get("repair_debt_delta", {}))
	var last_run := {
		"seed": run_seed,
		"phase": phase,
		"title": str(run_state.get("result_title", "Run Complete")),
		"message": str(run_state.get("result_message", "")),
		"cargo_collected": cargo_collected,
		"cargo_secured": cargo_secured,
		"cargo_lost": maxi(0, cargo_collected - cargo_secured),
		"reward_gold": reward_gold,
		"reward_salvage": _sum_material_dict(reward_items),
		"reward_items": reward_items,
		"reward_schematics": reward_schematics,
		"loot_lost_items": loot_lost_items,
		"repair_debt_delta": repair_debt_delta,
		"repair_actions": int(run_state.get("repair_actions", 0)),
		"repair_supplies_left": int(run_state.get("repair_supplies", 0)),
		"cache_recovered": bool(run_state.get("cache_recovered", false)),
		"timestamp": Time.get_datetime_string_from_system(false, true),
	}
	local_profile["total_runs"] = int(local_profile.get("total_runs", 0)) + 1
	if phase == "success":
		local_profile["successful_runs"] = int(local_profile.get("successful_runs", 0)) + 1
	local_profile["total_gold"] = int(local_profile.get("total_gold", 0)) + reward_gold
	if phase == "success":
		local_profile["stash_items"] = _merge_material_dicts(local_profile.get("stash_items", {}), reward_items)
		local_profile["known_schematics"] = _merge_schematic_lists(local_profile.get("known_schematics", []), reward_schematics)
	local_profile["last_run"] = last_run
	local_profile["last_haul"] = {
		"phase": phase,
		"reward_gold": reward_gold,
		"reward_items": reward_items,
		"reward_schematics": reward_schematics,
		"loot_lost_items": loot_lost_items,
		"timestamp": str(last_run.get("timestamp", "")),
	}
	_save_local_profile()
	emit_signal("profile_changed", get_profile_snapshot())
	return last_run.duplicate(true)

func apply_host_run_outcome(_run_seed: int, run_state: Dictionary) -> Dictionary:
	var phase := str(run_state.get("phase", "running"))
	if phase == "running":
		return {}
	var reward_schematics := _normalize_schematic_list(run_state.get("reward_schematics", []))
	if phase == "success" and not reward_schematics.is_empty():
		host_workshop_state["known_schematics"] = _merge_schematic_lists(host_workshop_state.get("known_schematics", []), reward_schematics)
	var repair_debt_delta := _normalize_repair_debt(run_state.get("repair_debt_delta", {}))
	host_workshop_state["repair_debt"] = _merge_repair_debt(host_workshop_state.get("repair_debt", {}), repair_debt_delta)
	_save_host_workshop_state()
	emit_signal("profile_changed", get_profile_snapshot())
	return {
		"reward_schematics": reward_schematics,
		"repair_debt": _normalize_repair_debt(host_workshop_state.get("repair_debt", {})),
	}

func resolve_launch_repair_debt() -> Dictionary:
	var repair_debt := _normalize_repair_debt(host_workshop_state.get("repair_debt", {}))
	var original_total_cost := int(repair_debt.get("gold", 0)) + _sum_material_dict(repair_debt.get("items", {}))
	if original_total_cost <= 0:
		return {
			"remaining_ratio": 0.0,
			"propulsion_health_factor": 1.0,
			"stability_factor": 1.0,
			"patch_kit_penalty": 0,
			"summary": str(repair_debt.get("summary", "No repair debt.")),
			"remaining_debt": repair_debt,
		}
	var workshop_gold := int(host_workshop_state.get("available_gold", 0))
	var paid_gold := mini(workshop_gold, int(repair_debt.get("gold", 0)))
	workshop_gold -= paid_gold
	repair_debt["gold"] = int(repair_debt.get("gold", 0)) - paid_gold
	var stock_items := _normalize_material_dict(host_workshop_state.get("stock_items", {}))
	var debt_items := _normalize_material_dict(repair_debt.get("items", {}))
	for material_id in MATERIAL_ORDER:
		var needed := int(debt_items.get(material_id, 0))
		if needed <= 0:
			continue
		var available := int(stock_items.get(material_id, 0))
		var paid_amount := mini(available, needed)
		if paid_amount <= 0:
			continue
		stock_items[material_id] = available - paid_amount
		debt_items[material_id] = needed - paid_amount
	repair_debt["items"] = debt_items
	repair_debt = _normalize_repair_debt(repair_debt)
	host_workshop_state["available_gold"] = workshop_gold
	host_workshop_state["stock_items"] = stock_items
	host_workshop_state["repair_debt"] = repair_debt
	_save_host_workshop_state()
	emit_signal("profile_changed", get_profile_snapshot())
	var remaining_total_cost := int(repair_debt.get("gold", 0)) + _sum_material_dict(repair_debt.get("items", {}))
	var remaining_ratio := clampf(float(remaining_total_cost) / float(maxi(1, original_total_cost)), 0.0, 1.0)
	return {
		"remaining_ratio": remaining_ratio,
		"propulsion_health_factor": clampf(1.0 - remaining_ratio * 0.35, 0.55, 1.0),
		"stability_factor": clampf(1.0 - remaining_ratio * 0.2, 0.7, 1.0),
		"patch_kit_penalty": clampi(int(ceil(remaining_ratio * 3.0)), 0, 3),
		"summary": str(repair_debt.get("summary", "Repair debt resolved.")),
		"remaining_debt": repair_debt,
	}

func _load_local_profile() -> void:
	local_profile = DEFAULT_LOCAL_PROFILE.duplicate(true)
	if FileAccess.file_exists(LOCAL_PROFILE_SAVE_PATH):
		var parsed := _load_json_dictionary(LOCAL_PROFILE_SAVE_PATH)
		if not parsed.is_empty():
			local_profile = _normalize_local_profile(parsed)
	else:
		var legacy_profile := _load_legacy_profile()
		if not legacy_profile.is_empty():
			local_profile = _migrate_legacy_local_profile(legacy_profile)
			_save_local_profile()
	emit_signal("profile_changed", get_profile_snapshot())

func _load_host_workshop_state() -> void:
	host_workshop_state = DEFAULT_HOST_WORKSHOP.duplicate(true)
	if FileAccess.file_exists(HOST_WORKSHOP_SAVE_PATH):
		var parsed := _load_json_dictionary(HOST_WORKSHOP_SAVE_PATH)
		if not parsed.is_empty():
			host_workshop_state = _normalize_host_workshop(parsed)
	else:
		var legacy_profile := _load_legacy_profile()
		if not legacy_profile.is_empty():
			host_workshop_state = _migrate_legacy_host_workshop(legacy_profile)
			_save_host_workshop_state()

func _save_local_profile() -> void:
	var file := FileAccess.open(LOCAL_PROFILE_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(_normalize_local_profile(local_profile), "\t"))

func _save_host_workshop_state() -> void:
	var file := FileAccess.open(HOST_WORKSHOP_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(_normalize_host_workshop(host_workshop_state), "\t"))

func save_boat_blueprint(snapshot: Dictionary) -> void:
	boat_blueprint = _normalize_boat_blueprint(snapshot)
	_save_boat_blueprint()
	emit_signal("boat_blueprint_changed", get_boat_blueprint())

func reset_boat_blueprint() -> Dictionary:
	var reset_snapshot := DEFAULT_BOAT_BLUEPRINT.duplicate(true)
	save_boat_blueprint(reset_snapshot)
	return get_boat_blueprint()

func _load_boat_blueprint() -> void:
	boat_blueprint = _normalize_boat_blueprint(DEFAULT_BOAT_BLUEPRINT)
	if not FileAccess.file_exists(BOAT_BLUEPRINT_SAVE_PATH):
		emit_signal("boat_blueprint_changed", get_boat_blueprint())
		return
	var parsed := _load_json_dictionary(BOAT_BLUEPRINT_SAVE_PATH)
	if not parsed.is_empty():
		boat_blueprint = _normalize_boat_blueprint(parsed)
		if boat_blueprint != parsed:
			_save_boat_blueprint()
	emit_signal("boat_blueprint_changed", get_boat_blueprint())

func _save_boat_blueprint() -> void:
	var file := FileAccess.open(BOAT_BLUEPRINT_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(boat_blueprint, "\t"))

func _load_json_dictionary(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		return Dictionary(parsed).duplicate(true)
	return {}

func _load_legacy_profile() -> Dictionary:
	if not FileAccess.file_exists(LEGACY_PROFILE_SAVE_PATH):
		return {}
	return _load_json_dictionary(LEGACY_PROFILE_SAVE_PATH)

func _migrate_legacy_local_profile(legacy_profile: Dictionary) -> Dictionary:
	var migrated := DEFAULT_LOCAL_PROFILE.duplicate(true)
	var legacy_salvage := maxi(0, int(legacy_profile.get("total_salvage", 0)))
	migrated["total_gold"] = maxi(0, int(legacy_profile.get("total_gold", 0)))
	migrated["total_runs"] = maxi(0, int(legacy_profile.get("total_runs", 0)))
	migrated["successful_runs"] = maxi(0, int(legacy_profile.get("successful_runs", 0)))
	migrated["last_run"] = Dictionary(legacy_profile.get("last_run", {})).duplicate(true)
	migrated["stash_items"] = {
		"scrap_metal": legacy_salvage * 2,
		"treated_planks": maxi(0, int(legacy_salvage / 2)),
		"rigging": maxi(0, int(legacy_salvage / 3)),
		"machined_parts": legacy_salvage,
		"boiler_parts": maxi(0, int(legacy_salvage / 5)),
		"shock_insulation": maxi(0, int(legacy_salvage / 6)),
	}
	migrated["known_schematics"] = _normalize_unlocked_blocks(legacy_profile.get("unlocked_blocks", DEFAULT_UNLOCKED_BLOCKS))
	migrated["last_haul"] = {
		"phase": "migration",
		"reward_gold": 0,
		"reward_items": _normalize_material_dict(migrated.get("stash_items", {})),
		"reward_schematics": _normalize_schematic_list(migrated.get("known_schematics", [])),
		"loot_lost_items": {},
		"timestamp": Time.get_datetime_string_from_system(false, true),
	}
	return _normalize_local_profile(migrated)

func _migrate_legacy_host_workshop(legacy_profile: Dictionary) -> Dictionary:
	var migrated := DEFAULT_HOST_WORKSHOP.duplicate(true)
	migrated["available_gold"] = 0
	migrated["stock_items"] = _normalize_material_dict({})
	migrated["known_schematics"] = _normalize_unlocked_blocks(legacy_profile.get("unlocked_blocks", DEFAULT_UNLOCKED_BLOCKS))
	migrated["unlocked_blocks"] = _normalize_unlocked_blocks(legacy_profile.get("unlocked_blocks", DEFAULT_UNLOCKED_BLOCKS))
	migrated["last_unlock"] = Dictionary(legacy_profile.get("last_unlock", {})).duplicate(true)
	return _normalize_host_workshop(migrated)

func _normalize_local_profile(snapshot: Dictionary) -> Dictionary:
	var normalized := DEFAULT_LOCAL_PROFILE.duplicate(true)
	normalized["schema_version"] = SCHEMA_VERSION
	normalized["total_gold"] = maxi(0, int(snapshot.get("total_gold", 0)))
	normalized["total_runs"] = maxi(0, int(snapshot.get("total_runs", 0)))
	normalized["successful_runs"] = maxi(0, int(snapshot.get("successful_runs", 0)))
	normalized["last_run"] = Dictionary(snapshot.get("last_run", {})).duplicate(true)
	normalized["last_haul"] = Dictionary(snapshot.get("last_haul", {})).duplicate(true)
	normalized["stash_items"] = _normalize_material_dict(snapshot.get("stash_items", {}))
	normalized["known_schematics"] = _normalize_schematic_list(snapshot.get("known_schematics", []))
	return normalized

func _normalize_host_workshop(snapshot: Dictionary) -> Dictionary:
	var normalized := DEFAULT_HOST_WORKSHOP.duplicate(true)
	normalized["schema_version"] = SCHEMA_VERSION
	normalized["available_gold"] = maxi(0, int(snapshot.get("available_gold", 0)))
	normalized["stock_items"] = _normalize_material_dict(snapshot.get("stock_items", {}))
	normalized["known_schematics"] = _normalize_schematic_list(snapshot.get("known_schematics", []))
	normalized["unlocked_blocks"] = _normalize_unlocked_blocks(snapshot.get("unlocked_blocks", DEFAULT_UNLOCKED_BLOCKS))
	normalized["last_unlock"] = Dictionary(snapshot.get("last_unlock", {})).duplicate(true)
	normalized["repair_debt"] = _normalize_repair_debt(snapshot.get("repair_debt", {}))
	return normalized

func _normalize_material_dict(source: Variant) -> Dictionary:
	var normalized := {}
	for material_id_variant in MATERIAL_ORDER:
		normalized[str(material_id_variant)] = 0
	if typeof(source) != TYPE_DICTIONARY:
		return normalized
	for key_variant in Dictionary(source).keys():
		var material_id := str(key_variant).strip_edges().to_lower()
		if material_id.is_empty():
			continue
		normalized[material_id] = maxi(0, int(Dictionary(source).get(key_variant, 0)))
	return normalized

func _normalize_schematic_list(values: Variant) -> Array:
	var schematics: Array = []
	var seen := {}
	if typeof(values) != TYPE_ARRAY:
		return schematics
	for value in values:
		var schematic_id := str(value).strip_edges().to_lower()
		if schematic_id.is_empty() or seen.has(schematic_id):
			continue
		seen[schematic_id] = true
		schematics.append(schematic_id)
	schematics.sort()
	return schematics

func _normalize_repair_debt(source: Variant) -> Dictionary:
	var gold_cost := 0
	var item_costs := {}
	var severity := "clear"
	if typeof(source) == TYPE_DICTIONARY:
		var source_dict := Dictionary(source)
		gold_cost = maxi(0, int(source_dict.get("gold", 0)))
		item_costs = _normalize_material_dict(source_dict.get("items", {}))
		severity = str(source_dict.get("severity", "clear"))
	else:
		item_costs = _normalize_material_dict({})
	var total_cost := gold_cost + _sum_material_dict(item_costs)
	if total_cost <= 0:
		return {
			"gold": 0,
			"items": _normalize_material_dict({}),
			"severity": "clear",
			"summary": "No repair debt.",
		}
	if severity == "clear":
		severity = "light" if total_cost <= 8 else ("moderate" if total_cost <= 20 else "heavy")
	return {
		"gold": gold_cost,
		"items": item_costs,
		"severity": severity,
		"summary": "%s debt: %d gold plus %d material unit(s)." % [
			severity.capitalize(),
			gold_cost,
			_sum_material_dict(item_costs),
		],
	}

func _merge_material_dicts(base_values: Variant, added_values: Variant) -> Dictionary:
	var merged := _normalize_material_dict(base_values)
	var added := _normalize_material_dict(added_values)
	for material_id_variant in added.keys():
		var material_id := str(material_id_variant)
		merged[material_id] = int(merged.get(material_id, 0)) + int(added.get(material_id, 0))
	return merged

func _subtract_material_dict(base_values: Variant, removed_values: Variant) -> Dictionary:
	var remaining := _normalize_material_dict(base_values)
	var removed := _normalize_material_dict(removed_values)
	for material_id_variant in removed.keys():
		var material_id := str(material_id_variant)
		remaining[material_id] = maxi(0, int(remaining.get(material_id, 0)) - int(removed.get(material_id, 0)))
	return remaining

func _sum_material_dict(values: Variant) -> int:
	var total := 0
	for amount_variant in _normalize_material_dict(values).values():
		total += int(amount_variant)
	return total

func _merge_schematic_lists(base_values: Variant, added_values: Variant) -> Array:
	var merged_lookup := {}
	var merged: Array = []
	for value in _normalize_schematic_list(base_values):
		var schematic_id := str(value)
		merged_lookup[schematic_id] = true
		merged.append(schematic_id)
	for value in _normalize_schematic_list(added_values):
		var schematic_id := str(value)
		if merged_lookup.has(schematic_id):
			continue
		merged_lookup[schematic_id] = true
		merged.append(schematic_id)
	merged.sort()
	return merged

func _merge_repair_debt(base_values: Variant, added_values: Variant) -> Dictionary:
	var merged := _normalize_repair_debt(base_values)
	var added := _normalize_repair_debt(added_values)
	merged["gold"] = int(merged.get("gold", 0)) + int(added.get("gold", 0))
	merged["items"] = _merge_material_dicts(merged.get("items", {}), added.get("items", {}))
	return _normalize_repair_debt(merged)

func _can_afford_material_costs(stock_values: Variant, cost_values: Variant) -> bool:
	var stock := _normalize_material_dict(stock_values)
	var costs := _normalize_material_dict(cost_values)
	for material_id_variant in costs.keys():
		var material_id := str(material_id_variant)
		if int(stock.get(material_id, 0)) < int(costs.get(material_id, 0)):
			return false
	return true

func _normalize_boat_blueprint(snapshot: Dictionary) -> Dictionary:
	var normalized := DEFAULT_BOAT_BLUEPRINT.duplicate(true)
	var geometry_schema_version := int(snapshot.get("geometry_schema_version", 1))
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
		geometry_schema_version = BOAT_BLUEPRINT_GEOMETRY_SCHEMA_VERSION
	normalized["geometry_schema_version"] = maxi(BOAT_BLUEPRINT_GEOMETRY_SCHEMA_VERSION, geometry_schema_version)
	normalized["version"] = maxi(1, version)
	normalized["next_block_id"] = maxi(1, next_block_id)
	normalized["blocks"] = normalized_blocks
	return normalized

func _normalize_cell(cell_value: Variant) -> Array:
	if cell_value is Vector3i:
		var cell_vec := cell_value as Vector3i
		return [cell_vec.x, cell_vec.y, cell_vec.z]
	if typeof(cell_value) == TYPE_ARRAY and cell_value.size() >= 3:
		return [int(cell_value[0]), int(cell_value[1]), int(cell_value[2])]
	if typeof(cell_value) == TYPE_DICTIONARY:
		return [
			int(cell_value.get("x", 0)),
			int(cell_value.get("y", 0)),
			int(cell_value.get("z", 0)),
		]
	return [0, 0, 0]

func _cell_to_key(cell: Array) -> String:
	return "%d:%d:%d" % [int(cell[0]), int(cell[1]), int(cell[2])]

func _normalize_unlocked_blocks(block_values: Variant) -> Array:
	var ordered_blocks: Array = []
	var seen_blocks := {}
	for base_block in DEFAULT_UNLOCKED_BLOCKS:
		var base_block_id := str(base_block).strip_edges().to_lower()
		if base_block_id.is_empty() or seen_blocks.has(base_block_id):
			continue
		ordered_blocks.append(base_block_id)
		seen_blocks[base_block_id] = true
	if typeof(block_values) != TYPE_ARRAY:
		return ordered_blocks
	for block_value in block_values:
		var block_id := str(block_value).strip_edges().to_lower()
		if block_id.is_empty() or seen_blocks.has(block_id):
			continue
		ordered_blocks.append(block_id)
		seen_blocks[block_id] = true
	return ordered_blocks
