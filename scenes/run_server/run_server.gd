extends Node

var heartbeat_timer: Timer
var last_run_summary := ""

func _ready() -> void:
	print("Run server ready with seed %d on port %d." % [NetworkRuntime.run_seed, NetworkRuntime.current_port])
	NetworkRuntime.peer_snapshot_changed.connect(_on_peer_snapshot_changed)
	NetworkRuntime.helm_changed.connect(_on_helm_changed)
	NetworkRuntime.station_state_changed.connect(_on_station_state_changed)
	NetworkRuntime.run_state_changed.connect(_on_run_state_changed)
	NetworkRuntime.loot_state_changed.connect(_on_loot_state_changed)

	heartbeat_timer = Timer.new()
	heartbeat_timer.wait_time = 1.5
	heartbeat_timer.autostart = true
	heartbeat_timer.timeout.connect(_on_heartbeat_timeout)
	add_child(heartbeat_timer)

func _process(delta: float) -> void:
	NetworkRuntime.server_step_shared_boat(delta)

func _on_heartbeat_timeout() -> void:
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var station_summaries := PackedStringArray()
	for station_id in NetworkRuntime.get_station_ids():
		station_summaries.append("%s=%s" % [
			station_id,
			NetworkRuntime.get_station_occupant_name(station_id),
		])
	print("Heartbeat: mode=%s peers=%d seed=%d" % [
		NetworkRuntime.get_mode_name(),
		NetworkRuntime.peer_snapshot.size(),
		NetworkRuntime.run_seed,
	])
	print("Boat: driver=%s pos=%s speed=%.2f/%.2f throttle=%.2f steer=%.2f hp=%.1f breaches=%d brace=%.2f repairCd=%.2f collisions=%d hazards=%d" % [
		NetworkRuntime.get_driver_name(),
		str(boat_position),
		float(NetworkRuntime.boat_state.get("speed", 0.0)),
		float(NetworkRuntime.boat_state.get("top_speed_limit", NetworkRuntime.BOAT_TOP_SPEED)),
		float(NetworkRuntime.boat_state.get("throttle", 0.0)),
		float(NetworkRuntime.boat_state.get("steer", 0.0)),
		float(NetworkRuntime.boat_state.get("hull_integrity", 100.0)),
		int(NetworkRuntime.boat_state.get("breach_stacks", 0)),
		float(NetworkRuntime.boat_state.get("brace_timer", 0.0)),
		float(NetworkRuntime.boat_state.get("repair_cooldown", 0.0)),
		int(NetworkRuntime.boat_state.get("collision_count", 0)),
		NetworkRuntime.hazard_state.size(),
	])
	print("Run: phase=%s cargo=%d secured=%d lootRemaining=%d repairs=%d extract=%.2f/%.2f stations=%s" % [
		str(NetworkRuntime.run_state.get("phase", "running")),
		int(NetworkRuntime.run_state.get("cargo_count", 0)),
		int(NetworkRuntime.run_state.get("cargo_secured", 0)),
		int(NetworkRuntime.run_state.get("loot_remaining", 0)),
		int(NetworkRuntime.run_state.get("repair_actions", 0)),
		float(NetworkRuntime.run_state.get("extraction_progress", 0.0)),
		float(NetworkRuntime.run_state.get("extraction_duration", 0.0)),
		", ".join(station_summaries),
	])

func _on_peer_snapshot_changed(snapshot: Dictionary) -> void:
	print("Peer snapshot updated: %s" % [snapshot])

func _on_helm_changed(driver_peer_id: int) -> void:
	print("Helm changed: peer=%d name=%s" % [driver_peer_id, NetworkRuntime.get_driver_name()])

func _on_station_state_changed(_stations: Dictionary) -> void:
	print("Stations updated: helm=%s brace=%s grapple=%s repair=%s" % [
		NetworkRuntime.get_station_occupant_name("helm"),
		NetworkRuntime.get_station_occupant_name("brace"),
		NetworkRuntime.get_station_occupant_name("grapple"),
		NetworkRuntime.get_station_occupant_name("repair"),
	])

func _on_run_state_changed(_state: Dictionary) -> void:
	var summary := "phase=%s cargo=%d secured=%d repairs=%d message=%s" % [
		str(NetworkRuntime.run_state.get("phase", "running")),
		int(NetworkRuntime.run_state.get("cargo_count", 0)),
		int(NetworkRuntime.run_state.get("cargo_secured", 0)),
		int(NetworkRuntime.run_state.get("repair_actions", 0)),
		str(NetworkRuntime.run_state.get("result_message", "")),
	]
	if summary == last_run_summary:
		return
	last_run_summary = summary
	print("Run state updated: %s" % summary)

func _on_loot_state_changed(_loot_targets: Array) -> void:
	print("Loot state updated: remaining=%d" % NetworkRuntime.loot_state.size())
