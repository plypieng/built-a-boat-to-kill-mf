extends Node

signal mode_changed(mode_name: String)
signal status_changed(message: String)
signal connection_ready()
signal client_connect_failed()
signal client_disconnected()
signal peer_snapshot_changed(snapshot: Dictionary)
signal run_seed_changed(seed: int)

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

	emit_signal("mode_changed", _mode_name())
	emit_signal("run_seed_changed", run_seed)
	_emit_peer_snapshot()
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
	emit_signal("mode_changed", _mode_name())
	_emit_peer_snapshot()
	emit_signal("run_seed_changed", run_seed)

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

func _broadcast_peer_snapshot() -> void:
	_emit_peer_snapshot()
	if multiplayer.is_server():
		client_receive_peer_snapshot.rpc(peer_snapshot.duplicate(true))

func _send_bootstrap(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	client_receive_bootstrap.rpc_id(peer_id, run_seed, current_port, GameConfig.MAX_PLAYERS)

func _on_peer_connected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return

	peer_snapshot[peer_id] = {
		"name": "Crewmate %d" % peer_id,
		"status": "connecting",
	}
	_send_bootstrap(peer_id)
	_broadcast_peer_snapshot()
	_set_status("Peer %d connected." % peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	peer_snapshot.erase(peer_id)
	_broadcast_peer_snapshot()
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

