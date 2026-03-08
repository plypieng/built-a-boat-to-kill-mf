extends Node3D

const CLIENT_BOOT_SCENE := "res://scenes/boot/client_boot.tscn"
const RUN_CLIENT_SCENE := "res://scenes/run_client/run_client.tscn"
const HudIconLibrary = preload("res://scenes/shared/hud_icon_library.gd")
const BLOCK_CELL_SIZE := 1.25
const CURSOR_OK_COLOR := Color(0.34, 0.82, 0.58, 0.55)
const CURSOR_OCCUPIED_COLOR := Color(0.92, 0.57, 0.22, 0.58)
const CURSOR_RANGE_COLOR := Color(0.23, 0.63, 0.90, 0.58)
const CURSOR_BLOCKED_COLOR := Color(0.88, 0.32, 0.24, 0.6)
const MAIN_CHUNK_TINT := Color(0.08, 0.08, 0.08)
const LOOSE_CHUNK_TINT := Color(0.25, 0.02, 0.02)
const REMOTE_AVATAR_COLORS := [
	Color(0.64, 0.82, 0.98),
	Color(0.92, 0.64, 0.41),
	Color(0.69, 0.90, 0.62),
	Color(0.94, 0.55, 0.74),
]
const HANGAR_MOVE_SPEED := 6.2
const HANGAR_ACCELERATION := 20.0
const HANGAR_AIR_ACCELERATION := 10.0
const HANGAR_JUMP_VELOCITY := 6.2
const HANGAR_AVATAR_SYNC_INTERVAL := 0.05
const HANGAR_AVATAR_NAME_HEIGHT := 1.4

@export_group("Chase Camera")
@export_range(-4.0, 4.0, 0.05) var chase_camera_side_offset := 0.9
@export_range(0.5, 6.0, 0.05) var chase_camera_height := 2.45
@export_range(1.0, 14.0, 0.05) var chase_camera_distance := 6.4
@export_range(0.5, 4.0, 0.05) var chase_camera_look_height := 1.38
@export_range(0.0, 6.0, 0.05) var chase_camera_look_ahead := 1.9
@export_range(0.1, 20.0, 0.1) var chase_camera_lag := 8.2
@export_group("Look Control")
@export_range(0.0005, 0.02, 0.0005) var mouse_look_sensitivity := 0.0035
@export_range(-80.0, 80.0, 0.5) var chase_camera_pitch_min_degrees := -58.0
@export_range(-80.0, 80.0, 0.5) var chase_camera_pitch_max_degrees := 44.0
@export_range(-45.0, 45.0, 0.5) var chase_camera_pitch_default_degrees := -12.0

var launch_overrides: Dictionary = {}
var connect_time_seconds := 0.0
var status_label: Label
var onboarding_label: Label
var selection_label: Label
var target_label: Label
var launch_readiness_label: Label
var builder_label: Label
var warning_label: Label
var roster_label: Label
var profile_label: Label
var store_label: Label
var controls_label: Label
var last_run_label: Label
var toolbelt_label: Label
var inventory_label: Label
var launch_button: Button
var unlock_button: Button
var detail_toggle_button: Button
var crosshair_label: Label
var detail_panel: PanelContainer
var tool_panel: PanelContainer
var inventory_panel: PanelContainer
var dock_body: StaticBody3D
var boat_root: Node3D
var block_container: Node3D
var avatar_container: Node3D
var cursor_root: Node3D
var cursor_mesh: MeshInstance3D
var cursor_label: Label3D
var block_visuals: Dictionary = {}
var camera: Camera3D
var local_avatar_body: CharacterBody3D
var remote_avatar_visuals: Dictionary = {}
var local_avatar_facing_y := PI
var local_camera_pitch := 0.0
var avatar_sync_timer := 0.0
var selected_block_index := 0
var selected_rotation_steps := 0
var cursor_cell := Vector3i.ZERO
var remove_cursor_cell := Vector3i.ZERO
var cursor_has_target := false
var cursor_can_place := false
var cursor_can_remove := false
var cursor_feedback_state := "hidden"
var cursor_target_label := "Aim at the boat or dock"
var autobuild_actions: Array = []
var autobuild_pending_action: Dictionary = {}
var autobuild_index := 0
var autobuild_timer := 0.0
var reaction_visual_state: Dictionary = {}
var local_reaction_impulse := Vector3.ZERO
var local_camera_jolt := Vector3.ZERO
var last_local_reaction_id := 0
var selected_store_index := 0
var hud_details_visible := false
var inventory_panel_visible := false
var selected_hangar_tool_index := 0
var hud_icons := HudIconLibrary.new()
var selection_icon: TextureRect
var launch_readiness_icon: TextureRect
var profile_icon: TextureRect
var store_icon: TextureRect
var builder_icon: TextureRect
var last_run_icon: TextureRect

func _ready() -> void:
	launch_overrides = GameConfig.parse_cmdline_overrides()
	local_camera_pitch = deg_to_rad(chase_camera_pitch_default_degrees)
	_build_world()
	_build_hud()
	_set_mouse_capture(true)
	_refresh_all()
	_schedule_frame_capture()
	_schedule_optional_quit()
	_initialize_autobuild()

	NetworkRuntime.status_changed.connect(_on_status_changed)
	NetworkRuntime.peer_snapshot_changed.connect(_on_peer_snapshot_changed)
	NetworkRuntime.hangar_avatar_state_changed.connect(_on_hangar_avatar_state_changed)
	NetworkRuntime.reaction_state_changed.connect(_on_reaction_state_changed)
	NetworkRuntime.boat_blueprint_changed.connect(_on_boat_blueprint_changed)
	NetworkRuntime.progression_state_changed.connect(_on_progression_state_changed)
	NetworkRuntime.session_phase_changed.connect(_on_session_phase_changed)
	DockState.profile_changed.connect(_on_profile_changed)
	reaction_visual_state = NetworkRuntime.get_reaction_state()
	if NetworkRuntime.get_session_phase() == NetworkRuntime.SESSION_PHASE_RUN:
		_set_mouse_capture(false)
		get_tree().call_deferred("change_scene_to_file", RUN_CLIENT_SCENE)
		return
	print("Hangar builder ready: version=%d blocks=%d phase=%s" % [
		int(NetworkRuntime.boat_blueprint.get("version", 1)),
		Array(NetworkRuntime.boat_blueprint.get("blocks", [])).size(),
		NetworkRuntime.get_session_phase(),
	])

func _process(delta: float) -> void:
	connect_time_seconds += delta
	_tick_reaction_visuals(delta)
	_update_boat_bob()
	_update_camera(delta)
	_update_remote_avatar_visuals(delta)
	_update_build_target_from_camera()
	_process_autobuild(delta)

func _physics_process(delta: float) -> void:
	_process_local_avatar_movement(delta)
	_sync_local_avatar_state(delta)

func _unhandled_input(event: InputEvent) -> void:
	if NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR:
		return
	if event is InputEventMouseMotion and _is_mouse_captured():
		var motion_event := event as InputEventMouseMotion
		local_avatar_facing_y -= motion_event.relative.x * mouse_look_sensitivity
		local_camera_pitch = clampf(
			local_camera_pitch - motion_event.relative.y * mouse_look_sensitivity,
			deg_to_rad(chase_camera_pitch_min_degrees),
			deg_to_rad(chase_camera_pitch_max_degrees)
		)
		return
	if event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		if button_event.pressed and button_event.button_index == MOUSE_BUTTON_RIGHT and not _is_mouse_captured():
			_set_mouse_capture(true)
			return
	if not (event is InputEventKey):
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_TAB, KEY_H:
			_toggle_hud_details()
		KEY_I:
			_toggle_inventory_panel()
		KEY_1, KEY_KP_1:
			_select_hangar_tool(0)
		KEY_2, KEY_KP_2:
			_select_hangar_tool(1)
		KEY_3, KEY_KP_3:
			_select_hangar_tool(2)
		KEY_Q:
			_cycle_block(-1)
		KEY_E:
			_cycle_block(1)
		KEY_Z:
			_cycle_store_selection(-1)
		KEY_C:
			_cycle_store_selection(1)
		KEY_V:
			_purchase_selected_unlock()
		KEY_R:
			_rotate_selected_block()
		KEY_F:
			_use_active_hangar_tool()
		KEY_X, KEY_BACKSPACE, KEY_DELETE:
			_remove_selected_block()
		KEY_ENTER, KEY_KP_ENTER:
			_launch_run()
		KEY_ESCAPE:
			_set_mouse_capture(not _is_mouse_captured())

func _build_world() -> void:
	_ensure_world_environment()

	dock_body = get_node_or_null("Environment/DockBody") as StaticBody3D
	if dock_body == null:
		_build_static_world_fallback()
	if dock_body != null:
		dock_body.set_meta("builder_surface", "dock")

	boat_root = get_node_or_null("BoatRoot") as Node3D
	if boat_root == null:
		boat_root = Node3D.new()
		boat_root.name = "BoatRoot"
		boat_root.position = Vector3(0.0, 0.1, 0.0)
		add_child(boat_root)

	block_container = get_node_or_null("BoatRoot/BlockContainer") as Node3D
	if block_container == null:
		block_container = Node3D.new()
		block_container.name = "BlockContainer"
		boat_root.add_child(block_container)

	avatar_container = get_node_or_null("AvatarContainer") as Node3D
	if avatar_container == null:
		avatar_container = Node3D.new()
		avatar_container.name = "AvatarContainer"
		add_child(avatar_container)
	_build_local_avatar()

	cursor_root = get_node_or_null("BoatRoot/CursorRoot") as Node3D
	if cursor_root == null:
		cursor_root = Node3D.new()
		cursor_root.name = "CursorRoot"
		boat_root.add_child(cursor_root)
	_build_cursor_visual()
	_build_build_volume()

	camera = get_node_or_null("HangarCamera") as Camera3D
	if camera == null:
		camera = Camera3D.new()
		camera.name = "HangarCamera"
		add_child(camera)
	camera.position = Vector3(0.0, chase_camera_height + 2.0, chase_camera_distance)
	camera.current = true
	camera.make_current()
	camera.look_at(Vector3(0.0, 1.4, 0.0), Vector3.UP)

func _supports_mouse_capture() -> bool:
	return DisplayServer.get_name() != "headless"

func _is_mouse_captured() -> bool:
	return _supports_mouse_capture() and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED

func _set_mouse_capture(captured: bool) -> void:
	if not _supports_mouse_capture():
		return
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE)

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
	environment.background_color = Color(0.58, 0.72, 0.84)
	return environment

func _build_static_world_fallback() -> void:
	var fallback_root := get_node_or_null("EnvironmentFallback") as Node3D
	if fallback_root == null:
		fallback_root = Node3D.new()
		fallback_root.name = "EnvironmentFallback"
		add_child(fallback_root)

	var light := DirectionalLight3D.new()
	light.name = "SunLight"
	light.light_energy = 1.18
	light.rotation_degrees = Vector3(-42.0, 32.0, 0.0)
	fallback_root.add_child(light)

	var dock := MeshInstance3D.new()
	dock.name = "DockVisual"
	var dock_mesh := BoxMesh.new()
	dock_mesh.size = Vector3(24.0, 0.6, 30.0)
	dock.mesh = dock_mesh
	dock.position = Vector3(0.0, -0.35, 0.0)
	var dock_material := StandardMaterial3D.new()
	dock_material.albedo_color = Color(0.65, 0.56, 0.42)
	dock_material.roughness = 0.9
	dock.material_override = dock_material
	fallback_root.add_child(dock)

	dock_body = StaticBody3D.new()
	dock_body.name = "DockBody"
	dock_body.position = dock.position
	var dock_collider := CollisionShape3D.new()
	var dock_shape := BoxShape3D.new()
	dock_shape.size = dock_mesh.size
	dock_collider.shape = dock_shape
	dock_body.add_child(dock_collider)
	fallback_root.add_child(dock_body)

	var water := MeshInstance3D.new()
	water.name = "Water"
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(180.0, 180.0)
	water.mesh = water_mesh
	water.position = Vector3(0.0, -0.68, 0.0)
	var water_material := StandardMaterial3D.new()
	water_material.albedo_color = Color(0.09, 0.39, 0.57)
	water_material.roughness = 0.18
	water.material_override = water_material
	fallback_root.add_child(water)

	_build_hangar_props(fallback_root)

func _build_hangar_props(parent: Node3D) -> void:
	var bollard_positions := [
		Vector3(-8.0, 0.12, 8.6),
		Vector3(8.0, 0.12, 8.6),
		Vector3(-8.0, 0.12, -7.6),
		Vector3(8.0, 0.12, -7.6),
	]
	for position in bollard_positions:
		var bollard := MeshInstance3D.new()
		var bollard_mesh := CylinderMesh.new()
		bollard_mesh.top_radius = 0.18
		bollard_mesh.bottom_radius = 0.22
		bollard_mesh.height = 0.95
		bollard.mesh = bollard_mesh
		bollard.position = position
		var bollard_material := StandardMaterial3D.new()
		bollard_material.albedo_color = Color(0.18, 0.22, 0.27)
		bollard_material.roughness = 0.9
		bollard.material_override = bollard_material
		parent.add_child(bollard)

	var crate_positions := [
		Vector3(-6.2, 0.18, 4.6),
		Vector3(-5.4, 0.68, 4.3),
		Vector3(6.0, 0.18, 4.9),
		Vector3(5.1, 0.68, 4.2),
	]
	for position in crate_positions:
		var crate := MeshInstance3D.new()
		var crate_mesh := BoxMesh.new()
		crate_mesh.size = Vector3(0.92, 0.72, 0.92)
		crate.mesh = crate_mesh
		crate.position = position
		var crate_material := StandardMaterial3D.new()
		crate_material.albedo_color = Color(0.74, 0.55, 0.31)
		crate_material.roughness = 0.88
		crate.material_override = crate_material
		parent.add_child(crate)

	var light_positions := [
		Vector3(-4.6, 2.8, 8.1),
		Vector3(4.6, 2.8, 8.1),
	]
	for position in light_positions:
		var lamp := OmniLight3D.new()
		lamp.position = position
		lamp.light_energy = 0.85
		lamp.light_color = Color(1.0, 0.88, 0.64)
		lamp.omni_range = 12.0
		parent.add_child(lamp)

func _build_local_avatar() -> void:
	local_avatar_body = CharacterBody3D.new()
	local_avatar_body.name = "LocalAvatar"
	avatar_container.add_child(local_avatar_body)

	var collision_shape := CollisionShape3D.new()
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.radius = 0.34
	capsule_shape.height = 1.08
	collision_shape.shape = capsule_shape
	collision_shape.position = Vector3(0.0, 0.9, 0.0)
	local_avatar_body.add_child(collision_shape)

	var visual_root := _create_avatar_visual("You", Color(0.32, 0.84, 0.56), true)
	local_avatar_body.add_child(visual_root)

	var local_state: Dictionary = NetworkRuntime.get_hangar_avatar_state().get(_get_local_peer_id(), {})
	if not local_state.is_empty():
		local_avatar_body.global_position = local_state.get("position", Vector3.ZERO)
		local_avatar_facing_y = float(local_state.get("facing_y", PI))
	else:
		local_avatar_body.global_position = Vector3(0.0, 0.55, 6.6)
		local_avatar_facing_y = 0.0
	_apply_autohangar_spawn_override()
	local_avatar_body.rotation.y = local_avatar_facing_y
	_send_local_hangar_presence(local_avatar_body.global_position, Vector3.ZERO, true)

func _create_avatar_visual(display_name: String, body_color: Color, is_local: bool) -> Node3D:
	var root := Node3D.new()
	root.name = "AvatarVisual"

	var foot_ring := MeshInstance3D.new()
	foot_ring.name = "FootRing"
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = 0.38
	ring_mesh.bottom_radius = 0.42
	ring_mesh.height = 0.05
	foot_ring.mesh = ring_mesh
	foot_ring.position = Vector3(0.0, 0.05, 0.0)
	var ring_material := StandardMaterial3D.new()
	ring_material.albedo_color = body_color.lightened(0.16)
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.roughness = 0.18
	foot_ring.material_override = ring_material
	root.add_child(foot_ring)

	var body := MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.height = 1.2
	capsule_mesh.radius = 0.28
	body.mesh = capsule_mesh
	body.position = Vector3(0.0, 0.9, 0.0)
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = body_color
	body_material.roughness = 0.72
	body.material_override = body_material
	root.add_child(body)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.44
	head.mesh = head_mesh
	head.position = Vector3(0.0, 1.6, 0.0)
	var head_material := StandardMaterial3D.new()
	head_material.albedo_color = Color(0.97, 0.90, 0.79) if is_local else Color(0.88, 0.91, 0.96)
	head.material_override = head_material
	root.add_child(head)

	var tool := MeshInstance3D.new()
	tool.name = "Tool"
	var tool_mesh := BoxMesh.new()
	tool_mesh.size = Vector3(0.18, 0.18, 0.85)
	tool.mesh = tool_mesh
	tool.position = Vector3(0.34, 1.08, -0.18)
	tool.rotation_degrees = Vector3(0.0, 18.0, -18.0)
	var tool_material := StandardMaterial3D.new()
	tool_material.albedo_color = body_color.lightened(0.28)
	tool_material.roughness = 0.28
	tool.material_override = tool_material
	root.add_child(tool)

	var label := Label3D.new()
	label.name = "Nameplate"
	label.text = display_name
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 15 if not is_local else 16
	label.position = Vector3(0.0, HANGAR_AVATAR_NAME_HEIGHT + 0.62, 0.0)
	label.outline_size = 8
	label.modulate = body_color.lightened(0.35) if not is_local else Color(0.96, 0.99, 0.96)
	root.add_child(label)

	return root

func _create_remote_presence_entry(peer_id: int, display_name: String, body_color: Color) -> Dictionary:
	var avatar_root := Node3D.new()
	avatar_root.name = "RemoteAvatar%d" % peer_id
	avatar_root.add_child(_create_avatar_visual(display_name, body_color, false))
	avatar_container.add_child(avatar_root)

	var ghost_root := Node3D.new()
	ghost_root.name = "RemoteGhost%d" % peer_id
	ghost_root.visible = false
	boat_root.add_child(ghost_root)

	var ghost_mesh := MeshInstance3D.new()
	ghost_mesh.name = "GhostMesh"
	var ghost_box := BoxMesh.new()
	ghost_box.size = Vector3.ONE * BLOCK_CELL_SIZE
	ghost_mesh.mesh = ghost_box
	ghost_root.add_child(ghost_mesh)

	var ring_mesh := MeshInstance3D.new()
	ring_mesh.name = "GhostRing"
	var ring_shape := CylinderMesh.new()
	ring_shape.top_radius = 0.52 * BLOCK_CELL_SIZE
	ring_shape.bottom_radius = 0.58 * BLOCK_CELL_SIZE
	ring_shape.height = 0.05
	ring_mesh.mesh = ring_shape
	ghost_root.add_child(ring_mesh)

	return {
		"avatar_root": avatar_root,
		"ghost_root": ghost_root,
		"ghost_mesh": ghost_mesh,
		"ghost_ring": ring_mesh,
	}

func _build_cursor_visual() -> void:
	cursor_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.1, 1.1, 1.1) * BLOCK_CELL_SIZE
	cursor_mesh.mesh = box
	cursor_root.add_child(cursor_mesh)

	cursor_label = Label3D.new()
	cursor_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	cursor_label.font_size = 15
	cursor_label.position = Vector3(0.0, 1.1 * BLOCK_CELL_SIZE, 0.0)
	cursor_label.outline_size = 8
	cursor_root.add_child(cursor_label)

func _build_local_hangar_presence_snapshot() -> Dictionary:
	return {
		"selected_block_id": _get_selected_block_id(),
		"rotation_steps": selected_rotation_steps,
		"target_cell": [cursor_cell.x, cursor_cell.y, cursor_cell.z],
		"remove_cell": [remove_cursor_cell.x, remove_cursor_cell.y, remove_cursor_cell.z],
		"has_target": cursor_has_target,
		"target_feedback_state": cursor_feedback_state,
	}

func _send_local_hangar_presence(position: Vector3, velocity: Vector3, grounded: bool) -> void:
	var snapshot := _build_local_hangar_presence_snapshot()
	NetworkRuntime.send_local_hangar_avatar_presence(
		position,
		velocity,
		local_avatar_facing_y,
		grounded,
		str(snapshot.get("selected_block_id", "structure")),
		int(snapshot.get("rotation_steps", 0)),
		snapshot.get("target_cell", [0, 0, 0]),
		snapshot.get("remove_cell", [0, 0, 0]),
		bool(snapshot.get("has_target", false)),
		str(snapshot.get("target_feedback_state", "hidden"))
	)

func _build_build_volume() -> void:
	var bounds_min := NetworkRuntime.get_builder_bounds_min()
	var bounds_max := NetworkRuntime.get_builder_bounds_max()
	var center := Vector3(
		float(bounds_min.x + bounds_max.x) * 0.5,
		float(bounds_min.y + bounds_max.y) * 0.5,
		float(bounds_min.z + bounds_max.z) * 0.5
	) * BLOCK_CELL_SIZE
	var size := Vector3(
		float(bounds_max.x - bounds_min.x + 1),
		float(bounds_max.y - bounds_min.y + 1),
		float(bounds_max.z - bounds_min.z + 1)
	) * BLOCK_CELL_SIZE

	var frame := MeshInstance3D.new()
	var frame_mesh := BoxMesh.new()
	frame_mesh.size = size + Vector3(BLOCK_CELL_SIZE * 0.18, BLOCK_CELL_SIZE * 0.18, BLOCK_CELL_SIZE * 0.18)
	frame.mesh = frame_mesh
	frame.position = center + Vector3(0.0, BLOCK_CELL_SIZE * 0.5, 0.0)
	var frame_material := StandardMaterial3D.new()
	frame_material.albedo_color = Color(0.16, 0.22, 0.29, 0.12)
	frame_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	frame.material_override = frame_material
	boat_root.add_child(frame)

func _build_hud() -> void:
	var hud := get_node("HUD") as CanvasLayer
	onboarding_label = hud.get_node("LeftPanel/Margin/Layout/OnboardingLabel") as Label
	selection_icon = hud.get_node("LeftPanel/Margin/Layout/SelectionHeader/SelectionIcon") as TextureRect
	selection_label = hud.get_node("LeftPanel/Margin/Layout/SelectionLabel") as Label
	target_label = hud.get_node("LeftPanel/Margin/Layout/TargetLabel") as Label
	launch_readiness_icon = hud.get_node("LeftPanel/Margin/Layout/LaunchReadinessHeader/LaunchReadinessIcon") as TextureRect
	launch_readiness_label = hud.get_node("LeftPanel/Margin/Layout/LaunchReadinessLabel") as Label
	status_label = hud.get_node("LeftPanel/Margin/Layout/StatusLabel") as Label
	launch_button = hud.get_node("LeftPanel/Margin/Layout/Actions/LaunchButton") as Button
	var reconnect_button := hud.get_node("LeftPanel/Margin/Layout/Actions/ReturnToConnectButton") as Button
	var quit_button := hud.get_node("LeftPanel/Margin/Layout/Actions/QuitButton") as Button
	profile_icon = hud.get_node("RightPanel/Margin/Layout/ProfileHeader/ProfileIcon") as TextureRect
	profile_label = hud.get_node("RightPanel/Margin/Layout/ProfileLabel") as Label
	store_icon = hud.get_node("RightPanel/Margin/Layout/StoreHeader/StoreIcon") as TextureRect
	store_label = hud.get_node("RightPanel/Margin/Layout/StoreLabel") as Label
	unlock_button = hud.get_node("RightPanel/Margin/Layout/UnlockButton") as Button
	detail_toggle_button = hud.get_node("RightPanel/Margin/Layout/DetailToggleButton") as Button
	roster_label = hud.get_node("BottomLeftPanel/Margin/Layout/RosterLabel") as Label
	controls_label = hud.get_node("BottomLeftPanel/Margin/Layout/ControlsLabel") as Label
	tool_panel = hud.get_node("ToolPanel") as PanelContainer
	toolbelt_label = hud.get_node("ToolPanel/Margin/Layout/ToolLabel") as Label
	inventory_panel = hud.get_node("InventoryPanel") as PanelContainer
	inventory_label = hud.get_node("InventoryPanel/Margin/Layout/InventoryLabel") as Label
	detail_panel = hud.get_node("DetailPanel") as PanelContainer
	builder_icon = hud.get_node("DetailPanel/Margin/Layout/BuilderHeader/BuilderIcon") as TextureRect
	builder_label = hud.get_node("DetailPanel/Margin/Layout/BuilderLabel") as Label
	warning_label = hud.get_node("DetailPanel/Margin/Layout/WarningLabel") as Label
	last_run_icon = hud.get_node("DetailPanel/Margin/Layout/LastRunHeader/LastRunIcon") as TextureRect
	last_run_label = hud.get_node("DetailPanel/Margin/Layout/LastRunLabel") as Label
	crosshair_label = hud.get_node("CrosshairLabel") as Label

	for icon in [
		selection_icon,
		launch_readiness_icon,
		profile_icon,
		store_icon,
		builder_icon,
		last_run_icon,
	]:
		hud_icons.configure_icon_rect(icon)

	if not launch_button.pressed.is_connected(_launch_run):
		launch_button.pressed.connect(_launch_run)
	if not reconnect_button.pressed.is_connected(_return_to_connect):
		reconnect_button.pressed.connect(_return_to_connect)
	if not quit_button.pressed.is_connected(_quit):
		quit_button.pressed.connect(_quit)
	if not unlock_button.pressed.is_connected(_purchase_selected_unlock):
		unlock_button.pressed.connect(_purchase_selected_unlock)
	if not detail_toggle_button.pressed.is_connected(_toggle_hud_details):
		detail_toggle_button.pressed.connect(_toggle_hud_details)

	_apply_hud_visibility()

func _refresh_all() -> void:
	_refresh_blueprint_visuals()
	_update_build_target_from_camera()
	_refresh_hangar_avatar_visuals()
	_refresh_hud()

func _refresh_blueprint_visuals() -> void:
	for child in block_container.get_children():
		child.queue_free()
	block_visuals.clear()

	var loose_ids := Array(NetworkRuntime.boat_blueprint.get("loose_block_ids", []))
	for block_variant in Array(NetworkRuntime.boat_blueprint.get("blocks", [])):
		var block: Dictionary = block_variant
		var block_type := str(block.get("type", "structure"))
		var block_def := NetworkRuntime.get_builder_block_definition(block_type)
		var block_node := Node3D.new()
		block_node.position = _cell_to_local_position(block.get("cell", [0, 0, 0]))
		block_node.rotation_degrees.y = float(int(block.get("rotation_steps", 0)) * 90)
		block_container.add_child(block_node)

		var mesh_instance := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		var block_size: Vector3 = block_def.get("size", Vector3.ONE)
		mesh.size = block_size * BLOCK_CELL_SIZE
		mesh_instance.mesh = mesh
		var material := StandardMaterial3D.new()
		var base_color: Color = block_def.get("color", Color(0.7, 0.7, 0.7))
		if loose_ids.has(int(block.get("id", 0))):
			base_color = base_color.darkened(0.16).lerp(LOOSE_CHUNK_TINT, 0.28)
		else:
			base_color = base_color.lerp(MAIN_CHUNK_TINT, 0.08)
		material.albedo_color = base_color
		material.roughness = 0.42
		mesh_instance.material_override = material
		block_node.add_child(mesh_instance)

		var facing_marker := MeshInstance3D.new()
		var marker_mesh := BoxMesh.new()
		marker_mesh.size = Vector3(0.28, 0.18, 0.38) * BLOCK_CELL_SIZE
		facing_marker.mesh = marker_mesh
		facing_marker.position = Vector3(0.0, 0.0, -0.42 * BLOCK_CELL_SIZE)
		var marker_material := StandardMaterial3D.new()
		marker_material.albedo_color = base_color.lightened(0.28)
		facing_marker.material_override = marker_material
		block_node.add_child(facing_marker)

		var static_body := StaticBody3D.new()
		static_body.set_meta("builder_surface", "block")
		static_body.set_meta("builder_cell", _normalize_cell(block.get("cell", [0, 0, 0])))
		var collision_shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = mesh.size
		collision_shape.shape = box_shape
		static_body.add_child(collision_shape)
		block_node.add_child(static_body)

		block_visuals[int(block.get("id", 0))] = block_node

func _refresh_cursor_visual() -> void:
	var block_id := _get_selected_block_id()
	var block_def := NetworkRuntime.get_builder_block_definition(block_id)
	var block_size: Vector3 = block_def.get("size", Vector3.ONE)
	cursor_root.position = _cell_to_local_position([cursor_cell.x, cursor_cell.y, cursor_cell.z])
	cursor_root.rotation_degrees.y = float(selected_rotation_steps * 90)
	cursor_root.visible = cursor_has_target
	var box_mesh := cursor_mesh.mesh as BoxMesh
	if box_mesh != null:
		box_mesh.size = block_size * BLOCK_CELL_SIZE * 1.05
	cursor_label.text = "%s • %s" % [
		str(block_def.get("label", block_id.capitalize())),
		_get_feedback_heading(cursor_feedback_state),
	]
	cursor_label.position = Vector3(0.0, block_size.y * BLOCK_CELL_SIZE * 0.82 + 0.42, 0.0)
	cursor_label.visible = cursor_has_target

	var material := StandardMaterial3D.new()
	material.albedo_color = _get_feedback_color(cursor_feedback_state)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.18
	cursor_mesh.material_override = material
	if crosshair_label != null:
		crosshair_label.modulate = material.albedo_color.lightened(0.26)
	_refresh_local_builder_tool_visual()

func _get_feedback_heading(feedback_state: String) -> String:
	match feedback_state:
		"ready":
			return "Ready"
		"occupied":
			return "Occupied"
		"range":
			return "Move Closer"
		"blocked":
			return "Outside Volume"
		_:
			return "Aim"

func _get_feedback_color(feedback_state: String) -> Color:
	match feedback_state:
		"ready":
			return CURSOR_OK_COLOR
		"occupied":
			return CURSOR_OCCUPIED_COLOR
		"range":
			return CURSOR_RANGE_COLOR
		_:
			return CURSOR_BLOCKED_COLOR

func _get_presence_feedback_color(base_color: Color, feedback_state: String) -> Color:
	var state_color := _get_feedback_color(feedback_state)
	if feedback_state == "ready":
		return base_color.lightened(0.12)
	return base_color.lerp(state_color, 0.72)

func _get_builder_presence_summary(avatar_state: Dictionary) -> String:
	var block_id := str(avatar_state.get("selected_block_id", "structure"))
	var block_label := str(NetworkRuntime.get_builder_block_definition(block_id).get("label", block_id.capitalize()))
	if bool(avatar_state.get("has_target", false)):
		return "%s • %s" % [block_label, _get_feedback_heading(str(avatar_state.get("target_feedback_state", "hidden")))]
	return "%s • Aiming" % block_label

func _get_local_target_compact_text() -> String:
	if not cursor_has_target:
		return "Aim at the dock or boat."
	var block_label := str(NetworkRuntime.get_builder_block_definition(_get_selected_block_id()).get("label", _get_selected_block_id().capitalize()))
	var target_cell_text := "%d,%d,%d" % [cursor_cell.x, cursor_cell.y, cursor_cell.z]
	match cursor_feedback_state:
		"ready":
			return "%s at %s • F place%s" % [
				block_label,
				target_cell_text,
				" • X remove" if cursor_can_remove else "",
			]
		"occupied":
			return "%s at %s • X remove or pick another face" % [block_label, target_cell_text]
		"range":
			return "%s at %s • move closer" % [block_label, target_cell_text]
		"blocked":
			return "%s at %s • outside build volume" % [block_label, target_cell_text]
		_:
			return "%s at %s" % [block_label, target_cell_text]

func _refresh_local_builder_tool_visual() -> void:
	if local_avatar_body == null:
		return
	var visual_root := local_avatar_body.get_node_or_null("AvatarVisual") as Node3D
	if visual_root == null:
		return
	var block_color: Color = NetworkRuntime.get_builder_block_definition(_get_selected_block_id()).get("color", Color(0.96, 0.83, 0.32))
	var tool := visual_root.get_node_or_null("Tool") as MeshInstance3D
	if tool != null:
		var tool_material := StandardMaterial3D.new()
		tool_material.albedo_color = block_color.lightened(0.12)
		tool_material.roughness = 0.24
		tool.material_override = tool_material

func _refresh_hud() -> void:
	var stats := NetworkRuntime.get_blueprint_stats()
	var block_id := _get_selected_block_id()
	var block_def := NetworkRuntime.get_builder_block_definition(block_id)
	var warnings := NetworkRuntime.get_blueprint_warnings()
	var warning_lines := PackedStringArray()
	for warning in warnings:
		warning_lines.append("- %s" % str(warning))
	if warning_lines.is_empty():
		warning_lines.append("- No major warnings. This hull is ready to sail.")

	var palette_entries := PackedStringArray()
	for palette_block_id_variant in NetworkRuntime.get_builder_block_ids():
		var palette_block_id := str(palette_block_id_variant)
		var palette_label_text := str(NetworkRuntime.get_builder_block_definition(palette_block_id).get("label", palette_block_id.capitalize()))
		if palette_block_id == block_id:
			palette_entries.append("[%s]" % palette_label_text)
		else:
			palette_entries.append(palette_label_text)
	onboarding_label.text = _build_onboarding_text()
	hud_icons.set_icon(selection_icon, hud_icons.get_block_icon_id(block_id))
	hud_icons.set_icon(builder_icon, hud_icons.get_block_icon_id(block_id))
	var active_tool_id := _get_selected_hangar_tool_id()
	var active_tool_label := _get_hangar_tool_label(active_tool_id)
	selection_label.text = "Tool %s | Palette %d/%d\n%s | Rot %d deg\nHP %.0f | Float %.1f | Thrust %.1f | Cargo +%d | Kits +%d | Brace +%.2f" % [
		active_tool_label,
		selected_block_index + 1,
		maxi(1, palette_entries.size()),
		str(block_def.get("label", block_id.capitalize())),
		selected_rotation_steps * 90,
		float(block_def.get("max_hp", 0.0)),
		float(block_def.get("buoyancy", 0.0)),
		float(block_def.get("thrust", 0.0)),
		int(block_def.get("cargo", 0)),
		int(block_def.get("repair", 0)),
		float(block_def.get("brace", 0.0)),
	]

	target_label.text = "%s Target\n%s\n%s" % [
		active_tool_label,
		_get_feedback_heading(cursor_feedback_state),
		_get_local_target_compact_text(),
	]

	builder_label.text = "Blueprint v%d | Blocks %d | Main %d | Loose %d | Components %d\nHull %.0f | Top Speed %.1f | Cargo %d | Patch Kits %d | Brace x%.2f | Margin %.1f" % [
		int(NetworkRuntime.boat_blueprint.get("version", 1)),
		int(stats.get("block_count", 0)),
		int(stats.get("main_chunk_blocks", 0)),
		int(stats.get("loose_blocks", 0)),
		int(stats.get("component_count", 0)),
		float(stats.get("max_hull_integrity", 0.0)),
		float(stats.get("top_speed", 0.0)),
		int(stats.get("cargo_capacity", 0)),
		int(stats.get("repair_capacity", 0)),
		float(stats.get("brace_multiplier", 1.0)),
		float(stats.get("buoyancy_margin", 0.0)),
	]
	var readiness_snapshot := _get_launch_readiness_snapshot(stats, warnings)
	hud_icons.set_icon(
		launch_readiness_icon,
		"brace" if str(readiness_snapshot.get("button_text", "")).contains("Risky") or str(readiness_snapshot.get("button_text", "")).contains("Loose") else "extraction"
	)
	launch_readiness_label.text = "%s\n%s" % [
		str(readiness_snapshot.get("title", "Ready To Sail")),
		str(readiness_snapshot.get("detail", "")),
	]
	launch_readiness_label.modulate = readiness_snapshot.get("color", Color(0.98, 0.97, 0.92))
	warning_label.text = "Warnings And Tips\n%s" % "\n".join(warning_lines)
	var mouse_hint := "Esc frees the cursor for buttons. RMB returns to build aim." if _is_mouse_captured() else "Cursor free: click buttons, then press Esc or RMB to return to aim."
	status_label.text = "Build Session\n%s\n%s" % [NetworkRuntime.status_message, mouse_hint]
	launch_button.disabled = NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR
	launch_button.text = str(readiness_snapshot.get("button_text", "Launch Run"))
	launch_button.tooltip_text = "\n".join(warning_lines)

	var progression_snapshot := _get_progression_snapshot()
	var total_runs := int(progression_snapshot.get("total_runs", 0))
	var successful_runs := int(progression_snapshot.get("successful_runs", 0))
	var extraction_rate := 0.0
	if total_runs > 0:
		extraction_rate = float(successful_runs) / float(total_runs) * 100.0
	var unlocked_blocks := Array(progression_snapshot.get("unlocked_blocks", []))
	hud_icons.set_icon(profile_icon, "gold")
	profile_label.text = "Gold %d | Salvage %d | Runs %d | Extracted %d (%.0f%%)\nUnlocked %d/%d parts" % [
		int(progression_snapshot.get("total_gold", 0)),
		int(progression_snapshot.get("total_salvage", 0)),
		total_runs,
		successful_runs,
		extraction_rate,
		unlocked_blocks.size(),
		NetworkRuntime.BUILDER_BLOCK_ORDER.size(),
	]
	var store_entries := NetworkRuntime.get_builder_store_entries()
	if store_entries.is_empty():
		hud_icons.set_icon(store_icon, "salvage")
		store_label.text = "All prototype parts are already available."
		if unlock_button != null:
			unlock_button.disabled = true
			unlock_button.text = "All Parts Unlocked"
	else:
		selected_store_index = wrapi(selected_store_index, 0, store_entries.size())
		var selected_store_entry: Dictionary = store_entries[selected_store_index]
		var selected_unlocked := bool(selected_store_entry.get("unlocked", false))
		var selected_affordable := bool(selected_store_entry.get("affordable", false))
		var entry_status := "Unlocked" if selected_unlocked else ("Ready" if selected_affordable else "Locked")
		hud_icons.set_icon(store_icon, hud_icons.get_block_icon_id(str(selected_store_entry.get("block_id", ""))))
		store_label.text = "Selection %d/%d\nSelected: %s\n%s\nStatus: %s\nCost: %d gold / %d salvage\nZ/C browse | V buy" % [
			selected_store_index + 1,
			store_entries.size(),
			str(selected_store_entry.get("label", "Part")),
			str(selected_store_entry.get("description", "")),
			entry_status,
			int(selected_store_entry.get("unlock_cost_gold", 0)),
			int(selected_store_entry.get("unlock_cost_salvage", 0)),
		]
		if unlock_button != null:
			unlock_button.disabled = NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR or selected_unlocked or not selected_affordable
			unlock_button.text = "Already Unlocked" if selected_unlocked else "Unlock %s" % str(selected_store_entry.get("label", "Part"))

	var crew_lines := PackedStringArray()
	var local_position := local_avatar_body.global_position if local_avatar_body != null and is_instance_valid(local_avatar_body) and local_avatar_body.is_inside_tree() else Vector3.ZERO
	var local_peer_id := _get_local_peer_id()
	for peer_id in NetworkRuntime.get_player_peer_ids():
		var peer_data: Dictionary = NetworkRuntime.peer_snapshot.get(peer_id, {})
		var avatar_state: Dictionary = NetworkRuntime.get_hangar_avatar_state().get(peer_id, {})
		var avatar_position: Vector3 = avatar_state.get("position", Vector3.ZERO)
		var distance_text := "You" if peer_id == local_peer_id else "%.1fm away" % local_position.distance_to(avatar_position)
		var presence_text := _get_builder_presence_summary(avatar_state)
		var peer_reaction := _get_reaction_visual(int(peer_id))
		var reaction_text := ""
		if not peer_reaction.is_empty():
			reaction_text = " | %s" % str(peer_reaction.get("type", "reacting")).capitalize()
		crew_lines.append("%s | %s | %s%s" % [
			str(peer_data.get("name", "Crew")),
			distance_text,
			presence_text,
			reaction_text,
		])
	if crew_lines.is_empty():
		crew_lines.append("No crew connected yet.")
	roster_label.text = "Crew In Hangar (%d)\n%s" % [NetworkRuntime.get_player_peer_ids().size(), "\n".join(crew_lines)]

	var last_run := Dictionary(progression_snapshot.get("last_run", {}))
	var last_unlock := Dictionary(progression_snapshot.get("last_unlock", {}))
	if last_run.is_empty():
		hud_icons.set_icon(last_run_icon, "cargo")
		last_run_label.text = "No extracted team runs recorded on this host yet."
	else:
		hud_icons.set_icon(last_run_icon, "salvage")
		last_run_label.text = "%s\nGold %d | Salvage %d | Secured %d | Lost %d | Recorded %s" % [
			str(last_run.get("title", "Run Complete")),
			int(last_run.get("reward_gold", 0)),
			int(last_run.get("reward_salvage", 0)),
			int(last_run.get("cargo_secured", 0)),
			int(last_run.get("cargo_lost", 0)),
			str(last_run.get("timestamp", "")),
		]
	if not last_unlock.is_empty():
		last_run_label.text += "\nLast Unlock: %s for %d gold / %d salvage" % [
			str(last_unlock.get("label", "Part")),
			int(last_unlock.get("cost_gold", 0)),
			int(last_unlock.get("cost_salvage", 0)),
		]

	toolbelt_label.text = _build_hangar_toolbelt_text()
	inventory_label.text = _build_hangar_inventory_text()
	controls_label.text = "Controls\nMouse aim | W A S D move | Space jump\n1 Build | 2 Remove | 3 Yard | I inventory\nQ / E parts | R rotate | F use tool | X remove\nZ / C unlocks | V buy | Enter launch\nEsc cursor toggle | RMB recapture aim"
	_apply_hud_visibility()

func _build_onboarding_text() -> String:
	if cursor_feedback_state == "range":
		return "Onboarding: Move closer before placing. Position matters in this shared build yard."
	if cursor_feedback_state == "occupied":
		return "Onboarding: That cell is taken. Rotate, remove, or pick a fresh face on the hull."
	if not cursor_has_target:
		return "Onboarding: Walk, jump, and aim the center crosshair at the dock or boat to build together."

	var stats := NetworkRuntime.get_blueprint_stats()
	if int(stats.get("loose_blocks", 0)) > 0:
		return "Onboarding: Loose chunks are allowed, but they will sink the moment the run starts."
	if Array(NetworkRuntime.get_builder_store_entries()).size() > 0:
		return "Onboarding: Z/C browses the unlock yard and V buys new parts for the whole crew."
	return "Onboarding: Build something weird, keep the main chunk floaty, and launch when the crew likes the shape."

func _get_hangar_tool_label(tool_id: String) -> String:
	for tool_variant in _get_hangar_toolbelt_entries():
		var tool: Dictionary = tool_variant
		if str(tool.get("id", "")) == tool_id:
			return str(tool.get("label", tool_id.capitalize()))
	return tool_id.capitalize()

func _build_hangar_toolbelt_text() -> String:
	var entries := _get_hangar_toolbelt_entries()
	if not entries.is_empty():
		selected_hangar_tool_index = wrapi(selected_hangar_tool_index, 0, entries.size())
	var tokens := PackedStringArray()
	for entry_index in range(entries.size()):
		var entry: Dictionary = entries[entry_index]
		var token := "%d %s" % [entry_index + 1, str(entry.get("label", "Tool"))]
		if entry_index == selected_hangar_tool_index:
			token = "[%s]" % token
		tokens.append(token)
	var selected_entry: Dictionary = entries[selected_hangar_tool_index] if not entries.is_empty() else {}
	return "%s\n%s" % [
		"  ".join(tokens),
		str(selected_entry.get("hint", "Use the shared builder tools from here.")),
	]

func _build_hangar_inventory_text() -> String:
	var snapshot := NetworkRuntime.get_hangar_inventory_snapshot(_get_selected_hangar_tool_id())
	var tool_lines := PackedStringArray()
	for entry_variant in Array(snapshot.get("toolbelt_manifest", [])):
		var entry: Dictionary = entry_variant
		var prefix := "* " if bool(entry.get("equipped", false)) else "- "
		tool_lines.append("%s%s" % [prefix, str(entry.get("label", "Tool"))])
	if tool_lines.is_empty():
		tool_lines.append("- No tools equipped.")
	var manifest_lines := PackedStringArray()
	for entry_variant in Array(snapshot.get("blueprint_manifest", [])):
		var entry: Dictionary = entry_variant
		manifest_lines.append("- %s x%d" % [
			str(entry.get("label", "Part")),
			int(entry.get("quantity", 0)),
		])
	if manifest_lines.is_empty():
		manifest_lines.append("- No parts mounted yet.")
	var unlocked_parts := PackedStringArray()
	for unlocked_part_variant in snapshot.get("unlocked_parts", PackedStringArray()):
		unlocked_parts.append(str(unlocked_part_variant))
	if unlocked_parts.is_empty():
		unlocked_parts.append("Core set only")
	var store_entries := Array(snapshot.get("store_entries", []))
	var next_unlock_text := "All current prototype parts unlocked."
	if not store_entries.is_empty():
		var next_entry: Dictionary = store_entries[selected_store_index % store_entries.size()]
		next_unlock_text = "%s for %d gold / %d salvage" % [
			str(next_entry.get("label", "Part")),
			int(next_entry.get("unlock_cost_gold", 0)),
			int(next_entry.get("unlock_cost_salvage", 0)),
		]
	var stats: Dictionary = snapshot.get("stats", {})
	return "On You\n%s\nDock Totals: %d gold | %d salvage\nMounted Parts\n%s\nUnlocked: %s\nNext Yard Pick: %s\nBlueprint: Cargo %d | Patch Kits %d | Main %d | Loose %d" % [
		"\n".join(tool_lines),
		int(snapshot.get("gold", 0)),
		int(snapshot.get("salvage", 0)),
		"\n".join(manifest_lines),
		", ".join(unlocked_parts),
		next_unlock_text,
		int(stats.get("cargo_capacity", 0)),
		int(stats.get("repair_capacity", 0)),
		int(stats.get("main_chunk_blocks", 0)),
		int(stats.get("loose_blocks", 0)),
	]

func _get_launch_readiness_snapshot(stats: Dictionary, warnings: Array) -> Dictionary:
	var loose_blocks := int(stats.get("loose_blocks", 0))
	var engine_count := int(stats.get("engine_count", 0))
	var buoyancy_margin := float(stats.get("buoyancy_margin", 0.0))
	var seaworthy := bool(NetworkRuntime.boat_blueprint.get("seaworthy", false))
	if not seaworthy:
		return {
			"title": "Risky Launch",
			"detail": "Your main chunk is missing key float or drive support. It will still launch, but mistakes will hurt immediately.",
			"color": Color(0.98, 0.72, 0.42),
			"button_text": "Launch Risky Build",
		}
	if loose_blocks > 0:
		return {
			"title": "Loose Chunks Detected",
			"detail": "%d block(s) will peel off and sink the moment the run starts. Launch if the chaos is worth it." % loose_blocks,
			"color": Color(0.96, 0.83, 0.42),
			"button_text": "Launch With Loose Chunks",
		}
	if buoyancy_margin < 2.0 or engine_count <= 1 or not warnings.is_empty():
		return {
			"title": "Ready, But Spicy",
			"detail": "This boat can sail, but the margin for error is thin. Brace timing and repairs will matter.",
			"color": Color(0.86, 0.95, 0.61),
			"button_text": "Launch Run",
		}
	return {
		"title": "Ready To Sail",
		"detail": "Main chunk is connected, powered, and stable enough for a clean first push.",
		"color": Color(0.72, 0.96, 0.78),
		"button_text": "Launch Run",
	}

func _update_build_target_from_camera() -> void:
	if camera == null or local_avatar_body == null:
		return
	var next_state := _query_build_target_from_camera()
	var next_cursor_has_target := bool(next_state.get("has_target", false))
	var next_cursor_cell: Vector3i = _variant_to_cell_vector(next_state.get("place_cell", cursor_cell))
	var next_remove_cell: Vector3i = _variant_to_cell_vector(next_state.get("remove_cell", remove_cursor_cell))
	var next_cursor_can_place := bool(next_state.get("can_place", false))
	var next_cursor_can_remove := bool(next_state.get("can_remove", false))
	var next_feedback_state := str(next_state.get("feedback_state", "hidden"))
	var next_cursor_target_label := str(next_state.get("label", "Aim at the boat or dock"))
	if next_cursor_has_target == cursor_has_target and next_cursor_cell == cursor_cell and next_remove_cell == remove_cursor_cell and next_cursor_can_place == cursor_can_place and next_cursor_can_remove == cursor_can_remove and next_feedback_state == cursor_feedback_state and next_cursor_target_label == cursor_target_label:
		return
	cursor_has_target = next_cursor_has_target
	cursor_cell = next_cursor_cell
	remove_cursor_cell = next_remove_cell
	cursor_can_place = next_cursor_can_place
	cursor_can_remove = next_cursor_can_remove
	cursor_feedback_state = next_feedback_state
	cursor_target_label = next_cursor_target_label
	_refresh_cursor_visual()
	_refresh_hud()
	avatar_sync_timer = 0.0

func _query_build_target_from_camera() -> Dictionary:
	if NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR:
		return {
			"has_target": false,
			"feedback_state": "hidden",
			"label": "Run in progress",
		}
	var viewport_rect := get_viewport().get_visible_rect()
	var screen_center := viewport_rect.size * 0.5
	var ray_origin := camera.project_ray_origin(screen_center)
	var ray_direction := camera.project_ray_normal(screen_center)
	var ray_length := NetworkRuntime.get_hangar_build_range() + chase_camera_distance + 10.0
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * ray_length)
	query.exclude = [local_avatar_body.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return {
			"has_target": false,
			"feedback_state": "hidden",
			"label": "Aim at the boat or dock",
		}

	var collider: Variant = hit.get("collider", null)
	var hit_position: Vector3 = hit.get("position", Vector3.ZERO)
	var hit_normal: Vector3 = hit.get("normal", Vector3.UP)
	var place_cell := Vector3i.ZERO
	var remove_cell := Vector3i.ZERO
	var can_remove := false
	var surface_label := "Dock"
	if collider != null and collider.has_meta("builder_cell"):
		remove_cell = _variant_to_cell_vector(collider.get_meta("builder_cell"))
		place_cell = remove_cell + _normal_to_cell_step(hit_normal)
		can_remove = _find_block_at_cell(remove_cell).size() > 0 and _cell_in_local_build_range(remove_cell)
		var hit_block := _find_block_at_cell(remove_cell)
		surface_label = str(NetworkRuntime.get_builder_block_definition(str(hit_block.get("type", "structure"))).get("label", "Block"))
	elif collider == dock_body or (collider != null and str(collider.get_meta("builder_surface", "")) == "dock"):
		place_cell = _world_to_cell(hit_position + hit_normal * (BLOCK_CELL_SIZE * 0.45))
		remove_cell = place_cell
	else:
		return {
			"has_target": false,
			"feedback_state": "hidden",
			"label": "Aim at the boat or dock",
		}

	var within_bounds := _cell_within_builder_bounds(place_cell)
	var occupied := _find_block_at_cell(place_cell).size() > 0
	var in_range := _cell_in_local_build_range(place_cell)
	var target_distance := 0.0
	if local_avatar_body != null:
		target_distance = local_avatar_body.global_position.distance_to(_cell_to_world_position(place_cell))
	var can_place := within_bounds and in_range and not occupied
	var feedback_state := "ready"
	var selected_block_label := str(NetworkRuntime.get_builder_block_definition(_get_selected_block_id()).get("label", _get_selected_block_id().capitalize()))
	var cell_text := "%d,%d,%d" % [place_cell.x, place_cell.y, place_cell.z]
	var label := "%s at %s" % [selected_block_label, cell_text]
	if surface_label != "Dock":
		label = "%s next to %s at %s" % [selected_block_label, surface_label, cell_text]
	if not within_bounds:
		feedback_state = "blocked"
		label += " • outside build volume"
	elif not in_range:
		feedback_state = "range"
		label += " • %.1fm / %.1fm" % [target_distance, NetworkRuntime.get_hangar_build_range()]
	elif occupied:
		feedback_state = "occupied"
		label += " • occupied"
	return {
		"has_target": true,
		"place_cell": place_cell,
		"remove_cell": remove_cell,
		"can_place": can_place,
		"can_remove": can_remove,
		"feedback_state": feedback_state,
		"label": label,
	}

func _variant_to_cell_vector(cell_value: Variant) -> Vector3i:
	var cell := _normalize_cell(cell_value)
	return Vector3i(cell[0], cell[1], cell[2])

func _world_to_cell(world_position: Vector3) -> Vector3i:
	var local_position := boat_root.to_local(world_position)
	return Vector3i(
		roundi(local_position.x / BLOCK_CELL_SIZE),
		roundi(local_position.y / BLOCK_CELL_SIZE),
		roundi(local_position.z / BLOCK_CELL_SIZE)
	)

func _normal_to_cell_step(normal: Vector3) -> Vector3i:
	var axis := Vector3.ZERO
	if absf(normal.x) >= absf(normal.y) and absf(normal.x) >= absf(normal.z):
		axis.x = signf(normal.x)
	elif absf(normal.y) >= absf(normal.z):
		axis.y = signf(normal.y)
	else:
		axis.z = signf(normal.z)
	return Vector3i(int(axis.x), int(axis.y), int(axis.z))

func _cell_within_builder_bounds(cell: Vector3i) -> bool:
	var bounds_min := NetworkRuntime.get_builder_bounds_min()
	var bounds_max := NetworkRuntime.get_builder_bounds_max()
	return cell.x >= bounds_min.x and cell.x <= bounds_max.x and cell.y >= bounds_min.y and cell.y <= bounds_max.y and cell.z >= bounds_min.z and cell.z <= bounds_max.z

func _cell_to_world_position(cell: Vector3i) -> Vector3:
	return boat_root.to_global(_cell_to_local_position(cell))

func _cell_in_local_build_range(cell: Vector3i) -> bool:
	if local_avatar_body == null:
		return false
	return local_avatar_body.global_position.distance_to(_cell_to_world_position(cell)) <= (NetworkRuntime.get_hangar_build_range() + 0.2)

func _apply_autohangar_spawn_override() -> void:
	var autohangar_role := str(launch_overrides.get("autohangar_role", ""))
	if autohangar_role.is_empty() or local_avatar_body == null:
		return
	match autohangar_role:
		"bumper_left":
			local_avatar_body.global_position = Vector3(-1.7, 0.55, 5.8)
			local_avatar_facing_y = -PI * 0.5
		"bumper_right":
			local_avatar_body.global_position = Vector3(1.7, 0.55, 5.8)
			local_avatar_facing_y = PI * 0.5

func _get_hangar_scripted_move_direction() -> Vector3:
	var autohangar_role := str(launch_overrides.get("autohangar_role", ""))
	if autohangar_role.is_empty() or local_avatar_body == null:
		return Vector3.ZERO
	var target := Vector3.ZERO
	match autohangar_role:
		"bumper_left":
			target = Vector3(0.85, 0.55, 5.7)
		"bumper_right":
			target = Vector3(-0.85, 0.55, 5.7)
		_:
			return Vector3.ZERO
	var offset := target - local_avatar_body.global_position
	offset.y = 0.0
	if offset.length() <= 0.12:
		return Vector3.ZERO
	return offset.normalized()

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
	local_camera_jolt = local_camera_jolt.lerp(Vector3.ZERO, minf(1.0, delta * 7.5))
	_apply_avatar_reaction_pose(local_avatar_body, _get_local_peer_id(), delta)

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
	local_reaction_impulse += local_reaction.get("knockback_velocity", Vector3.ZERO)
	var knockback: Vector3 = local_reaction.get("knockback_velocity", Vector3.ZERO)
	if knockback.length() > 0.01:
		local_camera_jolt += knockback.normalized() * (0.18 + float(local_reaction.get("strength", 0.5)) * 0.16)

func _apply_avatar_reaction_pose(avatar_node: Node3D, peer_id: int, delta: float) -> void:
	if avatar_node == null:
		return
	var visual_root := avatar_node.get_node_or_null("AvatarVisual") as Node3D
	if visual_root == null and avatar_node.get_child_count() > 0:
		visual_root = avatar_node.get_child(0) as Node3D
	if visual_root == null:
		return
	var peer_reaction := _get_reaction_visual(peer_id)
	var target_pitch := 0.0
	var target_roll := 0.0
	var target_height := 0.0
	if not peer_reaction.is_empty():
		var active_time := float(peer_reaction.get("active_time", 0.0))
		var recovery_time := float(peer_reaction.get("recovery_time", 0.0))
		var recovery_duration := maxf(0.01, float(peer_reaction.get("recovery_duration", 0.01)))
		var intensity := 1.0 if active_time > 0.0 else clampf(recovery_time / recovery_duration, 0.0, 1.0) * 0.55
		var knockback: Vector3 = peer_reaction.get("knockback_velocity", Vector3.ZERO)
		target_pitch = clampf(knockback.z * -0.035 * intensity, -0.38, 0.38)
		target_roll = clampf(knockback.x * 0.04 * intensity, -0.42, 0.42)
		target_height = sin(connect_time_seconds * 24.0 + float(peer_id)) * 0.04 * intensity
	visual_root.rotation.x = lerp_angle(visual_root.rotation.x, target_pitch, minf(1.0, delta * 12.0))
	visual_root.rotation.z = lerp_angle(visual_root.rotation.z, target_roll, minf(1.0, delta * 12.0))
	visual_root.position.y = lerpf(visual_root.position.y, target_height, minf(1.0, delta * 10.0))

func _get_hangar_toolbelt_entries() -> Array:
	return NetworkRuntime.get_toolbelt_entries(NetworkRuntime.SESSION_PHASE_HANGAR)

func _get_selected_hangar_tool_id() -> String:
	var tool_entries := _get_hangar_toolbelt_entries()
	if tool_entries.is_empty():
		return "build"
	selected_hangar_tool_index = wrapi(selected_hangar_tool_index, 0, tool_entries.size())
	return str(Dictionary(tool_entries[selected_hangar_tool_index]).get("id", "build"))

func _select_hangar_tool(slot_index: int) -> void:
	var tool_entries := _get_hangar_toolbelt_entries()
	if slot_index < 0 or slot_index >= tool_entries.size():
		return
	selected_hangar_tool_index = slot_index
	_refresh_hud()

func _toggle_inventory_panel() -> void:
	inventory_panel_visible = not inventory_panel_visible
	_apply_hud_visibility()
	_refresh_hud()

func _use_active_hangar_tool() -> void:
	match _get_selected_hangar_tool_id():
		"remove":
			_remove_selected_block()
		"yard":
			_purchase_selected_unlock()
		_:
			_place_selected_block()

func _cycle_block(direction: int) -> void:
	var block_ids := NetworkRuntime.get_builder_block_ids()
	if block_ids.is_empty():
		return
	selected_block_index = wrapi(selected_block_index + direction, 0, block_ids.size())
	_refresh_cursor_visual()
	_refresh_hud()
	avatar_sync_timer = 0.0

func _cycle_store_selection(direction: int) -> void:
	var store_entries := NetworkRuntime.get_builder_store_entries()
	if store_entries.is_empty():
		return
	selected_store_index = wrapi(selected_store_index + direction, 0, store_entries.size())
	_refresh_hud()

func _purchase_selected_unlock() -> void:
	if NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR:
		return
	var store_entries := NetworkRuntime.get_builder_store_entries()
	if store_entries.is_empty():
		return
	selected_store_index = wrapi(selected_store_index, 0, store_entries.size())
	var selected_store_entry: Dictionary = store_entries[selected_store_index]
	if bool(selected_store_entry.get("unlocked", false)):
		return
	if not bool(selected_store_entry.get("affordable", false)):
		return
	NetworkRuntime.request_unlock_builder_block(str(selected_store_entry.get("block_id", "")))

func _rotate_selected_block() -> void:
	selected_rotation_steps = wrapi(selected_rotation_steps + 1, 0, 4)
	_refresh_cursor_visual()
	_refresh_hud()
	avatar_sync_timer = 0.0

func _place_selected_block() -> void:
	if NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR:
		return
	if float(_get_reaction_visual(_get_local_peer_id()).get("active_time", 0.0)) > 0.0:
		return
	if not cursor_can_place:
		return
	NetworkRuntime.request_place_blueprint_block([cursor_cell.x, cursor_cell.y, cursor_cell.z], _get_selected_block_id(), selected_rotation_steps)

func _remove_selected_block() -> void:
	if NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR:
		return
	if float(_get_reaction_visual(_get_local_peer_id()).get("active_time", 0.0)) > 0.0:
		return
	if not cursor_can_remove:
		return
	NetworkRuntime.request_remove_blueprint_block([remove_cursor_cell.x, remove_cursor_cell.y, remove_cursor_cell.z])

func _launch_run() -> void:
	if NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR:
		return
	_set_mouse_capture(false)
	NetworkRuntime.request_launch_run()

func _return_to_connect() -> void:
	_set_mouse_capture(false)
	NetworkRuntime.shutdown()
	GameConfig.shutdown_hosted_server()
	get_tree().change_scene_to_file(CLIENT_BOOT_SCENE)

func _quit() -> void:
	_set_mouse_capture(false)
	get_tree().quit()

func _find_block_at_cell(cell_value: Variant) -> Dictionary:
	var target_cell := _normalize_cell(cell_value)
	for block_variant in Array(NetworkRuntime.boat_blueprint.get("blocks", [])):
		var block: Dictionary = block_variant
		if _normalize_cell(block.get("cell", [0, 0, 0])) == target_cell:
			return block
	return {}

func _get_selected_block_id() -> String:
	var block_ids := NetworkRuntime.get_builder_block_ids()
	if block_ids.is_empty():
		return "structure"
	selected_block_index = wrapi(selected_block_index, 0, block_ids.size())
	return str(block_ids[selected_block_index])

func _get_progression_snapshot() -> Dictionary:
	var snapshot := NetworkRuntime.get_progression_state()
	if snapshot.is_empty():
		return DockState.get_profile_snapshot()
	return snapshot

func _cell_to_local_position(cell_value: Variant) -> Vector3:
	var cell := _normalize_cell(cell_value)
	return Vector3(float(cell[0]), float(cell[1]), float(cell[2])) * BLOCK_CELL_SIZE

func _normalize_cell(cell_value: Variant) -> Array:
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

func _update_boat_bob() -> void:
	if boat_root == null:
		return
	boat_root.position.y = 0.1

func _update_camera(delta: float) -> void:
	if camera == null:
		return
	if local_avatar_body == null:
		return
	if not camera.current:
		camera.current = true
		camera.make_current()
	var avatar_position := local_avatar_body.global_position
	var pivot := avatar_position + Vector3(0.0, chase_camera_look_height, 0.0)
	var yaw_basis := Basis(Vector3.UP, local_avatar_facing_y)
	var aim_basis := yaw_basis * Basis(Vector3.RIGHT, local_camera_pitch)
	var forward := (aim_basis * Vector3.FORWARD).normalized()
	var right := (yaw_basis * Vector3.RIGHT).normalized()
	var desired_position := pivot - forward * chase_camera_distance
	desired_position += right * chase_camera_side_offset
	desired_position += Vector3.UP * maxf(0.0, chase_camera_height - chase_camera_look_height)
	desired_position += local_camera_jolt
	var look_target := pivot + forward * chase_camera_look_ahead
	look_target += local_camera_jolt * 0.35
	camera.position = camera.position.lerp(desired_position, minf(1.0, delta * chase_camera_lag))
	camera.look_at(look_target, Vector3.UP)

func _get_blueprint_focus_point() -> Vector3:
	var focus_blocks := _get_focus_block_ids()
	if focus_blocks.is_empty():
		return boat_root.global_position
	var total := Vector3.ZERO
	for block_id_variant in focus_blocks:
		var block := _get_block_by_id(int(block_id_variant))
		if block.is_empty():
			continue
		total += _cell_to_world_position(_variant_to_cell_vector(block.get("cell", [0, 0, 0])))
	return total / float(maxi(1, focus_blocks.size()))

func _get_blueprint_focus_span() -> float:
	var focus_blocks := _get_focus_block_ids()
	if focus_blocks.is_empty():
		return 4.0
	var min_position := Vector3(INF, INF, INF)
	var max_position := Vector3(-INF, -INF, -INF)
	for block_id_variant in focus_blocks:
		var block := _get_block_by_id(int(block_id_variant))
		if block.is_empty():
			continue
		var position := _cell_to_local_position(block.get("cell", [0, 0, 0]))
		min_position.x = minf(min_position.x, position.x)
		min_position.y = minf(min_position.y, position.y)
		min_position.z = minf(min_position.z, position.z)
		max_position.x = maxf(max_position.x, position.x)
		max_position.y = maxf(max_position.y, position.y)
		max_position.z = maxf(max_position.z, position.z)
	return maxf(4.0, (max_position - min_position).length() / BLOCK_CELL_SIZE + 1.2)

func _get_focus_block_ids() -> Array:
	var main_chunk_ids := Array(NetworkRuntime.boat_blueprint.get("main_chunk_block_ids", [])).duplicate(true)
	if not main_chunk_ids.is_empty():
		return main_chunk_ids
	var focus_ids: Array = []
	for block_variant in Array(NetworkRuntime.boat_blueprint.get("blocks", [])):
		var block: Dictionary = block_variant
		focus_ids.append(int(block.get("id", 0)))
	return focus_ids

func _get_block_by_id(block_id: int) -> Dictionary:
	for block_variant in Array(NetworkRuntime.boat_blueprint.get("blocks", [])):
		var block: Dictionary = block_variant
		if int(block.get("id", 0)) == block_id:
			return block
	return {}

func _process_local_avatar_movement(delta: float) -> void:
	if local_avatar_body == null:
		return
	if NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR:
		return
	_consume_local_reaction_impulse()

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

	var scripted_direction := _get_hangar_scripted_move_direction()
	var move_direction := Vector3.ZERO
	if input_vector.length() > 0.001:
		var camera_forward := -camera.global_transform.basis.z
		camera_forward.y = 0.0
		camera_forward = camera_forward.normalized()
		var camera_right := camera.global_transform.basis.x
		camera_right.y = 0.0
		camera_right = camera_right.normalized()
		move_direction = (camera_right * input_vector.x) + (camera_forward * input_vector.y)
	elif scripted_direction.length() > 0.001:
		move_direction = scripted_direction

	var local_reaction := _get_reaction_visual(_get_local_peer_id())
	var active_reaction := float(local_reaction.get("active_time", 0.0)) > 0.0
	var recovering := float(local_reaction.get("recovery_time", 0.0)) > 0.0
	if active_reaction:
		move_direction = Vector3.ZERO
	elif recovering:
		move_direction *= 0.35

	if move_direction.length() > 0.001:
		move_direction = move_direction.normalized()

	var velocity := local_avatar_body.velocity
	var acceleration := HANGAR_ACCELERATION if local_avatar_body.is_on_floor() else HANGAR_AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, move_direction.x * HANGAR_MOVE_SPEED, acceleration * delta)
	velocity.z = move_toward(velocity.z, move_direction.z * HANGAR_MOVE_SPEED, acceleration * delta)
	if move_direction.length() <= 0.001:
		velocity.x = move_toward(velocity.x, 0.0, HANGAR_ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, 0.0, HANGAR_ACCELERATION * delta)

	if not local_avatar_body.is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	elif Input.is_physical_key_pressed(KEY_SPACE) and not active_reaction:
		velocity.y = HANGAR_JUMP_VELOCITY

	velocity.x += local_reaction_impulse.x
	velocity.z += local_reaction_impulse.z
	velocity.y += local_reaction_impulse.y
	local_reaction_impulse = local_reaction_impulse.move_toward(Vector3.ZERO, 18.0 * delta)

	local_avatar_body.velocity = velocity
	local_avatar_body.move_and_slide()
	local_avatar_body.rotation.y = local_avatar_facing_y

func _sync_local_avatar_state(delta: float) -> void:
	if local_avatar_body == null:
		return
	if NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR:
		return

	avatar_sync_timer = maxf(0.0, avatar_sync_timer - delta)
	if avatar_sync_timer > 0.0:
		return
	avatar_sync_timer = HANGAR_AVATAR_SYNC_INTERVAL
	_send_local_hangar_presence(
		local_avatar_body.global_position,
		local_avatar_body.velocity,
		local_avatar_body.is_on_floor()
	)

func _toggle_hud_details() -> void:
	hud_details_visible = not hud_details_visible
	_apply_hud_visibility()

func _apply_hud_visibility() -> void:
	if detail_panel != null:
		detail_panel.visible = hud_details_visible
	if detail_toggle_button != null:
		detail_toggle_button.text = "Hide Details (Tab)" if hud_details_visible else "Show Details (Tab)"
	if inventory_panel != null:
		inventory_panel.visible = inventory_panel_visible

func _refresh_hangar_avatar_visuals() -> void:
	var local_peer_id := _get_local_peer_id()
	var avatar_state_snapshot := NetworkRuntime.get_hangar_avatar_state()
	var remote_peer_ids: Array = []
	for peer_id_variant in avatar_state_snapshot.keys():
		var peer_id := int(peer_id_variant)
		if peer_id == local_peer_id:
			continue
		remote_peer_ids.append(peer_id)
		if remote_avatar_visuals.has(peer_id):
			continue
		var peer_data: Dictionary = NetworkRuntime.peer_snapshot.get(peer_id, {})
		remote_avatar_visuals[peer_id] = _create_remote_presence_entry(
			peer_id,
			str(peer_data.get("name", "Crew")),
			_get_remote_avatar_color(peer_id)
		)

	for peer_id_variant in remote_avatar_visuals.keys():
		var peer_id := int(peer_id_variant)
		if remote_peer_ids.has(peer_id):
			continue
		var remote_entry: Dictionary = remote_avatar_visuals[peer_id]
		var avatar_root := remote_entry.get("avatar_root") as Node3D
		var ghost_root := remote_entry.get("ghost_root") as Node3D
		if avatar_root != null:
			avatar_root.queue_free()
		if ghost_root != null:
			ghost_root.queue_free()
		remote_avatar_visuals.erase(peer_id)

	if local_avatar_body != null:
		var local_state: Dictionary = avatar_state_snapshot.get(local_peer_id, {})
		if not local_state.is_empty() and local_avatar_body.global_position.distance_to(local_state.get("position", local_avatar_body.global_position)) > 4.0:
			local_avatar_body.global_position = local_state.get("position", local_avatar_body.global_position)
			local_avatar_facing_y = float(local_state.get("facing_y", local_avatar_facing_y))
			local_avatar_body.rotation.y = local_avatar_facing_y

func _update_remote_avatar_visuals(delta: float) -> void:
	var avatar_state_snapshot := NetworkRuntime.get_hangar_avatar_state()
	for peer_id_variant in remote_avatar_visuals.keys():
		var peer_id := int(peer_id_variant)
		var remote_entry: Dictionary = remote_avatar_visuals[peer_id]
		var avatar_root := remote_entry.get("avatar_root") as Node3D
		var ghost_root := remote_entry.get("ghost_root") as Node3D
		var ghost_mesh := remote_entry.get("ghost_mesh") as MeshInstance3D
		var ghost_ring := remote_entry.get("ghost_ring") as MeshInstance3D
		if avatar_root == null:
			continue
		var avatar_state: Dictionary = avatar_state_snapshot.get(peer_id, {})
		if avatar_state.is_empty():
			if ghost_root != null:
				ghost_root.visible = false
			continue
		var target_position: Vector3 = avatar_state.get("position", avatar_root.global_position)
		avatar_root.global_position = avatar_root.global_position.lerp(target_position, minf(1.0, delta * 10.0))
		avatar_root.rotation.y = lerp_angle(avatar_root.rotation.y, float(avatar_state.get("facing_y", avatar_root.rotation.y)), minf(1.0, delta * 10.0))
		var peer_data: Dictionary = NetworkRuntime.peer_snapshot.get(peer_id, {})
		var peer_color := _get_remote_avatar_color(peer_id)
		var selected_block_id := str(avatar_state.get("selected_block_id", "structure"))
		var selected_block_def := NetworkRuntime.get_builder_block_definition(selected_block_id)
		var selected_block_color: Color = selected_block_def.get("color", peer_color)
		var presence_state := str(avatar_state.get("target_feedback_state", "hidden"))
		var presence_text := _get_builder_presence_summary(avatar_state)
		var nameplate := avatar_root.get_node_or_null("Nameplate") as Label3D
		if nameplate == null:
			nameplate = avatar_root.find_child("Nameplate", true, false) as Label3D
		if nameplate != null:
			nameplate.text = "%s\n%s" % [str(peer_data.get("name", "Crew")), presence_text]
			nameplate.modulate = _get_presence_feedback_color(peer_color, presence_state).lightened(0.12)
		var tool := avatar_root.find_child("Tool", true, false) as MeshInstance3D
		if tool != null:
			var tool_material := StandardMaterial3D.new()
			tool_material.albedo_color = selected_block_color.lightened(0.14)
			tool_material.roughness = 0.24
			tool.material_override = tool_material
		if ghost_root != null and ghost_mesh != null and ghost_ring != null:
			var has_target := bool(avatar_state.get("has_target", false))
			ghost_root.visible = has_target
			if has_target:
				var target_cell := _variant_to_cell_vector(avatar_state.get("target_cell", [0, 0, 0]))
				var block_size: Vector3 = selected_block_def.get("size", Vector3.ONE)
				ghost_root.position = _cell_to_local_position(target_cell)
				ghost_root.rotation_degrees.y = float(int(avatar_state.get("rotation_steps", 0)) * 90)
				var ghost_box := ghost_mesh.mesh as BoxMesh
				if ghost_box != null:
					ghost_box.size = block_size * BLOCK_CELL_SIZE * 1.02
				var ghost_material := StandardMaterial3D.new()
				var ghost_color := _get_presence_feedback_color(peer_color, presence_state).darkened(0.04)
				ghost_color.a = 0.24 if presence_state == "ready" else 0.18
				ghost_material.albedo_color = ghost_color
				ghost_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				ghost_material.roughness = 0.16
				ghost_mesh.material_override = ghost_material
				var ring_shape := ghost_ring.mesh as CylinderMesh
				if ring_shape != null:
					var ring_radius := maxf(block_size.x, block_size.z) * BLOCK_CELL_SIZE * 0.58
					ring_shape.top_radius = ring_radius
					ring_shape.bottom_radius = ring_radius + 0.08
				ghost_ring.position.y = -(block_size.y * BLOCK_CELL_SIZE * 0.49)
				var ring_material := StandardMaterial3D.new()
				var ring_color := _get_presence_feedback_color(peer_color, presence_state).lightened(0.08)
				ring_color.a = 0.36 if presence_state == "ready" else 0.28
				ring_material.albedo_color = ring_color
				ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				ring_material.roughness = 0.1
				ghost_ring.material_override = ring_material
		_apply_avatar_reaction_pose(avatar_root, peer_id, delta)

func _get_remote_avatar_color(peer_id: int) -> Color:
	return REMOTE_AVATAR_COLORS[abs(peer_id) % REMOTE_AVATAR_COLORS.size()]

func _schedule_optional_quit() -> void:
	var quit_after_connect_ms := int(launch_overrides.get("quit_after_connect_ms", 0))
	if quit_after_connect_ms <= 0:
		return
	get_tree().create_timer(float(quit_after_connect_ms) / 1000.0).timeout.connect(_quit_after_timer)

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
		print("Captured hangar frame to %s" % capture_path)
	else:
		push_warning("Failed to capture hangar frame to %s (error %d)." % [capture_path, result])

func _quit_after_timer() -> void:
	print("Hangar auto-quit triggered. Blueprint version=%d blocks=%d phase=%s" % [
		int(NetworkRuntime.boat_blueprint.get("version", 1)),
		Array(NetworkRuntime.boat_blueprint.get("blocks", [])).size(),
		NetworkRuntime.get_session_phase(),
	])
	get_tree().quit()

func _initialize_autobuild() -> void:
	autobuild_actions.clear()
	autobuild_pending_action.clear()
	autobuild_index = 0
	autobuild_timer = 0.0
	var autobuild_role := str(launch_overrides.get("autobuild_role", ""))
	if autobuild_role.is_empty():
		return
	if not GameConfig.claim_one_shot_flag("autobuild:%s" % autobuild_role):
		return
	match autobuild_role:
		"builder_a":
			autobuild_actions = [
				{"type": "place", "cell": [2, 0, 0], "block": "hull"},
				{"type": "place", "cell": [2, 0, 1], "block": "hull"},
				{"type": "place", "cell": [1, 1, 0], "block": "utility"},
			]
		"builder_b":
			autobuild_actions = [
				{"type": "place", "cell": [-2, 0, 0], "block": "cargo"},
				{"type": "place", "cell": [0, 1, 1], "block": "structure"},
				{"type": "place", "cell": [0, 0, -2], "block": "engine"},
			]
		"builder_demo":
			autobuild_actions = [
				{"type": "place", "cell": [2, 0, 0], "block": "hull"},
				{"type": "place", "cell": [2, 1, 0], "block": "structure"},
				{"type": "place", "cell": [-2, 0, 0], "block": "cargo"},
				{"type": "launch"},
			]
		"builder_launch":
			autobuild_actions = [
				{"type": "launch"},
			]
		"builder_loose_launch":
			autobuild_actions = [
				{"type": "place", "cell": [5, 4, 6], "block": "structure"},
				{"type": "launch"},
			]
		"builder_fragile_cargo":
			autobuild_actions = [
				{"type": "remove", "cell": [-1, 0, 0]},
				{"type": "place", "cell": [0, 0, 2], "block": "structure"},
				{"type": "place", "cell": [0, 0, 3], "block": "cargo"},
				{"type": "place", "cell": [0, 0, 4], "block": "cargo"},
				{"type": "launch"},
			]
		"builder_unlock_reinforced_hull":
			autobuild_actions = [
				{"type": "unlock", "block": "reinforced_hull"},
				{"type": "place", "cell": [2, 0, 0], "block": "reinforced_hull"},
			]
		"builder_unlock_twin_engine_launch":
			autobuild_actions = [
				{"type": "unlock", "block": "twin_engine"},
				{"type": "remove", "cell": [0, 0, -1]},
				{"type": "place", "cell": [0, 0, -1], "block": "twin_engine"},
				{"type": "launch"},
			]
		"builder_unlock_stabilizer":
			autobuild_actions = [
				{"type": "unlock", "block": "stabilizer"},
				{"type": "place", "cell": [1, 1, 0], "block": "stabilizer"},
			]

func _process_autobuild(delta: float) -> void:
	if NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR:
		return

	autobuild_timer -= delta
	if autobuild_timer > 0.0:
		return
	if not autobuild_pending_action.is_empty():
		var pending_action := autobuild_pending_action.duplicate(true)
		autobuild_pending_action.clear()
		_execute_autobuild_action(pending_action)
		autobuild_timer = 0.3
		return
	if autobuild_index >= autobuild_actions.size():
		return

	var action: Dictionary = autobuild_actions[autobuild_index]
	autobuild_index += 1
	var action_type := str(action.get("type", ""))
	if action_type == "place" or action_type == "remove":
		var cell := _normalize_cell(action.get("cell", [0, 0, 0]))
		_position_local_avatar_for_autobuild_cell(cell)
		cursor_cell = Vector3i(cell[0], cell[1], cell[2])
		cursor_has_target = true
		cursor_target_label = "Autobuild targeting %s" % str(cursor_cell)
		_refresh_cursor_visual()
		autobuild_pending_action = action.duplicate(true)
		autobuild_timer = 0.2
		return
	_execute_autobuild_action(action)
	autobuild_timer = 0.35

func _execute_autobuild_action(action: Dictionary) -> void:
	match str(action.get("type", "")):
		"unlock":
			NetworkRuntime.request_unlock_builder_block(str(action.get("block", "")))
		"place":
			var cell := _normalize_cell(action.get("cell", [0, 0, 0]))
			NetworkRuntime.request_place_blueprint_block(cell, str(action.get("block", "structure")), int(action.get("rotation_steps", 0)))
		"remove":
			var cell := _normalize_cell(action.get("cell", [0, 0, 0]))
			NetworkRuntime.request_remove_blueprint_block(cell)
		"launch":
			NetworkRuntime.request_launch_run()

func _position_local_avatar_for_autobuild_cell(cell: Array) -> void:
	if local_avatar_body == null:
		return
	var cell_world := _cell_to_world_position(Vector3i(cell[0], cell[1], cell[2]))
	var target_position := cell_world + Vector3(0.0, 0.55, 2.15)
	local_avatar_body.global_position = target_position
	local_avatar_body.velocity = Vector3.ZERO
	local_avatar_facing_y = atan2(target_position.x - cell_world.x, target_position.z - cell_world.z)
	local_avatar_body.rotation.y = local_avatar_facing_y
	_send_local_hangar_presence(local_avatar_body.global_position, Vector3.ZERO, true)

func _on_status_changed(_message: String) -> void:
	_refresh_hud()

func _on_peer_snapshot_changed(_snapshot: Dictionary) -> void:
	_refresh_hangar_avatar_visuals()
	_refresh_hud()

func _on_hangar_avatar_state_changed(_snapshot: Dictionary) -> void:
	_refresh_hangar_avatar_visuals()
	_refresh_hud()

func _on_reaction_state_changed(snapshot: Dictionary) -> void:
	reaction_visual_state = snapshot.duplicate(true)
	_refresh_hud()

func _on_boat_blueprint_changed(_snapshot: Dictionary) -> void:
	_refresh_all()
	print("Blueprint updated: version=%d blocks=%d loose=%d" % [
		int(NetworkRuntime.boat_blueprint.get("version", 1)),
		Array(NetworkRuntime.boat_blueprint.get("blocks", [])).size(),
		int(NetworkRuntime.get_blueprint_stats().get("loose_blocks", 0)),
	])

func _on_session_phase_changed(phase: String) -> void:
	if phase == NetworkRuntime.SESSION_PHASE_RUN:
		_set_mouse_capture(false)
		get_tree().change_scene_to_file(RUN_CLIENT_SCENE)
		return
	_set_mouse_capture(true)
	_refresh_hud()

func _on_profile_changed(_snapshot: Dictionary) -> void:
	_refresh_hud()

func _on_progression_state_changed(_snapshot: Dictionary) -> void:
	_refresh_hud()

func _get_local_peer_id() -> int:
	if NetworkRuntime.multiplayer == null:
		return 0
	return NetworkRuntime.multiplayer.get_unique_id()
