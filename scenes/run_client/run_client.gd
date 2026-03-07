extends Node3D

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

var status_label: Label
var run_label: Label
var station_label: Label
var interaction_label: Label
var roster_label: Label
var boat_label: Label
var boat_root: Node3D
var hull_mesh_instance: MeshInstance3D
var hull_material: StandardMaterial3D
var crew_container: Node3D
var hazard_container: Node3D
var station_container: Node3D
var loot_container: Node3D
var extraction_root: Node3D
var extraction_ring_material: StandardMaterial3D
var extraction_buoy_material: StandardMaterial3D
var extraction_label: Label3D
var camera: Camera3D
var result_layer: CanvasLayer
var result_panel: PanelContainer
var result_title_label: Label
var result_body_label: Label
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
var selected_station_index := 0
var last_known_phase := "running"
var station_visuals: Dictionary = {}
var hazard_visuals: Dictionary = {}
var loot_visuals: Dictionary = {}

func _ready() -> void:
	launch_overrides = GameConfig.parse_cmdline_overrides()
	_build_world()
	_build_hud()
	_build_result_overlay()
	_refresh_world()
	_refresh_hud()
	_schedule_optional_quit()
	_initialize_autopilot()
	print("Run client ready with seed %d and peer id %d." % [NetworkRuntime.run_seed, multiplayer.get_unique_id()])

	NetworkRuntime.status_changed.connect(_on_status_changed)
	NetworkRuntime.peer_snapshot_changed.connect(_on_peer_snapshot_changed)
	NetworkRuntime.run_seed_changed.connect(_on_run_seed_changed)
	NetworkRuntime.helm_changed.connect(_on_helm_changed)
	NetworkRuntime.boat_state_changed.connect(_on_boat_state_changed)
	NetworkRuntime.hazard_state_changed.connect(_on_hazard_state_changed)
	NetworkRuntime.station_state_changed.connect(_on_station_state_changed)
	NetworkRuntime.loot_state_changed.connect(_on_loot_state_changed)
	NetworkRuntime.run_state_changed.connect(_on_run_state_changed)

func _process(delta: float) -> void:
	connect_time_seconds += delta
	_update_boat_visual(delta)
	_update_hazard_visuals()
	_update_loot_visuals()
	_update_extraction_visual(delta)
	_update_camera()

func _physics_process(delta: float) -> void:
	station_request_cooldown = maxf(0.0, station_request_cooldown - delta)
	action_request_cooldown = maxf(0.0, action_request_cooldown - delta)

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

	if NetworkRuntime.get_peer_station_id(multiplayer.get_unique_id()) == "helm":
		NetworkRuntime.send_local_boat_input(
			float(input_state.get("throttle", 0.0)),
			float(input_state.get("steer", 0.0))
		)

func _build_world() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.46, 0.71, 0.92)

	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)

	var light := DirectionalLight3D.new()
	light.light_energy = 1.2
	light.rotation_degrees = Vector3(-48.0, 38.0, 0.0)
	add_child(light)

	var water := MeshInstance3D.new()
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(220.0, 220.0)
	water.mesh = water_mesh
	var water_material := StandardMaterial3D.new()
	water_material.albedo_color = Color(0.08, 0.43, 0.65)
	water_material.roughness = 0.14
	water.material_override = water_material
	add_child(water)

	hazard_container = Node3D.new()
	add_child(hazard_container)

	loot_container = Node3D.new()
	add_child(loot_container)

	extraction_root = Node3D.new()
	add_child(extraction_root)
	_build_extraction_visual()

	boat_root = Node3D.new()
	add_child(boat_root)

	hull_mesh_instance = MeshInstance3D.new()
	var hull_mesh := BoxMesh.new()
	hull_mesh.size = Vector3(3.3, 0.72, 6.2)
	hull_mesh_instance.mesh = hull_mesh
	hull_mesh_instance.position = Vector3(0.0, 0.35, 0.0)
	hull_material = StandardMaterial3D.new()
	hull_material.albedo_color = Color(0.44, 0.27, 0.16)
	hull_material.roughness = 0.46
	hull_mesh_instance.material_override = hull_material
	boat_root.add_child(hull_mesh_instance)

	var deck := MeshInstance3D.new()
	var deck_mesh := BoxMesh.new()
	deck_mesh.size = Vector3(2.7, 0.14, 4.6)
	deck.mesh = deck_mesh
	deck.position = Vector3(0.0, 0.78, 0.0)
	var deck_material := StandardMaterial3D.new()
	deck_material.albedo_color = Color(0.70, 0.56, 0.34)
	deck.material_override = deck_material
	boat_root.add_child(deck)

	var mast := MeshInstance3D.new()
	var mast_mesh := CylinderMesh.new()
	mast_mesh.height = 3.0
	mast_mesh.top_radius = 0.12
	mast_mesh.bottom_radius = 0.12
	mast.mesh = mast_mesh
	mast.position = Vector3(0.0, 2.0, -0.2)
	var mast_material := StandardMaterial3D.new()
	mast_material.albedo_color = Color(0.82, 0.79, 0.72)
	mast.material_override = mast_material
	boat_root.add_child(mast)

	station_container = Node3D.new()
	boat_root.add_child(station_container)
	_build_station_visuals()

	crew_container = Node3D.new()
	boat_root.add_child(crew_container)

	camera = Camera3D.new()
	camera.position = Vector3(0.0, 5.5, 10.5)
	add_child(camera)
	camera.look_at(Vector3(0.0, 0.6, 0.0), Vector3.UP)

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
	heading.text = "First Run Loop Prototype"
	heading.add_theme_font_size_override("font_size", 22)
	layout.add_child(heading)

	run_label = Label.new()
	run_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(run_label)

	station_label = Label.new()
	station_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(station_label)

	interaction_label = Label.new()
	interaction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(interaction_label)

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
	footer.text = "Controls: Q/E cycle station | F claim/release | W/S throttle | A/D steer | Space brace | G grapple."
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(footer)

func _build_result_overlay() -> void:
	result_layer = CanvasLayer.new()
	add_child(result_layer)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.03, 0.08, 0.14, 0.66)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_layer.add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_layer.add_child(center)

	result_panel = PanelContainer.new()
	result_panel.custom_minimum_size = Vector2(420.0, 0.0)
	center.add_child(result_panel)

	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_left", 24)
	inner.add_theme_constant_override("margin_top", 24)
	inner.add_theme_constant_override("margin_right", 24)
	inner.add_theme_constant_override("margin_bottom", 24)
	result_panel.add_child(inner)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	inner.add_child(layout)

	result_title_label = Label.new()
	result_title_label.add_theme_font_size_override("font_size", 26)
	layout.add_child(result_title_label)

	result_body_label = Label.new()
	result_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(result_body_label)

	result_layer.visible = false

func _refresh_world() -> void:
	_refresh_station_visuals()
	_refresh_crew_visuals()
	_refresh_hazard_visuals()
	_refresh_loot_visuals()
	_refresh_extraction_visual()
	_refresh_result_overlay()
	_update_boat_material()

func _refresh_hud() -> void:
	var local_peer_id := multiplayer.get_unique_id()
	var local_station_id := NetworkRuntime.get_peer_station_id(local_peer_id)
	var selected_station_id := _get_selected_station_id()
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var extraction_position: Vector3 = NetworkRuntime.run_state.get("extraction_position", Vector3.ZERO)
	var extraction_progress: float = float(NetworkRuntime.run_state.get("extraction_progress", 0.0))
	var extraction_duration: float = float(NetworkRuntime.run_state.get("extraction_duration", 1.0))
	var hull_integrity: float = float(NetworkRuntime.boat_state.get("hull_integrity", 100.0))
	var extraction_distance := boat_position.distance_to(extraction_position)

	run_label.text = "Phase: %s | Seed: %d | Cargo: %d | Loot Remaining: %d | Extract: %.1f/%.1fs | Dist: %.1f" % [
		str(NetworkRuntime.run_state.get("phase", "running")),
		NetworkRuntime.run_seed,
		int(NetworkRuntime.run_state.get("cargo_count", 0)),
		int(NetworkRuntime.run_state.get("loot_remaining", 0)),
		extraction_progress,
		extraction_duration,
		extraction_distance,
	]

	var station_lines := PackedStringArray()
	for station_id in NetworkRuntime.get_station_ids():
		var prefix := ">" if station_id == selected_station_id else " "
		var occupant_name := NetworkRuntime.get_station_occupant_name(station_id)
		station_lines.append("%s %s: %s" % [
			prefix,
			NetworkRuntime.get_station_label(station_id),
			occupant_name,
		])
	station_label.text = "Stations:\n%s" % ("\n".join(station_lines) if not station_lines.is_empty() else "No stations available.")

	interaction_label.text = _build_interaction_text(selected_station_id, local_station_id)
	boat_label.text = "Boat: hp=%.1f speed=%.2f pos=(%.2f, %.2f, %.2f) heading=%.2f collisions=%d lastImpact=%.1f braced=%s" % [
		hull_integrity,
		float(NetworkRuntime.boat_state.get("speed", 0.0)),
		boat_position.x,
		boat_position.y,
		boat_position.z,
		float(NetworkRuntime.boat_state.get("rotation_y", 0.0)),
		int(NetworkRuntime.boat_state.get("collision_count", 0)),
		float(NetworkRuntime.boat_state.get("last_impact_damage", 0.0)),
		"yes" if bool(NetworkRuntime.boat_state.get("last_impact_braced", false)) else "no",
	]
	status_label.text = "Status: %s" % NetworkRuntime.status_message

	var crew_lines := PackedStringArray()
	for peer_id in NetworkRuntime.get_player_peer_ids():
		var peer_data: Dictionary = NetworkRuntime.peer_snapshot[peer_id]
		var crew_station := NetworkRuntime.get_peer_station_id(int(peer_id))
		crew_lines.append("%s - %s [%s]" % [
			str(peer_id),
			str(peer_data.get("name", "Unknown")),
			NetworkRuntime.get_station_label(crew_station) if not crew_station.is_empty() else "Free Roam",
		])
	roster_label.text = "Crew Snapshot:\n%s" % ("\n".join(crew_lines) if not crew_lines.is_empty() else "No crew connected yet.")

func _build_interaction_text(selected_station_id: String, local_station_id: String) -> String:
	if selected_station_id.is_empty():
		return "No station selected."

	var selected_label := NetworkRuntime.get_station_label(selected_station_id)
	var occupant_name := NetworkRuntime.get_station_occupant_name(selected_station_id)
	var occupant_peer_id := int(NetworkRuntime.station_state.get(selected_station_id, {}).get("occupant_peer_id", 0))
	var local_peer_id := multiplayer.get_unique_id()
	var lines := PackedStringArray()
	lines.append("Selected: %s" % selected_label)

	if occupant_peer_id == 0:
		lines.append("Press F to claim this station.")
	elif occupant_peer_id == local_peer_id:
		lines.append("You occupy this station. Press F to release it.")
	else:
		lines.append("%s is using this station." % occupant_name)

	if local_station_id == "helm":
		lines.append("Drive with W/S for throttle and A/D for steering.")
	elif local_station_id == "brace":
		lines.append("Press Space to brace for the next impact window.")
	elif local_station_id == "grapple":
		lines.append("Press G to reel nearby loot into cargo.")
	else:
		lines.append("Cycle stations with Q and E.")

	if str(NetworkRuntime.run_state.get("phase", "running")) != "running":
		lines.append("Run complete. The result panel shows the final outcome.")

	return "\n".join(lines)

func _refresh_station_visuals() -> void:
	_ensure_selected_station_valid()
	var local_peer_id := multiplayer.get_unique_id()
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
		var color := STATION_BASE_COLOR
		if occupant_peer_id == local_peer_id and occupant_peer_id != 0:
			color = STATION_LOCAL_COLOR
		elif occupant_peer_id != 0:
			color = STATION_OCCUPIED_COLOR
		if station_id == selected_station_id:
			color = color.lerp(STATION_SELECTED_COLOR, 0.45)

		var base_material := StandardMaterial3D.new()
		base_material.albedo_color = color.darkened(0.08)
		base_mesh.material_override = base_material

		var beacon_material := StandardMaterial3D.new()
		beacon_material.albedo_color = color
		beacon_mesh.material_override = beacon_material

		var occupant_name := NetworkRuntime.get_station_occupant_name(station_id)
		label.text = "%s\n%s" % [NetworkRuntime.get_station_label(station_id), occupant_name]
		label.modulate = color.lightened(0.22)

func _refresh_crew_visuals() -> void:
	for child in crew_container.get_children():
		child.queue_free()

	var idle_slot_index := 0
	for peer_id in NetworkRuntime.get_player_peer_ids():
		var peer_data: Dictionary = NetworkRuntime.peer_snapshot[peer_id]
		var crew_member := Node3D.new()
		var station_id := NetworkRuntime.get_peer_station_id(int(peer_id))
		if not station_id.is_empty():
			crew_member.position = NetworkRuntime.get_station_position(station_id) + Vector3(0.0, 0.18, 0.0)
		else:
			crew_member.position = IDLE_CREW_SLOTS[idle_slot_index % IDLE_CREW_SLOTS.size()]
			idle_slot_index += 1
		crew_container.add_child(crew_member)

		var body := MeshInstance3D.new()
		var body_mesh := CapsuleMesh.new()
		body_mesh.height = 1.2
		body_mesh.radius = 0.24
		body.mesh = body_mesh
		var material := StandardMaterial3D.new()
		if int(peer_id) == multiplayer.get_unique_id():
			material.albedo_color = Color(0.30, 0.82, 0.52)
		elif station_id == "helm":
			material.albedo_color = Color(0.94, 0.76, 0.18)
		else:
			material.albedo_color = Color(0.70, 0.84, 0.93)
		body.material_override = material
		crew_member.add_child(body)

		var nameplate := Label3D.new()
		var role_label := NetworkRuntime.get_station_label(station_id) if not station_id.is_empty() else "Crew"
		nameplate.text = "%s\n%s" % [str(peer_data.get("name", "Crew")), role_label]
		nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		nameplate.font_size = 24
		nameplate.position = Vector3(0.0, 0.96, 0.0)
		crew_member.add_child(nameplate)

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

	var cargo_count := int(NetworkRuntime.run_state.get("cargo_count", 0))
	var cargo_secured := int(NetworkRuntime.run_state.get("cargo_secured", 0))
	var cargo_lost: int = maxi(0, cargo_count - cargo_secured)
	result_title_label.text = str(NetworkRuntime.run_state.get("result_title", "Run Complete"))
	result_body_label.text = "%s\n\nCollected: %d\nSecured: %d\nLost: %d" % [
		str(NetworkRuntime.run_state.get("result_message", "")),
		cargo_count,
		cargo_secured,
		cargo_lost,
	]
	result_panel.modulate = Color(0.98, 1.0, 0.98) if phase == "success" else Color(1.0, 0.94, 0.94)

func _collect_input_state(delta: float) -> Dictionary:
	var input_state := {
		"claim_station": "",
		"request_brace": false,
		"request_grapple": false,
		"throttle": 0.0,
		"steer": 0.0,
	}

	_collect_station_selection_input()
	_collect_station_interaction_input(input_state)
	_collect_action_input(input_state)
	_collect_drive_input(input_state)

	if bool(launch_overrides.get("autorun_demo", false)):
		_apply_autorun_demo(delta, input_state)
	else:
		_apply_scripted_station_input(delta, input_state)

	return input_state

func _collect_station_selection_input() -> void:
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
		var selected_station_id := _get_selected_station_id()
		var selected_station: Dictionary = NetworkRuntime.station_state.get(selected_station_id, {})
		var occupant_peer_id := int(selected_station.get("occupant_peer_id", 0))
		if occupant_peer_id == multiplayer.get_unique_id():
			input_state["claim_station"] = "__release__"
		elif occupant_peer_id == 0:
			input_state["claim_station"] = selected_station_id
	interact_latched = interact_pressed

func _collect_action_input(input_state: Dictionary) -> void:
	var local_station_id := NetworkRuntime.get_peer_station_id(multiplayer.get_unique_id())

	var brace_pressed := Input.is_key_pressed(KEY_SPACE)
	if brace_pressed and not brace_request_latched and local_station_id == "brace":
		input_state["request_brace"] = true
	brace_request_latched = brace_pressed

	var grapple_pressed := Input.is_key_pressed(KEY_G)
	if grapple_pressed and not grapple_request_latched and local_station_id == "grapple":
		input_state["request_grapple"] = true
	grapple_request_latched = grapple_pressed

func _collect_drive_input(input_state: Dictionary) -> void:
	if NetworkRuntime.get_peer_station_id(multiplayer.get_unique_id()) != "helm":
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
		_request_station_if_needed(desired_station_id, input_state)

	if desired_station_id == "helm" and autopilot_remaining_seconds > 0.0 and NetworkRuntime.get_peer_station_id(multiplayer.get_unique_id()) == "helm":
		input_state["throttle"] = float(launch_overrides.get("autodrive_throttle", 1.0))
		input_state["steer"] = float(launch_overrides.get("autodrive_steer", 0.0))
	elif desired_station_id == "brace" and bool(launch_overrides.get("autobrace", false)) and NetworkRuntime.get_peer_station_id(multiplayer.get_unique_id()) == "brace" and action_request_cooldown <= 0.0 and _should_autobrace():
		input_state["request_brace"] = true
		action_request_cooldown = 0.35

func _apply_autorun_demo(_delta: float, input_state: Dictionary) -> void:
	if str(NetworkRuntime.run_state.get("phase", "running")) != "running":
		return

	var local_station_id := NetworkRuntime.get_peer_station_id(multiplayer.get_unique_id())
	var cargo_count := int(NetworkRuntime.run_state.get("cargo_count", 0))
	var loot_remaining := int(NetworkRuntime.run_state.get("loot_remaining", 0))
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var boat_speed: float = float(NetworkRuntime.boat_state.get("speed", 0.0))

	if cargo_count == 0 and loot_remaining > 0:
		if boat_position.distance_to(Vector3(0.0, 0.0, 3.1)) > 1.0:
			_request_station_if_needed("helm", input_state)
			if local_station_id == "helm":
				_apply_drive_to_target(Vector3(0.0, 0.0, 3.1), input_state)
			return

		_request_station_if_needed("grapple", input_state)
		if local_station_id == "grapple" and action_request_cooldown <= 0.0:
			input_state["request_grapple"] = true
			action_request_cooldown = 0.45
		return

	_request_station_if_needed("helm", input_state)
	if local_station_id != "helm":
		return

	var extraction_position: Vector3 = NetworkRuntime.run_state.get("extraction_position", Vector3.ZERO)
	var extraction_radius: float = float(NetworkRuntime.run_state.get("extraction_radius", 3.7))
	var target := Vector3(-4.2, 0.0, 20.0) if boat_position.z < 18.0 else Vector3(-2.0, 0.0, extraction_position.z)
	if boat_position.distance_to(extraction_position) <= extraction_radius + 0.6:
		input_state["steer"] = clampf(-boat_position.x * 0.14, -0.6, 0.6)
		input_state["throttle"] = -0.35 if boat_speed > NetworkRuntime.EXTRACTION_MAX_SPEED else 0.0
		return

	_apply_drive_to_target(target, input_state)

func _apply_drive_to_target(target: Vector3, input_state: Dictionary) -> void:
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var rotation_y: float = float(NetworkRuntime.boat_state.get("rotation_y", 0.0))
	var current_speed: float = float(NetworkRuntime.boat_state.get("speed", 0.0))
	var to_target := target - boat_position
	var distance := to_target.length()
	var local_offset := to_target.rotated(Vector3.UP, -rotation_y)
	var steer := clampf(local_offset.x * 0.25, -1.0, 1.0)
	var throttle := 1.0
	if distance < 8.0:
		throttle = 0.58
	if distance < 3.0:
		throttle = 0.18
	if distance < 1.25:
		throttle = -0.25 if current_speed > 1.2 else 0.0
	if local_offset.z < 0.4 and absf(local_offset.x) > 0.9:
		throttle = minf(throttle, 0.2)

	input_state["steer"] = steer
	input_state["throttle"] = throttle

func _request_station_if_needed(station_id: String, input_state: Dictionary) -> void:
	if station_request_cooldown > 0.0:
		return
	if NetworkRuntime.get_peer_station_id(multiplayer.get_unique_id()) == station_id:
		return

	var station_data: Dictionary = NetworkRuntime.station_state.get(station_id, {})
	var occupant_peer_id := int(station_data.get("occupant_peer_id", 0))
	if occupant_peer_id != 0 and occupant_peer_id != multiplayer.get_unique_id():
		return

	input_state["claim_station"] = station_id
	_select_station(station_id)
	station_request_cooldown = 0.35

func _should_autobrace() -> bool:
	if float(NetworkRuntime.boat_state.get("brace_cooldown", 0.0)) > 0.0:
		return false

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

func _update_extraction_visual(_delta: float) -> void:
	var extraction_position: Vector3 = NetworkRuntime.run_state.get("extraction_position", Vector3.ZERO)
	extraction_root.position = extraction_position + Vector3(0.0, sin(connect_time_seconds * 0.95) * 0.08, 0.0)

func _update_camera() -> void:
	if camera == null:
		return

	var boat_anchor := boat_root.position + Vector3(0.0, 1.8, 0.0)
	var follow_offset := Vector3(0.0, 4.7, 10.4).rotated(Vector3.UP, boat_root.rotation.y)
	camera.position = boat_anchor + follow_offset
	camera.look_at(boat_anchor, Vector3.UP)

func _update_boat_material() -> void:
	if hull_material == null:
		return

	var hull_integrity: float = float(NetworkRuntime.boat_state.get("hull_integrity", 100.0))
	var health_ratio := clampf(hull_integrity / 100.0, 0.0, 1.0)
	var damaged_color := Color(0.45, 0.14, 0.12)
	var healthy_color := Color(0.44, 0.27, 0.16)
	hull_material.albedo_color = damaged_color.lerp(healthy_color, health_ratio)

func _boat_within_extraction_zone() -> bool:
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var extraction_position: Vector3 = NetworkRuntime.run_state.get("extraction_position", Vector3.ZERO)
	var extraction_radius: float = float(NetworkRuntime.run_state.get("extraction_radius", 3.7))
	return boat_position.distance_to(extraction_position) <= extraction_radius

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
	print("Client auto-quit triggered. Final run state: %s | boat=%s" % [
		str(NetworkRuntime.run_state),
		str(NetworkRuntime.boat_state),
	])
	get_tree().quit()

func _initialize_autopilot() -> void:
	autopilot_remaining_seconds = float(int(launch_overrides.get("autodrive_ms", 0))) / 1000.0
	if bool(launch_overrides.get("autorun_demo", false)):
		_select_station("helm")
	elif not str(launch_overrides.get("autoclaim_station", "")).is_empty():
		_select_station(str(launch_overrides.get("autoclaim_station", "")))

func _ensure_selected_station_valid() -> void:
	var station_ids := NetworkRuntime.get_station_ids()
	if station_ids.is_empty():
		selected_station_index = 0
		return
	selected_station_index = wrapi(selected_station_index, 0, station_ids.size())

func _cycle_selected_station(direction: int) -> void:
	var station_ids := NetworkRuntime.get_station_ids()
	if station_ids.is_empty():
		return
	selected_station_index = wrapi(selected_station_index + direction, 0, station_ids.size())
	_refresh_station_visuals()
	_refresh_hud()

func _get_selected_station_id() -> String:
	var station_ids := NetworkRuntime.get_station_ids()
	if station_ids.is_empty():
		return ""
	selected_station_index = wrapi(selected_station_index, 0, station_ids.size())
	return str(station_ids[selected_station_index])

func _select_station(station_id: String) -> void:
	var station_ids := NetworkRuntime.get_station_ids()
	var station_index := station_ids.find(station_id)
	if station_index == -1:
		return
	selected_station_index = station_index
	_refresh_station_visuals()
	_refresh_hud()

func _on_status_changed(_message: String) -> void:
	_refresh_hud()

func _on_peer_snapshot_changed(_snapshot: Dictionary) -> void:
	_refresh_crew_visuals()
	_refresh_station_visuals()
	_refresh_hud()

func _on_run_seed_changed(_seed: int) -> void:
	_refresh_hud()

func _on_helm_changed(_driver_peer_id: int) -> void:
	_refresh_crew_visuals()
	_refresh_hud()

func _on_boat_state_changed(_state: Dictionary) -> void:
	_update_boat_material()
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
	_refresh_extraction_visual()
	_refresh_hud()

func _on_run_state_changed(_state: Dictionary) -> void:
	var phase := str(NetworkRuntime.run_state.get("phase", "running"))
	if phase != last_known_phase:
		print("Run phase changed: %s" % phase)
		last_known_phase = phase
	_refresh_extraction_visual()
	_refresh_result_overlay()
	_refresh_hud()
