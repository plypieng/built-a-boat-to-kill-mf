extends Node3D

const HANGAR_SCENE := "res://scenes/hangar/hangar.tscn"
const HudIconLibrary = preload("res://scenes/shared/hud_icon_library.gd")
const IDLE_CREW_SLOTS := [
	Vector3(0.0, 0.92, 1.35),
	Vector3(-1.2, 0.92, 1.05),
	Vector3(1.2, 0.92, 1.05),
	Vector3(0.0, 0.92, 2.1),
]

const STATION_BASE_COLOR := Color(0.29, 0.56, 0.78)
const STATION_SELECTED_COLOR := Color(0.97, 0.82, 0.28)
const STATION_OCCUPIED_COLOR := Color(0.88, 0.34, 0.26)
const STATION_LOCAL_COLOR := Color(0.30, 0.82, 0.52)
const EXTRACTION_IDLE_COLOR := Color(0.30, 0.62, 0.86)
const EXTRACTION_READY_COLOR := Color(0.21, 0.82, 0.57)
const EXTRACTION_FAILED_COLOR := Color(0.84, 0.25, 0.24)
const RUN_AVATAR_MOVE_SPEED := 4.9
const RUN_AVATAR_ACCELERATION := 15.0
const RUN_SWIM_MOVE_SPEED := 2.6
const RUN_SWIM_ACCELERATION := 8.5
const RUN_AVATAR_SYNC_INTERVAL := 0.05
const HUD_PANEL_BG := Color(0.05, 0.09, 0.13, 0.78)
const HUD_PANEL_BG_SOFT := Color(0.07, 0.12, 0.17, 0.70)
const HUD_BORDER_BLUE := Color(0.30, 0.53, 0.66, 0.92)
const HUD_BORDER_ORANGE := Color(0.83, 0.59, 0.28, 0.95)
const HUD_BORDER_GREEN := Color(0.28, 0.71, 0.54, 0.95)
const HUD_TEXT_PRIMARY := Color(0.96, 0.95, 0.90)
const HUD_TEXT_MUTED := Color(0.78, 0.84, 0.88)
const HUD_TEXT_WARNING := Color(0.95, 0.80, 0.43)
const HUD_TEXT_DANGER := Color(0.95, 0.55, 0.48)
const HUD_TEXT_SUCCESS := Color(0.76, 0.95, 0.82)

@export_group("Run Camera")
@export_range(-3.0, 3.0, 0.05) var run_camera_side_offset := 0.9
@export_range(0.5, 6.0, 0.05) var run_camera_height := 2.2
@export_range(1.0, 14.0, 0.05) var run_camera_distance := 5.9
@export_range(0.5, 4.0, 0.05) var run_camera_look_height := 1.32
@export_range(0.0, 6.0, 0.05) var run_camera_look_ahead := 2.1
@export_range(0.1, 20.0, 0.1) var run_camera_lag := 8.0
@export_range(0.001, 0.02, 0.0001) var run_mouse_look_sensitivity := 0.0035
@export_range(-89.0, 0.0, 0.5) var run_camera_pitch_min_degrees := -58.0
@export_range(0.0, 89.0, 0.5) var run_camera_pitch_max_degrees := 44.0
@export_range(-45.0, 45.0, 0.5) var run_camera_pitch_default_degrees := -10.0

var status_label: Label
var objective_label: Label
var onboarding_label: Label
var resource_label: Label
var run_label: Label
var station_label: Label
var interaction_label: Label
var roster_label: Label
var boat_label: Label
var event_callout_label: Label
var toolbelt_label: Label
var inventory_label: Label
var footer_label: Label
var boat_root: Node3D
var hull_mesh_instance: MeshInstance3D
var hull_material: StandardMaterial3D
var deck_mesh_instance: MeshInstance3D
var mast_mesh_instance: MeshInstance3D
var main_block_container: Node3D
var sinking_chunk_container: Node3D
var crew_container: Node3D
var hazard_container: Node3D
var squall_container: Node3D
var station_container: Node3D
var recovery_container: Node3D
var loot_container: Node3D
var wreck_root: Node3D
var wreck_ring_material: StandardMaterial3D
var wreck_hull_material: StandardMaterial3D
var wreck_label: Label3D
var rescue_root: Node3D
var rescue_ring_material: StandardMaterial3D
var rescue_flare_material: StandardMaterial3D
var rescue_label: Label3D
var cache_root: Node3D
var cache_ring_material: StandardMaterial3D
var cache_crate_material: StandardMaterial3D
var cache_label: Label3D
var extraction_root: Node3D
var extraction_ring_material: StandardMaterial3D
var extraction_buoy_material: StandardMaterial3D
var extraction_label: Label3D
var camera: Camera3D
var result_layer: CanvasLayer
var result_panel: PanelContainer
var result_title_label: Label
var result_body_label: Label
var result_continue_button: Button
var crosshair_label: Label
var tool_panel: PanelContainer
var inventory_panel: PanelContainer
var launch_overrides: Dictionary = {}
var connect_time_seconds := 0.0
var autopilot_remaining_seconds := 0.0
var station_request_cooldown := 0.0
var action_request_cooldown := 0.0
var station_prev_latched := false
var station_next_latched := false
var interact_latched := false
var brace_request_latched := false
var grapple_request_latched := false
var repair_request_latched := false
var recover_request_latched := false
var selected_station_index := 0
var last_known_phase := "running"
var station_visuals: Dictionary = {}
var hazard_visuals: Dictionary = {}
var loot_visuals: Dictionary = {}
var main_block_visuals: Dictionary = {}
var sinking_chunk_visuals: Dictionary = {}
var crew_visuals: Dictionary = {}
var squall_visuals: Dictionary = {}
var run_result_recorded := false
var auto_continue_queued := false
var reaction_visual_state: Dictionary = {}
var last_local_reaction_id := 0
var local_camera_jolt := Vector3.ZERO
var local_avatar_facing_y := PI
var local_camera_pitch := deg_to_rad(-10.0)
var local_run_avatar_position := IDLE_CREW_SLOTS[0]
var local_run_avatar_world_position := Vector3.ZERO
var local_run_avatar_velocity := Vector3.ZERO
var local_run_avatar_mode := NetworkRuntime.RUN_AVATAR_MODE_DECK
var run_avatar_sync_timer := 0.0
var autorun_overboard_forced := false
var event_callout_timer := 0.0
var event_callout_color := HUD_TEXT_PRIMARY
var last_hud_collision_count := 0
var last_hud_detached_chunk_count := 0
var last_hud_cargo_lost_to_sea := 0
var last_hud_rescue_completed := false
var last_hud_cache_recovered := false
var last_hud_overboard_count := 0
var last_hud_phase := "running"
var last_local_overboard := false
var selected_run_tool_index := 0
var inventory_panel_visible := false
var hud_icons := HudIconLibrary.new()
var objective_icon: TextureRect
var extraction_panel_icon: TextureRect
var crew_panel_icon: TextureRect
var survival_panel_icon: TextureRect
var result_panel_icon: TextureRect

func _ready() -> void:
	launch_overrides = GameConfig.parse_cmdline_overrides()
	local_camera_pitch = _get_run_camera_pitch_default()
	_build_world()
	_build_hud()
	_build_result_overlay()
	_prime_local_run_avatar_state()
	_set_mouse_capture(true)
	_refresh_world()
	_refresh_hud()
	_schedule_frame_capture()
	_schedule_optional_quit()
	_initialize_autopilot()
	_prime_run_hud_event_state()
	print("Run client ready with seed %d and peer id %d." % [NetworkRuntime.run_seed, _get_local_peer_id()])

	NetworkRuntime.status_changed.connect(_on_status_changed)
	NetworkRuntime.session_phase_changed.connect(_on_session_phase_changed)
	NetworkRuntime.peer_snapshot_changed.connect(_on_peer_snapshot_changed)
	NetworkRuntime.run_avatar_state_changed.connect(_on_run_avatar_state_changed)
	NetworkRuntime.reaction_state_changed.connect(_on_reaction_state_changed)
	NetworkRuntime.run_seed_changed.connect(_on_run_seed_changed)
	NetworkRuntime.helm_changed.connect(_on_helm_changed)
	NetworkRuntime.boat_state_changed.connect(_on_boat_state_changed)
	NetworkRuntime.hazard_state_changed.connect(_on_hazard_state_changed)
	NetworkRuntime.station_state_changed.connect(_on_station_state_changed)
	NetworkRuntime.loot_state_changed.connect(_on_loot_state_changed)
	NetworkRuntime.run_state_changed.connect(_on_run_state_changed)
	NetworkRuntime.progression_state_changed.connect(_on_progression_state_changed)
	reaction_visual_state = NetworkRuntime.get_reaction_state()

func _process(delta: float) -> void:
	connect_time_seconds += delta
	_tick_reaction_visuals(delta)
	_update_boat_visual(delta)
	_update_runtime_block_visuals()
	_update_sinking_chunk_visuals(delta)
	_update_crew_visuals(delta)
	_update_hazard_visuals()
	_update_loot_visuals()
	_update_wreck_visual()
	_update_rescue_visual()
	_update_cache_visual()
	_update_squall_visuals()
	_update_extraction_visual(delta)
	_update_camera(delta)
	_update_event_callout(delta)

func _physics_process(delta: float) -> void:
	station_request_cooldown = maxf(0.0, station_request_cooldown - delta)
	action_request_cooldown = maxf(0.0, action_request_cooldown - delta)
	_process_local_run_avatar_movement(delta)
	_sync_local_run_avatar_state(delta)

	var input_state := _collect_input_state(delta)
	var claim_station_id := str(input_state.get("claim_station", ""))
	if claim_station_id == "__release__":
		NetworkRuntime.request_station_release()
	elif not claim_station_id.is_empty():
		_select_station(claim_station_id)
		NetworkRuntime.request_station_claim(claim_station_id)

	if bool(input_state.get("request_brace", false)):
		NetworkRuntime.request_brace()
	if bool(input_state.get("request_grapple", false)):
		NetworkRuntime.request_grapple()
	if bool(input_state.get("request_repair", false)):
		NetworkRuntime.request_repair()
	if bool(input_state.get("request_recover", false)):
		NetworkRuntime.request_overboard_recovery()

	if not _is_local_overboard() and NetworkRuntime.get_peer_station_id(_get_local_peer_id()) == "helm":
		NetworkRuntime.send_local_boat_input(
			float(input_state.get("throttle", 0.0)),
			float(input_state.get("steer", 0.0))
		)

func _build_world() -> void:
	_ensure_world_environment()
	if get_node_or_null("Environment/Water") == null:
		_build_static_world_fallback()

	hazard_container = _ensure_root_node3d("HazardContainer")
	squall_container = _ensure_root_node3d("SquallContainer")
	loot_container = _ensure_root_node3d("LootContainer")

	wreck_root = _ensure_root_node3d("WreckRoot")
	_build_wreck_visual()

	rescue_root = _ensure_root_node3d("RescueRoot")
	_build_rescue_visual()

	cache_root = _ensure_root_node3d("CacheRoot")
	_build_cache_visual()

	extraction_root = _ensure_root_node3d("ExtractionRoot")
	_build_extraction_visual()

	sinking_chunk_container = _ensure_root_node3d("SinkingChunkContainer")

	boat_root = _ensure_root_node3d("BoatRoot")

	main_block_container = _ensure_child_node3d(boat_root, "MainBlockContainer")

	hull_mesh_instance = boat_root.get_node_or_null("HullMesh") as MeshInstance3D
	if hull_mesh_instance == null:
		hull_mesh_instance = MeshInstance3D.new()
		hull_mesh_instance.name = "HullMesh"
		var hull_mesh := BoxMesh.new()
		hull_mesh.size = Vector3(3.3, 0.72, 6.2)
		hull_mesh_instance.mesh = hull_mesh
		hull_mesh_instance.position = Vector3(0.0, 0.35, 0.0)
		boat_root.add_child(hull_mesh_instance)
	hull_material = hull_mesh_instance.material_override as StandardMaterial3D
	if hull_material == null:
		hull_material = StandardMaterial3D.new()
		hull_material.albedo_color = Color(0.44, 0.27, 0.16)
		hull_material.roughness = 0.46
		hull_mesh_instance.material_override = hull_material

	deck_mesh_instance = boat_root.get_node_or_null("DeckMesh") as MeshInstance3D
	if deck_mesh_instance == null:
		deck_mesh_instance = MeshInstance3D.new()
		deck_mesh_instance.name = "DeckMesh"
		var deck_mesh := BoxMesh.new()
		deck_mesh.size = Vector3(2.7, 0.14, 4.6)
		deck_mesh_instance.mesh = deck_mesh
		deck_mesh_instance.position = Vector3(0.0, 0.78, 0.0)
		var deck_material := StandardMaterial3D.new()
		deck_material.albedo_color = Color(0.70, 0.56, 0.34)
		deck_mesh_instance.material_override = deck_material
		boat_root.add_child(deck_mesh_instance)

	mast_mesh_instance = boat_root.get_node_or_null("MastMesh") as MeshInstance3D
	if mast_mesh_instance == null:
		mast_mesh_instance = MeshInstance3D.new()
		mast_mesh_instance.name = "MastMesh"
		var mast_mesh := CylinderMesh.new()
		mast_mesh.height = 3.0
		mast_mesh.top_radius = 0.12
		mast_mesh.bottom_radius = 0.12
		mast_mesh_instance.mesh = mast_mesh
		mast_mesh_instance.position = Vector3(0.0, 2.0, -0.2)
		var mast_material := StandardMaterial3D.new()
		mast_material.albedo_color = Color(0.82, 0.79, 0.72)
		mast_mesh_instance.material_override = mast_material
		boat_root.add_child(mast_mesh_instance)

	station_container = _ensure_child_node3d(boat_root, "StationContainer")
	_build_station_visuals()
	recovery_container = _ensure_child_node3d(boat_root, "RecoveryContainer")
	_build_recovery_visuals()

	crew_container = _ensure_child_node3d(boat_root, "CrewContainer")

	camera = get_node_or_null("RunCamera") as Camera3D
	if camera == null:
		camera = Camera3D.new()
		camera.name = "RunCamera"
		camera.position = Vector3(0.0, 5.5, 10.5)
		add_child(camera)
	camera.current = true
	camera.look_at(Vector3(0.0, 0.6, 0.0), Vector3.UP)

func _ensure_world_environment() -> void:
	var world_environment := get_node_or_null("Environment/WorldEnvironment") as WorldEnvironment
	if world_environment == null:
		world_environment = get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_environment != null:
		return
	world_environment = WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	world_environment.environment = _make_default_environment_resource()
	add_child(world_environment)

func _make_default_environment_resource() -> Environment:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.46, 0.71, 0.92)
	return environment

func _build_static_world_fallback() -> void:
	var fallback_root := get_node_or_null("EnvironmentFallback") as Node3D
	if fallback_root == null:
		fallback_root = Node3D.new()
		fallback_root.name = "EnvironmentFallback"
		add_child(fallback_root)

	var light := DirectionalLight3D.new()
	light.name = "SunLight"
	light.light_energy = 1.2
	light.rotation_degrees = Vector3(-48.0, 38.0, 0.0)
	fallback_root.add_child(light)

	var water := MeshInstance3D.new()
	water.name = "Water"
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(220.0, 220.0)
	water.mesh = water_mesh
	var water_material := StandardMaterial3D.new()
	water_material.albedo_color = Color(0.08, 0.43, 0.65)
	water_material.roughness = 0.14
	water.material_override = water_material
	fallback_root.add_child(water)

func _ensure_root_node3d(node_name: String) -> Node3D:
	var node := get_node_or_null(node_name) as Node3D
	if node != null:
		return node
	node = Node3D.new()
	node.name = node_name
	add_child(node)
	return node

func _ensure_child_node3d(parent: Node3D, node_name: String) -> Node3D:
	var node := parent.get_node_or_null(node_name) as Node3D
	if node != null:
		return node
	node = Node3D.new()
	node.name = node_name
	parent.add_child(node)
	return node

func _get_run_camera_pitch_min() -> float:
	return deg_to_rad(run_camera_pitch_min_degrees)

func _get_run_camera_pitch_max() -> float:
	return deg_to_rad(run_camera_pitch_max_degrees)

func _get_run_camera_pitch_default() -> float:
	return deg_to_rad(run_camera_pitch_default_degrees)

func _supports_mouse_capture() -> bool:
	return DisplayServer.get_name() != "headless"

func _is_mouse_captured() -> bool:
	return _supports_mouse_capture() and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED

func _set_mouse_capture(captured: bool) -> void:
	if not _supports_mouse_capture():
		return
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE)

func _prime_local_run_avatar_state() -> void:
	var local_peer_id := _get_local_peer_id()
	var snapshot: Dictionary = NetworkRuntime.get_run_avatar_state().get(local_peer_id, {})
	if snapshot.is_empty():
		local_run_avatar_position = IDLE_CREW_SLOTS[0]
		local_run_avatar_world_position = boat_root.to_global(local_run_avatar_position)
		local_run_avatar_velocity = Vector3.ZERO
		local_run_avatar_mode = NetworkRuntime.RUN_AVATAR_MODE_DECK
		local_avatar_facing_y = PI
		return
	local_run_avatar_position = snapshot.get("deck_position", IDLE_CREW_SLOTS[0])
	local_run_avatar_world_position = snapshot.get("world_position", boat_root.to_global(local_run_avatar_position))
	local_run_avatar_velocity = snapshot.get("velocity", Vector3.ZERO)
	local_run_avatar_mode = str(snapshot.get("mode", NetworkRuntime.RUN_AVATAR_MODE_DECK))
	local_avatar_facing_y = float(snapshot.get("facing_y", PI))

func _clamp_run_avatar_position(deck_position: Vector3) -> Vector3:
	return Vector3(
		clampf(deck_position.x, NetworkRuntime.RUN_DECK_BOUNDS_MIN.x, NetworkRuntime.RUN_DECK_BOUNDS_MAX.x),
		clampf(deck_position.y, NetworkRuntime.RUN_DECK_BOUNDS_MIN.y, NetworkRuntime.RUN_DECK_BOUNDS_MAX.y),
		clampf(deck_position.z, NetworkRuntime.RUN_DECK_BOUNDS_MIN.z, NetworkRuntime.RUN_DECK_BOUNDS_MAX.z)
	)

func _get_local_run_avatar_target() -> Vector3:
	var local_station_id := NetworkRuntime.get_peer_station_id(_get_local_peer_id())
	if local_station_id.is_empty() or not _station_anchors_avatar(local_station_id):
		return local_run_avatar_position
	return NetworkRuntime.get_station_position(local_station_id) + Vector3(0.0, 0.18, 0.0)

func _is_local_overboard() -> bool:
	return local_run_avatar_mode == NetworkRuntime.RUN_AVATAR_MODE_OVERBOARD

func _get_local_avatar_world_position() -> Vector3:
	if _is_local_overboard():
		return local_run_avatar_world_position
	return boat_root.to_global(local_run_avatar_position)

func _clamp_local_swim_world_position(world_position: Vector3) -> Vector3:
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var offset := world_position - boat_position
	offset.y = 0.0
	if offset.length() > NetworkRuntime.RUN_OVERBOARD_SWIM_RADIUS:
		offset = offset.normalized() * NetworkRuntime.RUN_OVERBOARD_SWIM_RADIUS
	var sanitized_position := boat_position + offset
	sanitized_position.y = NetworkRuntime.RUN_OVERBOARD_WATER_HEIGHT
	return sanitized_position

func _get_local_recovery_target() -> Dictionary:
	var local_state: Dictionary = NetworkRuntime.get_run_avatar_state().get(_get_local_peer_id(), {})
	if local_state.is_empty():
		return {}
	var target_id := str(local_state.get("recovery_target_id", ""))
	if target_id.is_empty():
		return {}
	for target_variant in NetworkRuntime.RUN_RECOVERY_POINTS:
		var target: Dictionary = target_variant
		if str(target.get("id", "")) != target_id:
			continue
		var water_position: Vector3 = target.get("water_position", Vector3.ZERO)
		var world_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO) + water_position.rotated(Vector3.UP, float(NetworkRuntime.boat_state.get("rotation_y", 0.0)))
		world_position.y = NetworkRuntime.RUN_OVERBOARD_WATER_HEIGHT
		var normalized := target.duplicate(true)
		normalized["world_position"] = world_position
		normalized["ready"] = bool(local_state.get("recovery_ready", false))
		return normalized
	return {}

func _scripted_move_local_avatar_toward_world(target_world_position: Vector3, delta: float) -> void:
	if delta <= 0.0:
		return
	var offset := target_world_position - local_run_avatar_world_position
	offset.y = 0.0
	if offset.length() <= 0.04:
		local_run_avatar_velocity = Vector3.ZERO
		return
	var direction := offset.normalized()
	local_run_avatar_velocity.x = move_toward(local_run_avatar_velocity.x, direction.x * RUN_SWIM_MOVE_SPEED, RUN_SWIM_ACCELERATION * delta)
	local_run_avatar_velocity.z = move_toward(local_run_avatar_velocity.z, direction.z * RUN_SWIM_MOVE_SPEED, RUN_SWIM_ACCELERATION * delta)
	local_run_avatar_world_position += Vector3(local_run_avatar_velocity.x, 0.0, local_run_avatar_velocity.z) * delta
	local_run_avatar_world_position = _clamp_local_swim_world_position(local_run_avatar_world_position)
	local_avatar_facing_y = atan2(-direction.x, -direction.z)

func _get_claimable_station_ids() -> Array:
	return NetworkRuntime.get_claimable_station_ids()

func _station_anchors_avatar(station_id: String) -> bool:
	return station_id == "grapple"

func _get_station_claim_radius(station_id: String) -> float:
	match station_id:
		"helm":
			return NetworkRuntime.RUN_HELM_ZONE_RADIUS
		"grapple":
			return NetworkRuntime.RUN_GRAPPLE_ZONE_RADIUS
		_:
			return 0.0

func _is_local_near_station(station_id: String, extra_margin: float = 0.0) -> bool:
	var claim_radius := _get_station_claim_radius(station_id)
	if claim_radius <= 0.0:
		return false
	return local_run_avatar_position.distance_to(NetworkRuntime.get_station_position(station_id)) <= (claim_radius + maxf(0.0, extra_margin))

func _find_local_repair_target() -> Dictionary:
	var nearest_block: Dictionary = {}
	var nearest_distance := NetworkRuntime.RUN_REPAIR_RANGE
	for block_variant in Array(NetworkRuntime.boat_state.get("runtime_blocks", [])):
		var block_state: Dictionary = block_variant
		var block := _build_runtime_block_render_data(block_state)
		if block.is_empty() or bool(block.get("destroyed", false)) or bool(block.get("detached", false)):
			continue
		if float(block.get("current_hp", 0.0)) >= float(block.get("max_hp", 0.0)) - 0.01:
			continue
		var local_position: Vector3 = block.get("local_position", Vector3.ZERO)
		var distance := local_run_avatar_position.distance_to(local_position)
		if distance > nearest_distance:
			continue
		nearest_distance = distance
		nearest_block = block.duplicate(true)
		nearest_block["repair_distance"] = distance
	return nearest_block

func _scripted_move_local_avatar_toward(target_position: Vector3, delta: float) -> void:
	if delta <= 0.0:
		return
	var offset := target_position - local_run_avatar_position
	offset.y = 0.0
	if offset.length() <= 0.04:
		local_run_avatar_velocity = Vector3.ZERO
		return
	var direction := offset.normalized()
	local_run_avatar_velocity.x = move_toward(local_run_avatar_velocity.x, direction.x * RUN_AVATAR_MOVE_SPEED, RUN_AVATAR_ACCELERATION * delta)
	local_run_avatar_velocity.z = move_toward(local_run_avatar_velocity.z, direction.z * RUN_AVATAR_MOVE_SPEED, RUN_AVATAR_ACCELERATION * delta)
	local_run_avatar_position += Vector3(local_run_avatar_velocity.x, 0.0, local_run_avatar_velocity.z) * delta
	local_run_avatar_position = _clamp_run_avatar_position(local_run_avatar_position)
	local_avatar_facing_y = atan2(-direction.x, -direction.z)
	local_run_avatar_world_position = _get_local_avatar_world_position()
	NetworkRuntime.send_local_run_avatar_state(
		local_run_avatar_position,
		local_run_avatar_world_position,
		Vector3(local_run_avatar_velocity.x, 0.0, local_run_avatar_velocity.z),
		local_avatar_facing_y,
		true,
		local_run_avatar_mode
	)

func _build_station_visuals() -> void:
	station_visuals = {}
	for station_id in NetworkRuntime.get_station_ids():
		var station_node := Node3D.new()
		station_node.position = NetworkRuntime.get_station_position(station_id)
		station_container.add_child(station_node)

		var base_mesh := MeshInstance3D.new()
		base_mesh.name = "Base"
		var cylinder := CylinderMesh.new()
		cylinder.height = 0.12
		cylinder.top_radius = 0.24
		cylinder.bottom_radius = 0.28
		base_mesh.mesh = cylinder
		base_mesh.position = Vector3(0.0, 0.06, 0.0)
		station_node.add_child(base_mesh)

		var beacon_mesh := MeshInstance3D.new()
		beacon_mesh.name = "Beacon"
		var beacon_shape := SphereMesh.new()
		beacon_shape.radius = 0.18
		beacon_shape.height = 0.36
		beacon_mesh.mesh = beacon_shape
		beacon_mesh.position = Vector3(0.0, 0.34, 0.0)
		station_node.add_child(beacon_mesh)

		var label := Label3D.new()
		label.name = "Label"
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 22
		label.position = Vector3(0.0, 0.92, 0.0)
		station_node.add_child(label)

		station_visuals[station_id] = {
			"root": station_node,
			"base": base_mesh,
			"beacon": beacon_mesh,
			"label": label,
		}

func _build_recovery_visuals() -> void:
	if recovery_container == null:
		return
	for child in recovery_container.get_children():
		child.queue_free()
	for target_variant in NetworkRuntime.RUN_RECOVERY_POINTS:
		var target: Dictionary = target_variant
		var target_node := Node3D.new()
		target_node.name = "%sMarker" % str(target.get("id", "Recovery"))
		target_node.position = target.get("water_position", Vector3.ZERO)
		recovery_container.add_child(target_node)

		var ring_mesh_instance := MeshInstance3D.new()
		var ring_mesh := CylinderMesh.new()
		ring_mesh.height = 0.05
		ring_mesh.top_radius = 0.34
		ring_mesh.bottom_radius = 0.34
		ring_mesh_instance.mesh = ring_mesh
		ring_mesh_instance.position = Vector3(0.0, 0.03, 0.0)
		var ring_material := StandardMaterial3D.new()
		ring_material.albedo_color = Color(0.20, 0.70, 0.74, 0.74)
		ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring_material.roughness = 0.18
		ring_mesh_instance.material_override = ring_material
		target_node.add_child(ring_mesh_instance)

		var pole_mesh_instance := MeshInstance3D.new()
		var pole_mesh := CylinderMesh.new()
		pole_mesh.height = 0.95
		pole_mesh.top_radius = 0.05
		pole_mesh.bottom_radius = 0.05
		pole_mesh_instance.mesh = pole_mesh
		pole_mesh_instance.position = Vector3(0.0, 0.48, 0.0)
		var pole_material := StandardMaterial3D.new()
		pole_material.albedo_color = Color(0.86, 0.89, 0.92)
		pole_mesh_instance.material_override = pole_material
		target_node.add_child(pole_mesh_instance)

		var label := Label3D.new()
		label.text = str(target.get("label", "Recovery"))
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 18
		label.position = Vector3(0.0, 1.18, 0.0)
		target_node.add_child(label)

func _build_wreck_visual() -> void:
	var ring_mesh_instance := MeshInstance3D.new()
	ring_mesh_instance.name = "WreckRing"
	var ring_mesh := CylinderMesh.new()
	ring_mesh.height = 0.06
	ring_mesh.top_radius = float(NetworkRuntime.run_state.get("wreck_radius", 4.1))
	ring_mesh.bottom_radius = float(NetworkRuntime.run_state.get("wreck_radius", 4.1))
	ring_mesh_instance.mesh = ring_mesh
	ring_mesh_instance.position = Vector3(0.0, 0.03, 0.0)
	wreck_ring_material = StandardMaterial3D.new()
	wreck_ring_material.albedo_color = Color(0.87, 0.56, 0.19)
	wreck_ring_material.roughness = 0.22
	ring_mesh_instance.material_override = wreck_ring_material
	wreck_root.add_child(ring_mesh_instance)

	var wreck_hull := MeshInstance3D.new()
	wreck_hull.name = "WreckHull"
	var hull_mesh := BoxMesh.new()
	hull_mesh.size = Vector3(4.4, 0.7, 2.2)
	wreck_hull.mesh = hull_mesh
	wreck_hull.rotation_degrees = Vector3(0.0, 18.0, 14.0)
	wreck_hull.position = Vector3(-0.35, 0.55, -0.25)
	wreck_hull_material = StandardMaterial3D.new()
	wreck_hull_material.albedo_color = Color(0.38, 0.24, 0.18)
	wreck_hull.material_override = wreck_hull_material
	wreck_root.add_child(wreck_hull)

	var mast_stub := MeshInstance3D.new()
	var mast_mesh := CylinderMesh.new()
	mast_mesh.height = 1.8
	mast_mesh.top_radius = 0.08
	mast_mesh.bottom_radius = 0.1
	mast_stub.mesh = mast_mesh
	mast_stub.position = Vector3(0.55, 1.15, 0.35)
	mast_stub.rotation_degrees = Vector3(0.0, 0.0, 34.0)
	mast_stub.material_override = wreck_hull_material
	wreck_root.add_child(mast_stub)

	wreck_label = Label3D.new()
	wreck_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	wreck_label.font_size = 24
	wreck_label.position = Vector3(0.0, 2.4, 0.0)
	wreck_root.add_child(wreck_label)

func _build_rescue_visual() -> void:
	var ring_mesh_instance := MeshInstance3D.new()
	ring_mesh_instance.name = "RescueRing"
	var ring_mesh := CylinderMesh.new()
	ring_mesh.height = 0.06
	ring_mesh.top_radius = float(NetworkRuntime.run_state.get("rescue_radius", 3.4))
	ring_mesh.bottom_radius = float(NetworkRuntime.run_state.get("rescue_radius", 3.4))
	ring_mesh_instance.mesh = ring_mesh
	ring_mesh_instance.position = Vector3(0.0, 0.03, 0.0)
	rescue_ring_material = StandardMaterial3D.new()
	rescue_ring_material.albedo_color = Color(0.93, 0.72, 0.28)
	rescue_ring_material.roughness = 0.18
	ring_mesh_instance.material_override = rescue_ring_material
	rescue_root.add_child(ring_mesh_instance)

	var raft := MeshInstance3D.new()
	raft.name = "RescueRaft"
	var raft_mesh := BoxMesh.new()
	raft_mesh.size = Vector3(1.4, 0.32, 1.0)
	raft.mesh = raft_mesh
	raft.position = Vector3(0.0, 0.38, 0.0)
	rescue_flare_material = StandardMaterial3D.new()
	rescue_flare_material.albedo_color = Color(0.56, 0.37, 0.18)
	raft.material_override = rescue_flare_material
	rescue_root.add_child(raft)

	var flare := MeshInstance3D.new()
	var flare_mesh := CylinderMesh.new()
	flare_mesh.height = 1.6
	flare_mesh.top_radius = 0.09
	flare_mesh.bottom_radius = 0.11
	flare.mesh = flare_mesh
	flare.position = Vector3(0.0, 1.45, 0.0)
	flare.material_override = rescue_flare_material
	rescue_root.add_child(flare)

	var beacon := OmniLight3D.new()
	beacon.name = "RescueLight"
	beacon.position = Vector3(0.0, 2.25, 0.0)
	beacon.light_energy = 1.35
	beacon.light_color = Color(1.0, 0.64, 0.28)
	beacon.omni_range = 9.0
	rescue_root.add_child(beacon)

	rescue_label = Label3D.new()
	rescue_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	rescue_label.font_size = 22
	rescue_label.position = Vector3(0.0, 3.0, 0.0)
	rescue_root.add_child(rescue_label)

func _build_extraction_visual() -> void:
	var ring_mesh_instance := MeshInstance3D.new()
	ring_mesh_instance.name = "Ring"
	var ring_mesh := CylinderMesh.new()
	ring_mesh.height = 0.08
	ring_mesh.top_radius = float(NetworkRuntime.run_state.get("extraction_radius", 3.7))
	ring_mesh.bottom_radius = float(NetworkRuntime.run_state.get("extraction_radius", 3.7))
	ring_mesh_instance.mesh = ring_mesh
	ring_mesh_instance.position = Vector3(0.0, 0.04, 0.0)
	extraction_ring_material = StandardMaterial3D.new()
	extraction_ring_material.albedo_color = EXTRACTION_IDLE_COLOR
	extraction_ring_material.roughness = 0.22
	ring_mesh_instance.material_override = extraction_ring_material
	extraction_root.add_child(ring_mesh_instance)

	var buoy := MeshInstance3D.new()
	buoy.name = "Buoy"
	var buoy_mesh := CylinderMesh.new()
	buoy_mesh.height = 2.4
	buoy_mesh.top_radius = 0.22
	buoy_mesh.bottom_radius = 0.28
	buoy.mesh = buoy_mesh
	buoy.position = Vector3(0.0, 1.2, 0.0)
	extraction_buoy_material = StandardMaterial3D.new()
	extraction_buoy_material.albedo_color = EXTRACTION_IDLE_COLOR
	buoy.material_override = extraction_buoy_material
	extraction_root.add_child(buoy)

	var cap := MeshInstance3D.new()
	var cap_mesh := SphereMesh.new()
	cap_mesh.radius = 0.32
	cap_mesh.height = 0.64
	cap.mesh = cap_mesh
	cap.position = Vector3(0.0, 2.55, 0.0)
	cap.material_override = extraction_buoy_material
	extraction_root.add_child(cap)

	extraction_label = Label3D.new()
	extraction_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	extraction_label.font_size = 24
	extraction_label.position = Vector3(0.0, 3.35, 0.0)
	extraction_root.add_child(extraction_label)

func _build_cache_visual() -> void:
	var ring_mesh_instance := MeshInstance3D.new()
	ring_mesh_instance.name = "CacheRing"
	var ring_mesh := CylinderMesh.new()
	ring_mesh.height = 0.06
	ring_mesh.top_radius = float(NetworkRuntime.run_state.get("cache_radius", 2.9))
	ring_mesh.bottom_radius = float(NetworkRuntime.run_state.get("cache_radius", 2.9))
	ring_mesh_instance.mesh = ring_mesh
	ring_mesh_instance.position = Vector3(0.0, 0.03, 0.0)
	cache_ring_material = StandardMaterial3D.new()
	cache_ring_material.albedo_color = Color(0.23, 0.71, 0.84)
	cache_ring_material.roughness = 0.18
	ring_mesh_instance.material_override = cache_ring_material
	cache_root.add_child(ring_mesh_instance)

	var crate := MeshInstance3D.new()
	crate.name = "CacheCrate"
	var crate_mesh := BoxMesh.new()
	crate_mesh.size = Vector3(1.15, 0.9, 1.15)
	crate.mesh = crate_mesh
	crate.position = Vector3(0.0, 0.58, 0.0)
	cache_crate_material = StandardMaterial3D.new()
	cache_crate_material.albedo_color = Color(0.19, 0.48, 0.58)
	crate.material_override = cache_crate_material
	cache_root.add_child(crate)

	var beacon := MeshInstance3D.new()
	var beacon_mesh := CylinderMesh.new()
	beacon_mesh.height = 1.9
	beacon_mesh.top_radius = 0.12
	beacon_mesh.bottom_radius = 0.18
	beacon.mesh = beacon_mesh
	beacon.position = Vector3(0.0, 1.85, 0.0)
	beacon.material_override = cache_crate_material
	cache_root.add_child(beacon)

	cache_label = Label3D.new()
	cache_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	cache_label.font_size = 22
	cache_label.position = Vector3(0.0, 3.0, 0.0)
	cache_root.add_child(cache_label)

func _build_hud() -> void:
	var hud := get_node("HUD") as CanvasLayer
	var objective_panel := hud.get_node("ObjectivePanel") as PanelContainer
	var extraction_panel := hud.get_node("ExtractionPanel") as PanelContainer
	var crew_panel := hud.get_node("CrewPanel") as PanelContainer
	var survival_panel := hud.get_node("SurvivalPanel") as PanelContainer
	tool_panel = hud.get_node("ToolPanel") as PanelContainer
	inventory_panel = hud.get_node("InventoryPanel") as PanelContainer

	objective_icon = hud.get_node("ObjectivePanel/Margin/Layout/HeadingRow/ObjectiveIcon") as TextureRect
	objective_label = hud.get_node("ObjectivePanel/Margin/Layout/ObjectiveLabel") as Label
	extraction_panel_icon = hud.get_node("ExtractionPanel/Margin/Layout/Header/ExtractionPanelIcon") as TextureRect
	resource_label = hud.get_node("ExtractionPanel/Margin/Layout/ResourceLabel") as Label
	run_label = hud.get_node("ExtractionPanel/Margin/Layout/RunLabel") as Label
	crew_panel_icon = hud.get_node("CrewPanel/Margin/Layout/Header/CrewPanelIcon") as TextureRect
	station_label = hud.get_node("CrewPanel/Margin/Layout/StationLabel") as Label
	roster_label = hud.get_node("CrewPanel/Margin/Layout/RosterLabel") as Label
	onboarding_label = hud.get_node("CrewPanel/Margin/Layout/OnboardingLabel") as Label
	survival_panel_icon = hud.get_node("SurvivalPanel/Margin/Layout/Header/SurvivalPanelIcon") as TextureRect
	boat_label = hud.get_node("SurvivalPanel/Margin/Layout/BoatLabel") as Label
	interaction_label = hud.get_node("SurvivalPanel/Margin/Layout/InteractionLabel") as Label
	status_label = hud.get_node("SurvivalPanel/Margin/Layout/StatusLabel") as Label
	toolbelt_label = hud.get_node("ToolPanel/Margin/Layout/ToolLabel") as Label
	inventory_label = hud.get_node("InventoryPanel/Margin/Layout/InventoryLabel") as Label
	crosshair_label = hud.get_node("CrosshairLabel") as Label
	event_callout_label = hud.get_node("EventCalloutLabel") as Label

	hud_icons.configure_icon_rect(objective_icon, Vector2(22.0, 22.0))
	hud_icons.configure_icon_rect(extraction_panel_icon)
	hud_icons.configure_icon_rect(crew_panel_icon)
	hud_icons.configure_icon_rect(survival_panel_icon)

	_apply_hud_panel_style(objective_panel, HUD_BORDER_ORANGE, HUD_PANEL_BG)
	_apply_hud_panel_style(extraction_panel, HUD_BORDER_ORANGE, HUD_PANEL_BG_SOFT)
	_apply_hud_panel_style(crew_panel, HUD_BORDER_BLUE, HUD_PANEL_BG_SOFT)
	_apply_hud_panel_style(survival_panel, HUD_BORDER_GREEN, HUD_PANEL_BG)
	_apply_hud_panel_style(tool_panel, HUD_BORDER_ORANGE, HUD_PANEL_BG_SOFT)
	_apply_hud_panel_style(inventory_panel, HUD_BORDER_BLUE, HUD_PANEL_BG_SOFT)

	var objective_heading := hud.get_node("ObjectivePanel/Margin/Layout/HeadingRow/ObjectiveHeading") as Label
	var extraction_heading := hud.get_node("ExtractionPanel/Margin/Layout/Header/ExtractionHeading") as Label
	var crew_heading := hud.get_node("CrewPanel/Margin/Layout/Header/CrewHeading") as Label
	footer_label = hud.get_node("CrewPanel/Margin/Layout/FooterLabel") as Label
	var survival_heading := hud.get_node("SurvivalPanel/Margin/Layout/Header/SurvivalHeading") as Label
	objective_heading.modulate = HUD_TEXT_WARNING
	objective_label.modulate = HUD_TEXT_PRIMARY
	extraction_heading.modulate = HUD_TEXT_WARNING
	resource_label.modulate = HUD_TEXT_PRIMARY
	run_label.modulate = HUD_TEXT_MUTED
	crew_heading.modulate = HUD_TEXT_MUTED
	station_label.modulate = HUD_TEXT_PRIMARY
	roster_label.modulate = HUD_TEXT_MUTED
	onboarding_label.modulate = HUD_TEXT_PRIMARY
	footer_label.modulate = HUD_TEXT_MUTED
	survival_heading.modulate = HUD_TEXT_SUCCESS
	boat_label.modulate = HUD_TEXT_PRIMARY
	interaction_label.modulate = HUD_TEXT_MUTED
	status_label.modulate = HUD_TEXT_MUTED
	toolbelt_label.modulate = HUD_TEXT_PRIMARY
	inventory_label.modulate = HUD_TEXT_PRIMARY

func _apply_hud_panel_style(panel: PanelContainer, border_color: Color, background_color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 4
	panel.add_theme_stylebox_override("panel", style)

func _build_result_overlay() -> void:
	result_layer = get_node("ResultOverlay") as CanvasLayer
	result_panel = result_layer.get_node("Center/ResultPanel") as PanelContainer
	result_panel_icon = result_layer.get_node("Center/ResultPanel/Inner/Layout/HeadingRow/ResultPanelIcon") as TextureRect
	result_title_label = result_layer.get_node("Center/ResultPanel/Inner/Layout/HeadingRow/ResultTitleLabel") as Label
	result_body_label = result_layer.get_node("Center/ResultPanel/Inner/Layout/ResultBodyLabel") as Label
	result_continue_button = result_layer.get_node("Center/ResultPanel/Inner/Layout/ResultContinueButton") as Button
	hud_icons.configure_icon_rect(result_panel_icon, Vector2(30.0, 30.0))
	if not result_continue_button.pressed.is_connected(_continue_to_dock):
		result_continue_button.pressed.connect(_continue_to_dock)
	result_layer.visible = false

func _get_run_toolbelt_entries() -> Array:
	return NetworkRuntime.get_toolbelt_entries(NetworkRuntime.SESSION_PHASE_RUN)

func _get_selected_run_tool_id() -> String:
	var entries := _get_run_toolbelt_entries()
	if entries.is_empty():
		return "helm"
	selected_run_tool_index = wrapi(selected_run_tool_index, 0, entries.size())
	return str(Dictionary(entries[selected_run_tool_index]).get("id", "helm"))

func _select_run_tool(slot_index: int) -> void:
	var entries := _get_run_toolbelt_entries()
	if slot_index < 0 or slot_index >= entries.size():
		return
	selected_run_tool_index = slot_index
	_sync_selected_station_with_tool()
	_refresh_hud()

func _toggle_inventory_panel() -> void:
	inventory_panel_visible = not inventory_panel_visible
	if inventory_panel != null:
		inventory_panel.visible = inventory_panel_visible
	_refresh_hud()

func _sync_selected_station_with_tool() -> void:
	var active_tool_id := _get_selected_run_tool_id()
	if active_tool_id == "helm":
		selected_station_index = maxi(0, NetworkRuntime.get_claimable_station_ids().find("helm"))
	elif active_tool_id == "grapple":
		selected_station_index = maxi(0, NetworkRuntime.get_claimable_station_ids().find("grapple"))

func _build_run_toolbelt_text() -> String:
	var entries := _get_run_toolbelt_entries()
	if not entries.is_empty():
		selected_run_tool_index = wrapi(selected_run_tool_index, 0, entries.size())
	var tokens := PackedStringArray()
	for entry_index in range(entries.size()):
		var entry: Dictionary = entries[entry_index]
		var token := "%d %s" % [entry_index + 1, str(entry.get("label", "Tool"))]
		if entry_index == selected_run_tool_index:
			token = "[%s]" % token
		tokens.append(token)
	var selected_entry: Dictionary = entries[selected_run_tool_index] if not entries.is_empty() else {}
	return "%s\n%s" % [
		"  ".join(tokens),
		str(selected_entry.get("hint", "Use the selected deck tool.")),
	]

func _build_run_inventory_text() -> String:
	var snapshot := NetworkRuntime.get_run_inventory_snapshot(_get_selected_run_tool_id())
	var tool_lines := PackedStringArray()
	for entry_variant in Array(snapshot.get("toolbelt_manifest", [])):
		var entry: Dictionary = entry_variant
		var prefix := "* " if bool(entry.get("equipped", false)) else "- "
		tool_lines.append("%s%s" % [prefix, str(entry.get("label", "Tool"))])
	if tool_lines.is_empty():
		tool_lines.append("- No tools equipped.")
	var manifest_lines := PackedStringArray()
	for entry_variant in Array(snapshot.get("cargo_manifest", [])):
		var entry: Dictionary = entry_variant
		manifest_lines.append("- %s x%d" % [
			str(entry.get("label", "Cargo")),
			int(entry.get("quantity", 0)),
		])
	if manifest_lines.is_empty():
		manifest_lines.append("- No cargo aboard.")
	var bonus_lines := PackedStringArray()
	for entry_variant in Array(snapshot.get("bonus_manifest", [])):
		var entry: Dictionary = entry_variant
		bonus_lines.append("- %s: %s" % [
			str(entry.get("label", "Bonus")),
			str(entry.get("detail", "")),
		])
	if bonus_lines.is_empty():
		bonus_lines.append("- No support bonuses secured yet.")
	return "On You\n%s\nCargo Hold %d/%d | Patch Kits %d/%d\nAboard\n%s\nSupport\n%s\nCargo Lost To Sea %d | Bonus Bank %dg / %ds" % [
		"\n".join(tool_lines),
		int(snapshot.get("cargo_count", 0)),
		int(snapshot.get("cargo_capacity", 0)),
		int(snapshot.get("patch_kits", 0)),
		int(snapshot.get("patch_kits_max", 0)),
		"\n".join(manifest_lines),
		"\n".join(bonus_lines),
		int(snapshot.get("cargo_lost_to_sea", 0)),
		int(snapshot.get("bonus_gold_bank", 0)),
		int(snapshot.get("bonus_salvage_bank", 0)),
	]

func _get_run_tool_label(tool_id: String) -> String:
	for tool_variant in _get_run_toolbelt_entries():
		var tool: Dictionary = tool_variant
		if str(tool.get("id", "")) == tool_id:
			return str(tool.get("label", tool_id.capitalize()))
	return tool_id.capitalize()

func _refresh_world() -> void:
	_refresh_runtime_block_visuals()
	_refresh_sinking_chunk_visuals()
	_refresh_station_visuals()
	_refresh_crew_visuals()
	_refresh_hazard_visuals()
	_refresh_loot_visuals()
	_refresh_wreck_visual()
	_refresh_rescue_visual()
	_refresh_cache_visual()
	_refresh_squall_visuals()
	_refresh_extraction_visual()
	_refresh_result_overlay()
	_update_boat_material()

func _refresh_hud() -> void:
	var local_peer_id := _get_local_peer_id()
	var local_avatar_state: Dictionary = NetworkRuntime.get_run_avatar_state().get(local_peer_id, {})
	var local_overboard := str(local_avatar_state.get("mode", NetworkRuntime.RUN_AVATAR_MODE_DECK)) == NetworkRuntime.RUN_AVATAR_MODE_OVERBOARD
	var local_station_id := NetworkRuntime.get_peer_station_id(local_peer_id)
	var selected_station_id := _get_selected_station_id()
	var active_tool_id := _get_selected_run_tool_id()
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var extraction_position: Vector3 = NetworkRuntime.run_state.get("extraction_position", Vector3.ZERO)
	var extraction_progress: float = float(NetworkRuntime.run_state.get("extraction_progress", 0.0))
	var extraction_duration: float = float(NetworkRuntime.run_state.get("extraction_duration", 1.0))
	var hull_integrity: float = float(NetworkRuntime.boat_state.get("hull_integrity", 100.0))
	var max_hull_integrity: float = float(NetworkRuntime.boat_state.get("max_hull_integrity", 100.0))
	var breach_stacks := int(NetworkRuntime.boat_state.get("breach_stacks", 0))
	var wreck_position: Vector3 = NetworkRuntime.run_state.get("wreck_position", Vector3.ZERO)
	var rescue_position: Vector3 = NetworkRuntime.run_state.get("rescue_position", Vector3.ZERO)
	var cache_position: Vector3 = NetworkRuntime.run_state.get("cache_position", Vector3.ZERO)
	var extraction_distance := boat_position.distance_to(extraction_position)
	var wreck_distance := boat_position.distance_to(wreck_position)
	var rescue_distance := boat_position.distance_to(rescue_position)
	var cache_distance := boat_position.distance_to(cache_position)
	var repair_supplies := int(NetworkRuntime.run_state.get("repair_supplies", 0))
	var repair_supplies_max := int(NetworkRuntime.run_state.get("repair_supplies_max", 0))
	var active_block_count := int(NetworkRuntime.boat_state.get("active_block_count", 0))
	var destroyed_block_count := int(NetworkRuntime.run_state.get("destroyed_block_count", 0))
	var detached_chunk_count := int(NetworkRuntime.run_state.get("detached_chunk_count", 0))
	var cargo_lost_to_sea := int(NetworkRuntime.run_state.get("cargo_lost_to_sea", 0))
	var overboard_count := int(NetworkRuntime.run_state.get("overboard_count", 0))
	var recoveries_completed := int(NetworkRuntime.run_state.get("recoveries_completed", 0))
	var rescue_progress: float = float(NetworkRuntime.run_state.get("rescue_progress", 0.0))
	var rescue_duration: float = float(NetworkRuntime.run_state.get("rescue_duration", 1.0))
	var rescue_available := bool(NetworkRuntime.run_state.get("rescue_available", false))
	var rescue_completed := bool(NetworkRuntime.run_state.get("rescue_completed", false))
	var squall_bands := Array(NetworkRuntime.run_state.get("squall_bands", []))
	var phase := str(NetworkRuntime.run_state.get("phase", "running"))
	var current_cargo := int(NetworkRuntime.run_state.get("cargo_count", 0))
	var cargo_capacity := int(NetworkRuntime.run_state.get("cargo_capacity", int(NetworkRuntime.boat_state.get("cargo_capacity", 1))))
	var loot_remaining := int(NetworkRuntime.run_state.get("loot_remaining", 0))
	var layout_label := str(NetworkRuntime.run_state.get("layout_label", "Wreck Push"))
	var brace_timer := float(NetworkRuntime.boat_state.get("brace_timer", 0.0))
	var brace_cooldown := float(NetworkRuntime.boat_state.get("brace_cooldown", 0.0))
	var brace_state := "Ready"
	if brace_timer > 0.0:
		brace_state = "Holding %.1fs" % brace_timer
	elif brace_cooldown > 0.0:
		brace_state = "Recharging %.1fs" % brace_cooldown

	hud_icons.set_icon(objective_icon, _get_run_objective_icon_id(phase, local_station_id, selected_station_id, current_cargo, cargo_capacity))
	hud_icons.set_icon(extraction_panel_icon, "extraction")
	hud_icons.set_icon(crew_panel_icon, "helm" if local_station_id == "helm" else "brace" if brace_timer > 0.0 else "helm")
	var objective_text := _build_objective_text().trim_prefix("Objective: ").strip_edges()
	objective_label.text = objective_text
	if phase == "success":
		objective_label.modulate = HUD_TEXT_SUCCESS
	elif phase == "failed":
		objective_label.modulate = HUD_TEXT_DANGER
	else:
		objective_label.modulate = HUD_TEXT_PRIMARY

	resource_label.text = "Cargo %d/%d | Extract %.1f/%.1fs | Dist %.1fm\nPatch Kits %d/%d | Bonus %dg / %ds" % [
		current_cargo,
		cargo_capacity,
		extraction_progress,
		extraction_duration,
		extraction_distance,
		repair_supplies,
		repair_supplies_max,
		int(NetworkRuntime.run_state.get("bonus_gold_bank", 0)),
		int(NetworkRuntime.run_state.get("bonus_salvage_bank", 0)),
	]
	if local_overboard:
		var recovery_target := _get_local_recovery_target()
		var target_label := str(recovery_target.get("label", "Recovery Point"))
		resource_label.text = "Overboard | Swim Radius %.1fm | Recoveries %d\nTarget %s | Press F once you grab on" % [
			NetworkRuntime.RUN_OVERBOARD_SWIM_RADIUS,
			recoveries_completed,
			target_label,
		]

	var pressure_lines := PackedStringArray()
	pressure_lines.append("%s | Loot %d left | Wreck %.1fm" % [layout_label, loot_remaining, wreck_distance])
	if rescue_available:
		pressure_lines.append("Rescue %.1fm | Window %.1f/%.1fs" % [rescue_distance, rescue_progress, rescue_duration])
	elif rescue_completed:
		pressure_lines.append("Rescue secured")
	if bool(NetworkRuntime.run_state.get("cache_available", false)):
		pressure_lines.append("Cache %.1fm | Quick bonus lane" % cache_distance)
	if not squall_bands.is_empty():
		pressure_lines.append("Squalls %d | %s" % [squall_bands.size(), "Inside storm band" if _boat_inside_any_squall() else "Route pressure"])
	if cargo_lost_to_sea > 0:
		pressure_lines.append("Cargo washed overboard: %d" % cargo_lost_to_sea)
	if overboard_count > 0:
		pressure_lines.append("Crew overboard: %d" % overboard_count)
	run_label.text = "\n".join(pressure_lines)

	var station_lines := PackedStringArray()
	for station_id in _get_claimable_station_ids():
		var occupant_name := NetworkRuntime.get_station_occupant_name(station_id)
		var marker := ">" if station_id == selected_station_id else " "
		station_lines.append("%s %s %s" % [
			marker,
			NetworkRuntime.get_station_label(station_id),
			occupant_name,
		])
	station_lines.append("  Brace Anywhere")
	station_lines.append("  Patch Nearby Hull")
	if local_overboard:
		station_lines.append("  Swim To Ladder")
	station_label.text = "Deck Jobs | Tool %s\n%s" % [_get_run_tool_label(active_tool_id), ("\n".join(station_lines) if not station_lines.is_empty() else "No stations available.")]

	var local_hint := _build_onboarding_text(selected_station_id, local_station_id).trim_prefix("Onboarding: ").strip_edges()
	onboarding_label.text = "Local Tip\n%s" % local_hint

	boat_label.text = "Hull %.0f/%.0f | Speed %.1f/%.1f\nBreaches %d | Patch Kits %d/%d | Blocks %d active / %d lost\nBrace %s | Cargo %d/%d | Collisions %d" % [
		hull_integrity,
		max_hull_integrity,
		float(NetworkRuntime.boat_state.get("speed", 0.0)),
		float(NetworkRuntime.boat_state.get("top_speed_limit", NetworkRuntime.BOAT_TOP_SPEED)),
		breach_stacks,
		repair_supplies,
		repair_supplies_max,
		active_block_count,
		destroyed_block_count,
		brace_state,
		current_cargo,
		cargo_capacity,
		int(NetworkRuntime.boat_state.get("collision_count", 0)),
	]
	if overboard_count > 0:
		boat_label.text += "\nOverboard %d | Recoveries %d" % [overboard_count, recoveries_completed]
	var hull_ratio := hull_integrity / maxf(1.0, max_hull_integrity)
	hud_icons.set_icon(survival_panel_icon, "brace" if hull_ratio <= 0.6 or detached_chunk_count > 0 or breach_stacks > 0 else "repair-kit")
	if hull_ratio <= 0.3 or detached_chunk_count > 0:
		boat_label.modulate = HUD_TEXT_DANGER
	elif hull_ratio <= 0.6 or breach_stacks > 0:
		boat_label.modulate = HUD_TEXT_WARNING
	else:
		boat_label.modulate = HUD_TEXT_PRIMARY

	var interaction_lines := PackedStringArray()
	var selected_label := NetworkRuntime.get_station_label(selected_station_id) if not selected_station_id.is_empty() else "No station"
	var local_label := NetworkRuntime.get_station_label(local_station_id) if not local_station_id.is_empty() else "Free Roam"
	interaction_lines.append("Selected %s | You %s" % [selected_label, local_label])
	if local_overboard:
		var recovery_target := _get_local_recovery_target()
		if recovery_target.is_empty():
			interaction_lines.append("Swim toward a ladder or stern line before the boat drifts farther away.")
		elif bool(recovery_target.get("ready", false)):
			interaction_lines.append("Grabbed %s. Press F to climb back aboard." % str(recovery_target.get("label", "Recovery Point")))
		else:
			interaction_lines.append("Swim to the %s and press F once you reach it." % str(recovery_target.get("label", "Recovery Point")))
	elif not selected_station_id.is_empty() and local_station_id.is_empty():
		if _is_local_near_station(selected_station_id):
			interaction_lines.append("Press F to take %s from this deck position." % selected_label)
		else:
			interaction_lines.append("Move closer to %s before claiming it." % selected_label)
	if local_station_id == "helm":
		interaction_lines.append("Stay near the helm to keep steering. Drift away and you lose control.")
	elif local_station_id == "grapple":
		interaction_lines.append("Stay on the crane and recover loot only when the helm has settled the boat.")
	elif not _find_local_repair_target().is_empty():
		interaction_lines.append("You are close enough to patch this section. Spend kits only when the trade is worth it.")
	else:
		interaction_lines.append("Move to the helm or grapple crane, brace anywhere, and patch damage up close.")
	interaction_label.text = "\n".join(interaction_lines)

	var crew_lines := PackedStringArray()
	for peer_id in NetworkRuntime.get_player_peer_ids():
		var peer_data: Dictionary = NetworkRuntime.peer_snapshot[peer_id]
		var crew_station := NetworkRuntime.get_peer_station_id(int(peer_id))
		var peer_reaction := _get_reaction_visual(int(peer_id))
		var crew_avatar_state: Dictionary = NetworkRuntime.get_run_avatar_state().get(int(peer_id), {})
		var reaction_text := ""
		if not peer_reaction.is_empty():
			reaction_text = " | %s" % str(peer_reaction.get("type", "reacting")).capitalize()
		if str(crew_avatar_state.get("mode", NetworkRuntime.RUN_AVATAR_MODE_DECK)) == NetworkRuntime.RUN_AVATAR_MODE_OVERBOARD:
			reaction_text += " | Overboard"
		crew_lines.append("%s - %s%s" % [
			str(peer_data.get("name", "Unknown")),
			NetworkRuntime.get_station_label(crew_station) if not crew_station.is_empty() else "Free",
			reaction_text,
		])
	roster_label.text = "Crew Snapshot\n%s" % ("\n".join(crew_lines) if not crew_lines.is_empty() else "No crew connected yet.")

	status_label.text = "Seed %d | %s | %s" % [
		NetworkRuntime.run_seed,
		phase.capitalize(),
		NetworkRuntime.status_message,
	]
	status_label.modulate = HUD_TEXT_MUTED
	if footer_label != null:
		footer_label.text = "Mouse aim | 1-5 tools | I inventory | Q/E stations | F use/claim | Space brace | G grapple | R patch"
	toolbelt_label.text = _build_run_toolbelt_text()
	inventory_label.text = _build_run_inventory_text()
	if inventory_panel != null:
		inventory_panel.visible = inventory_panel_visible

func _build_interaction_text(selected_station_id: String, local_station_id: String) -> String:
	if selected_station_id.is_empty():
		return "No station selected."

	var selected_label := NetworkRuntime.get_station_label(selected_station_id)
	var occupant_name := NetworkRuntime.get_station_occupant_name(selected_station_id)
	var occupant_peer_id := int(NetworkRuntime.station_state.get(selected_station_id, {}).get("occupant_peer_id", 0))
	var local_peer_id := _get_local_peer_id()
	var lines := PackedStringArray()
	lines.append("Selected: %s" % selected_label)

	if occupant_peer_id == 0:
		lines.append("Press F to claim this station.")
	elif occupant_peer_id == local_peer_id:
		lines.append("You occupy this station. Press F to release it.")
	else:
		lines.append("%s is using this station." % occupant_name)

	if local_station_id == "helm":
		lines.append("Hold the boat steady over wrecks and line up safe extraction approaches.")
	elif local_station_id == "grapple":
		lines.append("Press G to recover nearby wreck salvage, rescue cargo, or bonus caches once the helm has slowed the boat.")
	else:
		lines.append("Brace anywhere with Space, or patch nearby hull damage with R.")

	lines.append("Unbraced wreck grapples add hull breaches that slow the boat until repaired.")
	lines.append("Repairs now spend shared patch kits, so decide whether to patch now or save them for extraction.")
	if bool(NetworkRuntime.run_state.get("rescue_available", false)):
		lines.append("Optional distress rescue: hold slow inside the rescue ring and let the grappler secure the package.")
	if _boat_inside_any_squall():
		lines.append("Squall pressure: gusts drag the boat and can slam the hull if the crew fails to brace.")
	var local_reaction := _get_reaction_visual(_get_local_peer_id())
	if not local_reaction.is_empty():
		lines.append("Reaction: %s (recovering in %.2fs)." % [
			str(local_reaction.get("type", "impact")).capitalize(),
			float(local_reaction.get("active_time", 0.0)) + float(local_reaction.get("recovery_time", 0.0)),
		])

	if str(NetworkRuntime.run_state.get("phase", "running")) != "running":
		lines.append("Run complete. The result panel shows the final outcome.")

	return "\n".join(lines)

func _get_blueprint_block_by_id(block_id: int) -> Dictionary:
	for block_variant in Array(NetworkRuntime.boat_blueprint.get("blocks", [])):
		var block: Dictionary = block_variant
		if int(block.get("id", 0)) == block_id:
			return block
	return {}

func _normalize_runtime_block_cell(cell_value: Variant) -> Array:
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

func _cell_to_runtime_local_position(cell_value: Variant) -> Vector3:
	var cell := _normalize_runtime_block_cell(cell_value)
	return Vector3(float(cell[0]), float(cell[1]), float(cell[2])) * NetworkRuntime.RUNTIME_BLOCK_SPACING

func _build_runtime_block_render_data(block_state: Dictionary) -> Dictionary:
	var blueprint_block := _get_blueprint_block_by_id(int(block_state.get("id", 0)))
	if blueprint_block.is_empty():
		return {}

	var block_type := str(blueprint_block.get("type", "structure"))
	var block_def := NetworkRuntime.get_builder_block_definition(block_type)
	var max_hp := float(block_def.get("max_hp", 1.0))
	return {
		"id": int(block_state.get("id", 0)),
		"type": block_type,
		"rotation_steps": int(blueprint_block.get("rotation_steps", 0)),
		"local_position": _cell_to_runtime_local_position(blueprint_block.get("cell", [0, 0, 0])),
		"max_hp": max_hp,
		"current_hp": float(block_state.get("current_hp", max_hp)),
		"destroyed": bool(block_state.get("destroyed", false)),
		"detached": bool(block_state.get("detached", false)),
	}

func _build_sinking_chunk_center(block_ids: Array) -> Vector3:
	var center := Vector3.ZERO
	var counted_blocks := 0
	for block_id_variant in block_ids:
		var blueprint_block := _get_blueprint_block_by_id(int(block_id_variant))
		if blueprint_block.is_empty():
			continue
		center += _cell_to_runtime_local_position(blueprint_block.get("cell", [0, 0, 0]))
		counted_blocks += 1
	if counted_blocks <= 0:
		return Vector3.ZERO
	return center / float(counted_blocks)

func _apply_runtime_block_visual_style(block_node: Node3D, block_def: Dictionary, current_hp: float, max_hp: float, detached_visual: bool) -> void:
	var health_ratio := clampf(current_hp / maxf(1.0, max_hp), 0.0, 1.0)
	var damaged_color := Color(0.36, 0.16, 0.14)
	var base_color: Color = block_def.get("color", Color(0.7, 0.7, 0.7))
	var block_color := damaged_color.lerp(base_color, health_ratio)
	if detached_visual:
		block_color = block_color.darkened(0.18)

	var mesh_instance := block_node.get_node_or_null("Body") as MeshInstance3D
	if mesh_instance != null:
		var body_material := mesh_instance.material_override as StandardMaterial3D
		if body_material == null:
			body_material = StandardMaterial3D.new()
			mesh_instance.material_override = body_material
		body_material.albedo_color = block_color
		body_material.roughness = 0.45

	var facing_marker := block_node.get_node_or_null("Marker") as MeshInstance3D
	if facing_marker != null:
		var marker_material := facing_marker.material_override as StandardMaterial3D
		if marker_material == null:
			marker_material = StandardMaterial3D.new()
			facing_marker.material_override = marker_material
		marker_material.albedo_color = block_color.lightened(0.22)

func _refresh_runtime_block_visuals() -> void:
	for child in main_block_container.get_children():
		child.queue_free()
	main_block_visuals.clear()

	var runtime_blocks: Array = Array(NetworkRuntime.boat_state.get("runtime_blocks", []))
	_update_placeholder_boat_visibility(runtime_blocks.is_empty())
	for block_variant in runtime_blocks:
		var block_state: Dictionary = block_variant
		var block := _build_runtime_block_render_data(block_state)
		if block.is_empty() or bool(block.get("destroyed", false)) or bool(block.get("detached", false)):
			continue
		var block_node := _make_runtime_block_visual(block, false)
		main_block_container.add_child(block_node)
		main_block_visuals[int(block.get("id", 0))] = block_node

func _refresh_sinking_chunk_visuals() -> void:
	for child in sinking_chunk_container.get_children():
		child.queue_free()
	sinking_chunk_visuals.clear()

	var sinking_chunks: Array = Array(NetworkRuntime.boat_state.get("sinking_chunks", []))
	for chunk_variant in sinking_chunks:
		var chunk: Dictionary = chunk_variant
		var chunk_root := Node3D.new()
		var chunk_world_position: Vector3 = chunk.get("world_position", Vector3.ZERO)
		chunk_root.position = chunk_world_position
		chunk_root.rotation.y = float(chunk.get("rotation_y", 0.0))
		sinking_chunk_container.add_child(chunk_root)
		sinking_chunk_visuals[int(chunk.get("chunk_id", 0))] = chunk_root

		var block_ids := Array(chunk.get("block_ids", []))
		var chunk_center := _build_sinking_chunk_center(block_ids)
		for block_id_variant in block_ids:
			var block := _build_runtime_block_render_data({
				"id": int(block_id_variant),
				"detached": true,
			})
			if block.is_empty():
				continue
			var block_local_position: Vector3 = block.get("local_position", Vector3.ZERO)
			block["local_position"] = block_local_position - chunk_center
			var block_node := _make_runtime_block_visual(block, true)
			chunk_root.add_child(block_node)

func _make_runtime_block_visual(block: Dictionary, detached_visual: bool) -> Node3D:
	var block_type := str(block.get("type", "structure"))
	var block_def := NetworkRuntime.get_builder_block_definition(block_type)
	var block_node := Node3D.new()
	var block_local_position: Vector3 = block.get("local_position", Vector3.ZERO)
	block_node.position = block_local_position
	block_node.rotation_degrees.y = float(int(block.get("rotation_steps", 0)) * 90)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Body"
	var mesh := BoxMesh.new()
	var block_size: Vector3 = block_def.get("size", Vector3.ONE)
	mesh.size = block_size
	mesh_instance.mesh = mesh
	block_node.add_child(mesh_instance)

	var facing_marker := MeshInstance3D.new()
	facing_marker.name = "Marker"
	var marker_mesh := BoxMesh.new()
	marker_mesh.size = Vector3(0.22, 0.14, 0.26)
	facing_marker.mesh = marker_mesh
	facing_marker.position = Vector3(0.0, 0.0, -0.36)
	block_node.add_child(facing_marker)
	_apply_runtime_block_visual_style(
		block_node,
		block_def,
		float(block.get("current_hp", float(block.get("max_hp", 1.0)))),
		float(block.get("max_hp", 1.0)),
		detached_visual
	)

	return block_node

func _update_runtime_block_visuals() -> void:
	var runtime_blocks: Array = Array(NetworkRuntime.boat_state.get("runtime_blocks", []))
	_update_placeholder_boat_visibility(runtime_blocks.is_empty())
	for block_variant in runtime_blocks:
		var block_state: Dictionary = block_variant
		var block := _build_runtime_block_render_data(block_state)
		if block.is_empty():
			continue
		var block_id := int(block.get("id", 0))
		var block_node := main_block_visuals.get(block_id) as Node3D
		if bool(block.get("destroyed", false)) or bool(block.get("detached", false)):
			if block_node != null:
				block_node.visible = false
			continue
		if block_node == null:
			_refresh_runtime_block_visuals()
			return
		var block_local_position: Vector3 = block.get("local_position", Vector3.ZERO)
		block_node.position = block_local_position
		block_node.rotation_degrees.y = float(int(block.get("rotation_steps", 0)) * 90)
		block_node.visible = true
		_apply_runtime_block_visual_style(
			block_node,
			NetworkRuntime.get_builder_block_definition(str(block.get("type", "structure"))),
			float(block.get("current_hp", float(block.get("max_hp", 1.0)))),
			float(block.get("max_hp", 1.0)),
			false
		)

func _update_sinking_chunk_visuals(delta: float) -> void:
	var sinking_chunks: Array = Array(NetworkRuntime.boat_state.get("sinking_chunks", [])).duplicate(true)
	var active_chunk_ids := {}
	var updated_chunks: Array = []
	for chunk_variant in sinking_chunks:
		var chunk: Dictionary = chunk_variant
		var sink_elapsed := float(chunk.get("sink_elapsed", 0.0)) + delta
		if sink_elapsed >= NetworkRuntime.RUNTIME_SINK_LIFETIME:
			continue
		chunk["sink_elapsed"] = sink_elapsed
		var chunk_world_position: Vector3 = chunk.get("world_position", Vector3.ZERO)
		var drift_velocity: Vector3 = chunk.get("drift_velocity", Vector3.ZERO)
		chunk_world_position += drift_velocity * delta
		chunk["world_position"] = chunk_world_position
		var chunk_id := int(chunk.get("chunk_id", 0))
		active_chunk_ids[chunk_id] = true
		updated_chunks.append(chunk)
		var chunk_root := sinking_chunk_visuals.get(chunk_id) as Node3D
		if chunk_root == null:
			NetworkRuntime.boat_state["sinking_chunks"] = updated_chunks
			_refresh_sinking_chunk_visuals()
			return
		chunk_root.position = chunk_world_position
		chunk_root.rotation.y = float(chunk.get("rotation_y", 0.0))
		if chunk_root.get_child_count() != Array(chunk.get("block_ids", [])).size():
			NetworkRuntime.boat_state["sinking_chunks"] = updated_chunks
			_refresh_sinking_chunk_visuals()
			return

	for chunk_id_variant in sinking_chunk_visuals.keys():
		var chunk_id := int(chunk_id_variant)
		if active_chunk_ids.has(chunk_id):
			continue
		var stale_root := sinking_chunk_visuals.get(chunk_id) as Node3D
		if stale_root != null:
			stale_root.queue_free()
		sinking_chunk_visuals.erase(chunk_id)
	NetworkRuntime.boat_state["sinking_chunks"] = updated_chunks

func _update_placeholder_boat_visibility(placeholder_visible: bool) -> void:
	if hull_mesh_instance != null:
		hull_mesh_instance.visible = placeholder_visible
	if deck_mesh_instance != null:
		deck_mesh_instance.visible = placeholder_visible
	if mast_mesh_instance != null:
		mast_mesh_instance.visible = placeholder_visible

func _refresh_station_visuals() -> void:
	_ensure_selected_station_valid()
	var local_peer_id := _get_local_peer_id()
	var selected_station_id := _get_selected_station_id()

	for station_id in NetworkRuntime.get_station_ids():
		var station_visual: Dictionary = station_visuals.get(station_id, {})
		var base_mesh := station_visual.get("base") as MeshInstance3D
		var beacon_mesh := station_visual.get("beacon") as MeshInstance3D
		var label := station_visual.get("label") as Label3D
		if base_mesh == null or beacon_mesh == null or label == null:
			continue

		var station_data: Dictionary = NetworkRuntime.station_state.get(station_id, {})
		var occupant_peer_id := int(station_data.get("occupant_peer_id", 0))
		var claimable := _get_claimable_station_ids().has(station_id)
		var color := STATION_BASE_COLOR if claimable else Color(0.36, 0.56, 0.62)
		if claimable:
			if occupant_peer_id == local_peer_id and occupant_peer_id != 0:
				color = STATION_LOCAL_COLOR
			elif occupant_peer_id != 0:
				color = STATION_OCCUPIED_COLOR
			if station_id == selected_station_id:
				color = color.lerp(STATION_SELECTED_COLOR, 0.45)
		else:
			color = color.lerp(STATION_SELECTED_COLOR, 0.18)

		var base_material := StandardMaterial3D.new()
		base_material.albedo_color = color.darkened(0.08)
		base_mesh.material_override = base_material

		var beacon_material := StandardMaterial3D.new()
		beacon_material.albedo_color = color
		beacon_mesh.material_override = beacon_material

		var occupant_name := NetworkRuntime.get_station_occupant_name(station_id)
		if claimable:
			label.text = NetworkRuntime.get_station_label(station_id)
			if occupant_peer_id != 0:
				label.text += "\n%s" % occupant_name
		elif station_id == "brace":
			label.text = "Brace Anywhere"
		elif station_id == "repair":
			label.text = "Patch Nearby Hull"
		else:
			label.text = NetworkRuntime.get_station_label(station_id)
		label.modulate = color.lightened(0.22)

func _refresh_crew_visuals() -> void:
	if crew_container == null or not is_instance_valid(crew_container) or not crew_container.is_inside_tree():
		return
	if boat_root == null or not is_instance_valid(boat_root) or not boat_root.is_inside_tree():
		return
	for child in crew_container.get_children():
		child.queue_free()
	crew_visuals.clear()

	var idle_slot_index := 0
	for peer_id in NetworkRuntime.get_player_peer_ids():
		var peer_data: Dictionary = NetworkRuntime.peer_snapshot[peer_id]
		var crew_member := Node3D.new()
		var station_id := NetworkRuntime.get_peer_station_id(int(peer_id))
		var avatar_state: Dictionary = NetworkRuntime.get_run_avatar_state().get(int(peer_id), {})
		var overboard := str(avatar_state.get("mode", NetworkRuntime.RUN_AVATAR_MODE_DECK)) == NetworkRuntime.RUN_AVATAR_MODE_OVERBOARD
		if overboard:
			crew_member.top_level = true
			crew_container.add_child(crew_member)
			crew_member.global_position = avatar_state.get("world_position", boat_root.global_position)
			crew_member.rotation.y = float(avatar_state.get("facing_y", PI))
		elif not station_id.is_empty() and _station_anchors_avatar(station_id):
			crew_member.position = NetworkRuntime.get_station_position(station_id) + Vector3(0.0, 0.18, 0.0)
			crew_member.rotation.y = 0.0
		elif not avatar_state.is_empty():
			crew_member.position = avatar_state.get("deck_position", IDLE_CREW_SLOTS[idle_slot_index % IDLE_CREW_SLOTS.size()])
			crew_member.rotation.y = float(avatar_state.get("facing_y", PI))
		else:
			crew_member.position = IDLE_CREW_SLOTS[idle_slot_index % IDLE_CREW_SLOTS.size()]
			crew_member.rotation.y = PI
			idle_slot_index += 1
			crew_container.add_child(crew_member)
		if not overboard and crew_member.get_parent() == null:
			crew_container.add_child(crew_member)

		var body := MeshInstance3D.new()
		var body_mesh := CapsuleMesh.new()
		body_mesh.height = 1.2
		body_mesh.radius = 0.24
		body.mesh = body_mesh
		var material := StandardMaterial3D.new()
		if int(peer_id) == _get_local_peer_id():
			material.albedo_color = Color(0.30, 0.82, 0.52)
		elif overboard:
			material.albedo_color = Color(0.36, 0.74, 0.96)
		elif station_id == "helm":
			material.albedo_color = Color(0.94, 0.76, 0.18)
		else:
			material.albedo_color = Color(0.70, 0.84, 0.93)
		body.material_override = material
		crew_member.add_child(body)

		var nameplate := Label3D.new()
		var role_label := "Overboard" if overboard else (NetworkRuntime.get_station_label(station_id) if not station_id.is_empty() else "Crew")
		nameplate.text = "%s - %s" % [str(peer_data.get("name", "Crew")), role_label]
		nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		nameplate.font_size = 18
		nameplate.position = Vector3(0.0, 0.96, 0.0)
		crew_member.add_child(nameplate)
		crew_visuals[int(peer_id)] = {
			"root": crew_member,
			"nameplate": nameplate,
			"body": body,
		}

func _refresh_hazard_visuals() -> void:
	for child in hazard_container.get_children():
		child.queue_free()
	hazard_visuals = {}

	for hazard in NetworkRuntime.hazard_state:
		var hazard_data: Dictionary = hazard
		var hazard_node := Node3D.new()
		hazard_container.add_child(hazard_node)
		hazard_visuals[int(hazard_data.get("id", 0))] = {
			"root": hazard_node,
		}

		var mesh_instance := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = float(hazard_data.get("radius", 1.25))
		sphere.height = sphere.radius * 2.0
		mesh_instance.mesh = sphere
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.92, 0.28, 0.22)
		mesh_instance.material_override = material
		hazard_node.add_child(mesh_instance)

		var label := Label3D.new()
		label.text = str(hazard_data.get("label", "Hazard"))
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 22
		label.position = Vector3(0.0, float(hazard_data.get("radius", 1.25)) + 0.7, 0.0)
		hazard_node.add_child(label)

func _refresh_loot_visuals() -> void:
	for child in loot_container.get_children():
		child.queue_free()
	loot_visuals = {}

	for loot_target in NetworkRuntime.loot_state:
		var loot_data: Dictionary = loot_target
		var loot_node := Node3D.new()
		loot_container.add_child(loot_node)
		loot_visuals[int(loot_data.get("id", 0))] = {
			"root": loot_node,
		}

		var mesh_instance := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.8, 0.55, 0.8)
		mesh_instance.mesh = box
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.95, 0.78, 0.28)
		mesh_instance.material_override = material
		loot_node.add_child(mesh_instance)

		var label := Label3D.new()
		label.text = str(loot_data.get("label", "Loot"))
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 20
		label.position = Vector3(0.0, 0.75, 0.0)
		loot_node.add_child(label)

func _refresh_wreck_visual() -> void:
	if wreck_root == null:
		return

	var wreck_position: Vector3 = NetworkRuntime.run_state.get("wreck_position", Vector3.ZERO)
	var wreck_radius: float = float(NetworkRuntime.run_state.get("wreck_radius", 4.1))
	wreck_root.position = wreck_position

	var ring_mesh_instance := wreck_root.get_node_or_null("WreckRing") as MeshInstance3D
	if ring_mesh_instance != null:
		var ring_mesh := ring_mesh_instance.mesh as CylinderMesh
		if ring_mesh != null:
			ring_mesh.top_radius = wreck_radius
			ring_mesh.bottom_radius = wreck_radius

	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var boat_speed: float = absf(float(NetworkRuntime.boat_state.get("speed", 0.0)))
	var boat_in_wreck := boat_position.distance_to(wreck_position) <= wreck_radius
	var ready_color := Color(0.23, 0.79, 0.57) if boat_in_wreck and boat_speed <= float(NetworkRuntime.run_state.get("salvage_max_speed", NetworkRuntime.SALVAGE_MAX_SPEED)) else Color(0.87, 0.56, 0.19)
	wreck_ring_material.albedo_color = ready_color
	wreck_hull_material.albedo_color = Color(0.38, 0.24, 0.18).lerp(Color(0.58, 0.32, 0.18), 0.18 if boat_in_wreck else 0.0)
	wreck_label.text = "Wreck Salvage\nLoot %d/%d | Max Speed %.1f" % [
		int(NetworkRuntime.run_state.get("loot_remaining", 0)),
		int(NetworkRuntime.run_state.get("loot_total", 0)),
		float(NetworkRuntime.run_state.get("salvage_max_speed", NetworkRuntime.SALVAGE_MAX_SPEED)),
	]
	wreck_label.modulate = ready_color.lightened(0.18)

func _refresh_rescue_visual() -> void:
	if rescue_root == null:
		return

	var rescue_position: Vector3 = NetworkRuntime.run_state.get("rescue_position", Vector3.ZERO)
	var rescue_radius: float = float(NetworkRuntime.run_state.get("rescue_radius", 3.4))
	var rescue_available := bool(NetworkRuntime.run_state.get("rescue_available", false))
	var rescue_engaged := bool(NetworkRuntime.run_state.get("rescue_engaged", false))
	var rescue_completed := bool(NetworkRuntime.run_state.get("rescue_completed", false))
	rescue_root.visible = rescue_available or rescue_completed
	rescue_root.position = rescue_position

	var ring_mesh_instance := rescue_root.get_node_or_null("RescueRing") as MeshInstance3D
	if ring_mesh_instance != null:
		var ring_mesh := ring_mesh_instance.mesh as CylinderMesh
		if ring_mesh != null:
			ring_mesh.top_radius = rescue_radius
			ring_mesh.bottom_radius = rescue_radius

	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var boat_speed: float = absf(float(NetworkRuntime.boat_state.get("speed", 0.0)))
	var in_zone := boat_position.distance_to(rescue_position) <= rescue_radius
	var ready_color := Color(0.93, 0.72, 0.28)
	if rescue_completed:
		ready_color = Color(0.29, 0.82, 0.58)
	elif rescue_engaged:
		ready_color = Color(0.95, 0.84, 0.36)
	elif in_zone and boat_speed <= float(NetworkRuntime.run_state.get("rescue_max_speed", NetworkRuntime.RESCUE_MAX_SPEED)):
		ready_color = Color(0.98, 0.86, 0.36)
	rescue_ring_material.albedo_color = ready_color
	rescue_flare_material.albedo_color = Color(0.56, 0.37, 0.18).lerp(Color(0.93, 0.56, 0.18), 0.7 if rescue_available else 0.2)
	rescue_label.text = "%s\nHold %.1f/%.1fs | Max Speed %.1f" % [
		str(NetworkRuntime.run_state.get("rescue_label", "Distress Rescue")),
		float(NetworkRuntime.run_state.get("rescue_progress", 0.0)),
		float(NetworkRuntime.run_state.get("rescue_duration", 1.0)),
		float(NetworkRuntime.run_state.get("rescue_max_speed", NetworkRuntime.RESCUE_MAX_SPEED)),
	]
	if rescue_completed:
		rescue_label.text = "%s\nSecured +%d gold | +%d salvage | +%d kit" % [
			str(NetworkRuntime.run_state.get("rescue_label", "Distress Rescue")),
			int(NetworkRuntime.run_state.get("rescue_bonus_gold", 0)),
			int(NetworkRuntime.run_state.get("rescue_bonus_salvage", 0)),
			int(NetworkRuntime.run_state.get("rescue_patch_kit_bonus", 0)),
		]
	rescue_label.modulate = ready_color.lightened(0.16)

func _refresh_squall_visuals() -> void:
	for child in squall_container.get_children():
		child.queue_free()
	squall_visuals.clear()

	for band_variant in Array(NetworkRuntime.run_state.get("squall_bands", [])):
		var band: Dictionary = band_variant
		var band_id := int(band.get("id", 0))
		var root := Node3D.new()
		root.name = "SquallBand%d" % band_id
		squall_container.add_child(root)

		var shell := MeshInstance3D.new()
		shell.name = "Shell"
		var shell_mesh := BoxMesh.new()
		var half_extents: Vector3 = band.get("half_extents", Vector3.ONE)
		shell_mesh.size = Vector3(half_extents.x * 2.0, 1.7, half_extents.z * 2.0)
		shell.mesh = shell_mesh
		shell.position = Vector3(0.0, 0.95, 0.0)
		var shell_material := StandardMaterial3D.new()
		shell_material.albedo_color = Color(0.20, 0.37, 0.52, 0.22)
		shell_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		shell_material.roughness = 0.18
		shell.material_override = shell_material
		root.add_child(shell)

		var core := MeshInstance3D.new()
		core.name = "Core"
		var core_mesh := CylinderMesh.new()
		core_mesh.height = 0.12
		core_mesh.top_radius = maxf(1.2, minf(half_extents.x, half_extents.z))
		core_mesh.bottom_radius = core_mesh.top_radius
		core.mesh = core_mesh
		core.position = Vector3(0.0, 0.06, 0.0)
		var core_material := StandardMaterial3D.new()
		core_material.albedo_color = Color(0.30, 0.70, 0.96, 0.46)
		core_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		core_material.roughness = 0.1
		core.material_override = core_material
		root.add_child(core)

		var label := Label3D.new()
		label.name = "Label"
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 22
		label.position = Vector3(0.0, 2.2, 0.0)
		root.add_child(label)

		squall_visuals[band_id] = {
			"root": root,
			"shell_material": shell_material,
			"core_material": core_material,
			"label": label,
		}

func _refresh_cache_visual() -> void:
	if cache_root == null:
		return

	var cache_position: Vector3 = NetworkRuntime.run_state.get("cache_position", Vector3.ZERO)
	var cache_radius: float = float(NetworkRuntime.run_state.get("cache_radius", 2.9))
	var cache_available := bool(NetworkRuntime.run_state.get("cache_available", false))
	cache_root.position = cache_position

	var ring_mesh_instance := cache_root.get_node_or_null("CacheRing") as MeshInstance3D
	if ring_mesh_instance != null:
		var ring_mesh := ring_mesh_instance.mesh as CylinderMesh
		if ring_mesh != null:
			ring_mesh.top_radius = cache_radius
			ring_mesh.bottom_radius = cache_radius

	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var boat_speed: float = absf(float(NetworkRuntime.boat_state.get("speed", 0.0)))
	var in_zone := boat_position.distance_to(cache_position) <= cache_radius
	var ready_color := Color(0.21, 0.82, 0.57) if cache_available and in_zone and boat_speed <= float(NetworkRuntime.run_state.get("cache_max_speed", 1.75)) else Color(0.23, 0.71, 0.84)
	if not cache_available:
		ready_color = Color(0.44, 0.50, 0.56)
	cache_ring_material.albedo_color = ready_color
	cache_crate_material.albedo_color = Color(0.19, 0.48, 0.58).lerp(Color(0.50, 0.55, 0.60), 1.0 if not cache_available else 0.0)
	cache_label.text = "%s\n+%d gold | +%d salvage | +%d patch kit | Max Speed %.1f" % [
		str(NetworkRuntime.run_state.get("cache_label", "Resupply Cache")),
		NetworkRuntime.RESUPPLY_CACHE_GOLD_BONUS,
		NetworkRuntime.RESUPPLY_CACHE_SALVAGE_BONUS,
		NetworkRuntime.RESUPPLY_CACHE_SUPPLY_GRANT,
		float(NetworkRuntime.run_state.get("cache_max_speed", 1.75)),
	]
	if not cache_available:
		cache_label.text = "%s\nRecovered" % str(NetworkRuntime.run_state.get("cache_label", "Resupply Cache"))
	cache_label.modulate = ready_color.lightened(0.18)

func _refresh_extraction_visual() -> void:
	var extraction_position: Vector3 = NetworkRuntime.run_state.get("extraction_position", Vector3.ZERO)
	extraction_root.position = extraction_position
	var extraction_radius: float = float(NetworkRuntime.run_state.get("extraction_radius", 3.7))
	var ring_mesh_instance := extraction_root.get_node_or_null("Ring") as MeshInstance3D
	if ring_mesh_instance != null:
		var ring_mesh := ring_mesh_instance.mesh as CylinderMesh
		if ring_mesh != null:
			ring_mesh.top_radius = extraction_radius
			ring_mesh.bottom_radius = extraction_radius
	var cargo_count := int(NetworkRuntime.run_state.get("cargo_count", 0))
	var phase := str(NetworkRuntime.run_state.get("phase", "running"))
	var can_extract := cargo_count > 0 and _boat_within_extraction_zone() and float(NetworkRuntime.boat_state.get("speed", 0.0)) <= NetworkRuntime.EXTRACTION_MAX_SPEED
	var extraction_color := EXTRACTION_READY_COLOR if can_extract else EXTRACTION_IDLE_COLOR
	if phase == "failed":
		extraction_color = EXTRACTION_FAILED_COLOR
	elif phase == "success":
		extraction_color = EXTRACTION_READY_COLOR

	extraction_ring_material.albedo_color = extraction_color
	extraction_buoy_material.albedo_color = extraction_color
	extraction_label.text = "Extraction\nCargo %d | %.1f/%.1fs" % [
		cargo_count,
		float(NetworkRuntime.run_state.get("extraction_progress", 0.0)),
		float(NetworkRuntime.run_state.get("extraction_duration", 1.0)),
	]
	extraction_label.modulate = extraction_color.lightened(0.18)

func _refresh_result_overlay() -> void:
	var phase := str(NetworkRuntime.run_state.get("phase", "running"))
	result_layer.visible = phase != "running"
	if phase == "running":
		return

	hud_icons.set_icon(result_panel_icon, "extraction" if phase == "success" else "brace")
	var cargo_count := int(NetworkRuntime.run_state.get("cargo_count", 0))
	var cargo_secured := int(NetworkRuntime.run_state.get("cargo_secured", 0))
	var cargo_lost: int = maxi(0, cargo_count - cargo_secured)
	result_title_label.text = str(NetworkRuntime.run_state.get("result_title", "Run Complete"))
	result_body_label.text = "%s\n\nCollected: %d\nSecured: %d\nLost: %d\nGold: %d\nSalvage: %d\nCache Recovered: %s\nPatch Kits Left: %d\nBlocks Destroyed: %d\nChunks Lost: %d\nCargo Lost To Sea: %d\nBlueprint Version: %d" % [
		str(NetworkRuntime.run_state.get("result_message", "")),
		cargo_count,
		cargo_secured,
		cargo_lost,
		int(NetworkRuntime.run_state.get("reward_gold", 0)),
		int(NetworkRuntime.run_state.get("reward_salvage", 0)),
		"yes" if bool(NetworkRuntime.run_state.get("cache_recovered", false)) else "no",
		int(NetworkRuntime.run_state.get("repair_supplies", 0)),
		int(NetworkRuntime.run_state.get("destroyed_block_count", 0)),
		int(NetworkRuntime.run_state.get("detached_chunk_count", 0)),
		int(NetworkRuntime.run_state.get("cargo_lost_to_sea", 0)),
		int(NetworkRuntime.run_state.get("blueprint_version", 1)),
	]
	result_panel.modulate = Color(0.98, 1.0, 0.98) if phase == "success" else Color(1.0, 0.94, 0.94)
	result_continue_button.disabled = false

func _get_run_objective_icon_id(
	phase: String,
	local_station_id: String,
	selected_station_id: String,
	current_cargo: int,
	cargo_capacity: int
) -> String:
	if phase == "success":
		return "extraction"
	if phase == "failed":
		return "brace"
	if cargo_capacity > 0 and current_cargo >= cargo_capacity:
		return "cargo"
	if local_station_id == "helm" or selected_station_id == "helm":
		return "helm"
	if local_station_id == "grapple" or selected_station_id == "grapple":
		return "salvage"
	return "extraction"

func _prime_run_hud_event_state() -> void:
	last_hud_collision_count = int(NetworkRuntime.boat_state.get("collision_count", 0))
	last_hud_detached_chunk_count = int(NetworkRuntime.run_state.get("detached_chunk_count", 0))
	last_hud_cargo_lost_to_sea = int(NetworkRuntime.run_state.get("cargo_lost_to_sea", 0))
	last_hud_rescue_completed = bool(NetworkRuntime.run_state.get("rescue_completed", false))
	last_hud_cache_recovered = bool(NetworkRuntime.run_state.get("cache_recovered", false))
	last_hud_overboard_count = int(NetworkRuntime.run_state.get("overboard_count", 0))
	last_hud_phase = str(NetworkRuntime.run_state.get("phase", "running"))
	last_local_overboard = _is_local_overboard()

func _push_event_callout(text: String, color: Color, duration: float = 1.9) -> void:
	if event_callout_label == null:
		return
	event_callout_timer = duration
	event_callout_color = color
	event_callout_label.text = text
	event_callout_label.modulate = color
	event_callout_label.visible = true

func _update_event_callout(delta: float) -> void:
	if event_callout_label == null:
		return
	if event_callout_timer <= 0.0:
		event_callout_label.visible = false
		return
	event_callout_timer = maxf(0.0, event_callout_timer - delta)
	var fade_ratio := clampf(event_callout_timer / 1.9, 0.0, 1.0)
	event_callout_label.visible = true
	event_callout_label.modulate = Color(event_callout_color.r, event_callout_color.g, event_callout_color.b, clampf(0.2 + fade_ratio, 0.0, 1.0))

func _tick_reaction_visuals(delta: float) -> void:
	var expired_peer_ids: Array = []
	for peer_id_variant in reaction_visual_state.keys():
		var peer_id := int(peer_id_variant)
		var peer_reaction: Dictionary = reaction_visual_state[peer_id]
		peer_reaction["active_time"] = maxf(0.0, float(peer_reaction.get("active_time", 0.0)) - delta)
		peer_reaction["recovery_time"] = maxf(0.0, float(peer_reaction.get("recovery_time", 0.0)) - delta)
		if float(peer_reaction.get("active_time", 0.0)) <= 0.0 and float(peer_reaction.get("recovery_time", 0.0)) <= 0.0:
			expired_peer_ids.append(peer_id)
			continue
		reaction_visual_state[peer_id] = peer_reaction
	for peer_id_variant in expired_peer_ids:
		reaction_visual_state.erase(int(peer_id_variant))
	local_camera_jolt = local_camera_jolt.lerp(Vector3.ZERO, minf(1.0, delta * 8.4))
	_consume_local_reaction_impulse()

func _get_reaction_visual(peer_id: int) -> Dictionary:
	return Dictionary(reaction_visual_state.get(peer_id, {}))

func _consume_local_reaction_impulse() -> void:
	var local_reaction := _get_reaction_visual(_get_local_peer_id())
	if local_reaction.is_empty():
		return
	var reaction_id := int(local_reaction.get("reaction_id", 0))
	if reaction_id == 0 or reaction_id == last_local_reaction_id:
		return
	last_local_reaction_id = reaction_id
	var knockback: Vector3 = local_reaction.get("knockback_velocity", Vector3.ZERO)
	if knockback.length() > 0.01:
		local_camera_jolt += knockback.normalized() * (0.26 + float(local_reaction.get("strength", 0.5)) * 0.22)

func _update_crew_visuals(delta: float) -> void:
	var idle_slot_index := 0
	for peer_id in NetworkRuntime.get_player_peer_ids():
		var visual: Dictionary = crew_visuals.get(int(peer_id), {})
		var crew_root := visual.get("root") as Node3D
		if crew_root == null:
			continue
		var station_id := NetworkRuntime.get_peer_station_id(int(peer_id))
		var avatar_state: Dictionary = NetworkRuntime.get_run_avatar_state().get(int(peer_id), {})
		var overboard := str(avatar_state.get("mode", NetworkRuntime.RUN_AVATAR_MODE_DECK)) == NetworkRuntime.RUN_AVATAR_MODE_OVERBOARD
		var target_position: Vector3 = IDLE_CREW_SLOTS[idle_slot_index % IDLE_CREW_SLOTS.size()]
		var target_yaw := float(avatar_state.get("facing_y", PI))
		if overboard:
			crew_root.top_level = true
		elif not station_id.is_empty() and _station_anchors_avatar(station_id):
			target_position = NetworkRuntime.get_station_position(station_id) + Vector3(0.0, 0.18, 0.0)
			target_yaw = 0.0
		elif not avatar_state.is_empty():
			target_position = avatar_state.get("deck_position", target_position)
		else:
			idle_slot_index += 1
		var peer_reaction := _get_reaction_visual(int(peer_id))
		var local_knockback := Vector3.ZERO
		var intensity := 0.0
		if not peer_reaction.is_empty():
			var active_time := float(peer_reaction.get("active_time", 0.0))
			var recovery_time := float(peer_reaction.get("recovery_time", 0.0))
			var recovery_duration := maxf(0.01, float(peer_reaction.get("recovery_duration", 0.01)))
			intensity = 1.0 if active_time > 0.0 else clampf(recovery_time / recovery_duration, 0.0, 1.0) * 0.55
			var knockback: Vector3 = peer_reaction.get("knockback_velocity", Vector3.ZERO)
			local_knockback = boat_root.global_transform.basis.inverse() * knockback
			target_position += local_knockback * 0.08 * intensity
			target_position.y += sin(connect_time_seconds * 22.0 + float(peer_id)) * 0.06 * intensity
		if overboard:
			var target_world_position: Vector3 = avatar_state.get("world_position", boat_root.global_position)
			target_world_position.y += sin(connect_time_seconds * 2.8 + float(peer_id)) * 0.05
			crew_root.global_position = crew_root.global_position.lerp(target_world_position, minf(1.0, delta * 8.0))
			crew_root.rotation.y = lerp_angle(crew_root.rotation.y, target_yaw, minf(1.0, delta * 10.0))
			crew_root.rotation.x = lerp_angle(crew_root.rotation.x, 0.12 + clampf(local_knockback.z * -0.03 * intensity, -0.18, 0.18), minf(1.0, delta * 10.0))
			crew_root.rotation.z = lerp_angle(crew_root.rotation.z, clampf(local_knockback.x * 0.04 * intensity, -0.18, 0.18), minf(1.0, delta * 10.0))
		else:
			crew_root.top_level = false
			crew_root.position = crew_root.position.lerp(target_position, minf(1.0, delta * 8.5))
			crew_root.rotation.y = lerp_angle(crew_root.rotation.y, target_yaw, minf(1.0, delta * 10.0))
			crew_root.rotation.x = lerp_angle(crew_root.rotation.x, clampf(local_knockback.z * -0.05 * intensity, -0.42, 0.42), minf(1.0, delta * 12.0))
			crew_root.rotation.z = lerp_angle(crew_root.rotation.z, clampf(local_knockback.x * 0.055 * intensity, -0.48, 0.48), minf(1.0, delta * 12.0))
		var nameplate := visual.get("nameplate") as Label3D
		if nameplate != null:
			var peer_data: Dictionary = NetworkRuntime.peer_snapshot.get(int(peer_id), {})
			var role_label := "Overboard" if overboard else (NetworkRuntime.get_station_label(station_id) if not station_id.is_empty() else "Crew")
			nameplate.text = "%s - %s" % [str(peer_data.get("name", "Crew")), role_label]
			if not peer_reaction.is_empty():
				nameplate.text += " [%s]" % str(peer_reaction.get("type", "reacting")).capitalize()

func _process_local_run_avatar_movement(delta: float) -> void:
	var local_station_id := NetworkRuntime.get_peer_station_id(_get_local_peer_id())
	if not _is_local_overboard() and not local_station_id.is_empty() and _station_anchors_avatar(local_station_id):
		local_run_avatar_position = _get_local_run_avatar_target()
		local_run_avatar_world_position = _get_local_avatar_world_position()
		local_run_avatar_velocity = Vector3.ZERO
		return

	var input_vector := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A):
		input_vector.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		input_vector.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		input_vector.y += 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input_vector.y -= 1.0
	input_vector = input_vector.limit_length(1.0)

	var move_direction_world := Vector3.ZERO
	if input_vector.length() > 0.001:
		var camera_forward := -camera.global_transform.basis.z
		camera_forward.y = 0.0
		camera_forward = camera_forward.normalized()
		var camera_right := camera.global_transform.basis.x
		camera_right.y = 0.0
		camera_right = camera_right.normalized()
		move_direction_world = (camera_right * input_vector.x) + (camera_forward * input_vector.y)
		if move_direction_world.length() > 0.001:
			move_direction_world = move_direction_world.normalized()

	var local_reaction := _get_reaction_visual(_get_local_peer_id())
	var active_reaction := float(local_reaction.get("active_time", 0.0)) > 0.0
	var recovering := float(local_reaction.get("recovery_time", 0.0)) > 0.0
	if active_reaction:
		move_direction_world = Vector3.ZERO
	elif recovering:
		move_direction_world *= 0.35

	if _is_local_overboard():
		if move_direction_world.length() > 0.001:
			local_run_avatar_velocity.x = move_toward(local_run_avatar_velocity.x, move_direction_world.x * RUN_SWIM_MOVE_SPEED, RUN_SWIM_ACCELERATION * delta)
			local_run_avatar_velocity.z = move_toward(local_run_avatar_velocity.z, move_direction_world.z * RUN_SWIM_MOVE_SPEED, RUN_SWIM_ACCELERATION * delta)
		else:
			local_run_avatar_velocity.x = move_toward(local_run_avatar_velocity.x, 0.0, RUN_SWIM_ACCELERATION * delta)
			local_run_avatar_velocity.z = move_toward(local_run_avatar_velocity.z, 0.0, RUN_SWIM_ACCELERATION * delta)
		local_run_avatar_world_position += Vector3(local_run_avatar_velocity.x, 0.0, local_run_avatar_velocity.z) * delta
		local_run_avatar_world_position = _clamp_local_swim_world_position(local_run_avatar_world_position)
		return

	var move_direction_local := Vector3.ZERO
	if move_direction_world.length() > 0.001:
		move_direction_local = boat_root.global_transform.basis.inverse() * move_direction_world
		move_direction_local.y = 0.0
		move_direction_local = move_direction_local.normalized()

	if move_direction_local.length() > 0.001:
		local_run_avatar_velocity.x = move_toward(local_run_avatar_velocity.x, move_direction_local.x * RUN_AVATAR_MOVE_SPEED, RUN_AVATAR_ACCELERATION * delta)
		local_run_avatar_velocity.z = move_toward(local_run_avatar_velocity.z, move_direction_local.z * RUN_AVATAR_MOVE_SPEED, RUN_AVATAR_ACCELERATION * delta)
	else:
		local_run_avatar_velocity.x = move_toward(local_run_avatar_velocity.x, 0.0, RUN_AVATAR_ACCELERATION * delta)
		local_run_avatar_velocity.z = move_toward(local_run_avatar_velocity.z, 0.0, RUN_AVATAR_ACCELERATION * delta)

	local_run_avatar_position += Vector3(local_run_avatar_velocity.x, 0.0, local_run_avatar_velocity.z) * delta
	local_run_avatar_position = _clamp_run_avatar_position(local_run_avatar_position)
	local_run_avatar_world_position = _get_local_avatar_world_position()

func _sync_local_run_avatar_state(delta: float) -> void:
	run_avatar_sync_timer = maxf(0.0, run_avatar_sync_timer - delta)
	if run_avatar_sync_timer > 0.0:
		return
	run_avatar_sync_timer = RUN_AVATAR_SYNC_INTERVAL
	NetworkRuntime.send_local_run_avatar_state(
		local_run_avatar_position,
		local_run_avatar_world_position,
		Vector3(local_run_avatar_velocity.x, 0.0, local_run_avatar_velocity.z),
		local_avatar_facing_y,
		not _is_local_overboard(),
		local_run_avatar_mode
	)

func _collect_input_state(delta: float) -> Dictionary:
	var input_state := {
		"claim_station": "",
		"request_brace": false,
		"request_grapple": false,
		"request_repair": false,
		"request_recover": false,
		"throttle": 0.0,
		"steer": 0.0,
	}
	var local_reaction := _get_reaction_visual(_get_local_peer_id())
	var active_reaction := float(local_reaction.get("active_time", 0.0)) > 0.0
	var recovering := float(local_reaction.get("recovery_time", 0.0)) > 0.0

	if not active_reaction:
		_collect_station_selection_input()
		_collect_station_interaction_input(input_state)
		if not recovering:
			_collect_action_input(input_state)
		_collect_drive_input(input_state)
		if recovering:
			input_state["throttle"] = float(input_state.get("throttle", 0.0)) * 0.35
			input_state["steer"] = float(input_state.get("steer", 0.0)) * 0.35

	var autorun_role := str(launch_overrides.get("autorun_role", ""))
	if not active_reaction and not autorun_role.is_empty():
		_apply_autorun_role(delta, autorun_role, input_state)
	elif not active_reaction and bool(launch_overrides.get("autorun_demo", false)):
		_apply_autorun_demo(delta, input_state)
	elif not active_reaction:
		_apply_scripted_station_input(delta, input_state)

	return input_state

func _collect_station_selection_input() -> void:
	if _is_local_overboard():
		station_prev_latched = Input.is_key_pressed(KEY_Q)
		station_next_latched = Input.is_key_pressed(KEY_E)
		return
	var previous_pressed := Input.is_key_pressed(KEY_Q)
	if previous_pressed and not station_prev_latched:
		_cycle_selected_station(-1)
	station_prev_latched = previous_pressed

	var next_pressed := Input.is_key_pressed(KEY_E)
	if next_pressed and not station_next_latched:
		_cycle_selected_station(1)
	station_next_latched = next_pressed

func _collect_station_interaction_input(input_state: Dictionary) -> void:
	var interact_pressed := Input.is_key_pressed(KEY_F)
	if interact_pressed and not interact_latched:
		var active_tool_id := _get_selected_run_tool_id()
		if _is_local_overboard():
			input_state["request_recover"] = true
			interact_latched = interact_pressed
			return
		match active_tool_id:
			"brace":
				input_state["request_brace"] = true
				interact_latched = interact_pressed
				return
			"repair":
				input_state["request_repair"] = true
				interact_latched = interact_pressed
				return
		var selected_station_id := _get_selected_station_id()
		var selected_station: Dictionary = NetworkRuntime.station_state.get(selected_station_id, {})
		var occupant_peer_id := int(selected_station.get("occupant_peer_id", 0))
		if occupant_peer_id == _get_local_peer_id():
			input_state["claim_station"] = "__release__"
		elif occupant_peer_id == 0:
			input_state["claim_station"] = selected_station_id
	interact_latched = interact_pressed

func _collect_action_input(input_state: Dictionary) -> void:
	if _is_local_overboard():
		brace_request_latched = Input.is_key_pressed(KEY_SPACE)
		grapple_request_latched = Input.is_key_pressed(KEY_G)
		repair_request_latched = Input.is_key_pressed(KEY_R)
		return
	var local_station_id := NetworkRuntime.get_peer_station_id(_get_local_peer_id())

	var brace_pressed := Input.is_key_pressed(KEY_SPACE)
	if brace_pressed and not brace_request_latched:
		input_state["request_brace"] = true
	brace_request_latched = brace_pressed

	var grapple_pressed := Input.is_key_pressed(KEY_G)
	if grapple_pressed and not grapple_request_latched and local_station_id == "grapple":
		input_state["request_grapple"] = true
	grapple_request_latched = grapple_pressed

	var repair_pressed := Input.is_key_pressed(KEY_R)
	if repair_pressed and not repair_request_latched:
		input_state["request_repair"] = true
	repair_request_latched = repair_pressed

func _collect_drive_input(input_state: Dictionary) -> void:
	if NetworkRuntime.get_peer_station_id(_get_local_peer_id()) != "helm":
		return
	if str(NetworkRuntime.run_state.get("phase", "running")) != "running":
		return

	var throttle := 0.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		throttle += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		throttle -= 1.0

	var steer := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		steer += 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		steer -= 1.0

	input_state["throttle"] = clampf(throttle, -1.0, 1.0)
	input_state["steer"] = clampf(steer, -1.0, 1.0)

func _apply_scripted_station_input(delta: float, input_state: Dictionary) -> void:
	var desired_station_id := str(launch_overrides.get("autoclaim_station", ""))
	if desired_station_id.is_empty() and autopilot_remaining_seconds > 0.0:
		desired_station_id = "helm"

	if autopilot_remaining_seconds > 0.0:
		autopilot_remaining_seconds = maxf(0.0, autopilot_remaining_seconds - delta)

	if not desired_station_id.is_empty():
		_request_station_if_needed(desired_station_id, input_state, delta)

	if desired_station_id == "helm" and autopilot_remaining_seconds > 0.0 and NetworkRuntime.get_peer_station_id(_get_local_peer_id()) == "helm":
		input_state["throttle"] = float(launch_overrides.get("autodrive_throttle", 1.0))
		input_state["steer"] = float(launch_overrides.get("autodrive_steer", 0.0))
		_maybe_request_autobrace(input_state, true)
	elif desired_station_id == "brace":
		_maybe_request_autobrace(input_state, true)
	elif desired_station_id == "repair" and action_request_cooldown <= 0.0 and int(NetworkRuntime.boat_state.get("breach_stacks", 0)) > 0:
		var repair_target := _find_local_repair_target()
		if not repair_target.is_empty():
			input_state["request_repair"] = true
			action_request_cooldown = 0.45
		else:
			var damage_target := _find_most_damaged_runtime_block()
			if not damage_target.is_empty():
				_scripted_move_local_avatar_toward(damage_target.get("local_position", local_run_avatar_position), delta)

func _apply_autorun_role(delta: float, autorun_role: String, input_state: Dictionary) -> void:
	if _is_local_overboard():
		_apply_overboard_recovery_role(delta, input_state)
		return
	match autorun_role:
		"driver":
			_apply_driver_role(delta, input_state)
		"driver_detach_test":
			_apply_driver_detach_test_role(delta, input_state)
		"overboard_recovery":
			_apply_overboard_recovery_role(delta, input_state)
		"grapple":
			_apply_grapple_role(delta, input_state)
		"brace":
			_apply_brace_role(delta, input_state)
		"repair":
			_apply_repair_role(delta, input_state)
		_:
			_apply_scripted_station_input(delta, input_state)

func _apply_autorun_demo(delta: float, input_state: Dictionary) -> void:
	if str(NetworkRuntime.run_state.get("phase", "running")) != "running":
		return
	if _is_local_overboard():
		_apply_overboard_recovery_role(delta, input_state)
		return

	var local_station_id := NetworkRuntime.get_peer_station_id(_get_local_peer_id())
	var loot_remaining := int(NetworkRuntime.run_state.get("loot_remaining", 0))
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var boat_speed: float = float(NetworkRuntime.boat_state.get("speed", 0.0))
	var wreck_position: Vector3 = NetworkRuntime.run_state.get("wreck_position", Vector3.ZERO)
	var wreck_radius: float = float(NetworkRuntime.run_state.get("wreck_radius", 4.1))
	var breach_stacks := int(NetworkRuntime.boat_state.get("breach_stacks", 0))
	var brace_timer: float = float(NetworkRuntime.boat_state.get("brace_timer", 0.0))
	var brace_cooldown: float = float(NetworkRuntime.boat_state.get("brace_cooldown", 0.0))
	var cache_available := bool(NetworkRuntime.run_state.get("cache_available", false))
	var cache_position: Vector3 = NetworkRuntime.run_state.get("cache_position", Vector3.ZERO)
	var cache_radius: float = float(NetworkRuntime.run_state.get("cache_radius", 2.9))
	var cache_max_speed: float = float(NetworkRuntime.run_state.get("cache_max_speed", 1.75))
	var rescue_available := bool(NetworkRuntime.run_state.get("rescue_available", false))
	var rescue_position: Vector3 = NetworkRuntime.run_state.get("rescue_position", Vector3.ZERO)
	var rescue_radius: float = float(NetworkRuntime.run_state.get("rescue_radius", 3.4))
	var rescue_max_speed: float = float(NetworkRuntime.run_state.get("rescue_max_speed", NetworkRuntime.RESCUE_MAX_SPEED))

	if loot_remaining > 0:
		if boat_position.distance_to(wreck_position) > wreck_radius * 0.55:
			_request_station_if_needed("helm", input_state, delta)
			if local_station_id == "helm":
				_apply_drive_to_target(wreck_position + Vector3(0.0, 0.0, -1.1), input_state)
				_maybe_request_autobrace(input_state)
			return

		if boat_speed > float(NetworkRuntime.run_state.get("salvage_max_speed", NetworkRuntime.SALVAGE_MAX_SPEED)):
			_request_station_if_needed("helm", input_state, delta)
			if local_station_id == "helm":
				_hold_position_over_target(wreck_position, float(NetworkRuntime.run_state.get("salvage_max_speed", NetworkRuntime.SALVAGE_MAX_SPEED)), input_state)
				_maybe_request_autobrace(input_state)
			return

		if brace_timer <= 0.0 and brace_cooldown <= 0.0:
			if action_request_cooldown <= 0.0:
				input_state["request_brace"] = true
				action_request_cooldown = 0.2
			return

		if brace_timer <= 0.0:
			_request_station_if_needed("helm", input_state, delta)
			if local_station_id == "helm":
				_hold_position_over_target(wreck_position, float(NetworkRuntime.run_state.get("salvage_max_speed", NetworkRuntime.SALVAGE_MAX_SPEED)), input_state)
			return

		_request_station_if_needed("grapple", input_state, delta)
		if local_station_id == "grapple" and action_request_cooldown <= 0.0:
			input_state["request_grapple"] = true
			action_request_cooldown = 0.45
		return

	if breach_stacks > 0 and int(NetworkRuntime.run_state.get("repair_supplies", 0)) > 0:
		var repair_target := _find_local_repair_target()
		if not repair_target.is_empty() and action_request_cooldown <= 0.0:
			input_state["request_repair"] = true
			action_request_cooldown = 0.45
		else:
			var damage_target := _find_most_damaged_runtime_block()
			if not damage_target.is_empty():
				_scripted_move_local_avatar_toward(damage_target.get("local_position", local_run_avatar_position), delta)
		return

	if rescue_available:
		if boat_position.distance_to(rescue_position) > rescue_radius * 0.8:
			_request_station_if_needed("helm", input_state, delta)
			if local_station_id == "helm":
				_apply_drive_to_target(rescue_position + Vector3(0.0, 0.0, -0.8), input_state, 0.52)
				_maybe_request_autobrace(input_state)
			return
		if boat_speed > rescue_max_speed:
			_request_station_if_needed("helm", input_state, delta)
			if local_station_id == "helm":
				_hold_position_over_target(rescue_position, rescue_max_speed, input_state)
				_maybe_request_autobrace(input_state)
			return
		_request_station_if_needed("grapple", input_state, delta)
		if local_station_id == "grapple" and action_request_cooldown <= 0.0:
			input_state["request_grapple"] = true
			action_request_cooldown = 0.45
		return

	if cache_available and boat_position.distance_to(cache_position) <= cache_radius and absf(boat_speed) <= cache_max_speed:
		_request_station_if_needed("grapple", input_state, delta)
		if local_station_id == "grapple" and action_request_cooldown <= 0.0:
			input_state["request_grapple"] = true
			action_request_cooldown = 0.45
		return

	_request_station_if_needed("helm", input_state, delta)
	if local_station_id != "helm":
		return

	_apply_coordinated_return_route(input_state)
	_maybe_request_autobrace(input_state)

func _apply_driver_role(delta: float, input_state: Dictionary) -> void:
	if str(NetworkRuntime.run_state.get("phase", "running")) != "running":
		return

	var local_station_id := NetworkRuntime.get_peer_station_id(_get_local_peer_id())
	_request_station_if_needed("helm", input_state, delta)
	if local_station_id != "helm":
		return

	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var loot_remaining := int(NetworkRuntime.run_state.get("loot_remaining", 0))
	var wreck_position: Vector3 = NetworkRuntime.run_state.get("wreck_position", Vector3.ZERO)
	var wreck_radius: float = float(NetworkRuntime.run_state.get("wreck_radius", 4.1))
	if loot_remaining > 0:
		if not _station_is_crewed("grapple"):
			input_state["throttle"] = 0.0
			input_state["steer"] = 0.0
			_maybe_request_autobrace(input_state)
			return
		if boat_position.distance_to(wreck_position) > wreck_radius * 0.55:
			_apply_drive_to_target(wreck_position + Vector3(0.0, 0.0, -1.1), input_state)
		else:
			_hold_position_over_target(wreck_position, float(NetworkRuntime.run_state.get("salvage_max_speed", NetworkRuntime.SALVAGE_MAX_SPEED)), input_state)
		_maybe_request_autobrace(input_state)
		return

	if bool(NetworkRuntime.run_state.get("rescue_available", false)):
		if not _station_is_crewed("grapple"):
			input_state["throttle"] = 0.0
			input_state["steer"] = 0.0
			_maybe_request_autobrace(input_state)
			return
		var rescue_position: Vector3 = NetworkRuntime.run_state.get("rescue_position", Vector3.ZERO)
		var rescue_radius: float = float(NetworkRuntime.run_state.get("rescue_radius", 3.4))
		if boat_position.distance_to(rescue_position) > rescue_radius * 0.8:
			_apply_drive_to_target(rescue_position + Vector3(0.0, 0.0, -0.8), input_state, 0.52)
		else:
			_hold_position_over_target(rescue_position, float(NetworkRuntime.run_state.get("rescue_max_speed", NetworkRuntime.RESCUE_MAX_SPEED)), input_state)
		_maybe_request_autobrace(input_state)
		return

	_apply_coordinated_return_route(input_state)
	_maybe_request_autobrace(input_state)

func _apply_driver_detach_test_role(delta: float, input_state: Dictionary) -> void:
	if str(NetworkRuntime.run_state.get("phase", "running")) != "running":
		return

	var local_station_id := NetworkRuntime.get_peer_station_id(_get_local_peer_id())
	_request_station_if_needed("helm", input_state, delta)
	if local_station_id != "helm":
		return

	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var loot_remaining := int(NetworkRuntime.run_state.get("loot_remaining", 0))
	var wreck_position: Vector3 = NetworkRuntime.run_state.get("wreck_position", Vector3.ZERO)
	var wreck_radius: float = float(NetworkRuntime.run_state.get("wreck_radius", 4.1))
	if loot_remaining > 0:
		if not _station_is_crewed("grapple"):
			input_state["throttle"] = 0.0
			input_state["steer"] = 0.0
			_maybe_request_autobrace(input_state)
			return
		if boat_position.distance_to(wreck_position) > wreck_radius * 0.55:
			_apply_drive_to_target(wreck_position + Vector3(0.0, 0.0, -1.1), input_state)
		else:
			_hold_position_over_target(wreck_position, float(NetworkRuntime.run_state.get("salvage_max_speed", NetworkRuntime.SALVAGE_MAX_SPEED)), input_state)
		_maybe_request_autobrace(input_state)
		return

	if int(NetworkRuntime.run_state.get("detached_chunk_count", 0)) > 0 or int(NetworkRuntime.run_state.get("cargo_lost_to_sea", 0)) > 0:
		input_state["throttle"] = 0.0
		input_state["steer"] = 0.0
		_maybe_request_autobrace(input_state)
		return

	_apply_drive_to_target(Vector3(0.0, 0.0, 19.2), input_state, 0.84)
	_maybe_request_autobrace(input_state)

func _apply_grapple_role(delta: float, input_state: Dictionary) -> void:
	if str(NetworkRuntime.run_state.get("phase", "running")) != "running":
		return

	var local_station_id := NetworkRuntime.get_peer_station_id(_get_local_peer_id())
	_request_station_if_needed("grapple", input_state, delta)
	if local_station_id != "grapple":
		return

	var cache_available := bool(NetworkRuntime.run_state.get("cache_available", false))
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	if bool(NetworkRuntime.run_state.get("rescue_available", false)):
		var rescue_position: Vector3 = NetworkRuntime.run_state.get("rescue_position", Vector3.ZERO)
		var rescue_radius: float = float(NetworkRuntime.run_state.get("rescue_radius", 3.4))
		if boat_position.distance_to(rescue_position) <= rescue_radius and absf(float(NetworkRuntime.boat_state.get("speed", 0.0))) <= float(NetworkRuntime.run_state.get("rescue_max_speed", NetworkRuntime.RESCUE_MAX_SPEED)) and action_request_cooldown <= 0.0:
			input_state["request_grapple"] = true
			action_request_cooldown = 0.45
			return

	if cache_available:
		var cache_position: Vector3 = NetworkRuntime.run_state.get("cache_position", Vector3.ZERO)
		var cache_radius: float = float(NetworkRuntime.run_state.get("cache_radius", 2.9))
		if boat_position.distance_to(cache_position) <= cache_radius and absf(float(NetworkRuntime.boat_state.get("speed", 0.0))) <= float(NetworkRuntime.run_state.get("cache_max_speed", 1.75)) and action_request_cooldown <= 0.0:
			input_state["request_grapple"] = true
			action_request_cooldown = 0.45
			return

	if int(NetworkRuntime.run_state.get("loot_remaining", 0)) <= 0:
		return

	var wreck_position: Vector3 = NetworkRuntime.run_state.get("wreck_position", Vector3.ZERO)
	var wreck_radius: float = float(NetworkRuntime.run_state.get("wreck_radius", 4.1))
	if boat_position.distance_to(wreck_position) > wreck_radius:
		return
	if float(NetworkRuntime.boat_state.get("brace_timer", 0.0)) <= 0.0:
		return
	if absf(float(NetworkRuntime.boat_state.get("speed", 0.0))) > float(NetworkRuntime.run_state.get("salvage_max_speed", NetworkRuntime.SALVAGE_MAX_SPEED)):
		return
	if action_request_cooldown > 0.0:
		return

	input_state["request_grapple"] = true
	action_request_cooldown = 0.45

func _apply_brace_role(_delta: float, input_state: Dictionary) -> void:
	if str(NetworkRuntime.run_state.get("phase", "running")) != "running":
		return
	if float(NetworkRuntime.boat_state.get("brace_cooldown", 0.0)) > 0.0 or action_request_cooldown > 0.0:
		return

	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var wreck_position: Vector3 = NetworkRuntime.run_state.get("wreck_position", Vector3.ZERO)
	var wreck_radius: float = float(NetworkRuntime.run_state.get("wreck_radius", 4.1))
	var salvage_ready := int(NetworkRuntime.run_state.get("loot_remaining", 0)) > 0 and boat_position.distance_to(wreck_position) <= wreck_radius + 0.55 and absf(float(NetworkRuntime.boat_state.get("speed", 0.0))) <= float(NetworkRuntime.run_state.get("salvage_max_speed", NetworkRuntime.SALVAGE_MAX_SPEED)) + 0.45
	var squall_ready := _boat_inside_any_squall()
	if not salvage_ready and not squall_ready and not _should_autobrace():
		return

	input_state["request_brace"] = true
	action_request_cooldown = 0.35

func _apply_repair_role(delta: float, input_state: Dictionary) -> void:
	if str(NetworkRuntime.run_state.get("phase", "running")) != "running":
		return
	if int(NetworkRuntime.boat_state.get("breach_stacks", 0)) <= 0:
		return
	if int(NetworkRuntime.run_state.get("repair_supplies", 0)) <= 0:
		return
	if float(NetworkRuntime.boat_state.get("repair_cooldown", 0.0)) > 0.0 or action_request_cooldown > 0.0:
		return
	var repair_target := _find_local_repair_target()
	if repair_target.is_empty():
		var damage_target := _find_most_damaged_runtime_block()
		if not damage_target.is_empty():
			_scripted_move_local_avatar_toward(damage_target.get("local_position", local_run_avatar_position), delta)
		return
	input_state["request_repair"] = true
	action_request_cooldown = 0.45

func _apply_overboard_recovery_role(delta: float, input_state: Dictionary) -> void:
	if str(NetworkRuntime.run_state.get("phase", "running")) != "running":
		return
	if _is_local_overboard():
		var recovery_target := _get_local_recovery_target()
		if recovery_target.is_empty():
			return
		if bool(recovery_target.get("ready", false)):
			input_state["request_recover"] = true
			return
		_scripted_move_local_avatar_toward_world(recovery_target.get("world_position", local_run_avatar_world_position), delta)
		return
	var stern_edge := Vector3(0.0, 0.92, 1.98)
	_scripted_move_local_avatar_toward(stern_edge, delta)
	if bool(launch_overrides.get("autoforce_overboard", false)) and not autorun_overboard_forced and action_request_cooldown <= 0.0 and local_run_avatar_position.distance_to(stern_edge) <= 0.16:
		NetworkRuntime.request_debug_overboard()
		action_request_cooldown = 0.5
		autorun_overboard_forced = true

func _maybe_request_autobrace(input_state: Dictionary, require_launch_override: bool = false) -> void:
	if require_launch_override and not bool(launch_overrides.get("autobrace", false)):
		return
	if bool(input_state.get("request_grapple", false)) or bool(input_state.get("request_repair", false)):
		return
	if action_request_cooldown > 0.0:
		return
	if float(NetworkRuntime.boat_state.get("brace_timer", 0.0)) > 0.0:
		return
	if float(NetworkRuntime.boat_state.get("brace_cooldown", 0.0)) > 0.0:
		return
	if not _should_autobrace():
		return
	input_state["request_brace"] = true
	action_request_cooldown = 0.35

func _apply_coordinated_return_route(input_state: Dictionary) -> void:
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var extraction_position: Vector3 = NetworkRuntime.run_state.get("extraction_position", Vector3.ZERO)
	var extraction_radius: float = float(NetworkRuntime.run_state.get("extraction_radius", 3.7))
	var current_speed: float = absf(float(NetworkRuntime.boat_state.get("speed", 0.0)))

	if boat_position.x > -4.8 and boat_position.z < 17.0:
		_apply_lane_shift(-6.2, input_state)
		return
	if boat_position.z < 24.0:
		var staging_target := Vector3(-5.1, 0.0, 24.8)
		_apply_drive_to_target(staging_target, input_state, 0.5)
		if boat_position.distance_to(staging_target) < 1.6 and current_speed < 0.32:
			input_state["throttle"] = maxf(float(input_state.get("throttle", 0.0)), 0.18)
		return
	if boat_position.distance_to(extraction_position) <= extraction_radius + 0.6:
		_hold_position_over_target(extraction_position, NetworkRuntime.EXTRACTION_MAX_SPEED, input_state)
		return

	var final_target := Vector3(-1.9, 0.0, extraction_position.z - 0.35)
	var throttle_cap := 0.72 if boat_position.z < extraction_position.z - 4.0 else 0.46
	_apply_drive_to_target(final_target, input_state, throttle_cap)

func _apply_lane_shift(target_x: float, input_state: Dictionary) -> void:
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var lookahead_z := boat_position.z + 0.45
	_apply_drive_to_target(Vector3(target_x, 0.0, lookahead_z), input_state, 0.18)

func _apply_drive_to_target(target: Vector3, input_state: Dictionary, throttle_cap: float = 1.0) -> void:
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var rotation_y: float = float(NetworkRuntime.boat_state.get("rotation_y", 0.0))
	var current_speed: float = float(NetworkRuntime.boat_state.get("speed", 0.0))
	var to_target := target - boat_position
	var distance := to_target.length()
	var local_offset := to_target.rotated(Vector3.UP, -rotation_y)
	var steer := clampf(local_offset.x * 0.25, -1.0, 1.0)
	var throttle := 1.0
	if local_offset.z < -0.6:
		steer = 1.0 if absf(local_offset.x) < 0.18 else sign(local_offset.x)
		throttle = -0.22 if absf(current_speed) > 0.8 else 0.0
	else:
		if distance < 8.0:
			throttle = 0.58
		if distance < 3.0:
			throttle = 0.18
		if distance < 1.25:
			throttle = -0.25 if current_speed > 1.2 else 0.0
		if local_offset.z < 0.4 and absf(local_offset.x) > 0.9:
			throttle = minf(throttle, 0.2)

	input_state["steer"] = steer
	input_state["throttle"] = clampf(throttle, -0.35, throttle_cap)

func _hold_position_over_target(target: Vector3, max_speed: float, input_state: Dictionary) -> void:
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var rotation_y: float = float(NetworkRuntime.boat_state.get("rotation_y", 0.0))
	var current_speed: float = absf(float(NetworkRuntime.boat_state.get("speed", 0.0)))
	var to_target := target - boat_position
	var distance := to_target.length()
	var local_offset := to_target.rotated(Vector3.UP, -rotation_y)
	input_state["steer"] = clampf(local_offset.x * 0.18, -0.7, 0.7)

	var throttle := 0.0
	if current_speed > max_speed:
		throttle = -0.35
	elif distance > 1.5 and current_speed < max_speed * 0.6:
		throttle = 0.22
	elif distance > 0.8 and current_speed < max_speed * 0.35:
		throttle = 0.12
	input_state["throttle"] = throttle

func _find_most_damaged_runtime_block() -> Dictionary:
	var worst_block: Dictionary = {}
	var worst_ratio := 1.0
	for block_variant in Array(NetworkRuntime.boat_state.get("runtime_blocks", [])):
		var block_state: Dictionary = block_variant
		var block := _build_runtime_block_render_data(block_state)
		if block.is_empty() or bool(block.get("destroyed", false)) or bool(block.get("detached", false)):
			continue
		var max_hp := maxf(1.0, float(block.get("max_hp", 1.0)))
		var health_ratio := float(block.get("current_hp", max_hp)) / max_hp
		if health_ratio >= worst_ratio:
			continue
		worst_ratio = health_ratio
		worst_block = block.duplicate(true)
	return worst_block

func _request_station_if_needed(station_id: String, input_state: Dictionary, delta: float = 0.0) -> void:
	if _is_local_overboard():
		return
	if not _get_claimable_station_ids().has(station_id):
		return
	if station_request_cooldown > 0.0:
		return
	var current_station_id := NetworkRuntime.get_peer_station_id(_get_local_peer_id())
	if current_station_id == station_id:
		return
	if not current_station_id.is_empty() and _station_anchors_avatar(current_station_id):
		input_state["claim_station"] = "__release__"
		station_request_cooldown = 0.15
		return
	if not _is_local_near_station(station_id):
		if delta > 0.0:
			_scripted_move_local_avatar_toward(NetworkRuntime.get_station_position(station_id), delta)
		return

	var station_data: Dictionary = NetworkRuntime.station_state.get(station_id, {})
	var occupant_peer_id := int(station_data.get("occupant_peer_id", 0))
	if occupant_peer_id != 0 and occupant_peer_id != _get_local_peer_id():
		return

	input_state["claim_station"] = station_id
	_select_station(station_id)
	station_request_cooldown = 0.35

func _station_is_crewed(station_id: String) -> bool:
	var station_data: Dictionary = NetworkRuntime.station_state.get(station_id, {})
	return int(station_data.get("occupant_peer_id", 0)) != 0

func _should_autobrace() -> bool:
	if float(NetworkRuntime.boat_state.get("brace_cooldown", 0.0)) > 0.0:
		return false

	if _boat_inside_any_squall():
		return true

	var autobrace_distance: float = float(launch_overrides.get("autobrace_distance", 7.5))
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var rotation_y: float = float(NetworkRuntime.boat_state.get("rotation_y", 0.0))
	var forward := -Vector3.FORWARD.rotated(Vector3.UP, rotation_y)
	for hazard in NetworkRuntime.hazard_state:
		var hazard_data: Dictionary = hazard
		var hazard_position: Vector3 = hazard_data.get("position", Vector3.ZERO)
		var offset := hazard_position - boat_position
		if offset.length() > autobrace_distance:
			continue
		if offset.dot(forward) <= 0.0:
			continue
		return true

	return false

func _update_boat_visual(delta: float) -> void:
	var server_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var target_position := server_position + Vector3(0.0, 0.34 + sin(connect_time_seconds * 1.35) * 0.08, 0.0)
	var rotation_y: float = float(NetworkRuntime.boat_state.get("rotation_y", 0.0))
	boat_root.position = boat_root.position.lerp(target_position, minf(1.0, delta * 8.0))
	boat_root.rotation.y = lerp_angle(boat_root.rotation.y, rotation_y, minf(1.0, delta * 8.0))

func _update_hazard_visuals() -> void:
	for hazard in NetworkRuntime.hazard_state:
		var hazard_data: Dictionary = hazard
		var hazard_id := int(hazard_data.get("id", 0))
		var visual: Dictionary = hazard_visuals.get(hazard_id, {})
		var hazard_node := visual.get("root") as Node3D
		if hazard_node == null:
			continue

		var base_position: Vector3 = hazard_data.get("position", Vector3.ZERO)
		var bob_height := sin(connect_time_seconds * 1.45 + float(hazard_id)) * 0.18
		hazard_node.position = base_position + Vector3(0.0, 0.55 + bob_height, 0.0)

func _update_loot_visuals() -> void:
	for loot_target in NetworkRuntime.loot_state:
		var loot_data: Dictionary = loot_target
		var loot_id := int(loot_data.get("id", 0))
		var visual: Dictionary = loot_visuals.get(loot_id, {})
		var loot_node := visual.get("root") as Node3D
		if loot_node == null:
			continue

		var base_position: Vector3 = loot_data.get("position", Vector3.ZERO)
		var bob_height := sin(connect_time_seconds * 1.8 + float(loot_id)) * 0.16
		loot_node.position = base_position + Vector3(0.0, 0.55 + bob_height, 0.0)

func _update_wreck_visual() -> void:
	if wreck_root == null:
		return

	var wreck_position: Vector3 = NetworkRuntime.run_state.get("wreck_position", Vector3.ZERO)
	wreck_root.position = wreck_position + Vector3(0.0, sin(connect_time_seconds * 0.72) * 0.06, 0.0)

func _update_rescue_visual() -> void:
	if rescue_root == null or not rescue_root.visible:
		return

	var rescue_position: Vector3 = NetworkRuntime.run_state.get("rescue_position", Vector3.ZERO)
	rescue_root.position = rescue_position + Vector3(0.0, sin(connect_time_seconds * 1.18) * 0.08, 0.0)
	if rescue_label != null:
		rescue_label.visible = true
	var rescue_light := rescue_root.get_node_or_null("RescueLight") as OmniLight3D
	if rescue_light != null:
		var pulse := 1.15 + maxf(0.0, sin(connect_time_seconds * 4.4)) * 0.85
		rescue_light.light_energy = pulse if bool(NetworkRuntime.run_state.get("rescue_available", false)) else 0.65

func _update_cache_visual() -> void:
	if cache_root == null:
		return

	var cache_position: Vector3 = NetworkRuntime.run_state.get("cache_position", Vector3.ZERO)
	cache_root.position = cache_position + Vector3(0.0, sin(connect_time_seconds * 1.12 + 0.5) * 0.07, 0.0)

func _update_squall_visuals() -> void:
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	for band_variant in Array(NetworkRuntime.run_state.get("squall_bands", [])):
		var band: Dictionary = band_variant
		var band_id := int(band.get("id", 0))
		var visual: Dictionary = squall_visuals.get(band_id, {})
		var root := visual.get("root") as Node3D
		if root == null:
			_refresh_squall_visuals()
			return
		var center: Vector3 = band.get("center", Vector3.ZERO)
		root.position = center + Vector3(0.0, sin(connect_time_seconds * 0.8 + float(band_id)) * 0.08, 0.0)
		var shell_material := visual.get("shell_material") as StandardMaterial3D
		var core_material := visual.get("core_material") as StandardMaterial3D
		var label := visual.get("label") as Label3D
		var inside := _position_inside_squall(boat_position, band)
		if shell_material != null:
			shell_material.albedo_color = Color(0.20, 0.37, 0.52, 0.22).lerp(Color(0.33, 0.62, 0.88, 0.34), 1.0 if inside else 0.0)
		if core_material != null:
			core_material.albedo_color = Color(0.30, 0.70, 0.96, 0.46).lerp(Color(0.92, 0.95, 1.0, 0.64), 1.0 if inside else 0.0)
		if label != null:
			label.text = "%s\nDrag x%.2f | Surge %.1f" % [
				str(band.get("label", "Squall Front")),
				float(band.get("drag_multiplier", 1.0)),
				float(band.get("pulse_damage", 0.0)),
			]
			label.modulate = Color(0.90, 0.97, 1.0) if inside else Color(0.70, 0.84, 0.96)

func _update_extraction_visual(_delta: float) -> void:
	var extraction_position: Vector3 = NetworkRuntime.run_state.get("extraction_position", Vector3.ZERO)
	extraction_root.position = extraction_position + Vector3(0.0, sin(connect_time_seconds * 0.95) * 0.08, 0.0)

func _update_camera(delta: float) -> void:
	if camera == null:
		return

	var speed_ratio := clampf(absf(float(NetworkRuntime.boat_state.get("speed", 0.0))) / NetworkRuntime.BOAT_TOP_SPEED, 0.0, 1.0)
	var pivot := _get_local_avatar_world_position() + Vector3(0.0, run_camera_look_height, 0.0)
	var global_yaw := local_avatar_facing_y if _is_local_overboard() else boat_root.rotation.y + local_avatar_facing_y
	var yaw_basis := Basis(Vector3.UP, global_yaw)
	var aim_basis := yaw_basis * Basis(Vector3.RIGHT, local_camera_pitch)
	var forward := (aim_basis * Vector3.FORWARD).normalized()
	var right := (yaw_basis * Vector3.RIGHT).normalized()
	var desired_position := pivot - forward * (run_camera_distance + speed_ratio * 1.4)
	desired_position += right * run_camera_side_offset
	desired_position += Vector3.UP * (run_camera_height - (0.4 if _is_local_overboard() else 0.0))
	desired_position += local_camera_jolt
	var look_target := pivot + forward * (run_camera_look_ahead + speed_ratio * 0.8) + local_camera_jolt * 0.42
	var blend := minf(1.0, delta * run_camera_lag)
	camera.position = camera.position.lerp(desired_position, blend)
	camera.fov = lerpf(camera.fov, 69.0 + speed_ratio * 7.0, blend)
	camera.look_at(look_target, Vector3.UP)

func _update_boat_material() -> void:
	if hull_material == null:
		return

	var hull_integrity: float = float(NetworkRuntime.boat_state.get("hull_integrity", 100.0))
	var max_hull_integrity: float = maxf(1.0, float(NetworkRuntime.boat_state.get("max_hull_integrity", 100.0)))
	var health_ratio := clampf(hull_integrity / max_hull_integrity, 0.0, 1.0)
	var damaged_color := Color(0.45, 0.14, 0.12)
	var healthy_color := Color(0.44, 0.27, 0.16)
	hull_material.albedo_color = damaged_color.lerp(healthy_color, health_ratio)

func _boat_within_extraction_zone() -> bool:
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var extraction_position: Vector3 = NetworkRuntime.run_state.get("extraction_position", Vector3.ZERO)
	var extraction_radius: float = float(NetworkRuntime.run_state.get("extraction_radius", 3.7))
	return boat_position.distance_to(extraction_position) <= extraction_radius

func _boat_inside_any_squall() -> bool:
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	for band_variant in Array(NetworkRuntime.run_state.get("squall_bands", [])):
		var band: Dictionary = band_variant
		if _position_inside_squall(boat_position, band):
			return true
	return false

func _position_inside_squall(position: Vector3, band: Dictionary) -> bool:
	var center: Vector3 = band.get("center", Vector3.ZERO)
	var half_extents: Vector3 = band.get("half_extents", Vector3.ZERO)
	return absf(position.x - center.x) <= half_extents.x and absf(position.z - center.z) <= half_extents.z

func _get_local_peer_id() -> int:
	if NetworkRuntime.multiplayer == null:
		return 0
	return NetworkRuntime.multiplayer.get_unique_id()

func _schedule_optional_quit() -> void:
	var quit_after_connect_ms := int(launch_overrides.get("quit_after_connect_ms", 0))
	if quit_after_connect_ms <= 0:
		return

	get_tree().create_timer(float(quit_after_connect_ms) / 1000.0).timeout.connect(_quit_after_connect_timer)
	print("Client auto-quit armed for %d ms after connect." % quit_after_connect_ms)

func _schedule_frame_capture() -> void:
	var capture_path := str(launch_overrides.get("capture_frame_path", ""))
	if capture_path.is_empty():
		return
	var delay_ms: int = maxi(0, int(launch_overrides.get("capture_frame_delay_ms", 0)))
	get_tree().create_timer(float(delay_ms) / 1000.0).timeout.connect(_capture_frame)

func _capture_frame() -> void:
	var capture_path := str(launch_overrides.get("capture_frame_path", ""))
	if capture_path.is_empty():
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(capture_path.get_base_dir())
	var image: Image = get_viewport().get_texture().get_image()
	var result: int = image.save_png(capture_path)
	if result == OK:
		print("Captured run frame to %s" % capture_path)
	else:
		push_warning("Failed to capture run frame to %s (error %d)." % [capture_path, result])

func _quit_after_connect_timer() -> void:
	print("Client auto-quit triggered. Final run state: %s | boat=%s" % [
		str(NetworkRuntime.run_state),
		str(NetworkRuntime.boat_state),
	])
	get_tree().quit()

func _initialize_autopilot() -> void:
	autopilot_remaining_seconds = float(int(launch_overrides.get("autodrive_ms", 0))) / 1000.0
	var autorun_role := str(launch_overrides.get("autorun_role", ""))
	if not autorun_role.is_empty():
		if autorun_role == "driver":
			_select_station("helm")
		elif _get_claimable_station_ids().has(autorun_role):
			_select_station(autorun_role)
	elif bool(launch_overrides.get("autorun_demo", false)):
		_select_station("helm")
	elif _get_claimable_station_ids().has(str(launch_overrides.get("autoclaim_station", ""))):
		_select_station(str(launch_overrides.get("autoclaim_station", "")))

func _ensure_selected_station_valid() -> void:
	var station_ids := _get_claimable_station_ids()
	if station_ids.is_empty():
		selected_station_index = 0
		return
	selected_station_index = wrapi(selected_station_index, 0, station_ids.size())

func _cycle_selected_station(direction: int) -> void:
	var station_ids := _get_claimable_station_ids()
	if station_ids.is_empty():
		return
	selected_station_index = wrapi(selected_station_index + direction, 0, station_ids.size())
	_refresh_station_visuals()
	_refresh_hud()

func _get_selected_station_id() -> String:
	var station_ids := _get_claimable_station_ids()
	if station_ids.is_empty():
		return ""
	selected_station_index = wrapi(selected_station_index, 0, station_ids.size())
	return str(station_ids[selected_station_index])

func _select_station(station_id: String) -> void:
	var station_ids := _get_claimable_station_ids()
	var station_index := station_ids.find(station_id)
	if station_index == -1:
		return
	selected_station_index = station_index
	_refresh_station_visuals()
	_refresh_hud()

func _continue_to_dock() -> void:
	if str(NetworkRuntime.run_state.get("phase", "running")) == "running":
		return
	NetworkRuntime.request_return_to_hangar()

func _exit_tree() -> void:
	_set_mouse_capture(false)

func _unhandled_input(event: InputEvent) -> void:
	var phase := str(NetworkRuntime.run_state.get("phase", "running"))
	if phase == "running":
		if event is InputEventMouseMotion and _is_mouse_captured():
			var motion_event := event as InputEventMouseMotion
			local_avatar_facing_y -= motion_event.relative.x * run_mouse_look_sensitivity
			local_camera_pitch = clampf(local_camera_pitch - motion_event.relative.y * run_mouse_look_sensitivity, _get_run_camera_pitch_min(), _get_run_camera_pitch_max())
			return
		if event is InputEventMouseButton:
			var button_event := event as InputEventMouseButton
			if button_event.pressed and button_event.button_index == MOUSE_BUTTON_LEFT and not _is_mouse_captured():
				_set_mouse_capture(true)
				return
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			_set_mouse_capture(not _is_mouse_captured())
			return
		if event is InputEventKey and event.pressed and not event.echo:
			match event.keycode:
				KEY_I:
					_toggle_inventory_panel()
					return
				KEY_1, KEY_KP_1:
					_select_run_tool(0)
					return
				KEY_2, KEY_KP_2:
					_select_run_tool(1)
					return
				KEY_3, KEY_KP_3:
					_select_run_tool(2)
					return
				KEY_4, KEY_KP_4:
					_select_run_tool(3)
					return
				KEY_5, KEY_KP_5:
					_select_run_tool(4)
					return
		return
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
		_continue_to_dock()

func _on_status_changed(_message: String) -> void:
	_refresh_hud()

func _on_session_phase_changed(phase: String) -> void:
	if phase == NetworkRuntime.SESSION_PHASE_HANGAR:
		_set_mouse_capture(false)
		get_tree().change_scene_to_file(HANGAR_SCENE)

func _on_peer_snapshot_changed(_snapshot: Dictionary) -> void:
	_refresh_crew_visuals()
	_refresh_station_visuals()
	_refresh_hud()

func _on_run_avatar_state_changed(snapshot: Dictionary) -> void:
	var local_state: Dictionary = snapshot.get(_get_local_peer_id(), {})
	if not local_state.is_empty():
		var previous_mode := local_run_avatar_mode
		local_run_avatar_mode = str(local_state.get("mode", NetworkRuntime.RUN_AVATAR_MODE_DECK))
		var target_position: Vector3 = local_state.get("deck_position", local_run_avatar_position)
		var target_world_position: Vector3 = local_state.get("world_position", _get_local_avatar_world_position())
		if local_run_avatar_position.distance_to(target_position) > 0.85:
			local_run_avatar_position = target_position
		if local_run_avatar_world_position.distance_to(target_world_position) > 0.95:
			local_run_avatar_world_position = target_world_position
		local_run_avatar_velocity = local_state.get("velocity", local_run_avatar_velocity)
		var synced_facing := float(local_state.get("facing_y", local_avatar_facing_y))
		if previous_mode != local_run_avatar_mode:
			if local_run_avatar_mode == NetworkRuntime.RUN_AVATAR_MODE_OVERBOARD:
				local_avatar_facing_y = boat_root.rotation.y + synced_facing
			elif previous_mode == NetworkRuntime.RUN_AVATAR_MODE_OVERBOARD:
				local_avatar_facing_y = synced_facing - boat_root.rotation.y
			else:
				local_avatar_facing_y = synced_facing
		else:
			local_avatar_facing_y = synced_facing
	var local_overboard := _is_local_overboard()
	if local_overboard and not last_local_overboard:
		_push_event_callout("Overboard!", HUD_TEXT_DANGER, 2.4)
	elif not local_overboard and last_local_overboard:
		_push_event_callout("Back On Deck", HUD_TEXT_SUCCESS, 2.1)
	last_local_overboard = local_overboard
	var overboard_count := 0
	for peer_id_variant in snapshot.keys():
		if str(Dictionary(snapshot.get(peer_id_variant, {})).get("mode", NetworkRuntime.RUN_AVATAR_MODE_DECK)) == NetworkRuntime.RUN_AVATAR_MODE_OVERBOARD:
			overboard_count += 1
	if overboard_count > last_hud_overboard_count:
		_push_event_callout("Crew Overboard", HUD_TEXT_WARNING, 2.0)
	last_hud_overboard_count = overboard_count
	_refresh_crew_visuals()
	_refresh_hud()

func _on_reaction_state_changed(snapshot: Dictionary) -> void:
	reaction_visual_state = snapshot.duplicate(true)
	_refresh_hud()

func _on_run_seed_changed(_seed: int) -> void:
	_refresh_world()
	_refresh_hud()

func _on_helm_changed(_driver_peer_id: int) -> void:
	_refresh_crew_visuals()
	_refresh_hud()

func _on_boat_state_changed(_state: Dictionary) -> void:
	var collision_count := int(NetworkRuntime.boat_state.get("collision_count", 0))
	if collision_count > last_hud_collision_count:
		if bool(NetworkRuntime.boat_state.get("last_impact_braced", false)):
			_push_event_callout("Brace Held", HUD_TEXT_SUCCESS)
		else:
			_push_event_callout("Hull Slammed", HUD_TEXT_DANGER)
	last_hud_collision_count = collision_count
	_update_runtime_block_visuals()
	_update_sinking_chunk_visuals(0.0)
	_update_boat_material()
	_refresh_wreck_visual()
	_refresh_cache_visual()
	_refresh_extraction_visual()
	_refresh_hud()

func _on_hazard_state_changed(_hazards: Array) -> void:
	_refresh_hazard_visuals()
	_refresh_hud()

func _on_station_state_changed(_stations: Dictionary) -> void:
	_refresh_station_visuals()
	_refresh_crew_visuals()
	_refresh_hud()

func _on_loot_state_changed(_loot_targets: Array) -> void:
	_refresh_loot_visuals()
	_refresh_wreck_visual()
	_refresh_cache_visual()
	_refresh_extraction_visual()
	_refresh_hud()

func _on_run_state_changed(_state: Dictionary) -> void:
	var phase := str(NetworkRuntime.run_state.get("phase", "running"))
	var detached_chunk_count := int(NetworkRuntime.run_state.get("detached_chunk_count", 0))
	var cargo_lost_to_sea := int(NetworkRuntime.run_state.get("cargo_lost_to_sea", 0))
	var rescue_completed := bool(NetworkRuntime.run_state.get("rescue_completed", false))
	var cache_recovered := bool(NetworkRuntime.run_state.get("cache_recovered", false))
	if detached_chunk_count > last_hud_detached_chunk_count:
		_push_event_callout("Chunk Lost", HUD_TEXT_DANGER)
	if cargo_lost_to_sea > last_hud_cargo_lost_to_sea:
		_push_event_callout("Cargo Washed Overboard", HUD_TEXT_WARNING)
	if rescue_completed and not last_hud_rescue_completed:
		_push_event_callout("Rescue Secured", HUD_TEXT_SUCCESS)
	if cache_recovered and not last_hud_cache_recovered:
		_push_event_callout("Cache Secured", HUD_TEXT_WARNING)
	if phase == "running":
		run_result_recorded = false
		auto_continue_queued = false
	if phase != last_known_phase:
		print("Run phase changed: %s" % phase)
		last_known_phase = phase
	if phase == "success" and last_hud_phase != "success":
		_push_event_callout("Extraction Secured", HUD_TEXT_SUCCESS, 2.3)
	elif phase == "failed" and last_hud_phase != "failed":
		_push_event_callout("Boat Sunk", HUD_TEXT_DANGER, 2.4)
	if phase != "running" and not run_result_recorded:
		run_result_recorded = true
	if phase != "running" and bool(launch_overrides.get("autocontinue_to_dock", false)) and not auto_continue_queued:
		auto_continue_queued = true
		get_tree().create_timer(0.5).timeout.connect(_continue_to_dock)
	last_hud_detached_chunk_count = detached_chunk_count
	last_hud_cargo_lost_to_sea = cargo_lost_to_sea
	last_hud_rescue_completed = rescue_completed
	last_hud_cache_recovered = cache_recovered
	last_hud_phase = phase
	_refresh_wreck_visual()
	_refresh_rescue_visual()
	_refresh_cache_visual()
	_refresh_squall_visuals()
	_refresh_extraction_visual()
	_refresh_result_overlay()
	_refresh_hud()

func _on_progression_state_changed(_snapshot: Dictionary) -> void:
	_refresh_hud()

func _get_progression_snapshot() -> Dictionary:
	var snapshot := NetworkRuntime.get_progression_state()
	if snapshot.is_empty():
		return DockState.get_profile_snapshot()
	return snapshot

func _build_objective_text() -> String:
	var phase := str(NetworkRuntime.run_state.get("phase", "running"))
	if phase == "success":
		return "Objective: Return to the hangar and bank the haul."
	if phase == "failed":
		return "Objective: Return to the hangar and review the loss."
	if _is_local_overboard():
		return "Objective: Swim to a ladder or stern line and press F to climb back aboard."

	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var boat_speed: float = absf(float(NetworkRuntime.boat_state.get("speed", 0.0)))
	var loot_remaining := int(NetworkRuntime.run_state.get("loot_remaining", 0))
	var wreck_position: Vector3 = NetworkRuntime.run_state.get("wreck_position", Vector3.ZERO)
	var wreck_radius: float = float(NetworkRuntime.run_state.get("wreck_radius", 4.1))
	var rescue_available := bool(NetworkRuntime.run_state.get("rescue_available", false))
	var rescue_engaged := bool(NetworkRuntime.run_state.get("rescue_engaged", false))
	var rescue_position: Vector3 = NetworkRuntime.run_state.get("rescue_position", Vector3.ZERO)
	var rescue_radius: float = float(NetworkRuntime.run_state.get("rescue_radius", 3.4))
	if loot_remaining > 0:
		if boat_position.distance_to(wreck_position) > wreck_radius:
			return "Objective: Bring the boat into the wreck ring."
		if boat_speed > float(NetworkRuntime.run_state.get("salvage_max_speed", NetworkRuntime.SALVAGE_MAX_SPEED)):
			return "Objective: Hold below salvage speed."
		return "Objective: Brace anywhere on deck and let the grappler recover the remaining wreck loot."

	if rescue_available:
		if boat_position.distance_to(rescue_position) > rescue_radius:
			return "Objective: Distress signal spotted. Divert if the crew wants the bonus."
		if boat_speed > float(NetworkRuntime.run_state.get("rescue_max_speed", NetworkRuntime.RESCUE_MAX_SPEED)):
			return "Objective: Slow down inside the rescue ring."
		if rescue_engaged:
			return "Objective: Hold steady until the rescue package is secured."
		return "Objective: Let the grappler recover the rescue package."

	if bool(NetworkRuntime.run_state.get("cache_available", false)):
		return "Objective: Pass through the cache lane for a quick bonus."

	if int(NetworkRuntime.run_state.get("cargo_count", 0)) > 0:
		if not _boat_within_extraction_zone():
			return "Objective: Bring the boat into the extraction ring."
		if boat_speed > NetworkRuntime.EXTRACTION_MAX_SPEED:
			return "Objective: Bleed speed and hold steady."
		return "Objective: Stay calm until extraction completes."

	return "Objective: Claim stations and prepare the shared boat."

func _build_onboarding_text(selected_station_id: String, local_station_id: String) -> String:
	var phase := str(NetworkRuntime.run_state.get("phase", "running"))
	if phase == "success":
		return "Onboarding: Press Enter or Continue to return to the hangar and spend the rewards."
	if phase == "failed":
		return "Onboarding: Failed runs lose unbanked cargo. Rebuild and try a safer route."
	if _is_local_overboard():
		return "Onboarding: You went overboard. Swim to the nearest ladder marker, then press F to climb back onto the boat."

	if local_station_id.is_empty():
		var selected_label := "a station"
		if not selected_station_id.is_empty():
			selected_label = NetworkRuntime.get_station_label(selected_station_id)
		return "Onboarding: Mouse aim drives the camera. Walk the deck, then use Q/E and F to take %s. Space works anywhere." % selected_label

	if _boat_inside_any_squall():
		return "Onboarding: Squalls drag the boat and fire surge pulses. Keep speed under control and brace through the slam."

	if int(NetworkRuntime.run_state.get("loot_remaining", 0)) > 0:
		return "Onboarding: Get inside the wreck ring, slow down, brace from anywhere, and keep the grappler safe."

	var repair_target := _find_local_repair_target()
	if not repair_target.is_empty():
		return "Onboarding: You are close enough to patch the damaged hull here. Press R if the kit spend is worth it."

	if bool(NetworkRuntime.run_state.get("rescue_available", false)):
		return "Onboarding: Distress rescues are optional. Hold inside the ring long enough to secure the bonus."

	if bool(NetworkRuntime.run_state.get("cache_available", false)):
		return "Onboarding: The resupply cache is a quick bonus stop if the route still looks safe."

	if int(NetworkRuntime.run_state.get("cargo_count", 0)) > 0:
		return "Onboarding: Everything aboard is lost if the boat sinks before extraction. Cash out once risk climbs."

	return "Onboarding: Stay near the helm to steer, or roam the deck and support the crew where it hurts."
