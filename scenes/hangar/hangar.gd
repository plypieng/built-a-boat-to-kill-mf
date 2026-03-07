extends Node3D

const CLIENT_BOOT_SCENE := "res://scenes/boot/client_boot.tscn"
const RUN_CLIENT_SCENE := "res://scenes/run_client/run_client.tscn"
const BLOCK_CELL_SIZE := 1.25
const CURSOR_OK_COLOR := Color(0.34, 0.82, 0.58, 0.55)
const CURSOR_BLOCKED_COLOR := Color(0.88, 0.32, 0.24, 0.55)
const MAIN_CHUNK_TINT := Color(0.08, 0.08, 0.08)
const LOOSE_CHUNK_TINT := Color(0.25, 0.02, 0.02)

var launch_overrides: Dictionary = {}
var connect_time_seconds := 0.0
var status_label: Label
var builder_label: Label
var warning_label: Label
var roster_label: Label
var profile_label: Label
var controls_label: Label
var last_run_label: Label
var launch_button: Button
var boat_root: Node3D
var block_container: Node3D
var cursor_root: Node3D
var cursor_mesh: MeshInstance3D
var cursor_label: Label3D
var block_visuals: Dictionary = {}
var camera: Camera3D
var selected_block_index := 0
var selected_rotation_steps := 0
var cursor_cell := Vector3i.ZERO
var autobuild_actions: Array = []
var autobuild_index := 0
var autobuild_timer := 0.0

func _ready() -> void:
	launch_overrides = GameConfig.parse_cmdline_overrides()
	_build_world()
	_build_hud()
	_refresh_all()
	_schedule_optional_quit()
	_initialize_autobuild()

	NetworkRuntime.status_changed.connect(_on_status_changed)
	NetworkRuntime.peer_snapshot_changed.connect(_on_peer_snapshot_changed)
	NetworkRuntime.boat_blueprint_changed.connect(_on_boat_blueprint_changed)
	NetworkRuntime.session_phase_changed.connect(_on_session_phase_changed)
	DockState.profile_changed.connect(_on_profile_changed)
	if NetworkRuntime.get_session_phase() == NetworkRuntime.SESSION_PHASE_RUN:
		get_tree().call_deferred("change_scene_to_file", RUN_CLIENT_SCENE)
		return
	print("Hangar builder ready: version=%d blocks=%d phase=%s" % [
		int(NetworkRuntime.boat_blueprint.get("version", 1)),
		Array(NetworkRuntime.boat_blueprint.get("blocks", [])).size(),
		NetworkRuntime.get_session_phase(),
	])

func _process(delta: float) -> void:
	connect_time_seconds += delta
	_update_boat_bob()
	_update_camera(delta)
	_process_autobuild(delta)

func _unhandled_input(event: InputEvent) -> void:
	if NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR:
		return
	if not (event is InputEventKey):
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_Q:
			_cycle_block(-1)
		KEY_E:
			_cycle_block(1)
		KEY_LEFT:
			_move_cursor(Vector3i(-1, 0, 0))
		KEY_RIGHT:
			_move_cursor(Vector3i(1, 0, 0))
		KEY_UP:
			_move_cursor(Vector3i(0, 0, -1))
		KEY_DOWN:
			_move_cursor(Vector3i(0, 0, 1))
		KEY_PAGEUP:
			_move_cursor(Vector3i(0, 1, 0))
		KEY_PAGEDOWN:
			_move_cursor(Vector3i(0, -1, 0))
		KEY_R:
			_rotate_selected_block()
		KEY_F:
			_place_selected_block()
		KEY_X, KEY_BACKSPACE, KEY_DELETE:
			_remove_selected_block()
		KEY_ENTER, KEY_KP_ENTER:
			_launch_run()
		KEY_ESCAPE:
			_return_to_connect()

func _build_world() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.58, 0.72, 0.84)

	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)

	var light := DirectionalLight3D.new()
	light.light_energy = 1.18
	light.rotation_degrees = Vector3(-42.0, 32.0, 0.0)
	add_child(light)

	var dock := MeshInstance3D.new()
	var dock_mesh := BoxMesh.new()
	dock_mesh.size = Vector3(24.0, 0.6, 30.0)
	dock.mesh = dock_mesh
	dock.position = Vector3(0.0, -0.35, 0.0)
	var dock_material := StandardMaterial3D.new()
	dock_material.albedo_color = Color(0.65, 0.56, 0.42)
	dock_material.roughness = 0.9
	dock.material_override = dock_material
	add_child(dock)

	var water := MeshInstance3D.new()
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(180.0, 180.0)
	water.mesh = water_mesh
	water.position = Vector3(0.0, -0.68, 0.0)
	var water_material := StandardMaterial3D.new()
	water_material.albedo_color = Color(0.09, 0.39, 0.57)
	water_material.roughness = 0.18
	water.material_override = water_material
	add_child(water)

	boat_root = Node3D.new()
	boat_root.position = Vector3(0.0, 0.1, 0.0)
	add_child(boat_root)

	block_container = Node3D.new()
	boat_root.add_child(block_container)

	cursor_root = Node3D.new()
	boat_root.add_child(cursor_root)
	_build_cursor_visual()
	_build_build_volume()

	camera = Camera3D.new()
	camera.position = Vector3(15.0, 13.0, 18.0)
	add_child(camera)
	camera.look_at(Vector3(0.0, 2.5, 0.0), Vector3.UP)

func _build_cursor_visual() -> void:
	cursor_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.1, 1.1, 1.1) * BLOCK_CELL_SIZE
	cursor_mesh.mesh = box
	cursor_root.add_child(cursor_mesh)

	cursor_label = Label3D.new()
	cursor_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	cursor_label.font_size = 22
	cursor_label.position = Vector3(0.0, 1.1 * BLOCK_CELL_SIZE, 0.0)
	cursor_root.add_child(cursor_label)

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
	var layer := CanvasLayer.new()
	add_child(layer)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 20.0
	margin.offset_top = 20.0
	margin.offset_right = -20.0
	margin.offset_bottom = -20.0
	layer.add_child(margin)

	var shell := HBoxContainer.new()
	shell.alignment = BoxContainer.ALIGNMENT_BEGIN
	shell.add_theme_constant_override("separation", 16)
	margin.add_child(shell)

	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(520.0, 0.0)
	shell.add_child(left_panel)

	var left_margin := MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", 16)
	left_margin.add_theme_constant_override("margin_top", 14)
	left_margin.add_theme_constant_override("margin_right", 16)
	left_margin.add_theme_constant_override("margin_bottom", 14)
	left_panel.add_child(left_margin)

	var left_layout := VBoxContainer.new()
	left_layout.add_theme_constant_override("separation", 8)
	left_margin.add_child(left_layout)

	var title := Label.new()
	title.text = "Shared Boat Hangar"
	title.add_theme_font_size_override("font_size", 26)
	left_layout.add_child(title)

	builder_label = Label.new()
	builder_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_layout.add_child(builder_label)

	warning_label = Label.new()
	warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_layout.add_child(warning_label)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_layout.add_child(status_label)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	left_layout.add_child(actions)

	launch_button = Button.new()
	launch_button.text = "Launch Run"
	launch_button.pressed.connect(_launch_run)
	actions.add_child(launch_button)

	var reconnect_button := Button.new()
	reconnect_button.text = "Return To Connect"
	reconnect_button.pressed.connect(_return_to_connect)
	actions.add_child(reconnect_button)

	var quit_button := Button.new()
	quit_button.text = "Quit"
	quit_button.pressed.connect(_quit)
	actions.add_child(quit_button)

	var right_panel := PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(420.0, 0.0)
	shell.add_child(right_panel)

	var right_margin := MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left", 16)
	right_margin.add_theme_constant_override("margin_top", 14)
	right_margin.add_theme_constant_override("margin_right", 16)
	right_margin.add_theme_constant_override("margin_bottom", 14)
	right_panel.add_child(right_margin)

	var right_layout := VBoxContainer.new()
	right_layout.add_theme_constant_override("separation", 8)
	right_margin.add_child(right_layout)

	profile_label = Label.new()
	profile_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_layout.add_child(profile_label)

	roster_label = Label.new()
	roster_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_layout.add_child(roster_label)

	last_run_label = Label.new()
	last_run_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_layout.add_child(last_run_label)

	controls_label = Label.new()
	controls_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_layout.add_child(controls_label)

func _refresh_all() -> void:
	_refresh_blueprint_visuals()
	_refresh_cursor_visual()
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
		mesh.size = Vector3(block_def.get("size", Vector3.ONE)) * BLOCK_CELL_SIZE
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

		block_visuals[int(block.get("id", 0))] = block_node

func _refresh_cursor_visual() -> void:
	var block_id := _get_selected_block_id()
	var block_def := NetworkRuntime.get_builder_block_definition(block_id)
	cursor_root.position = _cell_to_local_position([cursor_cell.x, cursor_cell.y, cursor_cell.z])
	cursor_root.rotation_degrees.y = float(selected_rotation_steps * 90)
	cursor_label.text = "%s\n%s" % [
		str(block_def.get("label", block_id.capitalize())),
		"Cell %s" % str(cursor_cell),
	]

	var material := StandardMaterial3D.new()
	var occupied := _find_block_at_cell(cursor_cell).size() > 0
	material.albedo_color = CURSOR_BLOCKED_COLOR if occupied else CURSOR_OK_COLOR
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cursor_mesh.material_override = material

func _refresh_hud() -> void:
	var stats := NetworkRuntime.get_blueprint_stats()
	var block_id := _get_selected_block_id()
	var block_def := NetworkRuntime.get_builder_block_definition(block_id)
	var warning_lines := PackedStringArray()
	for warning in NetworkRuntime.get_blueprint_warnings():
		warning_lines.append("- %s" % str(warning))
	if warning_lines.is_empty():
		warning_lines.append("- No launch warnings right now.")

	builder_label.text = "Blueprint v%d | Selected %s | Rotation %d deg | Cursor %s\nBlocks %d | Main Chunk %d | Loose %d | Components %d\nHull %.0f | Top Speed %.1f | Cargo %d | Patch Kits %d | Brace x%.2f | Seaworthy %s" % [
		int(NetworkRuntime.boat_blueprint.get("version", 1)),
		str(block_def.get("label", block_id.capitalize())),
		selected_rotation_steps * 90,
		str(cursor_cell),
		int(stats.get("block_count", 0)),
		int(stats.get("main_chunk_blocks", 0)),
		int(stats.get("loose_blocks", 0)),
		int(stats.get("component_count", 0)),
		float(stats.get("max_hull_integrity", 0.0)),
		float(stats.get("top_speed", 0.0)),
		int(stats.get("cargo_capacity", 0)),
		int(stats.get("repair_capacity", 0)),
		float(stats.get("brace_multiplier", 1.0)),
		"yes" if bool(NetworkRuntime.boat_blueprint.get("seaworthy", false)) else "no",
	]
	warning_label.text = "Launch Warnings\n%s" % "\n".join(warning_lines)
	status_label.text = "Status\n%s" % NetworkRuntime.status_message
	launch_button.disabled = NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR

	var total_runs := DockState.get_total_runs()
	var successful_runs := DockState.get_successful_runs()
	var extraction_rate := 0.0
	if total_runs > 0:
		extraction_rate = float(successful_runs) / float(total_runs) * 100.0
	profile_label.text = "Dock Totals\nGold %d | Salvage %d | Runs %d | Extracted %d (%.0f%%)" % [
		DockState.get_total_gold(),
		DockState.get_total_salvage(),
		total_runs,
		successful_runs,
		extraction_rate,
	]

	var crew_lines := PackedStringArray()
	for peer_id in NetworkRuntime.get_player_peer_ids():
		var peer_data: Dictionary = NetworkRuntime.peer_snapshot.get(peer_id, {})
		crew_lines.append("%s - %s" % [str(peer_id), str(peer_data.get("name", "Crew"))])
	if crew_lines.is_empty():
		crew_lines.append("No crew connected yet.")
	roster_label.text = "Crew In Hangar\n%s" % "\n".join(crew_lines)

	var last_run := DockState.get_last_run()
	if last_run.is_empty():
		last_run_label.text = "Last Run\nNo extracted runs recorded locally yet."
	else:
		last_run_label.text = "Last Run\n%s\nGold %d | Salvage %d | Secured %d | Lost %d | Recorded %s" % [
			str(last_run.get("title", "Run Complete")),
			int(last_run.get("reward_gold", 0)),
			int(last_run.get("reward_salvage", 0)),
			int(last_run.get("cargo_secured", 0)),
			int(last_run.get("cargo_lost", 0)),
			str(last_run.get("timestamp", "")),
		]

	controls_label.text = "Controls\nArrow keys move cursor on X/Z\nPageUp / PageDown move cursor vertically\nQ / E cycle blocks | R rotate\nF place block | X remove block\nEnter launches the run | Esc returns to connect"

func _move_cursor(delta_cell: Vector3i) -> void:
	var bounds_min := NetworkRuntime.get_builder_bounds_min()
	var bounds_max := NetworkRuntime.get_builder_bounds_max()
	cursor_cell.x = clampi(cursor_cell.x + delta_cell.x, bounds_min.x, bounds_max.x)
	cursor_cell.y = clampi(cursor_cell.y + delta_cell.y, bounds_min.y, bounds_max.y)
	cursor_cell.z = clampi(cursor_cell.z + delta_cell.z, bounds_min.z, bounds_max.z)
	_refresh_cursor_visual()
	_refresh_hud()

func _cycle_block(direction: int) -> void:
	var block_ids := NetworkRuntime.get_builder_block_ids()
	if block_ids.is_empty():
		return
	selected_block_index = wrapi(selected_block_index + direction, 0, block_ids.size())
	_refresh_cursor_visual()
	_refresh_hud()

func _rotate_selected_block() -> void:
	selected_rotation_steps = wrapi(selected_rotation_steps + 1, 0, 4)
	_refresh_cursor_visual()
	_refresh_hud()

func _place_selected_block() -> void:
	if NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR:
		return
	if _find_block_at_cell(cursor_cell).size() > 0:
		return
	NetworkRuntime.request_place_blueprint_block([cursor_cell.x, cursor_cell.y, cursor_cell.z], _get_selected_block_id(), selected_rotation_steps)

func _remove_selected_block() -> void:
	if NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR:
		return
	if _find_block_at_cell(cursor_cell).is_empty():
		return
	NetworkRuntime.request_remove_blueprint_block([cursor_cell.x, cursor_cell.y, cursor_cell.z])

func _launch_run() -> void:
	if NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR:
		return
	NetworkRuntime.request_launch_run()

func _return_to_connect() -> void:
	NetworkRuntime.shutdown()
	get_tree().change_scene_to_file(CLIENT_BOOT_SCENE)

func _quit() -> void:
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
	boat_root.position.y = 0.1 + sin(connect_time_seconds * 0.9) * 0.08

func _update_camera(delta: float) -> void:
	if camera == null:
		return
	var desired_position := Vector3(15.0, 13.0, 18.0)
	camera.position = camera.position.lerp(desired_position, minf(1.0, delta * 2.0))
	camera.look_at(Vector3(0.0, 2.6, 0.0), Vector3.UP)

func _schedule_optional_quit() -> void:
	var quit_after_connect_ms := int(launch_overrides.get("quit_after_connect_ms", 0))
	if quit_after_connect_ms <= 0:
		return
	get_tree().create_timer(float(quit_after_connect_ms) / 1000.0).timeout.connect(_quit_after_timer)

func _quit_after_timer() -> void:
	print("Hangar auto-quit triggered. Blueprint version=%d blocks=%d phase=%s" % [
		int(NetworkRuntime.boat_blueprint.get("version", 1)),
		Array(NetworkRuntime.boat_blueprint.get("blocks", [])).size(),
		NetworkRuntime.get_session_phase(),
	])
	get_tree().quit()

func _initialize_autobuild() -> void:
	autobuild_actions.clear()
	autobuild_index = 0
	autobuild_timer = 0.0
	match str(launch_overrides.get("autobuild_role", "")):
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

func _process_autobuild(delta: float) -> void:
	if autobuild_index >= autobuild_actions.size():
		return
	if NetworkRuntime.get_session_phase() != NetworkRuntime.SESSION_PHASE_HANGAR:
		return

	autobuild_timer -= delta
	if autobuild_timer > 0.0:
		return

	var action: Dictionary = autobuild_actions[autobuild_index]
	autobuild_index += 1
	autobuild_timer = 0.35
	match str(action.get("type", "")):
		"place":
			var cell := _normalize_cell(action.get("cell", [0, 0, 0]))
			cursor_cell = Vector3i(cell[0], cell[1], cell[2])
			_refresh_cursor_visual()
			NetworkRuntime.request_place_blueprint_block(cell, str(action.get("block", "structure")), int(action.get("rotation_steps", 0)))
		"remove":
			var cell := _normalize_cell(action.get("cell", [0, 0, 0]))
			cursor_cell = Vector3i(cell[0], cell[1], cell[2])
			_refresh_cursor_visual()
			NetworkRuntime.request_remove_blueprint_block(cell)
		"launch":
			NetworkRuntime.request_launch_run()

func _on_status_changed(_message: String) -> void:
	_refresh_hud()

func _on_peer_snapshot_changed(_snapshot: Dictionary) -> void:
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
		get_tree().change_scene_to_file(RUN_CLIENT_SCENE)
		return
	_refresh_hud()

func _on_profile_changed(_snapshot: Dictionary) -> void:
	_refresh_hud()
