extends Node3D

const RunWorldGenerator = preload("res://systems/worldgen/run_world_generator.gd")

const SERVER_WORLD_COLLISION_HEIGHT := 4.6
const SERVER_REEF_COLLISION_HEIGHT := 3.2
const SERVER_WORLD_EDGE_SIZE_FACTOR := 0.96
const SERVER_REEF_COLLISION_SIZE_FACTOR := 0.72
const SERVER_WORLD_COLLISION_Y_OFFSET := 0.46

var heartbeat_timer: Timer
var world_collision_root: Node3D
var last_run_summary := ""
var last_world_collision_debug_snapshot: Dictionary = {}
var _world_collision_signature := 0

func _ready() -> void:
	print("Run server ready with seed %d on port %d." % [NetworkRuntime.run_seed, NetworkRuntime.current_port])
	NetworkRuntime.register_server_world_query_root(self)
	NetworkRuntime.session_phase_changed.connect(_on_session_phase_changed)
	NetworkRuntime.boat_blueprint_changed.connect(_on_boat_blueprint_changed)
	NetworkRuntime.peer_snapshot_changed.connect(_on_peer_snapshot_changed)
	NetworkRuntime.helm_changed.connect(_on_helm_changed)
	NetworkRuntime.station_state_changed.connect(_on_station_state_changed)
	NetworkRuntime.run_state_changed.connect(_on_run_state_changed)
	NetworkRuntime.loot_state_changed.connect(_on_loot_state_changed)

	world_collision_root = Node3D.new()
	world_collision_root.name = "WorldCollisionRoot"
	add_child(world_collision_root)

	heartbeat_timer = Timer.new()
	heartbeat_timer.wait_time = 1.5
	heartbeat_timer.autostart = true
	heartbeat_timer.timeout.connect(_on_heartbeat_timeout)
	add_child(heartbeat_timer)

	_refresh_world_collision_geometry()
	last_world_collision_debug_snapshot = NetworkRuntime.get_world_collision_debug_snapshot()

func _exit_tree() -> void:
	NetworkRuntime.clear_server_world_query_root(self)

func _process(delta: float) -> void:
	NetworkRuntime.server_step_shared_boat(delta)

func _build_world_collision_signature() -> int:
	if NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_RUN:
		return 0
	var blocked_entries := PackedStringArray()
	for descriptor_variant in Array(NetworkRuntime.run_state.get("chunk_descriptors", [])):
		var descriptor: Dictionary = descriptor_variant
		if not bool(descriptor.get("is_blocked", false)):
			continue
		var coord := RunWorldGenerator._coord_from_variant(descriptor.get("coord", [0, 0]))
		blocked_entries.append("%d:%d:%s:%d" % [
			coord.x,
			coord.y,
			str(descriptor.get("biome_id", RunWorldGenerator.BIOME_OPEN_OCEAN)),
			1 if bool(descriptor.get("is_border_chunk", false)) else 0,
		])
	blocked_entries.sort()
	blocked_entries.append(str(Array(NetworkRuntime.run_state.get("world_bounds_chunks", [])).hash()))
	blocked_entries.append(str(int(NetworkRuntime.run_seed)))
	return "\n".join(blocked_entries).hash()

func _refresh_world_collision_geometry() -> void:
	var signature := _build_world_collision_signature()
	if signature == _world_collision_signature:
		return
	_world_collision_signature = signature
	_clear_world_collision_geometry()
	if signature == 0:
		return
	var chunk_size := float(NetworkRuntime.run_state.get("chunk_size_m", RunWorldGenerator.CHUNK_SIZE_M))
	for descriptor_variant in Array(NetworkRuntime.run_state.get("chunk_descriptors", [])):
		var descriptor: Dictionary = descriptor_variant
		if not bool(descriptor.get("is_blocked", false)):
			continue
		_add_blocked_chunk_collision(descriptor, chunk_size)

func _clear_world_collision_geometry() -> void:
	if world_collision_root == null:
		return
	for child in world_collision_root.get_children():
		child.free()

func _add_blocked_chunk_collision(descriptor: Dictionary, chunk_size: float) -> void:
	if world_collision_root == null:
		return
	var is_border := bool(descriptor.get("is_border_chunk", false))
	var biome_id := str(descriptor.get("biome_id", RunWorldGenerator.BIOME_OPEN_OCEAN))
	var center: Vector3 = descriptor.get("world_center", Vector3.ZERO)
	var size_factor := SERVER_WORLD_EDGE_SIZE_FACTOR if is_border else SERVER_REEF_COLLISION_SIZE_FACTOR
	var height := SERVER_WORLD_COLLISION_HEIGHT if is_border else SERVER_REEF_COLLISION_HEIGHT
	var label := "World edge" if is_border else "Reef shelf"
	var damage_scale := 0.9 if is_border else 1.15
	if biome_id == RunWorldGenerator.BIOME_GRAVEYARD_WATERS:
		label = "Wreck shoal"
		damage_scale = 1.0
	elif biome_id == RunWorldGenerator.BIOME_STORM_BELT and not is_border:
		label = "Storm shelf"
		damage_scale = 1.05

	var body := StaticBody3D.new()
	body.name = "Collision_%d_%d" % [int(center.x), int(center.z)]
	body.position = center + Vector3(0.0, SERVER_WORLD_COLLISION_Y_OFFSET, 0.0)
	body.collision_layer = NetworkRuntime.SERVER_WORLD_GEOMETRY_COLLISION_LAYER
	body.collision_mask = 0
	body.set_meta("collision_label", label)
	body.set_meta("collision_damage_scale", damage_scale)
	body.set_meta("contact_radius", maxf(1.2, chunk_size * size_factor * 0.42))

	var collision_shape := CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(chunk_size * size_factor, height, chunk_size * size_factor)
	collision_shape.shape = box_shape
	body.add_child(collision_shape)
	world_collision_root.add_child(body)

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
	print("Session: phase=%s blueprintVersion=%d blocks=%d loose=%d" % [
		NetworkRuntime.get_session_phase(),
		int(NetworkRuntime.boat_blueprint.get("version", 1)),
		int(NetworkRuntime.get_blueprint_stats().get("block_count", 0)),
		int(NetworkRuntime.get_blueprint_stats().get("loose_blocks", 0)),
	])
	var progression_snapshot := NetworkRuntime.get_progression_state()
	var last_unlock := Dictionary(progression_snapshot.get("last_unlock", {}))
	print("Workshop: gold=%d materials=%d unlocked=%d lastCraft=%s" % [
		int(progression_snapshot.get("total_gold", 0)),
		int(progression_snapshot.get("total_salvage", 0)),
		Array(progression_snapshot.get("unlocked_blocks", [])).size(),
		str(last_unlock.get("label", "None")),
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
	print("Runtime boat: blocks=%d active=%d destroyed=%d detachedChunks=%d sinking=%d cargoLost=%d" % [
		Array(NetworkRuntime.boat_state.get("runtime_blocks", [])).size(),
		int(NetworkRuntime.boat_state.get("active_block_count", 0)),
		int(NetworkRuntime.boat_state.get("destroyed_block_count", 0)),
		int(NetworkRuntime.run_state.get("detached_chunk_count", 0)),
		Array(NetworkRuntime.boat_state.get("sinking_chunks", [])).size(),
		int(NetworkRuntime.run_state.get("cargo_lost_to_sea", 0)),
	])
	_print_world_collision_heartbeat()
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

func _print_world_collision_heartbeat() -> void:
	var snapshot: Dictionary = NetworkRuntime.get_world_collision_debug_snapshot()
	var previous: Dictionary = last_world_collision_debug_snapshot
	last_world_collision_debug_snapshot = snapshot.duplicate(true)
	print("World collision: bodies=%d q=%d (+%d) cast=%d (+%d) overlap=%d (+%d) resolved=%d (+%d) slides=%d (+%d) missing=%d" % [
		world_collision_root.get_child_count() if world_collision_root != null else 0,
		int(snapshot.get("query_count", 0)),
		int(snapshot.get("query_count", 0)) - int(previous.get("query_count", 0)),
		int(snapshot.get("cast_query_hits", 0)),
		int(snapshot.get("cast_query_hits", 0)) - int(previous.get("cast_query_hits", 0)),
		int(snapshot.get("overlap_query_hits", 0)),
		int(snapshot.get("overlap_query_hits", 0)) - int(previous.get("overlap_query_hits", 0)),
		int(snapshot.get("resolved_hits", 0)),
		int(snapshot.get("resolved_hits", 0)) - int(previous.get("resolved_hits", 0)),
		int(snapshot.get("slide_resolutions", 0)),
		int(snapshot.get("slide_resolutions", 0)) - int(previous.get("slide_resolutions", 0)),
		int(snapshot.get("missing_space_queries", 0)),
	])
	print("World collision last: label=%s zone=%s dmg=%.1f scale=%.2f motion=%.2f slide=%.2f safe=%.2f braced=%s tick=%d" % [
		str(snapshot.get("last_label", "none")),
		str(snapshot.get("last_zone", "n/a")),
		float(snapshot.get("last_damage", 0.0)),
		float(snapshot.get("last_damage_scale", 1.0)),
		float(snapshot.get("last_motion_m", 0.0)),
		float(snapshot.get("last_slide_m", 0.0)),
		float(snapshot.get("last_safe_fraction", 1.0)),
		"yes" if bool(snapshot.get("last_braced", false)) else "no",
		int(snapshot.get("last_collision_tick", 0)),
	])

func _on_peer_snapshot_changed(snapshot: Dictionary) -> void:
	print("Peer snapshot updated: %s" % [snapshot])

func _on_session_phase_changed(phase: String) -> void:
	print("Session phase changed: %s" % phase)
	_refresh_world_collision_geometry()

func _on_boat_blueprint_changed(_snapshot: Dictionary) -> void:
	print("Blueprint changed: version=%d blocks=%d loose=%d warnings=%s" % [
		int(NetworkRuntime.boat_blueprint.get("version", 1)),
		int(NetworkRuntime.get_blueprint_stats().get("block_count", 0)),
		int(NetworkRuntime.get_blueprint_stats().get("loose_blocks", 0)),
		str(NetworkRuntime.get_blueprint_warnings()),
	])

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
	_refresh_world_collision_geometry()
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
