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

var _peer_inputs: Dictionary = {}
var _boat_broadcast_accumulator := 0.0

const BOAT_ACCELERATION := 8.0
const BOAT_DECELERATION := 10.0
const BOAT_TOP_SPEED := 14.0
const BOAT_TURN_SPEED := 1.9
const BOAT_BROADCAST_INTERVAL := 0.05

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

func _broadcast_peer_snapshot() -> void:
	_emit_peer_snapshot()
	if multiplayer.is_server():
		client_receive_peer_snapshot.rpc(peer_snapshot.duplicate(true))

func _broadcast_boat_state() -> void:
	_emit_boat_state()
	if multiplayer.is_server():
		client_receive_boat_state.rpc(boat_state.duplicate(true), driver_peer_id)

func _send_bootstrap(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	client_receive_bootstrap.rpc_id(peer_id, run_seed, current_port, GameConfig.MAX_PLAYERS)

func _reset_boat_runtime() -> void:
	driver_peer_id = 0
	_peer_inputs = {}
	_boat_broadcast_accumulator = 0.0
	boat_state = {
		"position": Vector3.ZERO,
		"rotation_y": 0.0,
		"speed": 0.0,
		"throttle": 0.0,
		"steer": 0.0,
		"tick": 0,
		"driver_peer_id": 0,
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

func request_driver_control() -> void:
	if multiplayer.is_server():
		_assign_driver(multiplayer.get_unique_id())
		return

	server_request_driver_control.rpc_id(1)

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
