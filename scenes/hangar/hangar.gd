extends Node3D

const CLIENT_BOOT_SCENE := "res://scenes/boot/client_boot.tscn"
const LOADING_SCENE := "res://scenes/boot/loading_screen.tscn"
const RUN_CLIENT_SCENE := "res://scenes/run_client/run_client.tscn"
const HudIconLibrary = preload("res://scenes/shared/hud_icon_library.gd")
const ExpeditionHudSkin = preload("res://scenes/shared/expedition_hud_skin.gd")
const BoatBlockMaterials = preload("res://scenes/shared/boat_block_materials.gd")
const SeaSkyRigScene = preload("res://scenes/shared/environment/sea_sky_rig.tscn")
const HANGAR_PLAYER_CONTROLLER_SCENE := preload("res://scenes/shared/avatar/hangar_player_controller.tscn")
const PLAYER_AVATAR_VISUAL_SCENE := preload("res://scenes/shared/avatar/player_avatar_visual.tscn")
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
const HANGAR_POINTER_REPEAT_DELAY := 0.22
const HANGAR_POINTER_REPEAT_INTERVAL := 0.12
const HANGAR_CURSOR_SWITCH_STICKINESS := 0.08
const HANGAR_CURSOR_PULSE_DURATION := 0.12
const PALETTE_CATEGORY_ORDER := [
	"all",
	"hull",
	"structure",
	"propulsion",
	"salvage",
	"recovery",
	"support",
	"cargo",
]
const PALETTE_CATEGORY_LABELS := {
	"all": "All Crafted Parts",
	"hull": "Hull",
	"structure": "Structure",
	"propulsion": "Propulsion",
	"salvage": "Salvage",
	"recovery": "Recovery",
	"support": "Support",
	"cargo": "Cargo",
}

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
var hangar_tool_slot_panels: Array = []
var hangar_tool_slot_key_labels: Array = []
var hangar_tool_slot_name_labels: Array = []
var hangar_tool_slot_icons: Array = []
var block_strip_slot_panels: Array = []
var block_strip_slot_icons: Array = []
var block_strip_slot_labels: Array = []
var launch_button: Button
var sea_test_button: Button
var reset_button: Button
var unlock_button: Button
var detail_toggle_button: Button
var crosshair_label: Label
var build_focus_part_label: Label
var build_focus_state_label: Label
var build_focus_hint_label: Label
var left_panel: PanelContainer
var right_panel: PanelContainer
var bottom_left_panel: PanelContainer
var build_focus_panel: PanelContainer
var detail_panel: PanelContainer
var tool_panel: PanelContainer
var inventory_panel: PanelContainer
var block_palette_filter: OptionButton
var block_palette_list: ItemList
var block_palette_detail_label: Label
var dock_body: StaticBody3D
var boat_root: Node3D
var block_container: Node3D
var avatar_container: Node3D
var cursor_root: Node3D
var cursor_mesh: MeshInstance3D
var cursor_face_marker: MeshInstance3D
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
var cursor_face_normal := Vector3.UP
var autobuild_actions: Array = []
var autobuild_pending_action: Dictionary = {}
var autobuild_index := 0
var autobuild_timer := 0.0
var reaction_visual_state: Dictionary = {}
var local_reaction_impulse := Vector3.ZERO
var local_camera_jolt := Vector3.ZERO
var last_local_reaction_id := 0
var selected_store_index := 0
var selected_donation_index := 0
var selected_builder_overlay_index := 0
var selected_palette_category := "all"
var palette_category_ids: Array = []
var hud_details_visible := false
var inventory_panel_visible := false
var selected_hangar_tool_index := 0
var launch_transition_pending := false
var hangar_camera_dragging := false
var hangar_tool_mouse_down := false
var hangar_tool_hold_time := 0.0
var hangar_tool_repeat_armed := false
var hangar_hold_action_cooldown := 0.0
var hangar_last_drag_action_key := ""
var hangar_drag_plane_active := false
var hangar_drag_plane_axis := -1
var hangar_drag_plane_coordinate := 0
var hangar_drag_plane_face_sign := 0
var hangar_drag_plane_tool_id := ""
var cursor_switch_candidate: Dictionary = {}
var cursor_switch_candidate_started_at := 0.0
var cursor_action_pulse_time := 0.0
var hud_icons := HudIconLibrary.new()
var selection_icon: TextureRect
var build_focus_icon: TextureRect
var launch_readiness_icon: TextureRect
var profile_icon: TextureRect
var store_icon: TextureRect
var builder_icon: TextureRect
var last_run_icon: TextureRect

func _ready() -> void:
	launch_overrides = GameConfig.parse_cmdline_overrides()
	get_tree().debug_collisions_hint = false
	get_tree().debug_navigation_hint = false
	local_camera_pitch = deg_to_rad(chase_camera_pitch_default_degrees)
	_build_world()
	_build_hud()
	_set_mouse_capture(false)
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
		GameConfig.queue_scene_load(
			RUN_CLIENT_SCENE,
			"Launching Run",
			"Charting the sea, loading the weather, and hauling your boat into the next run."
		)
		get_tree().call_deferred("change_scene_to_file", LOADING_SCENE)
		return
	print("Hangar builder ready: version=%d blocks=%d phase=%s" % [
		int(NetworkRuntime.boat_blueprint.get("version", 1)),
		Array(NetworkRuntime.boat_blueprint.get("blocks", [])).size(),
		NetworkRuntime.get_session_phase(),
	])

func _process(delta: float) -> void:
	connect_time_seconds += delta
	if hangar_hold_action_cooldown > 0.0:
		hangar_hold_action_cooldown = maxf(0.0, hangar_hold_action_cooldown - delta)
	if cursor_action_pulse_time > 0.0:
		cursor_action_pulse_time = maxf(0.0, cursor_action_pulse_time - delta)
		_refresh_cursor_visual()
	_tick_reaction_visuals(delta)
	_update_boat_bob()
	_update_camera(delta)
	_update_remote_avatar_visuals(delta)
	_update_build_target_from_camera()
	_process_drag_building(delta)
	_process_autobuild(delta)

func _physics_process(delta: float) -> void:
	_process_local_avatar_movement(delta)
	_sync_local_avatar_state(delta)

func _unhandled_input(event: InputEvent) -> void:
	if NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR:
		return
	if event is InputEventMouseMotion and hangar_camera_dragging:
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
		match button_event.button_index:
			MOUSE_BUTTON_RIGHT:
				hangar_camera_dragging = button_event.pressed
				_set_mouse_capture(button_event.pressed)
				return
			MOUSE_BUTTON_LEFT:
				hangar_tool_mouse_down = button_event.pressed and not inventory_panel_visible
				if button_event.pressed:
					hangar_tool_hold_time = 0.0
					hangar_tool_repeat_armed = false
					_begin_hangar_drag_plane_lock()
				if button_event.pressed and not inventory_panel_visible:
					_apply_hangar_pointer_tool(true)
				if not button_event.pressed:
					hangar_tool_hold_time = 0.0
					hangar_tool_repeat_armed = false
					_clear_hangar_drag_plane_lock()
					cursor_switch_candidate.clear()
					cursor_switch_candidate_started_at = 0.0
					hangar_last_drag_action_key = ""
				return
			MOUSE_BUTTON_WHEEL_UP:
				if button_event.pressed and not inventory_panel_visible:
					_cycle_block(-1)
				return
			MOUSE_BUTTON_WHEEL_DOWN:
				if button_event.pressed and not inventory_panel_visible:
					_cycle_block(1)
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
		KEY_UP:
			if inventory_panel_visible:
				_cycle_block(-1)
		KEY_DOWN:
			if inventory_panel_visible:
				_cycle_block(1)
		KEY_LEFT:
			if inventory_panel_visible:
				_cycle_palette_category(-1)
		KEY_RIGHT:
			if inventory_panel_visible:
				_cycle_palette_category(1)
		KEY_Z:
			_cycle_store_selection(-1)
		KEY_C:
			_cycle_store_selection(1)
		KEY_B:
			_cycle_donation_selection(-1)
		KEY_N:
			_cycle_donation_selection(1)
		KEY_T:
			_cycle_builder_overlay(1)
		KEY_V:
			_purchase_selected_unlock()
		KEY_G:
			_donate_selected_resource()
		KEY_R:
			_rotate_selected_block()
		KEY_F:
			_use_active_hangar_tool()
		KEY_X, KEY_BACKSPACE, KEY_DELETE:
			_remove_selected_block()
		KEY_ENTER, KEY_KP_ENTER:
			_launch_run()
		KEY_ESCAPE:
			hangar_camera_dragging = false
			hangar_tool_mouse_down = false
			hangar_tool_hold_time = 0.0
			hangar_tool_repeat_armed = false
			_clear_hangar_drag_plane_lock()
			cursor_switch_candidate.clear()
			cursor_switch_candidate_started_at = 0.0
			hangar_last_drag_action_key = ""
			_set_mouse_capture(false)

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
	if get_node_or_null("Environment") is SeaSkyRig:
		return
	var sky_rig := SeaSkyRigScene.instantiate() as SeaSkyRig
	if sky_rig == null:
		return
	sky_rig.name = "Environment"
	sky_rig.preset_id = &"hangar_harbor"
	sky_rig.sun_rotation_degrees = Vector3(-42.0, 32.0, 0.0)
	sky_rig.base_sun_energy = 1.18
	add_child(sky_rig)

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
	local_avatar_body = get_node_or_null("AvatarContainer/LocalAvatar") as CharacterBody3D
	if local_avatar_body == null:
		local_avatar_body = HANGAR_PLAYER_CONTROLLER_SCENE.instantiate() as CharacterBody3D
		if local_avatar_body == null:
			return
		local_avatar_body.name = "LocalAvatar"
		avatar_container.add_child(local_avatar_body)
	_configure_player_controller_visual(local_avatar_body, "You", Color(0.32, 0.84, 0.56), true)

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

func _configure_player_controller_visual(controller: Node, display_name: String, body_color: Color, is_local: bool) -> void:
	if controller == null:
		return
	var nameplate_color := body_color.lightened(0.35) if not is_local else Color(0.96, 0.99, 0.96)
	var highlight_color := body_color.lightened(0.08)
	var tool_color := body_color.lightened(0.28)
	_apply_player_controller_presentation(controller, display_name, highlight_color, tool_color, nameplate_color, "")

func _apply_player_controller_presentation(
	controller: Node,
	display_name: String,
	highlight_color: Color,
	tool_color: Color,
	nameplate_color: Color,
	secondary_text: String
) -> void:
	if controller == null:
		return
	if controller.has_method("configure_presentation"):
		controller.call("configure_presentation", display_name, highlight_color, tool_color, nameplate_color, secondary_text)
		return
	var visual_root := controller.get_node_or_null("AvatarVisual") as Node3D
	if visual_root == null:
		visual_root = _create_avatar_visual(display_name, highlight_color.darkened(0.08), false)
		controller.add_child(visual_root)
	if visual_root.has_method("set_display_text"):
		visual_root.call("set_display_text", display_name, secondary_text)
	if visual_root.has_method("set_highlight_color"):
		visual_root.call("set_highlight_color", highlight_color)
	if visual_root.has_method("set_tool_color"):
		visual_root.call("set_tool_color", tool_color)
	if visual_root.has_method("set_nameplate_color"):
		visual_root.call("set_nameplate_color", nameplate_color)

func _create_avatar_visual(display_name: String, body_color: Color, is_local: bool) -> Node3D:
	var avatar_visual := PLAYER_AVATAR_VISUAL_SCENE.instantiate() as Node3D
	if avatar_visual != null:
		avatar_visual.name = "AvatarVisual"
		if avatar_visual.has_method("set_display_text"):
			avatar_visual.call("set_display_text", display_name)
		if avatar_visual.has_method("set_highlight_color"):
			avatar_visual.call("set_highlight_color", body_color.lightened(0.08))
		if avatar_visual.has_method("set_tool_color"):
			avatar_visual.call("set_tool_color", body_color.lightened(0.28))
		if avatar_visual.has_method("set_nameplate_color"):
			avatar_visual.call("set_nameplate_color", body_color.lightened(0.35) if not is_local else Color(0.96, 0.99, 0.96))
		return avatar_visual

	return _create_placeholder_avatar_visual(display_name, body_color, is_local)

func _create_placeholder_avatar_visual(display_name: String, body_color: Color, is_local: bool) -> Node3D:
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
	var avatar_root := HANGAR_PLAYER_CONTROLLER_SCENE.instantiate() as CharacterBody3D
	if avatar_root == null:
		avatar_root = CharacterBody3D.new()
	avatar_root.name = "RemoteAvatar%d" % peer_id
	avatar_root.collision_layer = 0
	avatar_root.collision_mask = 0
	var collision_shape := avatar_root.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision_shape != null:
		collision_shape.disabled = true
	_configure_player_controller_visual(avatar_root, display_name, body_color, false)
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
	box.size = Vector3.ONE * BLOCK_CELL_SIZE
	cursor_mesh.mesh = box
	cursor_root.add_child(cursor_mesh)

	cursor_face_marker = MeshInstance3D.new()
	cursor_face_marker.name = "CursorFaceMarker"
	var face_box := BoxMesh.new()
	face_box.size = Vector3(0.74, 0.06, 0.74) * BLOCK_CELL_SIZE
	cursor_face_marker.mesh = face_box
	cursor_root.add_child(cursor_face_marker)

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
	left_panel = hud.get_node("LeftPanel") as PanelContainer
	right_panel = hud.get_node("RightPanel") as PanelContainer
	bottom_left_panel = hud.get_node("BottomLeftPanel") as PanelContainer
	build_focus_panel = hud.get_node("BuildFocusPanel") as PanelContainer
	var title_label := hud.get_node("LeftPanel/Margin/Layout/Title") as Label
	var selection_heading := hud.get_node("LeftPanel/Margin/Layout/SelectionHeader/SelectionHeading") as Label
	var launch_readiness_heading := hud.get_node("LeftPanel/Margin/Layout/LaunchReadinessHeader/LaunchReadinessHeading") as Label
	var profile_heading := hud.get_node("RightPanel/Margin/Layout/ProfileHeader/ProfileHeading") as Label
	var store_heading := hud.get_node("RightPanel/Margin/Layout/StoreHeader/StoreHeading") as Label
	var builder_heading := hud.get_node("DetailPanel/Margin/Layout/BuilderHeader/BuilderHeading") as Label
	var last_run_heading := hud.get_node("DetailPanel/Margin/Layout/LastRunHeader/LastRunHeading") as Label
	var tool_heading := hud.get_node("ToolPanel/Margin/Layout/Heading") as Label
	var inventory_heading := hud.get_node("InventoryPanel/Margin/Layout/Heading") as Label
	var palette_heading := hud.get_node("InventoryPanel/Margin/Layout/MainRow/PaletteColumn/PaletteHeading") as Label
	var inventory_column_heading := hud.get_node("InventoryPanel/Margin/Layout/MainRow/InventoryColumn/InventoryHeading") as Label
	onboarding_label = hud.get_node("LeftPanel/Margin/Layout/OnboardingLabel") as Label
	selection_icon = hud.get_node("LeftPanel/Margin/Layout/SelectionHeader/SelectionIcon") as TextureRect
	build_focus_icon = hud.get_node("BuildFocusPanel/Margin/Layout/TopRow/FocusIcon") as TextureRect
	build_focus_part_label = hud.get_node("BuildFocusPanel/Margin/Layout/TopRow/PartLabel") as Label
	build_focus_state_label = hud.get_node("BuildFocusPanel/Margin/Layout/StateLabel") as Label
	build_focus_hint_label = hud.get_node("BuildFocusPanel/Margin/Layout/HintLabel") as Label
	selection_label = hud.get_node("LeftPanel/Margin/Layout/SelectionLabel") as Label
	target_label = hud.get_node("LeftPanel/Margin/Layout/TargetLabel") as Label
	launch_readiness_icon = hud.get_node("LeftPanel/Margin/Layout/LaunchReadinessHeader/LaunchReadinessIcon") as TextureRect
	launch_readiness_label = hud.get_node("LeftPanel/Margin/Layout/LaunchReadinessLabel") as Label
	status_label = hud.get_node("LeftPanel/Margin/Layout/StatusLabel") as Label
	launch_button = hud.get_node("LeftPanel/Margin/Layout/Actions/LaunchButton") as Button
	sea_test_button = hud.get_node("LeftPanel/Margin/Layout/Actions/SeaTestButton") as Button
	reset_button = hud.get_node("LeftPanel/Margin/Layout/Actions/ResetButton") as Button
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
	hangar_tool_slot_panels.clear()
	hangar_tool_slot_key_labels.clear()
	hangar_tool_slot_name_labels.clear()
	hangar_tool_slot_icons.clear()
	for slot_index in range(3):
		var slot_path := "ToolPanel/Margin/Layout/HotbarRow/Slot%d" % [slot_index + 1]
		hangar_tool_slot_panels.append(hud.get_node(slot_path) as PanelContainer)
		hangar_tool_slot_key_labels.append(hud.get_node("%s/Margin/Layout/TopRow/KeyLabel" % slot_path) as Label)
		hangar_tool_slot_name_labels.append(hud.get_node("%s/Margin/Layout/TopRow/NameLabel" % slot_path) as Label)
		hangar_tool_slot_icons.append(hud.get_node("%s/Margin/Layout/Icon" % slot_path) as TextureRect)
	_ensure_block_strip_row(hud.get_node("ToolPanel/Margin/Layout") as VBoxContainer)
	inventory_panel = hud.get_node("InventoryPanel") as PanelContainer
	block_palette_filter = hud.get_node("InventoryPanel/Margin/Layout/MainRow/PaletteColumn/CategoryRow/CategoryOption") as OptionButton
	block_palette_list = hud.get_node("InventoryPanel/Margin/Layout/MainRow/PaletteColumn/BlockPaletteList") as ItemList
	block_palette_detail_label = hud.get_node("InventoryPanel/Margin/Layout/MainRow/PaletteColumn/BlockPaletteDetailLabel") as Label
	inventory_label = hud.get_node("InventoryPanel/Margin/Layout/MainRow/InventoryColumn/InventoryLabel") as Label
	detail_panel = hud.get_node("DetailPanel") as PanelContainer
	builder_icon = hud.get_node("DetailPanel/Margin/Layout/BuilderHeader/BuilderIcon") as TextureRect
	builder_label = hud.get_node("DetailPanel/Margin/Layout/BuilderLabel") as Label
	warning_label = hud.get_node("DetailPanel/Margin/Layout/WarningLabel") as Label
	last_run_icon = hud.get_node("DetailPanel/Margin/Layout/LastRunHeader/LastRunIcon") as TextureRect
	last_run_label = hud.get_node("DetailPanel/Margin/Layout/LastRunLabel") as Label
	crosshair_label = hud.get_node("CrosshairLabel") as Label

	for icon in [
		selection_icon,
		build_focus_icon,
		launch_readiness_icon,
		profile_icon,
		store_icon,
		builder_icon,
		last_run_icon,
	]:
		hud_icons.configure_icon_rect(icon)
	for slot_icon_variant in hangar_tool_slot_icons:
		hud_icons.configure_icon_rect(slot_icon_variant as TextureRect, Vector2(24.0, 24.0))
	for strip_icon_variant in block_strip_slot_icons:
		hud_icons.configure_icon_rect(strip_icon_variant as TextureRect, Vector2(30.0, 30.0))

	ExpeditionHudSkin.apply_plate(left_panel, ExpeditionHudSkin.BUOY_ORANGE, ExpeditionHudSkin.HANGAR_PANEL, "scrim")
	ExpeditionHudSkin.apply_plate(right_panel, ExpeditionHudSkin.OXIDIZED_TEAL, ExpeditionHudSkin.HANGAR_PANEL_SOFT, "scrim")
	ExpeditionHudSkin.apply_plate(bottom_left_panel, ExpeditionHudSkin.OXIDIZED_TEAL, ExpeditionHudSkin.HANGAR_PANEL_SOFT, "scrim")
	ExpeditionHudSkin.apply_plate(build_focus_panel, ExpeditionHudSkin.BUOY_ORANGE, ExpeditionHudSkin.HANGAR_PANEL_SOFT, "scrim")
	ExpeditionHudSkin.apply_plate(detail_panel, ExpeditionHudSkin.BRASS_YELLOW, ExpeditionHudSkin.HANGAR_PANEL_SOFT, "ghost")
	ExpeditionHudSkin.apply_plate(tool_panel, ExpeditionHudSkin.BUOY_ORANGE, ExpeditionHudSkin.HANGAR_PANEL_SOFT, "scrim")
	ExpeditionHudSkin.apply_plate(inventory_panel, ExpeditionHudSkin.OXIDIZED_TEAL, ExpeditionHudSkin.HANGAR_PANEL_SOFT, "ledger")

	ExpeditionHudSkin.apply_heading(title_label, ExpeditionHudSkin.TEXT_PRIMARY)
	ExpeditionHudSkin.apply_heading(selection_heading, ExpeditionHudSkin.TEXT_WARNING)
	ExpeditionHudSkin.apply_heading(launch_readiness_heading, ExpeditionHudSkin.TEXT_SUCCESS)
	ExpeditionHudSkin.apply_heading(profile_heading, ExpeditionHudSkin.TEXT_MUTED)
	ExpeditionHudSkin.apply_heading(store_heading, ExpeditionHudSkin.TEXT_WARNING)
	ExpeditionHudSkin.apply_heading(builder_heading, ExpeditionHudSkin.TEXT_PRIMARY)
	ExpeditionHudSkin.apply_heading(last_run_heading, ExpeditionHudSkin.TEXT_MUTED)
	ExpeditionHudSkin.apply_heading(tool_heading, ExpeditionHudSkin.TEXT_WARNING)
	ExpeditionHudSkin.apply_heading(inventory_heading, ExpeditionHudSkin.TEXT_MUTED)
	ExpeditionHudSkin.apply_heading(palette_heading, ExpeditionHudSkin.TEXT_PRIMARY)
	ExpeditionHudSkin.apply_heading(inventory_column_heading, ExpeditionHudSkin.TEXT_PRIMARY)
	ExpeditionHudSkin.apply_heading(onboarding_label, ExpeditionHudSkin.TEXT_PRIMARY)
	ExpeditionHudSkin.apply_heading(build_focus_part_label, ExpeditionHudSkin.TEXT_PRIMARY)
	ExpeditionHudSkin.apply_heading(build_focus_state_label, ExpeditionHudSkin.TEXT_PRIMARY)
	ExpeditionHudSkin.apply_body(build_focus_hint_label, ExpeditionHudSkin.TEXT_MUTED)
	ExpeditionHudSkin.apply_body(selection_label, ExpeditionHudSkin.TEXT_PRIMARY)
	ExpeditionHudSkin.apply_muted(target_label)
	ExpeditionHudSkin.apply_heading(launch_readiness_label, ExpeditionHudSkin.TEXT_SUCCESS)
	ExpeditionHudSkin.apply_body(status_label, ExpeditionHudSkin.TEXT_MUTED)
	ExpeditionHudSkin.apply_heading(profile_label, ExpeditionHudSkin.TEXT_PRIMARY)
	ExpeditionHudSkin.apply_heading(store_label, ExpeditionHudSkin.TEXT_PRIMARY)
	ExpeditionHudSkin.apply_body(roster_label, ExpeditionHudSkin.TEXT_MUTED)
	ExpeditionHudSkin.apply_body(controls_label, ExpeditionHudSkin.TEXT_MUTED)
	ExpeditionHudSkin.apply_body(toolbelt_label, ExpeditionHudSkin.TEXT_PRIMARY)
	ExpeditionHudSkin.apply_body(inventory_label, ExpeditionHudSkin.TEXT_PRIMARY)
	for key_label_variant in hangar_tool_slot_key_labels:
		ExpeditionHudSkin.apply_muted(key_label_variant as Label)
	for name_label_variant in hangar_tool_slot_name_labels:
		ExpeditionHudSkin.apply_body(name_label_variant as Label, ExpeditionHudSkin.TEXT_MUTED)
	ExpeditionHudSkin.apply_muted(block_palette_detail_label)
	ExpeditionHudSkin.apply_body(builder_label, ExpeditionHudSkin.TEXT_PRIMARY)
	ExpeditionHudSkin.apply_body(warning_label, ExpeditionHudSkin.TEXT_WARNING)
	ExpeditionHudSkin.apply_muted(last_run_label)
	ExpeditionHudSkin.apply_crosshair(crosshair_label)
	ExpeditionHudSkin.apply_compact_button(launch_button, ExpeditionHudSkin.SEA_GLASS_GREEN, ExpeditionHudSkin.RUST_BROWN)
	ExpeditionHudSkin.apply_compact_button(sea_test_button, ExpeditionHudSkin.BRASS_YELLOW, ExpeditionHudSkin.RUST_BROWN)
	ExpeditionHudSkin.apply_compact_button(reset_button, ExpeditionHudSkin.OXIDIZED_TEAL, ExpeditionHudSkin.HANGAR_PANEL_SOFT)
	ExpeditionHudSkin.apply_compact_button(reconnect_button, ExpeditionHudSkin.BUOY_ORANGE, ExpeditionHudSkin.HANGAR_PANEL_SOFT)
	ExpeditionHudSkin.apply_compact_button(quit_button, ExpeditionHudSkin.FLARE_RED, ExpeditionHudSkin.HANGAR_PANEL_SOFT)
	ExpeditionHudSkin.apply_compact_button(unlock_button, ExpeditionHudSkin.BRASS_YELLOW, ExpeditionHudSkin.RUST_BROWN)
	ExpeditionHudSkin.apply_compact_button(detail_toggle_button, ExpeditionHudSkin.OXIDIZED_TEAL, ExpeditionHudSkin.HANGAR_PANEL_SOFT)
	ExpeditionHudSkin.apply_button(block_palette_filter, ExpeditionHudSkin.OXIDIZED_TEAL, ExpeditionHudSkin.HANGAR_PANEL_SOFT)
	ExpeditionHudSkin.apply_item_list(block_palette_list, ExpeditionHudSkin.OXIDIZED_TEAL, ExpeditionHudSkin.HANGAR_PANEL_SOFT)
	reconnect_button.text = "Back"
	quit_button.text = "Exit"

	left_panel.offset_right = 486.0
	right_panel.offset_left = -360.0
	right_panel.offset_bottom = 252.0
	tool_panel.offset_left = -224.0
	tool_panel.offset_right = 224.0
	inventory_panel.offset_left = -448.0
	inventory_panel.offset_right = 448.0

	if not launch_button.pressed.is_connected(_launch_run):
		launch_button.pressed.connect(_launch_run)
	if not sea_test_button.pressed.is_connected(_launch_sea_test):
		sea_test_button.pressed.connect(_launch_sea_test)
	if not reset_button.pressed.is_connected(_reset_boat):
		reset_button.pressed.connect(_reset_boat)
	if not reconnect_button.pressed.is_connected(_return_to_connect):
		reconnect_button.pressed.connect(_return_to_connect)
	if not quit_button.pressed.is_connected(_quit):
		quit_button.pressed.connect(_quit)
	if not unlock_button.pressed.is_connected(_purchase_selected_unlock):
		unlock_button.pressed.connect(_purchase_selected_unlock)
	if not detail_toggle_button.pressed.is_connected(_toggle_hud_details):
		detail_toggle_button.pressed.connect(_toggle_hud_details)
	if block_palette_filter != null and not block_palette_filter.item_selected.is_connected(_on_block_palette_filter_selected):
		block_palette_filter.item_selected.connect(_on_block_palette_filter_selected)
	if block_palette_list != null and not block_palette_list.item_selected.is_connected(_on_block_palette_item_selected):
		block_palette_list.item_selected.connect(_on_block_palette_item_selected)

	_apply_hud_visibility()

func _refresh_all() -> void:
	_refresh_blueprint_visuals()
	_update_build_target_from_camera()
	_refresh_hangar_avatar_visuals()
	_refresh_hud()

func _get_selected_builder_overlay_mode() -> String:
	var overlay_modes := NetworkRuntime.get_builder_overlay_modes()
	if overlay_modes.is_empty():
		return "none"
	selected_builder_overlay_index = wrapi(selected_builder_overlay_index, 0, overlay_modes.size())
	return str(overlay_modes[selected_builder_overlay_index])

func _cycle_builder_overlay(direction: int) -> void:
	var overlay_modes := NetworkRuntime.get_builder_overlay_modes()
	if overlay_modes.is_empty():
		return
	selected_builder_overlay_index = wrapi(selected_builder_overlay_index + direction, 0, overlay_modes.size())
	_refresh_blueprint_visuals()
	_refresh_hud()

func _get_builder_overlay_value(cell_key: String, overlay_mode: String) -> float:
	if overlay_mode == "none":
		return 0.0
	var overlay_cells := NetworkRuntime.get_blueprint_overlay_cells()
	var cell_data: Dictionary = overlay_cells.get(cell_key, {})
	return clampf(float(cell_data.get(overlay_mode, 0.0)), 0.0, 1.0)

func _get_builder_overlay_color(base_color: Color, cell_key: String, overlay_mode: String) -> Color:
	var overlay_value := _get_builder_overlay_value(cell_key, overlay_mode)
	if overlay_mode == "none":
		return base_color
	match overlay_mode:
		"pathing":
			return base_color.lerp(Color(0.92, 0.84, 0.28), overlay_value)
		"recovery":
			return base_color.lerp(Color(0.20, 0.76, 0.72), overlay_value)
		"repair":
			return base_color.lerp(Color(0.26, 0.80, 0.48), overlay_value)
		"propulsion":
			return base_color.lerp(Color(0.90, 0.32, 0.24), overlay_value)
		"redundancy":
			return base_color.lerp(Color(0.22, 0.64, 0.84), overlay_value)
		"safety":
			return base_color.lerp(Color(0.72, 0.86, 0.30), overlay_value)
		_:
			return base_color

func _refresh_blueprint_visuals() -> void:
	for child in block_container.get_children():
		child.queue_free()
	block_visuals.clear()

	var loose_ids := Array(NetworkRuntime.boat_blueprint.get("loose_block_ids", []))
	var overlay_mode := _get_selected_builder_overlay_mode()
	for block_variant in Array(NetworkRuntime.boat_blueprint.get("blocks", [])):
		var block: Dictionary = block_variant
		var block_type := str(block.get("type", "structure"))
		var block_def := NetworkRuntime.get_builder_block_definition(block_type)
		var cell := _normalize_cell(block.get("cell", [0, 0, 0]))
		var cell_key := "%d:%d:%d" % [int(cell[0]), int(cell[1]), int(cell[2])]
		var block_node := Node3D.new()
		block_node.position = _cell_to_local_position(cell)
		block_node.rotation_degrees.y = float(int(block.get("rotation_steps", 0)) * 90)
		block_container.add_child(block_node)

		var mesh_instance := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3.ONE * BLOCK_CELL_SIZE
		mesh_instance.mesh = mesh
		var material := StandardMaterial3D.new()
		var base_color: Color = block_def.get("color", Color(0.7, 0.7, 0.7))
		if loose_ids.has(int(block.get("id", 0))):
			base_color = base_color.darkened(0.16).lerp(LOOSE_CHUNK_TINT, 0.28)
		else:
			base_color = base_color.lerp(MAIN_CHUNK_TINT, 0.08)
		base_color = _get_builder_overlay_color(base_color, cell_key, overlay_mode)
		BoatBlockMaterials.apply_wood(material, base_color, 0.48)
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
		box_shape.size = Vector3.ONE * BLOCK_CELL_SIZE
		collision_shape.shape = box_shape
		static_body.add_child(collision_shape)
		block_node.add_child(static_body)

		block_visuals[int(block.get("id", 0))] = block_node

func _refresh_cursor_visual() -> void:
	var block_id := _get_selected_block_id()
	var block_def := NetworkRuntime.get_builder_block_definition(block_id)
	var pulse_ratio := 0.0
	if HANGAR_CURSOR_PULSE_DURATION > 0.0:
		pulse_ratio = clampf(cursor_action_pulse_time / HANGAR_CURSOR_PULSE_DURATION, 0.0, 1.0)
	var pulse_amount := sin(pulse_ratio * PI)
	cursor_root.position = _cell_to_local_position([cursor_cell.x, cursor_cell.y, cursor_cell.z])
	cursor_root.rotation_degrees.y = float(selected_rotation_steps * 90)
	cursor_root.scale = Vector3.ONE * (1.0 + pulse_amount * 0.055)
	cursor_root.visible = cursor_has_target
	var box_mesh := cursor_mesh.mesh as BoxMesh
	if box_mesh != null:
		box_mesh.size = Vector3.ONE * BLOCK_CELL_SIZE * (1.05 + pulse_amount * 0.04)
	cursor_label.text = "%s • %s" % [
		str(block_def.get("label", block_id.capitalize())),
		_get_feedback_heading(cursor_feedback_state),
	]
	cursor_label.position = Vector3(0.0, BLOCK_CELL_SIZE * 0.82 + 0.42, 0.0)
	cursor_label.visible = cursor_has_target
	_refresh_cursor_face_marker()

	var material := StandardMaterial3D.new()
	material.albedo_color = _get_feedback_color(cursor_feedback_state)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.18
	material.emission_enabled = pulse_amount > 0.001
	material.emission = material.albedo_color.lightened(0.18)
	material.emission_energy_multiplier = pulse_amount * 0.55
	cursor_mesh.material_override = material
	if crosshair_label != null:
		crosshair_label.modulate = material.albedo_color.lightened(0.26)
		crosshair_label.visible = hangar_camera_dragging
	_refresh_local_builder_tool_visual()

func _refresh_cursor_face_marker() -> void:
	if cursor_face_marker == null:
		return
	cursor_face_marker.visible = cursor_has_target
	if not cursor_has_target:
		return
	var normal := cursor_face_normal
	var dominant_axis := Vector3(absf(normal.x), absf(normal.y), absf(normal.z))
	var pulse_ratio := 0.0
	if HANGAR_CURSOR_PULSE_DURATION > 0.0:
		pulse_ratio = clampf(cursor_action_pulse_time / HANGAR_CURSOR_PULSE_DURATION, 0.0, 1.0)
	var pulse_amount := sin(pulse_ratio * PI)
	var marker_size := Vector3(0.74, 0.06, 0.74) * BLOCK_CELL_SIZE
	if dominant_axis.x >= dominant_axis.y and dominant_axis.x >= dominant_axis.z:
		marker_size = Vector3(0.06, 0.74, 0.74) * BLOCK_CELL_SIZE
	elif dominant_axis.z >= dominant_axis.y:
		marker_size = Vector3(0.74, 0.74, 0.06) * BLOCK_CELL_SIZE
	var marker_mesh := cursor_face_marker.mesh as BoxMesh
	if marker_mesh != null:
		marker_mesh.size = marker_size * (1.0 + pulse_amount * 0.08)
	cursor_face_marker.position = -normal.normalized() * (BLOCK_CELL_SIZE * 0.52)
	var material := StandardMaterial3D.new()
	material.albedo_color = _get_feedback_color(cursor_feedback_state).lightened(0.08)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.12
	material.emission_enabled = pulse_amount > 0.001
	material.emission = material.albedo_color.lightened(0.12)
	material.emission_energy_multiplier = pulse_amount * 0.5
	cursor_face_marker.material_override = material

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
			return "%s at %s • LMB place%s" % [
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
	if visual_root.has_method("set_tool_color"):
		visual_root.call("set_tool_color", block_color.lightened(0.12))
	var tool := visual_root.get_node_or_null("Tool") as MeshInstance3D
	if tool != null:
		var tool_material := StandardMaterial3D.new()
		tool_material.albedo_color = block_color.lightened(0.12)
		tool_material.roughness = 0.24
		tool.material_override = tool_material

func _refresh_hud() -> void:
	var stats := NetworkRuntime.get_blueprint_stats()
	var overlay_mode := _get_selected_builder_overlay_mode()
	var warnings := NetworkRuntime.get_blueprint_warnings()
	var warning_lines := PackedStringArray()
	for warning in warnings:
		warning_lines.append("- %s" % str(warning))
	if warning_lines.is_empty():
		warning_lines.append("- No major warnings. This hull is ready to sail.")
	var overlay_label := overlay_mode.replace("_", " ").capitalize()
	var overlay_summary := "Overlay %s | Pathing %.0f | Recovery %.0f | Repair %.0f%% | Exposure %.0f | Redundancy %.0f" % [
		overlay_label,
		float(stats.get("pathing_score", 0.0)),
		float(stats.get("recovery_access_rating", 0.0)),
		float(stats.get("repair_coverage", 0.0)),
		float(stats.get("propulsion_exposure_rating", 0.0)),
		float(stats.get("damage_redundancy", 0.0)),
	]
	var previous_block_id := _get_selected_block_id()
	_refresh_block_palette_menu()
	var block_id := _get_selected_block_id()
	var block_def := NetworkRuntime.get_builder_block_definition(block_id)
	if block_id != previous_block_id:
		_refresh_cursor_visual()
	var filtered_block_ids := _get_filtered_builder_block_ids()
	var palette_index := maxi(0, filtered_block_ids.find(block_id))
	var palette_count := maxi(1, filtered_block_ids.size())
	onboarding_label.text = _build_onboarding_text().trim_prefix("Onboarding: ").strip_edges()
	hud_icons.set_icon(selection_icon, hud_icons.get_block_icon_id(block_id))
	hud_icons.set_icon(build_focus_icon, hud_icons.get_block_icon_id(block_id))
	hud_icons.set_icon(builder_icon, hud_icons.get_block_icon_id(block_id))
	var active_tool_id := _get_selected_hangar_tool_id()
	var active_tool_label := _get_hangar_tool_label(active_tool_id)
	selection_label.text = "%s | %s %d/%d\nHull %.0f | Float %.1f | Thrust %.1f | Cargo %d" % [
		active_tool_label,
		_get_palette_category_label(selected_palette_category),
		palette_index + 1,
		palette_count,
		float(block_def.get("max_hp", 0.0)),
		float(block_def.get("buoyancy", 0.0)),
		float(block_def.get("thrust", 0.0)),
		int(block_def.get("cargo", 0)),
	]
	if build_focus_part_label != null:
		build_focus_part_label.text = "%s | %s | %s" % [
			str(block_def.get("label", block_id.capitalize())),
			_format_block_family_label(str(block_def.get("family", "utility"))),
			active_tool_label,
		]
	if build_focus_state_label != null:
		build_focus_state_label.text = _build_focus_state_text(block_def, stats)
	if build_focus_hint_label != null:
		build_focus_hint_label.text = _build_focus_hint_text(block_def, stats, warnings)

	target_label.text = "Placement\n%s\n%s" % [
		_get_feedback_heading(cursor_feedback_state),
		_get_local_target_compact_text(),
	]

	builder_label.text = "Blueprint v%d | Blocks %d | Main %d | Loose %d\nHull %.0f | Speed %.1f | Accel %.0f | Turn %.0f\n%s | Crew %d | Workload %.0f | Drive HP %.0f\nCargo %d | Kits %d | Brace x%.2f | Margin %.1f\nSafety %.0f | Stability %.0f | Repair %.0f%% | Recovery %.0f\nExposure %.0f | Redundancy %.0f | Salvage %d | Overlay %s" % [
		int(NetworkRuntime.boat_blueprint.get("version", 1)),
		int(stats.get("block_count", 0)),
		int(stats.get("main_chunk_blocks", 0)),
		int(stats.get("loose_blocks", 0)),
		float(stats.get("max_hull_integrity", 0.0)),
		float(stats.get("top_speed", 0.0)),
		float(stats.get("acceleration", 0.0)),
		float(stats.get("turn_authority", 0.0)),
		str(stats.get("propulsion_label", NetworkRuntime.get_propulsion_family_label(str(stats.get("propulsion_family", NetworkRuntime.PROPULSION_FAMILY_RAFT_PADDLES))))),
		int(stats.get("recommended_crew", 1)),
		float(stats.get("workload", 0.0)),
		float(stats.get("propulsion_health_rating", 0.0)),
		int(stats.get("cargo_capacity", 0)),
		int(stats.get("repair_capacity", 0)),
		float(stats.get("brace_multiplier", 1.0)),
		float(stats.get("buoyancy_margin", 0.0)),
		float(stats.get("crew_safety", 0.0)),
		float(stats.get("storm_stability", 0.0)),
		float(stats.get("repair_coverage", 0.0)),
		float(stats.get("recovery_access_rating", 0.0)),
		float(stats.get("propulsion_exposure_rating", 0.0)),
		float(stats.get("damage_redundancy", 0.0)),
		int(stats.get("salvage_station_count", 0)),
		overlay_label,
	]
	var readiness_snapshot := _get_launch_readiness_snapshot(stats, warnings)
	hud_icons.set_icon(
		launch_readiness_icon,
		"brace" if str(readiness_snapshot.get("button_text", "")).contains("Risky") or str(readiness_snapshot.get("button_text", "")).contains("Loose") else "extraction"
	)
	launch_readiness_label.text = _build_launch_readiness_summary(readiness_snapshot)
	launch_readiness_label.modulate = readiness_snapshot.get("color", Color(0.98, 0.97, 0.92))
	var warning_preview := PackedStringArray()
	for warning_line in warning_lines:
		if warning_preview.size() >= 3:
			break
		warning_preview.append(str(warning_line))
	warning_label.text = "Top risks\n%s\n%s" % [
		"\n".join(warning_preview),
		overlay_summary,
	]
	var mouse_hint := "Hold RMB to orbit the camera." if hangar_camera_dragging else "Cursor free: aim with the mouse, LMB to use the tool, hold RMB to orbit."
	var status_body := NetworkRuntime.status_message
	if launch_transition_pending:
		status_body = "Preparing the run. Charting the sea and loading the next scene."
	status_label.text = _build_dock_status_text(status_body)
	launch_button.disabled = launch_transition_pending or NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR
	launch_button.text = "Launching..." if launch_transition_pending else _build_launch_button_label(readiness_snapshot)
	launch_button.tooltip_text = "\n".join(warning_lines)
	if sea_test_button != null:
		sea_test_button.disabled = launch_transition_pending or NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR
		sea_test_button.text = "Sea Test Hull" if _blueprint_is_default_core() else "Sea Test"
		sea_test_button.tooltip_text = _build_sea_test_tooltip()
	if reset_button != null:
		var block_count := Array(NetworkRuntime.boat_blueprint.get("blocks", [])).size()
		reset_button.disabled = launch_transition_pending or NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR or block_count <= 1
		reset_button.text = "Reset Boat"
		reset_button.tooltip_text = "Reset the hangar boat to a single core block."

	var progression_snapshot := _get_progression_snapshot()
	var local_profile := DockState.get_local_profile_snapshot()
	var total_runs := int(progression_snapshot.get("total_runs", 0))
	var successful_runs := int(progression_snapshot.get("successful_runs", 0))
	var extraction_rate := 0.0
	if total_runs > 0:
		extraction_rate = float(successful_runs) / float(total_runs) * 100.0
	var unlocked_blocks := Array(progression_snapshot.get("unlocked_blocks", []))
	var local_known_schematics := Array(local_profile.get("known_schematics", []))
	var repair_debt := Dictionary(progression_snapshot.get("repair_debt", {}))
	hud_icons.set_icon(profile_icon, "gold")
	profile_label.text = "Stash %d gold | %d mats | Schematics %d\nWorkshop %d gold | Parts %d/%d | Debt %s" % [
		int(local_profile.get("total_gold", 0)),
		DockState.get_total_salvage(),
		local_known_schematics.size(),
		int(progression_snapshot.get("workshop_gold", 0)),
		unlocked_blocks.size(),
		NetworkRuntime.BUILDER_BLOCK_ORDER.size(),
		str(repair_debt.get("severity", "clear")).capitalize(),
	]
	var store_entries := NetworkRuntime.get_builder_store_entries()
	if store_entries.is_empty():
		hud_icons.set_icon(store_icon, "salvage")
		store_label.text = "Workshop stocked.\nAll current prototype parts are already craftable."
		if unlock_button != null:
			unlock_button.disabled = true
			unlock_button.text = "Workshop Clear"
	else:
		selected_store_index = wrapi(selected_store_index, 0, store_entries.size())
		var selected_store_entry: Dictionary = store_entries[selected_store_index]
		var selected_unlocked := bool(selected_store_entry.get("unlocked", false))
		var selected_affordable := bool(selected_store_entry.get("affordable", false))
		var schematic_text := "Known" if bool(selected_store_entry.get("schematic_known", true)) else "Missing"
		var missing_tokens := PackedStringArray()
		if int(selected_store_entry.get("missing_gold", 0)) > 0:
			missing_tokens.append("%d gold" % int(selected_store_entry.get("missing_gold", 0)))
		for material_id_variant in Dictionary(selected_store_entry.get("missing_materials", {})).keys():
			var material_id := str(material_id_variant)
			missing_tokens.append("%s x%d" % [
				str(NetworkRuntime.MATERIAL_LABELS.get(material_id, material_id.capitalize())),
				int(Dictionary(selected_store_entry.get("missing_materials", {})).get(material_id, 0)),
			])
		var entry_status := "Crafted" if selected_unlocked else ("Ready" if selected_affordable else "Blocked")
		var cost_tokens := PackedStringArray()
		var recipe_gold := int(selected_store_entry.get("recipe_gold", 0))
		if recipe_gold > 0:
			cost_tokens.append("%d gold" % recipe_gold)
		for material_id_variant in Dictionary(selected_store_entry.get("recipe_materials", {})).keys():
			var material_id := str(material_id_variant)
			var quantity := int(Dictionary(selected_store_entry.get("recipe_materials", {})).get(material_id, 0))
			if quantity <= 0:
				continue
			cost_tokens.append("%s x%d" % [str(NetworkRuntime.MATERIAL_LABELS.get(material_id, material_id.capitalize())), quantity])
		var missing_text := "None" if missing_tokens.is_empty() else ", ".join(missing_tokens)
		hud_icons.set_icon(store_icon, hud_icons.get_block_icon_id(str(selected_store_entry.get("block_id", ""))))
		store_label.text = "%s | Recipe %d/%d\n%s | Schematic %s\nCost %s\nNeed %s" % [
			str(selected_store_entry.get("label", "Part")),
			selected_store_index + 1,
			store_entries.size(),
			entry_status,
			schematic_text,
			", ".join(cost_tokens) if not cost_tokens.is_empty() else "Free",
			missing_text,
		]
		if unlock_button != null:
			unlock_button.disabled = NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR or selected_unlocked or not selected_affordable
			unlock_button.text = "Already Crafted" if selected_unlocked else "Craft %s" % str(selected_store_entry.get("label", "Part"))

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
	roster_label.text = "Crew in yard (%d)\n%s" % [NetworkRuntime.get_player_peer_ids().size(), "\n".join(crew_lines)]

	var last_run := Dictionary(progression_snapshot.get("last_run", {}))
	var last_unlock := Dictionary(progression_snapshot.get("last_unlock", {}))
	if last_run.is_empty():
		hud_icons.set_icon(last_run_icon, "cargo")
		last_run_label.text = "No runs banked yet."
	else:
		hud_icons.set_icon(last_run_icon, "salvage")
		var reward_items := Dictionary(last_run.get("reward_items", {}))
		var lost_items := Dictionary(last_run.get("loot_lost_items", {}))
		last_run_label.text = "%s\nGold %d | Mats %d | Schematics %d\nSecured %d | Lost %d | Logged %s" % [
			str(last_run.get("title", "Run Complete")),
			int(last_run.get("reward_gold", 0)),
			NetworkRuntime._sum_material_dict_ui(reward_items),
			Array(last_run.get("reward_schematics", [])).size(),
			int(last_run.get("cargo_secured", 0)),
			int(last_run.get("cargo_lost", 0)),
			str(last_run.get("timestamp", "")),
		]
		if not lost_items.is_empty():
			last_run_label.text += "\nLost haul %d mats" % NetworkRuntime._sum_material_dict_ui(lost_items)
	if not last_unlock.is_empty():
		last_run_label.text += "\nLast craft %s for %d gold" % [
			str(last_unlock.get("label", "Part")),
			int(last_unlock.get("cost_gold", 0)),
		]

	_refresh_hangar_tool_slots()
	_refresh_block_strip_slots()
	toolbelt_label.text = _build_hangar_toolbelt_text()
	inventory_label.text = _build_hangar_inventory_text()
	controls_label.text = "LMB click use | Hold LMB paint | Hold RMB camera | Wheel part | R rotate | 1/2/3 tools | I locker\n%s" % mouse_hint
	_apply_hud_visibility()

func _build_onboarding_text() -> String:
	if cursor_feedback_state == "range":
		return "Onboarding: Move closer before placing. Position matters in this shared build yard."
	if cursor_feedback_state == "occupied":
		return "Onboarding: That cell is taken. Rotate, remove, or pick a fresh face on the hull."
	if not cursor_has_target:
		return "Onboarding: Point at the dock or boat, click to place one block, or hold to paint. Hold right mouse to steer the camera."

	var stats := NetworkRuntime.get_blueprint_stats()
	if int(stats.get("loose_blocks", 0)) > 0:
		return "Onboarding: Loose chunks are allowed, but they will sink the moment the run starts."
	if Array(NetworkRuntime.get_builder_store_entries()).size() > 0:
		return "Onboarding: Press I to open the part palette and workshop locker. Click a crafted part to equip it, then use Z/C for recipes, B/N for donations, G to donate, and V to craft."
	return "Onboarding: Press I to open the part palette, pick a part, then click to place or hold to paint while keeping the main chunk floaty."

func _get_hangar_tool_label(tool_id: String) -> String:
	for tool_variant in _get_hangar_toolbelt_entries():
		var tool: Dictionary = tool_variant
		if str(tool.get("id", "")) == tool_id:
			return str(tool.get("label", tool_id.capitalize()))
	return tool_id.capitalize()

func _get_hangar_tool_accent(tool_id: String) -> Color:
	match tool_id:
		"build":
			return ExpeditionHudSkin.OXIDIZED_TEAL
		"remove":
			return ExpeditionHudSkin.BUOY_ORANGE
		"yard":
			return ExpeditionHudSkin.BRASS_YELLOW
		_:
			return ExpeditionHudSkin.TEXT_MUTED

func _refresh_hangar_tool_slots() -> void:
	var entries := _get_hangar_toolbelt_entries()
	for slot_index in range(hangar_tool_slot_panels.size()):
		var slot_panel := hangar_tool_slot_panels[slot_index] as PanelContainer
		var key_label := hangar_tool_slot_key_labels[slot_index] as Label
		var name_label := hangar_tool_slot_name_labels[slot_index] as Label
		var slot_icon := hangar_tool_slot_icons[slot_index] as TextureRect
		if slot_index >= entries.size():
			if slot_panel != null:
				slot_panel.visible = false
			continue
		var entry: Dictionary = entries[slot_index]
		var tool_id := str(entry.get("id", ""))
		var is_active := slot_index == selected_hangar_tool_index
		var accent_color := _get_hangar_tool_accent(tool_id)
		ExpeditionHudSkin.apply_hotbar_slot(slot_panel, accent_color, is_active, false)
		if key_label != null:
			key_label.text = str(slot_index + 1)
			key_label.modulate = ExpeditionHudSkin.TEXT_PRIMARY if is_active else ExpeditionHudSkin.TEXT_MUTED
		if name_label != null:
			name_label.text = str(entry.get("label", "Tool")).to_upper()
			name_label.modulate = ExpeditionHudSkin.TEXT_PRIMARY if is_active else ExpeditionHudSkin.TEXT_MUTED
		if slot_icon != null:
			hud_icons.set_icon(slot_icon, str(entry.get("icon", "")))
			slot_icon.modulate = accent_color.lightened(0.08) if is_active else ExpeditionHudSkin.TEXT_MUTED

func _ensure_block_strip_row(layout: VBoxContainer) -> void:
	if layout == null or not block_strip_slot_panels.is_empty():
		return
	var strip_row := HBoxContainer.new()
	strip_row.name = "BlockStripRow"
	strip_row.alignment = BoxContainer.ALIGNMENT_CENTER
	strip_row.add_theme_constant_override("separation", 6)
	layout.add_child(strip_row)
	layout.move_child(strip_row, 1)
	for slot_index in range(5):
		var slot_panel := PanelContainer.new()
		slot_panel.name = "BlockSlot%d" % [slot_index + 1]
		slot_panel.custom_minimum_size = Vector2(72.0, 58.0)
		strip_row.add_child(slot_panel)
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 6)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_right", 6)
		margin.add_theme_constant_override("margin_bottom", 4)
		slot_panel.add_child(margin)
		var slot_layout := VBoxContainer.new()
		slot_layout.add_theme_constant_override("separation", 2)
		margin.add_child(slot_layout)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(30.0, 30.0)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slot_layout.add_child(icon)
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		slot_layout.add_child(label)
		block_strip_slot_panels.append(slot_panel)
		block_strip_slot_icons.append(icon)
		block_strip_slot_labels.append(label)

func _refresh_block_strip_slots() -> void:
	if block_strip_slot_panels.is_empty():
		return
	var visible_block_ids := _get_filtered_builder_block_ids()
	if visible_block_ids.is_empty():
		visible_block_ids = NetworkRuntime.get_builder_block_ids()
	var selected_block_id := _get_selected_block_id()
	var selected_visible_index := maxi(0, visible_block_ids.find(selected_block_id))
	var slot_count := block_strip_slot_panels.size()
	var start_index := maxi(0, selected_visible_index - int(slot_count / 2))
	if visible_block_ids.size() > slot_count:
		start_index = mini(start_index, visible_block_ids.size() - slot_count)
	for slot_index in range(slot_count):
		var panel := block_strip_slot_panels[slot_index] as PanelContainer
		var icon := block_strip_slot_icons[slot_index] as TextureRect
		var label := block_strip_slot_labels[slot_index] as Label
		var block_list_index := start_index + slot_index
		if block_list_index >= visible_block_ids.size():
			panel.visible = false
			continue
		panel.visible = true
		var block_id := str(visible_block_ids[block_list_index])
		var block_def := NetworkRuntime.get_builder_block_definition(block_id)
		var is_selected := block_id == selected_block_id
		var accent_color: Color = block_def.get("color", ExpeditionHudSkin.OXIDIZED_TEAL)
		ExpeditionHudSkin.apply_hotbar_slot(panel, accent_color, is_selected, false)
		if icon != null:
			hud_icons.set_icon(icon, hud_icons.get_block_icon_id(block_id))
			icon.modulate = Color.WHITE if is_selected else ExpeditionHudSkin.TEXT_MUTED
		if label != null:
			var short_label := str(block_def.get("label", block_id.capitalize())).substr(0, 10)
			label.text = short_label.to_upper()
			label.modulate = ExpeditionHudSkin.TEXT_PRIMARY if is_selected else ExpeditionHudSkin.TEXT_MUTED

func _build_hangar_toolbelt_text() -> String:
	var entries := _get_hangar_toolbelt_entries()
	if not entries.is_empty():
		selected_hangar_tool_index = wrapi(selected_hangar_tool_index, 0, entries.size())
	var selected_entry: Dictionary = entries[selected_hangar_tool_index] if not entries.is_empty() else {}
	return str(selected_entry.get("hint", "Place the selected part into the aimed cell."))

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
	var local_stash_lines := PackedStringArray()
	for entry_variant in Array(snapshot.get("local_stash_manifest", [])):
		var entry: Dictionary = entry_variant
		local_stash_lines.append("- %s x%d" % [
			str(entry.get("label", "Resource")),
			int(entry.get("quantity", 0)),
		])
	if local_stash_lines.is_empty():
		local_stash_lines.append("- Personal stash is empty.")
	var workshop_lines := PackedStringArray()
	for entry_variant in Array(snapshot.get("workshop_manifest", [])):
		var entry: Dictionary = entry_variant
		workshop_lines.append("- %s x%d" % [
			str(entry.get("label", "Resource")),
			int(entry.get("quantity", 0)),
		])
	if workshop_lines.is_empty():
		workshop_lines.append("- Host workshop is empty.")
	var known_schematics := PackedStringArray()
	for schematic_variant in Array(snapshot.get("local_known_schematics", [])):
		var schematic_id := str(schematic_variant)
		var block_def := NetworkRuntime.get_builder_block_definition(schematic_id)
		known_schematics.append(str(block_def.get("label", schematic_id.capitalize())))
	if known_schematics.is_empty():
		known_schematics.append("None yet")
	var store_entries := Array(snapshot.get("store_entries", []))
	var next_unlock_text := "All current prototype parts crafted."
	if not store_entries.is_empty():
		var next_entry: Dictionary = store_entries[selected_store_index % store_entries.size()]
		var donation_entries := _get_donatable_resource_entries()
		if not donation_entries.is_empty():
			selected_donation_index = wrapi(selected_donation_index, 0, donation_entries.size())
		var selected_donation: Dictionary = {}
		if not donation_entries.is_empty():
			selected_donation = donation_entries[selected_donation_index]
		next_unlock_text = "%s for %d gold | Donate: %s x%d" % [
			str(next_entry.get("label", "Part")),
			int(next_entry.get("recipe_gold", 0)),
			str(selected_donation.get("label", "Nothing")),
			int(selected_donation.get("quantity", 0)),
		]
	var stats: Dictionary = snapshot.get("stats", {})
	var repair_debt := Dictionary(snapshot.get("repair_debt", {}))
	return "On You\n%s\nStash\n%s\nHost Workshop\n%s\nSchematics: %s\nMounted Parts\n%s\nNext Craft / Donation: %s\nRepair Debt: %s\nBlueprint: %s | Cargo %d | Patch Kits %d | Workload %.0f | Crew %d\nSafety %.0f | Drive HP %.0f | Recovery %.0f | Redundancy %.0f | Pathing %.0f\nMain %d | Loose %d" % [
		"\n".join(tool_lines),
		"\n".join(local_stash_lines),
		"\n".join(workshop_lines),
		", ".join(known_schematics),
		"\n".join(manifest_lines),
		next_unlock_text,
		str(repair_debt.get("summary", "No repair debt.")),
		str(stats.get("propulsion_label", NetworkRuntime.get_propulsion_family_label(str(stats.get("propulsion_family", NetworkRuntime.PROPULSION_FAMILY_RAFT_PADDLES))))),
		int(stats.get("cargo_capacity", 0)),
		int(stats.get("repair_capacity", 0)),
		float(stats.get("workload", 0.0)),
		int(stats.get("recommended_crew", 1)),
		float(stats.get("crew_safety", 0.0)),
		float(stats.get("propulsion_health_rating", 0.0)),
		float(stats.get("recovery_access_rating", 0.0)),
		float(stats.get("damage_redundancy", 0.0)),
		float(stats.get("pathing_score", 0.0)),
		int(stats.get("main_chunk_blocks", 0)),
		int(stats.get("loose_blocks", 0)),
	]

func _build_launch_readiness_summary(snapshot: Dictionary) -> String:
	var title := str(snapshot.get("title", "Ready To Sail"))
	match title:
		"Risky Launch":
			return "Risky launch\nNeeds support, buoyancy, or routing."
		"Loose Chunks Detected":
			return "Loose chunks\nDetached pieces will sink on launch."
		"Ready, But Spicy":
			return "Ready with risk\nRecovery and repair still matter."
		_:
			return "Ready to sail\nStable enough to launch."

func _format_block_family_label(family: String) -> String:
	return family.replace("_", " ").capitalize()

func _build_focus_state_text(block_def: Dictionary, stats: Dictionary) -> String:
	var tokens := PackedStringArray()
	tokens.append(_get_feedback_heading(cursor_feedback_state))
	tokens.append(str(stats.get("hydrostatic_class", "stable")).capitalize())
	tokens.append("Margin %.1f" % float(stats.get("reserve_buoyancy", stats.get("buoyancy_margin", 0.0))))
	tokens.append("Draft %d%%" % int(round(float(stats.get("draft_ratio", 0.0)) * 100.0)))
	tokens.append("Rot %d" % (selected_rotation_steps * 90))
	var thrust := float(block_def.get("thrust", 0.0))
	if thrust > 0.05:
		tokens.append("Thrust %.1f" % thrust)
	var repair := int(block_def.get("repair", 0))
	if repair > 0:
		tokens.append("Kits +%d" % repair)
	return " | ".join(tokens)

func _build_focus_hint_text(block_def: Dictionary, stats: Dictionary, warnings: Array) -> String:
	var repair := int(block_def.get("repair", 0))
	var warning_preview := _build_focus_warning_preview(stats, warnings)
	match cursor_feedback_state:
		"range":
			return "Move closer | Hold RMB camera | Wheel/QE part | I locker"
		"occupied":
			return "Cell taken | Use remove tool or X | R rotate | Wheel/QE part"
		"blocked":
			return "Outside build area | Step back toward the dock"
		_:
			var tokens := PackedStringArray([
				warning_preview,
				"LMB place/use",
				"Hold RMB camera",
				"R rotate",
				"X remove",
				"Wheel/QE part",
				"I locker",
			])
			if repair > 0:
				tokens.append("+%d kits" % repair)
			var filtered := PackedStringArray()
			for token_variant in tokens:
				var token := str(token_variant).strip_edges()
				if token.is_empty():
					continue
				filtered.append(token)
			return " | ".join(filtered)

func _build_focus_warning_preview(stats: Dictionary, warnings: Array) -> String:
	var preview := PackedStringArray()
	var hydro_class := str(stats.get("hydrostatic_class", "stable"))
	if hydro_class != "stable":
		preview.append(hydro_class.capitalize())
	for warning_variant in warnings:
		var warning := str(warning_variant).strip_edges()
		if warning.is_empty() or preview.has(warning):
			continue
		preview.append(warning)
		if preview.size() >= 2:
			break
	return " | ".join(preview)

func _get_launch_readiness_snapshot(stats: Dictionary, warnings: Array) -> Dictionary:
	var loose_blocks := int(stats.get("loose_blocks", 0))
	var buoyancy_margin := float(stats.get("reserve_buoyancy", stats.get("buoyancy_margin", 0.0)))
	var crew_safety := float(stats.get("crew_safety", 0.0))
	var propulsion_health := float(stats.get("propulsion_health_rating", 0.0))
	var workload := float(stats.get("workload", 0.0))
	var recovery_access := float(stats.get("recovery_access_rating", 0.0))
	var pathing_score := float(stats.get("pathing_score", 0.0))
	var redundancy := float(stats.get("damage_redundancy", 0.0))
	var draft_ratio := float(stats.get("draft_ratio", 0.0))
	var freeboard_rating := float(stats.get("freeboard_rating", 100.0))
	var hydro_class := str(stats.get("hydrostatic_class", "stable"))
	var seaworthy := bool(NetworkRuntime.boat_blueprint.get("seaworthy", false))
	if not seaworthy or hydro_class == "sinking":
		return {
			"title": "Risky Launch",
			"detail": "Your main chunk is missing required machine support, float margin, or routeing. It will still launch, but one early mistake could collapse the run.",
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
	if hydro_class == "unstable" or buoyancy_margin < 2.0 or draft_ratio > 0.92 or freeboard_rating < 42.0 or crew_safety < 45.0 or propulsion_health < 45.0 or recovery_access < 45.0 or pathing_score < 45.0 or redundancy < 40.0 or workload >= 70.0 or not warnings.is_empty():
		return {
			"title": "Ready, But Spicy",
			"detail": "This boat can sail, but the machine is demanding. Recovery routes, redundancy, propulsion protection, and repair timing will matter.",
			"color": Color(0.86, 0.95, 0.61),
			"button_text": "Launch Run",
		}
	return {
		"title": "Ready To Sail",
		"detail": "Main chunk is connected, the propulsion package is readable, and the crew load looks manageable.",
		"color": Color(0.72, 0.96, 0.78),
		"button_text": "Launch Run",
	}

func _update_build_target_from_camera() -> void:
	if camera == null or local_avatar_body == null:
		return
	var next_state := _apply_cursor_target_stickiness(_query_build_target_from_camera())
	var next_cursor_has_target := bool(next_state.get("has_target", false))
	var next_cursor_cell: Vector3i = _variant_to_cell_vector(next_state.get("place_cell", cursor_cell))
	var next_remove_cell: Vector3i = _variant_to_cell_vector(next_state.get("remove_cell", remove_cursor_cell))
	var next_cursor_can_place := bool(next_state.get("can_place", false))
	var next_cursor_can_remove := bool(next_state.get("can_remove", false))
	var next_feedback_state := str(next_state.get("feedback_state", "hidden"))
	var next_cursor_target_label := str(next_state.get("label", "Aim at the boat or dock"))
	var next_cursor_face_normal: Vector3 = next_state.get("face_normal", cursor_face_normal)
	if next_cursor_has_target == cursor_has_target and next_cursor_cell == cursor_cell and next_remove_cell == remove_cursor_cell and next_cursor_can_place == cursor_can_place and next_cursor_can_remove == cursor_can_remove and next_feedback_state == cursor_feedback_state and next_cursor_target_label == cursor_target_label and next_cursor_face_normal.is_equal_approx(cursor_face_normal):
		return
	cursor_has_target = next_cursor_has_target
	cursor_cell = next_cursor_cell
	remove_cursor_cell = next_remove_cell
	cursor_can_place = next_cursor_can_place
	cursor_can_remove = next_cursor_can_remove
	cursor_feedback_state = next_feedback_state
	cursor_target_label = next_cursor_target_label
	cursor_face_normal = next_cursor_face_normal
	_refresh_cursor_visual()
	_refresh_hud()
	avatar_sync_timer = 0.0

func _build_current_cursor_target_state() -> Dictionary:
	return {
		"has_target": cursor_has_target,
		"place_cell": cursor_cell,
		"remove_cell": remove_cursor_cell,
		"can_place": cursor_can_place,
		"can_remove": cursor_can_remove,
		"feedback_state": cursor_feedback_state,
		"label": cursor_target_label,
		"face_normal": cursor_face_normal,
	}

func _clear_hangar_drag_plane_lock() -> void:
	hangar_drag_plane_active = false
	hangar_drag_plane_axis = -1
	hangar_drag_plane_coordinate = 0
	hangar_drag_plane_face_sign = 0
	hangar_drag_plane_tool_id = ""

func _begin_hangar_drag_plane_lock() -> void:
	_clear_hangar_drag_plane_lock()
	if inventory_panel_visible or not cursor_has_target:
		return
	var tool_id := _get_selected_hangar_tool_id()
	if tool_id == "yard":
		return
	var axis_step := _normal_to_cell_step(cursor_face_normal)
	var axis_index := _get_dominant_axis_index(axis_step)
	if axis_index == -1:
		return
	var action_cell := cursor_cell if tool_id != "remove" else remove_cursor_cell
	hangar_drag_plane_active = true
	hangar_drag_plane_axis = axis_index
	hangar_drag_plane_coordinate = _get_cell_axis_value(action_cell, axis_index)
	hangar_drag_plane_face_sign = _get_cell_axis_value(axis_step, axis_index)
	hangar_drag_plane_tool_id = tool_id

func _get_dominant_axis_index(cell_value: Variant) -> int:
	var cell := _variant_to_cell_vector(cell_value)
	if cell.x != 0:
		return 0
	if cell.y != 0:
		return 1
	if cell.z != 0:
		return 2
	return -1

func _get_cell_axis_value(cell_value: Variant, axis_index: int) -> int:
	var cell := _variant_to_cell_vector(cell_value)
	match axis_index:
		0:
			return cell.x
		1:
			return cell.y
		2:
			return cell.z
		_:
			return 0

func _state_matches_drag_plane_lock(state: Dictionary) -> bool:
	if not hangar_drag_plane_active or not bool(state.get("has_target", false)):
		return false
	var state_tool_id := hangar_drag_plane_tool_id if not hangar_drag_plane_tool_id.is_empty() else _get_selected_hangar_tool_id()
	var axis_step := _normal_to_cell_step(Vector3(state.get("face_normal", Vector3.UP)))
	var axis_index := _get_dominant_axis_index(axis_step)
	if axis_index != hangar_drag_plane_axis:
		return false
	if hangar_drag_plane_face_sign != 0 and _get_cell_axis_value(axis_step, axis_index) != hangar_drag_plane_face_sign:
		return false
	var action_cell := _variant_to_cell_vector(state.get("place_cell", Vector3i.ZERO))
	if state_tool_id == "remove":
		action_cell = _variant_to_cell_vector(state.get("remove_cell", Vector3i.ZERO))
	return _get_cell_axis_value(action_cell, axis_index) == hangar_drag_plane_coordinate

func _cursor_states_match(left: Dictionary, right: Dictionary) -> bool:
	if bool(left.get("has_target", false)) != bool(right.get("has_target", false)):
		return false
	if not bool(left.get("has_target", false)):
		return str(left.get("feedback_state", "hidden")) == str(right.get("feedback_state", "hidden"))
	return (
		_variant_to_cell_vector(left.get("place_cell", Vector3i.ZERO)) == _variant_to_cell_vector(right.get("place_cell", Vector3i.ZERO))
		and _variant_to_cell_vector(left.get("remove_cell", Vector3i.ZERO)) == _variant_to_cell_vector(right.get("remove_cell", Vector3i.ZERO))
		and str(left.get("feedback_state", "hidden")) == str(right.get("feedback_state", "hidden"))
		and Vector3(left.get("face_normal", Vector3.UP)).is_equal_approx(Vector3(right.get("face_normal", Vector3.UP)))
	)

func _should_apply_cursor_stickiness(current_state: Dictionary, next_state: Dictionary) -> bool:
	if not bool(current_state.get("has_target", false)) or not bool(next_state.get("has_target", false)):
		return false
	var current_place := _variant_to_cell_vector(current_state.get("place_cell", Vector3i.ZERO))
	var next_place := _variant_to_cell_vector(next_state.get("place_cell", Vector3i.ZERO))
	var current_remove := _variant_to_cell_vector(current_state.get("remove_cell", Vector3i.ZERO))
	var next_remove := _variant_to_cell_vector(next_state.get("remove_cell", Vector3i.ZERO))
	if current_place == next_place or current_remove == next_remove:
		return true
	return _cell_to_world_position(current_place).distance_to(_cell_to_world_position(next_place)) <= (BLOCK_CELL_SIZE * 1.05)

func _apply_cursor_target_stickiness(next_state: Dictionary) -> Dictionary:
	var current_state := _build_current_cursor_target_state()
	if hangar_tool_mouse_down and _state_matches_drag_plane_lock(current_state) and not _state_matches_drag_plane_lock(next_state):
		return current_state
	if not _should_apply_cursor_stickiness(current_state, next_state):
		cursor_switch_candidate.clear()
		cursor_switch_candidate_started_at = 0.0
		return next_state
	if _cursor_states_match(current_state, next_state):
		cursor_switch_candidate.clear()
		cursor_switch_candidate_started_at = 0.0
		return next_state
	if not _cursor_states_match(cursor_switch_candidate, next_state):
		cursor_switch_candidate = next_state.duplicate(true)
		cursor_switch_candidate_started_at = connect_time_seconds
		return current_state
	if connect_time_seconds - cursor_switch_candidate_started_at < HANGAR_CURSOR_SWITCH_STICKINESS:
		return current_state
	cursor_switch_candidate.clear()
	cursor_switch_candidate_started_at = 0.0
	return next_state

func _query_build_target_from_camera() -> Dictionary:
	if NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR:
		return {
			"has_target": false,
			"feedback_state": "hidden",
			"label": "Run in progress",
		}
	var viewport_rect := get_viewport().get_visible_rect()
	var screen_target := viewport_rect.size * 0.5
	if not hangar_camera_dragging and not _is_mouse_captured():
		screen_target = get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(screen_target)
	var ray_direction := camera.project_ray_normal(screen_target)
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
		"face_normal": hit_normal,
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
	if inventory_panel_visible:
		_set_mouse_capture(false)
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

func _apply_hangar_pointer_tool(force_single: bool) -> void:
	var tool_id := _get_selected_hangar_tool_id()
	if tool_id == "yard":
		if force_single:
			_purchase_selected_unlock()
		return
	var action_cell := cursor_cell if tool_id != "remove" else remove_cursor_cell
	var action_key := "%s:%d:%d:%d" % [tool_id, action_cell.x, action_cell.y, action_cell.z]
	if not force_single and hangar_hold_action_cooldown > 0.0 and action_key == hangar_last_drag_action_key:
		return
	var acted := false
	match tool_id:
		"remove":
			acted = _remove_selected_block()
		_:
			acted = _place_selected_block()
	if acted:
		hangar_hold_action_cooldown = HANGAR_POINTER_REPEAT_INTERVAL
		hangar_last_drag_action_key = action_key
		cursor_action_pulse_time = HANGAR_CURSOR_PULSE_DURATION
		_refresh_cursor_visual()

func _process_drag_building(delta: float) -> void:
	if not hangar_tool_mouse_down or inventory_panel_visible or hangar_camera_dragging:
		return
	hangar_tool_hold_time += maxf(delta, 0.0)
	if not hangar_tool_repeat_armed:
		if hangar_tool_hold_time < HANGAR_POINTER_REPEAT_DELAY:
			return
		hangar_tool_repeat_armed = true
		hangar_hold_action_cooldown = 0.0
	_apply_hangar_pointer_tool(false)

func _cycle_block(direction: int) -> void:
	var block_ids := _get_filtered_builder_block_ids() if inventory_panel_visible else NetworkRuntime.get_builder_block_ids()
	if block_ids.is_empty():
		return
	var current_block_id := _get_selected_block_id()
	var current_index := block_ids.find(current_block_id)
	if current_index == -1:
		current_index = 0
	current_index = wrapi(current_index + direction, 0, block_ids.size())
	_set_selected_block_id(str(block_ids[current_index]))

func _cycle_palette_category(direction: int) -> void:
	if palette_category_ids.is_empty():
		return
	var current_index := palette_category_ids.find(selected_palette_category)
	if current_index == -1:
		current_index = 0
	current_index = wrapi(current_index + direction, 0, palette_category_ids.size())
	selected_palette_category = str(palette_category_ids[current_index])
	_refresh_hud()

func _cycle_store_selection(direction: int) -> void:
	var store_entries := NetworkRuntime.get_builder_store_entries()
	if store_entries.is_empty():
		return
	selected_store_index = wrapi(selected_store_index + direction, 0, store_entries.size())
	_refresh_hud()

func _get_donatable_resource_entries() -> Array:
	var local_profile := DockState.get_local_profile_snapshot()
	var entries: Array = []
	var total_gold := int(local_profile.get("total_gold", 0))
	if total_gold > 0:
		entries.append({
			"resource_id": "gold",
			"label": "Gold",
			"quantity": total_gold,
		})
	var stash_items := Dictionary(local_profile.get("stash_items", {}))
	for material_id_variant in NetworkRuntime.MATERIAL_ORDER:
		var material_id := str(material_id_variant)
		var quantity := int(stash_items.get(material_id, 0))
		if quantity <= 0:
			continue
		entries.append({
			"resource_id": material_id,
			"label": str(NetworkRuntime.MATERIAL_LABELS.get(material_id, material_id.capitalize())),
			"quantity": quantity,
		})
	return entries

func _cycle_donation_selection(direction: int) -> void:
	var entries := _get_donatable_resource_entries()
	if entries.is_empty():
		return
	selected_donation_index = wrapi(selected_donation_index + direction, 0, entries.size())
	_refresh_hud()

func _donate_selected_resource() -> void:
	if NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR:
		return
	var entries := _get_donatable_resource_entries()
	if entries.is_empty():
		return
	selected_donation_index = wrapi(selected_donation_index, 0, entries.size())
	var selected_entry: Dictionary = entries[selected_donation_index]
	var resource_id := str(selected_entry.get("resource_id", ""))
	var quantity := int(selected_entry.get("quantity", 0))
	if resource_id.is_empty() or quantity <= 0:
		return
	if NetworkRuntime.request_donate_workshop_resource(resource_id, quantity):
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

func _place_selected_block() -> bool:
	if NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR:
		return false
	if float(_get_reaction_visual(_get_local_peer_id()).get("active_time", 0.0)) > 0.0:
		return false
	if not cursor_can_place:
		return false
	NetworkRuntime.request_place_blueprint_block([cursor_cell.x, cursor_cell.y, cursor_cell.z], _get_selected_block_id(), selected_rotation_steps)
	return true

func _remove_selected_block() -> bool:
	if NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR:
		return false
	if float(_get_reaction_visual(_get_local_peer_id()).get("active_time", 0.0)) > 0.0:
		return false
	if not cursor_can_remove:
		return false
	NetworkRuntime.request_remove_blueprint_block([remove_cursor_cell.x, remove_cursor_cell.y, remove_cursor_cell.z])
	return true

func _launch_run() -> void:
	if NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR:
		return
	launch_transition_pending = true
	_set_mouse_capture(false)
	NetworkRuntime.request_launch_run()
	_refresh_hud()

func _launch_sea_test() -> void:
	if NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR:
		return
	if launch_transition_pending:
		return
	if _blueprint_is_default_core():
		launch_transition_pending = true
		_set_mouse_capture(false)
		_queue_autobuild_actions(_build_sea_test_actions(true))
		_refresh_hud()
		return
	_launch_run()

func _reset_boat() -> void:
	if NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR:
		return
	_set_mouse_capture(false)
	NetworkRuntime.request_reset_blueprint()
	_refresh_hud()

func _blueprint_is_default_core() -> bool:
	var blocks := Array(NetworkRuntime.boat_blueprint.get("blocks", []))
	if blocks.size() != 1:
		return false
	var block: Dictionary = blocks[0]
	return int(block.get("id", 0)) == 1 \
		and str(block.get("type", "")) == "core" \
		and _normalize_cell(block.get("cell", [0, 0, 0])) == [0, 0, 0]

func _build_sea_test_tooltip() -> String:
	if _blueprint_is_default_core():
		return "Build a known-good buoyancy test hull and launch it into the sea."
	return "Launch the current boat into the sea to preview buoyancy behavior."

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

func _set_selected_block_id(block_id: String, refresh_ui: bool = true) -> void:
	var block_ids := NetworkRuntime.get_builder_block_ids()
	var block_index := block_ids.find(block_id)
	if block_index == -1:
		return
	selected_block_index = block_index
	if not refresh_ui:
		return
	_refresh_cursor_visual()
	_refresh_hud()
	avatar_sync_timer = 0.0

func _refresh_block_palette_menu() -> void:
	if block_palette_filter == null or block_palette_list == null or block_palette_detail_label == null:
		return
	_refresh_block_palette_filter()
	var filtered_block_ids := _get_filtered_builder_block_ids()
	var current_block_id := _get_selected_block_id()
	if not filtered_block_ids.is_empty() and not filtered_block_ids.has(current_block_id):
		_set_selected_block_id(str(filtered_block_ids[0]), false)
		current_block_id = _get_selected_block_id()
	block_palette_list.clear()
	var selected_visible_index := -1
	for block_index in range(filtered_block_ids.size()):
		var filtered_block_id := str(filtered_block_ids[block_index])
		var block_def := NetworkRuntime.get_builder_block_definition(filtered_block_id)
		var block_label := str(block_def.get("label", filtered_block_id.capitalize()))
		var tier := int(block_def.get("unlock_tier", 0))
		var category_label := _get_palette_category_label(str(block_def.get("category", "structure")))
		var item_text := "%s  |  T%d %s" % [block_label, tier, category_label]
		var item_icon := hud_icons.load_icon(hud_icons.get_block_icon_id(filtered_block_id))
		block_palette_list.add_item(item_text, item_icon, true)
		block_palette_list.set_item_metadata(block_index, filtered_block_id)
		block_palette_list.set_item_custom_fg_color(block_index, block_def.get("color", Color(0.96, 0.95, 0.90)))
		block_palette_list.set_item_tooltip(block_index, "%s\n%s" % [
			block_label,
			str(block_def.get("description", "")),
		])
		if filtered_block_id == current_block_id:
			selected_visible_index = block_index
	if selected_visible_index >= 0:
		block_palette_list.select(selected_visible_index)
		block_palette_list.ensure_current_is_visible()
	block_palette_detail_label.text = _build_block_palette_detail_text(current_block_id, filtered_block_ids.size())
	block_palette_detail_label.modulate = Color(0.94, 0.95, 0.90)

func _refresh_block_palette_filter() -> void:
	if block_palette_filter == null:
		return
	var available_categories := _get_available_palette_categories()
	if available_categories.is_empty():
		available_categories.append("all")
	if not available_categories.has(selected_palette_category):
		selected_palette_category = str(available_categories[0])
	palette_category_ids = available_categories
	block_palette_filter.clear()
	var selected_index := 0
	for category_index in range(palette_category_ids.size()):
		var category_id := str(palette_category_ids[category_index])
		block_palette_filter.add_item(_get_palette_category_label(category_id))
		if category_id == selected_palette_category:
			selected_index = category_index
	block_palette_filter.select(selected_index)

func _get_available_palette_categories() -> Array:
	var unlocked_block_ids := NetworkRuntime.get_builder_block_ids()
	var available_lookup := {"all": true}
	for block_id_variant in unlocked_block_ids:
		var block_id := str(block_id_variant)
		var category_id := str(NetworkRuntime.get_builder_block_definition(block_id).get("category", "structure"))
		available_lookup[category_id] = true
	var ordered_categories: Array = []
	for category_id_variant in PALETTE_CATEGORY_ORDER:
		var category_id := str(category_id_variant)
		if available_lookup.has(category_id):
			ordered_categories.append(category_id)
			available_lookup.erase(category_id)
	for remaining_category_variant in available_lookup.keys():
		ordered_categories.append(str(remaining_category_variant))
	return ordered_categories

func _get_filtered_builder_block_ids() -> Array:
	var unlocked_block_ids := NetworkRuntime.get_builder_block_ids()
	if selected_palette_category == "all":
		return unlocked_block_ids
	var filtered_block_ids: Array = []
	for block_id_variant in unlocked_block_ids:
		var block_id := str(block_id_variant)
		var block_category := str(NetworkRuntime.get_builder_block_definition(block_id).get("category", "structure"))
		if block_category != selected_palette_category:
			continue
		filtered_block_ids.append(block_id)
	return filtered_block_ids

func _get_palette_category_label(category_id: String) -> String:
	return str(PALETTE_CATEGORY_LABELS.get(category_id, category_id.replace("_", " ").capitalize()))

func _build_block_palette_detail_text(block_id: String, visible_count: int) -> String:
	var block_def := NetworkRuntime.get_builder_block_definition(block_id)
	return "Selected: %s\n%s • Tier %d\n%s\nHP %.0f | Float %.1f | Thrust %.1f\nCargo +%d | Kits +%d | Brace +%.2f\nShowing %d crafted part(s). Click a part to equip it for F-place, or use Q/E and the arrow keys while this menu is open." % [
		str(block_def.get("label", block_id.capitalize())),
		_get_palette_category_label(str(block_def.get("category", "structure"))),
		int(block_def.get("unlock_tier", 0)),
		str(block_def.get("description", "")),
		float(block_def.get("max_hp", 0.0)),
		float(block_def.get("buoyancy", 0.0)),
		float(block_def.get("thrust", 0.0)),
		int(block_def.get("cargo", 0)),
		int(block_def.get("repair", 0)),
		float(block_def.get("brace", 0.0)),
		visible_count,
	]

func _on_block_palette_filter_selected(index: int) -> void:
	if index < 0 or index >= palette_category_ids.size():
		return
	selected_palette_category = str(palette_category_ids[index])
	_refresh_hud()

func _on_block_palette_item_selected(index: int) -> void:
	if block_palette_list == null or index < 0 or index >= block_palette_list.item_count:
		return
	_set_selected_block_id(str(block_palette_list.get_item_metadata(index)))

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
	var visual_root := local_avatar_body.get_node_or_null("AvatarVisual") as Node3D
	if visual_root != null:
		if visual_root.has_method("set_motion_blend"):
			visual_root.call("set_motion_blend", _get_hangar_avatar_motion_blend(local_avatar_body.velocity))
		elif visual_root.has_method("set_motion_state"):
			visual_root.call("set_motion_state", _get_hangar_avatar_motion_state(local_avatar_body.velocity))

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
		detail_toggle_button.text = "Close Boat Plate" if hud_details_visible else "Open Boat Plate"
	if inventory_panel != null:
		inventory_panel.visible = inventory_panel_visible
	var workshop_focus := _get_selected_hangar_tool_id() == "yard" or inventory_panel_visible
	if right_panel != null:
		right_panel.visible = workshop_focus
	if build_focus_panel != null:
		build_focus_panel.visible = not inventory_panel_visible
	if tool_panel != null:
		tool_panel.visible = not inventory_panel_visible
	if bottom_left_panel != null:
		bottom_left_panel.visible = not inventory_panel_visible

func _build_dock_status_text(status_body: String) -> String:
	var normalized := status_body.strip_edges()
	if normalized.is_empty():
		return "Dock systems ready."
	if normalized.begins_with("Run bootstrap received"):
		return "Dock link stable."
	if normalized.begins_with("Connected to "):
		return "Connected to dock crew."
	if normalized.begins_with("Connecting to "):
		return "Connecting to dock crew..."
	return normalized

func _build_launch_button_label(snapshot: Dictionary) -> String:
	var title := str(snapshot.get("title", "Ready To Sail"))
	match title:
		"Risky Launch":
			return "Launch Risky"
		"Loose Chunks Detected":
			return "Launch Loose"
		_:
			return "Launch"

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
		_apply_player_controller_presentation(
			avatar_root,
			str(peer_data.get("name", "Crew")),
			peer_color,
			selected_block_color.lightened(0.14),
			_get_presence_feedback_color(peer_color, presence_state).lightened(0.12),
			presence_text
		)
		if avatar_root.has_method("set_motion_blend"):
			avatar_root.call("set_motion_blend", _get_hangar_avatar_motion_blend(avatar_state.get("velocity", Vector3.ZERO)))
		elif avatar_root.has_method("set_motion_state"):
			avatar_root.call("set_motion_state", _get_hangar_avatar_motion_state(avatar_state.get("velocity", Vector3.ZERO)))
		if ghost_root != null and ghost_mesh != null and ghost_ring != null:
			var has_target := bool(avatar_state.get("has_target", false))
			ghost_root.visible = has_target
			if has_target:
				var target_cell := _variant_to_cell_vector(avatar_state.get("target_cell", [0, 0, 0]))
				ghost_root.position = _cell_to_local_position(target_cell)
				ghost_root.rotation_degrees.y = float(int(avatar_state.get("rotation_steps", 0)) * 90)
				var ghost_box := ghost_mesh.mesh as BoxMesh
				if ghost_box != null:
					ghost_box.size = Vector3.ONE * BLOCK_CELL_SIZE * 1.02
				var ghost_material := StandardMaterial3D.new()
				var ghost_color := _get_presence_feedback_color(peer_color, presence_state).darkened(0.04)
				ghost_color.a = 0.24 if presence_state == "ready" else 0.18
				ghost_material.albedo_color = ghost_color
				ghost_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				ghost_material.roughness = 0.16
				ghost_mesh.material_override = ghost_material
				var ring_shape := ghost_ring.mesh as CylinderMesh
				if ring_shape != null:
					var ring_radius := BLOCK_CELL_SIZE * 0.58
					ring_shape.top_radius = ring_radius
					ring_shape.bottom_radius = ring_radius + 0.08
				ghost_ring.position.y = -(BLOCK_CELL_SIZE * 0.49)
				var ring_material := StandardMaterial3D.new()
				var ring_color := _get_presence_feedback_color(peer_color, presence_state).lightened(0.08)
				ring_color.a = 0.36 if presence_state == "ready" else 0.28
				ring_material.albedo_color = ring_color
				ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				ring_material.roughness = 0.1
				ghost_ring.material_override = ring_material
		_apply_avatar_reaction_pose(avatar_root, peer_id, delta)

func _get_hangar_avatar_motion_blend(velocity: Vector3) -> float:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if horizontal_speed < 0.18:
		return 0.0
	return clampf(horizontal_speed / HANGAR_MOVE_SPEED, 0.0, 1.0)

func _get_hangar_avatar_motion_state(velocity: Vector3) -> String:
	var motion_blend := _get_hangar_avatar_motion_blend(velocity)
	if motion_blend >= 0.75:
		return "run"
	if motion_blend >= 0.08:
		return "walk"
	return "idle"

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
		"builder_work_barge":
			autobuild_actions = [
				{"type": "place", "cell": [2, 0, 0], "block": "hull"},
				{"type": "place", "cell": [2, 0, 1], "block": "cargo"},
				{"type": "place", "cell": [1, 1, 1], "block": "utility"},
				{"type": "place", "cell": [2, 1, 0], "block": "deck_plate"},
				{"type": "launch"},
			]
		"builder_sea_test":
			autobuild_actions = _build_sea_test_actions(false)
		"builder_sea_test_launch":
			autobuild_actions = _build_sea_test_actions(true)
		"builder_rescue_tug":
			autobuild_actions = [
				{"type": "place", "cell": [-2, 0, 0], "block": "hull"},
				{"type": "place", "cell": [-2, 1, 0], "block": "ladder_rig"},
				{"type": "place", "cell": [-1, 1, 1], "block": "deck_plate"},
				{"type": "place", "cell": [1, 1, 1], "block": "utility"},
				{"type": "launch"},
			]
		"builder_routeing_demo":
			autobuild_actions = [
				{"type": "place", "cell": [0, 1, 1], "block": "deck_plate"},
				{"type": "place", "cell": [1, 1, 1], "block": "deck_plate"},
				{"type": "place", "cell": [2, 1, 1], "block": "structure"},
				{"type": "place", "cell": [2, 0, 1], "block": "cargo"},
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

func _queue_autobuild_actions(actions: Array) -> void:
	autobuild_actions = Array(actions).duplicate(true)
	autobuild_pending_action.clear()
	autobuild_index = 0
	autobuild_timer = 0.1

func _build_sea_test_actions(include_launch: bool) -> Array:
	var actions: Array = [
		{"type": "reset"},
		{"type": "place", "cell": [0, 0, -1], "block": "engine"},
		{"type": "place", "cell": [-1, 0, 0], "block": "hull"},
		{"type": "place", "cell": [1, 0, 0], "block": "hull"},
		{"type": "place", "cell": [-1, 0, 1], "block": "hull"},
		{"type": "place", "cell": [0, 0, 1], "block": "hull"},
		{"type": "place", "cell": [1, 0, 1], "block": "hull"},
		{"type": "place", "cell": [-1, 0, 2], "block": "hull"},
		{"type": "place", "cell": [0, 0, 2], "block": "hull"},
		{"type": "place", "cell": [1, 0, 2], "block": "hull"},
		{"type": "place", "cell": [-1, 0, 3], "block": "hull"},
		{"type": "place", "cell": [0, 0, 3], "block": "hull"},
		{"type": "place", "cell": [1, 0, 3], "block": "hull"},
		{"type": "place", "cell": [0, 1, -1], "block": "structure"},
		{"type": "place", "cell": [0, 1, 0], "block": "deck_plate"},
		{"type": "place", "cell": [-1, 1, 1], "block": "deck_plate"},
		{"type": "place", "cell": [1, 1, 1], "block": "deck_plate"},
		{"type": "place", "cell": [0, 1, 1], "block": "utility"},
		{"type": "place", "cell": [0, 1, 2], "block": "cargo"},
		{"type": "place", "cell": [0, 1, 3], "block": "light_crane"},
		{"type": "place", "cell": [-2, 1, 1], "block": "ladder_rig"},
		{"type": "place", "cell": [2, 1, 1], "block": "ladder_rig"},
	]
	if include_launch:
		actions.append({"type": "launch"})
	return actions

func _execute_autobuild_action(action: Dictionary) -> void:
	match str(action.get("type", "")):
		"reset":
			NetworkRuntime.request_reset_blueprint()
		"unlock":
			NetworkRuntime.request_unlock_builder_block(str(action.get("block", "")))
		"place":
			var cell := _normalize_cell(action.get("cell", [0, 0, 0]))
			NetworkRuntime.request_place_blueprint_block(cell, str(action.get("block", "structure")), int(action.get("rotation_steps", 0)))
		"remove":
			var cell := _normalize_cell(action.get("cell", [0, 0, 0]))
			NetworkRuntime.request_remove_blueprint_block(cell)
		"launch":
			launch_transition_pending = true
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
		GameConfig.queue_scene_load(
			RUN_CLIENT_SCENE,
			"Launching Run",
			"Charting the sea, loading the weather, and hauling your boat into the next run."
		)
		get_tree().change_scene_to_file(LOADING_SCENE)
		return
	launch_transition_pending = false
	_set_mouse_capture(true)
	_refresh_hud()

func _on_profile_changed(_snapshot: Dictionary) -> void:
	_refresh_hud()

func _on_progression_state_changed(_snapshot: Dictionary) -> void:
	_refresh_hud()

func _get_local_peer_id() -> int:
	if NetworkRuntime == null:
		return 0
	return NetworkRuntime.get_local_peer_id()
