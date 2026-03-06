extends Node

var heartbeat_timer: Timer

func _ready() -> void:
	print("Run server ready with seed %d on port %d." % [NetworkRuntime.run_seed, NetworkRuntime.current_port])
	NetworkRuntime.peer_snapshot_changed.connect(_on_peer_snapshot_changed)

	heartbeat_timer = Timer.new()
	heartbeat_timer.wait_time = 5.0
	heartbeat_timer.autostart = true
	heartbeat_timer.timeout.connect(_on_heartbeat_timeout)
	add_child(heartbeat_timer)

func _on_heartbeat_timeout() -> void:
	print("Heartbeat: mode=%s peers=%d seed=%d" % [
		NetworkRuntime._mode_name(),
		NetworkRuntime.peer_snapshot.size(),
		NetworkRuntime.run_seed,
	])

func _on_peer_snapshot_changed(snapshot: Dictionary) -> void:
	print("Peer snapshot updated: %s" % [snapshot])

