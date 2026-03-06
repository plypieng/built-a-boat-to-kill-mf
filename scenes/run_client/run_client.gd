extends Node3D

var status_label: Label
var run_label: Label
var roster_label: Label
var boat_visual: MeshInstance3D
var bob_time := 0.0

func _ready() -> void:
	_build_world()
	_build_hud()
	_refresh_hud()

	NetworkRuntime.status_changed.connect(_on_status_changed)
	NetworkRuntime.peer_snapshot_changed.connect(_on_peer_snapshot_changed)
	NetworkRuntime.run_seed_changed.connect(_on_run_seed_changed)

func _process(delta: float) -> void:
	bob_time += delta
	if boat_visual != null:
		boat_visual.position.y = 0.35 + sin(bob_time * 1.35) * 0.08

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
	water_mesh.size = Vector2(120.0, 120.0)
	water.mesh = water_mesh
	var water_material := StandardMaterial3D.new()
	water_material.albedo_color = Color(0.10, 0.44, 0.66)
	water_material.roughness = 0.12
	water.material_override = water_material
	add_child(water)

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

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 5.5, 10.5)
	camera.look_at(Vector3(0.0, 0.6, 0.0), Vector3.UP)
	add_child(camera)

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
	heading.text = "Connected Run Placeholder"
	heading.add_theme_font_size_override("font_size", 22)
	layout.add_child(heading)

	run_label = Label.new()
	layout.add_child(run_label)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(status_label)

	roster_label = Label.new()
	roster_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(roster_label)

	var footer := Label.new()
	footer.text = "Milestone 0 shows the local dedicated-server handshake and a placeholder ocean scene."
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(footer)

func _refresh_hud() -> void:
	run_label.text = "Mode: %s | Run Seed: %d | Peer ID: %d" % [
		NetworkRuntime._mode_name(),
		NetworkRuntime.run_seed,
		multiplayer.get_unique_id(),
	]
	status_label.text = "Status: %s" % NetworkRuntime.status_message

	var peer_ids := NetworkRuntime.peer_snapshot.keys()
	peer_ids.sort()
	var lines := PackedStringArray()
	for peer_id in peer_ids:
		var peer_data: Dictionary = NetworkRuntime.peer_snapshot[peer_id]
		lines.append("%s - %s [%s]" % [
			str(peer_id),
			str(peer_data.get("name", "Unknown")),
			str(peer_data.get("status", "unknown")),
		])
	roster_label.text = "Crew Snapshot:\n%s" % ("\n".join(lines) if not lines.is_empty() else "No peers yet.")

func _on_status_changed(_message: String) -> void:
	_refresh_hud()

func _on_peer_snapshot_changed(_snapshot: Dictionary) -> void:
	_refresh_hud()

func _on_run_seed_changed(_seed: int) -> void:
	_refresh_hud()

