extends Node3D

const CAPTURE_DEFAULT_DELAY_MS := 2200
const CAPTURE_DEFAULT_PATH := "/tmp/builtaboat_buoyancy_preview.png"
const PREVIEW_SPEED := 1.8

var boat_root: Node3D
var water_mesh: MeshInstance3D
var camera: Camera3D
var preview_time := 0.0
var capture_queued := false

func _ready() -> void:
	DisplayServer.window_set_title("Buoyancy Preview")
	_build_preview_world()
	_prime_preview_state()
	_queue_capture()

func _process(delta: float) -> void:
	preview_time += delta
	NetworkRuntime.run_state["elapsed_time"] = preview_time
	var rotation_y := sin(preview_time * 0.38) * 0.18
	var world_position := Vector3(sin(preview_time * 0.22) * 1.4, 0.0, preview_time * PREVIEW_SPEED)
	NetworkRuntime.boat_state["position"] = world_position
	NetworkRuntime.boat_state["rotation_y"] = rotation_y
	NetworkRuntime.boat_state["speed"] = PREVIEW_SPEED
	var buoyancy_step := NetworkRuntime._step_boat_buoyancy(delta, world_position, rotation_y, PREVIEW_SPEED)
	for key in buoyancy_step.keys():
		NetworkRuntime.boat_state[key] = buoyancy_step[key]

	var ride_height_offset := -clampf((float(NetworkRuntime.boat_state.get("draft_ratio", 0.72)) - 0.72) * 0.85, -0.04, 0.34)
	var target_position := world_position + Vector3(
		0.0,
		0.36 + ride_height_offset + float(NetworkRuntime.boat_state.get("water_surface_offset", 0.0)) + float(NetworkRuntime.boat_state.get("buoyancy_heave", 0.0)),
		0.0
	)
	boat_root.position = target_position
	boat_root.rotation.y = rotation_y
	boat_root.rotation.x = float(NetworkRuntime.boat_state.get("buoyancy_pitch", 0.0))
	boat_root.rotation.z = float(NetworkRuntime.boat_state.get("buoyancy_roll", 0.0))
	water_mesh.position = Vector3(world_position.x, NetworkRuntime.SEA_SURFACE_Y, world_position.z)
	camera.look_at(boat_root.global_position + Vector3(0.0, 0.45, 0.0), Vector3.UP)

func _build_preview_world() -> void:
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.58, 0.77, 0.95)
	environment.environment.ambient_light_energy = 0.85
	environment.environment.ambient_light_color = Color(0.60, 0.68, 0.78)
	add_child(environment)

	var light := DirectionalLight3D.new()
	light.light_energy = 1.35
	light.rotation_degrees = Vector3(-52.0, 32.0, 0.0)
	add_child(light)

	water_mesh = MeshInstance3D.new()
	water_mesh.name = "Water"
	var water_plane := PlaneMesh.new()
	water_plane.size = Vector2(220.0, 220.0)
	water_plane.subdivide_width = 64
	water_plane.subdivide_depth = 64
	water_mesh.mesh = water_plane
	var water_material := StandardMaterial3D.new()
	water_material.albedo_color = Color(0.09, 0.42, 0.62)
	water_material.roughness = 0.12
	water_material.metallic = 0.02
	water_mesh.material_override = water_material
	add_child(water_mesh)

	boat_root = Node3D.new()
	boat_root.name = "BoatRoot"
	add_child(boat_root)

	var hull := MeshInstance3D.new()
	hull.name = "Hull"
	var hull_mesh := BoxMesh.new()
	hull_mesh.size = Vector3(2.8, 0.7, 5.7)
	hull.mesh = hull_mesh
	hull.position = Vector3(0.0, 0.35, 0.0)
	var hull_material := StandardMaterial3D.new()
	hull_material.albedo_color = Color(0.46, 0.28, 0.18)
	hull_material.roughness = 0.5
	hull.material_override = hull_material
	boat_root.add_child(hull)

	var deck := MeshInstance3D.new()
	deck.name = "Deck"
	var deck_mesh := BoxMesh.new()
	deck_mesh.size = Vector3(2.3, 0.12, 4.2)
	deck.mesh = deck_mesh
	deck.position = Vector3(0.0, 0.78, 0.0)
	var deck_material := StandardMaterial3D.new()
	deck_material.albedo_color = Color(0.75, 0.59, 0.37)
	deck.material_override = deck_material
	boat_root.add_child(deck)

	var mast := MeshInstance3D.new()
	mast.name = "Mast"
	var mast_mesh := CylinderMesh.new()
	mast_mesh.height = 2.8
	mast_mesh.top_radius = 0.08
	mast_mesh.bottom_radius = 0.1
	mast.mesh = mast_mesh
	mast.position = Vector3(0.0, 1.95, -0.15)
	var mast_material := StandardMaterial3D.new()
	mast_material.albedo_color = Color(0.84, 0.80, 0.70)
	mast.material_override = mast_material
	boat_root.add_child(mast)

	camera = Camera3D.new()
	camera.position = Vector3(5.2, 3.1, 8.8)
	camera.current = true
	add_child(camera)

func _prime_preview_state() -> void:
	NetworkRuntime.run_state = {
		"elapsed_time": 0.0,
		"spawn_chunk": [7, 7],
		"chunk_descriptors": [],
	}
	NetworkRuntime.boat_state = {
		"position": Vector3.ZERO,
		"rotation_y": 0.0,
		"speed": PREVIEW_SPEED,
		"draft_ratio": 0.76,
		"reserve_buoyancy": 2.8,
		"roll_resistance": 63.0,
		"pitch_resistance": 58.0,
		"heel_bias": 0.04,
		"trim_bias": -0.02,
		"hull_length": 4.9,
		"hull_beam": 2.5,
		"base_top_speed": 6.0,
		"water_surface_offset": 0.0,
		"buoyancy_heave": 0.0,
		"buoyancy_heave_velocity": 0.0,
		"buoyancy_pitch": 0.0,
		"buoyancy_pitch_velocity": 0.0,
		"buoyancy_roll": 0.0,
		"buoyancy_roll_velocity": 0.0,
	}

func _queue_capture() -> void:
	if capture_queued:
		return
	if "--disable-preview-capture" in OS.get_cmdline_user_args():
		return
	capture_queued = true
	var overrides := GameConfig.parse_cmdline_overrides()
	var capture_delay_ms := maxi(0, int(overrides.get("capture_frame_delay_ms", CAPTURE_DEFAULT_DELAY_MS)))
	get_tree().create_timer(float(capture_delay_ms) / 1000.0).timeout.connect(_capture_frame)

func _capture_frame() -> void:
	var overrides := GameConfig.parse_cmdline_overrides()
	var capture_path := str(overrides.get("capture_frame_path", CAPTURE_DEFAULT_PATH))
	if capture_path.is_empty():
		capture_path = CAPTURE_DEFAULT_PATH
	DirAccess.make_dir_recursive_absolute(capture_path.get_base_dir())
	var image := get_viewport().get_texture().get_image()
	var result := image.save_png(capture_path)
	if result == OK:
		print("Captured buoyancy preview frame to %s" % capture_path)
	else:
		push_warning("Failed to capture buoyancy preview frame to %s (error %d)." % [capture_path, result])
	get_tree().quit()
