extends Node

signal mode_changed(mode_name: String)
signal status_changed(message: String)
signal connection_ready()
signal client_connect_failed()
signal client_disconnected()
signal peer_snapshot_changed(snapshot: Dictionary)
signal run_seed_changed(seed: int)
signal helm_changed(driver_peer_id: int)
signal boat_state_changed(state: Dictionary)
signal hazard_state_changed(hazards: Array)
signal station_state_changed(stations: Dictionary)
signal loot_state_changed(loot_targets: Array)
signal run_state_changed(state: Dictionary)

enum Mode {
	OFFLINE,
	CLIENT,
	SERVER,
}

const STATION_ORDER := ["helm", "brace", "grapple", "repair"]
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
const REWARD_GOLD_PER_CARGO := 35
const REWARD_SALVAGE_PER_CARGO := 2

var mode: int = Mode.OFFLINE
var current_host: String = GameConfig.DEFAULT_HOST
var current_port: int = GameConfig.DEFAULT_PORT
var local_player_name: String = GameConfig.DEFAULT_PLAYER_NAME
var run_seed: int = GameConfig.DEFAULT_RUN_SEED
var peer_snapshot: Dictionary = {}
var status_message := "Offline"
var driver_peer_id := 0
var boat_state: Dictionary = {}
var hazard_state: Array = []
var station_state: Dictionary = {}
var loot_state: Array = []
var run_state: Dictionary = {}

var _peer_inputs: Dictionary = {}
var _boat_broadcast_accumulator := 0.0
var _next_hazard_id: int = 1
var _next_loot_id: int = 1

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
	peer_snapshot = {
		1: {
			"name": "Dedicated Server",
			"status": "hosting",
		},
	}
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
		_set_status("Client failed to connect (code %s)." % str(error))
		emit_signal("client_connect_failed")
		return error

	multiplayer.multiplayer_peer = peer
	mode = Mode.CLIENT
	current_host = host
	current_port = connect_port
	local_player_name = player_name if not player_name.is_empty() else GameConfig.DEFAULT_PLAYER_NAME
	emit_signal("mode_changed", _mode_name())
	_set_status("Connecting to %s:%d..." % [current_host, current_port])
	return OK

func shutdown() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

	mode = Mode.OFFLINE
	peer_snapshot = {}
	status_message = "Offline"
	_reset_run_runtime()
	emit_signal("mode_changed", _mode_name())
	emit_signal("run_seed_changed", run_seed)
	_emit_all_runtime_state()

func get_mode_name() -> String:
	return _mode_name()

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

	if str(run_state.get("phase", "running")) != "running":
		return

	var brace_timer: float = maxf(0.0, float(boat_state.get("brace_timer", 0.0)) - delta)
	var brace_cooldown: float = maxf(0.0, float(boat_state.get("brace_cooldown", 0.0)) - delta)
	var repair_cooldown: float = maxf(0.0, float(boat_state.get("repair_cooldown", 0.0)) - delta)
	boat_state["brace_timer"] = brace_timer
	boat_state["brace_cooldown"] = brace_cooldown
	boat_state["repair_cooldown"] = repair_cooldown

	var breach_stacks := int(boat_state.get("breach_stacks", 0))
	var top_speed_limit := BOAT_TOP_SPEED * maxf(0.45, 1.0 - float(breach_stacks) * BREACH_SPEED_PENALTY)
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

	if breach_stacks > 0:
		var leak_damage := HULL_LEAK_DAMAGE_PER_BREACH * float(breach_stacks) * delta
		boat_state["hull_integrity"] = maxf(0.0, float(boat_state.get("hull_integrity", BOAT_MAX_INTEGRITY)) - leak_damage)
		if float(boat_state.get("hull_integrity", BOAT_MAX_INTEGRITY)) <= 0.0:
			_broadcast_boat_state()
			_resolve_run_failure("The hull flooded before the crew could repair it.")
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
	emit_signal("peer_snapshot_changed", peer_snapshot.duplicate(true))
	emit_signal("helm_changed", driver_peer_id)
	emit_signal("boat_state_changed", boat_state.duplicate(true))
	emit_signal("hazard_state_changed", hazard_state.duplicate(true))
	emit_signal("station_state_changed", station_state.duplicate(true))
	emit_signal("loot_state_changed", loot_state.duplicate(true))
	emit_signal("run_state_changed", run_state.duplicate(true))

func _broadcast_peer_snapshot() -> void:
	emit_signal("peer_snapshot_changed", peer_snapshot.duplicate(true))
	if multiplayer.is_server():
		var snapshot := peer_snapshot.duplicate(true)
		for peer_id in get_player_peer_ids():
			client_receive_peer_snapshot.rpc_id(int(peer_id), snapshot)

func _broadcast_boat_state() -> void:
	emit_signal("boat_state_changed", boat_state.duplicate(true))
	if multiplayer.is_server():
		var state := boat_state.duplicate(true)
		for peer_id in get_player_peer_ids():
			client_receive_boat_state.rpc_id(int(peer_id), state, driver_peer_id)

func _broadcast_hazard_state() -> void:
	emit_signal("hazard_state_changed", hazard_state.duplicate(true))
	if multiplayer.is_server():
		var hazards := hazard_state.duplicate(true)
		for peer_id in get_player_peer_ids():
			client_receive_hazard_state.rpc_id(int(peer_id), hazards)

func _broadcast_station_state() -> void:
	emit_signal("station_state_changed", station_state.duplicate(true))
	if multiplayer.is_server():
		var stations := station_state.duplicate(true)
		for peer_id in get_player_peer_ids():
			client_receive_station_state.rpc_id(int(peer_id), stations)

func _broadcast_loot_state() -> void:
	emit_signal("loot_state_changed", loot_state.duplicate(true))
	if multiplayer.is_server():
		var targets := loot_state.duplicate(true)
		for peer_id in get_player_peer_ids():
			client_receive_loot_state.rpc_id(int(peer_id), targets)

func _broadcast_run_state() -> void:
	emit_signal("run_state_changed", run_state.duplicate(true))
	if multiplayer.is_server():
		var state := run_state.duplicate(true)
		for peer_id in get_player_peer_ids():
			client_receive_run_state.rpc_id(int(peer_id), state)

func _send_bootstrap(peer_id: int) -> void:
	if not multiplayer.is_server():
		return

	client_receive_bootstrap.rpc_id(peer_id, run_seed, current_port, GameConfig.MAX_PLAYERS)
	client_receive_boat_state.rpc_id(peer_id, boat_state.duplicate(true), driver_peer_id)
	client_receive_hazard_state.rpc_id(peer_id, hazard_state.duplicate(true))
	client_receive_station_state.rpc_id(peer_id, station_state.duplicate(true))
	client_receive_loot_state.rpc_id(peer_id, loot_state.duplicate(true))
	client_receive_run_state.rpc_id(peer_id, run_state.duplicate(true))

func _reset_run_runtime() -> void:
	driver_peer_id = 0
	_peer_inputs = {}
	_boat_broadcast_accumulator = 0.0
	_next_hazard_id = 1
	_next_loot_id = 1

	boat_state = {
		"position": Vector3.ZERO,
		"rotation_y": 0.0,
		"speed": 0.0,
		"throttle": 0.0,
		"steer": 0.0,
		"tick": 0,
		"driver_peer_id": 0,
		"hull_integrity": BOAT_MAX_INTEGRITY,
		"brace_timer": 0.0,
		"brace_cooldown": 0.0,
		"repair_cooldown": 0.0,
		"top_speed_limit": BOAT_TOP_SPEED,
		"breach_stacks": 0,
		"last_impact_damage": 0.0,
		"last_impact_braced": false,
		"collision_count": 0,
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
	_initialize_run_state()

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

func _initialize_run_state() -> void:
	run_state = {
		"phase": "running",
		"cargo_count": 0,
		"cargo_secured": 0,
		"loot_collected": 0,
		"loot_total": loot_state.size(),
		"loot_remaining": loot_state.size(),
		"wreck_position": Vector3(0.0, 0.0, 10.6),
		"wreck_radius": 4.1,
		"salvage_max_speed": SALVAGE_MAX_SPEED,
		"repair_actions": 0,
		"repair_supplies": REPAIR_SUPPLIES_START,
		"repair_supplies_max": REPAIR_SUPPLIES_MAX,
		"cache_position": Vector3(-5.8, 0.0, 24.8),
		"cache_radius": RESUPPLY_CACHE_RADIUS,
		"cache_max_speed": RESUPPLY_CACHE_MAX_SPEED,
		"cache_available": true,
		"cache_label": "Resupply Cache",
		"cache_recovered": false,
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
	}

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
	if not station_state.has(station_id):
		return
	if str(run_state.get("phase", "running")) != "running":
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
	if str(run_state.get("phase", "running")) != "running":
		return
	if peer_id != driver_peer_id:
		return
	if get_peer_station_id(peer_id) != "helm":
		return

	_peer_inputs[peer_id] = {
		"throttle": throttle,
		"steer": steer,
	}

func _begin_brace(peer_id: int) -> void:
	if str(run_state.get("phase", "running")) != "running":
		return
	if get_peer_station_id(peer_id) != "brace":
		return
	if float(boat_state.get("brace_cooldown", 0.0)) > 0.0:
		return

	boat_state["brace_timer"] = BRACE_ACTIVE_SECONDS
	boat_state["brace_cooldown"] = BRACE_COOLDOWN_SECONDS
	_broadcast_boat_state()
	_set_status("Brace station activated.")

func _process_repair(peer_id: int) -> void:
	if str(run_state.get("phase", "running")) != "running":
		return
	if get_peer_station_id(peer_id) != "repair":
		return
	if float(boat_state.get("repair_cooldown", 0.0)) > 0.0:
		return
	if int(run_state.get("repair_supplies", 0)) <= 0:
		_set_status("Repair bench is out of patch kits.")
		return

	var breach_stacks := int(boat_state.get("breach_stacks", 0))
	var hull_integrity: float = float(boat_state.get("hull_integrity", BOAT_MAX_INTEGRITY))
	if breach_stacks <= 0 and hull_integrity >= BOAT_MAX_INTEGRITY - 0.1:
		return

	boat_state["breach_stacks"] = maxi(0, breach_stacks - 1)
	boat_state["hull_integrity"] = minf(BOAT_MAX_INTEGRITY, hull_integrity + REPAIR_HULL_RECOVERY)
	boat_state["repair_cooldown"] = REPAIR_COOLDOWN_SECONDS
	run_state["repair_actions"] = int(run_state.get("repair_actions", 0)) + 1
	run_state["repair_supplies"] = maxi(0, int(run_state.get("repair_supplies", 0)) - 1)
	_broadcast_boat_state()
	_broadcast_run_state()
	_set_status("Repair bench patched the hull. %d patch kit(s) left." % int(run_state.get("repair_supplies", 0)))

func _process_grapple(peer_id: int) -> void:
	if str(run_state.get("phase", "running")) != "running":
		return
	if get_peer_station_id(peer_id) != "grapple":
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
	var requires_brace := bool(loot_target.get("requires_brace", true))
	var was_braced := float(boat_state.get("brace_timer", 0.0)) > 0.0
	run_state["cargo_count"] = int(run_state.get("cargo_count", 0)) + cargo_value
	run_state["loot_collected"] = int(run_state.get("loot_collected", 0)) + 1
	loot_state.remove_at(closest_index)
	run_state["loot_remaining"] = loot_state.size()

	if requires_brace:
		boat_state["brace_timer"] = 0.0
		if was_braced:
			boat_state["last_impact_damage"] = 0.0
			boat_state["last_impact_braced"] = true
		else:
			boat_state["hull_integrity"] = maxf(0.0, float(boat_state.get("hull_integrity", BOAT_MAX_INTEGRITY)) - SALVAGE_BACKLASH_DAMAGE)
			boat_state["last_impact_damage"] = SALVAGE_BACKLASH_DAMAGE
			boat_state["last_impact_braced"] = false
			boat_state["breach_stacks"] = mini(MAX_BREACH_STACKS, int(boat_state.get("breach_stacks", 0)) + SALVAGE_BACKLASH_BREACHES)
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

func _process_hazard_collisions() -> void:
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
		var damage := COLLISION_DAMAGE_BRACED if was_braced else COLLISION_DAMAGE_UNBRACED
		var breach_delta := 1 if was_braced else 2
		boat_state["hull_integrity"] = maxf(0.0, float(boat_state.get("hull_integrity", BOAT_MAX_INTEGRITY)) - damage)
		boat_state["speed"] = float(boat_state.get("speed", 0.0)) * (0.72 if was_braced else 0.38)
		boat_state["breach_stacks"] = mini(MAX_BREACH_STACKS, int(boat_state.get("breach_stacks", 0)) + breach_delta)
		boat_state["last_impact_damage"] = damage
		boat_state["last_impact_braced"] = was_braced
		boat_state["collision_count"] = int(boat_state.get("collision_count", 0)) + 1
		boat_state["brace_timer"] = 0.0

		_respawn_hazard(index)
		_broadcast_hazard_state()
		_broadcast_boat_state()
		_set_status("%s impact for %.1f damage." % ["Braced" if was_braced else "Unbraced", damage])
		if float(boat_state.get("hull_integrity", BOAT_MAX_INTEGRITY)) <= 0.0:
			_resolve_run_failure("Hull destroyed in open water.")
		return

func _process_extraction(delta: float) -> void:
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
	run_state["reward_gold"] = reward_gold
	run_state["reward_salvage"] = reward_salvage
	run_state["result_title"] = "Extraction Successful"
	run_state["result_message"] = "Secured %d cargo item(s) at the outpost for %d gold and %d salvage." % [
		cargo_secured,
		reward_gold,
		reward_salvage,
	]
	_broadcast_boat_state()
	_broadcast_run_state()
	_set_status(str(run_state.get("result_message", "")))

func _resolve_run_failure(reason: String) -> void:
	if str(run_state.get("phase", "running")) != "running":
		return

	_freeze_boat()
	run_state["phase"] = "failed"
	run_state["cargo_secured"] = 0
	run_state["reward_gold"] = 0
	run_state["reward_salvage"] = 0
	run_state["failure_reason"] = reason
	run_state["result_title"] = "Run Failed"
	run_state["result_message"] = "%s Lost %d cargo item(s)." % [reason, int(run_state.get("cargo_count", 0))]
	_broadcast_boat_state()
	_broadcast_run_state()
	_set_status(str(run_state.get("result_message", "")))

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
	_set_status("Peer %d connected." % peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	_peer_inputs.erase(peer_id)
	_release_station(peer_id, false)
	peer_snapshot.erase(peer_id)
	call_deferred("_broadcast_disconnect_updates")
	if multiplayer.is_server():
		_set_status("Peer %d disconnected." % peer_id)

func _broadcast_disconnect_updates() -> void:
	if not multiplayer.is_server():
		return
	_broadcast_station_state()
	_broadcast_boat_state()
	_broadcast_peer_snapshot()

func _on_connected_to_server() -> void:
	_set_status("Connected to %s:%d as %s." % [current_host, current_port, local_player_name])
	server_register_player.rpc_id(1, local_player_name)
	emit_signal("connection_ready")

func _on_connection_failed() -> void:
	_set_status("Connection failed.")
	emit_signal("client_connect_failed")

func _on_server_disconnected() -> void:
	_set_status("Server disconnected.")
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
	_send_bootstrap(peer_id)
	_broadcast_peer_snapshot()

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

@rpc("any_peer", "call_remote", "unreliable")
func server_receive_boat_input(throttle: float, steer: float) -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_receive_boat_input(peer_id, throttle, steer)

@rpc("authority", "call_remote", "reliable")
func client_receive_bootstrap(seed: int, server_port: int, max_players: int) -> void:
	run_seed = seed
	current_port = server_port
	emit_signal("run_seed_changed", run_seed)
	_set_status("Run bootstrap received: seed %d, max players %d." % [run_seed, max_players])

@rpc("authority", "call_remote", "reliable")
func client_receive_peer_snapshot(snapshot: Dictionary) -> void:
	peer_snapshot = snapshot.duplicate(true)
	emit_signal("peer_snapshot_changed", peer_snapshot.duplicate(true))

@rpc("authority", "call_remote", "unreliable")
func client_receive_boat_state(state: Dictionary, current_driver_id: int) -> void:
	var driver_changed := driver_peer_id != current_driver_id
	boat_state = state.duplicate(true)
	driver_peer_id = current_driver_id
	emit_signal("boat_state_changed", boat_state.duplicate(true))
	if driver_changed:
		emit_signal("helm_changed", driver_peer_id)

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
