extends Node

signal mode_changed(mode_name: String)
signal status_changed(message: String)
signal connection_ready()
signal client_connect_failed()
signal client_disconnected()
signal session_phase_changed(phase: String)
signal boat_blueprint_changed(snapshot: Dictionary)
signal peer_snapshot_changed(snapshot: Dictionary)
signal hangar_avatar_state_changed(snapshot: Dictionary)
signal run_avatar_state_changed(snapshot: Dictionary)
signal reaction_state_changed(snapshot: Dictionary)
signal run_seed_changed(seed: int)
signal helm_changed(driver_peer_id: int)
signal boat_state_changed(state: Dictionary)
signal hazard_state_changed(hazards: Array)
signal station_state_changed(stations: Dictionary)
signal loot_state_changed(loot_targets: Array)
signal run_state_changed(state: Dictionary)
signal progression_state_changed(snapshot: Dictionary)

enum Mode {
	OFFLINE,
	CLIENT,
	SERVER,
}

const SESSION_PHASE_HANGAR := "hangar"
const SESSION_PHASE_RUN := "run"
const STATION_ORDER := ["helm", "brace", "grapple", "repair"]
const STATION_CLAIMABLE_ORDER := ["helm", "grapple"]
const STATION_LAYOUT := {
	"helm": {
		"label": "Helm",
		"position": Vector3(0.0, 0.92, -1.4),
	},
	"brace": {
		"label": "Brace Station",
		"position": Vector3(-0.95, 0.92, 0.1),
	},
	"grapple": {
		"label": "Grapple Crane",
		"position": Vector3(0.95, 0.92, 0.45),
	},
	"repair": {
		"label": "Repair Bench",
		"position": Vector3(-0.95, 0.92, 1.05),
	},
}
const HANGAR_TOOLBELT := [
	{
		"id": "build",
		"label": "Build",
		"icon": "reinforced-hull",
		"hint": "Place the selected part into the aimed cell.",
	},
	{
		"id": "remove",
		"label": "Remove",
		"icon": "salvage",
		"hint": "Scrap the targeted block from the shared blueprint.",
	},
	{
		"id": "yard",
		"label": "Yard",
		"icon": "gold",
		"hint": "Review shared stock and buy unlocks for the whole crew.",
	},
]
const RUN_TOOLBELT := [
	{
		"id": "helm",
		"label": "Helm",
		"icon": "helm",
		"hint": "Claim the wheel when you are inside the helm zone.",
	},
	{
		"id": "brace",
		"label": "Brace",
		"icon": "brace",
		"hint": "Brace anywhere on deck to resist impacts and surges.",
	},
	{
		"id": "grapple",
		"label": "Grapple",
		"icon": "salvage",
		"hint": "Work the crane to recover salvage, rescue lines, and cache pulls.",
	},
	{
		"id": "repair",
		"label": "Repair",
		"icon": "repair-kit",
		"hint": "Patch nearby damaged hull sections using shared kits.",
	},
	{
		"id": "recover",
		"label": "Recover",
		"icon": "extraction",
		"hint": "Climb back aboard from a ladder or stern line when overboard.",
	},
]
const BUILDER_CELL_SIZE := 1.25
const BUILDER_WORLD_ORIGIN := Vector3(0.0, 0.1, 0.0)
const BUILDER_BOUNDS_MIN := Vector3i(-5, 0, -6)
const BUILDER_BOUNDS_MAX := Vector3i(5, 4, 6)
const HANGAR_BUILD_RANGE := 5.25
const HANGAR_SPAWN_POINTS := [
	Vector3(-3.6, 0.55, 6.8),
	Vector3(-1.2, 0.55, 6.4),
	Vector3(1.2, 0.55, 6.4),
	Vector3(3.6, 0.55, 6.8),
]
const RUN_DECK_SPAWN_POINTS := [
	Vector3(0.0, 0.92, 1.35),
	Vector3(-1.0, 0.92, 1.05),
	Vector3(1.0, 0.92, 1.05),
	Vector3(0.0, 0.92, 2.0),
]
const RUN_DECK_BOUNDS_MIN := Vector3(-1.18, 0.72, -1.92)
const RUN_DECK_BOUNDS_MAX := Vector3(1.18, 1.28, 2.08)
const RUN_HELM_ZONE_RADIUS := 1.15
const RUN_HELM_RELEASE_RADIUS := 1.55
const RUN_GRAPPLE_ZONE_RADIUS := 0.92
const RUN_GRAPPLE_RELEASE_RADIUS := 1.18
const RUN_REPAIR_RANGE := 1.32
const RUN_REPAIR_HEAL_RADIUS := 1.2
const BUILDER_BLOCK_ORDER := [
	"core",
	"hull",
	"reinforced_hull",
	"engine",
	"twin_engine",
	"cargo",
	"utility",
	"stabilizer",
	"structure",
]
const BUILDER_BLOCK_LIBRARY := {
	"core": {
		"label": "Core",
		"description": "The shared heart of the boat. Losing the main core chunk is a bad day.",
		"unlockable": false,
		"unlock_cost_gold": 0,
		"unlock_cost_salvage": 0,
		"color": Color(0.84, 0.30, 0.24),
		"size": Vector3(1.05, 1.05, 1.05),
		"max_hp": 34.0,
		"weight": 3.0,
		"buoyancy": 5.5,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 0,
		"brace": 0.08,
		"hull": 1.0,
	},
	"hull": {
		"label": "Hull",
		"description": "Basic float support for everyday builds.",
		"unlockable": false,
		"unlock_cost_gold": 0,
		"unlock_cost_salvage": 0,
		"color": Color(0.54, 0.35, 0.20),
		"size": Vector3(1.2, 0.8, 1.2),
		"max_hp": 24.0,
		"weight": 2.1,
		"buoyancy": 5.2,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 0,
		"brace": 0.03,
		"hull": 1.0,
	},
	"reinforced_hull": {
		"label": "Reinforced Hull",
		"description": "Heavier plating for crews that want more hull and buoyancy margin.",
		"unlockable": true,
		"unlock_cost_gold": 55,
		"unlock_cost_salvage": 1,
		"color": Color(0.42, 0.30, 0.18),
		"size": Vector3(1.28, 0.9, 1.28),
		"max_hp": 34.0,
		"weight": 3.1,
		"buoyancy": 6.6,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 0,
		"brace": 0.05,
		"hull": 1.55,
	},
	"engine": {
		"label": "Engine",
		"description": "Reliable starter thrust for the main hull.",
		"unlockable": false,
		"unlock_cost_gold": 0,
		"unlock_cost_salvage": 0,
		"color": Color(0.27, 0.34, 0.38),
		"size": Vector3(1.0, 0.9, 1.2),
		"max_hp": 18.0,
		"weight": 2.5,
		"buoyancy": 1.8,
		"thrust": 1.0,
		"cargo": 0,
		"repair": 0,
		"brace": 0.0,
		"hull": 0.35,
	},
	"twin_engine": {
		"label": "Twin Engine",
		"description": "A louder, faster drive block that trades sturdiness for speed.",
		"unlockable": true,
		"unlock_cost_gold": 70,
		"unlock_cost_salvage": 3,
		"color": Color(0.20, 0.25, 0.29),
		"size": Vector3(1.18, 0.96, 1.26),
		"max_hp": 16.0,
		"weight": 3.3,
		"buoyancy": 1.6,
		"thrust": 1.75,
		"cargo": 0,
		"repair": 0,
		"brace": -0.02,
		"hull": 0.3,
	},
	"cargo": {
		"label": "Cargo",
		"description": "Adds space for salvage at the cost of extra weight.",
		"unlockable": false,
		"unlock_cost_gold": 0,
		"unlock_cost_salvage": 0,
		"color": Color(0.82, 0.62, 0.22),
		"size": Vector3(1.0, 1.0, 1.0),
		"max_hp": 16.0,
		"weight": 1.8,
		"buoyancy": 1.6,
		"thrust": 0.0,
		"cargo": 2,
		"repair": 0,
		"brace": 0.0,
		"hull": 0.3,
	},
	"utility": {
		"label": "Utility",
		"description": "General-purpose support gear for patch kits and brace help.",
		"unlockable": false,
		"unlock_cost_gold": 0,
		"unlock_cost_salvage": 0,
		"color": Color(0.24, 0.62, 0.50),
		"size": Vector3(1.0, 1.0, 1.0),
		"max_hp": 20.0,
		"weight": 1.6,
		"buoyancy": 1.9,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 1,
		"brace": 0.18,
		"hull": 0.5,
	},
	"stabilizer": {
		"label": "Stabilizer",
		"description": "Support rigging that improves brace strength and repair capacity.",
		"unlockable": true,
		"unlock_cost_gold": 62,
		"unlock_cost_salvage": 2,
		"color": Color(0.19, 0.52, 0.63),
		"size": Vector3(1.0, 1.12, 1.0),
		"max_hp": 24.0,
		"weight": 1.9,
		"buoyancy": 2.1,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 2,
		"brace": 0.34,
		"hull": 0.62,
	},
	"structure": {
		"label": "Structure",
		"description": "Cheap scaffold material for shape, walkways, and goofy ideas.",
		"unlockable": false,
		"unlock_cost_gold": 0,
		"unlock_cost_salvage": 0,
		"color": Color(0.68, 0.74, 0.78),
		"size": Vector3(1.0, 1.0, 1.0),
		"max_hp": 14.0,
		"weight": 1.2,
		"buoyancy": 1.1,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 0,
		"brace": 0.06,
		"hull": 0.5,
	},
}
const RUNTIME_BLOCK_SPACING := 0.95
const RUNTIME_DAMAGE_CLUSTER_RADIUS := 1.9
const RUNTIME_DAMAGE_CLUSTER_WEIGHTS := [1.0, 0.6, 0.45, 0.3, 0.2]
const RUNTIME_SINK_SPEED := 0.95
const RUNTIME_SINK_DRIFT_SPEED := 0.42
const RUNTIME_SINK_LIFETIME := 8.0
const REACTION_BUMP_SPEED_THRESHOLD := 5.4
const REACTION_BUMP_COLLISION_RADIUS := 0.92
const REACTION_BUMP_PAIR_COOLDOWN := 0.68
const REACTION_BUMP_ACTIVE_SECONDS := 0.15
const REACTION_BUMP_RECOVERY_SECONDS := 0.34
const REACTION_BUMP_KNOCKBACK := 4.4
const REACTION_IMPACT_ACTIVE_SECONDS := 0.24
const REACTION_IMPACT_RECOVERY_SECONDS := 0.46
const REACTION_IMPACT_KNOCKBACK := 5.8
const REACTION_HOOK_ACTIVE_SECONDS := 0.42
const REACTION_HOOK_RECOVERY_SECONDS := 0.38
const RUN_AVATAR_MODE_DECK := "deck"
const RUN_AVATAR_MODE_OVERBOARD := "overboard"
const RUN_OVERBOARD_WATER_HEIGHT := 0.18
const RUN_OVERBOARD_SWIM_RADIUS := 8.8
const RUN_OVERBOARD_RECOVERY_RANGE := 1.15
const RUN_OVERBOARD_EDGE_MARGIN := 0.24
const RUN_OVERBOARD_MIN_STRENGTH := 0.54
const RUN_RECOVERY_POINTS := [
	{
		"id": "port_ladder",
		"label": "Port Ladder",
		"water_position": Vector3(-1.74, RUN_OVERBOARD_WATER_HEIGHT, 0.62),
		"deck_position": Vector3(-1.02, 0.92, 0.74),
	},
	{
		"id": "starboard_ladder",
		"label": "Starboard Ladder",
		"water_position": Vector3(1.74, RUN_OVERBOARD_WATER_HEIGHT, 0.62),
		"deck_position": Vector3(1.02, 0.92, 0.74),
	},
	{
		"id": "stern_line",
		"label": "Stern Line",
		"water_position": Vector3(0.0, RUN_OVERBOARD_WATER_HEIGHT, 2.62),
		"deck_position": Vector3(0.0, 0.92, 1.96),
	},
]
const DISCONNECT_BROADCAST_DELAY_SECONDS := 0.12

const BOAT_ACCELERATION := 8.0
const BOAT_DECELERATION := 10.0
const BOAT_TOP_SPEED := 14.0
const BOAT_TURN_SPEED := 1.9
const BOAT_BROADCAST_INTERVAL := 0.05
const BOAT_COLLISION_RADIUS := 1.8
const BOAT_MAX_INTEGRITY := 100.0
const BRACE_ACTIVE_SECONDS := 0.9
const BRACE_COOLDOWN_SECONDS := 2.25
const COLLISION_DAMAGE_UNBRACED := 18.0
const COLLISION_DAMAGE_BRACED := 7.0
const GRAPPLE_RANGE := 7.8
const SALVAGE_MAX_SPEED := 1.55
const SALVAGE_BACKLASH_DAMAGE := 6.0
const SALVAGE_BACKLASH_BREACHES := 1
const RESCUE_MAX_SPEED := 1.25
const RESCUE_DURATION := 1.85
const RESCUE_PATCH_KIT_GRANT := 1
const RESCUE_GOLD_BONUS_MIN := 22
const RESCUE_GOLD_BONUS_MAX := 34
const RESCUE_SALVAGE_BONUS_MIN := 1
const RESCUE_SALVAGE_BONUS_MAX := 2
const BREACH_SPEED_PENALTY := 0.16
const MAX_BREACH_STACKS := 4
const HULL_LEAK_DAMAGE_PER_BREACH := 0.55
const REPAIR_COOLDOWN_SECONDS := 1.35
const REPAIR_HULL_RECOVERY := 12.0
const REPAIR_SUPPLIES_START := 3
const REPAIR_SUPPLIES_MAX := 4
const EXTRACTION_DURATION := 1.6
const EXTRACTION_RADIUS := 3.7
const EXTRACTION_MAX_SPEED := 2.25
const RESUPPLY_CACHE_RADIUS := 4.4
const RESUPPLY_CACHE_MAX_SPEED := 8.0
const RESUPPLY_CACHE_SUPPLY_GRANT := 1
const RESUPPLY_CACHE_GOLD_BONUS := 18
const RESUPPLY_CACHE_SALVAGE_BONUS := 1
const SQUALL_PULSE_DAMAGE_MIN := 3.4
const SQUALL_PULSE_DAMAGE_MAX := 5.6
const SQUALL_DRAG_MIN := 0.6
const SQUALL_DRAG_MAX := 0.82
const SQUALL_PULSE_INTERVAL_MIN := 2.1
const SQUALL_PULSE_INTERVAL_MAX := 2.9
const REWARD_GOLD_PER_CARGO := 35
const REWARD_SALVAGE_PER_CARGO := 2

var mode: int = Mode.OFFLINE
var current_host: String = GameConfig.DEFAULT_HOST
var current_port: int = GameConfig.DEFAULT_PORT
var local_player_name: String = GameConfig.DEFAULT_PLAYER_NAME
var run_seed: int = GameConfig.DEFAULT_RUN_SEED
var session_phase := SESSION_PHASE_HANGAR
var boat_blueprint: Dictionary = {}
var peer_snapshot: Dictionary = {}
var hangar_avatar_state: Dictionary = {}
var run_avatar_state: Dictionary = {}
var reaction_state: Dictionary = {}
var status_message := "Offline"
var driver_peer_id := 0
var boat_state: Dictionary = {}
var hazard_state: Array = []
var station_state: Dictionary = {}
var loot_state: Array = []
var run_state: Dictionary = {}
var progression_state: Dictionary = {}

var _peer_inputs: Dictionary = {}
var _boat_broadcast_accumulator := 0.0
var _next_hazard_id: int = 1
var _next_loot_id: int = 1
var _next_runtime_chunk_id: int = 1
var _next_reaction_id: int = 1
var _hangar_bump_pair_cooldowns: Dictionary = {}
var _disconnect_broadcast_scheduled := false
var _client_bootstrap_complete := false

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func start_server(listen_port: int = GameConfig.DEFAULT_PORT, seed: int = GameConfig.DEFAULT_RUN_SEED) -> int:
	shutdown()

	var peer := ENetMultiplayerPeer.new()
	var error: int = peer.create_server(listen_port, GameConfig.MAX_PLAYERS)
	if error != OK:
		_set_status("Server failed to start (code %s)." % str(error))
		return error

	multiplayer.multiplayer_peer = peer
	mode = Mode.SERVER
	current_host = "0.0.0.0"
	current_port = listen_port
	run_seed = seed
	session_phase = SESSION_PHASE_HANGAR
	_client_bootstrap_complete = false
	peer_snapshot = {
		1: {
			"name": "Dedicated Server",
			"status": "hosting",
		},
	}
	_reset_progression_runtime()
	_reset_hangar_avatar_state()
	_reset_run_avatar_state()
	_reset_reaction_runtime()
	_reset_blueprint_runtime()
	_reset_run_runtime()

	emit_signal("mode_changed", _mode_name())
	emit_signal("run_seed_changed", run_seed)
	_emit_all_runtime_state()
	_set_status("Server listening on port %d." % current_port)
	return OK

func start_client(host: String, connect_port: int, player_name: String) -> int:
	shutdown()

	var peer := ENetMultiplayerPeer.new()
	var error: int = peer.create_client(host, connect_port)
	if error != OK:
		_set_status("Could not start a client connection to %s:%d (code %s)." % [host, connect_port, str(error)])
		emit_signal("client_connect_failed")
		return error

	multiplayer.multiplayer_peer = peer
	mode = Mode.CLIENT
	current_host = host
	current_port = connect_port
	local_player_name = player_name if not player_name.is_empty() else GameConfig.DEFAULT_PLAYER_NAME
	_client_bootstrap_complete = false
	emit_signal("mode_changed", _mode_name())
	_set_status("Connecting to %s:%d..." % [current_host, current_port])
	return OK

func shutdown() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

	mode = Mode.OFFLINE
	session_phase = SESSION_PHASE_HANGAR
	boat_blueprint = _decorate_blueprint(DockState.get_boat_blueprint())
	progression_state = _decorate_progression_snapshot(DockState.get_profile_snapshot())
	peer_snapshot = {}
	hangar_avatar_state = {}
	reaction_state = {}
	status_message = "Offline"
	_client_bootstrap_complete = false
	_disconnect_broadcast_scheduled = false
	_reset_reaction_runtime()
	_reset_run_runtime()
	emit_signal("mode_changed", _mode_name())
	emit_signal("run_seed_changed", run_seed)
	_emit_all_runtime_state()

func get_mode_name() -> String:
	return _mode_name()

func get_session_phase() -> String:
	return session_phase

func get_builder_bounds_min() -> Vector3i:
	return BUILDER_BOUNDS_MIN

func get_builder_bounds_max() -> Vector3i:
	return BUILDER_BOUNDS_MAX

func get_builder_cell_size() -> float:
	return BUILDER_CELL_SIZE

func get_builder_world_origin() -> Vector3:
	return BUILDER_WORLD_ORIGIN

func get_hangar_build_range() -> float:
	return HANGAR_BUILD_RANGE

func get_builder_block_ids() -> Array:
	var unlocked_lookup := _get_unlocked_block_lookup()
	var block_ids: Array = []
	for block_id_variant in BUILDER_BLOCK_ORDER:
		var block_id := str(block_id_variant)
		if not unlocked_lookup.has(block_id):
			continue
		block_ids.append(block_id)
	return block_ids

func get_builder_block_definition(block_type: String) -> Dictionary:
	var block_id := block_type.strip_edges().to_lower()
	var definition: Dictionary = BUILDER_BLOCK_LIBRARY.get(block_id, BUILDER_BLOCK_LIBRARY["structure"])
	return definition.duplicate(true)

func get_progression_state() -> Dictionary:
	return progression_state.duplicate(true)

func get_builder_store_entries() -> Array:
	var store_entries: Array = []
	var unlocked_lookup := _get_unlocked_block_lookup()
	var total_gold := int(progression_state.get("total_gold", 0))
	var total_salvage := int(progression_state.get("total_salvage", 0))
	for block_id_variant in BUILDER_BLOCK_ORDER:
		var block_id := str(block_id_variant)
		var block_def := get_builder_block_definition(block_id)
		if not bool(block_def.get("unlockable", false)):
			continue
		var unlock_cost_gold := int(block_def.get("unlock_cost_gold", 0))
		var unlock_cost_salvage := int(block_def.get("unlock_cost_salvage", 0))
		var unlocked := unlocked_lookup.has(block_id)
		store_entries.append({
			"block_id": block_id,
			"label": str(block_def.get("label", block_id.capitalize())),
			"description": str(block_def.get("description", "")),
			"unlock_cost_gold": unlock_cost_gold,
			"unlock_cost_salvage": unlock_cost_salvage,
			"unlocked": unlocked,
			"affordable": unlocked or (total_gold >= unlock_cost_gold and total_salvage >= unlock_cost_salvage),
			"definition": block_def.duplicate(true),
		})
	return store_entries

func get_toolbelt_entries(phase_name: String = session_phase) -> Array:
	if phase_name == SESSION_PHASE_RUN:
		return RUN_TOOLBELT.duplicate(true)
	return HANGAR_TOOLBELT.duplicate(true)

func get_hangar_inventory_snapshot() -> Dictionary:
	var snapshot := progression_state.duplicate(true)
	if snapshot.is_empty():
		snapshot = DockState.get_profile_snapshot()
	var blueprint_manifest: Array = []
	var block_counts: Dictionary = {}
	for block_variant in Array(boat_blueprint.get("blocks", [])):
		var block: Dictionary = block_variant
		var block_id := str(block.get("type", "structure"))
		block_counts[block_id] = int(block_counts.get(block_id, 0)) + 1
	for block_id_variant in block_counts.keys():
		var block_id := str(block_id_variant)
		var block_def := get_builder_block_definition(block_id)
		blueprint_manifest.append(_make_inventory_entry(
			str(block_def.get("label", block_id.capitalize())),
			int(block_counts.get(block_id, 0)),
			_get_inventory_icon_for_block(block_id),
			"Mounted on the shared blueprint."
		))
	blueprint_manifest.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("label", "")) < str(b.get("label", ""))
	)
	var unlocked_labels := PackedStringArray()
	for block_id_variant in Array(snapshot.get("unlocked_blocks", [])):
		var block_id := str(block_id_variant)
		var block_def := get_builder_block_definition(block_id)
		unlocked_labels.append(str(block_def.get("label", block_id.capitalize())))
	unlocked_labels.sort()
	return {
		"gold": int(snapshot.get("total_gold", 0)),
		"salvage": int(snapshot.get("total_salvage", 0)),
		"unlocked_parts": unlocked_labels,
		"blueprint_manifest": blueprint_manifest,
		"store_entries": get_builder_store_entries(),
		"stats": get_blueprint_stats(),
	}

func get_run_inventory_snapshot() -> Dictionary:
	var bonus_manifest: Array = []
	if bool(run_state.get("rescue_completed", false)):
		bonus_manifest.append(_make_inventory_entry(
			str(run_state.get("rescue_label", "Rescue Package")),
			1,
			"salvage",
			"+%d gold / +%d salvage / +%d patch kit." % [
				int(run_state.get("rescue_bonus_gold", 0)),
				int(run_state.get("rescue_bonus_salvage", 0)),
				int(run_state.get("rescue_patch_kit_bonus", 0)),
			]
		))
	if bool(run_state.get("cache_recovered", false)):
		bonus_manifest.append(_make_inventory_entry(
			str(run_state.get("cache_label", "Resupply Cache")),
			1,
			"repair-kit",
			"+%d gold / +%d salvage / +%d patch kit." % [
				RESUPPLY_CACHE_GOLD_BONUS,
				RESUPPLY_CACHE_SALVAGE_BONUS,
				RESUPPLY_CACHE_SUPPLY_GRANT,
			]
		))
	return {
		"cargo_manifest": Array(run_state.get("cargo_manifest", [])).duplicate(true),
		"secured_manifest": Array(run_state.get("secured_manifest", [])).duplicate(true),
		"bonus_manifest": bonus_manifest,
		"cargo_count": int(run_state.get("cargo_count", 0)),
		"cargo_capacity": int(run_state.get("cargo_capacity", int(boat_state.get("cargo_capacity", 0)))),
		"cargo_lost_to_sea": int(run_state.get("cargo_lost_to_sea", 0)),
		"patch_kits": int(run_state.get("repair_supplies", 0)),
		"patch_kits_max": int(run_state.get("repair_supplies_max", 0)),
		"bonus_gold_bank": int(run_state.get("bonus_gold_bank", 0)),
		"bonus_salvage_bank": int(run_state.get("bonus_salvage_bank", 0)),
	}

func _get_inventory_icon_for_block(block_id: String) -> String:
	match block_id.strip_edges().to_lower():
		"core", "hull", "reinforced_hull", "structure":
			return "reinforced-hull"
		"engine", "twin_engine":
			return "twin-engine"
		"cargo":
			return "cargo"
		"utility":
			return "repair-kit"
		"stabilizer":
			return "stabilizer"
		_:
			return "cargo"

func _make_inventory_entry(label: String, quantity: int, icon_id: String, detail: String = "") -> Dictionary:
	return {
		"label": label,
		"quantity": maxi(1, quantity),
		"icon_id": icon_id,
		"detail": detail,
	}

func _append_inventory_entry(state_key: String, label: String, quantity: int, icon_id: String, detail: String = "") -> void:
	if quantity <= 0:
		return
	var manifest: Array = Array(run_state.get(state_key, [])).duplicate(true)
	for entry_index in range(manifest.size()):
		var entry: Dictionary = manifest[entry_index]
		if str(entry.get("label", "")) != label:
			continue
		if str(entry.get("detail", "")) != detail:
			continue
		entry["quantity"] = int(entry.get("quantity", 0)) + quantity
		manifest[entry_index] = entry
		run_state[state_key] = manifest
		return
	manifest.append(_make_inventory_entry(label, quantity, icon_id, detail))
	run_state[state_key] = manifest

func _spill_inventory_quantity(state_key: String, quantity: int) -> void:
	if quantity <= 0:
		return
	var manifest: Array = Array(run_state.get(state_key, [])).duplicate(true)
	var remaining := quantity
	for entry_index in range(manifest.size() - 1, -1, -1):
		if remaining <= 0:
			break
		var entry: Dictionary = manifest[entry_index]
		var entry_quantity := int(entry.get("quantity", 0))
		if entry_quantity <= remaining:
			remaining -= entry_quantity
			manifest.remove_at(entry_index)
			continue
		entry["quantity"] = entry_quantity - remaining
		remaining = 0
		manifest[entry_index] = entry
	run_state[state_key] = manifest

func get_hangar_avatar_state() -> Dictionary:
	return hangar_avatar_state.duplicate(true)

func get_run_avatar_state() -> Dictionary:
	return run_avatar_state.duplicate(true)

func get_reaction_state() -> Dictionary:
	return reaction_state.duplicate(true)

func get_peer_reaction_state(peer_id: int) -> Dictionary:
	return Dictionary(reaction_state.get(peer_id, {})).duplicate(true)

func get_blueprint_stats() -> Dictionary:
	return Dictionary(boat_blueprint.get("stats", {})).duplicate(true)

func get_blueprint_warnings() -> Array:
	return Array(boat_blueprint.get("warnings", [])).duplicate(true)

func get_driver_name() -> String:
	if driver_peer_id <= 0:
		return "Unclaimed"

	var peer_data: Dictionary = peer_snapshot.get(driver_peer_id, {})
	return str(peer_data.get("name", "Peer %d" % driver_peer_id))

func get_player_peer_ids() -> Array:
	var peer_ids: Array = []
	if multiplayer.is_server():
		for peer_id in multiplayer.get_peers():
			var peer_data: Dictionary = peer_snapshot.get(peer_id, {})
			if str(peer_data.get("status", "")) == "hosting":
				continue
			peer_ids.append(peer_id)
		peer_ids.sort()
		return peer_ids

	for peer_id in peer_snapshot.keys():
		var peer_data: Dictionary = peer_snapshot[peer_id]
		if str(peer_data.get("status", "")) == "hosting":
			continue
		peer_ids.append(peer_id)
	peer_ids.sort()
	return peer_ids

func get_station_ids() -> Array:
	return STATION_ORDER.duplicate()

func get_claimable_station_ids() -> Array:
	return STATION_CLAIMABLE_ORDER.duplicate()

func get_station_label(station_id: String) -> String:
	var station_data: Dictionary = station_state.get(station_id, {})
	return str(station_data.get("label", station_id.capitalize()))

func get_station_position(station_id: String) -> Vector3:
	var station_data: Dictionary = station_state.get(station_id, {})
	return station_data.get("position", Vector3.ZERO)

func get_station_occupant_name(station_id: String) -> String:
	var station_data: Dictionary = station_state.get(station_id, {})
	var occupant_peer_id := int(station_data.get("occupant_peer_id", 0))
	if occupant_peer_id <= 0:
		return "Open"

	var peer_data: Dictionary = peer_snapshot.get(occupant_peer_id, {})
	return str(peer_data.get("name", "Peer %d" % occupant_peer_id))

func get_peer_station_id(peer_id: int) -> String:
	for station_id in STATION_ORDER:
		var station_data: Dictionary = station_state.get(station_id, {})
		if int(station_data.get("occupant_peer_id", 0)) == peer_id:
			return station_id
	return ""

func request_driver_control() -> void:
	request_station_claim("helm")

func request_station_claim(station_id: String) -> void:
	if multiplayer.is_server():
		_claim_station(multiplayer.get_unique_id(), station_id)
		return

	server_request_station_claim.rpc_id(1, station_id)

func request_station_release() -> void:
	if multiplayer.is_server():
		_release_station(multiplayer.get_unique_id())
		return

	server_request_station_release.rpc_id(1)

func request_unlock_builder_block(block_type: String) -> void:
	var normalized_block_type := block_type.strip_edges().to_lower()
	if normalized_block_type.is_empty():
		return
	if multiplayer.is_server():
		_unlock_builder_block(multiplayer.get_unique_id(), normalized_block_type)
		return

	server_request_unlock_builder_block.rpc_id(1, normalized_block_type)

func request_brace() -> void:
	if multiplayer.is_server():
		_begin_brace(multiplayer.get_unique_id())
		return

	server_request_brace.rpc_id(1)

func request_grapple() -> void:
	if multiplayer.is_server():
		_process_grapple(multiplayer.get_unique_id())
		return

	server_request_grapple.rpc_id(1)

func request_repair() -> void:
	if multiplayer.is_server():
		_process_repair(multiplayer.get_unique_id())
		return

	server_request_repair.rpc_id(1)

func request_overboard_recovery() -> void:
	if multiplayer.is_server():
		_attempt_overboard_recovery(multiplayer.get_unique_id())
		return

	server_request_overboard_recovery.rpc_id(1)

func request_debug_overboard() -> void:
	if multiplayer.is_server():
		_force_peer_overboard_for_debug(multiplayer.get_unique_id())
		return

	server_request_debug_overboard.rpc_id(1)

func request_place_blueprint_block(cell_value: Variant, block_type: String, rotation_steps: int) -> void:
	var cell := _normalize_blueprint_cell(cell_value)
	var normalized_type := block_type.strip_edges().to_lower()
	var normalized_rotation := wrapi(rotation_steps, 0, 4)
	if multiplayer.is_server():
		_place_blueprint_block(multiplayer.get_unique_id(), cell, normalized_type, normalized_rotation)
		return

	server_request_place_blueprint_block.rpc_id(1, cell, normalized_type, normalized_rotation)

func request_remove_blueprint_block(cell_value: Variant) -> void:
	var cell := _normalize_blueprint_cell(cell_value)
	if multiplayer.is_server():
		_remove_blueprint_block(multiplayer.get_unique_id(), cell)
		return

	server_request_remove_blueprint_block.rpc_id(1, cell)

func request_launch_run() -> void:
	if multiplayer.is_server():
		_launch_run_session(multiplayer.get_unique_id())
		return

	server_request_launch_run.rpc_id(1)

func request_return_to_hangar() -> void:
	if multiplayer.is_server():
		_return_to_hangar_session(multiplayer.get_unique_id())
		return

	server_request_return_to_hangar.rpc_id(1)

func send_local_hangar_avatar_state(position: Vector3, velocity: Vector3, facing_y: float, grounded: bool) -> void:
	if session_phase != SESSION_PHASE_HANGAR:
		return
	if multiplayer.is_server():
		_receive_hangar_avatar_state(
			multiplayer.get_unique_id(),
			position,
			velocity,
			facing_y,
			grounded,
			"",
			0,
			[0, 0, 0],
			[0, 0, 0],
			false,
			"hidden"
		)
		return
	server_receive_hangar_avatar_state.rpc_id(
		1,
		position,
		velocity,
		facing_y,
		grounded,
		"",
		0,
		[0, 0, 0],
		[0, 0, 0],
		false,
		"hidden"
	)

func send_local_hangar_avatar_presence(
	position: Vector3,
	velocity: Vector3,
	facing_y: float,
	grounded: bool,
	selected_block_id: String,
	rotation_steps: int,
	target_cell_value: Variant,
	remove_cell_value: Variant,
	has_target: bool,
	target_feedback_state: String
) -> void:
	if session_phase != SESSION_PHASE_HANGAR:
		return
	var normalized_target_cell := _normalize_blueprint_cell(target_cell_value)
	var normalized_remove_cell := _normalize_blueprint_cell(remove_cell_value)
	if multiplayer.is_server():
		_receive_hangar_avatar_state(
			multiplayer.get_unique_id(),
			position,
			velocity,
			facing_y,
			grounded,
			selected_block_id,
			rotation_steps,
			normalized_target_cell,
			normalized_remove_cell,
			has_target,
			target_feedback_state
		)
		return
	server_receive_hangar_avatar_state.rpc_id(
		1,
		position,
		velocity,
		facing_y,
		grounded,
		selected_block_id,
		rotation_steps,
		normalized_target_cell,
		normalized_remove_cell,
		has_target,
		target_feedback_state
	)

func send_local_run_avatar_state(deck_position: Vector3, world_position: Vector3, velocity: Vector3, facing_y: float, grounded: bool, avatar_mode: String = RUN_AVATAR_MODE_DECK) -> void:
	if session_phase != SESSION_PHASE_RUN:
		return
	if multiplayer.is_server():
		_receive_run_avatar_state(multiplayer.get_unique_id(), deck_position, world_position, velocity, facing_y, grounded, avatar_mode)
		return
	server_receive_run_avatar_state.rpc_id(1, deck_position, world_position, velocity, facing_y, grounded, avatar_mode)

func send_local_boat_input(throttle: float, steer: float) -> void:
	var clamped_throttle := clampf(throttle, -1.0, 1.0)
	var clamped_steer := clampf(steer, -1.0, 1.0)
	if multiplayer.is_server():
		_receive_boat_input(multiplayer.get_unique_id(), clamped_throttle, clamped_steer)
		return

	server_receive_boat_input.rpc_id(1, clamped_throttle, clamped_steer)

func server_step_shared_boat(delta: float) -> void:
	if not multiplayer.is_server():
		return
	_tick_reaction_state(delta)
	if session_phase == SESSION_PHASE_HANGAR:
		_process_hangar_bump_reactions()
		return
	if session_phase != SESSION_PHASE_RUN:
		return

	if str(run_state.get("phase", "running")) != "running":
		return

	_enforce_run_station_ranges()

	var brace_timer: float = maxf(0.0, float(boat_state.get("brace_timer", 0.0)) - delta)
	var brace_cooldown: float = maxf(0.0, float(boat_state.get("brace_cooldown", 0.0)) - delta)
	var repair_cooldown: float = maxf(0.0, float(boat_state.get("repair_cooldown", 0.0)) - delta)
	boat_state["brace_timer"] = brace_timer
	boat_state["brace_cooldown"] = brace_cooldown
	boat_state["repair_cooldown"] = repair_cooldown

	var breach_stacks := int(boat_state.get("breach_stacks", 0))
	var base_top_speed: float = float(boat_state.get("base_top_speed", BOAT_TOP_SPEED))
	var boat_position_for_drag: Vector3 = boat_state.get("position", Vector3.ZERO)
	var squall_drag_multiplier := _get_active_squall_drag_multiplier(boat_position_for_drag)
	boat_state["squall_drag_multiplier"] = squall_drag_multiplier
	var top_speed_limit := base_top_speed * maxf(0.45, 1.0 - float(breach_stacks) * BREACH_SPEED_PENALTY) * squall_drag_multiplier
	boat_state["top_speed_limit"] = top_speed_limit

	var input_state: Dictionary = _peer_inputs.get(driver_peer_id, {
		"throttle": 0.0,
		"steer": 0.0,
	})
	var throttle: float = float(input_state.get("throttle", 0.0))
	var steer: float = float(input_state.get("steer", 0.0))
	var current_speed: float = float(boat_state.get("speed", 0.0))
	var target_speed: float = throttle * top_speed_limit
	var acceleration: float = BOAT_ACCELERATION if absf(target_speed) > absf(current_speed) else BOAT_DECELERATION
	current_speed = move_toward(current_speed, target_speed, acceleration * delta)

	if is_zero_approx(throttle):
		current_speed = move_toward(current_speed, 0.0, BOAT_DECELERATION * 0.6 * delta)

	var turn_factor: float = clampf(absf(current_speed) / BOAT_TOP_SPEED, 0.25, 1.0)
	var rotation_y: float = float(boat_state.get("rotation_y", 0.0))
	rotation_y += steer * BOAT_TURN_SPEED * turn_factor * delta

	var forward: Vector3 = -Vector3.FORWARD.rotated(Vector3.UP, rotation_y)
	var position: Vector3 = boat_state.get("position", Vector3.ZERO)
	position += forward * current_speed * delta

	boat_state["position"] = position
	boat_state["rotation_y"] = rotation_y
	boat_state["speed"] = current_speed
	boat_state["throttle"] = throttle
	boat_state["steer"] = steer
	boat_state["tick"] = int(boat_state.get("tick", 0)) + 1
	boat_state["driver_peer_id"] = driver_peer_id
	_update_sinking_chunks(delta)

	if breach_stacks > 0:
		var leak_damage := HULL_LEAK_DAMAGE_PER_BREACH * float(breach_stacks) * delta
		boat_state["hull_integrity"] = maxf(0.0, float(boat_state.get("hull_integrity", BOAT_MAX_INTEGRITY)) - leak_damage)
		if float(boat_state.get("hull_integrity", BOAT_MAX_INTEGRITY)) <= 0.0:
			_broadcast_boat_state()
			_resolve_run_failure("The hull flooded before the crew could repair it.")
			return

	_process_rescue_hold(delta)
	if str(run_state.get("phase", "running")) != "running":
		return
	_process_squall_pressure(delta)
	if str(run_state.get("phase", "running")) != "running":
		return
	_process_hazard_collisions()
	_process_extraction(delta)

	_boat_broadcast_accumulator += delta
	if _boat_broadcast_accumulator >= BOAT_BROADCAST_INTERVAL:
		_boat_broadcast_accumulator = 0.0
		_broadcast_boat_state()

func _mode_name() -> String:
	match mode:
		Mode.CLIENT:
			return "client"
		Mode.SERVER:
			return "server"
		_:
			return "offline"

func _set_status(message: String) -> void:
	status_message = message
	emit_signal("status_changed", message)
	print(message)

func _emit_all_runtime_state() -> void:
	emit_signal("session_phase_changed", session_phase)
	emit_signal("boat_blueprint_changed", boat_blueprint.duplicate(true))
	emit_signal("progression_state_changed", progression_state.duplicate(true))
	emit_signal("peer_snapshot_changed", peer_snapshot.duplicate(true))
	emit_signal("hangar_avatar_state_changed", hangar_avatar_state.duplicate(true))
	emit_signal("run_avatar_state_changed", run_avatar_state.duplicate(true))
	emit_signal("reaction_state_changed", reaction_state.duplicate(true))
	emit_signal("helm_changed", driver_peer_id)
	emit_signal("boat_state_changed", boat_state.duplicate(true))
	emit_signal("hazard_state_changed", hazard_state.duplicate(true))
	emit_signal("station_state_changed", station_state.duplicate(true))
	emit_signal("loot_state_changed", loot_state.duplicate(true))
	emit_signal("run_state_changed", run_state.duplicate(true))

func _broadcast_session_phase() -> void:
	emit_signal("session_phase_changed", session_phase)
	if multiplayer.is_server():
		for peer_id in _get_server_broadcast_peer_ids():
			client_receive_session_phase.rpc_id(int(peer_id), session_phase)

func _broadcast_blueprint_state() -> void:
	emit_signal("boat_blueprint_changed", boat_blueprint.duplicate(true))
	if multiplayer.is_server():
		var snapshot := boat_blueprint.duplicate(true)
		for peer_id in _get_server_broadcast_peer_ids():
			client_receive_blueprint_state.rpc_id(int(peer_id), snapshot)

func _broadcast_progression_state() -> void:
	emit_signal("progression_state_changed", progression_state.duplicate(true))
	if multiplayer.is_server():
		var snapshot := progression_state.duplicate(true)
		for peer_id in _get_server_broadcast_peer_ids():
			client_receive_progression_state.rpc_id(int(peer_id), snapshot)

func _broadcast_peer_snapshot() -> void:
	emit_signal("peer_snapshot_changed", peer_snapshot.duplicate(true))
	if multiplayer.is_server():
		var snapshot := peer_snapshot.duplicate(true)
		for peer_id in _get_server_broadcast_peer_ids():
			client_receive_peer_snapshot.rpc_id(int(peer_id), snapshot)

func _broadcast_hangar_avatar_state() -> void:
	emit_signal("hangar_avatar_state_changed", hangar_avatar_state.duplicate(true))
	if multiplayer.is_server():
		var snapshot := hangar_avatar_state.duplicate(true)
		for peer_id in _get_server_broadcast_peer_ids():
			client_receive_hangar_avatar_state.rpc_id(int(peer_id), snapshot)

func _broadcast_run_avatar_state() -> void:
	emit_signal("run_avatar_state_changed", run_avatar_state.duplicate(true))
	if multiplayer.is_server():
		var snapshot := run_avatar_state.duplicate(true)
		for peer_id in _get_server_broadcast_peer_ids():
			client_receive_run_avatar_state.rpc_id(int(peer_id), snapshot)

func _broadcast_reaction_state() -> void:
	emit_signal("reaction_state_changed", reaction_state.duplicate(true))
	if multiplayer.is_server():
		var snapshot := reaction_state.duplicate(true)
		for peer_id in _get_server_broadcast_peer_ids():
			client_receive_reaction_state.rpc_id(int(peer_id), snapshot)

func _broadcast_boat_state() -> void:
	emit_signal("boat_state_changed", boat_state.duplicate(true))
	if multiplayer.is_server():
		var state := _build_client_boat_state_snapshot()
		for peer_id in _get_server_broadcast_peer_ids():
			client_receive_boat_state.rpc_id(int(peer_id), state, driver_peer_id)

func _broadcast_hazard_state() -> void:
	emit_signal("hazard_state_changed", hazard_state.duplicate(true))
	if multiplayer.is_server():
		var hazards := hazard_state.duplicate(true)
		for peer_id in _get_server_broadcast_peer_ids():
			client_receive_hazard_state.rpc_id(int(peer_id), hazards)

func _broadcast_station_state() -> void:
	emit_signal("station_state_changed", station_state.duplicate(true))
	if multiplayer.is_server():
		var stations := station_state.duplicate(true)
		for peer_id in _get_server_broadcast_peer_ids():
			client_receive_station_state.rpc_id(int(peer_id), stations)

func _broadcast_loot_state() -> void:
	emit_signal("loot_state_changed", loot_state.duplicate(true))
	if multiplayer.is_server():
		var targets := loot_state.duplicate(true)
		for peer_id in _get_server_broadcast_peer_ids():
			client_receive_loot_state.rpc_id(int(peer_id), targets)

func _broadcast_run_state() -> void:
	emit_signal("run_state_changed", run_state.duplicate(true))
	if multiplayer.is_server():
		var state := run_state.duplicate(true)
		for peer_id in _get_server_broadcast_peer_ids():
			client_receive_run_state.rpc_id(int(peer_id), state)

func _get_server_broadcast_peer_ids() -> Array:
	if not multiplayer.is_server():
		return []
	if _disconnect_broadcast_scheduled:
		return []
	return get_player_peer_ids()

func _send_bootstrap(peer_id: int) -> void:
	if not multiplayer.is_server():
		return

	client_receive_bootstrap.rpc_id(peer_id, run_seed, current_port, GameConfig.MAX_PLAYERS, session_phase, boat_blueprint.duplicate(true))
	client_receive_progression_state.rpc_id(peer_id, progression_state.duplicate(true))
	client_receive_boat_state.rpc_id(peer_id, _build_client_boat_state_snapshot(), driver_peer_id)
	client_receive_hazard_state.rpc_id(peer_id, hazard_state.duplicate(true))
	client_receive_station_state.rpc_id(peer_id, station_state.duplicate(true))
	client_receive_loot_state.rpc_id(peer_id, loot_state.duplicate(true))
	client_receive_run_state.rpc_id(peer_id, run_state.duplicate(true))
	client_receive_hangar_avatar_state.rpc_id(peer_id, hangar_avatar_state.duplicate(true))
	client_receive_run_avatar_state.rpc_id(peer_id, run_avatar_state.duplicate(true))
	client_receive_reaction_state.rpc_id(peer_id, reaction_state.duplicate(true))
	if session_phase == SESSION_PHASE_RUN:
		client_receive_runtime_boat_state.rpc_id(peer_id, _build_client_runtime_boat_snapshot())

func _build_client_boat_state_snapshot() -> Dictionary:
	var snapshot := boat_state.duplicate(true)
	snapshot.erase("runtime_blocks")
	snapshot.erase("sinking_chunks")
	snapshot.erase("runtime_chunks")
	snapshot.erase("recent_damage_block_ids")
	snapshot.erase("recent_detached_chunk_ids")
	snapshot.erase("cargo_lost_to_sea")
	return snapshot

func _build_client_runtime_boat_snapshot() -> Dictionary:
	return {
		"runtime_blocks": _build_client_runtime_blocks_snapshot(),
		"sinking_chunks": _build_client_sinking_chunks_snapshot(),
	}

func _build_client_runtime_blocks_snapshot() -> Array:
	var runtime_blocks_snapshot: Array = []
	for block_variant in Array(boat_state.get("runtime_blocks", [])):
		var block: Dictionary = block_variant
		runtime_blocks_snapshot.append({
			"id": int(block.get("id", 0)),
			"current_hp": float(block.get("current_hp", 0.0)),
			"destroyed": bool(block.get("destroyed", false)),
			"detached": bool(block.get("detached", false)),
		})
	return runtime_blocks_snapshot

func _build_client_sinking_chunks_snapshot() -> Array:
	var sinking_chunks_snapshot: Array = []
	for chunk_variant in Array(boat_state.get("sinking_chunks", [])):
		var chunk: Dictionary = chunk_variant
		var block_ids: Array = []
		for block_variant in Array(chunk.get("blocks", [])):
			var block: Dictionary = block_variant
			block_ids.append(int(block.get("id", 0)))
		sinking_chunks_snapshot.append({
			"chunk_id": int(chunk.get("chunk_id", 0)),
			"world_position": chunk.get("world_position", Vector3.ZERO),
			"rotation_y": float(chunk.get("rotation_y", 0.0)),
			"sink_elapsed": float(chunk.get("sink_elapsed", 0.0)),
			"drift_velocity": chunk.get("drift_velocity", Vector3.ZERO),
			"block_ids": block_ids,
		})
	return sinking_chunks_snapshot

func _broadcast_runtime_boat_state() -> void:
	if not multiplayer.is_server() or session_phase != SESSION_PHASE_RUN:
		return

	var runtime_snapshot := _build_client_runtime_boat_snapshot()
	for peer_id in get_player_peer_ids():
		client_receive_runtime_boat_state.rpc_id(int(peer_id), runtime_snapshot)

func _tick_reaction_state(delta: float) -> void:
	if not multiplayer.is_server():
		return

	var expired_peers: Array = []
	for peer_id_variant in reaction_state.keys():
		var peer_id := int(peer_id_variant)
		var peer_reaction: Dictionary = reaction_state[peer_id]
		peer_reaction["active_time"] = maxf(0.0, float(peer_reaction.get("active_time", 0.0)) - delta)
		peer_reaction["recovery_time"] = maxf(0.0, float(peer_reaction.get("recovery_time", 0.0)) - delta)
		if float(peer_reaction.get("active_time", 0.0)) <= 0.0 and float(peer_reaction.get("recovery_time", 0.0)) <= 0.0:
			expired_peers.append(peer_id)
			continue
		reaction_state[peer_id] = peer_reaction
	for peer_id_variant in expired_peers:
		reaction_state.erase(int(peer_id_variant))
	if not expired_peers.is_empty():
		_broadcast_reaction_state()

	var expired_pairs: Array = []
	for pair_key_variant in _hangar_bump_pair_cooldowns.keys():
		var pair_key := str(pair_key_variant)
		var remaining: float = maxf(0.0, float(_hangar_bump_pair_cooldowns[pair_key]) - delta)
		if remaining <= 0.0:
			expired_pairs.append(pair_key)
		else:
			_hangar_bump_pair_cooldowns[pair_key] = remaining
	for pair_key_variant in expired_pairs:
		_hangar_bump_pair_cooldowns.erase(str(pair_key_variant))

func _process_hangar_bump_reactions() -> void:
	if session_phase != SESSION_PHASE_HANGAR:
		return
	var peer_ids := get_player_peer_ids()
	if peer_ids.size() < 2:
		return

	for left_index in range(peer_ids.size()):
		var left_peer := int(peer_ids[left_index])
		if _peer_has_reaction_lock(left_peer):
			continue
		var left_state: Dictionary = hangar_avatar_state.get(left_peer, {})
		if left_state.is_empty():
			continue
		var left_position: Vector3 = left_state.get("position", Vector3.ZERO)
		var left_velocity: Vector3 = left_state.get("velocity", Vector3.ZERO)
		for right_index in range(left_index + 1, peer_ids.size()):
			var right_peer := int(peer_ids[right_index])
			if _peer_has_reaction_lock(right_peer):
				continue
			var pair_key := _build_peer_pair_key(left_peer, right_peer)
			if float(_hangar_bump_pair_cooldowns.get(pair_key, 0.0)) > 0.0:
				continue
			var right_state: Dictionary = hangar_avatar_state.get(right_peer, {})
			if right_state.is_empty():
				continue
			var right_position: Vector3 = right_state.get("position", Vector3.ZERO)
			var offset := right_position - left_position
			var distance := offset.length()
			if distance > REACTION_BUMP_COLLISION_RADIUS or distance <= 0.05:
				continue
			var collision_direction := offset / distance
			var right_velocity: Vector3 = right_state.get("velocity", Vector3.ZERO)
			var relative_velocity: Vector3 = left_velocity - right_velocity
			var relative_speed := relative_velocity.length()
			if relative_speed < REACTION_BUMP_SPEED_THRESHOLD:
				continue
			if relative_velocity.dot(collision_direction) <= 0.75:
				continue
			var strength := clampf((relative_speed - REACTION_BUMP_SPEED_THRESHOLD) / 3.0 + 0.35, 0.35, 1.0)
			var knockback_speed := lerpf(REACTION_BUMP_KNOCKBACK * 0.55, REACTION_BUMP_KNOCKBACK, strength)
			_start_peer_reaction(
				left_peer,
				"bump",
				strength,
				-collision_direction * knockback_speed + Vector3.UP * (0.3 + strength * 0.18),
				REACTION_BUMP_ACTIVE_SECONDS + strength * 0.04,
				REACTION_BUMP_RECOVERY_SECONDS + strength * 0.08,
				right_peer
			)
			_start_peer_reaction(
				right_peer,
				"bump",
				strength,
				collision_direction * knockback_speed + Vector3.UP * (0.3 + strength * 0.18),
				REACTION_BUMP_ACTIVE_SECONDS + strength * 0.04,
				REACTION_BUMP_RECOVERY_SECONDS + strength * 0.08,
				left_peer
			)
			_hangar_bump_pair_cooldowns[pair_key] = REACTION_BUMP_PAIR_COOLDOWN
			_set_status("%s slammed into %s in the hangar." % [_get_peer_name(left_peer), _get_peer_name(right_peer)])
			return

func _start_peer_reaction(peer_id: int, reaction_type: String, strength: float, knockback_velocity: Vector3, active_seconds: float, recovery_seconds: float, source_peer_id: int = 0, brace_applied: bool = false, pull_direction: Vector3 = Vector3.ZERO) -> void:
	if not multiplayer.is_server():
		return
	if peer_id <= 0:
		return
	if not peer_snapshot.has(peer_id):
		return
	var current_reaction: Dictionary = reaction_state.get(peer_id, {})
	if not current_reaction.is_empty() and float(current_reaction.get("active_time", 0.0)) > 0.0 and float(current_reaction.get("strength", 0.0)) > strength and str(current_reaction.get("type", "")) == "impact":
		return
	reaction_state[peer_id] = {
		"reaction_id": _next_reaction_id,
		"type": reaction_type,
		"strength": clampf(strength, 0.0, 1.0),
		"active_time": maxf(0.0, active_seconds),
		"active_duration": maxf(0.0, active_seconds),
		"recovery_time": maxf(0.0, recovery_seconds),
		"recovery_duration": maxf(0.0, recovery_seconds),
		"knockback_velocity": knockback_velocity,
		"pull_direction": pull_direction,
		"source_peer_id": source_peer_id,
		"brace_applied": brace_applied,
		"phase": session_phase,
	}
	_next_reaction_id += 1
	_broadcast_reaction_state()

func _apply_run_impact_reactions(base_direction: Vector3, base_strength: float, brace_applied: bool, release_stations: bool, primary_station_id: String = "") -> void:
	if not multiplayer.is_server():
		return
	var direction := base_direction.normalized()
	if direction.length() <= 0.01:
		direction = Vector3.BACK
	var released_any := false
	for peer_id_variant in get_player_peer_ids():
		var peer_id := int(peer_id_variant)
		var station_id := get_peer_station_id(peer_id)
		var strength := clampf(base_strength, 0.0, 1.0)
		if not primary_station_id.is_empty() and station_id == primary_station_id:
			strength = minf(1.0, strength + 0.14)
		var knockback_speed := lerpf(REACTION_IMPACT_KNOCKBACK * 0.65, REACTION_IMPACT_KNOCKBACK, strength)
		var active_seconds := REACTION_IMPACT_ACTIVE_SECONDS + strength * 0.08
		var recovery_seconds := REACTION_IMPACT_RECOVERY_SECONDS + strength * 0.12
		_start_peer_reaction(
			peer_id,
			"impact",
			strength,
			direction * knockback_speed + Vector3.UP * (0.42 + strength * 0.22),
			active_seconds,
			recovery_seconds,
			0,
			brace_applied
		)
		_try_knock_peer_overboard(peer_id, direction * knockback_speed, strength, brace_applied)
		if release_stations and not station_id.is_empty():
			_release_station(peer_id, false)
			released_any = true
	if released_any:
		_broadcast_station_state()
		_broadcast_boat_state()

func _try_knock_peer_overboard(peer_id: int, knockback_velocity: Vector3, strength: float, brace_applied: bool) -> void:
	if brace_applied or strength < RUN_OVERBOARD_MIN_STRENGTH:
		return
	if _is_peer_overboard(peer_id):
		return
	var avatar_state: Dictionary = run_avatar_state.get(peer_id, {})
	if avatar_state.is_empty():
		return
	var deck_position: Vector3 = avatar_state.get("deck_position", Vector3.ZERO)
	var local_knockback := knockback_velocity.rotated(Vector3.UP, -float(boat_state.get("rotation_y", 0.0)))
	local_knockback.y = 0.0
	if local_knockback.length() <= 0.01:
		return
	local_knockback = local_knockback.normalized()

	var overboard_local_position := deck_position
	var will_go_overboard := false
	if deck_position.x <= RUN_DECK_BOUNDS_MIN.x + RUN_OVERBOARD_EDGE_MARGIN and local_knockback.x < -0.2:
		overboard_local_position.x = RUN_DECK_BOUNDS_MIN.x - 1.05
		overboard_local_position.z = clampf(deck_position.z, RUN_DECK_BOUNDS_MIN.z + 0.18, RUN_DECK_BOUNDS_MAX.z - 0.18)
		will_go_overboard = true
	elif deck_position.x >= RUN_DECK_BOUNDS_MAX.x - RUN_OVERBOARD_EDGE_MARGIN and local_knockback.x > 0.2:
		overboard_local_position.x = RUN_DECK_BOUNDS_MAX.x + 1.05
		overboard_local_position.z = clampf(deck_position.z, RUN_DECK_BOUNDS_MIN.z + 0.18, RUN_DECK_BOUNDS_MAX.z - 0.18)
		will_go_overboard = true
	elif deck_position.z <= RUN_DECK_BOUNDS_MIN.z + RUN_OVERBOARD_EDGE_MARGIN and local_knockback.z < -0.2:
		overboard_local_position.z = RUN_DECK_BOUNDS_MIN.z - 0.95
		overboard_local_position.x = clampf(deck_position.x, RUN_DECK_BOUNDS_MIN.x + 0.18, RUN_DECK_BOUNDS_MAX.x - 0.18)
		will_go_overboard = true
	elif deck_position.z >= RUN_DECK_BOUNDS_MAX.z - RUN_OVERBOARD_EDGE_MARGIN and local_knockback.z > 0.2:
		overboard_local_position.z = RUN_DECK_BOUNDS_MAX.z + 0.95
		overboard_local_position.x = clampf(deck_position.x, RUN_DECK_BOUNDS_MIN.x + 0.18, RUN_DECK_BOUNDS_MAX.x - 0.18)
		will_go_overboard = true
	if not will_go_overboard:
		return
	_set_peer_overboard(peer_id, overboard_local_position, knockback_velocity)

func _set_peer_overboard(peer_id: int, overboard_local_position: Vector3, knockback_velocity: Vector3) -> void:
	if not multiplayer.is_server():
		return
	var avatar_state: Dictionary = run_avatar_state.get(peer_id, {})
	if avatar_state.is_empty():
		return
	if _is_peer_overboard(peer_id):
		return
	var current_station_id := get_peer_station_id(peer_id)
	if not current_station_id.is_empty():
		_release_station(peer_id, false)
	var world_position := _run_local_to_world(overboard_local_position)
	world_position.y = RUN_OVERBOARD_WATER_HEIGHT
	avatar_state["mode"] = RUN_AVATAR_MODE_OVERBOARD
	avatar_state["world_position"] = world_position
	avatar_state["velocity"] = knockback_velocity.limit_length(6.8)
	avatar_state["grounded"] = false
	run_avatar_state[peer_id] = avatar_state
	_refresh_run_avatar_runtime_fields(peer_id)
	var peer_reaction: Dictionary = reaction_state.get(peer_id, {})
	if not peer_reaction.is_empty():
		peer_reaction["type"] = "overboard"
		peer_reaction["active_time"] = maxf(float(peer_reaction.get("active_time", 0.0)), 0.18)
		peer_reaction["recovery_time"] = maxf(float(peer_reaction.get("recovery_time", 0.0)), 0.55)
		reaction_state[peer_id] = peer_reaction
	run_state["overboard_incidents"] = int(run_state.get("overboard_incidents", 0)) + 1
	_refresh_overboard_run_metrics()
	_peer_inputs[peer_id] = {
		"throttle": 0.0,
		"steer": 0.0,
	}
	_broadcast_station_state()
	_broadcast_run_avatar_state()
	_broadcast_reaction_state()
	_broadcast_run_state()
	_broadcast_boat_state()
	_set_status("%s went overboard." % _get_peer_name(peer_id))

func _force_peer_overboard_for_debug(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	var avatar_state: Dictionary = run_avatar_state.get(peer_id, {})
	if avatar_state.is_empty() or _is_peer_overboard(peer_id):
		return
	var deck_position: Vector3 = avatar_state.get("deck_position", Vector3.ZERO)
	var overboard_local_position := deck_position
	var knockback_velocity := Vector3.ZERO
	if absf(deck_position.x) >= absf(deck_position.z):
		var starboard := deck_position.x >= 0.0
		overboard_local_position.x = (RUN_DECK_BOUNDS_MAX.x + 1.05) if starboard else (RUN_DECK_BOUNDS_MIN.x - 1.05)
		knockback_velocity = _run_local_to_world(Vector3(1.0 if starboard else -1.0, 0.0, 0.0)) - boat_state.get("position", Vector3.ZERO)
	else:
		var stern := deck_position.z >= 0.0
		overboard_local_position.z = (RUN_DECK_BOUNDS_MAX.z + 0.95) if stern else (RUN_DECK_BOUNDS_MIN.z - 0.95)
		knockback_velocity = _run_local_to_world(Vector3(0.0, 0.0, 1.0 if stern else -1.0)) - boat_state.get("position", Vector3.ZERO)
	knockback_velocity.y = 0.0
	_set_peer_overboard(peer_id, overboard_local_position, knockback_velocity.normalized() * 4.8)

func _attempt_overboard_recovery(peer_id: int) -> void:
	if session_phase != SESSION_PHASE_RUN:
		return
	if str(run_state.get("phase", "running")) != "running":
		return
	if not _is_peer_overboard(peer_id):
		return
	var avatar_state: Dictionary = run_avatar_state.get(peer_id, {})
	if avatar_state.is_empty():
		return
	var world_position: Vector3 = avatar_state.get("world_position", boat_state.get("position", Vector3.ZERO))
	var recovery_target := _get_best_overboard_recovery_target(world_position)
	if recovery_target.is_empty() or not bool(recovery_target.get("ready", false)):
		_set_status("%s needs to reach a ladder before climbing back aboard." % _get_peer_name(peer_id))
		return
	avatar_state["mode"] = RUN_AVATAR_MODE_DECK
	avatar_state["deck_position"] = _sanitize_run_avatar_deck_position(recovery_target.get("deck_position", RUN_DECK_SPAWN_POINTS[0]))
	avatar_state["velocity"] = Vector3.ZERO
	avatar_state["grounded"] = true
	run_avatar_state[peer_id] = avatar_state
	_refresh_run_avatar_runtime_fields(peer_id)
	var peer_reaction: Dictionary = reaction_state.get(peer_id, {})
	if not peer_reaction.is_empty():
		peer_reaction["type"] = "recovering"
		peer_reaction["active_time"] = 0.0
		peer_reaction["recovery_time"] = maxf(float(peer_reaction.get("recovery_time", 0.0)), 0.22)
		reaction_state[peer_id] = peer_reaction
	run_state["recoveries_completed"] = int(run_state.get("recoveries_completed", 0)) + 1
	_refresh_overboard_run_metrics()
	_broadcast_run_avatar_state()
	_broadcast_reaction_state()
	_broadcast_run_state()
	_set_status("%s climbed back aboard via the %s." % [
		_get_peer_name(peer_id),
		str(recovery_target.get("label", "recovery line")),
	])

func _peer_has_reaction_lock(peer_id: int) -> bool:
	var peer_reaction: Dictionary = reaction_state.get(peer_id, {})
	if peer_reaction.is_empty():
		return false
	return float(peer_reaction.get("active_time", 0.0)) > 0.0

func _build_peer_pair_key(left_peer: int, right_peer: int) -> String:
	var low_peer := mini(left_peer, right_peer)
	var high_peer := maxi(left_peer, right_peer)
	return "%d:%d" % [low_peer, high_peer]

func _reset_progression_runtime() -> void:
	progression_state = _decorate_progression_snapshot(DockState.get_profile_snapshot())

func _reset_blueprint_runtime() -> void:
	boat_blueprint = _decorate_blueprint(DockState.get_boat_blueprint())

func _reset_hangar_avatar_state() -> void:
	hangar_avatar_state = {}

func _reset_run_avatar_state() -> void:
	run_avatar_state = {}

func _reset_reaction_runtime() -> void:
	reaction_state = {}
	_next_reaction_id = 1
	_hangar_bump_pair_cooldowns = {}

func _reset_connected_hangar_avatars() -> void:
	if not multiplayer.is_server():
		return
	hangar_avatar_state = {}
	var peer_ids := get_player_peer_ids()
	for index in range(peer_ids.size()):
		var peer_id := int(peer_ids[index])
		hangar_avatar_state[peer_id] = _make_default_hangar_avatar_state(index)
	_broadcast_hangar_avatar_state()

func _reset_connected_run_avatars() -> void:
	if not multiplayer.is_server():
		return
	run_avatar_state = {}
	var peer_ids := get_player_peer_ids()
	for index in range(peer_ids.size()):
		var peer_id := int(peer_ids[index])
		run_avatar_state[peer_id] = _make_default_run_avatar_state(index)
		_refresh_run_avatar_runtime_fields(peer_id)
	_refresh_overboard_run_metrics()
	_broadcast_run_avatar_state()

func _make_default_hangar_avatar_state(spawn_index: int) -> Dictionary:
	var clamped_index := wrapi(spawn_index, 0, HANGAR_SPAWN_POINTS.size())
	var spawn_position: Vector3 = HANGAR_SPAWN_POINTS[clamped_index]
	var default_block_id := "structure"
	var unlocked_block_ids := get_builder_block_ids()
	if not unlocked_block_ids.is_empty():
		default_block_id = str(unlocked_block_ids[0])
	return {
		"position": spawn_position,
		"velocity": Vector3.ZERO,
		"facing_y": 0.0,
		"grounded": true,
		"selected_block_id": default_block_id,
		"rotation_steps": 0,
		"target_cell": [0, 0, 0],
		"remove_cell": [0, 0, 0],
		"has_target": false,
		"target_feedback_state": "hidden",
	}

func _make_default_run_avatar_state(spawn_index: int) -> Dictionary:
	var clamped_index := wrapi(spawn_index, 0, RUN_DECK_SPAWN_POINTS.size())
	var spawn_position: Vector3 = RUN_DECK_SPAWN_POINTS[clamped_index]
	var world_position := _run_local_to_world(spawn_position)
	return {
		"mode": RUN_AVATAR_MODE_DECK,
		"deck_position": spawn_position,
		"world_position": world_position,
		"velocity": Vector3.ZERO,
		"facing_y": PI,
		"grounded": true,
		"recovery_target_id": "",
		"recovery_target_label": "",
		"recovery_ready": false,
	}

func _run_local_to_world(local_position: Vector3) -> Vector3:
	var rotation_y: float = float(boat_state.get("rotation_y", 0.0))
	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	return boat_position + local_position.rotated(Vector3.UP, rotation_y)

func _run_world_to_local(world_position: Vector3) -> Vector3:
	var rotation_y: float = float(boat_state.get("rotation_y", 0.0))
	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	return (world_position - boat_position).rotated(Vector3.UP, -rotation_y)

func _get_overboard_recovery_targets() -> Array:
	var targets: Array = []
	for target_variant in RUN_RECOVERY_POINTS:
		var target: Dictionary = target_variant
		var world_target := _run_local_to_world(target.get("water_position", Vector3.ZERO))
		world_target.y = RUN_OVERBOARD_WATER_HEIGHT
		targets.append({
			"id": str(target.get("id", "")),
			"label": str(target.get("label", "Recovery")),
			"water_position": world_target,
			"deck_position": target.get("deck_position", Vector3.ZERO),
		})
	return targets

func _get_best_overboard_recovery_target(world_position: Vector3) -> Dictionary:
	var nearest_target: Dictionary = {}
	var nearest_distance := INF
	for target_variant in _get_overboard_recovery_targets():
		var target: Dictionary = target_variant
		var target_world_position: Vector3 = target.get("water_position", Vector3.ZERO)
		var distance := world_position.distance_to(target_world_position)
		if distance >= nearest_distance:
			continue
		nearest_distance = distance
		nearest_target = target.duplicate(true)
		nearest_target["distance"] = distance
		nearest_target["ready"] = distance <= RUN_OVERBOARD_RECOVERY_RANGE
	return nearest_target

func _sanitize_overboard_world_position(world_position: Vector3) -> Vector3:
	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	var offset := world_position - boat_position
	offset.y = 0.0
	if offset.length() > RUN_OVERBOARD_SWIM_RADIUS:
		offset = offset.normalized() * RUN_OVERBOARD_SWIM_RADIUS
	var sanitized_position := boat_position + offset
	sanitized_position.y = RUN_OVERBOARD_WATER_HEIGHT
	return sanitized_position

func _refresh_run_avatar_runtime_fields(peer_id: int) -> void:
	var avatar_state: Dictionary = run_avatar_state.get(peer_id, {})
	if avatar_state.is_empty():
		return
	var avatar_mode := str(avatar_state.get("mode", RUN_AVATAR_MODE_DECK))
	if avatar_mode == RUN_AVATAR_MODE_OVERBOARD:
		var world_position := _sanitize_overboard_world_position(avatar_state.get("world_position", boat_state.get("position", Vector3.ZERO)))
		var recovery_target := _get_best_overboard_recovery_target(world_position)
		avatar_state["world_position"] = world_position
		avatar_state["recovery_target_id"] = str(recovery_target.get("id", ""))
		avatar_state["recovery_target_label"] = str(recovery_target.get("label", ""))
		avatar_state["recovery_ready"] = bool(recovery_target.get("ready", false))
		avatar_state["deck_position"] = _sanitize_run_avatar_deck_position(avatar_state.get("deck_position", RUN_DECK_SPAWN_POINTS[0]))
	else:
		var deck_position := _sanitize_run_avatar_deck_position(avatar_state.get("deck_position", RUN_DECK_SPAWN_POINTS[0]))
		avatar_state["mode"] = RUN_AVATAR_MODE_DECK
		avatar_state["deck_position"] = deck_position
		avatar_state["world_position"] = _run_local_to_world(deck_position)
		avatar_state["recovery_target_id"] = ""
		avatar_state["recovery_target_label"] = ""
		avatar_state["recovery_ready"] = false
	run_avatar_state[peer_id] = avatar_state

func _is_peer_overboard(peer_id: int) -> bool:
	return str(run_avatar_state.get(peer_id, {}).get("mode", RUN_AVATAR_MODE_DECK)) == RUN_AVATAR_MODE_OVERBOARD

func _refresh_overboard_run_metrics() -> void:
	var overboard_count := 0
	for peer_id_variant in run_avatar_state.keys():
		if _is_peer_overboard(int(peer_id_variant)):
			overboard_count += 1
	run_state["overboard_count"] = overboard_count

func _is_station_claimable(station_id: String) -> bool:
	return STATION_CLAIMABLE_ORDER.has(station_id)

func _get_run_station_claim_radius(station_id: String) -> float:
	match station_id:
		"helm":
			return RUN_HELM_ZONE_RADIUS
		"grapple":
			return RUN_GRAPPLE_ZONE_RADIUS
		_:
			return 0.0

func _get_run_station_release_radius(station_id: String) -> float:
	match station_id:
		"helm":
			return RUN_HELM_RELEASE_RADIUS
		"grapple":
			return RUN_GRAPPLE_RELEASE_RADIUS
		_:
			return 0.0

func _get_peer_run_avatar_position(peer_id: int) -> Vector3:
	var avatar_state: Dictionary = run_avatar_state.get(peer_id, {})
	return avatar_state.get("deck_position", Vector3.ZERO)

func _peer_within_run_station_range(peer_id: int, station_id: String, extra_margin: float = 0.0) -> bool:
	if peer_id <= 0 or not station_state.has(station_id):
		return false
	var avatar_state: Dictionary = run_avatar_state.get(peer_id, {})
	if avatar_state.is_empty():
		return false
	if str(avatar_state.get("mode", RUN_AVATAR_MODE_DECK)) != RUN_AVATAR_MODE_DECK:
		return false
	var claim_radius := _get_run_station_claim_radius(station_id)
	if claim_radius <= 0.0:
		return false
	var avatar_position: Vector3 = avatar_state.get("deck_position", Vector3.ZERO)
	var station_position := get_station_position(station_id)
	return avatar_position.distance_to(station_position) <= (claim_radius + maxf(0.0, extra_margin))

func _find_nearest_repairable_block(peer_id: int, max_range: float = RUN_REPAIR_RANGE) -> Dictionary:
	if peer_id <= 0:
		return {}
	var avatar_state: Dictionary = run_avatar_state.get(peer_id, {})
	if avatar_state.is_empty():
		return {}
	if str(avatar_state.get("mode", RUN_AVATAR_MODE_DECK)) != RUN_AVATAR_MODE_DECK:
		return {}
	var avatar_position: Vector3 = avatar_state.get("deck_position", Vector3.ZERO)
	var nearest_block: Dictionary = {}
	var nearest_distance := max_range
	for block_variant in Array(boat_state.get("runtime_blocks", [])):
		var block: Dictionary = block_variant
		if bool(block.get("destroyed", false)) or bool(block.get("detached", false)):
			continue
		if float(block.get("current_hp", 0.0)) >= float(block.get("max_hp", 0.0)) - 0.01:
			continue
		var local_position: Vector3 = block.get("local_position", Vector3.ZERO)
		var distance := avatar_position.distance_to(local_position)
		if distance > nearest_distance:
			continue
		nearest_distance = distance
		nearest_block = block.duplicate(true)
		nearest_block["repair_distance"] = distance
	return nearest_block

func _enforce_run_station_ranges() -> void:
	if not multiplayer.is_server():
		return
	var released_station_labels := PackedStringArray()
	for station_id_variant in STATION_CLAIMABLE_ORDER:
		var station_id := str(station_id_variant)
		var station: Dictionary = station_state.get(station_id, {})
		var occupant_peer_id := int(station.get("occupant_peer_id", 0))
		if occupant_peer_id <= 0:
			continue
		if _peer_within_run_station_range(occupant_peer_id, station_id, _get_run_station_release_radius(station_id) - _get_run_station_claim_radius(station_id)):
			continue
		_release_station(occupant_peer_id, false)
		released_station_labels.append(get_station_label(station_id))
	if not released_station_labels.is_empty():
		_broadcast_station_state()
		_broadcast_boat_state()
		_set_status("%s lost station control after drifting out of range." % ", ".join(released_station_labels))

func _reset_run_runtime() -> void:
	driver_peer_id = 0
	_peer_inputs = {}
	_boat_broadcast_accumulator = 0.0
	_next_hazard_id = 1
	_next_loot_id = 1
	_next_runtime_chunk_id = 1
	_reset_run_avatar_state()
	_reset_reaction_runtime()
	var blueprint_stats := Dictionary(boat_blueprint.get("stats", {}))
	var max_hull_integrity := float(blueprint_stats.get("max_hull_integrity", BOAT_MAX_INTEGRITY))
	var top_speed := float(blueprint_stats.get("top_speed", BOAT_TOP_SPEED))
	var cargo_capacity := int(blueprint_stats.get("cargo_capacity", 1))
	var repair_capacity := int(blueprint_stats.get("repair_capacity", REPAIR_SUPPLIES_START))
	var brace_multiplier := float(blueprint_stats.get("brace_multiplier", 1.0))
	var launch_warning_text := _build_blueprint_warning_text()

	boat_state = {
		"position": Vector3.ZERO,
		"rotation_y": 0.0,
		"speed": 0.0,
		"throttle": 0.0,
		"steer": 0.0,
		"tick": 0,
		"driver_peer_id": 0,
		"max_hull_integrity": max_hull_integrity,
		"hull_integrity": max_hull_integrity,
		"brace_timer": 0.0,
		"brace_cooldown": 0.0,
		"repair_cooldown": 0.0,
		"base_top_speed": top_speed,
		"top_speed_limit": top_speed,
		"breach_stacks": 0,
		"last_impact_damage": 0.0,
		"last_impact_braced": false,
		"collision_count": 0,
		"cargo_capacity": cargo_capacity,
		"brace_multiplier": brace_multiplier,
		"blueprint_version": int(boat_blueprint.get("version", 1)),
		"runtime_blocks": [],
		"runtime_chunks": [],
		"sinking_chunks": [],
		"main_chunk_id": 0,
		"destroyed_block_count": 0,
		"detached_chunk_count": 0,
		"recent_damage_block_ids": [],
		"recent_detached_chunk_ids": [],
		"cargo_lost_to_sea": 0,
	}

	station_state = {}
	for station_id in STATION_ORDER:
		var layout: Dictionary = STATION_LAYOUT[station_id]
		station_state[station_id] = {
			"label": str(layout["label"]),
			"position": layout["position"],
			"occupant_peer_id": 0,
		}

	_initialize_hazards()
	_initialize_loot()
	_initialize_run_state(repair_capacity, cargo_capacity, launch_warning_text)

func _initialize_hazards() -> void:
	hazard_state = [
		_make_hazard(Vector3(2.4, 0.0, 19.5), 1.35, "Debris Cluster"),
		_make_hazard(Vector3(5.4, 0.0, 31.5), 1.25, "Broken Spar"),
		_make_hazard(Vector3(-5.5, 0.0, 46.5), 1.4, "Cargo Crate"),
	]

func _initialize_loot() -> void:
	loot_state = [
		_make_loot(Vector3(-1.05, 0.0, 10.25), 1, "Barnacled Locker"),
		_make_loot(Vector3(1.05, 0.0, 11.15), 1, "Sunken Supply Crate"),
	]

func _initialize_run_state(repair_capacity: int, cargo_capacity: int, launch_warning_text: String) -> void:
	var blueprint_stats := Dictionary(boat_blueprint.get("stats", {}))
	var seeded_layout := _build_seeded_run_layout()
	run_state = {
		"phase": "running",
		"cargo_count": 0,
		"cargo_manifest": [],
		"secured_manifest": [],
		"cargo_secured": 0,
		"loot_collected": 0,
		"loot_total": loot_state.size(),
		"loot_remaining": loot_state.size(),
		"wreck_position": Vector3(0.0, 0.0, 10.6),
		"wreck_radius": 4.1,
		"salvage_max_speed": SALVAGE_MAX_SPEED,
		"layout_label": str(seeded_layout.get("layout_label", "Wreck Push")),
		"repair_actions": 0,
		"repair_supplies": repair_capacity,
		"repair_supplies_max": repair_capacity,
		"cargo_capacity": cargo_capacity,
		"rescue_position": seeded_layout.get("rescue_position", Vector3(6.2, 0.0, 18.6)),
		"rescue_radius": float(seeded_layout.get("rescue_radius", 3.4)),
		"rescue_max_speed": float(seeded_layout.get("rescue_max_speed", RESCUE_MAX_SPEED)),
		"rescue_duration": float(seeded_layout.get("rescue_duration", RESCUE_DURATION)),
		"rescue_progress": 0.0,
		"rescue_available": true,
		"rescue_engaged": false,
		"rescue_completed": false,
		"rescue_label": str(seeded_layout.get("rescue_label", "Distress Rescue")),
		"rescue_archetype": str(seeded_layout.get("rescue_archetype", "side_lane")),
		"rescue_bonus_gold": int(seeded_layout.get("rescue_bonus_gold", RESCUE_GOLD_BONUS_MIN)),
		"rescue_bonus_salvage": int(seeded_layout.get("rescue_bonus_salvage", RESCUE_SALVAGE_BONUS_MIN)),
		"rescue_patch_kit_bonus": int(seeded_layout.get("rescue_patch_kit_bonus", RESCUE_PATCH_KIT_GRANT)),
		"cache_position": Vector3(-5.8, 0.0, 24.8),
		"cache_radius": RESUPPLY_CACHE_RADIUS,
		"cache_max_speed": RESUPPLY_CACHE_MAX_SPEED,
		"cache_available": true,
		"cache_label": "Resupply Cache",
		"cache_recovered": false,
		"squall_bands": Array(seeded_layout.get("squall_bands", [])).duplicate(true),
		"bonus_gold_bank": 0,
		"bonus_salvage_bank": 0,
		"extraction_position": Vector3(0.0, 0.0, 34.0),
		"extraction_radius": EXTRACTION_RADIUS,
		"extraction_progress": 0.0,
		"extraction_duration": EXTRACTION_DURATION,
		"reward_gold": 0,
		"reward_salvage": 0,
		"result_title": "",
		"result_message": "",
		"failure_reason": "",
		"launch_warning": launch_warning_text,
		"blueprint_version": int(boat_blueprint.get("version", 1)),
		"cargo_lost_to_sea": 0,
		"detached_chunk_count": 0,
		"destroyed_block_count": 0,
		"overboard_count": 0,
		"overboard_incidents": 0,
		"recoveries_completed": 0,
		"launch_loose_chunks": int(blueprint_stats.get("loose_blocks", 0)),
	}
	_initialize_runtime_boat_from_blueprint()

func _build_seeded_run_layout() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(run_seed) * 131 + 17
	var rescue_archetypes := [
		{
			"id": "left_detour",
			"position": Vector3(-6.4, 0.0, 18.8),
			"label": "Distress Flare",
		},
		{
			"id": "right_detour",
			"position": Vector3(6.3, 0.0, 18.4),
			"label": "Rescue Beacon",
		},
		{
			"id": "post_wreck_lane",
			"position": Vector3(4.6, 0.0, 24.2),
			"label": "Broken Skiff",
		},
	]
	var rescue_archetype: Dictionary = rescue_archetypes[int(rng.randi() % rescue_archetypes.size())]
	var rescue_position: Vector3 = rescue_archetype.get("position", Vector3(6.2, 0.0, 18.6))
	var rescue_radius := rng.randf_range(3.15, 3.8)
	var rescue_duration := rng.randf_range(1.55, 2.15)
	var rescue_bonus_gold := rng.randi_range(RESCUE_GOLD_BONUS_MIN, RESCUE_GOLD_BONUS_MAX)
	var rescue_bonus_salvage := rng.randi_range(RESCUE_SALVAGE_BONUS_MIN, RESCUE_SALVAGE_BONUS_MAX)
	var squall_bands: Array = []
	var first_half_width := rng.randf_range(4.1, 5.2)
	var first_half_depth := rng.randf_range(2.2, 3.1)
	squall_bands.append(_make_squall_band(
		1,
		Vector3(clampf(rescue_position.x * 0.45, -3.2, 3.2), 0.0, rescue_position.z + rng.randf_range(-1.6, 1.2)),
		Vector3(first_half_width, 0.0, first_half_depth),
		"Squall Front",
		rng.randf_range(SQUALL_DRAG_MIN, SQUALL_DRAG_MAX),
		rng.randf_range(SQUALL_PULSE_INTERVAL_MIN, SQUALL_PULSE_INTERVAL_MAX),
		rng.randf_range(SQUALL_PULSE_DAMAGE_MIN, SQUALL_PULSE_DAMAGE_MAX)
	))
	if bool(rng.randi() % 2):
		squall_bands.append(_make_squall_band(
			2,
			Vector3(rng.randf_range(-2.4, 2.4), 0.0, rng.randf_range(27.5, 30.8)),
			Vector3(rng.randf_range(4.0, 5.0), 0.0, rng.randf_range(2.1, 2.8)),
			"Rear Squall",
			rng.randf_range(SQUALL_DRAG_MIN, SQUALL_DRAG_MAX),
			rng.randf_range(SQUALL_PULSE_INTERVAL_MIN, SQUALL_PULSE_INTERVAL_MAX),
			rng.randf_range(SQUALL_PULSE_DAMAGE_MIN, SQUALL_PULSE_DAMAGE_MAX)
		))

	var layout_label := "%s + %d squall band%s" % [
		str(rescue_archetype.get("id", "rescue")).replace("_", " ").capitalize(),
		squall_bands.size(),
		"" if squall_bands.size() == 1 else "s",
	]
	return {
		"layout_label": layout_label,
		"rescue_archetype": str(rescue_archetype.get("id", "side_lane")),
		"rescue_position": rescue_position,
		"rescue_radius": rescue_radius,
		"rescue_duration": rescue_duration,
		"rescue_max_speed": RESCUE_MAX_SPEED,
		"rescue_label": str(rescue_archetype.get("label", "Distress Rescue")),
		"rescue_bonus_gold": rescue_bonus_gold,
		"rescue_bonus_salvage": rescue_bonus_salvage,
		"rescue_patch_kit_bonus": RESCUE_PATCH_KIT_GRANT,
		"squall_bands": squall_bands,
	}

func _make_squall_band(band_id: int, center: Vector3, half_extents: Vector3, label: String, drag_multiplier: float, pulse_interval: float, pulse_damage: float) -> Dictionary:
	return {
		"id": band_id,
		"center": center,
		"half_extents": half_extents,
		"label": label,
		"drag_multiplier": drag_multiplier,
		"pulse_interval": pulse_interval,
		"pulse_timer": pulse_interval * 0.72,
		"pulse_damage": pulse_damage,
	}

func _initialize_runtime_boat_from_blueprint() -> void:
	var runtime_blocks: Array = []
	for block_variant in Array(boat_blueprint.get("blocks", [])):
		var block: Dictionary = block_variant
		var block_type := str(block.get("type", "structure"))
		var block_def := get_builder_block_definition(block_type)
		runtime_blocks.append({
			"id": int(block.get("id", 0)),
			"type": block_type,
			"cell": _normalize_blueprint_cell(block.get("cell", [0, 0, 0])),
			"rotation_steps": wrapi(int(block.get("rotation_steps", 0)), 0, 4),
			"local_position": _block_cell_to_local_position(block.get("cell", [0, 0, 0])),
			"max_hp": float(block_def.get("max_hp", 12.0)),
			"current_hp": float(block_def.get("max_hp", 12.0)),
			"destroyed": false,
			"detached": false,
			"chunk_id": 0,
		})

	boat_state["runtime_blocks"] = runtime_blocks
	boat_state["runtime_chunks"] = []
	boat_state["sinking_chunks"] = []
	boat_state["recent_damage_block_ids"] = []
	boat_state["recent_detached_chunk_ids"] = []
	_recompute_runtime_connectivity(true, "launch_disconnect")

func _block_cell_to_local_position(cell_value: Variant) -> Vector3:
	var cell := _normalize_blueprint_cell(cell_value)
	return Vector3(float(cell[0]), float(cell[1]), float(cell[2])) * RUNTIME_BLOCK_SPACING

func _collect_active_runtime_blocks() -> Array:
	var active_blocks: Array = []
	for block_variant in Array(boat_state.get("runtime_blocks", [])):
		var block: Dictionary = block_variant
		if bool(block.get("destroyed", false)) or bool(block.get("detached", false)):
			continue
		active_blocks.append(block)
	return active_blocks

func _recompute_runtime_connectivity(initial_launch: bool = false, detached_reason: String = "detached") -> void:
	var runtime_blocks: Array = Array(boat_state.get("runtime_blocks", [])).duplicate(true)
	var active_blocks := _collect_active_runtime_blocks()
	var components := _compute_runtime_components(active_blocks)
	var previous_main_chunk_id := int(boat_state.get("main_chunk_id", 0))
	var main_component_index := -1

	for index in range(components.size()):
		var component: Dictionary = components[index]
		if bool(component.get("contains_core", false)):
			main_component_index = index
			break
	if main_component_index == -1:
		var largest_component_size := -1
		for index in range(components.size()):
			var component_size := Array(components[index].get("block_ids", [])).size()
			if component_size > largest_component_size:
				largest_component_size = component_size
				main_component_index = index

	var main_block_ids: Array = []
	var runtime_chunks: Array = []
	var detached_chunk_ids: Array = []
	for index in range(components.size()):
		var component: Dictionary = components[index]
		var chunk_id := _next_runtime_chunk_id
		_next_runtime_chunk_id += 1
		var is_main := index == main_component_index
		var block_ids := Array(component.get("block_ids", [])).duplicate(true)
		var chunk_record := {
			"chunk_id": chunk_id,
			"block_ids": block_ids,
			"contains_core": bool(component.get("contains_core", false)),
			"is_main": is_main,
			"detached": not is_main,
		}
		runtime_chunks.append(chunk_record)
		for block_index in range(runtime_blocks.size()):
			var block: Dictionary = runtime_blocks[block_index]
			if not block_ids.has(int(block.get("id", 0))):
				continue
			block["chunk_id"] = chunk_id
			runtime_blocks[block_index] = block
		if is_main:
			main_block_ids = block_ids
		else:
			detached_chunk_ids.append(chunk_id)
			runtime_blocks = _mark_runtime_blocks_detached(runtime_blocks, block_ids)
			var detached_blocks := _get_runtime_blocks_by_ids(runtime_blocks, block_ids)
			var sinking_chunk := _build_sinking_chunk_snapshot(chunk_id, detached_blocks, detached_reason, initial_launch)
			var sinking_chunks: Array = Array(boat_state.get("sinking_chunks", [])).duplicate(true)
			sinking_chunks.append(sinking_chunk)
			boat_state["sinking_chunks"] = sinking_chunks

	if main_component_index == -1 or main_block_ids.is_empty():
		boat_state["runtime_blocks"] = runtime_blocks
		boat_state["runtime_chunks"] = runtime_chunks
		boat_state["main_chunk_id"] = 0
		boat_state["destroyed_block_count"] = _count_destroyed_runtime_blocks(runtime_blocks)
		boat_state["detached_chunk_count"] = int(run_state.get("detached_chunk_count", 0)) + detached_chunk_ids.size()
		boat_state["recent_detached_chunk_ids"] = detached_chunk_ids
		run_state["detached_chunk_count"] = int(run_state.get("detached_chunk_count", 0)) + detached_chunk_ids.size()
		run_state["destroyed_block_count"] = _count_destroyed_runtime_blocks(runtime_blocks)
		_resolve_run_failure("The main hull broke apart in open water.")
		return

	boat_state["runtime_blocks"] = runtime_blocks
	boat_state["runtime_chunks"] = runtime_chunks
	boat_state["main_chunk_id"] = int(runtime_chunks[main_component_index].get("chunk_id", previous_main_chunk_id))
	boat_state["destroyed_block_count"] = _count_destroyed_runtime_blocks(runtime_blocks)
	boat_state["recent_detached_chunk_ids"] = detached_chunk_ids
	boat_state["detached_chunk_count"] = int(run_state.get("detached_chunk_count", 0)) + detached_chunk_ids.size()
	run_state["detached_chunk_count"] = int(run_state.get("detached_chunk_count", 0)) + detached_chunk_ids.size()
	run_state["destroyed_block_count"] = _count_destroyed_runtime_blocks(runtime_blocks)
	_apply_runtime_stats_from_main_blocks(runtime_blocks, main_block_ids)
	if detached_chunk_ids.size() > 0:
		_set_status(_build_detachment_status(runtime_blocks, detached_chunk_ids))

func _compute_runtime_components(active_blocks: Array) -> Array:
	var blocks_by_key := {}
	for block_variant in active_blocks:
		var block: Dictionary = block_variant
		blocks_by_key[_cell_to_key(block.get("cell", [0, 0, 0]))] = block

	var components: Array = []
	var visited := {}
	for block_variant in active_blocks:
		var block: Dictionary = block_variant
		var cell := _normalize_blueprint_cell(block.get("cell", [0, 0, 0]))
		var key := _cell_to_key(cell)
		if visited.has(key):
			continue

		var queue: Array = [cell]
		var component_block_ids: Array = []
		var contains_core := false
		visited[key] = true
		while not queue.is_empty():
			var current_cell: Array = queue.pop_front()
			var current_key := _cell_to_key(current_cell)
			var current_block: Dictionary = blocks_by_key.get(current_key, {})
			if current_block.is_empty():
				continue
			component_block_ids.append(int(current_block.get("id", 0)))
			if str(current_block.get("type", "")) == "core":
				contains_core = true
			for neighbor in _get_adjacent_cells(current_cell):
				var neighbor_key := _cell_to_key(neighbor)
				if not blocks_by_key.has(neighbor_key) or visited.has(neighbor_key):
					continue
				visited[neighbor_key] = true
				queue.append(neighbor)
		components.append({
			"block_ids": component_block_ids,
			"contains_core": contains_core,
		})
	return components

func _mark_runtime_blocks_detached(runtime_blocks: Array, block_ids: Array) -> Array:
	for index in range(runtime_blocks.size()):
		var block: Dictionary = runtime_blocks[index]
		if not block_ids.has(int(block.get("id", 0))):
			continue
		block["detached"] = true
		runtime_blocks[index] = block
	return runtime_blocks

func _get_runtime_blocks_by_ids(runtime_blocks: Array, block_ids: Array) -> Array:
	var matched_blocks: Array = []
	for block_variant in runtime_blocks:
		var block: Dictionary = block_variant
		if block_ids.has(int(block.get("id", 0))):
			matched_blocks.append(block.duplicate(true))
	return matched_blocks

func _build_sinking_chunk_snapshot(chunk_id: int, detached_blocks: Array, reason: String, launch_chunk: bool) -> Dictionary:
	var center := Vector3.ZERO
	if not detached_blocks.is_empty():
		for block_variant in detached_blocks:
			var block: Dictionary = block_variant
			var local_position: Vector3 = block.get("local_position", Vector3.ZERO)
			center += local_position
		center /= float(detached_blocks.size())

	var facing_vector := Vector3(
		sin(float(boat_state.get("rotation_y", 0.0))),
		0.0,
		cos(float(boat_state.get("rotation_y", 0.0)))
	)
	var drift_sign := -1.0 if chunk_id % 2 == 0 else 1.0
	var drift_velocity := Vector3(drift_sign * RUNTIME_SINK_DRIFT_SPEED, -RUNTIME_SINK_SPEED, RUNTIME_SINK_DRIFT_SPEED * 0.18).rotated(Vector3.UP, float(boat_state.get("rotation_y", 0.0)))
	var chunk_blocks: Array = []
	for block_variant in detached_blocks:
		var block: Dictionary = block_variant
		var local_position: Vector3 = block.get("local_position", Vector3.ZERO)
		chunk_blocks.append({
			"id": int(block.get("id", 0)),
			"type": str(block.get("type", "structure")),
			"rotation_steps": int(block.get("rotation_steps", 0)),
			"local_offset": local_position - center,
			"destroyed": bool(block.get("destroyed", false)),
		})

	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	return {
		"chunk_id": chunk_id,
		"reason": reason,
		"launch_chunk": launch_chunk,
		"world_position": boat_position + center.rotated(Vector3.UP, float(boat_state.get("rotation_y", 0.0))),
		"rotation_y": float(boat_state.get("rotation_y", 0.0)),
		"sink_elapsed": 0.0,
		"drift_velocity": drift_velocity + facing_vector * 0.12,
		"blocks": chunk_blocks,
	}

func _apply_runtime_stats_from_main_blocks(runtime_blocks: Array, main_block_ids: Array) -> void:
	var stat_source_blocks: Array = []
	for block_variant in runtime_blocks:
		var block: Dictionary = block_variant
		if block.get("destroyed", false) or block.get("detached", false):
			continue
		if main_block_ids.has(int(block.get("id", 0))):
			stat_source_blocks.append(block)

	var stats := _compute_runtime_stats_for_blocks(stat_source_blocks)
	var new_cargo_capacity := int(stats.get("cargo_capacity", 1))
	var overflow := maxi(0, int(run_state.get("cargo_count", 0)) - new_cargo_capacity)
	if overflow > 0:
		run_state["cargo_count"] = new_cargo_capacity
		run_state["cargo_lost_to_sea"] = int(run_state.get("cargo_lost_to_sea", 0)) + overflow
		_spill_inventory_quantity("cargo_manifest", overflow)

	var new_max_hull := float(stats.get("max_hull_integrity", BOAT_MAX_INTEGRITY))
	boat_state["max_hull_integrity"] = new_max_hull
	boat_state["hull_integrity"] = minf(float(boat_state.get("hull_integrity", new_max_hull)), new_max_hull)
	boat_state["base_top_speed"] = float(stats.get("top_speed", BOAT_TOP_SPEED))
	boat_state["top_speed_limit"] = float(stats.get("top_speed", BOAT_TOP_SPEED))
	boat_state["cargo_capacity"] = new_cargo_capacity
	boat_state["brace_multiplier"] = float(stats.get("brace_multiplier", 1.0))
	boat_state["active_block_count"] = int(stats.get("main_chunk_blocks", 0))
	run_state["cargo_capacity"] = new_cargo_capacity
	run_state["repair_supplies_max"] = int(stats.get("repair_capacity", REPAIR_SUPPLIES_START))
	run_state["repair_supplies"] = mini(int(run_state.get("repair_supplies", 0)), int(run_state.get("repair_supplies_max", REPAIR_SUPPLIES_START)))
	run_state["destroyed_block_count"] = _count_destroyed_runtime_blocks(runtime_blocks)

	if overflow > 0:
		_set_status("Chunk loss dumped %d cargo item(s) into the sea." % overflow)

	if float(stats.get("buoyancy_margin", 0.0)) < -0.75:
		_resolve_run_failure("The remaining hull lost too much buoyancy and sank.")

func _compute_runtime_stats_for_blocks(blocks: Array) -> Dictionary:
	var total_weight := 0.0
	var total_buoyancy := 0.0
	var total_thrust := 0.0
	var total_cargo := 0
	var total_repair := 0
	var total_brace := 0.0
	var total_hull := 0.0
	var engine_count := 0
	for block_variant in blocks:
		var block: Dictionary = block_variant
		var block_def := get_builder_block_definition(str(block.get("type", "structure")))
		total_weight += float(block_def.get("weight", 1.0))
		total_buoyancy += float(block_def.get("buoyancy", 1.0))
		total_thrust += float(block_def.get("thrust", 0.0))
		total_cargo += int(block_def.get("cargo", 0))
		total_repair += int(block_def.get("repair", 0))
		total_brace += float(block_def.get("brace", 0.0))
		total_hull += float(block_def.get("hull", 0.0))
		if float(block_def.get("thrust", 0.0)) > 0.0:
			engine_count += 1

	var block_count := blocks.size()
	var buoyancy_margin := total_buoyancy - total_weight
	var top_speed := 4.5 + total_thrust * 3.4 - maxf(0.0, total_weight - total_buoyancy * 0.78) * 0.22
	if engine_count <= 0:
		top_speed = 1.6
	top_speed = clampf(top_speed, 1.6, 24.0)
	return {
		"main_chunk_blocks": block_count,
		"buoyancy_margin": buoyancy_margin,
		"top_speed": top_speed,
		"max_hull_integrity": clampf(38.0 + total_hull * 18.0 + float(block_count) * 1.8, 20.0, 240.0),
		"cargo_capacity": maxi(1, 1 + total_cargo),
		"repair_capacity": maxi(1, mini(REPAIR_SUPPLIES_MAX + 3, REPAIR_SUPPLIES_START + total_repair)),
		"brace_multiplier": clampf(1.0 + total_brace, 1.0, 2.3),
	}

func _count_destroyed_runtime_blocks(runtime_blocks: Array) -> int:
	var count := 0
	for block_variant in runtime_blocks:
		var block: Dictionary = block_variant
		if bool(block.get("destroyed", false)):
			count += 1
	return count

func _build_detachment_status(runtime_blocks: Array, detached_chunk_ids: Array) -> String:
	var type_counts := {}
	for chunk_id in detached_chunk_ids:
		for block_variant in runtime_blocks:
			var block: Dictionary = block_variant
			if int(block.get("chunk_id", 0)) != chunk_id or not bool(block.get("detached", false)):
				continue
			var block_type := str(block.get("type", "structure"))
			type_counts[block_type] = int(type_counts.get(block_type, 0)) + 1

	var fragments := PackedStringArray()
	for block_type in type_counts.keys():
		var label := str(get_builder_block_definition(str(block_type)).get("label", str(block_type).capitalize()))
		fragments.append("%s x%d" % [label, int(type_counts[block_type])])
	return "Chunk detached: %s." % ", ".join(fragments)

func _update_sinking_chunks(delta: float) -> void:
	var sinking_chunks: Array = Array(boat_state.get("sinking_chunks", [])).duplicate(true)
	var updated_chunks: Array = []
	for chunk_variant in sinking_chunks:
		var chunk: Dictionary = chunk_variant
		var sink_elapsed := float(chunk.get("sink_elapsed", 0.0)) + delta
		if sink_elapsed >= RUNTIME_SINK_LIFETIME:
			continue
		chunk["sink_elapsed"] = sink_elapsed
		var world_position: Vector3 = chunk.get("world_position", Vector3.ZERO)
		var drift_velocity: Vector3 = chunk.get("drift_velocity", Vector3.ZERO)
		chunk["world_position"] = world_position + drift_velocity * delta
		updated_chunks.append(chunk)
	boat_state["sinking_chunks"] = updated_chunks

func _apply_localized_block_damage(total_damage: float, impact_point_local: Vector3, event_label: String) -> bool:
	var runtime_blocks: Array = Array(boat_state.get("runtime_blocks", [])).duplicate(true)
	var candidate_entries: Array = []
	for block_variant in runtime_blocks:
		var block: Dictionary = block_variant
		if bool(block.get("destroyed", false)) or bool(block.get("detached", false)):
			continue
		var local_position: Vector3 = block.get("local_position", Vector3.ZERO)
		var distance := local_position.distance_to(impact_point_local)
		if distance > RUNTIME_DAMAGE_CLUSTER_RADIUS:
			continue
		candidate_entries.append({
			"id": int(block.get("id", 0)),
			"distance": distance,
		})

	if candidate_entries.is_empty():
		var nearest_id := 0
		var nearest_distance := INF
		for block_variant in runtime_blocks:
			var block: Dictionary = block_variant
			if bool(block.get("destroyed", false)) or bool(block.get("detached", false)):
				continue
			var local_position: Vector3 = block.get("local_position", Vector3.ZERO)
			var distance := local_position.distance_to(impact_point_local)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_id = int(block.get("id", 0))
		if nearest_id > 0:
			candidate_entries.append({
				"id": nearest_id,
				"distance": nearest_distance,
			})

	candidate_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("distance", 0.0)) < float(b.get("distance", 0.0))
	)

	var hit_block_ids: Array = []
	var destroyed_now := false
	var max_hits := mini(candidate_entries.size(), RUNTIME_DAMAGE_CLUSTER_WEIGHTS.size())
	for hit_index in range(max_hits):
		var entry: Dictionary = candidate_entries[hit_index]
		var block_id := int(entry.get("id", 0))
		var weight := float(RUNTIME_DAMAGE_CLUSTER_WEIGHTS[hit_index])
		for runtime_index in range(runtime_blocks.size()):
			var block: Dictionary = runtime_blocks[runtime_index]
			if int(block.get("id", 0)) != block_id:
				continue
			block["current_hp"] = maxf(0.0, float(block.get("current_hp", 0.0)) - total_damage * weight)
			if float(block.get("current_hp", 0.0)) <= 0.0:
				block["destroyed"] = true
				destroyed_now = true
			runtime_blocks[runtime_index] = block
			hit_block_ids.append(block_id)
			break

	boat_state["runtime_blocks"] = runtime_blocks
	boat_state["recent_damage_block_ids"] = hit_block_ids
	if destroyed_now:
		_recompute_runtime_connectivity(false, event_label)
	else:
		boat_state["recent_detached_chunk_ids"] = []
		boat_state["destroyed_block_count"] = _count_destroyed_runtime_blocks(runtime_blocks)
		run_state["destroyed_block_count"] = int(boat_state.get("destroyed_block_count", 0))
	return str(run_state.get("phase", "running")) == "running"

func _heal_runtime_blocks(total_heal: float) -> void:
	var runtime_blocks: Array = Array(boat_state.get("runtime_blocks", [])).duplicate(true)
	var damaged_blocks: Array = []
	for block_variant in runtime_blocks:
		var block: Dictionary = block_variant
		if bool(block.get("destroyed", false)) or bool(block.get("detached", false)):
			continue
		if float(block.get("current_hp", 0.0)) >= float(block.get("max_hp", 0.0)):
			continue
		damaged_blocks.append(block.duplicate(true))

	damaged_blocks.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("current_hp", 0.0)) < float(b.get("current_hp", 0.0))
	)

	var remaining_heal := total_heal
	for damaged_block_variant in damaged_blocks:
		if remaining_heal <= 0.0:
			break
		var damaged_block: Dictionary = damaged_block_variant
		var block_id := int(damaged_block.get("id", 0))
		for runtime_index in range(runtime_blocks.size()):
			var block: Dictionary = runtime_blocks[runtime_index]
			if int(block.get("id", 0)) != block_id:
				continue
			var missing_hp := float(block.get("max_hp", 0.0)) - float(block.get("current_hp", 0.0))
			var applied_heal := minf(missing_hp, remaining_heal)
			block["current_hp"] = float(block.get("current_hp", 0.0)) + applied_heal
			runtime_blocks[runtime_index] = block
			remaining_heal -= applied_heal
			break

	boat_state["runtime_blocks"] = runtime_blocks

func _heal_runtime_blocks_around(center_local: Vector3, total_heal: float) -> void:
	var runtime_blocks: Array = Array(boat_state.get("runtime_blocks", [])).duplicate(true)
	var damaged_blocks: Array = []
	for block_variant in runtime_blocks:
		var block: Dictionary = block_variant
		if bool(block.get("destroyed", false)) or bool(block.get("detached", false)):
			continue
		var max_hp := float(block.get("max_hp", 0.0))
		var current_hp := float(block.get("current_hp", max_hp))
		if current_hp >= max_hp - 0.01:
			continue
		var distance := center_local.distance_to(block.get("local_position", Vector3.ZERO))
		if distance > RUN_REPAIR_HEAL_RADIUS:
			continue
		var block_copy := block.duplicate(true)
		block_copy["repair_distance"] = distance
		damaged_blocks.append(block_copy)

	if damaged_blocks.is_empty():
		_heal_runtime_blocks(total_heal)
		return

	damaged_blocks.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("repair_distance", 0.0)) < float(b.get("repair_distance", 0.0))
	)

	var remaining_heal := total_heal
	for damaged_block_variant in damaged_blocks:
		if remaining_heal <= 0.0:
			break
		var damaged_block: Dictionary = damaged_block_variant
		var block_id := int(damaged_block.get("id", 0))
		for runtime_index in range(runtime_blocks.size()):
			var block: Dictionary = runtime_blocks[runtime_index]
			if int(block.get("id", 0)) != block_id:
				continue
			var missing_hp := float(block.get("max_hp", 0.0)) - float(block.get("current_hp", 0.0))
			var applied_heal := minf(missing_hp, remaining_heal)
			block["current_hp"] = float(block.get("current_hp", 0.0)) + applied_heal
			runtime_blocks[runtime_index] = block
			remaining_heal -= applied_heal
			break

	boat_state["runtime_blocks"] = runtime_blocks

func _launch_run_session(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	if session_phase != SESSION_PHASE_HANGAR:
		return

	_reset_run_runtime()
	_set_session_phase(SESSION_PHASE_RUN)
	_reset_connected_run_avatars()
	_broadcast_boat_state()
	_broadcast_hazard_state()
	_broadcast_station_state()
	_broadcast_loot_state()
	_broadcast_run_state()
	_broadcast_run_avatar_state()
	_broadcast_reaction_state()
	_broadcast_runtime_boat_state()
	_set_status("Run launched by %s using blueprint v%d." % [
		_get_peer_name(peer_id),
		int(boat_blueprint.get("version", 1)),
	])

func _return_to_hangar_session(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	if session_phase != SESSION_PHASE_RUN:
		return
	if str(run_state.get("phase", "running")) == "running":
		return

	_reset_run_runtime()
	_reset_connected_hangar_avatars()
	_set_session_phase(SESSION_PHASE_HANGAR)
	_broadcast_boat_state()
	_broadcast_hazard_state()
	_broadcast_station_state()
	_broadcast_loot_state()
	_broadcast_run_state()
	_broadcast_run_avatar_state()
	_broadcast_reaction_state()
	_set_status("%s returned the crew to the hangar." % _get_peer_name(peer_id))

func _unlock_builder_block(peer_id: int, block_type: String) -> void:
	if not multiplayer.is_server():
		return
	if session_phase != SESSION_PHASE_HANGAR:
		return
	if not BUILDER_BLOCK_LIBRARY.has(block_type):
		return
	if _is_block_unlocked(block_type):
		return

	var block_def := get_builder_block_definition(block_type)
	if not bool(block_def.get("unlockable", false)):
		return

	var unlock_cost_gold: int = maxi(0, int(block_def.get("unlock_cost_gold", 0)))
	var unlock_cost_salvage: int = maxi(0, int(block_def.get("unlock_cost_salvage", 0)))
	var unlock_result: Dictionary = DockState.unlock_block(
		block_type,
		unlock_cost_gold,
		unlock_cost_salvage,
		str(block_def.get("label", block_type.capitalize())),
		str(block_def.get("description", ""))
	)
	if unlock_result.is_empty():
		return

	progression_state = _decorate_progression_snapshot(DockState.get_profile_snapshot())
	_broadcast_progression_state()
	_set_status("%s unlocked %s for %d gold and %d salvage." % [
		_get_peer_name(peer_id),
		str(block_def.get("label", block_type.capitalize())),
		unlock_cost_gold,
		unlock_cost_salvage,
	])

func _place_blueprint_block(peer_id: int, cell: Array, block_type: String, rotation_steps: int) -> void:
	if not multiplayer.is_server():
		return
	if session_phase != SESSION_PHASE_HANGAR:
		return
	if not _cell_within_builder_bounds(cell):
		return
	if not _peer_within_builder_range(peer_id, cell):
		return
	if not BUILDER_BLOCK_LIBRARY.has(block_type):
		return
	if not _is_block_unlocked(block_type):
		return

	var persisted := _extract_persisted_blueprint(boat_blueprint)
	var blocks: Array = Array(persisted.get("blocks", [])).duplicate(true)
	if _find_block_index_by_cell(blocks, cell) != -1:
		return

	var next_block_id := int(persisted.get("next_block_id", 1))
	blocks.append({
		"id": next_block_id,
		"type": block_type,
		"cell": _normalize_blueprint_cell(cell),
		"rotation_steps": wrapi(rotation_steps, 0, 4),
	})
	persisted["blocks"] = blocks
	persisted["next_block_id"] = next_block_id + 1
	persisted["version"] = int(persisted.get("version", 1)) + 1
	boat_blueprint = _decorate_blueprint(persisted)
	_save_server_blueprint()
	_broadcast_blueprint_state()
	_set_status("%s placed %s at %s." % [
		_get_peer_name(peer_id),
		get_builder_block_definition(block_type).get("label", block_type.capitalize()),
		str(_cell_to_vector3i(cell)),
	])

func _remove_blueprint_block(peer_id: int, cell: Array) -> void:
	if not multiplayer.is_server():
		return
	if session_phase != SESSION_PHASE_HANGAR:
		return
	if not _peer_within_builder_range(peer_id, cell):
		return

	var persisted := _extract_persisted_blueprint(boat_blueprint)
	var blocks: Array = Array(persisted.get("blocks", [])).duplicate(true)
	var block_index := _find_block_index_by_cell(blocks, cell)
	if block_index == -1:
		return
	if blocks.size() <= 1:
		return

	var removed_block: Dictionary = blocks[block_index]
	blocks.remove_at(block_index)
	persisted["blocks"] = blocks
	persisted["version"] = int(persisted.get("version", 1)) + 1
	boat_blueprint = _decorate_blueprint(persisted)
	_save_server_blueprint()
	_broadcast_blueprint_state()
	_set_status("%s removed %s from %s." % [
		_get_peer_name(peer_id),
		get_builder_block_definition(str(removed_block.get("type", "structure"))).get("label", "Block"),
		str(_cell_to_vector3i(cell)),
	])

func _save_server_blueprint() -> void:
	if multiplayer.is_server():
		DockState.save_boat_blueprint(_extract_persisted_blueprint(boat_blueprint))

func _extract_persisted_blueprint(snapshot: Dictionary) -> Dictionary:
	return {
		"version": int(snapshot.get("version", 1)),
		"next_block_id": int(snapshot.get("next_block_id", 1)),
		"blocks": Array(snapshot.get("blocks", [])).duplicate(true),
	}

func _decorate_progression_snapshot(snapshot: Dictionary) -> Dictionary:
	var normalized := {
		"total_gold": max(0, int(snapshot.get("total_gold", 0))),
		"total_salvage": max(0, int(snapshot.get("total_salvage", 0))),
		"total_runs": max(0, int(snapshot.get("total_runs", 0))),
		"successful_runs": max(0, int(snapshot.get("successful_runs", 0))),
		"last_run": {},
		"last_unlock": {},
		"unlocked_blocks": [],
	}
	var last_run_variant: Variant = snapshot.get("last_run", {})
	if typeof(last_run_variant) == TYPE_DICTIONARY:
		normalized["last_run"] = Dictionary(last_run_variant).duplicate(true)
	var last_unlock_variant: Variant = snapshot.get("last_unlock", {})
	if typeof(last_unlock_variant) == TYPE_DICTIONARY:
		normalized["last_unlock"] = Dictionary(last_unlock_variant).duplicate(true)

	var unlocked_lookup := {}
	for base_block_variant in _get_default_unlocked_block_ids():
		var base_block_id := str(base_block_variant)
		unlocked_lookup[base_block_id] = true
	for block_value in Array(snapshot.get("unlocked_blocks", [])):
		var block_id := str(block_value).strip_edges().to_lower()
		if block_id.is_empty() or not BUILDER_BLOCK_LIBRARY.has(block_id):
			continue
		unlocked_lookup[block_id] = true

	var ordered_unlocked_blocks: Array = []
	for block_id_variant in BUILDER_BLOCK_ORDER:
		var ordered_block_id := str(block_id_variant)
		if unlocked_lookup.has(ordered_block_id):
			ordered_unlocked_blocks.append(ordered_block_id)
	normalized["unlocked_blocks"] = ordered_unlocked_blocks
	return normalized

func _get_default_unlocked_block_ids() -> Array:
	var block_ids: Array = []
	for block_id_variant in BUILDER_BLOCK_ORDER:
		var block_id := str(block_id_variant)
		var block_def := Dictionary(BUILDER_BLOCK_LIBRARY.get(block_id, {}))
		if bool(block_def.get("unlockable", false)):
			continue
		block_ids.append(block_id)
	return block_ids

func _get_unlocked_block_lookup() -> Dictionary:
	var unlocked_lookup := {}
	for block_id_variant in Array(progression_state.get("unlocked_blocks", [])):
		var block_id := str(block_id_variant)
		if block_id.is_empty():
			continue
		unlocked_lookup[block_id] = true
	return unlocked_lookup

func _is_block_unlocked(block_type: String) -> bool:
	return _get_unlocked_block_lookup().has(block_type.strip_edges().to_lower())

func _decorate_blueprint(snapshot: Dictionary) -> Dictionary:
	var normalized := _normalize_blueprint(snapshot)
	var blocks: Array = Array(normalized.get("blocks", []))
	var blocks_by_key := {}
	var blocks_by_id := {}
	var component_entries: Array = []
	for block_variant in blocks:
		var block: Dictionary = block_variant
		var key := _cell_to_key(block.get("cell", [0, 0, 0]))
		blocks_by_key[key] = block
		blocks_by_id[int(block.get("id", 0))] = block

	var visited := {}
	for block_variant in blocks:
		var block: Dictionary = block_variant
		var cell := _normalize_blueprint_cell(block.get("cell", [0, 0, 0]))
		var key := _cell_to_key(cell)
		if visited.has(key):
			continue

		var queue: Array = [cell]
		var component_block_ids: Array = []
		var contains_core := false
		visited[key] = true
		while not queue.is_empty():
			var current_cell: Array = queue.pop_front()
			var current_key := _cell_to_key(current_cell)
			var current_block: Dictionary = blocks_by_key.get(current_key, {})
			if current_block.is_empty():
				continue
			component_block_ids.append(int(current_block.get("id", 0)))
			if str(current_block.get("type", "")) == "core":
				contains_core = true
			for neighbor in _get_adjacent_cells(current_cell):
				var neighbor_key := _cell_to_key(neighbor)
				if not blocks_by_key.has(neighbor_key) or visited.has(neighbor_key):
					continue
				visited[neighbor_key] = true
				queue.append(neighbor)
		component_entries.append({
			"block_ids": component_block_ids,
			"contains_core": contains_core,
		})

	var main_component: Dictionary = {}
	for component in component_entries:
		if bool(component.get("contains_core", false)):
			main_component = component
			break
	if main_component.is_empty():
		for component in component_entries:
			if Array(component.get("block_ids", [])).size() > Array(main_component.get("block_ids", [])).size():
				main_component = component

	var main_block_ids: Array = Array(main_component.get("block_ids", [])).duplicate(true)
	var loose_block_ids: Array = []
	for block_variant in blocks:
		var block: Dictionary = block_variant
		if main_block_ids.has(int(block.get("id", 0))):
			continue
		loose_block_ids.append(int(block.get("id", 0)))

	var block_counts := {}
	var total_weight := 0.0
	var total_buoyancy := 0.0
	var total_thrust := 0.0
	var total_cargo := 0
	var total_repair := 0
	var total_brace := 0.0
	var total_hull := 0.0
	var propulsion_count := 0
	for block_id in main_block_ids:
		var block: Dictionary = blocks_by_id.get(int(block_id), {})
		var block_type := str(block.get("type", "structure"))
		var block_def := get_builder_block_definition(block_type)
		block_counts[block_type] = int(block_counts.get(block_type, 0)) + 1
		total_weight += float(block_def.get("weight", 1.0))
		total_buoyancy += float(block_def.get("buoyancy", 1.0))
		total_thrust += float(block_def.get("thrust", 0.0))
		total_cargo += int(block_def.get("cargo", 0))
		total_repair += int(block_def.get("repair", 0))
		total_brace += float(block_def.get("brace", 0.0))
		total_hull += float(block_def.get("hull", 0.0))
		if float(block_def.get("thrust", 0.0)) > 0.0:
			propulsion_count += 1

	var main_block_count := main_block_ids.size()
	var engine_count := propulsion_count
	var buoyancy_margin := total_buoyancy - total_weight
	var top_speed := 4.5 + total_thrust * 3.4 - maxf(0.0, total_weight - total_buoyancy * 0.78) * 0.22
	if engine_count <= 0:
		top_speed = 1.8
	top_speed = clampf(top_speed, 1.8, 24.0)
	var max_hull_integrity := clampf(38.0 + total_hull * 18.0 + float(main_block_count) * 1.8, 40.0, 240.0)
	var cargo_capacity := maxi(1, 1 + total_cargo)
	var repair_capacity := maxi(1, mini(REPAIR_SUPPLIES_MAX + 3, REPAIR_SUPPLIES_START + total_repair))
	var brace_multiplier := clampf(1.0 + total_brace, 1.0, 2.3)
	var seaworthy := main_block_count > 0 and engine_count > 0 and buoyancy_margin >= -1.2

	var warnings: Array = []
	if loose_block_ids.size() > 0:
		warnings.append("%d disconnected block(s) will spawn loose and sink at launch." % loose_block_ids.size())
	if engine_count <= 0:
		warnings.append("The main chunk has no engine, so the run boat will barely move.")
	if buoyancy_margin < 0.0:
		warnings.append("The main chunk is overweight and may fail once it starts taking damage.")
	elif buoyancy_margin < 2.0:
		warnings.append("The main chunk has a thin buoyancy margin. Extra hits will matter.")
	if cargo_capacity <= 1:
		warnings.append("Cargo space is minimal. Add cargo blocks to haul more salvage per run.")

	normalized["stats"] = {
		"block_count": blocks.size(),
		"main_chunk_blocks": main_block_count,
		"loose_blocks": loose_block_ids.size(),
		"component_count": component_entries.size(),
		"block_counts": block_counts,
		"weight": total_weight,
		"buoyancy": total_buoyancy,
		"buoyancy_margin": buoyancy_margin,
		"top_speed": top_speed,
		"max_hull_integrity": max_hull_integrity,
		"cargo_capacity": cargo_capacity,
		"repair_capacity": repair_capacity,
		"brace_multiplier": brace_multiplier,
		"engine_count": engine_count,
	}
	normalized["warnings"] = warnings
	normalized["seaworthy"] = seaworthy
	normalized["main_chunk_block_ids"] = main_block_ids
	normalized["loose_block_ids"] = loose_block_ids
	return normalized

func _normalize_blueprint(snapshot: Dictionary) -> Dictionary:
	var normalized := {
		"version": maxi(1, int(snapshot.get("version", 1))),
		"next_block_id": maxi(1, int(snapshot.get("next_block_id", 1))),
		"blocks": [],
	}
	var normalized_blocks: Array = []
	var seen_cells := {}
	var next_block_id := int(normalized.get("next_block_id", 1))

	for block_variant in Array(snapshot.get("blocks", [])):
		if typeof(block_variant) != TYPE_DICTIONARY:
			continue
		var block: Dictionary = block_variant
		var block_type := str(block.get("type", "structure")).strip_edges().to_lower()
		if not BUILDER_BLOCK_LIBRARY.has(block_type):
			continue
		var block_id := int(block.get("id", 0))
		if block_id <= 0:
			block_id = next_block_id
			next_block_id += 1
		var cell := _normalize_blueprint_cell(block.get("cell", [0, 0, 0]))
		if not _cell_within_builder_bounds(cell):
			continue
		var cell_key := _cell_to_key(cell)
		if seen_cells.has(cell_key):
			continue
		seen_cells[cell_key] = true
		normalized_blocks.append({
			"id": block_id,
			"type": block_type,
			"cell": cell,
			"rotation_steps": wrapi(int(block.get("rotation_steps", 0)), 0, 4),
		})
		next_block_id = maxi(next_block_id, block_id + 1)

	if normalized_blocks.is_empty():
		normalized_blocks = Array(DockState.get_boat_blueprint().get("blocks", [])).duplicate(true)
		next_block_id = maxi(next_block_id, int(DockState.get_boat_blueprint().get("next_block_id", 1)))

	normalized["blocks"] = normalized_blocks
	normalized["next_block_id"] = next_block_id
	return normalized

func _build_blueprint_warning_text() -> String:
	var warnings := get_blueprint_warnings()
	if warnings.is_empty():
		return ""
	var lines := PackedStringArray()
	for warning in warnings:
		lines.append(str(warning))
	return "\n".join(lines)

func _normalize_blueprint_cell(cell_value: Variant) -> Array:
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

func _cell_within_builder_bounds(cell: Array) -> bool:
	var cell_vec := _cell_to_vector3i(cell)
	return cell_vec.x >= BUILDER_BOUNDS_MIN.x and cell_vec.x <= BUILDER_BOUNDS_MAX.x and cell_vec.y >= BUILDER_BOUNDS_MIN.y and cell_vec.y <= BUILDER_BOUNDS_MAX.y and cell_vec.z >= BUILDER_BOUNDS_MIN.z and cell_vec.z <= BUILDER_BOUNDS_MAX.z

func _builder_cell_to_world_position(cell_value: Variant) -> Vector3:
	var cell_vec := _cell_to_vector3i(cell_value)
	return BUILDER_WORLD_ORIGIN + Vector3(cell_vec) * BUILDER_CELL_SIZE

func _peer_within_builder_range(peer_id: int, cell: Array) -> bool:
	if peer_id <= 0:
		return false
	var avatar_state: Dictionary = hangar_avatar_state.get(peer_id, {})
	if avatar_state.is_empty():
		return false
	var avatar_position: Vector3 = avatar_state.get("position", Vector3.ZERO)
	return avatar_position.distance_to(_builder_cell_to_world_position(cell)) <= (HANGAR_BUILD_RANGE + 0.35)

func _cell_to_key(cell_value: Variant) -> String:
	var cell := _normalize_blueprint_cell(cell_value)
	return "%d:%d:%d" % [int(cell[0]), int(cell[1]), int(cell[2])]

func _cell_to_vector3i(cell_value: Variant) -> Vector3i:
	var cell := _normalize_blueprint_cell(cell_value)
	return Vector3i(int(cell[0]), int(cell[1]), int(cell[2]))

func _get_adjacent_cells(cell_value: Variant) -> Array:
	var cell_vec := _cell_to_vector3i(cell_value)
	return [
		[cell_vec.x + 1, cell_vec.y, cell_vec.z],
		[cell_vec.x - 1, cell_vec.y, cell_vec.z],
		[cell_vec.x, cell_vec.y + 1, cell_vec.z],
		[cell_vec.x, cell_vec.y - 1, cell_vec.z],
		[cell_vec.x, cell_vec.y, cell_vec.z + 1],
		[cell_vec.x, cell_vec.y, cell_vec.z - 1],
	]

func _find_block_index_by_cell(blocks: Array, cell_value: Variant) -> int:
	var target_key := _cell_to_key(cell_value)
	for index in range(blocks.size()):
		var block: Dictionary = blocks[index]
		if _cell_to_key(block.get("cell", [0, 0, 0])) == target_key:
			return index
	return -1

func _set_session_phase(next_phase: String) -> void:
	if session_phase == next_phase:
		return
	session_phase = next_phase
	_broadcast_session_phase()

func _get_peer_name(peer_id: int) -> String:
	var peer_data: Dictionary = peer_snapshot.get(peer_id, {})
	return str(peer_data.get("name", "Peer %d" % peer_id))

func _make_hazard(position: Vector3, radius: float, label: String) -> Dictionary:
	var hazard_id: int = _next_hazard_id
	_next_hazard_id += 1
	return {
		"id": hazard_id,
		"position": position,
		"radius": radius,
		"label": label,
	}

func _make_loot(position: Vector3, value: int, label: String, requires_brace: bool = true) -> Dictionary:
	var loot_id: int = _next_loot_id
	_next_loot_id += 1
	return {
		"id": loot_id,
		"position": position,
		"value": value,
		"label": label,
		"requires_brace": requires_brace,
	}

func _set_driver(peer_id: int, broadcast: bool = true) -> void:
	if driver_peer_id == peer_id:
		return

	driver_peer_id = peer_id
	boat_state["driver_peer_id"] = driver_peer_id
	if driver_peer_id == 0:
		boat_state["throttle"] = 0.0
		boat_state["steer"] = 0.0
		boat_state["speed"] = 0.0
	emit_signal("helm_changed", driver_peer_id)
	if broadcast:
		_broadcast_boat_state()

func _claim_station(peer_id: int, station_id: String) -> void:
	if session_phase != SESSION_PHASE_RUN:
		return
	if not station_state.has(station_id):
		return
	if not _is_station_claimable(station_id):
		return
	if str(run_state.get("phase", "running")) != "running":
		return
	if _peer_has_reaction_lock(peer_id):
		return
	if not _peer_within_run_station_range(peer_id, station_id):
		return

	var station: Dictionary = station_state.get(station_id, {})
	var occupant_peer_id := int(station.get("occupant_peer_id", 0))
	if occupant_peer_id != 0 and occupant_peer_id != peer_id:
		return

	var current_station_id := get_peer_station_id(peer_id)
	if current_station_id == station_id:
		return

	if not current_station_id.is_empty():
		_release_station(peer_id, false)

	station["occupant_peer_id"] = peer_id
	station_state[station_id] = station
	if station_id == "helm":
		_set_driver(peer_id, false)

	_broadcast_station_state()
	_broadcast_boat_state()
	_set_status("%s claimed by %s." % [get_station_label(station_id), get_station_occupant_name(station_id)])

func _release_station(peer_id: int, broadcast: bool = true) -> void:
	var current_station_id := get_peer_station_id(peer_id)
	if current_station_id.is_empty():
		return

	var station: Dictionary = station_state.get(current_station_id, {})
	station["occupant_peer_id"] = 0
	station_state[current_station_id] = station
	if current_station_id == "helm" and driver_peer_id == peer_id:
		_set_driver(0, false)

	if broadcast:
		_broadcast_station_state()
		_broadcast_boat_state()

func _receive_boat_input(peer_id: int, throttle: float, steer: float) -> void:
	if session_phase != SESSION_PHASE_RUN:
		return
	if str(run_state.get("phase", "running")) != "running":
		return
	if _is_peer_overboard(peer_id):
		_peer_inputs[peer_id] = {
			"throttle": 0.0,
			"steer": 0.0,
		}
		return
	if _peer_has_reaction_lock(peer_id):
		_peer_inputs[peer_id] = {
			"throttle": 0.0,
			"steer": 0.0,
		}
		return
	if peer_id != driver_peer_id:
		return
	if get_peer_station_id(peer_id) != "helm":
		return
	if not _peer_within_run_station_range(peer_id, "helm", RUN_HELM_RELEASE_RADIUS - RUN_HELM_ZONE_RADIUS):
		_release_station(peer_id)
		return

	_peer_inputs[peer_id] = {
		"throttle": throttle,
		"steer": steer,
	}

func _begin_brace(peer_id: int) -> void:
	if session_phase != SESSION_PHASE_RUN:
		return
	if str(run_state.get("phase", "running")) != "running":
		return
	if _peer_has_reaction_lock(peer_id):
		return
	if not run_avatar_state.has(peer_id):
		return
	if _is_peer_overboard(peer_id):
		return
	if float(boat_state.get("brace_cooldown", 0.0)) > 0.0:
		return

	boat_state["brace_timer"] = BRACE_ACTIVE_SECONDS
	boat_state["brace_cooldown"] = BRACE_COOLDOWN_SECONDS
	_broadcast_boat_state()
	_set_status("%s braced for impact." % _get_peer_name(peer_id))

func _process_repair(peer_id: int) -> void:
	if session_phase != SESSION_PHASE_RUN:
		return
	if str(run_state.get("phase", "running")) != "running":
		return
	if _peer_has_reaction_lock(peer_id):
		return
	if _is_peer_overboard(peer_id):
		return
	if float(boat_state.get("repair_cooldown", 0.0)) > 0.0:
		return
	if int(run_state.get("repair_supplies", 0)) <= 0:
		_set_status("The crew is out of patch kits.")
		return

	var breach_stacks := int(boat_state.get("breach_stacks", 0))
	var hull_integrity: float = float(boat_state.get("hull_integrity", BOAT_MAX_INTEGRITY))
	var max_hull_integrity: float = float(boat_state.get("max_hull_integrity", BOAT_MAX_INTEGRITY))
	if breach_stacks <= 0 and hull_integrity >= max_hull_integrity - 0.1:
		return
	var repair_target := _find_nearest_repairable_block(peer_id)
	if repair_target.is_empty():
		_set_status("%s needs to move closer to the damaged hull to patch it." % _get_peer_name(peer_id))
		return

	boat_state["breach_stacks"] = maxi(0, breach_stacks - 1)
	boat_state["hull_integrity"] = minf(max_hull_integrity, hull_integrity + REPAIR_HULL_RECOVERY)
	boat_state["repair_cooldown"] = REPAIR_COOLDOWN_SECONDS
	run_state["repair_actions"] = int(run_state.get("repair_actions", 0)) + 1
	run_state["repair_supplies"] = maxi(0, int(run_state.get("repair_supplies", 0)) - 1)
	_heal_runtime_blocks_around(repair_target.get("local_position", Vector3.ZERO), REPAIR_HULL_RECOVERY)
	_broadcast_runtime_boat_state()
	_broadcast_boat_state()
	_broadcast_run_state()
	_set_status("%s patched the hull. %d patch kit(s) left." % [
		_get_peer_name(peer_id),
		int(run_state.get("repair_supplies", 0)),
	])

func _process_grapple(peer_id: int) -> void:
	if session_phase != SESSION_PHASE_RUN:
		return
	if str(run_state.get("phase", "running")) != "running":
		return
	if _peer_has_reaction_lock(peer_id):
		return
	if _is_peer_overboard(peer_id):
		return
	if get_peer_station_id(peer_id) != "grapple":
		return
	if _process_rescue_grapple():
		return
	if _process_resupply_cache_grapple():
		return
	if loot_state.is_empty():
		return

	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	var wreck_position: Vector3 = run_state.get("wreck_position", Vector3.ZERO)
	var wreck_radius: float = float(run_state.get("wreck_radius", 4.1))
	if boat_position.distance_to(wreck_position) > wreck_radius:
		_set_status("Bring the boat into the wreck ring before grappling salvage.")
		return
	if absf(float(boat_state.get("speed", 0.0))) > SALVAGE_MAX_SPEED:
		_set_status("Slow the boat down before attempting wreck salvage.")
		return

	var grapple_position := _get_station_world_position("grapple")
	var closest_index := -1
	var closest_distance := GRAPPLE_RANGE
	for index in range(loot_state.size()):
		var loot_target: Dictionary = loot_state[index]
		var loot_position: Vector3 = loot_target.get("position", Vector3.ZERO)
		var distance := grapple_position.distance_to(loot_position)
		if distance <= closest_distance:
			closest_distance = distance
			closest_index = index

	if closest_index == -1:
		return

	var loot_target: Dictionary = loot_state[closest_index]
	var cargo_value := int(loot_target.get("value", 1))
	var cargo_capacity := int(run_state.get("cargo_capacity", int(boat_state.get("cargo_capacity", 1))))
	if int(run_state.get("cargo_count", 0)) + cargo_value > cargo_capacity:
		_set_status("Cargo hold is full. Expand the shared boat before hauling more salvage.")
		return
	var requires_brace := bool(loot_target.get("requires_brace", true))
	var was_braced := float(boat_state.get("brace_timer", 0.0)) > 0.0
	run_state["cargo_count"] = int(run_state.get("cargo_count", 0)) + cargo_value
	_append_inventory_entry(
		"cargo_manifest",
		str(loot_target.get("label", "Recovered Cargo")),
		cargo_value,
		"cargo",
		"Wreck salvage"
	)
	run_state["loot_collected"] = int(run_state.get("loot_collected", 0)) + 1
	loot_state.remove_at(closest_index)
	run_state["loot_remaining"] = loot_state.size()

	if requires_brace:
		boat_state["brace_timer"] = 0.0
		if was_braced:
			boat_state["last_impact_damage"] = 0.0
			boat_state["last_impact_braced"] = true
			_apply_run_impact_reactions(
				Vector3.BACK.rotated(Vector3.UP, float(boat_state.get("rotation_y", 0.0))),
				0.24,
				true,
				false,
				"grapple"
			)
		else:
			var grapple_impact_local := get_station_position("grapple") + Vector3(0.0, 0.0, 0.55)
			var run_continues := _apply_localized_block_damage(SALVAGE_BACKLASH_DAMAGE, grapple_impact_local, "salvage_backlash")
			_broadcast_runtime_boat_state()
			if not run_continues:
				_broadcast_loot_state()
				_broadcast_run_state()
				_broadcast_boat_state()
				return
			boat_state["hull_integrity"] = maxf(0.0, float(boat_state.get("hull_integrity", BOAT_MAX_INTEGRITY)) - SALVAGE_BACKLASH_DAMAGE)
			boat_state["last_impact_damage"] = SALVAGE_BACKLASH_DAMAGE
			boat_state["last_impact_braced"] = false
			boat_state["breach_stacks"] = mini(MAX_BREACH_STACKS, int(boat_state.get("breach_stacks", 0)) + SALVAGE_BACKLASH_BREACHES)
			_apply_run_impact_reactions(
				Vector3.BACK.rotated(Vector3.UP, float(boat_state.get("rotation_y", 0.0))),
				0.74,
				false,
				false,
				"grapple"
			)
			if float(boat_state.get("hull_integrity", BOAT_MAX_INTEGRITY)) <= 0.0:
				_broadcast_loot_state()
				_broadcast_run_state()
				_broadcast_boat_state()
				_resolve_run_failure("The salvage surge tore the hull apart.")
				return

	_broadcast_loot_state()
	_broadcast_run_state()
	_broadcast_boat_state()
	if requires_brace and not was_braced:
		_set_status("Recovered %s, but the unbraced salvage surge damaged the hull." % str(loot_target.get("label", "Loot")))
	else:
		_set_status("Grappled %s." % str(loot_target.get("label", "Loot")))

func _process_resupply_cache_grapple() -> bool:
	if not bool(run_state.get("cache_available", false)):
		return false

	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	var cache_position: Vector3 = run_state.get("cache_position", Vector3.ZERO)
	var cache_radius: float = float(run_state.get("cache_radius", RESUPPLY_CACHE_RADIUS))
	var cache_max_speed: float = float(run_state.get("cache_max_speed", RESUPPLY_CACHE_MAX_SPEED))
	if boat_position.distance_to(cache_position) > cache_radius:
		return false
	if absf(float(boat_state.get("speed", 0.0))) > cache_max_speed:
		_set_status("Slow the boat down before attempting cache recovery.")
		return true

	var grapple_position := _get_station_world_position("grapple")
	if grapple_position.distance_to(cache_position) > GRAPPLE_RANGE:
		return false

	run_state["cache_available"] = false
	run_state["cache_recovered"] = true
	run_state["repair_supplies"] = mini(
		int(run_state.get("repair_supplies_max", REPAIR_SUPPLIES_MAX)),
		int(run_state.get("repair_supplies", 0)) + RESUPPLY_CACHE_SUPPLY_GRANT
	)
	run_state["bonus_gold_bank"] = int(run_state.get("bonus_gold_bank", 0)) + RESUPPLY_CACHE_GOLD_BONUS
	run_state["bonus_salvage_bank"] = int(run_state.get("bonus_salvage_bank", 0)) + RESUPPLY_CACHE_SALVAGE_BONUS
	_broadcast_run_state()
	_set_status("Recovered the resupply cache: +%d gold, +%d salvage, +%d patch kit." % [
		RESUPPLY_CACHE_GOLD_BONUS,
		RESUPPLY_CACHE_SALVAGE_BONUS,
		RESUPPLY_CACHE_SUPPLY_GRANT,
	])
	return true

func _process_rescue_grapple() -> bool:
	if not bool(run_state.get("rescue_available", false)):
		return false

	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	var rescue_position: Vector3 = run_state.get("rescue_position", Vector3.ZERO)
	var rescue_radius: float = float(run_state.get("rescue_radius", 3.4))
	var rescue_max_speed: float = float(run_state.get("rescue_max_speed", RESCUE_MAX_SPEED))
	if boat_position.distance_to(rescue_position) > rescue_radius:
		return false
	if absf(float(boat_state.get("speed", 0.0))) > rescue_max_speed:
		_set_status("Slow the boat down before attempting the rescue.")
		return true

	var grapple_position := _get_station_world_position("grapple")
	if grapple_position.distance_to(rescue_position) > GRAPPLE_RANGE:
		return false

	if bool(run_state.get("rescue_engaged", false)):
		_set_status("Hold the boat steady while the rescue line stays tight.")
		return true

	run_state["rescue_engaged"] = true
	run_state["rescue_progress"] = maxf(float(run_state.get("rescue_progress", 0.0)), 0.08)
	_broadcast_run_state()
	_set_status("Rescue line secured. Hold steady until the evac completes.")
	return true

func _process_rescue_hold(delta: float) -> void:
	if not bool(run_state.get("rescue_available", false)):
		return
	if not bool(run_state.get("rescue_engaged", false)):
		return

	var rescue_position: Vector3 = run_state.get("rescue_position", Vector3.ZERO)
	var rescue_radius: float = float(run_state.get("rescue_radius", 3.4))
	var rescue_max_speed: float = float(run_state.get("rescue_max_speed", RESCUE_MAX_SPEED))
	var rescue_duration: float = float(run_state.get("rescue_duration", RESCUE_DURATION))
	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	var boat_speed: float = absf(float(boat_state.get("speed", 0.0)))
	var progress := float(run_state.get("rescue_progress", 0.0))
	var progress_before := progress
	if boat_position.distance_to(rescue_position) <= rescue_radius and boat_speed <= rescue_max_speed:
		progress = minf(rescue_duration, progress + delta)
	else:
		progress = maxf(0.0, progress - delta * 1.5)

	run_state["rescue_progress"] = progress
	if not is_equal_approx(progress_before, progress):
		_broadcast_run_state()

	if progress >= rescue_duration:
		run_state["rescue_available"] = false
		run_state["rescue_engaged"] = false
		run_state["rescue_completed"] = true
		run_state["repair_supplies"] = mini(
			int(run_state.get("repair_supplies_max", REPAIR_SUPPLIES_MAX)),
			int(run_state.get("repair_supplies", 0)) + int(run_state.get("rescue_patch_kit_bonus", RESCUE_PATCH_KIT_GRANT))
		)
		run_state["bonus_gold_bank"] = int(run_state.get("bonus_gold_bank", 0)) + int(run_state.get("rescue_bonus_gold", RESCUE_GOLD_BONUS_MIN))
		run_state["bonus_salvage_bank"] = int(run_state.get("bonus_salvage_bank", 0)) + int(run_state.get("rescue_bonus_salvage", RESCUE_SALVAGE_BONUS_MIN))
		_broadcast_run_state()
		_set_status("%s completed: +%d gold, +%d salvage, +%d patch kit." % [
			str(run_state.get("rescue_label", "Rescue")),
			int(run_state.get("rescue_bonus_gold", RESCUE_GOLD_BONUS_MIN)),
			int(run_state.get("rescue_bonus_salvage", RESCUE_SALVAGE_BONUS_MIN)),
			int(run_state.get("rescue_patch_kit_bonus", RESCUE_PATCH_KIT_GRANT)),
		])

func _get_active_squall_drag_multiplier(position: Vector3) -> float:
	var drag_multiplier := 1.0
	for band_variant in Array(run_state.get("squall_bands", [])):
		var band: Dictionary = band_variant
		if not _position_inside_squall(position, band):
			continue
		drag_multiplier = minf(drag_multiplier, float(band.get("drag_multiplier", 1.0)))
	return drag_multiplier

func _process_squall_pressure(delta: float) -> void:
	var bands: Array = Array(run_state.get("squall_bands", [])).duplicate(true)
	if bands.is_empty():
		return

	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	var updated_bands := false
	for band_index in range(bands.size()):
		var band: Dictionary = bands[band_index]
		var pulse_timer := float(band.get("pulse_timer", float(band.get("pulse_interval", SQUALL_PULSE_INTERVAL_MIN))))
		pulse_timer = maxf(0.0, pulse_timer - delta)
		if _position_inside_squall(boat_position, band) and pulse_timer <= 0.0:
			var pulse_interval: float = float(band.get("pulse_interval", SQUALL_PULSE_INTERVAL_MIN))
			pulse_timer = pulse_interval
			_resolve_squall_pulse(band)
			if str(run_state.get("phase", "running")) != "running":
				return
		band["pulse_timer"] = pulse_timer
		bands[band_index] = band
		updated_bands = true

	if updated_bands:
		run_state["squall_bands"] = bands

func _resolve_squall_pulse(band: Dictionary) -> void:
	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	var band_center: Vector3 = band.get("center", Vector3.ZERO)
	var pulse_damage := float(band.get("pulse_damage", SQUALL_PULSE_DAMAGE_MIN))
	var was_braced := float(boat_state.get("brace_timer", 0.0)) > 0.0
	var brace_multiplier: float = float(boat_state.get("brace_multiplier", 1.0))
	if was_braced:
		pulse_damage = maxf(1.5, pulse_damage / maxf(1.0, brace_multiplier))
		boat_state["brace_timer"] = 0.0

	var pulse_sign := 1.0 if boat_position.x <= band_center.x else -1.0
	var impact_local := Vector3(0.7 * pulse_sign, 0.0, 0.45)
	var survives := _apply_localized_block_damage(pulse_damage, impact_local, "squall_pulse")
	_broadcast_runtime_boat_state()
	if not survives:
		_broadcast_run_state()
		_broadcast_boat_state()
		return

	boat_state["hull_integrity"] = maxf(0.0, float(boat_state.get("hull_integrity", BOAT_MAX_INTEGRITY)) - pulse_damage)
	boat_state["last_impact_damage"] = pulse_damage
	boat_state["last_impact_braced"] = was_braced
	var reaction_direction := Vector3.RIGHT.rotated(Vector3.UP, float(boat_state.get("rotation_y", 0.0))) * pulse_sign
	_apply_run_impact_reactions(
		reaction_direction,
		clampf(pulse_damage / SQUALL_PULSE_DAMAGE_MAX, 0.26, 0.62),
		was_braced,
		false,
		"squall"
	)
	_broadcast_run_state()
	_broadcast_boat_state()
	if float(boat_state.get("hull_integrity", BOAT_MAX_INTEGRITY)) <= 0.0:
		_resolve_run_failure("A squall surge smashed the hull apart before the crew could extract.")
		return
	_set_status("Braced through the squall surge." if was_braced else "A squall surge slammed the hull.")

func _position_inside_squall(position: Vector3, band: Dictionary) -> bool:
	var center: Vector3 = band.get("center", Vector3.ZERO)
	var half_extents: Vector3 = band.get("half_extents", Vector3(4.0, 0.0, 2.4))
	return absf(position.x - center.x) <= half_extents.x and absf(position.z - center.z) <= half_extents.z

func _process_hazard_collisions() -> void:
	if session_phase != SESSION_PHASE_RUN:
		return
	if str(run_state.get("phase", "running")) != "running":
		return

	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	for index in range(hazard_state.size()):
		var hazard: Dictionary = hazard_state[index]
		var hazard_position: Vector3 = hazard.get("position", Vector3.ZERO)
		var hazard_radius: float = float(hazard.get("radius", 1.25))
		if boat_position.distance_to(hazard_position) > BOAT_COLLISION_RADIUS + hazard_radius:
			continue

		var was_braced := float(boat_state.get("brace_timer", 0.0)) > 0.0
		var brace_multiplier: float = float(boat_state.get("brace_multiplier", 1.0))
		var damage := COLLISION_DAMAGE_BRACED if was_braced else COLLISION_DAMAGE_UNBRACED
		if was_braced:
			damage = maxf(2.0, damage / maxf(1.0, brace_multiplier))
		var impact_local := (hazard_position - boat_position).rotated(Vector3.UP, -float(boat_state.get("rotation_y", 0.0)))
		var run_continues := _apply_localized_block_damage(damage, impact_local, "collision")
		_broadcast_runtime_boat_state()
		if not run_continues:
			_respawn_hazard(index)
			_broadcast_hazard_state()
			_broadcast_boat_state()
			return
		var breach_delta := 1 if was_braced else 2
		boat_state["hull_integrity"] = maxf(0.0, float(boat_state.get("hull_integrity", BOAT_MAX_INTEGRITY)) - damage)
		boat_state["speed"] = float(boat_state.get("speed", 0.0)) * (0.72 if was_braced else 0.38)
		boat_state["breach_stacks"] = mini(MAX_BREACH_STACKS, int(boat_state.get("breach_stacks", 0)) + breach_delta)
		boat_state["last_impact_damage"] = damage
		boat_state["last_impact_braced"] = was_braced
		boat_state["collision_count"] = int(boat_state.get("collision_count", 0)) + 1
		boat_state["brace_timer"] = 0.0
		_apply_run_impact_reactions(
			(boat_position - hazard_position).normalized(),
			0.42 if was_braced else 0.92,
			was_braced,
			not was_braced
		)

		_respawn_hazard(index)
		_broadcast_hazard_state()
		_broadcast_boat_state()
		_set_status("%s impact for %.1f damage." % ["Braced" if was_braced else "Unbraced", damage])
		if float(boat_state.get("hull_integrity", BOAT_MAX_INTEGRITY)) <= 0.0:
			_resolve_run_failure("Hull destroyed in open water.")
		return

func _process_extraction(delta: float) -> void:
	if session_phase != SESSION_PHASE_RUN:
		return
	if str(run_state.get("phase", "running")) != "running":
		return

	var previous_progress: float = float(run_state.get("extraction_progress", 0.0))
	var extraction_progress := previous_progress
	var cargo_count := int(run_state.get("cargo_count", 0))
	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	var extraction_position: Vector3 = run_state.get("extraction_position", Vector3.ZERO)
	var extraction_radius: float = float(run_state.get("extraction_radius", EXTRACTION_RADIUS))
	var boat_speed: float = float(boat_state.get("speed", 0.0))
	var can_extract := cargo_count > 0 and boat_position.distance_to(extraction_position) <= extraction_radius and boat_speed <= EXTRACTION_MAX_SPEED

	if can_extract:
		extraction_progress = minf(float(run_state.get("extraction_duration", EXTRACTION_DURATION)), previous_progress + delta)
	else:
		extraction_progress = maxf(0.0, previous_progress - delta * 1.5)

	run_state["extraction_progress"] = extraction_progress
	if not is_equal_approx(previous_progress, extraction_progress):
		_broadcast_run_state()

	if extraction_progress >= float(run_state.get("extraction_duration", EXTRACTION_DURATION)):
		_resolve_run_success()

func _resolve_run_success() -> void:
	if str(run_state.get("phase", "running")) != "running":
		return

	_freeze_boat()
	var cargo_secured := int(run_state.get("cargo_count", 0))
	var reward_gold := cargo_secured * REWARD_GOLD_PER_CARGO + int(run_state.get("bonus_gold_bank", 0))
	var reward_salvage := cargo_secured * REWARD_SALVAGE_PER_CARGO + int(run_state.get("bonus_salvage_bank", 0))
	run_state["phase"] = "success"
	run_state["cargo_secured"] = cargo_secured
	run_state["secured_manifest"] = Array(run_state.get("cargo_manifest", [])).duplicate(true)
	run_state["reward_gold"] = reward_gold
	run_state["reward_salvage"] = reward_salvage
	run_state["result_title"] = "Extraction Successful"
	run_state["result_message"] = "Secured %d cargo item(s) at the outpost for %d gold and %d salvage." % [
		cargo_secured,
		reward_gold,
		reward_salvage,
	]
	_record_shared_run_result()
	_broadcast_boat_state()
	_broadcast_run_state()
	_broadcast_progression_state()
	_set_status(str(run_state.get("result_message", "")))

func _resolve_run_failure(reason: String) -> void:
	if str(run_state.get("phase", "running")) != "running":
		return

	_freeze_boat()
	run_state["phase"] = "failed"
	run_state["cargo_secured"] = 0
	run_state["secured_manifest"] = []
	run_state["reward_gold"] = 0
	run_state["reward_salvage"] = 0
	run_state["failure_reason"] = reason
	run_state["result_title"] = "Run Failed"
	run_state["result_message"] = "%s Lost %d cargo item(s)." % [reason, int(run_state.get("cargo_count", 0))]
	_record_shared_run_result()
	_broadcast_boat_state()
	_broadcast_run_state()
	_broadcast_progression_state()
	_set_status(str(run_state.get("result_message", "")))

func _record_shared_run_result() -> void:
	if not multiplayer.is_server():
		return
	DockState.record_run_result(run_seed, run_state)
	progression_state = _decorate_progression_snapshot(DockState.get_profile_snapshot())

func _freeze_boat() -> void:
	boat_state["speed"] = 0.0
	boat_state["throttle"] = 0.0
	boat_state["steer"] = 0.0
	_peer_inputs = {}

func _respawn_hazard(index: int) -> void:
	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	var hazard: Dictionary = hazard_state[index]
	var lane_offset := 0.0
	if index == 1:
		lane_offset = -5.5
	elif index == 2:
		lane_offset = 5.5
	var next_position := boat_position + Vector3(lane_offset, 0.0, 28.0 + float(index * 7))
	hazard["position"] = next_position
	hazard_state[index] = hazard

func _get_station_world_position(station_id: String) -> Vector3:
	var local_position := get_station_position(station_id)
	var rotation_y: float = float(boat_state.get("rotation_y", 0.0))
	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	return boat_position + local_position.rotated(Vector3.UP, rotation_y)

func _on_peer_connected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return

	peer_snapshot[peer_id] = {
		"name": "Crewmate %d" % peer_id,
		"status": "connecting",
	}
	_broadcast_peer_snapshot()
	_reset_connected_hangar_avatars()
	_set_status("Peer %d connected." % peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	_peer_inputs.erase(peer_id)
	_release_station(peer_id, false)
	peer_snapshot.erase(peer_id)
	hangar_avatar_state.erase(peer_id)
	run_avatar_state.erase(peer_id)
	reaction_state.erase(peer_id)
	if multiplayer.is_server() and session_phase == SESSION_PHASE_RUN:
		_refresh_overboard_run_metrics()
	var expired_pair_keys: Array = []
	for pair_key_variant in _hangar_bump_pair_cooldowns.keys():
		var pair_key := str(pair_key_variant)
		if pair_key.begins_with("%d:" % peer_id) or pair_key.ends_with(":%d" % peer_id):
			expired_pair_keys.append(pair_key)
	for pair_key_variant in expired_pair_keys:
		_hangar_bump_pair_cooldowns.erase(str(pair_key_variant))
	_schedule_disconnect_updates()
	if multiplayer.is_server():
		_set_status("Peer %d disconnected." % peer_id)

func _broadcast_disconnect_updates() -> void:
	if not multiplayer.is_server():
		return
	_broadcast_station_state()
	_broadcast_boat_state()
	_broadcast_run_state()
	_broadcast_peer_snapshot()
	_broadcast_hangar_avatar_state()
	_broadcast_run_avatar_state()
	_broadcast_reaction_state()

func _schedule_disconnect_updates() -> void:
	if not multiplayer.is_server():
		return
	if _disconnect_broadcast_scheduled:
		return
	_disconnect_broadcast_scheduled = true
	_finish_disconnect_updates()

func _finish_disconnect_updates() -> void:
	await get_tree().create_timer(DISCONNECT_BROADCAST_DELAY_SECONDS).timeout
	_disconnect_broadcast_scheduled = false
	_broadcast_disconnect_updates()

func _on_connected_to_server() -> void:
	_set_status("Connected to %s:%d as %s." % [current_host, current_port, local_player_name])
	server_register_player.rpc_id(1, local_player_name)

func _on_connection_failed() -> void:
	_set_status("Connection failed. Check the host IP and port, or make sure the host started the server.")
	emit_signal("client_connect_failed")

func _on_server_disconnected() -> void:
	_set_status("Server disconnected. Ask the host to restart the server or return to the connect screen.")
	emit_signal("client_disconnected")

@rpc("any_peer", "call_remote", "reliable")
func server_register_player(player_name: String) -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	peer_snapshot[peer_id] = {
		"name": player_name,
		"status": "ready",
	}
	if not hangar_avatar_state.has(peer_id):
		hangar_avatar_state[peer_id] = _make_default_hangar_avatar_state(hangar_avatar_state.size())
	if session_phase == SESSION_PHASE_RUN and not run_avatar_state.has(peer_id):
		run_avatar_state[peer_id] = _make_default_run_avatar_state(run_avatar_state.size())
		_refresh_run_avatar_runtime_fields(peer_id)
		_refresh_overboard_run_metrics()
	_send_bootstrap(peer_id)
	_broadcast_peer_snapshot()
	_broadcast_hangar_avatar_state()
	_broadcast_run_avatar_state()

@rpc("any_peer", "call_remote", "reliable")
func server_request_driver_control() -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_claim_station(peer_id, "helm")

@rpc("any_peer", "call_remote", "reliable")
func server_request_station_claim(station_id: String) -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_claim_station(peer_id, station_id.to_lower())

@rpc("any_peer", "call_remote", "reliable")
func server_request_station_release() -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_release_station(peer_id)

@rpc("any_peer", "call_remote", "reliable")
func server_request_brace() -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_begin_brace(peer_id)

@rpc("any_peer", "call_remote", "reliable")
func server_request_grapple() -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_process_grapple(peer_id)

@rpc("any_peer", "call_remote", "reliable")
func server_request_repair() -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_process_repair(peer_id)

@rpc("any_peer", "call_remote", "reliable")
func server_request_overboard_recovery() -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_attempt_overboard_recovery(peer_id)

@rpc("any_peer", "call_remote", "reliable")
func server_request_debug_overboard() -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_force_peer_overboard_for_debug(peer_id)

@rpc("any_peer", "call_remote", "reliable")
func server_request_place_blueprint_block(cell: Array, block_type: String, rotation_steps: int) -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_place_blueprint_block(peer_id, cell, block_type, rotation_steps)

@rpc("any_peer", "call_remote", "reliable")
func server_request_remove_blueprint_block(cell: Array) -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_remove_blueprint_block(peer_id, cell)

@rpc("any_peer", "call_remote", "reliable")
func server_request_unlock_builder_block(block_type: String) -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_unlock_builder_block(peer_id, block_type.strip_edges().to_lower())

@rpc("any_peer", "call_remote", "reliable")
func server_request_launch_run() -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_launch_run_session(peer_id)

@rpc("any_peer", "call_remote", "reliable")
func server_request_return_to_hangar() -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_return_to_hangar_session(peer_id)

@rpc("any_peer", "call_remote", "unreliable")
func server_receive_hangar_avatar_state(
	position: Vector3,
	velocity: Vector3,
	facing_y: float,
	grounded: bool,
	selected_block_id: String,
	rotation_steps: int,
	target_cell: Array,
	remove_cell: Array,
	has_target: bool,
	target_feedback_state: String
) -> void:
	if not multiplayer.is_server():
		return
	if session_phase != SESSION_PHASE_HANGAR:
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_receive_hangar_avatar_state(
		peer_id,
		position,
		velocity,
		facing_y,
		grounded,
		selected_block_id,
		rotation_steps,
		target_cell,
		remove_cell,
		has_target,
		target_feedback_state
	)

@rpc("any_peer", "call_remote", "unreliable")
func server_receive_run_avatar_state(deck_position: Vector3, world_position: Vector3, velocity: Vector3, facing_y: float, grounded: bool, avatar_mode: String) -> void:
	if not multiplayer.is_server():
		return
	if session_phase != SESSION_PHASE_RUN:
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_receive_run_avatar_state(peer_id, deck_position, world_position, velocity, facing_y, grounded, avatar_mode)

@rpc("any_peer", "call_remote", "unreliable")
func server_receive_boat_input(throttle: float, steer: float) -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_receive_boat_input(peer_id, throttle, steer)

@rpc("authority", "call_remote", "unreliable")
func client_receive_hangar_avatar_state(snapshot: Dictionary) -> void:
	hangar_avatar_state = snapshot.duplicate(true)
	emit_signal("hangar_avatar_state_changed", hangar_avatar_state.duplicate(true))

@rpc("authority", "call_remote", "unreliable")
func client_receive_run_avatar_state(snapshot: Dictionary) -> void:
	run_avatar_state = snapshot.duplicate(true)
	emit_signal("run_avatar_state_changed", run_avatar_state.duplicate(true))

@rpc("authority", "call_remote", "reliable")
func client_receive_reaction_state(snapshot: Dictionary) -> void:
	reaction_state = snapshot.duplicate(true)
	emit_signal("reaction_state_changed", reaction_state.duplicate(true))

@rpc("authority", "call_remote", "reliable")
func client_receive_bootstrap(seed: int, server_port: int, max_players: int, phase: String, blueprint_snapshot: Dictionary) -> void:
	run_seed = seed
	current_port = server_port
	session_phase = phase
	boat_blueprint = _decorate_blueprint(blueprint_snapshot)
	emit_signal("run_seed_changed", run_seed)
	emit_signal("session_phase_changed", session_phase)
	emit_signal("boat_blueprint_changed", boat_blueprint.duplicate(true))
	_set_status("Run bootstrap received: seed %d, max players %d." % [run_seed, max_players])
	if not _client_bootstrap_complete:
		_client_bootstrap_complete = true
		emit_signal("connection_ready")

@rpc("authority", "call_remote", "reliable")
func client_receive_session_phase(phase: String) -> void:
	session_phase = phase
	emit_signal("session_phase_changed", session_phase)

@rpc("authority", "call_remote", "reliable")
func client_receive_blueprint_state(snapshot: Dictionary) -> void:
	boat_blueprint = _decorate_blueprint(snapshot)
	emit_signal("boat_blueprint_changed", boat_blueprint.duplicate(true))

@rpc("authority", "call_remote", "reliable")
func client_receive_progression_state(snapshot: Dictionary) -> void:
	progression_state = _decorate_progression_snapshot(snapshot)
	emit_signal("progression_state_changed", progression_state.duplicate(true))

@rpc("authority", "call_remote", "reliable")
func client_receive_peer_snapshot(snapshot: Dictionary) -> void:
	peer_snapshot = snapshot.duplicate(true)
	emit_signal("peer_snapshot_changed", peer_snapshot.duplicate(true))

func _normalize_hangar_feedback_state(feedback_state: String) -> String:
	match feedback_state.strip_edges().to_lower():
		"ready":
			return "ready"
		"occupied":
			return "occupied"
		"range":
			return "range"
		"blocked":
			return "blocked"
		_:
			return "hidden"

func _normalize_hangar_selected_block_id(block_type: String) -> String:
	var normalized := block_type.strip_edges().to_lower()
	if BUILDER_BLOCK_LIBRARY.has(normalized):
		return normalized
	return "structure"

func _build_hangar_avatar_presence_snapshot(
	selected_block_id: String,
	rotation_steps: int,
	target_cell_value: Variant,
	remove_cell_value: Variant,
	has_target: bool,
	target_feedback_state: String
) -> Dictionary:
	var normalized_presence := {
		"selected_block_id": _normalize_hangar_selected_block_id(selected_block_id),
		"rotation_steps": wrapi(rotation_steps, 0, 4),
		"target_cell": _normalize_blueprint_cell(target_cell_value),
		"remove_cell": _normalize_blueprint_cell(remove_cell_value),
		"has_target": has_target,
		"target_feedback_state": _normalize_hangar_feedback_state(target_feedback_state),
	}
	if not bool(normalized_presence.get("has_target", false)):
		normalized_presence["target_feedback_state"] = "hidden"
		normalized_presence["target_cell"] = [0, 0, 0]
		normalized_presence["remove_cell"] = [0, 0, 0]
	return normalized_presence

func _receive_hangar_avatar_state(
	peer_id: int,
	position: Vector3,
	velocity: Vector3,
	facing_y: float,
	grounded: bool,
	selected_block_id: String,
	rotation_steps: int,
	target_cell_value: Variant,
	remove_cell_value: Variant,
	has_target: bool,
	target_feedback_state: String
) -> void:
	if not multiplayer.is_server():
		return
	if not peer_snapshot.has(peer_id):
		return

	var existing_state: Dictionary = hangar_avatar_state.get(peer_id, _make_default_hangar_avatar_state(hangar_avatar_state.size()))
	var normalized_presence := _build_hangar_avatar_presence_snapshot(
		selected_block_id if not selected_block_id.is_empty() else str(existing_state.get("selected_block_id", "structure")),
		rotation_steps,
		target_cell_value,
		remove_cell_value,
		has_target,
		target_feedback_state
	)
	hangar_avatar_state[peer_id] = {
		"position": position,
		"velocity": velocity,
		"facing_y": facing_y,
		"grounded": grounded,
		"selected_block_id": str(normalized_presence.get("selected_block_id", "structure")),
		"rotation_steps": int(normalized_presence.get("rotation_steps", 0)),
		"target_cell": normalized_presence.get("target_cell", [0, 0, 0]),
		"remove_cell": normalized_presence.get("remove_cell", [0, 0, 0]),
		"has_target": bool(normalized_presence.get("has_target", false)),
		"target_feedback_state": str(normalized_presence.get("target_feedback_state", "hidden")),
	}
	_broadcast_hangar_avatar_state()

func _sanitize_run_avatar_deck_position(deck_position: Vector3) -> Vector3:
	return Vector3(
		clampf(deck_position.x, RUN_DECK_BOUNDS_MIN.x, RUN_DECK_BOUNDS_MAX.x),
		clampf(deck_position.y, RUN_DECK_BOUNDS_MIN.y, RUN_DECK_BOUNDS_MAX.y),
		clampf(deck_position.z, RUN_DECK_BOUNDS_MIN.z, RUN_DECK_BOUNDS_MAX.z)
	)

func _receive_run_avatar_state(peer_id: int, deck_position: Vector3, world_position: Vector3, velocity: Vector3, facing_y: float, grounded: bool, _avatar_mode: String) -> void:
	if not multiplayer.is_server():
		return
	if not peer_snapshot.has(peer_id):
		return

	var previous_overboard_count := int(run_state.get("overboard_count", 0))
	var existing_state: Dictionary = run_avatar_state.get(peer_id, _make_default_run_avatar_state(run_avatar_state.size()))
	var normalized_mode := str(existing_state.get("mode", RUN_AVATAR_MODE_DECK))
	existing_state["mode"] = normalized_mode
	existing_state["deck_position"] = _sanitize_run_avatar_deck_position(deck_position)
	existing_state["velocity"] = velocity.limit_length(9.5)
	existing_state["facing_y"] = facing_y
	existing_state["grounded"] = grounded
	if normalized_mode == RUN_AVATAR_MODE_OVERBOARD:
		existing_state["world_position"] = _sanitize_overboard_world_position(world_position)
	run_avatar_state[peer_id] = existing_state
	_refresh_run_avatar_runtime_fields(peer_id)
	_refresh_overboard_run_metrics()
	_broadcast_run_avatar_state()
	if int(run_state.get("overboard_count", 0)) != previous_overboard_count:
		_broadcast_run_state()

@rpc("authority", "call_remote", "unreliable")
func client_receive_boat_state(state: Dictionary, current_driver_id: int) -> void:
	var driver_changed := driver_peer_id != current_driver_id
	var preserved_runtime_blocks := Array(boat_state.get("runtime_blocks", [])).duplicate(true)
	var preserved_sinking_chunks := Array(boat_state.get("sinking_chunks", [])).duplicate(true)
	boat_state = state.duplicate(true)
	boat_state["runtime_blocks"] = preserved_runtime_blocks
	boat_state["sinking_chunks"] = preserved_sinking_chunks
	driver_peer_id = current_driver_id
	emit_signal("boat_state_changed", boat_state.duplicate(true))
	if driver_changed:
		emit_signal("helm_changed", driver_peer_id)

@rpc("authority", "call_remote", "reliable")
func client_receive_runtime_boat_state(runtime_state: Dictionary) -> void:
	boat_state["runtime_blocks"] = Array(runtime_state.get("runtime_blocks", [])).duplicate(true)
	boat_state["sinking_chunks"] = Array(runtime_state.get("sinking_chunks", [])).duplicate(true)
	emit_signal("boat_state_changed", boat_state.duplicate(true))

@rpc("authority", "call_remote", "reliable")
func client_receive_hazard_state(hazards: Array) -> void:
	hazard_state = hazards.duplicate(true)
	emit_signal("hazard_state_changed", hazard_state.duplicate(true))

@rpc("authority", "call_remote", "reliable")
func client_receive_station_state(stations: Dictionary) -> void:
	var previous_driver := driver_peer_id
	station_state = stations.duplicate(true)
	var helm_station: Dictionary = station_state.get("helm", {})
	driver_peer_id = int(helm_station.get("occupant_peer_id", 0))
	emit_signal("station_state_changed", station_state.duplicate(true))
	if previous_driver != driver_peer_id:
		emit_signal("helm_changed", driver_peer_id)

@rpc("authority", "call_remote", "reliable")
func client_receive_loot_state(targets: Array) -> void:
	loot_state = targets.duplicate(true)
	emit_signal("loot_state_changed", loot_state.duplicate(true))

@rpc("authority", "call_remote", "reliable")
func client_receive_run_state(state: Dictionary) -> void:
	run_state = state.duplicate(true)
	emit_signal("run_state_changed", run_state.duplicate(true))
