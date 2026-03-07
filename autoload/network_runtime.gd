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

enum Mode {
	OFFLINE,
	CLIENT,
	SERVER,
}

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

var _peer_inputs: Dictionary = {}
var _boat_broadcast_accumulator := 0.0
var _next_hazard_id: int = 1

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

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func start_server(listen_port: int = GameConfig.DEFAULT_PORT, seed: int = GameConfig.DEFAULT_RUN_SEED) -> int:
	shutdown()

	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(listen_port, GameConfig.MAX_PLAYERS)
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
	_reset_boat_runtime()

	emit_signal("mode_changed", _mode_name())
	emit_signal("run_seed_changed", run_seed)
	_emit_peer_snapshot()
	_emit_helm_changed()
	_emit_boat_state()
	_emit_hazard_state()
	_set_status("Server listening on port %d." % current_port)
	return OK

func start_client(host: String, connect_port: int, player_name: String) -> int:
	shutdown()

	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(host, connect_port)
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
	_reset_boat_runtime()
	emit_signal("mode_changed", _mode_name())
	_emit_peer_snapshot()
	emit_signal("run_seed_changed", run_seed)
	_emit_helm_changed()
	_emit_boat_state()
	_emit_hazard_state()

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

func _emit_peer_snapshot() -> void:
	emit_signal("peer_snapshot_changed", peer_snapshot.duplicate(true))

func _emit_helm_changed() -> void:
	emit_signal("helm_changed", driver_peer_id)

func _emit_boat_state() -> void:
	emit_signal("boat_state_changed", boat_state.duplicate(true))

func _emit_hazard_state() -> void:
	emit_signal("hazard_state_changed", hazard_state.duplicate(true))

func _broadcast_peer_snapshot() -> void:
	_emit_peer_snapshot()
	if multiplayer.is_server():
		var snapshot := peer_snapshot.duplicate(true)
		for peer_id in get_player_peer_ids():
			client_receive_peer_snapshot.rpc_id(int(peer_id), snapshot)

func _broadcast_boat_state() -> void:
	_emit_boat_state()
	if multiplayer.is_server():
		var state := boat_state.duplicate(true)
		for peer_id in get_player_peer_ids():
			client_receive_boat_state.rpc_id(int(peer_id), state, driver_peer_id)

func _broadcast_hazard_state() -> void:
	_emit_hazard_state()
	if multiplayer.is_server():
		var hazards := hazard_state.duplicate(true)
		for peer_id in get_player_peer_ids():
			client_receive_hazard_state.rpc_id(int(peer_id), hazards)

func _send_bootstrap(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	client_receive_bootstrap.rpc_id(peer_id, run_seed, current_port, GameConfig.MAX_PLAYERS)
	client_receive_hazard_state.rpc_id(peer_id, hazard_state.duplicate(true))
	client_receive_boat_state.rpc_id(peer_id, boat_state.duplicate(true), driver_peer_id)

func _reset_boat_runtime() -> void:
	driver_peer_id = 0
	_peer_inputs = {}
	_boat_broadcast_accumulator = 0.0
	_next_hazard_id = 1
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
		"last_impact_damage": 0.0,
		"last_impact_braced": false,
		"collision_count": 0,
	}
	_initialize_hazards()

func _initialize_hazards() -> void:
	hazard_state = [
		_make_hazard(Vector3(0.0, 0.0, 13.5), 1.35, "Debris Cluster"),
		_make_hazard(Vector3(-4.5, 0.0, 27.0), 1.2, "Broken Spar"),
		_make_hazard(Vector3(5.0, 0.0, 42.0), 1.4, "Cargo Crate"),
	]

func _make_hazard(position: Vector3, radius: float, label: String) -> Dictionary:
	var hazard_id: int = _next_hazard_id
	_next_hazard_id += 1
	return {
		"id": hazard_id,
		"position": position,
		"radius": radius,
		"label": label,
	}

func _assign_driver(peer_id: int) -> void:
	if driver_peer_id == peer_id:
		return

	driver_peer_id = peer_id
	boat_state["driver_peer_id"] = driver_peer_id
	_emit_helm_changed()
	_set_status("Peer %d took the helm." % driver_peer_id)
	_broadcast_boat_state()

func _clear_driver() -> void:
	driver_peer_id = 0
	boat_state["driver_peer_id"] = 0
	boat_state["throttle"] = 0.0
	boat_state["steer"] = 0.0
	_emit_helm_changed()
	_broadcast_boat_state()

func get_driver_name() -> String:
	if driver_peer_id <= 0:
		return "Unclaimed"

	var peer_data: Dictionary = peer_snapshot.get(driver_peer_id, {})
	return str(peer_data.get("name", "Peer %d" % driver_peer_id))

func get_player_peer_ids() -> Array:
	var peer_ids: Array = []
	for peer_id in peer_snapshot.keys():
		var peer_data: Dictionary = peer_snapshot[peer_id]
		if str(peer_data.get("status", "")) == "hosting":
			continue
		peer_ids.append(peer_id)
	peer_ids.sort()
	return peer_ids

func request_driver_control() -> void:
	if multiplayer.is_server():
		_assign_driver(multiplayer.get_unique_id())
		return

	server_request_driver_control.rpc_id(1)

func request_brace() -> void:
	if multiplayer.is_server():
		_begin_brace(multiplayer.get_unique_id())
		return

	server_request_brace.rpc_id(1)

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

	var brace_timer: float = maxf(0.0, float(boat_state.get("brace_timer", 0.0)) - delta)
	var brace_cooldown: float = maxf(0.0, float(boat_state.get("brace_cooldown", 0.0)) - delta)
	boat_state["brace_timer"] = brace_timer
	boat_state["brace_cooldown"] = brace_cooldown

	var input_state: Dictionary = _peer_inputs.get(driver_peer_id, {
		"throttle": 0.0,
		"steer": 0.0,
	})
	var throttle: float = float(input_state.get("throttle", 0.0))
	var steer: float = float(input_state.get("steer", 0.0))
	var current_speed: float = float(boat_state.get("speed", 0.0))
	var target_speed: float = throttle * BOAT_TOP_SPEED
	var acceleration := BOAT_ACCELERATION if absf(target_speed) > absf(current_speed) else BOAT_DECELERATION
	current_speed = move_toward(current_speed, target_speed, acceleration * delta)

	if is_zero_approx(throttle):
		current_speed = move_toward(current_speed, 0.0, BOAT_DECELERATION * 0.6 * delta)

	var turn_factor := clampf(absf(current_speed) / BOAT_TOP_SPEED, 0.25, 1.0)
	var rotation_y: float = float(boat_state.get("rotation_y", 0.0))
	rotation_y += steer * BOAT_TURN_SPEED * turn_factor * delta

	var forward := -Vector3.FORWARD.rotated(Vector3.UP, rotation_y)
	var position: Vector3 = boat_state.get("position", Vector3.ZERO)
	position += forward * current_speed * delta

	boat_state["position"] = position
	boat_state["rotation_y"] = rotation_y
	boat_state["speed"] = current_speed
	boat_state["throttle"] = throttle
	boat_state["steer"] = steer
	boat_state["tick"] = int(boat_state.get("tick", 0)) + 1
	boat_state["driver_peer_id"] = driver_peer_id
	_process_hazard_collisions()

	_boat_broadcast_accumulator += delta
	if _boat_broadcast_accumulator >= BOAT_BROADCAST_INTERVAL:
		_boat_broadcast_accumulator = 0.0
		_broadcast_boat_state()

func _receive_boat_input(peer_id: int, throttle: float, steer: float) -> void:
	if driver_peer_id == 0:
		_assign_driver(peer_id)

	if peer_id != driver_peer_id:
		return

	_peer_inputs[peer_id] = {
		"throttle": throttle,
		"steer": steer,
	}

func _begin_brace(peer_id: int) -> void:
	if driver_peer_id == 0:
		_assign_driver(peer_id)

	if float(boat_state.get("brace_cooldown", 0.0)) > 0.0:
		return

	boat_state["brace_timer"] = BRACE_ACTIVE_SECONDS
	boat_state["brace_cooldown"] = BRACE_COOLDOWN_SECONDS
	_broadcast_boat_state()

func _process_hazard_collisions() -> void:
	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	for index in range(hazard_state.size()):
		var hazard: Dictionary = hazard_state[index]
		var hazard_position: Vector3 = hazard.get("position", Vector3.ZERO)
		var hazard_radius: float = float(hazard.get("radius", 1.25))
		if boat_position.distance_to(hazard_position) > BOAT_COLLISION_RADIUS + hazard_radius:
			continue

		var was_braced := float(boat_state.get("brace_timer", 0.0)) > 0.0
		var damage := COLLISION_DAMAGE_BRACED if was_braced else COLLISION_DAMAGE_UNBRACED
		boat_state["hull_integrity"] = maxf(0.0, float(boat_state.get("hull_integrity", BOAT_MAX_INTEGRITY)) - damage)
		boat_state["speed"] = float(boat_state.get("speed", 0.0)) * (0.72 if was_braced else 0.38)
		boat_state["last_impact_damage"] = damage
		boat_state["last_impact_braced"] = was_braced
		boat_state["collision_count"] = int(boat_state.get("collision_count", 0)) + 1
		boat_state["brace_timer"] = 0.0

		_respawn_hazard(index)
		_broadcast_hazard_state()
		_broadcast_boat_state()
		_set_status("%s impact for %.1f damage." % ["Braced" if was_braced else "Unbraced", damage])
		return

func _respawn_hazard(index: int) -> void:
	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	var hazard: Dictionary = hazard_state[index]
	var lateral_options := [-5.5, 0.0, 5.5]
	var lane_index: int = int(hazard.get("id", 0)) % lateral_options.size()
	var next_position := boat_position + Vector3(lateral_options[lane_index], 0.0, 28.0 + float(index * 9))
	hazard["position"] = next_position
	hazard_state[index] = hazard

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
	peer_snapshot.erase(peer_id)
	_broadcast_peer_snapshot()
	if peer_id == driver_peer_id:
		_clear_driver()
	if multiplayer.is_server():
		_set_status("Peer %d disconnected." % peer_id)

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

func get_mode_name() -> String:
	return _mode_name()

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
	_assign_driver(peer_id)

@rpc("any_peer", "call_remote", "reliable")
func server_request_brace() -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_begin_brace(peer_id)

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
	_emit_peer_snapshot()

@rpc("authority", "call_remote", "unreliable")
func client_receive_boat_state(state: Dictionary, current_driver_peer_id: int) -> void:
	var driver_changed := driver_peer_id != current_driver_peer_id
	boat_state = state.duplicate(true)
	driver_peer_id = current_driver_peer_id
	_emit_boat_state()
	if driver_changed:
		_emit_helm_changed()

@rpc("authority", "call_remote", "reliable")
func client_receive_hazard_state(hazards: Array) -> void:
	hazard_state = hazards.duplicate(true)
	_emit_hazard_state()
