extends Node3D

const CREW_SLOTS := [
	Vector3(0.0, 0.92, -1.2),
	Vector3(-0.95, 0.92, 0.05),
	Vector3(0.95, 0.92, 0.05),
	Vector3(0.0, 0.92, 1.25),
]

var status_label: Label
var run_label: Label
var roster_label: Label
var helm_label: Label
var boat_label: Label
var boat_visual: MeshInstance3D
var crew_container: Node3D
var hazard_container: Node3D
var camera: Camera3D
var launch_overrides: Dictionary = {}
var connect_time_seconds := 0.0
var autopilot_remaining_seconds := 0.0
var autopilot_request_cooldown := 0.0
var autobrace_request_cooldown := 0.0
var helm_request_latched := false
var brace_request_latched := false
var hazard_visuals: Dictionary = {}

func _ready() -> void:
	launch_overrides = GameConfig.parse_cmdline_overrides()
	_build_world()
	_build_hud()
	_refresh_hud()
	_refresh_crew_visuals()
	_refresh_hazard_visuals()
	_schedule_optional_quit()
	_initialize_autopilot()
	print("Run client ready with seed %d and peer id %d." % [NetworkRuntime.run_seed, multiplayer.get_unique_id()])

	NetworkRuntime.status_changed.connect(_on_status_changed)
	NetworkRuntime.peer_snapshot_changed.connect(_on_peer_snapshot_changed)
	NetworkRuntime.run_seed_changed.connect(_on_run_seed_changed)
	NetworkRuntime.helm_changed.connect(_on_helm_changed)
	NetworkRuntime.boat_state_changed.connect(_on_boat_state_changed)
	NetworkRuntime.hazard_state_changed.connect(_on_hazard_state_changed)

func _process(delta: float) -> void:
	connect_time_seconds += delta
	_update_boat_visual(delta)
	_update_hazard_visuals(delta)
	_update_camera()

func _physics_process(delta: float) -> void:
	var input_state: Dictionary = _collect_input_state(delta)
	if bool(input_state.get("request_helm", false)):
		NetworkRuntime.request_driver_control()
	if bool(input_state.get("request_brace", false)):
		NetworkRuntime.request_brace()

	if multiplayer.get_unique_id() == NetworkRuntime.driver_peer_id:
		NetworkRuntime.send_local_boat_input(
			float(input_state.get("throttle", 0.0)),
			float(input_state.get("steer", 0.0))
		)

func _build_world() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.48, 0.72, 0.92)

	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)

	var light := DirectionalLight3D.new()
	light.light_energy = 1.2
	light.rotation_degrees = Vector3(-48.0, 40.0, 0.0)
	add_child(light)

	var water := MeshInstance3D.new()
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(190.0, 190.0)
	water.mesh = water_mesh
	var water_material := StandardMaterial3D.new()
	water_material.albedo_color = Color(0.10, 0.44, 0.66)
	water_material.roughness = 0.12
	water.material_override = water_material
	add_child(water)

	hazard_container = Node3D.new()
	add_child(hazard_container)

	boat_visual = MeshInstance3D.new()
	var hull_mesh := BoxMesh.new()
	hull_mesh.size = Vector3(3.2, 0.7, 6.0)
	boat_visual.mesh = hull_mesh
	boat_visual.position = Vector3(0.0, 0.35, 0.0)
	var hull_material := StandardMaterial3D.new()
	hull_material.albedo_color = Color(0.44, 0.27, 0.16)
	boat_visual.material_override = hull_material
	add_child(boat_visual)

	var mast := MeshInstance3D.new()
	var mast_mesh := CylinderMesh.new()
	mast_mesh.height = 3.2
	mast_mesh.top_radius = 0.12
	mast_mesh.bottom_radius = 0.12
	mast.mesh = mast_mesh
	mast.position = Vector3(0.0, 2.0, -0.2)
	var mast_material := StandardMaterial3D.new()
	mast_material.albedo_color = Color(0.82, 0.79, 0.72)
	mast.material_override = mast_material
	boat_visual.add_child(mast)

	crew_container = Node3D.new()
	boat_visual.add_child(crew_container)

	camera = Camera3D.new()
	camera.position = Vector3(0.0, 5.5, 10.5)
	add_child(camera)
	camera.look_at(Vector3(0.0, 0.6, 0.0), Vector3.UP)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	margin.offset_left = 20.0
	margin.offset_top = 20.0
	layer.add_child(margin)

	var panel := PanelContainer.new()
	margin.add_child(panel)

	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_left", 16)
	inner.add_theme_constant_override("margin_top", 14)
	inner.add_theme_constant_override("margin_right", 16)
	inner.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(inner)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	inner.add_child(layout)

	var heading := Label.new()
	heading.text = "Shared Boat Prototype"
	heading.add_theme_font_size_override("font_size", 22)
	layout.add_child(heading)

	run_label = Label.new()
	layout.add_child(run_label)

	helm_label = Label.new()
	helm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(helm_label)

	boat_label = Label.new()
	boat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(boat_label)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(status_label)

	roster_label = Label.new()
	roster_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(roster_label)

	var footer := Label.new()
	footer.text = "Controls: E request helm | W/S throttle | A/D steer | Space brace | Arrow keys also work."
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(footer)

func _refresh_hud() -> void:
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var local_peer_id := multiplayer.get_unique_id()
	var has_helm := local_peer_id == NetworkRuntime.driver_peer_id
	var brace_timer: float = float(NetworkRuntime.boat_state.get("brace_timer", 0.0))
	var brace_cooldown: float = float(NetworkRuntime.boat_state.get("brace_cooldown", 0.0))
	var hull_integrity: float = float(NetworkRuntime.boat_state.get("hull_integrity", 100.0))

	run_label.text = "Mode: %s | Run Seed: %d | Peer ID: %d | Hazards: %d" % [
		NetworkRuntime.get_mode_name(),
		NetworkRuntime.run_seed,
		local_peer_id,
		NetworkRuntime.hazard_state.size(),
	]
	helm_label.text = "Helm: %s | Driver Peer: %d | You Have Control: %s" % [
		NetworkRuntime.get_driver_name(),
		NetworkRuntime.driver_peer_id,
		"yes" if has_helm else "no",
	]
	boat_label.text = "Boat: hp=%.1f pos=(%.2f, %.2f, %.2f) heading=%.2f speed=%.2f brace=%.2f cooldown=%.2f collisions=%d lastImpact=%.1f braced=%s" % [
		hull_integrity,
		boat_position.x,
		boat_position.y,
		boat_position.z,
		float(NetworkRuntime.boat_state.get("rotation_y", 0.0)),
		float(NetworkRuntime.boat_state.get("speed", 0.0)),
		brace_timer,
		brace_cooldown,
		int(NetworkRuntime.boat_state.get("collision_count", 0)),
		float(NetworkRuntime.boat_state.get("last_impact_damage", 0.0)),
		"yes" if bool(NetworkRuntime.boat_state.get("last_impact_braced", false)) else "no",
	]
	status_label.text = "Status: %s" % NetworkRuntime.status_message

	var lines := PackedStringArray()
	for peer_id in NetworkRuntime.get_player_peer_ids():
		var peer_data: Dictionary = NetworkRuntime.peer_snapshot[peer_id]
		var role_label := "helmsman" if int(peer_id) == NetworkRuntime.driver_peer_id else "crew"
		lines.append("%s - %s [%s / %s]" % [
			str(peer_id),
			str(peer_data.get("name", "Unknown")),
			str(peer_data.get("status", "unknown")),
			role_label,
		])
	roster_label.text = "Crew Snapshot:\n%s" % ("\n".join(lines) if not lines.is_empty() else "No crew connected yet.")

func _on_status_changed(_message: String) -> void:
	_refresh_hud()

func _on_peer_snapshot_changed(_snapshot: Dictionary) -> void:
	_refresh_hud()
	_refresh_crew_visuals()

func _on_run_seed_changed(_seed: int) -> void:
	_refresh_hud()

func _on_helm_changed(_driver_peer_id: int) -> void:
	_refresh_hud()
	_refresh_crew_visuals()

func _on_boat_state_changed(_state: Dictionary) -> void:
	_refresh_hud()

func _on_hazard_state_changed(_hazards: Array) -> void:
	_refresh_hud()
	_refresh_hazard_visuals()

func _schedule_optional_quit() -> void:
	var quit_after_connect_ms := int(launch_overrides.get("quit_after_connect_ms", 0))
	if quit_after_connect_ms <= 0:
		return

	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = float(quit_after_connect_ms) / 1000.0
	timer.timeout.connect(_quit_after_connect_timer)
	add_child(timer)
	timer.start()
	print("Client auto-quit armed for %d ms after connect." % quit_after_connect_ms)

func _quit_after_connect_timer() -> void:
	print("Client auto-quit triggered. Final boat state: %s" % [str(NetworkRuntime.boat_state)])
	get_tree().quit()

func _initialize_autopilot() -> void:
	autopilot_remaining_seconds = float(int(launch_overrides.get("autodrive_ms", 0))) / 1000.0

func _collect_input_state(delta: float) -> Dictionary:
	var request_helm := false
	var request_brace := false

	if Input.is_key_pressed(KEY_E):
		if not helm_request_latched:
			request_helm = true
			helm_request_latched = true
	else:
		helm_request_latched = false

	if Input.is_key_pressed(KEY_SPACE):
		if not brace_request_latched:
			request_brace = true
			brace_request_latched = true
	else:
		brace_request_latched = false

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

	if autopilot_remaining_seconds > 0.0:
		autopilot_remaining_seconds = maxf(0.0, autopilot_remaining_seconds - delta)
		autopilot_request_cooldown = maxf(0.0, autopilot_request_cooldown - delta)
		autobrace_request_cooldown = maxf(0.0, autobrace_request_cooldown - delta)
		if autopilot_request_cooldown <= 0.0 and multiplayer.get_unique_id() != NetworkRuntime.driver_peer_id:
			request_helm = true
			autopilot_request_cooldown = 0.35

		throttle = float(launch_overrides.get("autodrive_throttle", 1.0))
		steer = float(launch_overrides.get("autodrive_steer", 0.0))

		if bool(launch_overrides.get("autobrace", false)) and autobrace_request_cooldown <= 0.0 and _should_autobrace():
			request_brace = true
			autobrace_request_cooldown = 0.45

	return {
		"request_helm": request_helm,
		"request_brace": request_brace,
		"throttle": clampf(throttle, -1.0, 1.0),
		"steer": clampf(steer, -1.0, 1.0),
	}

func _should_autobrace() -> bool:
	var autobrace_distance: float = float(launch_overrides.get("autobrace_distance", 7.5))
	if float(NetworkRuntime.boat_state.get("brace_cooldown", 0.0)) > 0.0:
		return false

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
	var target_position := server_position + Vector3(0.0, 0.35 + sin(connect_time_seconds * 1.35) * 0.08, 0.0)
	var rotation_y: float = float(NetworkRuntime.boat_state.get("rotation_y", 0.0))
	boat_visual.position = boat_visual.position.lerp(target_position, minf(1.0, delta * 8.0))
	boat_visual.rotation.y = lerp_angle(boat_visual.rotation.y, rotation_y, minf(1.0, delta * 8.0))

func _update_camera() -> void:
	if camera == null:
		return

	var boat_anchor := boat_visual.position + Vector3(0.0, 1.8, 0.0)
	var follow_offset := Vector3(0.0, 4.5, 10.0).rotated(Vector3.UP, boat_visual.rotation.y)
	camera.position = boat_anchor + follow_offset
	camera.look_at(boat_anchor, Vector3.UP)

func _refresh_crew_visuals() -> void:
	for child in crew_container.get_children():
		child.queue_free()

	var slot_index := 0
	for peer_id in NetworkRuntime.get_player_peer_ids():
		var peer_data: Dictionary = NetworkRuntime.peer_snapshot[peer_id]
		var crew_member := Node3D.new()
		crew_member.position = CREW_SLOTS[slot_index % CREW_SLOTS.size()]
		crew_container.add_child(crew_member)

		var body := MeshInstance3D.new()
		var body_mesh := CapsuleMesh.new()
		body_mesh.height = 1.2
		body_mesh.radius = 0.24
		body.mesh = body_mesh
		var material := StandardMaterial3D.new()
		var is_driver := int(peer_id) == NetworkRuntime.driver_peer_id
		material.albedo_color = Color(0.94, 0.76, 0.18) if is_driver else Color(0.70, 0.84, 0.93)
		body.material_override = material
		body.position = Vector3.ZERO
		crew_member.add_child(body)

		var nameplate := Label3D.new()
		nameplate.text = str(peer_data.get("name", "Crew"))
		nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		nameplate.font_size = 28
		nameplate.modulate = Color(1.0, 0.96, 0.84) if is_driver else Color(0.88, 0.95, 1.0)
		nameplate.position = Vector3(0.0, 0.92, 0.0)
		crew_member.add_child(nameplate)

		slot_index += 1

func _refresh_hazard_visuals() -> void:
	for child in hazard_container.get_children():
		child.queue_free()
	hazard_visuals = {}

	for hazard in NetworkRuntime.hazard_state:
		var hazard_data: Dictionary = hazard
		var hazard_node := Node3D.new()
		hazard_container.add_child(hazard_node)
		hazard_visuals[int(hazard_data.get("id", 0))] = hazard_node

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

func _update_hazard_visuals(_delta: float) -> void:
	for hazard in NetworkRuntime.hazard_state:
		var hazard_data: Dictionary = hazard
		var hazard_id := int(hazard_data.get("id", 0))
		if not hazard_visuals.has(hazard_id):
			continue

		var hazard_node: Node3D = hazard_visuals[hazard_id]
		var base_position: Vector3 = hazard_data.get("position", Vector3.ZERO)
		var bob_height := sin(connect_time_seconds * 1.45 + float(hazard_id)) * 0.18
		hazard_node.position = base_position + Vector3(0.0, 0.55 + bob_height, 0.0)
