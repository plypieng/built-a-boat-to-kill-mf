extends Node

var heartbeat_timer: Timer

func _ready() -> void:
	print("Run server ready with seed %d on port %d." % [NetworkRuntime.run_seed, NetworkRuntime.current_port])
	NetworkRuntime.peer_snapshot_changed.connect(_on_peer_snapshot_changed)
	NetworkRuntime.helm_changed.connect(_on_helm_changed)

	heartbeat_timer = Timer.new()
	heartbeat_timer.wait_time = 1.5
	heartbeat_timer.autostart = true
	heartbeat_timer.timeout.connect(_on_heartbeat_timeout)
	add_child(heartbeat_timer)

func _process(delta: float) -> void:
	NetworkRuntime.server_step_shared_boat(delta)

func _on_heartbeat_timeout() -> void:
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	print("Heartbeat: mode=%s peers=%d seed=%d" % [
		NetworkRuntime.get_mode_name(),
		NetworkRuntime.peer_snapshot.size(),
		NetworkRuntime.run_seed,
	])
	print("Boat: driver=%s pos=%s speed=%.2f throttle=%.2f steer=%.2f hp=%.1f brace=%.2f cooldown=%.2f collisions=%d hazards=%d" % [
		NetworkRuntime.get_driver_name(),
		str(boat_position),
		float(NetworkRuntime.boat_state.get("speed", 0.0)),
		float(NetworkRuntime.boat_state.get("throttle", 0.0)),
		float(NetworkRuntime.boat_state.get("steer", 0.0)),
		float(NetworkRuntime.boat_state.get("hull_integrity", 100.0)),
		float(NetworkRuntime.boat_state.get("brace_timer", 0.0)),
		float(NetworkRuntime.boat_state.get("brace_cooldown", 0.0)),
		int(NetworkRuntime.boat_state.get("collision_count", 0)),
		NetworkRuntime.hazard_state.size(),
	])

func _on_peer_snapshot_changed(snapshot: Dictionary) -> void:
	print("Peer snapshot updated: %s" % [snapshot])

func _on_helm_changed(driver_peer_id: int) -> void:
	print("Helm changed: peer=%d name=%s" % [driver_peer_id, NetworkRuntime.get_driver_name()])
