extends Node3D

const HANGAR_SCENE := "res://scenes/hangar/hangar.tscn"
const LOADING_SCENE := "res://scenes/boot/loading_screen.tscn"
const RUN_PLAYER_CONTROLLER_SCENE := preload("res://scenes/shared/avatar/run_player_controller.tscn")
const RUN_STATION_MARKER_SCENE := preload("res://scenes/run_client/markers/run_station_marker.tscn")
const RUN_RECOVERY_MARKER_SCENE := preload("res://scenes/run_client/markers/run_recovery_marker.tscn")
const OPEN_OCEAN_CHUNK_SCENE := preload("res://scenes/run_client/chunks/open_ocean_chunk_visual.tscn")
const REEF_CHUNK_SCENE := preload("res://scenes/run_client/chunks/reef_chunk_visual.tscn")
const FOG_BANK_CHUNK_SCENE := preload("res://scenes/run_client/chunks/fog_bank_chunk_visual.tscn")
const STORM_BELT_CHUNK_SCENE := preload("res://scenes/run_client/chunks/storm_belt_chunk_visual.tscn")
const GRAVEYARD_CHUNK_SCENE := preload("res://scenes/run_client/chunks/graveyard_chunk_visual.tscn")
const DRIFT_BUOY_PROP_SCENE := preload("res://scenes/run_client/chunks/drift_buoy_prop.tscn")
const REEF_SPIRE_PROP_SCENE := preload("res://scenes/run_client/chunks/reef_spire_prop.tscn")
const GRAVEYARD_SPAR_PROP_SCENE := preload("res://scenes/run_client/chunks/graveyard_spar_prop.tscn")
const SALVAGE_SITE_MARKER_SCENE := preload("res://scenes/run_client/sites/salvage_site_marker.tscn")
const DISTRESS_SITE_MARKER_SCENE := preload("res://scenes/run_client/sites/distress_site_marker.tscn")
const RESUPPLY_SITE_MARKER_SCENE := preload("res://scenes/run_client/sites/resupply_site_marker.tscn")
const EXTRACTION_OUTPOST_MARKER_SCENE := preload("res://scenes/run_client/sites/extraction_outpost_marker.tscn")
const RunWorldGenerator = preload("res://systems/worldgen/run_world_generator.gd")
const HudIconLibrary = preload("res://scenes/shared/hud_icon_library.gd")
const ExpeditionHudSkin = preload("res://scenes/shared/expedition_hud_skin.gd")
const BoatBlockMaterials = preload("res://scenes/shared/boat_block_materials.gd")
const SeaSkyRigScene = preload("res://scenes/shared/environment/sea_sky_rig.tscn")
const PHANTOM_CAMERA_HOST_SCRIPT := preload("res://addons/phantom_camera/scripts/phantom_camera_host/phantom_camera_host.gd")
const PHANTOM_CAMERA_3D_SCRIPT := preload("res://addons/phantom_camera/scripts/phantom_camera/phantom_camera_3d.gd")
const SPATIAL_AUDIO_PLAYER_3D_SCRIPT := preload("res://addons/spatial_audio_extended/spatial_audio_player_3d.gd")
const ACOUSTIC_BODY_SCRIPT := preload("res://addons/spatial_audio_extended/acoustic_body.gd")
const WOOD_ACOUSTIC_MATERIAL := preload("res://addons/spatial_audio_extended/presets/materials/wood.tres")
const METAL_ACOUSTIC_MATERIAL := preload("res://addons/spatial_audio_extended/presets/materials/metal.tres")
const TRAIL_RENDERER_SCRIPT := preload("res://addons/TrailRenderer/Runtime/GD/trail_renderer.gd")
const TERRAIN_PREVIEW_SCENE := preload("res://scenes/tools/terrain3d_preview.tscn")
const OpenSeaWaterShader = preload("res://shaders/open_sea_water.gdshader")
const OpenSeaAbyssShader = preload("res://shaders/open_sea_abyss.gdshader")
const OpenSeaWakeShader = preload("res://shaders/open_sea_wake.gdshader")
const OpenSeaContactFoamShader = preload("res://shaders/open_sea_contact_foam.gdshader")
const OpenSeaSplashShader = preload("res://shaders/open_sea_splash.gdshader")
const SquallStreaksShader = preload("res://shaders/squall_streaks.gdshader")
const StormWallShader = preload("res://shaders/storm_wall.gdshader")
const SEA_HDRI_PATH := "res://assets/third_party/polyhaven/overcast_soil_puresky_2k.hdr"
const SEA_FOAM_MASK_TEXTURE_PATH := "res://assets/third_party/ambientcg/Foam001_Opacity.jpg"
const SEA_FOAM_COLOR_TEXTURE_PATH := "res://assets/third_party/ambientcg/Foam001_Color.jpg"
const SEA_FOAM_SPRAY_TEXTURE_PATH := "res://assets/third_party/ambientcg/Foam001_RGBA.png"
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
const RUN_AVATAR_AIR_ACCELERATION := 7.5
const RUN_AVATAR_JUMP_VELOCITY := 5.4
const RUN_AVATAR_GRAVITY := 18.0
const RUN_AVATAR_FLOOR_SNAP_LENGTH := 0.42
const RUN_AVATAR_SUPPORT_DROP_THRESHOLD := 0.16
const RUN_AVATAR_OVERBOARD_ENTRY_BUFFER := 0.14
const RUN_AVATAR_EDGE_EXIT_GRACE_DISTANCE := 0.42
const RUN_AIRBORNE_DECK_CATCH_MARGIN := 0.58
const RUN_AIRBORNE_DECK_CATCH_BELOW_TOLERANCE := 0.18
const RUN_AIRBORNE_OFFBOARD_COMMIT_DELAY := 0.14
const RUN_AIRBORNE_OFFBOARD_COMMIT_DISTANCE := 0.82
const RUN_AIRBORNE_OFFBOARD_RETURN_WINDOW := 0.34
const RUN_AIRBORNE_RETURN_MAX_ASCEND_SPEED := 1.1
const RUN_WATER_ENTRY_RELAND_HORIZONTAL_GRACE := 0.34
const RUN_WATER_ENTRY_RELAND_VERTICAL_GRACE := 0.52
const RUN_WATER_ENTRY_GRAVITY := 20.0
const RUN_REBOARD_SETTLE_DURATION := 0.32
const RUN_WATER_ENTRY_MAX_DURATION := 1.35
const RUN_WATER_ENTRY_SURFACE_BLEND_HEIGHT := 0.9
const RUN_OFF_DECK_BLEND_DURATION := 1.05
const RUN_SURFACE_TREAD_SETTLE_DURATION := 1.45
const RUN_SURFACE_TREAD_BOB_SPEED := 2.7
const RUN_SURFACE_TREAD_BOB_AMPLITUDE := 0.08
const RUN_SURFACE_TREAD_LEAN_MAX := 0.12
const RUN_BRACE_KEY := KEY_B
const RUN_DEBUG_OVERLAY_TOGGLE_KEY := KEY_F3
const RUN_SWIM_MOVE_SPEED := 2.6
const RUN_SWIM_ACCELERATION := 8.5
const RUN_AVATAR_SPRINT_MULTIPLIER := 1.35
const RUN_SWIM_BURST_MULTIPLIER := 1.25
const RUN_SWIM_BOAT_CARRY_MIN := 0.18
const RUN_SWIM_BOAT_CARRY_MAX := 0.42
const RUN_SWIM_STERN_DRIFT_RADIUS := 3.1
const RUN_SWIM_STERN_DRIFT_PULL := 1.15
const RUN_SWIM_HULL_CORE_FACTOR := 0.86
const RUN_SWIM_JUMP_VELOCITY := 4.8
const RUN_SWIM_JUMP_FORWARD_BOOST := 2.4
const RUN_SWIM_JUMP_COOLDOWN := 0.34
const RUN_CLIMB_SPEED := 2.3
const RUN_CLIMB_SHIMMY_SPEED := 1.5
const RUN_CLIMB_TOP_OUT_DISTANCE := 0.28
const RUN_CLIMB_ATTACH_BUFFER := 0.42
const RUN_CLIMB_JUMP_OFF_UPWARD := 3.7
const RUN_CLIMB_JUMP_OFF_PUSH := 2.4
const RUN_AVATAR_SYNC_INTERVAL := 0.05
const RUN_BLOCK_COLLISION_LAYER := 1
const ASSIST_RALLY_HOLD_SECONDS := 1.5
const LOCAL_RUN_TRANSITION_DECK := "deck"
const LOCAL_RUN_TRANSITION_AIRBORNE_DECK := "airborne_deck"
const LOCAL_RUN_TRANSITION_AIRBORNE_OFFBOARD := "airborne_offboard"
const WATER_SURFACE_Y := -0.12
const WATER_SURFACE_SIZE := 640.0
const WATER_SURFACE_SUBDIVISIONS := 220
const OCEAN_ABYSS_DEPTH := 220.0
const OCEAN_ABYSS_RADIUS := 560.0
const OCEAN_FLOOR_SIZE := 1120.0
const OCEAN_WALL_HEIGHT := 260.0
const OCEAN_WALL_DISTANCE := 540.0
const HUD_PANEL_BG := ExpeditionHudSkin.STORM_PANEL
const HUD_PANEL_BG_SOFT := ExpeditionHudSkin.STORM_PANEL_SOFT
const HUD_BORDER_BLUE := ExpeditionHudSkin.OXIDIZED_TEAL
const HUD_BORDER_ORANGE := ExpeditionHudSkin.BUOY_ORANGE
const HUD_BORDER_GREEN := ExpeditionHudSkin.SEA_GLASS_GREEN
const HUD_TEXT_PRIMARY := ExpeditionHudSkin.TEXT_PRIMARY
const HUD_TEXT_MUTED := ExpeditionHudSkin.TEXT_MUTED
const HUD_TEXT_WARNING := ExpeditionHudSkin.TEXT_WARNING
const HUD_TEXT_DANGER := ExpeditionHudSkin.TEXT_DANGER
const HUD_TEXT_SUCCESS := ExpeditionHudSkin.TEXT_SUCCESS

@export_group("Run Camera")
@export_range(-3.0, 3.0, 0.05) var run_camera_side_offset := 0.9
@export_range(0.5, 6.0, 0.05) var run_camera_height := 1.8
@export_range(1.0, 14.0, 0.05) var run_camera_distance := 6.4
@export_range(0.5, 4.0, 0.05) var run_camera_look_height := 1.32
@export_range(0.0, 6.0, 0.05) var run_camera_look_ahead := 2.1
@export_range(0.1, 20.0, 0.1) var run_camera_lag := 8.0
@export_range(0.001, 0.02, 0.0001) var run_mouse_look_sensitivity := 0.0035
@export_range(-89.0, 0.0, 0.5) var run_camera_pitch_min_degrees := -58.0
@export_range(0.0, 89.0, 0.5) var run_camera_pitch_max_degrees := 44.0
@export_range(-45.0, 45.0, 0.5) var run_camera_pitch_default_degrees := -7.0

var status_label: Label
var objective_label: Label
var clock_label: Label
var pressure_clock_label: Label
var compass_label: Label
var resource_label: Label
var run_label: Label
var station_label: Label
var interaction_label: Label
var boat_label: Label
var health_meter_label: Label
var stamina_meter_label: Label
var health_meter_bar: ProgressBar
var stamina_meter_bar: ProgressBar
var stage_clock_progress_bar: ProgressBar
var event_callout_label: Label
var toolbelt_label: Label
var inventory_label: Label
var hotbar_slot_panels: Array = []
var hotbar_slot_key_labels: Array = []
var hotbar_slot_name_labels: Array = []
var hotbar_slot_icons: Array = []
var boat_root: Node3D
var chunk_container: Node3D
var water_mesh_instance: MeshInstance3D
var water_shader_material: ShaderMaterial
var ocean_body_root: Node3D
var ocean_floor_mesh_instance: MeshInstance3D
var ocean_abyss_materials: Array[ShaderMaterial] = []
var sun_light: DirectionalLight3D
var storm_wall_container: Node3D
var hull_mesh_instance: MeshInstance3D
var hull_material: StandardMaterial3D
var deck_mesh_instance: MeshInstance3D
var mast_mesh_instance: MeshInstance3D
var main_block_container: Node3D
var sinking_chunk_container: Node3D
var crew_container: Node3D
var local_run_avatar_controller: CharacterBody3D
var wake_root: Node3D
var wake_mesh_instance: MeshInstance3D
var wake_material: ShaderMaterial
var boat_contact_foam_mesh: MeshInstance3D
var boat_contact_foam_material: ShaderMaterial
var bow_spray_left: MeshInstance3D
var bow_spray_left_material: ShaderMaterial
var bow_spray_right: MeshInstance3D
var bow_spray_right_material: ShaderMaterial
var bow_spray_left_particles: GPUParticles3D
var bow_spray_right_particles: GPUParticles3D
var wake_mist_particles: GPUParticles3D
var splash_container: Node3D
var hazard_container: Node3D
var squall_container: Node3D
var station_container: Node3D
var recovery_container: Node3D
var debug_overlay_container: Node3D
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
var salvage_site_container: Node3D
var distress_site_container: Node3D
var resupply_site_container: Node3D
var extraction_site_container: Node3D
var camera: Camera3D
var phantom_runtime_camera: Camera3D
var phantom_camera_host: Node
var phantom_follow_camera: Node3D
var phantom_overview_camera: Node3D
var result_layer: CanvasLayer
var result_panel: PanelContainer
var result_title_label: Label
var result_body_label: Label
var result_continue_button: Button
var crosshair_label: Label
var tool_panel: PanelContainer
var inventory_panel: PanelContainer
var boat_inspect_panel: PanelContainer
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
var item_use_request_latched := false
var selected_station_index := 0
var last_known_phase := "running"
var station_visuals: Dictionary = {}
var recovery_visuals: Dictionary = {}
var chunk_visuals: Dictionary = {}
var hazard_visuals: Dictionary = {}
var loot_visuals: Dictionary = {}
var salvage_site_visuals: Dictionary = {}
var distress_site_visuals: Dictionary = {}
var resupply_site_visuals: Dictionary = {}
var extraction_site_visuals: Dictionary = {}
var main_block_visuals: Dictionary = {}
var sinking_chunk_visuals: Dictionary = {}
var crew_visuals: Dictionary = {}
var squall_visuals: Dictionary = {}
var splash_visuals: Array = []
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
var local_run_avatar_grounded := true
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
var last_hud_downed_count := 0
var last_hud_phase := "running"
var last_local_overboard := false
var last_local_downed := false
var local_jump_latched := false
var local_water_entry_active := false
var local_water_entry_elapsed := 0.0
var local_overboard_transition_pending := false
var local_off_deck_entry_elapsed := RUN_OFF_DECK_BLEND_DURATION
var local_surface_tread_active := false
var local_surface_tread_elapsed := 0.0
var local_surface_contact_feedback_timer := 0.0
var local_reboard_settle_timer := 0.0
var local_swim_jump_cooldown := 0.0
var local_run_transition_state := LOCAL_RUN_TRANSITION_DECK
var local_run_transition_elapsed := 0.0
var local_run_offboard_elapsed := 0.0
var local_last_stable_deck_position := IDLE_CREW_SLOTS[0]
var local_last_stable_deck_world_position := Vector3.ZERO
var local_climb_surface_candidate_cache: Dictionary = {}
var local_climb_surface_candidate_cache_frame := -1
var local_climb_surface_candidate_cache_include_ladders := true
var local_climb_surface_candidate_cache_world_position := Vector3.ZERO
var debug_overlay_enabled := false
var boat_visual_velocity := Vector3.ZERO
var selected_run_tool_index := 0
var inventory_panel_visible := false
var assist_rally_hold_target_peer_id := 0
var assist_rally_hold_seconds := 0.0
var hud_icons := HudIconLibrary.new()
var stage_clock_icon: TextureRect
var objective_icon: TextureRect
var inspect_panel_icon: TextureRect
var result_panel_icon: TextureRect
var wind_audio_player: AudioStreamPlayer3D
var hull_audio_player: AudioStreamPlayer3D
var storm_audio_player: AudioStreamPlayer3D
var wind_audio_playback: AudioStreamGeneratorPlayback
var hull_audio_playback: AudioStreamGeneratorPlayback
var storm_audio_playback: AudioStreamGeneratorPlayback
var wind_audio_time := 0.0
var hull_audio_time := 0.0
var storm_audio_time := 0.0
var sea_hdri_texture: Texture2D
var sea_foam_mask_texture: Texture2D
var sea_foam_color_texture: Texture2D
var sea_foam_spray_texture: Texture2D
var sea_water_wave_texture: NoiseTexture2D
var sea_water_normal_texture: NoiseTexture2D
var sea_water_normal_texture_secondary: NoiseTexture2D
var sea_sky_rig: SeaSkyRig
var debug_overlay_visuals: Dictionary = {}
var wake_trail_renderer: Node3D
var terrain_preview_root: Node3D

func _ready() -> void:
	launch_overrides = GameConfig.parse_cmdline_overrides()
	local_camera_pitch = _get_run_camera_pitch_default()
	_build_world()
	_ensure_procedural_audio()
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
	local_surface_contact_feedback_timer = maxf(0.0, local_surface_contact_feedback_timer - delta)
	local_reboard_settle_timer = maxf(0.0, local_reboard_settle_timer - delta)
	_tick_reaction_visuals(delta)
	_update_sea_presentation(delta)
	_update_sea_audio()
	_update_sinking_chunk_visuals(delta)
	_update_splash_bursts(delta)
	_update_crew_visuals(delta)
	_update_hazard_visuals()
	_update_loot_visuals()
	_refresh_debug_overlay_visuals()
	_update_wreck_visual()
	_update_rescue_visual()
	_update_cache_visual()
	_update_squall_visuals()
	_update_extraction_visual(delta)
	_update_camera(delta)
	_update_terrain_preview()
	_draw_debug_draw_overlay()
	_update_event_callout(delta)

func _physics_process(delta: float) -> void:
	if NetworkRuntime.multiplayer == null or NetworkRuntime.multiplayer.multiplayer_peer == null:
		NetworkRuntime.server_step_shared_boat(delta)
	_update_boat_visual(delta)
	_update_runtime_block_visuals()
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
	if bool(input_state.get("request_propulsion_primary", false)):
		NetworkRuntime.request_propulsion_primary()
	if bool(input_state.get("request_propulsion_secondary", false)):
		NetworkRuntime.request_propulsion_secondary()
	var assist_target_peer_id := int(input_state.get("assist_target_peer_id", 0))
	if assist_target_peer_id > 0:
		NetworkRuntime.request_assist_rally(assist_target_peer_id)

	if not _is_local_off_deck() and not _is_local_downed() and NetworkRuntime.get_peer_station_id(_get_local_peer_id()) == "helm":
		NetworkRuntime.send_local_boat_input(
			float(input_state.get("throttle", 0.0)),
			float(input_state.get("steer", 0.0))
		)

func _build_world() -> void:
	_ensure_world_environment()
	if get_node_or_null("Environment/Water") == null:
		_build_static_world_fallback()

	chunk_container = _ensure_root_node3d("ChunkContainer")
	storm_wall_container = _ensure_root_node3d("StormWallContainer")
	hazard_container = _ensure_root_node3d("HazardContainer")
	squall_container = _ensure_root_node3d("SquallContainer")
	splash_container = _ensure_root_node3d("SplashContainer")
	loot_container = _ensure_root_node3d("LootContainer")
	salvage_site_container = _ensure_root_node3d("SalvageSiteContainer")
	distress_site_container = _ensure_root_node3d("DistressSiteContainer")
	resupply_site_container = _ensure_root_node3d("ResupplySiteContainer")
	extraction_site_container = _ensure_root_node3d("ExtractionSiteContainer")

	sinking_chunk_container = _ensure_root_node3d("SinkingChunkContainer")
	debug_overlay_container = _ensure_root_node3d("DebugOverlayContainer")
	debug_overlay_container.top_level = true
	_build_debug_overlay_visuals()

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
	_build_local_run_avatar_controller()
	wake_root = _ensure_child_node3d(boat_root, "WakeRoot")
	_ensure_sea_fx()

	camera = get_node_or_null("RunCamera") as Camera3D
	if camera == null:
		camera = Camera3D.new()
		camera.name = "RunCamera"
		camera.position = Vector3(0.0, 5.5, 10.5)
		add_child(camera)
	camera.current = true
	camera.look_at(Vector3(0.0, 0.6, 0.0), Vector3.UP)
	_ensure_phantom_camera_rig()
	_ensure_terrain_preview()

func _load_optional_texture(path: String) -> Texture2D:
	var absolute_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(absolute_path):
		var image := Image.load_from_file(absolute_path)
		if image != null and not image.is_empty():
			return ImageTexture.create_from_image(image)
	var resource := load(path)
	if resource is Texture2D:
		return resource as Texture2D
	return null

func _make_water_noise_texture(
	noise_type: FastNoiseLite.NoiseType,
	frequency: float,
	fractal_type: FastNoiseLite.FractalType,
	as_normal_map: bool,
	bump_strength: float = 1.5,
	seamless: bool = true,
	fractal_octaves: int = 5,
	seed: int = 1
) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = noise_type
	noise.frequency = frequency
	noise.fractal_type = fractal_type
	noise.fractal_octaves = fractal_octaves
	noise.seed = seed
	var texture := NoiseTexture2D.new()
	texture.seamless = seamless
	texture.as_normal_map = as_normal_map
	texture.bump_strength = bump_strength
	texture.noise = noise
	return texture

func _ensure_sea_shader_noise_resources() -> void:
	if sea_water_normal_texture == null:
		sea_water_normal_texture = _make_water_noise_texture(
			FastNoiseLite.TYPE_SIMPLEX,
			0.01,
			FastNoiseLite.FRACTAL_FBM,
			true,
			1.5,
			true,
			5,
			11
		)
	if sea_water_normal_texture_secondary == null:
		sea_water_normal_texture_secondary = _make_water_noise_texture(
			FastNoiseLite.TYPE_SIMPLEX_SMOOTH,
			0.01,
			FastNoiseLite.FRACTAL_FBM,
			true,
			1.5,
			true,
			5,
			23
		)
	if sea_water_wave_texture == null:
		sea_water_wave_texture = _make_water_noise_texture(
			FastNoiseLite.TYPE_SIMPLEX_SMOOTH,
			0.001,
			FastNoiseLite.FRACTAL_FBM,
			false,
			1.0,
			true,
			3,
			37
		)

func _ensure_sea_reference_assets() -> void:
	if sea_hdri_texture == null:
		sea_hdri_texture = _load_optional_texture(SEA_HDRI_PATH)
	if sea_foam_mask_texture == null:
		sea_foam_mask_texture = _load_optional_texture(SEA_FOAM_MASK_TEXTURE_PATH)
	if sea_foam_color_texture == null:
		sea_foam_color_texture = _load_optional_texture(SEA_FOAM_COLOR_TEXTURE_PATH)
	if sea_foam_spray_texture == null:
		sea_foam_spray_texture = _load_optional_texture(SEA_FOAM_SPRAY_TEXTURE_PATH)

func _make_ocean_abyss_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = OpenSeaAbyssShader
	material.set_shader_parameter("ocean_radius", OCEAN_ABYSS_RADIUS)
	material.set_shader_parameter("top_y", WATER_SURFACE_Y)
	material.set_shader_parameter("bottom_y", WATER_SURFACE_Y - OCEAN_ABYSS_DEPTH)
	return material

func _track_ocean_abyss_material(material: ShaderMaterial) -> void:
	if material == null:
		return
	if ocean_abyss_materials.has(material):
		return
	ocean_abyss_materials.append(material)

func _ensure_ocean_abyss_mesh(
	parent: Node3D,
	node_name: String,
	mesh: Mesh,
	position: Vector3,
	rotation: Vector3 = Vector3.ZERO
) -> MeshInstance3D:
	var node := parent.get_node_or_null(node_name) as MeshInstance3D
	if node == null:
		node = MeshInstance3D.new()
		node.name = node_name
		node.mesh = mesh
		node.position = position
		node.rotation = rotation
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(node)
	var material := node.material_override as ShaderMaterial
	if material == null or material.shader != OpenSeaAbyssShader:
		material = _make_ocean_abyss_material()
		node.material_override = material
	_track_ocean_abyss_material(material)
	return node

func _ensure_ocean_body() -> void:
	ocean_body_root = _ensure_root_node3d("OceanBodyRoot")
	if ocean_floor_mesh_instance == null or not is_instance_valid(ocean_floor_mesh_instance):
		var floor_mesh := PlaneMesh.new()
		floor_mesh.size = Vector2(OCEAN_FLOOR_SIZE, OCEAN_FLOOR_SIZE)
		floor_mesh.subdivide_width = 60
		floor_mesh.subdivide_depth = 60
		ocean_floor_mesh_instance = _ensure_ocean_abyss_mesh(
			ocean_body_root,
			"OceanFloor",
			floor_mesh,
			Vector3(0.0, WATER_SURFACE_Y - OCEAN_ABYSS_DEPTH, 0.0)
		)

	var wall_mesh := PlaneMesh.new()
	wall_mesh.size = Vector2(OCEAN_FLOOR_SIZE, OCEAN_WALL_HEIGHT)
	_ensure_ocean_abyss_mesh(
		ocean_body_root,
		"OceanWallNorth",
		wall_mesh,
		Vector3(0.0, WATER_SURFACE_Y - OCEAN_WALL_HEIGHT * 0.5, -OCEAN_WALL_DISTANCE),
		Vector3(PI * 0.5, 0.0, 0.0)
	)
	_ensure_ocean_abyss_mesh(
		ocean_body_root,
		"OceanWallSouth",
		wall_mesh,
		Vector3(0.0, WATER_SURFACE_Y - OCEAN_WALL_HEIGHT * 0.5, OCEAN_WALL_DISTANCE),
		Vector3(PI * 0.5, PI, 0.0)
	)
	_ensure_ocean_abyss_mesh(
		ocean_body_root,
		"OceanWallEast",
		wall_mesh,
		Vector3(OCEAN_WALL_DISTANCE, WATER_SURFACE_Y - OCEAN_WALL_HEIGHT * 0.5, 0.0),
		Vector3(PI * 0.5, PI * 0.5, 0.0)
	)
	_ensure_ocean_abyss_mesh(
		ocean_body_root,
		"OceanWallWest",
		wall_mesh,
		Vector3(-OCEAN_WALL_DISTANCE, WATER_SURFACE_Y - OCEAN_WALL_HEIGHT * 0.5, 0.0),
		Vector3(PI * 0.5, -PI * 0.5, 0.0)
	)

func _ensure_world_environment() -> void:
	sea_sky_rig = get_node_or_null("Environment") as SeaSkyRig
	if sea_sky_rig != null:
		return
	sea_sky_rig = SeaSkyRigScene.instantiate() as SeaSkyRig
	if sea_sky_rig == null:
		return
	sea_sky_rig.name = "Environment"
	add_child(sea_sky_rig)

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
	water_mesh.size = Vector2(520.0, 520.0)
	water.mesh = water_mesh
	var water_material := StandardMaterial3D.new()
	water_material.albedo_color = Color(0.08, 0.43, 0.65)
	water_material.roughness = 0.14
	water.material_override = water_material
	fallback_root.add_child(water)

func _ensure_sea_fx() -> void:
	_ensure_sea_reference_assets()
	_ensure_ocean_body()
	sea_sky_rig = get_node_or_null("Environment") as SeaSkyRig
	water_mesh_instance = get_node_or_null("Environment/Water") as MeshInstance3D
	if water_mesh_instance == null:
		water_mesh_instance = get_node_or_null("EnvironmentFallback/Water") as MeshInstance3D
	if water_mesh_instance != null:
		if water_mesh_instance.has_method("apply_sea_state"):
			water_shader_material = null
		else:
			if water_mesh_instance.mesh is PlaneMesh:
				var plane_mesh := water_mesh_instance.mesh as PlaneMesh
				plane_mesh.size = Vector2(WATER_SURFACE_SIZE, WATER_SURFACE_SIZE)
				plane_mesh.subdivide_width = WATER_SURFACE_SUBDIVISIONS
				plane_mesh.subdivide_depth = WATER_SURFACE_SUBDIVISIONS
			water_shader_material = water_mesh_instance.material_override as ShaderMaterial
			if water_shader_material == null:
				water_shader_material = ShaderMaterial.new()
				water_shader_material.shader = OpenSeaWaterShader
				water_mesh_instance.material_override = water_shader_material
			elif water_shader_material.shader == null:
				water_shader_material.shader = OpenSeaWaterShader
			_configure_open_sea_water_material(water_shader_material)

	sun_light = get_node_or_null("Environment/SunLight") as DirectionalLight3D
	if sun_light == null:
		sun_light = get_node_or_null("EnvironmentFallback/SunLight") as DirectionalLight3D

	if wake_root == null:
		return
	wake_mesh_instance = _ensure_wake_plane("WakeTrail", Vector2(1.0, 1.0))
	wake_material = wake_mesh_instance.material_override as ShaderMaterial
	boat_contact_foam_mesh = _ensure_contact_foam_plane(boat_root, "BoatContactFoam", Vector2(1.0, 1.0))
	boat_contact_foam_mesh.position = Vector3(0.0, WATER_SURFACE_Y + 0.06, 0.12)
	boat_contact_foam_material = boat_contact_foam_mesh.material_override as ShaderMaterial
	bow_spray_left = _ensure_wake_plane("BowSprayLeft", Vector2(1.0, 1.0))
	bow_spray_left.position = Vector3(-0.9, 0.06, -2.55)
	bow_spray_right = _ensure_wake_plane("BowSprayRight", Vector2(1.0, 1.0))
	bow_spray_right.position = Vector3(0.9, 0.06, -2.55)
	bow_spray_left_material = bow_spray_left.material_override as ShaderMaterial
	bow_spray_right_material = bow_spray_right.material_override as ShaderMaterial
	bow_spray_left_particles = _ensure_sea_spray_particles("BowSprayLeftParticles", Vector3(-0.92, 0.18, -2.56), Vector3(-0.22, 0.92, -0.72), Color(0.84, 0.93, 0.97, 0.84))
	bow_spray_right_particles = _ensure_sea_spray_particles("BowSprayRightParticles", Vector3(0.92, 0.18, -2.56), Vector3(0.22, 0.92, -0.72), Color(0.84, 0.93, 0.97, 0.84))
	wake_mist_particles = _ensure_sea_spray_particles("WakeMistParticles", Vector3(0.0, 0.02, 3.0), Vector3(0.0, 0.58, 0.88), Color(0.76, 0.88, 0.94, 0.56), 88, 1.30)
	_ensure_wake_trail_renderer()


func _ensure_wake_trail_renderer() -> void:
	if wake_root == null:
		return
	wake_trail_renderer = wake_root.get_node_or_null("WakeTrailRenderer") as Node3D
	if wake_trail_renderer != null:
		return
	wake_trail_renderer = TRAIL_RENDERER_SCRIPT.new()
	wake_trail_renderer.name = "WakeTrailRenderer"
	wake_trail_renderer.set("world_space", false)
	wake_trail_renderer.set("alignment", 1)
	wake_trail_renderer.set("texture_mode", 1)
	wake_trail_renderer.set("lifetime", 1.6)
	wake_trail_renderer.set("min_vertex_distance", 0.24)
	var wake_curve := Curve.new()
	wake_curve.add_point(Vector2(0.0, 0.34), 0.0, 0.0)
	wake_curve.add_point(Vector2(0.42, 0.28), 0.0, 0.0)
	wake_curve.add_point(Vector2(1.0, 0.04), 0.0, 0.0)
	wake_trail_renderer.set("curve", wake_curve)
	var wake_gradient := Gradient.new()
	wake_gradient.add_point(0.0, Color(0.86, 0.95, 1.0, 0.42))
	wake_gradient.add_point(1.0, Color(0.70, 0.82, 0.90, 0.0))
	wake_trail_renderer.set("color_gradient", wake_gradient)
	var wake_material := StandardMaterial3D.new()
	wake_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wake_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wake_material.vertex_color_use_as_albedo = true
	wake_material.disable_receive_shadows = true
	wake_trail_renderer.set("material", wake_material)
	wake_root.add_child(wake_trail_renderer)

func _configure_open_sea_water_material(material: ShaderMaterial) -> void:
	if material == null:
		return
	_ensure_sea_reference_assets()
	_ensure_sea_shader_noise_resources()
	material.set_shader_parameter("metallic", 0.0)
	material.set_shader_parameter("roughness", 0.04)
	material.set_shader_parameter("wave_direction", Vector2(2.0, 0.0))
	material.set_shader_parameter("wave_2_direction", Vector2(0.0, 1.0))
	material.set_shader_parameter("wave_3_direction", Vector2(0.82, 0.38))
	material.set_shader_parameter("time_scale", 0.025)
	material.set_shader_parameter("wave_group_strength", 0.26)
	material.set_shader_parameter("chop_strength", 0.18)
	material.set_shader_parameter("chop_scale", 2.6)
	material.set_shader_parameter("crest_foam_bias", 0.10)
	material.set_shader_parameter("noise_scale", 10.0)
	material.set_shader_parameter("normal_tiling", 1.55)
	material.set_shader_parameter("beers_law", 0.14)
	material.set_shader_parameter("depth_offset", -0.24)
	material.set_shader_parameter("edge_scale", 0.18)
	material.set_shader_parameter("near", 0.5)
	material.set_shader_parameter("far", 100.0)
	material.set_shader_parameter("texture_normal", sea_water_normal_texture)
	material.set_shader_parameter("texture_normal2", sea_water_normal_texture_secondary)
	material.set_shader_parameter("wave", sea_water_wave_texture)
	material.set_shader_parameter("wave_time", 0.0)
	material.set_shader_parameter("wave_speed", 0.20)
	material.set_shader_parameter("height_scale", 0.36)
	material.set_shader_parameter("reflection_strength", 0.72)
	material.set_shader_parameter("fresnel_power", 3.6)
	material.set_shader_parameter("refraction_strength", 0.022)
	material.set_shader_parameter("whitecap_strength", 0.12)
	material.set_shader_parameter("whitecap_cutoff", 0.76)
	material.set_shader_parameter("crest_tint_strength", 0.22)
	material.set_shader_parameter("trough_darkness", 0.22)
	material.set_shader_parameter("distance_haze", 0.03)
	material.set_shader_parameter("slope_shading_strength", 0.12)
	material.set_shader_parameter("sun_direction", Vector3(0.0, 0.72, 0.69))
	material.set_shader_parameter("sun_color", Color(1.0, 0.94, 0.80))
	material.set_shader_parameter("sun_glint_strength", 0.72)
	material.set_shader_parameter("sun_glint_focus", 110.0)
	material.set_shader_parameter("sun_horizon_fade", 0.18)

func _configure_contact_foam_material(material: ShaderMaterial) -> void:
	if material == null:
		return
	_ensure_sea_reference_assets()
	var has_mask := sea_foam_mask_texture != null
	var has_color := sea_foam_color_texture != null
	material.set_shader_parameter("use_foam_mask", has_mask)
	material.set_shader_parameter("use_foam_color", has_color)
	if has_mask:
		material.set_shader_parameter("foam_mask_texture", sea_foam_mask_texture)
		material.set_shader_parameter("mask_tiling", 0.084)
		material.set_shader_parameter("mask_scroll", Vector2(0.065, -0.042))
		material.set_shader_parameter("mask_contrast", 1.24)
	if has_color:
		material.set_shader_parameter("foam_color_texture", sea_foam_color_texture)

func _make_foam_particle_material(tint: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_color = tint
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = 0.22
	if sea_foam_spray_texture != null:
		material.albedo_texture = sea_foam_spray_texture
	elif sea_foam_color_texture != null:
		material.albedo_texture = sea_foam_color_texture
	return material

func _ensure_sea_spray_particles(node_name: String, local_position: Vector3, direction: Vector3, tint: Color, amount: int = 52, lifetime: float = 0.86) -> GPUParticles3D:
	var particles := wake_root.get_node_or_null(node_name) as GPUParticles3D
	if particles != null:
		return particles
	particles = GPUParticles3D.new()
	particles.name = node_name
	particles.local_coords = true
	particles.one_shot = false
	particles.emitting = true
	particles.amount = amount
	particles.lifetime = lifetime
	particles.preprocess = minf(0.25, lifetime * 0.45)
	particles.visibility_aabb = AABB(Vector3(-8.0, -2.0, -8.0), Vector3(16.0, 12.0, 16.0))
	particles.position = local_position
	var draw_mesh := QuadMesh.new()
	draw_mesh.size = Vector2(0.32, 0.32)
	particles.draw_pass_1 = draw_mesh
	particles.material_override = _make_foam_particle_material(tint)
	var process := ParticleProcessMaterial.new()
	process.direction = direction.normalized()
	process.spread = 28.0
	process.gravity = Vector3(0.0, -7.2, 0.0)
	process.initial_velocity_min = 1.8
	process.initial_velocity_max = 3.6
	process.scale_min = 0.18
	process.scale_max = 0.42
	process.damping_min = 0.55
	process.damping_max = 1.25
	process.angle_min = -22.0
	process.angle_max = 22.0
	process.angular_velocity_min = -0.7
	process.angular_velocity_max = 0.7
	particles.process_material = process
	wake_root.add_child(particles)
	return particles

func _ensure_wake_plane(node_name: String, plane_size: Vector2) -> MeshInstance3D:
	var plane_node := wake_root.get_node_or_null(node_name) as MeshInstance3D
	if plane_node != null:
		return plane_node
	plane_node = MeshInstance3D.new()
	plane_node.name = node_name
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = plane_size
	plane_mesh.subdivide_width = 12
	plane_mesh.subdivide_depth = 20
	plane_node.mesh = plane_mesh
	var material := ShaderMaterial.new()
	material.shader = OpenSeaWakeShader
	plane_node.material_override = material
	wake_root.add_child(plane_node)
	return plane_node

func _ensure_contact_foam_plane(parent: Node3D, node_name: String, plane_size: Vector2) -> MeshInstance3D:
	var plane_node := parent.get_node_or_null(node_name) as MeshInstance3D
	if plane_node != null:
		var existing_material := plane_node.material_override as ShaderMaterial
		if existing_material != null and existing_material.shader == null:
			existing_material.shader = OpenSeaContactFoamShader
		_configure_contact_foam_material(existing_material)
		return plane_node
	plane_node = MeshInstance3D.new()
	plane_node.name = node_name
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = plane_size
	plane_mesh.subdivide_width = 20
	plane_mesh.subdivide_depth = 20
	plane_node.mesh = plane_mesh
	plane_node.rotation.x = -PI * 0.5
	var material := ShaderMaterial.new()
	material.shader = OpenSeaContactFoamShader
	plane_node.material_override = material
	_configure_contact_foam_material(material)
	parent.add_child(plane_node)
	return plane_node

func _ensure_procedural_audio() -> void:
	wind_audio_player = _ensure_audio_layer("SeaWindAudio", -20.0)
	hull_audio_player = _ensure_audio_layer("HullGroanAudio", -24.0)
	storm_audio_player = _ensure_audio_layer("StormRoarAudio", -22.0)
	wind_audio_playback = null
	hull_audio_playback = null
	storm_audio_playback = null
	if wind_audio_player != null:
		wind_audio_playback = wind_audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if hull_audio_player != null:
		hull_audio_playback = hull_audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if storm_audio_player != null:
		storm_audio_playback = storm_audio_player.get_stream_playback() as AudioStreamGeneratorPlayback

func _ensure_audio_layer(node_name: String, volume_db: float) -> AudioStreamPlayer3D:
	var parent: Node = boat_root if node_name != "StormRoarAudio" and boat_root != null else self
	var player := parent.get_node_or_null(node_name) as AudioStreamPlayer3D
	if player == null:
		player = SPATIAL_AUDIO_PLAYER_3D_SCRIPT.new()
		player.name = node_name
		player.autoplay = false
		parent.add_child(player)
	player.volume_db = volume_db
	_configure_spatial_audio_player(player, node_name)
	var generator := player.stream as AudioStreamGenerator
	if generator == null:
		generator = AudioStreamGenerator.new()
		generator.mix_rate = 22050
		generator.buffer_length = 0.25
		player.stream = generator
	if not player.playing:
		player.play()
	return player


func _configure_spatial_audio_player(player: AudioStreamPlayer3D, node_name: String) -> void:
	if player == null:
		return
	player.max_distance = 140.0 if node_name == "StormRoarAudio" else 42.0
	player.unit_size = 8.0 if node_name == "SeaWindAudio" else 5.0
	player.attenuation_filter_cutoff_hz = 18000.0
	player.emission_angle_enabled = false
	if node_name == "StormRoarAudio":
		player.position = Vector3(0.0, 18.0, -34.0)
		player.set("audio_occlusion", false)
		player.set("room_size_reverb", false)
		player.set("enable_air_absorption", true)
	elif node_name == "HullGroanAudio":
		player.position = Vector3(0.0, 1.2, 0.2)
		player.set("audio_occlusion", true)
		player.set("room_size_reverb", true)
		player.set("surface_absorption", true)
		player.set("ignore_floor", true)
		player.set("ray_distribution", 1)
		player.set("fibonacci_ray_count", 12)
	else:
		player.position = Vector3(0.0, 2.8, -0.6)
		player.set("audio_occlusion", false)
		player.set("room_size_reverb", false)
		player.set("enable_air_absorption", true)

func _wave_synth(t: float, base_a: float, base_b: float, mod_a: float, mod_b: float, mix_amount: float = 0.5) -> float:
	return sin(TAU * base_a * t + sin(TAU * mod_a * t) * mix_amount) * 0.58 + sin(TAU * base_b * t + cos(TAU * mod_b * t) * mix_amount * 0.7) * 0.42

func _fill_audio_layer(playback: AudioStreamGeneratorPlayback, layer_name: String, from_time: float, intensity: float, mod_strength: float) -> float:
	if playback == null:
		return from_time
	var frames := mini(playback.get_frames_available(), 2048)
	if frames <= 0:
		return from_time
	var delta_t := 1.0 / 22050.0
	var current_time := from_time
	for _frame in range(frames):
		var sample_left := 0.0
		var sample_right := 0.0
		match layer_name:
			"wind":
				var body := _wave_synth(current_time, 97.0, 173.0, 0.07, 0.11, 2.8)
				var hiss := _wave_synth(current_time, 233.0, 311.0, 0.13, 0.09, 1.4)
				sample_left = (body * 0.62 + hiss * 0.28) * intensity
				sample_right = (_wave_synth(current_time + 0.003, 103.0, 181.0, 0.05, 0.09, 2.5) * 0.62 + hiss * 0.24) * intensity
			"hull":
				var groan := sin(TAU * (0.62 + mod_strength * 0.35) * current_time + sin(TAU * 0.19 * current_time) * 2.2)
				var slap: float = pow(abs(sin(TAU * (1.1 + mod_strength * 0.8) * current_time)), 6.0) * sign(sin(TAU * 3.8 * current_time))
				sample_left = (groan * 0.54 + slap * 0.34) * intensity
				sample_right = (sin(TAU * (0.66 + mod_strength * 0.28) * current_time + 0.8) * 0.48 + slap * 0.30) * intensity
			"storm":
				var roar := _wave_synth(current_time, 61.0, 89.0, 0.03, 0.05, 3.4)
				var rumble := sin(TAU * 19.0 * current_time + sin(TAU * 0.08 * current_time) * 1.5)
				sample_left = (roar * 0.48 + rumble * 0.36) * intensity
				sample_right = (_wave_synth(current_time + 0.002, 67.0, 97.0, 0.02, 0.06, 3.2) * 0.46 + rumble * 0.34) * intensity
		playback.push_frame(Vector2(sample_left, sample_right))
		current_time += delta_t
	return current_time

func _get_biome_sea_profile(biome_id: String) -> Dictionary:
	return NetworkRuntime.get_biome_sea_profile(biome_id)

func _sample_wave_height(world_position: Vector3) -> float:
	return NetworkRuntime.sample_wave_height(world_position, connect_time_seconds)

func _sample_boat_wave_pose(world_position: Vector3, rotation_y: float) -> Dictionary:
	return NetworkRuntime.sample_boat_wave_pose(
		world_position,
		rotation_y,
		float(NetworkRuntime.boat_state.get("hull_length", 4.4)),
		float(NetworkRuntime.boat_state.get("hull_beam", 2.7)),
		connect_time_seconds
	)

func _update_sea_presentation(delta: float) -> void:
	var descriptor := _get_current_chunk_descriptor()
	var biome_id := str(descriptor.get("biome_id", RunWorldGenerator.BIOME_OPEN_OCEAN))
	var hazard_level := clampf(float(descriptor.get("hazard_level", 0.35)), 0.0, 1.0)
	var profile := _get_biome_sea_profile(biome_id)
	var atmosphere_blend := minf(1.0, delta * 2.2)
	var storm_strength := clampf(hazard_level * 0.8 + (0.35 if biome_id == RunWorldGenerator.BIOME_STORM_BELT else 0.0), 0.0, 1.0)
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var deep_color: Color = profile.get("deep_color", Color(0.05, 0.16, 0.22))
	var shallow_color: Color = profile.get("shallow_color", Color(0.08, 0.34, 0.42))
	var foam_color: Color = profile.get("foam_color", Color(0.76, 0.90, 0.96))
	var clarity := float(profile.get("clarity", 0.5))
	var glint_strength := float(profile.get("glint_strength", 0.24))
	var chop_profile := float(profile.get("chop_strength", 0.18))
	var abyss_mid_color := deep_color.darkened(0.32)
	var abyss_deep_color := deep_color.darkened(0.72)
	var wind_angle := 0.34 + sin(connect_time_seconds * 0.029) * 0.18 + hazard_level * 0.12
	var wind_direction := Vector2.RIGHT.rotated(wind_angle)
	var swell_direction := wind_direction.rotated(-0.56 + cos(connect_time_seconds * 0.021) * 0.10)
	var cross_direction := wind_direction.rotated(1.08 + sin(connect_time_seconds * 0.017) * 0.08)
	var drift_direction := wind_direction.rotated(-1.42)
	var sea_state_strength := clampf(float(profile.get("wave_amp", 0.24)) * 1.7 + chop_profile * 0.9 + storm_strength * 0.35, 0.0, 1.0)

	if water_mesh_instance != null:
		if water_mesh_instance.has_method("apply_sea_state"):
			water_mesh_instance.call("apply_sea_state", biome_id, profile, hazard_level, boat_position, connect_time_seconds)
		else:
			water_mesh_instance.global_position = Vector3(boat_position.x, WATER_SURFACE_Y, boat_position.z)
	if ocean_body_root != null:
		ocean_body_root.global_position = Vector3(boat_position.x, 0.0, boat_position.z)
	for material_variant in ocean_abyss_materials:
		var abyss_material := material_variant as ShaderMaterial
		if abyss_material == null:
			continue
		abyss_material.set_shader_parameter("world_center", Vector2(boat_position.x, boat_position.z))
		abyss_material.set_shader_parameter("top_color", shallow_color.darkened(0.22))
		abyss_material.set_shader_parameter("mid_color", abyss_mid_color)
		abyss_material.set_shader_parameter("deep_color", abyss_deep_color)
		abyss_material.set_shader_parameter("side_fade", 0.30 + storm_strength * 0.12)
	if water_shader_material != null:
		water_shader_material.set_shader_parameter("albedo", deep_color.lerp(shallow_color, 0.18))
		water_shader_material.set_shader_parameter("albedo2", shallow_color.lightened(0.18))
		water_shader_material.set_shader_parameter("color_deep", abyss_deep_color.lerp(deep_color, 0.18))
		water_shader_material.set_shader_parameter("color_shallow", deep_color.lerp(shallow_color, 0.52))
		water_shader_material.set_shader_parameter("horizon_color", profile.get("horizon_color", Color(0.25, 0.42, 0.50)))
		water_shader_material.set_shader_parameter("edge_color", foam_color.lightened(0.04))
		water_shader_material.set_shader_parameter("wave_direction", wind_direction)
		water_shader_material.set_shader_parameter("wave_2_direction", cross_direction)
		water_shader_material.set_shader_parameter("wave_3_direction", drift_direction)
		water_shader_material.set_shader_parameter("wave_time", connect_time_seconds)
		water_shader_material.set_shader_parameter("wave_speed", 0.16 + float(profile.get("wave_speed", 1.0)) * 0.08 + hazard_level * 0.025)
		water_shader_material.set_shader_parameter("time_scale", 0.022 + hazard_level * 0.007)
		water_shader_material.set_shader_parameter("wave_group_strength", clampf(0.18 + hazard_level * 0.18 + chop_profile * 0.24, 0.18, 0.42))
		water_shader_material.set_shader_parameter("chop_strength", clampf(0.10 + chop_profile * 0.62 + hazard_level * 0.18, 0.10, 0.46))
		water_shader_material.set_shader_parameter("chop_scale", lerpf(2.2, 3.3, hazard_level))
		water_shader_material.set_shader_parameter("crest_foam_bias", clampf(0.05 + glint_strength * 0.10 + storm_strength * 0.12, 0.05, 0.22))
		water_shader_material.set_shader_parameter("noise_scale", lerpf(16.0, 10.0, clampf(hazard_level, 0.0, 1.0)))
		water_shader_material.set_shader_parameter("height_scale", float(profile.get("wave_amp", 0.24)) * (0.94 + hazard_level * 0.70))
		water_shader_material.set_shader_parameter("beers_law", clampf(0.12 + (1.0 - clarity) * 0.18 + storm_strength * 0.06, 0.10, 0.30))
		water_shader_material.set_shader_parameter("depth_offset", -0.18 - storm_strength * 0.14)
		water_shader_material.set_shader_parameter("edge_scale", clampf(0.14 + storm_strength * 0.08 + (1.0 - clarity) * 0.06, 0.12, 0.30))
		water_shader_material.set_shader_parameter("reflection_strength", clampf(float(profile.get("reflection_strength", 0.50)) + 0.08 + glint_strength * 0.18 + storm_strength * 0.05, 0.64, 0.92))
		water_shader_material.set_shader_parameter("fresnel_power", clampf(3.6 - storm_strength * 0.4, 2.8, 4.4))
		water_shader_material.set_shader_parameter("refraction_strength", 0.020 + storm_strength * 0.006 + hazard_level * 0.004)
		water_shader_material.set_shader_parameter("whitecap_strength", clampf(0.05 + storm_strength * 0.18 + hazard_level * 0.06 + chop_profile * 0.28, 0.04, 0.42))
		water_shader_material.set_shader_parameter("whitecap_cutoff", clampf(0.84 - storm_strength * 0.16, 0.60, 0.88))
		water_shader_material.set_shader_parameter("crest_tint_strength", clampf(0.18 + clarity * 0.16 + glint_strength * 0.08, 0.18, 0.38))
		water_shader_material.set_shader_parameter("trough_darkness", clampf(0.22 + storm_strength * 0.16, 0.18, 0.42))
		water_shader_material.set_shader_parameter("distance_haze", 0.02 + storm_strength * 0.05)
		water_shader_material.set_shader_parameter("slope_shading_strength", clampf(0.10 + hazard_level * 0.08, 0.10, 0.24))
		if camera != null:
			water_shader_material.set_shader_parameter("near", camera.near)
			water_shader_material.set_shader_parameter("far", camera.far)
	if sea_sky_rig != null:
		sea_sky_rig.apply_profile(profile, storm_strength, atmosphere_blend)

	var sun_world_direction := sea_sky_rig.get_sun_direction() if sea_sky_rig != null else Vector3(0.0, 0.72, 0.69)
	var sun_view_direction := _get_view_space_direction(sun_world_direction)
	var sun_color: Color = profile.get("sun_color", Color(0.95, 0.93, 0.85))
	var sun_glint_strength := clampf(float(profile.get("sun_glint_strength", profile.get("reflection_strength", 0.50))) + storm_strength * 0.08, 0.0, 1.6)
	var sun_glint_focus := float(profile.get("sun_glint_focus", 110.0))
	var sun_horizon_fade := float(profile.get("sun_horizon_fade", 0.18))
	if water_mesh_instance != null and water_mesh_instance.has_method("apply_sun_state"):
		water_mesh_instance.call("apply_sun_state", sun_view_direction, sun_color, sun_glint_strength, sun_glint_focus, sun_horizon_fade)
	if water_shader_material != null:
		water_shader_material.set_shader_parameter("sun_direction", sun_view_direction)
		water_shader_material.set_shader_parameter("sun_color", sun_color)
		water_shader_material.set_shader_parameter("sun_glint_strength", sun_glint_strength)
		water_shader_material.set_shader_parameter("sun_glint_focus", sun_glint_focus)
		water_shader_material.set_shader_parameter("sun_horizon_fade", sun_horizon_fade)

	if storm_wall_container != null:
		var wall_color: Color = profile.get("deep_color", Color(0.05, 0.16, 0.22)).darkened(0.42 + storm_strength * 0.16)
		var rim_color: Color = profile.get("horizon_color", Color(0.25, 0.42, 0.50)).lightened(0.10 + storm_strength * 0.18)
		for wall_variant in storm_wall_container.get_children():
			var wall := wall_variant as MeshInstance3D
			if wall == null:
				continue
			var wall_material := wall.material_override as ShaderMaterial
			if wall_material == null:
				continue
			wall_material.set_shader_parameter("wall_color", wall_color)
			wall_material.set_shader_parameter("rim_color", rim_color)
			wall_material.set_shader_parameter("intensity", 0.38 + storm_strength * 0.46)
			wall_material.set_shader_parameter("scroll_speed", 0.26 + storm_strength * 0.62)

	var speed_ratio := clampf(absf(float(NetworkRuntime.boat_state.get("speed", 0.0))) / maxf(0.1, float(NetworkRuntime.boat_state.get("top_speed_limit", NetworkRuntime.BOAT_TOP_SPEED))), 0.0, 1.0)
	var hull_motion_strength := clampf(absf(boat_root.rotation.x) * 2.4 + absf(boat_root.rotation.z) * 2.0, 0.0, 1.0)
	if wake_mesh_instance != null:
		wake_mesh_instance.position = Vector3(0.0, -0.18, 3.45)
		wake_mesh_instance.scale = Vector3(1.5 + speed_ratio * 1.8 + sea_state_strength * 0.35, 1.0, 4.5 + speed_ratio * 7.5 + sea_state_strength * 1.2)
	if wake_material != null:
		wake_material.set_shader_parameter("wake_strength", clampf(speed_ratio * 0.88 + sea_state_strength * 0.18 + hull_motion_strength * 0.16 + storm_strength * 0.22, 0.0, 1.0))
		wake_material.set_shader_parameter("core_color", Color(0.84, 0.94, 0.98, 1.0))
		wake_material.set_shader_parameter("edge_color", profile.get("shallow_color", Color(0.08, 0.34, 0.42)))
		wake_material.set_shader_parameter("noise_scale", 0.95 + storm_strength * 0.45 + chop_profile * 0.25)
	if boat_contact_foam_mesh != null:
		boat_contact_foam_mesh.visible = true
		boat_contact_foam_mesh.position = Vector3(0.0, WATER_SURFACE_Y + 0.06, 0.08)
		boat_contact_foam_mesh.scale = Vector3(2.9 + speed_ratio * 1.0 + sea_state_strength * 0.35, 1.0, 5.8 + speed_ratio * 1.7 + sea_state_strength * 0.75)
	if boat_contact_foam_material != null:
		var hull_foam_strength := clampf(0.16 + speed_ratio * 0.30 + sea_state_strength * 0.18 + hull_motion_strength * 0.22 + storm_strength * 0.24, 0.0, 1.0)
		boat_contact_foam_material.set_shader_parameter("core_color", profile.get("foam_color", Color(0.76, 0.90, 0.96)))
		boat_contact_foam_material.set_shader_parameter("edge_color", profile.get("shallow_color", Color(0.08, 0.34, 0.42)))
		boat_contact_foam_material.set_shader_parameter("intensity", hull_foam_strength)
		boat_contact_foam_material.set_shader_parameter("foam_radius", 0.70)
		boat_contact_foam_material.set_shader_parameter("foam_width", 0.16 + storm_strength * 0.04)
		boat_contact_foam_material.set_shader_parameter("soft_fill", 0.12 + speed_ratio * 0.08)
		boat_contact_foam_material.set_shader_parameter("breakup_strength", 0.26 + storm_strength * 0.16)
		boat_contact_foam_material.set_shader_parameter("scroll_speed", 0.45 + speed_ratio * 0.28 + storm_strength * 0.40)

	var spray_strength := clampf(speed_ratio * 0.72 + sea_state_strength * 0.22 + hull_motion_strength * 0.20 + storm_strength * 0.38 + (0.20 if _boat_inside_any_squall() else 0.0), 0.0, 1.0)
	for spray_pair in [
		{"node": bow_spray_left, "material": bow_spray_left_material, "x": -0.95},
		{"node": bow_spray_right, "material": bow_spray_right_material, "x": 0.95},
	]:
		var spray_node := spray_pair["node"] as MeshInstance3D
		var spray_material := spray_pair["material"] as ShaderMaterial
		if spray_node != null:
			spray_node.position = Vector3(float(spray_pair["x"]), -0.12, -2.58)
			spray_node.rotation_degrees.y = -16.0 if float(spray_pair["x"]) < 0.0 else 16.0
			spray_node.scale = Vector3(0.95 + spray_strength * 0.80, 1.0, 1.8 + spray_strength * 3.0)
			spray_node.visible = spray_strength > 0.05
		if spray_material != null:
			spray_material.set_shader_parameter("wake_strength", spray_strength)
			spray_material.set_shader_parameter("core_color", Color(0.92, 0.96, 0.98, 1.0))
			spray_material.set_shader_parameter("edge_color", profile.get("foam_color", Color(0.76, 0.90, 0.96)))
			spray_material.set_shader_parameter("noise_scale", 1.25 + storm_strength * 0.55 + chop_profile * 0.35)

	_update_spray_particle_layer(bow_spray_left_particles, spray_strength, Vector3(-0.26, 0.92, -0.72), 28.0 + storm_strength * 12.0 + chop_profile * 8.0, 2.0, 4.7 + storm_strength * 1.6 + sea_state_strength * 0.8)
	_update_spray_particle_layer(bow_spray_right_particles, spray_strength, Vector3(0.26, 0.92, -0.72), 28.0 + storm_strength * 12.0 + chop_profile * 8.0, 2.0, 4.7 + storm_strength * 1.6 + sea_state_strength * 0.8)
	_update_spray_particle_layer(wake_mist_particles, clampf(speed_ratio * 0.60 + sea_state_strength * 0.24 + storm_strength * 0.28, 0.0, 1.0), Vector3(0.0, 0.58, 0.88), 36.0, 1.2, 3.5 + storm_strength * 1.1 + sea_state_strength * 0.6)

func _update_spray_particle_layer(particles: GPUParticles3D, intensity: float, direction: Vector3, spread: float, velocity_min: float, velocity_max: float) -> void:
	if particles == null:
		return
	var clamped_intensity := clampf(intensity, 0.0, 1.0)
	particles.visible = clamped_intensity > 0.02
	particles.amount_ratio = clampf(clamped_intensity * 1.18, 0.0, 1.0)
	particles.speed_scale = 0.85 + clamped_intensity * 0.85
	var process := particles.process_material as ParticleProcessMaterial
	if process == null:
		return
	process.direction = direction.normalized()
	process.spread = spread
	process.initial_velocity_min = velocity_min
	process.initial_velocity_max = velocity_max
	process.gravity = Vector3(0.0, -6.6 - clamped_intensity * 1.8, 0.0)
	process.scale_min = 0.14 + clamped_intensity * 0.06
	process.scale_max = 0.30 + clamped_intensity * 0.20
	process.damping_min = 0.44 + clamped_intensity * 0.18
	process.damping_max = 1.10 + clamped_intensity * 0.34

func _update_sea_audio() -> void:
	var descriptor := _get_current_chunk_descriptor()
	var biome_id := str(descriptor.get("biome_id", RunWorldGenerator.BIOME_OPEN_OCEAN))
	var hazard_level := clampf(float(descriptor.get("hazard_level", 0.35)), 0.0, 1.0)
	var speed_ratio := clampf(absf(float(NetworkRuntime.boat_state.get("speed", 0.0))) / maxf(0.1, float(NetworkRuntime.boat_state.get("top_speed_limit", NetworkRuntime.BOAT_TOP_SPEED))), 0.0, 1.0)
	var storm_strength := clampf(hazard_level * 0.65 + (0.35 if biome_id == RunWorldGenerator.BIOME_STORM_BELT else 0.0) + (0.22 if _boat_inside_any_squall() else 0.0), 0.0, 1.0)
	var hull_motion := clampf(absf(boat_root.rotation.x) * 2.8 + absf(boat_root.rotation.z) * 2.4, 0.0, 1.0)
	var overboard_boost := 0.12 if _is_local_off_deck() else 0.0
	wind_audio_time = _fill_audio_layer(wind_audio_playback, "wind", wind_audio_time, 0.022 + speed_ratio * 0.035 + storm_strength * 0.055 + overboard_boost, storm_strength)
	hull_audio_time = _fill_audio_layer(hull_audio_playback, "hull", hull_audio_time, 0.010 + speed_ratio * 0.020 + hull_motion * 0.024 + storm_strength * 0.012, hull_motion)
	storm_audio_time = _fill_audio_layer(storm_audio_playback, "storm", storm_audio_time, storm_strength * 0.072 + (0.024 if _boat_inside_any_squall() else 0.0), storm_strength)
	if wind_audio_player != null:
		wind_audio_player.position = Vector3(0.0, 2.8, -0.6)
	if hull_audio_player != null:
		hull_audio_player.position = Vector3(0.0, 1.18, 0.2)
	if storm_audio_player != null and camera != null:
		storm_audio_player.global_position = camera.global_position + Vector3(sin(connect_time_seconds * 0.21) * 12.0, 18.0, -34.0)
	if wake_trail_renderer != null:
		wake_trail_renderer.position = Vector3(0.0, WATER_SURFACE_Y + 0.06, 2.92)
		wake_trail_renderer.set("is_emitting", speed_ratio > 0.06)

func _refresh_horizon_storm_wall() -> void:
	if storm_wall_container == null:
		return
	for child in storm_wall_container.get_children():
		child.queue_free()
	var bounds := RunWorldGenerator._coord_from_variant(NetworkRuntime.run_state.get("world_bounds_chunks", [RunWorldGenerator.WORLD_SIZE_CHUNKS, RunWorldGenerator.WORLD_SIZE_CHUNKS]))
	var chunk_size := float(NetworkRuntime.run_state.get("chunk_size_m", RunWorldGenerator.CHUNK_SIZE_M))
	var world_width := float(bounds.x) * chunk_size
	var world_depth := float(bounds.y) * chunk_size
	var center := Vector3(0.0, 18.0, -chunk_size * 0.5)
	var height := 84.0
	var north_south_width := world_width + chunk_size * 3.0
	var east_west_width := world_depth + chunk_size * 3.0
	var wall_specs := [
		{"name": "NorthWall", "position": center + Vector3(0.0, 0.0, -world_depth * 0.5 - 22.0), "width": north_south_width, "rotation_y": PI},
		{"name": "SouthWall", "position": center + Vector3(0.0, 0.0, world_depth * 0.5 + 22.0), "width": north_south_width, "rotation_y": 0.0},
		{"name": "WestWall", "position": center + Vector3(-world_width * 0.5 - 22.0, 0.0, 0.0), "width": east_west_width, "rotation_y": PI * 0.5},
		{"name": "EastWall", "position": center + Vector3(world_width * 0.5 + 22.0, 0.0, 0.0), "width": east_west_width, "rotation_y": -PI * 0.5},
	]
	for wall_spec_variant in wall_specs:
		var wall_spec: Dictionary = wall_spec_variant
		var wall := MeshInstance3D.new()
		wall.name = str(wall_spec.get("name", "StormWall"))
		var quad := QuadMesh.new()
		quad.size = Vector2(float(wall_spec.get("width", world_width)), height)
		wall.mesh = quad
		wall.position = wall_spec.get("position", Vector3.ZERO)
		wall.rotation.y = float(wall_spec.get("rotation_y", 0.0))
		var material := ShaderMaterial.new()
		material.shader = StormWallShader
		material.set_shader_parameter("intensity", 0.82)
		wall.material_override = material
		storm_wall_container.add_child(wall)

func _spawn_splash_burst(world_position: Vector3, strength: float, ring_color: Color = Color(0.86, 0.96, 1.0), mist_color: Color = Color(0.48, 0.70, 0.82)) -> void:
	if splash_container == null:
		return
	var splash := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(1.0, 1.0)
	mesh.subdivide_width = 8
	mesh.subdivide_depth = 8
	splash.mesh = mesh
	splash.position = Vector3(world_position.x, WATER_SURFACE_Y + 0.04, world_position.z)
	splash.rotation.x = -PI * 0.5
	var material := ShaderMaterial.new()
	material.shader = OpenSeaSplashShader
	material.set_shader_parameter("ring_color", ring_color)
	material.set_shader_parameter("mist_color", mist_color)
	material.set_shader_parameter("life_ratio", 0.0)
	material.set_shader_parameter("intensity", clampf(strength, 0.3, 1.6))
	splash.material_override = material
	splash_container.add_child(splash)
	splash_visuals.append({
		"node": splash,
		"material": material,
		"age": 0.0,
		"duration": 0.9 + strength * 0.25,
		"base_scale": 1.2 + strength * 2.0,
	})

func _emit_local_surface_contact_feedback(world_position: Vector3, strength: float = 1.0) -> void:
	local_surface_contact_feedback_timer = 0.35
	local_camera_jolt += Vector3(0.0, 0.06, -0.12) * clampf(strength, 0.6, 1.2)
	_spawn_splash_burst(
		world_position,
		strength,
		Color(0.92, 0.96, 1.0),
		Color(0.54, 0.76, 0.86)
	)

func _update_splash_bursts(delta: float) -> void:
	if splash_visuals.is_empty():
		return
	var survivors: Array = []
	for splash_variant in splash_visuals:
		var splash: Dictionary = splash_variant
		var node := splash.get("node") as MeshInstance3D
		var material := splash.get("material") as ShaderMaterial
		if node == null:
			continue
		var age := float(splash.get("age", 0.0)) + delta
		var duration := maxf(0.1, float(splash.get("duration", 1.0)))
		var life_ratio := clampf(age / duration, 0.0, 1.0)
		var base_scale := float(splash.get("base_scale", 2.0))
		node.scale = Vector3.ONE * lerpf(base_scale * 0.4, base_scale, life_ratio)
		node.position.y = WATER_SURFACE_Y + 0.04 + sin(connect_time_seconds * 8.0 + base_scale) * 0.02
		if material != null:
			material.set_shader_parameter("life_ratio", life_ratio)
		if life_ratio >= 1.0:
			node.queue_free()
			continue
		splash["age"] = age
		survivors.append(splash)
	splash_visuals = survivors

func _refresh_chunk_visuals() -> void:
	if chunk_container == null:
		return
	for child in chunk_container.get_children():
		child.queue_free()
	chunk_visuals.clear()

	for descriptor_variant in _get_active_chunk_descriptors():
		var descriptor: Dictionary = descriptor_variant
		var coord_key := _chunk_coord_key(descriptor.get("coord", [0, 0]))
		var coord := RunWorldGenerator._coord_from_variant(descriptor.get("coord", [0, 0]))
		var biome_id := str(descriptor.get("biome_id", RunWorldGenerator.BIOME_OPEN_OCEAN))
		var chunk_root := _get_chunk_visual_scene(biome_id).instantiate() as Node3D
		if chunk_root == null:
			chunk_root = Node3D.new()
		chunk_root.name = "Chunk_%d_%d" % [coord.x, coord.y]
		chunk_root.position = descriptor.get("world_center", Vector3.ZERO)
		chunk_container.add_child(chunk_root)
		chunk_visuals[coord_key] = {
			"root": chunk_root,
			"descriptor": descriptor.duplicate(true),
		}
		var chunk_size := float(NetworkRuntime.run_state.get("chunk_size_m", RunWorldGenerator.CHUNK_SIZE_M))
		if chunk_root.has_method("set_chunk_size"):
			chunk_root.call("set_chunk_size", chunk_size)
		if chunk_root.has_method("set_tile_color"):
			chunk_root.call("set_tile_color", _get_chunk_biome_color(biome_id))
		if chunk_root.has_method("set_outline_color"):
			chunk_root.call("set_outline_color", _get_chunk_outline_color(biome_id))
		if chunk_root.has_method("clear_props"):
			chunk_root.call("clear_props")
		_build_chunk_props(chunk_root, descriptor)

	_update_chunk_environment()

func _build_chunk_props(parent: Node3D, descriptor: Dictionary) -> void:
	var biome_id := str(descriptor.get("biome_id", RunWorldGenerator.BIOME_OPEN_OCEAN))
	var richness := float(descriptor.get("richness_level", 0.5))
	var hazard_level := float(descriptor.get("hazard_level", 0.5))
	var prop_count := 1 + int(round((richness + hazard_level) * 1.5))
	var props_root := parent
	if parent.has_method("get_props_root"):
		props_root = parent.call("get_props_root") as Node3D
		if props_root == null:
			props_root = parent
	for prop_index in range(prop_count):
		var prop := _get_chunk_prop_scene(biome_id).instantiate() as Node3D
		if prop == null:
			prop = Node3D.new()
		var props_seed := int(descriptor.get("props_seed", 0)) + prop_index * 53
		if biome_id == RunWorldGenerator.BIOME_REEF_WATERS:
			prop.scale = Vector3.ONE * (0.86 + float((props_seed % 3)) * 0.22)
		elif biome_id == RunWorldGenerator.BIOME_GRAVEYARD_WATERS:
			prop.scale = Vector3(1.0, 0.92 + float((props_seed % 4)) * 0.16, 1.0)
		else:
			prop.scale = Vector3.ONE * (0.88 + float((props_seed % 4)) * 0.12)
		prop.position = Vector3(
			sin(float(props_seed % 360)) * 6.5,
			0.42,
			cos(float((props_seed * 3) % 360)) * 6.1
		)
		prop.rotation.y = deg_to_rad(float(props_seed % 360))
		props_root.add_child(prop)
		if prop.has_method("set_prop_color"):
			prop.call("set_prop_color", _get_chunk_prop_color(biome_id, prop_index))

func _get_chunk_visual_scene(biome_id: String) -> PackedScene:
	match biome_id:
		RunWorldGenerator.BIOME_REEF_WATERS:
			return REEF_CHUNK_SCENE
		RunWorldGenerator.BIOME_FOG_BANK:
			return FOG_BANK_CHUNK_SCENE
		RunWorldGenerator.BIOME_STORM_BELT:
			return STORM_BELT_CHUNK_SCENE
		RunWorldGenerator.BIOME_GRAVEYARD_WATERS:
			return GRAVEYARD_CHUNK_SCENE
		_:
			return OPEN_OCEAN_CHUNK_SCENE

func _get_chunk_prop_scene(biome_id: String) -> PackedScene:
	match biome_id:
		RunWorldGenerator.BIOME_REEF_WATERS:
			return REEF_SPIRE_PROP_SCENE
		RunWorldGenerator.BIOME_GRAVEYARD_WATERS:
			return GRAVEYARD_SPAR_PROP_SCENE
		_:
			return DRIFT_BUOY_PROP_SCENE

func _get_chunk_biome_color(biome_id: String) -> Color:
	match biome_id:
		RunWorldGenerator.BIOME_REEF_WATERS:
			return Color(0.08, 0.18, 0.18, 0.16)
		RunWorldGenerator.BIOME_FOG_BANK:
			return Color(0.11, 0.13, 0.16, 0.12)
		RunWorldGenerator.BIOME_STORM_BELT:
			return Color(0.05, 0.07, 0.10, 0.18)
		RunWorldGenerator.BIOME_GRAVEYARD_WATERS:
			return Color(0.09, 0.10, 0.11, 0.15)
		_:
			return Color(0.05, 0.10, 0.14, 0.12)

func _get_chunk_outline_color(biome_id: String) -> Color:
	match biome_id:
		RunWorldGenerator.BIOME_STORM_BELT:
			return Color(0.58, 0.72, 0.95, 0.10)
		RunWorldGenerator.BIOME_FOG_BANK:
			return Color(0.82, 0.88, 0.94, 0.08)
		RunWorldGenerator.BIOME_REEF_WATERS:
			return Color(0.32, 0.86, 0.80, 0.08)
		RunWorldGenerator.BIOME_GRAVEYARD_WATERS:
			return Color(0.68, 0.70, 0.76, 0.08)
		_:
			return Color(0.46, 0.72, 0.88, 0.05)

func _get_chunk_prop_color(biome_id: String, prop_index: int) -> Color:
	match biome_id:
		RunWorldGenerator.BIOME_REEF_WATERS:
			return Color(0.14, 0.36, 0.33).darkened(float(prop_index) * 0.06)
		RunWorldGenerator.BIOME_GRAVEYARD_WATERS:
			return Color(0.47, 0.34, 0.22).lightened(float(prop_index) * 0.04)
		RunWorldGenerator.BIOME_FOG_BANK:
			return Color(0.48, 0.52, 0.56).darkened(float(prop_index) * 0.05)
		RunWorldGenerator.BIOME_STORM_BELT:
			return Color(0.33, 0.37, 0.42).darkened(float(prop_index) * 0.04)
		_:
			return Color(0.32, 0.38, 0.42).darkened(float(prop_index) * 0.05)

func _update_chunk_environment() -> void:
	_update_sea_presentation(1.0)

func _get_view_space_direction(world_direction: Vector3) -> Vector3:
	if camera == null:
		return world_direction.normalized()
	return (camera.global_transform.basis.inverse() * world_direction.normalized()).normalized()

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

func _copy_array(value: Variant) -> Array:
	return value.duplicate(true) if value is Array else []

func _chunk_coord_key(coord_value: Variant) -> String:
	var coord := RunWorldGenerator._coord_from_variant(coord_value)
	return "%d:%d" % [coord.x, coord.y]

func _get_active_chunk_coords() -> Array:
	return _copy_array(NetworkRuntime.run_state.get("active_chunk_coords", []))

func _get_active_chunk_descriptors() -> Array:
	var descriptors: Array = []
	for coord_variant in _get_active_chunk_coords():
		var descriptor := NetworkRuntime.get_chunk_descriptor(coord_variant)
		if descriptor.is_empty():
			continue
		descriptors.append(descriptor)
	return descriptors

func _get_current_chunk_descriptor() -> Dictionary:
	return NetworkRuntime.get_chunk_descriptor(NetworkRuntime.get_world_chunk_coord(NetworkRuntime.boat_state.get("position", Vector3.ZERO)))

func _get_poi_sites(site_type: String, available_only: bool = false) -> Array:
	var matches: Array = []
	for site_variant in _copy_array(NetworkRuntime.run_state.get("poi_sites", [])):
		var site: Dictionary = site_variant
		if str(site.get("site_type", "")) != site_type:
			continue
		if available_only:
			if site_type == RunWorldGenerator.SITE_DISTRESS and not bool(site.get("available", false)):
				continue
			if site_type == RunWorldGenerator.SITE_RESUPPLY and not bool(site.get("available", false)):
				continue
			if site_type == RunWorldGenerator.SITE_SALVAGE and int(site.get("loot_remaining", 0)) <= 0:
				continue
		matches.append(site.duplicate(true))
	return matches

func _get_nearest_poi_site(site_type: String, available_only: bool = false) -> Dictionary:
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var best_site: Dictionary = {}
	var best_distance := INF
	for site_variant in _get_poi_sites(site_type, available_only):
		var site: Dictionary = site_variant
		var distance := boat_position.distance_to(site.get("position", Vector3.ZERO))
		if distance >= best_distance:
			continue
		best_distance = distance
		best_site = site.duplicate(true)
	return best_site

func _get_revealed_extraction_sites() -> Array:
	var revealed_lookup := {}
	for extraction_id_variant in _copy_array(NetworkRuntime.run_state.get("revealed_extraction_ids", [])):
		revealed_lookup[str(extraction_id_variant)] = true
	var matches: Array = []
	for site_variant in _copy_array(NetworkRuntime.run_state.get("extraction_sites", [])):
		var site: Dictionary = site_variant
		if revealed_lookup.has(str(site.get("id", ""))):
			matches.append(site.duplicate(true))
	return matches

func _get_nearest_extraction_site(revealed_only: bool = true) -> Dictionary:
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var source := _get_revealed_extraction_sites() if revealed_only else _copy_array(NetworkRuntime.run_state.get("extraction_sites", []))
	var best_site: Dictionary = {}
	var best_distance := INF
	for site_variant in source:
		var site: Dictionary = site_variant
		var distance := boat_position.distance_to(site.get("position", Vector3.ZERO))
		if distance >= best_distance:
			continue
		best_distance = distance
		best_site = site.duplicate(true)
	return best_site

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
	var fallback_position := NetworkRuntime.get_nearest_run_avatar_deck_position(IDLE_CREW_SLOTS[0])
	if snapshot.is_empty():
		local_run_avatar_position = fallback_position
		local_run_avatar_world_position = boat_root.to_global(local_run_avatar_position)
		local_run_avatar_velocity = Vector3.ZERO
		local_run_avatar_mode = NetworkRuntime.RUN_AVATAR_MODE_DECK
		local_run_avatar_grounded = true
		local_avatar_facing_y = PI
		local_water_entry_active = false
		local_water_entry_elapsed = 0.0
		local_overboard_transition_pending = false
		local_off_deck_entry_elapsed = RUN_OFF_DECK_BLEND_DURATION
		local_surface_tread_active = false
		local_surface_tread_elapsed = 0.0
		_reset_local_run_transition_state(local_run_avatar_position, local_run_avatar_world_position)
		_sync_local_run_avatar_controller_from_state(true)
		return
	local_run_avatar_position = snapshot.get("deck_position", fallback_position)
	local_run_avatar_world_position = snapshot.get("world_position", boat_root.to_global(local_run_avatar_position))
	local_run_avatar_velocity = snapshot.get("velocity", Vector3.ZERO)
	local_run_avatar_mode = str(snapshot.get("mode", NetworkRuntime.RUN_AVATAR_MODE_DECK))
	local_run_avatar_grounded = bool(snapshot.get("grounded", true))
	local_avatar_facing_y = float(snapshot.get("facing_y", PI))
	local_water_entry_active = false
	local_water_entry_elapsed = 0.0
	local_overboard_transition_pending = false
	local_off_deck_entry_elapsed = RUN_OFF_DECK_BLEND_DURATION if local_run_avatar_mode == NetworkRuntime.RUN_AVATAR_MODE_DECK else 0.0
	local_surface_tread_active = local_run_avatar_mode == NetworkRuntime.RUN_AVATAR_MODE_SWIM
	local_surface_tread_elapsed = 0.0
	_reset_local_run_transition_state(local_run_avatar_position, local_run_avatar_world_position)
	_sync_local_run_avatar_controller_from_state(true)
	_refresh_local_run_avatar_controller()

func _reset_local_run_transition_state(deck_position: Vector3, world_position: Vector3) -> void:
	local_run_transition_state = LOCAL_RUN_TRANSITION_DECK
	local_run_transition_elapsed = 0.0
	local_run_offboard_elapsed = 0.0
	local_last_stable_deck_position = deck_position
	local_last_stable_deck_world_position = world_position

func _get_local_airborne_catch_projection() -> Dictionary:
	return NetworkRuntime.get_run_avatar_support_projection(local_run_avatar_position, RUN_AIRBORNE_DECK_CATCH_MARGIN)

func _can_recatch_local_deck(catch_projection: Dictionary, velocity: Vector3) -> bool:
	if not bool(catch_projection.get("valid", false)):
		return false
	var deck_position: Vector3 = catch_projection.get("deck_position", local_run_avatar_position)
	var deck_world_position := boat_root.to_global(deck_position)
	var planar_gap := Vector2(
		local_run_avatar_world_position.x - deck_world_position.x,
		local_run_avatar_world_position.z - deck_world_position.z
	).length()
	var vertical_gap := local_run_avatar_world_position.y - deck_world_position.y
	if planar_gap > RUN_AIRBORNE_DECK_CATCH_MARGIN:
		return false
	if vertical_gap < -RUN_AIRBORNE_DECK_CATCH_BELOW_TOLERANCE or vertical_gap > RUN_WATER_ENTRY_RELAND_VERTICAL_GRACE:
		return false
	if velocity.y > RUN_AIRBORNE_RETURN_MAX_ASCEND_SPEED:
		return false
	return true

func _begin_local_water_entry(entry_velocity: Vector3) -> void:
	local_water_entry_active = true
	local_water_entry_elapsed = 0.0
	local_off_deck_entry_elapsed = 0.0
	local_surface_tread_active = false
	local_surface_tread_elapsed = 0.0
	local_run_transition_state = LOCAL_RUN_TRANSITION_AIRBORNE_OFFBOARD
	local_run_transition_elapsed = 0.0
	local_run_offboard_elapsed = 0.0
	_set_local_run_avatar_collision_enabled(false)
	local_run_avatar_world_position = local_run_avatar_controller.global_position
	var boat_carry_velocity := _get_boat_world_linear_velocity()
	local_run_avatar_velocity = (boat_root.global_transform.basis * entry_velocity) + boat_carry_velocity
	local_run_avatar_controller.top_level = true
	local_run_avatar_controller.global_position = local_run_avatar_world_position
	local_run_avatar_controller.velocity = local_run_avatar_velocity

func _begin_local_swim_jump(world_velocity: Vector3) -> void:
	if local_run_avatar_controller == null:
		return
	local_water_entry_active = true
	local_water_entry_elapsed = 0.0
	local_overboard_transition_pending = false
	local_off_deck_entry_elapsed = 0.0
	local_surface_tread_active = false
	local_surface_tread_elapsed = 0.0
	local_run_transition_state = LOCAL_RUN_TRANSITION_AIRBORNE_OFFBOARD
	local_run_transition_elapsed = 0.0
	local_run_offboard_elapsed = 0.0
	local_swim_jump_cooldown = RUN_SWIM_JUMP_COOLDOWN
	local_run_avatar_mode = NetworkRuntime.RUN_AVATAR_MODE_SWIM
	local_run_avatar_velocity = world_velocity
	_set_local_run_avatar_collision_enabled(false)
	local_run_avatar_controller.top_level = true
	local_run_avatar_controller.global_position = local_run_avatar_world_position
	local_run_avatar_controller.velocity = world_velocity

func _build_local_run_avatar_controller() -> void:
	local_run_avatar_controller = boat_root.get_node_or_null("LocalAvatar") as CharacterBody3D
	if local_run_avatar_controller == null:
		local_run_avatar_controller = RUN_PLAYER_CONTROLLER_SCENE.instantiate() as CharacterBody3D
		if local_run_avatar_controller == null:
			return
		local_run_avatar_controller.name = "LocalAvatar"
		boat_root.add_child(local_run_avatar_controller)
	local_run_avatar_controller.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	local_run_avatar_controller.floor_snap_length = RUN_AVATAR_FLOOR_SNAP_LENGTH
	local_run_avatar_controller.platform_floor_layers = RUN_BLOCK_COLLISION_LAYER
	local_run_avatar_controller.platform_wall_layers = 0
	local_run_avatar_controller.safe_margin = 0.02
	if local_run_avatar_controller.has_method("set_tool_visible"):
		local_run_avatar_controller.call("set_tool_visible", false)
	_set_local_run_avatar_collision_enabled(not _is_local_off_deck())
	_sync_local_run_avatar_controller_from_state(true)
	_refresh_local_run_avatar_controller()

func _set_local_run_avatar_collision_enabled(enabled: bool) -> void:
	if local_run_avatar_controller == null:
		return
	var effective_enabled := enabled and not local_water_entry_active and not local_overboard_transition_pending
	local_run_avatar_controller.collision_layer = RUN_BLOCK_COLLISION_LAYER if effective_enabled else 0
	local_run_avatar_controller.collision_mask = RUN_BLOCK_COLLISION_LAYER if effective_enabled else 0
	var collision_shape := local_run_avatar_controller.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision_shape != null:
		collision_shape.disabled = not effective_enabled

func _should_enable_local_avatar_collision() -> bool:
	return not local_water_entry_active and not local_overboard_transition_pending

func _sync_local_run_avatar_controller_from_state(force_snap: bool = false) -> void:
	if local_run_avatar_controller == null:
		return
	if _is_local_off_deck():
		local_run_avatar_controller.top_level = true
		if force_snap or local_run_avatar_controller.global_position.distance_to(local_run_avatar_world_position) > 0.4:
			local_run_avatar_controller.global_position = local_run_avatar_world_position
	else:
		local_run_avatar_controller.top_level = true
		var target_position := _get_local_run_avatar_target() if not NetworkRuntime.get_peer_station_id(_get_local_peer_id()).is_empty() and _station_anchors_avatar(NetworkRuntime.get_peer_station_id(_get_local_peer_id())) else local_run_avatar_position
		var target_world_position := boat_root.to_global(target_position)
		if force_snap or local_run_avatar_controller.global_position.distance_to(target_world_position) > 0.35:
			local_run_avatar_controller.global_position = target_world_position
	local_run_avatar_controller.velocity = local_run_avatar_velocity

func _refresh_local_run_avatar_controller() -> void:
	if local_run_avatar_controller == null:
		return
	var local_state := _get_local_run_avatar_state()
	var station_id := NetworkRuntime.get_peer_station_id(_get_local_peer_id())
	var overboard := _is_local_swimming() or _is_local_climbing() or _is_local_water_entry()
	var downed := _is_local_downed()
	var display_name := str(NetworkRuntime.peer_snapshot.get(_get_local_peer_id(), {}).get("name", "You"))
	var presentation_state := local_state.duplicate(true)
	presentation_state["peer_id"] = _get_local_peer_id()
	_set_local_run_avatar_collision_enabled(_should_enable_local_avatar_collision())
	_sync_local_run_avatar_controller_from_state(false)
	_configure_run_avatar_controller(local_run_avatar_controller, display_name, station_id, presentation_state, overboard, downed)

func _configure_run_avatar_controller(
	controller: CharacterBody3D,
	display_name: String,
	station_id: String,
	avatar_state: Dictionary,
	overboard: bool,
	downed: bool,
	reaction_label: String = ""
) -> void:
	if controller == null:
		return
	var badge_text := _format_avatar_badges(avatar_state)
	var mode := str(avatar_state.get("mode", NetworkRuntime.RUN_AVATAR_MODE_DECK))
	var role_label := "Crew"
	if downed:
		role_label = "Downed"
	elif mode == NetworkRuntime.RUN_AVATAR_MODE_CLIMB:
		role_label = "Climbing"
	elif mode == NetworkRuntime.RUN_AVATAR_MODE_SWIM or overboard:
		role_label = "Swimming"
	elif not station_id.is_empty():
		role_label = NetworkRuntime.get_station_label(station_id)
	if not reaction_label.is_empty():
		role_label += " [%s]" % reaction_label
	if not badge_text.is_empty():
		role_label += " [%s]" % badge_text
	var peer_id := int(avatar_state.get("peer_id", _get_local_peer_id()))
	var highlight_color := _get_run_avatar_highlight_color(peer_id, station_id, overboard, downed)
	if controller.has_method("configure_presentation"):
		controller.call(
			"configure_presentation",
			display_name,
			highlight_color,
			highlight_color.lightened(0.22),
			Color(0.96, 0.98, 1.0),
			role_label
		)
	else:
		var avatar_visual := controller.get_node_or_null("AvatarVisual") as Node3D
		if avatar_visual != null and avatar_visual.has_method("set_display_text"):
			avatar_visual.call("set_display_text", display_name, role_label)
	if controller.has_method("set_tool_visible"):
		controller.call("set_tool_visible", false)
	if controller.has_method("set_motion_blend"):
		controller.call("set_motion_blend", _get_run_avatar_motion_blend(avatar_state, overboard, downed))
	elif controller.has_method("set_motion_state"):
		controller.call("set_motion_state", _get_run_avatar_motion_state(avatar_state, overboard, downed))

func _update_local_run_avatar_controller(delta: float) -> void:
	if local_run_avatar_controller == null:
		return
	var local_state := _get_local_run_avatar_state()
	var station_id := NetworkRuntime.get_peer_station_id(_get_local_peer_id())
	var overboard := _is_local_swimming()
	var climbing := _is_local_climbing()
	var water_entry := _is_local_water_entry()
	var downed := _is_local_downed()
	var local_reaction := _get_reaction_visual(_get_local_peer_id())
	var local_knockback := Vector3.ZERO
	var intensity := 0.0
	if not local_reaction.is_empty():
		var active_time := float(local_reaction.get("active_time", 0.0))
		var recovery_time := float(local_reaction.get("recovery_time", 0.0))
		var recovery_duration := maxf(0.01, float(local_reaction.get("recovery_duration", 0.01)))
		intensity = 1.0 if active_time > 0.0 else clampf(recovery_time / recovery_duration, 0.0, 1.0) * 0.55
		var knockback: Vector3 = local_reaction.get("knockback_velocity", Vector3.ZERO)
		local_knockback = boat_root.global_transform.basis.inverse() * knockback
	var target_yaw := local_avatar_facing_y
	if water_entry:
		var target_world_position := local_run_avatar_world_position
		_set_local_run_avatar_collision_enabled(false)
		local_run_avatar_controller.top_level = true
		local_run_avatar_controller.global_position = target_world_position
		local_run_avatar_controller.rotation.y = lerp_angle(local_run_avatar_controller.rotation.y, target_yaw, minf(1.0, delta * 10.0))
		local_run_avatar_controller.rotation.x = lerp_angle(local_run_avatar_controller.rotation.x, clampf(local_run_avatar_velocity.y * -0.05, -0.32, 0.22), minf(1.0, delta * 10.0))
		local_run_avatar_controller.rotation.z = lerp_angle(local_run_avatar_controller.rotation.z, 0.0, minf(1.0, delta * 10.0))
	elif climbing:
		var climb_world_position := local_run_avatar_world_position
		_set_local_run_avatar_collision_enabled(false)
		local_run_avatar_controller.top_level = true
		if local_run_avatar_controller.global_position.distance_to(climb_world_position) > 0.02:
			local_run_avatar_controller.global_position = climb_world_position
		local_run_avatar_controller.rotation.y = lerp_angle(local_run_avatar_controller.rotation.y, target_yaw, minf(1.0, delta * 10.0))
		local_run_avatar_controller.rotation.x = lerp_angle(local_run_avatar_controller.rotation.x, -0.04 + clampf(local_knockback.z * -0.02 * intensity, -0.12, 0.12), minf(1.0, delta * 9.0))
		local_run_avatar_controller.rotation.z = lerp_angle(local_run_avatar_controller.rotation.z, clampf(local_knockback.x * 0.02 * intensity, -0.10, 0.10), minf(1.0, delta * 9.0))
	elif overboard:
		var target_world_position := local_run_avatar_world_position
		var surface_tread_tilt := _get_local_surface_tread_tilt(target_yaw)
		_set_local_run_avatar_collision_enabled(true)
		local_run_avatar_controller.top_level = true
		if local_run_avatar_controller.global_position.distance_to(target_world_position) > 0.02:
			local_run_avatar_controller.global_position = target_world_position
		local_run_avatar_controller.rotation.y = lerp_angle(local_run_avatar_controller.rotation.y, target_yaw, minf(1.0, delta * 10.0))
		local_run_avatar_controller.rotation.x = lerp_angle(local_run_avatar_controller.rotation.x, surface_tread_tilt.x + clampf(local_knockback.z * -0.03 * intensity, -0.18, 0.18), minf(1.0, delta * 9.0))
		local_run_avatar_controller.rotation.z = lerp_angle(local_run_avatar_controller.rotation.z, surface_tread_tilt.y + clampf(local_knockback.x * 0.04 * intensity, -0.18, 0.18), minf(1.0, delta * 9.0))
	else:
		_set_local_run_avatar_collision_enabled(true)
		var target_position := local_run_avatar_position
		var reboard_settle_blend := _get_local_reboard_settle_blend()
		if not station_id.is_empty() and _station_anchors_avatar(station_id):
			target_position = _get_local_run_avatar_target()
			local_run_avatar_controller.global_position = boat_root.to_global(target_position)
		local_run_avatar_controller.top_level = true
		local_run_avatar_controller.scale = local_run_avatar_controller.scale.lerp(Vector3.ONE, minf(1.0, delta * 8.0))
		local_run_avatar_controller.rotation.y = lerp_angle(local_run_avatar_controller.rotation.y, target_yaw, minf(1.0, delta * 10.0))
		local_run_avatar_controller.rotation.x = lerp_angle(local_run_avatar_controller.rotation.x, 0.16 * reboard_settle_blend, minf(1.0, delta * 12.0))
		local_run_avatar_controller.rotation.z = lerp_angle(local_run_avatar_controller.rotation.z, 0.0, minf(1.0, delta * 12.0))
	local_run_avatar_controller.velocity = local_run_avatar_velocity

func _sanitize_local_run_avatar_position(deck_position: Vector3, fallback_position = null) -> Vector3:
	return NetworkRuntime.sanitize_run_avatar_deck_position(deck_position, fallback_position)

func _get_local_run_avatar_target() -> Vector3:
	var local_station_id := NetworkRuntime.get_peer_station_id(_get_local_peer_id())
	if local_station_id.is_empty() or not _station_anchors_avatar(local_station_id):
		return local_run_avatar_position
	return NetworkRuntime.get_station_position(local_station_id) + Vector3(0.0, 0.18, 0.0)

func _get_local_run_avatar_state() -> Dictionary:
	return NetworkRuntime.get_run_avatar_state().get(_get_local_peer_id(), {})

func _is_local_swimming() -> bool:
	return local_run_avatar_mode == NetworkRuntime.RUN_AVATAR_MODE_SWIM

func _is_local_climbing() -> bool:
	return local_run_avatar_mode == NetworkRuntime.RUN_AVATAR_MODE_CLIMB

func _is_local_overboard() -> bool:
	return _is_local_swimming()

func _is_local_water_entry() -> bool:
	return local_water_entry_active

func _is_local_off_deck() -> bool:
	return _is_local_swimming() or _is_local_climbing() or _is_local_water_entry()

func _is_local_downed() -> bool:
	return local_run_avatar_mode == NetworkRuntime.RUN_AVATAR_MODE_DOWNED

func _get_local_off_deck_blend() -> float:
	return clampf(local_off_deck_entry_elapsed / RUN_OFF_DECK_BLEND_DURATION, 0.0, 1.0)

func _get_local_reboard_settle_blend() -> float:
	return clampf(local_reboard_settle_timer / RUN_REBOARD_SETTLE_DURATION, 0.0, 1.0)

func _is_local_surface_tread() -> bool:
	return local_surface_tread_active and _is_local_swimming()

func _get_local_surface_tread_height_offset() -> float:
	if not _is_local_surface_tread():
		return 0.0
	var planar_speed := Vector2(local_run_avatar_velocity.x, local_run_avatar_velocity.z).length()
	var speed_ratio := clampf(planar_speed / (RUN_SWIM_MOVE_SPEED * RUN_SWIM_BURST_MULTIPLIER), 0.0, 1.0)
	var bob_amplitude := lerpf(RUN_SURFACE_TREAD_BOB_AMPLITUDE, RUN_SURFACE_TREAD_BOB_AMPLITUDE * 0.45, speed_ratio)
	var bob := sin(connect_time_seconds * RUN_SURFACE_TREAD_BOB_SPEED + float(_get_local_peer_id()) * 0.73) * bob_amplitude
	var settle_progress := clampf(local_surface_tread_elapsed / RUN_SURFACE_TREAD_SETTLE_DURATION, 0.0, 1.0)
	var settle := lerpf(-0.15, 0.0, ease(settle_progress, -2.1)) + sin(settle_progress * PI) * 0.035
	return bob + settle

func _get_local_surface_tread_tilt(target_yaw: float) -> Vector2:
	if not _is_local_surface_tread():
		return Vector2.ZERO
	var local_planar_velocity := Basis(Vector3.UP, -target_yaw) * Vector3(local_run_avatar_velocity.x, 0.0, local_run_avatar_velocity.z)
	var planar_speed := Vector2(local_planar_velocity.x, local_planar_velocity.z).length()
	var speed_ratio := clampf(planar_speed / (RUN_SWIM_MOVE_SPEED * RUN_SWIM_BURST_MULTIPLIER), 0.0, 1.0)
	var bob_pitch := 0.05 + sin(connect_time_seconds * RUN_SURFACE_TREAD_BOB_SPEED + 0.4) * 0.02
	var pitch := bob_pitch + clampf(-local_planar_velocity.z * 0.055, -RUN_SURFACE_TREAD_LEAN_MAX, RUN_SURFACE_TREAD_LEAN_MAX) * (0.45 + speed_ratio * 0.55)
	var roll := clampf(local_planar_velocity.x * 0.075, -RUN_SURFACE_TREAD_LEAN_MAX, RUN_SURFACE_TREAD_LEAN_MAX) * (0.35 + speed_ratio * 0.65)
	return Vector2(pitch, roll)

func _get_local_surface_camera_roll(target_yaw: float) -> float:
	if not _is_local_surface_tread():
		return 0.0
	var local_planar_velocity := Basis(Vector3.UP, -target_yaw) * Vector3(local_run_avatar_velocity.x, 0.0, local_run_avatar_velocity.z)
	var planar_speed := Vector2(local_planar_velocity.x, local_planar_velocity.z).length()
	var speed_ratio := clampf(planar_speed / (RUN_SWIM_MOVE_SPEED * RUN_SWIM_BURST_MULTIPLIER), 0.0, 1.0)
	var drift_roll := clampf(local_planar_velocity.x * -0.045, -0.09, 0.09) * (0.4 + speed_ratio * 0.6)
	var bob_roll := sin(connect_time_seconds * RUN_SURFACE_TREAD_BOB_SPEED + 1.1) * 0.016
	return drift_roll + bob_roll

func _get_local_avatar_world_position() -> Vector3:
	if local_run_avatar_controller != null and (_is_local_off_deck() or local_overboard_transition_pending):
		return local_run_avatar_controller.global_position
	if _is_local_overboard():
		return local_run_avatar_world_position
	if local_run_avatar_controller != null:
		return local_run_avatar_controller.global_position
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

func _get_local_swim_drift_velocity(world_position: Vector3) -> Vector3:
	var boat_velocity := _get_boat_world_linear_velocity()
	boat_velocity.y = 0.0
	var boat_speed := Vector2(boat_velocity.x, boat_velocity.z).length()
	if boat_speed <= 0.01:
		return Vector3.ZERO
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var rotation_y: float = float(NetworkRuntime.boat_state.get("rotation_y", 0.0))
	var local_offset := (world_position - boat_position).rotated(Vector3.UP, -rotation_y)
	local_offset.y = 0.0
	var hull_beam := maxf(1.4, float(NetworkRuntime.boat_state.get("hull_beam", 2.7)))
	var hull_length := maxf(2.8, float(NetworkRuntime.boat_state.get("hull_length", 4.4)))
	var side_clearance := absf(local_offset.x) - hull_beam * 0.5
	var fore_aft_clearance := absf(local_offset.z) - hull_length * 0.58
	var edge_proximity := 1.0 - clampf(maxf(side_clearance, fore_aft_clearance) / 2.6, 0.0, 1.0)
	var drift_velocity := boat_velocity * lerpf(RUN_SWIM_BOAT_CARRY_MIN, RUN_SWIM_BOAT_CARRY_MAX, edge_proximity)
	var stern_clearance := -local_offset.z - hull_length * 0.42
	if stern_clearance > 0.0 and absf(local_offset.x) <= hull_beam * 0.95 + 1.15:
		var stern_ratio := clampf(1.0 - stern_clearance / RUN_SWIM_STERN_DRIFT_RADIUS, 0.0, 1.0)
		var local_pull := Vector3(-local_offset.x, 0.0, stern_clearance + hull_length * 0.18)
		if local_pull.length_squared() > 0.001:
			drift_velocity += local_pull.normalized().rotated(Vector3.UP, rotation_y) * (boat_speed * 0.24 + RUN_SWIM_STERN_DRIFT_PULL * stern_ratio)
	return drift_velocity.limit_length(boat_speed * 0.62 + RUN_SWIM_STERN_DRIFT_PULL)

func _resolve_local_swim_hull_core(world_position: Vector3) -> Vector3:
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var rotation_y: float = float(NetworkRuntime.boat_state.get("rotation_y", 0.0))
	var local_offset := (world_position - boat_position).rotated(Vector3.UP, -rotation_y)
	local_offset.y = 0.0
	var hull_half_beam := maxf(0.92, float(NetworkRuntime.boat_state.get("hull_beam", 2.7)) * 0.46)
	var hull_half_length := maxf(1.32, float(NetworkRuntime.boat_state.get("hull_length", 4.4)) * 0.44)
	var normalized := Vector2(
		local_offset.x / maxf(0.001, hull_half_beam),
		local_offset.z / maxf(0.001, hull_half_length)
	)
	var normalized_length := normalized.length()
	if normalized_length >= RUN_SWIM_HULL_CORE_FACTOR:
		return world_position
	if normalized_length <= 0.001:
		normalized = Vector2(0.0, -1.0)
	else:
		normalized /= normalized_length
	var adjusted_local := Vector3(
		normalized.x * hull_half_beam * RUN_SWIM_HULL_CORE_FACTOR,
		0.0,
		normalized.y * hull_half_length * RUN_SWIM_HULL_CORE_FACTOR
	)
	var adjusted_position := boat_position + adjusted_local.rotated(Vector3.UP, rotation_y)
	adjusted_position.y = NetworkRuntime.RUN_OVERBOARD_WATER_HEIGHT
	return adjusted_position

func _get_boat_world_linear_velocity() -> Vector3:
	return boat_visual_velocity

func _try_reacquire_local_deck_from_water_entry() -> bool:
	if local_run_avatar_controller == null:
		return false
	var local_probe := boat_root.to_local(local_run_avatar_world_position)
	var support_projection := NetworkRuntime.get_run_avatar_support_projection(
		local_probe,
		maxf(NetworkRuntime.RUN_OVERBOARD_EDGE_MARGIN, RUN_WATER_ENTRY_RELAND_HORIZONTAL_GRACE)
	)
	if not bool(support_projection.get("valid", false)):
		return false
	var deck_position: Vector3 = support_projection.get("deck_position", local_probe)
	var deck_world_position := boat_root.to_global(deck_position)
	var planar_gap := Vector2(
		local_run_avatar_world_position.x - deck_world_position.x,
		local_run_avatar_world_position.z - deck_world_position.z
	).length()
	var vertical_gap := local_run_avatar_world_position.y - deck_world_position.y
	if planar_gap > RUN_WATER_ENTRY_RELAND_HORIZONTAL_GRACE:
		return false
	if vertical_gap < -0.08 or vertical_gap > RUN_WATER_ENTRY_RELAND_VERTICAL_GRACE:
		return false
	if local_run_avatar_velocity.y > 1.2:
		return false
	local_water_entry_active = false
	local_water_entry_elapsed = 0.0
	local_overboard_transition_pending = false
	local_off_deck_entry_elapsed = RUN_OFF_DECK_BLEND_DURATION
	local_surface_tread_active = false
	local_surface_tread_elapsed = 0.0
	local_run_avatar_mode = NetworkRuntime.RUN_AVATAR_MODE_DECK
	local_run_avatar_position = deck_position
	local_run_avatar_world_position = deck_world_position
	local_run_avatar_grounded = true
	var deck_velocity := local_run_avatar_velocity
	deck_velocity.y = 0.0
	local_run_avatar_velocity = deck_velocity
	_set_local_run_avatar_collision_enabled(true)
	local_run_avatar_controller.top_level = true
	local_run_avatar_controller.global_position = deck_world_position
	local_run_avatar_controller.velocity = deck_velocity
	return true

func _clamp_local_position_to_climb_surface(surface: Dictionary, local_position: Vector3) -> Vector3:
	var surface_type := str(surface.get("type", ""))
	if surface_type == "ladder":
		var water_position: Vector3 = surface.get("water_position", Vector3.ZERO)
		var deck_position: Vector3 = surface.get("deck_position", water_position)
		return Vector3(
			water_position.x,
			clampf(local_position.y, float(surface.get("min_y", water_position.y)), float(surface.get("max_y", deck_position.y))),
			water_position.z
		)
	var anchor_local_position: Vector3 = surface.get("anchor_local_position", Vector3.ZERO)
	var tangent: Vector3 = surface.get("tangent", Vector3.FORWARD)
	var tangent_offset := (local_position - anchor_local_position).dot(tangent)
	tangent_offset = clampf(tangent_offset, float(surface.get("min_tangent", -0.4)), float(surface.get("max_tangent", 0.4)))
	var clamped_y := clampf(local_position.y, float(surface.get("min_y", anchor_local_position.y)), float(surface.get("max_y", anchor_local_position.y)))
	var tangent_position := anchor_local_position + tangent * tangent_offset
	return Vector3(tangent_position.x, clamped_y, tangent_position.z)

func _clamp_world_position_to_climb_surface(surface: Dictionary, world_position: Vector3) -> Vector3:
	var local_position := boat_root.to_local(world_position)
	return boat_root.to_global(_clamp_local_position_to_climb_surface(surface, local_position))

func _get_local_climb_surface() -> Dictionary:
	var local_state := _get_local_run_avatar_state()
	if local_state.is_empty():
		return {}
	var surface_id := str(local_state.get("climb_surface_id", ""))
	if surface_id.is_empty():
		return {}
	var surface := NetworkRuntime.get_run_climb_surface(surface_id)
	if surface.is_empty():
		return {}
	surface["attach_world_position"] = _clamp_world_position_to_climb_surface(surface, local_run_avatar_world_position)
	return surface

func _get_local_climb_surface_candidate(include_ladders: bool = true) -> Dictionary:
	var current_frame := Engine.get_physics_frames()
	if current_frame == local_climb_surface_candidate_cache_frame \
	and include_ladders == local_climb_surface_candidate_cache_include_ladders \
	and local_climb_surface_candidate_cache_world_position.distance_to(local_run_avatar_world_position) <= 0.01:
		return local_climb_surface_candidate_cache.duplicate(true)
	var best_surface: Dictionary = {}
	var best_distance := INF
	for surface_variant in NetworkRuntime.get_nearby_run_climb_surfaces(local_run_avatar_world_position, include_ladders):
		var surface: Dictionary = surface_variant
		var attach_world_position := _clamp_world_position_to_climb_surface(surface, local_run_avatar_world_position)
		var distance := attach_world_position.distance_to(local_run_avatar_world_position)
		var attach_range := float(surface.get("attach_range", NetworkRuntime.RUN_CLIMB_ATTACH_WORLD_RANGE)) + RUN_CLIMB_ATTACH_BUFFER
		if distance > attach_range or distance >= best_distance:
			continue
		best_distance = distance
		best_surface = surface.duplicate(true)
		best_surface["attach_world_position"] = attach_world_position
		best_surface["attach_distance"] = distance
	local_climb_surface_candidate_cache = best_surface.duplicate(true)
	local_climb_surface_candidate_cache_frame = current_frame
	local_climb_surface_candidate_cache_include_ladders = include_ladders
	local_climb_surface_candidate_cache_world_position = local_run_avatar_world_position
	return best_surface

func _try_top_out_local_climb(surface: Dictionary) -> bool:
	if surface.is_empty():
		return false
	var deck_position := NetworkRuntime.get_nearest_run_avatar_deck_position(surface.get("deck_position", local_run_avatar_position))
	var deck_world_position := boat_root.to_global(deck_position)
	if local_run_avatar_world_position.y < deck_world_position.y - RUN_CLIMB_TOP_OUT_DISTANCE:
		return false
	local_run_avatar_mode = NetworkRuntime.RUN_AVATAR_MODE_DECK
	local_run_avatar_position = deck_position
	local_run_avatar_world_position = deck_world_position
	local_run_avatar_velocity = Vector3.ZERO
	local_run_avatar_grounded = true
	local_water_entry_active = false
	local_water_entry_elapsed = 0.0
	local_overboard_transition_pending = false
	local_off_deck_entry_elapsed = RUN_OFF_DECK_BLEND_DURATION
	local_surface_tread_active = false
	local_surface_tread_elapsed = 0.0
	_reset_local_run_transition_state(deck_position, deck_world_position)
	_set_local_run_avatar_collision_enabled(true)
	if local_run_avatar_controller != null:
		local_run_avatar_controller.top_level = true
		local_run_avatar_controller.global_position = deck_world_position
		local_run_avatar_controller.velocity = Vector3.ZERO
	NetworkRuntime.send_local_run_avatar_state(
		local_run_avatar_position,
		local_run_avatar_world_position,
		local_run_avatar_velocity,
		local_avatar_facing_y,
		true,
		local_run_avatar_mode
	)
	return true

func _detach_local_climb(jump_direction_world: Vector3) -> void:
	var climb_surface := _get_local_climb_surface()
	var detach_velocity := Vector3.UP * RUN_CLIMB_JUMP_OFF_UPWARD
	if not climb_surface.is_empty():
		var surface_normal: Vector3 = climb_surface.get("normal", Vector3.ZERO).rotated(Vector3.UP, boat_root.rotation.y)
		detach_velocity += surface_normal * RUN_CLIMB_JUMP_OFF_PUSH
	if jump_direction_world.length() > 0.001:
		detach_velocity += jump_direction_world.normalized() * RUN_CLIMB_JUMP_OFF_PUSH
	NetworkRuntime.request_local_climb_detach(local_run_avatar_world_position, detach_velocity)
	_begin_local_swim_jump(detach_velocity)

func _get_local_rally_target() -> Dictionary:
	if _is_local_off_deck() or _is_local_downed():
		return {}
	var best_target: Dictionary = {}
	var best_distance := INF
	for peer_id in NetworkRuntime.get_player_peer_ids():
		if int(peer_id) == _get_local_peer_id():
			continue
		var avatar_state: Dictionary = NetworkRuntime.get_run_avatar_state().get(int(peer_id), {})
		if str(avatar_state.get("mode", NetworkRuntime.RUN_AVATAR_MODE_DECK)) != NetworkRuntime.RUN_AVATAR_MODE_DOWNED:
			continue
		var target_position: Vector3 = avatar_state.get("deck_position", Vector3.ZERO)
		var distance := local_run_avatar_position.distance_to(target_position)
		if distance > NetworkRuntime.AVATAR_ASSIST_RALLY_RANGE or distance >= best_distance:
			continue
		best_distance = distance
		best_target = {
			"peer_id": int(peer_id),
			"distance": distance,
			"name": str(NetworkRuntime.peer_snapshot.get(int(peer_id), {}).get("name", "Crew")),
		}
	return best_target

func _can_local_use_stamina_action(cost: float) -> bool:
	if _is_local_downed():
		return false
	var local_state := _get_local_run_avatar_state()
	if local_state.is_empty():
		return false
	if bool(local_state.get("stamina_exhausted", false)):
		return false
	return float(local_state.get("stamina", NetworkRuntime.AVATAR_MAX_STAMINA)) >= cost

func _show_local_action_blocked(text: String) -> void:
	_push_event_callout(text, HUD_TEXT_WARNING, 1.3)

func _get_avatar_status_badges(avatar_state: Dictionary) -> PackedStringArray:
	var badges := PackedStringArray()
	var mode := str(avatar_state.get("mode", NetworkRuntime.RUN_AVATAR_MODE_DECK))
	if mode == NetworkRuntime.RUN_AVATAR_MODE_SWIM:
		badges.append("Swimming")
	elif mode == NetworkRuntime.RUN_AVATAR_MODE_CLIMB:
		badges.append("Climbing")
	elif mode == NetworkRuntime.RUN_AVATAR_MODE_DOWNED:
		badges.append("Downed")
	var health := float(avatar_state.get("health", NetworkRuntime.AVATAR_MAX_HEALTH))
	if mode != NetworkRuntime.RUN_AVATAR_MODE_DOWNED and health > 0.0:
		if health <= NetworkRuntime.AVATAR_CRITICAL_THRESHOLD:
			badges.append("Critical")
		elif health <= NetworkRuntime.AVATAR_WOUNDED_THRESHOLD:
			badges.append("Wounded")
	if bool(avatar_state.get("stamina_exhausted", false)):
		badges.append("Exhausted")
	return badges

func _format_avatar_badges(avatar_state: Dictionary) -> String:
	var badges := _get_avatar_status_badges(avatar_state)
	return " | ".join(badges)

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
	return float(NetworkRuntime.station_state.get(station_id, {}).get("claim_radius", 0.0))

func _is_local_near_station(station_id: String, extra_margin: float = 0.0) -> bool:
	var claim_radius := _get_station_claim_radius(station_id)
	if claim_radius <= 0.0:
		return false
	return local_run_avatar_position.distance_to(NetworkRuntime.get_station_position(station_id)) <= (claim_radius + maxf(0.0, extra_margin))

func _find_local_repair_target() -> Dictionary:
	var nearest_block: Dictionary = {}
	var nearest_distance := NetworkRuntime.get_run_peer_repair_range(_get_local_peer_id())
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
	var previous_position := local_run_avatar_position
	local_run_avatar_position += Vector3(local_run_avatar_velocity.x, 0.0, local_run_avatar_velocity.z) * delta
	local_run_avatar_position = _sanitize_local_run_avatar_position(local_run_avatar_position, previous_position)
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
	for child in station_container.get_children():
		child.queue_free()
	station_visuals = {}
	for station_id in NetworkRuntime.get_station_ids():
		var station_node := RUN_STATION_MARKER_SCENE.instantiate() as Node3D
		if station_node == null:
			station_node = Node3D.new()
		station_node.position = NetworkRuntime.get_station_position(station_id)
		station_container.add_child(station_node)
		station_visuals[station_id] = {
			"root": station_node,
		}

func _build_recovery_visuals() -> void:
	if recovery_container == null:
		return
	for child in recovery_container.get_children():
		child.queue_free()
	recovery_visuals = {}
	for target_variant in NetworkRuntime.get_run_ladder_points():
		var target: Dictionary = target_variant
		var target_node := RUN_RECOVERY_MARKER_SCENE.instantiate() as Node3D
		if target_node == null:
			target_node = Node3D.new()
		target_node.name = "%sMarker" % str(target.get("id", "Recovery"))
		target_node.position = target.get("water_position", Vector3.ZERO)
		recovery_container.add_child(target_node)
		if target_node.has_method("set_marker_text"):
			target_node.call("set_marker_text", str(target.get("label", "Recovery")))
		if target_node.has_method("set_marker_color"):
			target_node.call("set_marker_color", Color(0.20, 0.70, 0.74))
		if target_node.has_method("set_label_visible"):
			target_node.call("set_label_visible", false)
		recovery_visuals[str(target.get("id", ""))] = {
			"root": target_node,
		}

func _create_debug_overlay_marker(node_name: String, marker_text: String, color: Color) -> Node3D:
	var marker_node := RUN_RECOVERY_MARKER_SCENE.instantiate() as Node3D
	if marker_node == null:
		marker_node = Node3D.new()
	marker_node.name = node_name
	if marker_node.has_method("set_marker_text"):
		marker_node.call("set_marker_text", marker_text)
	if marker_node.has_method("set_marker_color"):
		marker_node.call("set_marker_color", color)
	if marker_node.has_method("set_label_visible"):
		marker_node.call("set_label_visible", true)
	return marker_node

func _build_debug_overlay_visuals() -> void:
	if debug_overlay_container == null:
		return
	for child in debug_overlay_container.get_children():
		child.queue_free()
	debug_overlay_visuals.clear()
	var overlay_specs := {
		"support": {
			"text": "Support",
			"color": HUD_TEXT_PRIMARY,
		},
		"direct_reboard": {
			"text": "Direct Reboard",
			"color": HUD_TEXT_SUCCESS,
		},
		"emergency_reboard": {
			"text": "Emergency Reboard",
			"color": HUD_TEXT_WARNING,
		},
	}
	for marker_id_variant in overlay_specs.keys():
		var marker_id := str(marker_id_variant)
		var marker_spec: Dictionary = overlay_specs[marker_id]
		var marker_node := _create_debug_overlay_marker(
			"%sDebugMarker" % marker_id.capitalize(),
			str(marker_spec.get("text", marker_id)),
			marker_spec.get("color", HUD_TEXT_PRIMARY)
		)
		debug_overlay_container.add_child(marker_node)
		marker_node.visible = false
		debug_overlay_visuals[marker_id] = {
			"root": marker_node,
		}
	debug_overlay_container.visible = false

func _set_debug_overlay_enabled(is_enabled: bool) -> void:
	debug_overlay_enabled = is_enabled
	if debug_overlay_container != null:
		debug_overlay_container.visible = debug_overlay_enabled
	if not debug_overlay_enabled:
		for marker_id_variant in debug_overlay_visuals.keys():
			_set_debug_marker_state(str(marker_id_variant), false, Vector3.ZERO, "", HUD_TEXT_MUTED)
	_push_event_callout(
		"Debug Overlay %s" % ("On" if debug_overlay_enabled else "Off"),
		HUD_TEXT_PRIMARY if debug_overlay_enabled else HUD_TEXT_MUTED,
		1.4
	)
	_refresh_hud()

func _set_debug_marker_state(marker_id: String, is_visible: bool, world_position: Vector3, label_text: String, color: Color) -> void:
	var marker_visual: Dictionary = debug_overlay_visuals.get(marker_id, {})
	var marker_root := marker_visual.get("root") as Node3D
	if marker_root == null:
		return
	marker_root.visible = is_visible and debug_overlay_enabled
	if not marker_root.visible:
		if marker_root.has_method("set_label_visible"):
			marker_root.call("set_label_visible", false)
		return
	marker_root.global_position = world_position
	if marker_root.has_method("set_marker_text"):
		marker_root.call("set_marker_text", label_text)
	if marker_root.has_method("set_marker_color"):
		marker_root.call("set_marker_color", color)
	if marker_root.has_method("set_label_visible"):
		marker_root.call("set_label_visible", true)

func _refresh_debug_overlay_visuals() -> void:
	if debug_overlay_container == null:
		return
	debug_overlay_container.visible = debug_overlay_enabled
	if not debug_overlay_enabled or boat_root == null:
		for marker_id_variant in debug_overlay_visuals.keys():
			_set_debug_marker_state(str(marker_id_variant), false, Vector3.ZERO, "", HUD_TEXT_MUTED)
		return
	var local_world_position := _get_local_avatar_world_position()
	var local_probe := boat_root.to_local(local_world_position)
	var support_projection := NetworkRuntime.get_run_avatar_support_projection(
		local_probe,
		maxf(NetworkRuntime.RUN_OVERBOARD_EDGE_MARGIN, RUN_AVATAR_EDGE_EXIT_GRACE_DISTANCE)
	)
	var support_valid := bool(support_projection.get("valid", false))
	var support_local_position: Vector3 = support_projection.get("deck_position", local_probe)
	if not support_valid:
		support_local_position = NetworkRuntime.get_nearest_run_avatar_deck_position(local_probe)
	var support_world_position := boat_root.to_global(support_local_position)
	var support_planar_gap := Vector2(
		local_world_position.x - support_world_position.x,
		local_world_position.z - support_world_position.z
	).length()
	var support_vertical_gap := local_world_position.y - support_world_position.y
	_set_debug_marker_state(
		"support",
		true,
		support_world_position,
		"Support %s\nPlanar %.2f | Vertical %.2f" % [
			"OK" if support_valid else "Lost",
			support_planar_gap,
			support_vertical_gap,
		],
		HUD_TEXT_SUCCESS if support_valid else HUD_TEXT_DANGER
	)
	var climb_surface := _get_local_climb_surface_candidate()
	_set_debug_marker_state(
		"climb_surface",
		not climb_surface.is_empty(),
		climb_surface.get("attach_world_position", support_world_position),
		"%s\nDistance %.2f" % [
			"Ladder Attach" if str(climb_surface.get("type", "")) == "ladder" else "Hull Climb",
			float(climb_surface.get("attach_distance", 0.0)),
		],
		HUD_TEXT_SUCCESS if str(climb_surface.get("type", "")) == "ladder" else HUD_TEXT_WARNING
	)

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
	var stage_clock_panel := hud.get_node("StageClockPanel") as PanelContainer
	var objective_panel := hud.get_node("ObjectivePanel") as PanelContainer
	var health_panel := hud.get_node("HealthPanel") as PanelContainer
	var stamina_panel := hud.get_node("StaminaPanel") as PanelContainer
	tool_panel = hud.get_node("ToolPanel") as PanelContainer
	boat_inspect_panel = hud.get_node("BoatInspectPanel") as PanelContainer
	inventory_panel = hud.get_node("InventoryPanel") as PanelContainer

	stage_clock_icon = hud.get_node("StageClockPanel/Margin/Layout/HeadingRow/ClockIcon") as TextureRect
	clock_label = hud.get_node("StageClockPanel/Margin/Layout/ClockLabel") as Label
	pressure_clock_label = hud.get_node("StageClockPanel/Margin/Layout/PressureLabel") as Label
	stage_clock_progress_bar = hud.get_node("StageClockPanel/Margin/Layout/ClockProgressBar") as ProgressBar
	objective_icon = hud.get_node("ObjectivePanel/Margin/Layout/HeadingRow/ObjectiveIcon") as TextureRect
	compass_label = hud.get_node("ObjectivePanel/Margin/Layout/CompassLabel") as Label
	objective_label = hud.get_node("ObjectivePanel/Margin/Layout/ObjectiveLabel") as Label
	health_meter_label = hud.get_node("HealthPanel/Margin/Layout/HealthMeterLabel") as Label
	health_meter_bar = hud.get_node("HealthPanel/Margin/Layout/HealthMeterBar") as ProgressBar
	stamina_meter_label = hud.get_node("StaminaPanel/Margin/Layout/StaminaMeterLabel") as Label
	stamina_meter_bar = hud.get_node("StaminaPanel/Margin/Layout/StaminaMeterBar") as ProgressBar
	toolbelt_label = hud.get_node("ToolPanel/Margin/Layout/ToolLabel") as Label
	station_label = hud.get_node("ToolPanel/Margin/Layout/StationPromptLabel") as Label
	hotbar_slot_panels.clear()
	hotbar_slot_key_labels.clear()
	hotbar_slot_name_labels.clear()
	hotbar_slot_icons.clear()
	for slot_index in range(4):
		var slot_path := "ToolPanel/Margin/Layout/HotbarRow/Slot%d" % [slot_index + 1]
		var slot_panel := hud.get_node(slot_path) as PanelContainer
		var key_label := hud.get_node("%s/Margin/Layout/TopRow/KeyLabel" % slot_path) as Label
		var name_label := hud.get_node("%s/Margin/Layout/TopRow/NameLabel" % slot_path) as Label
		var slot_icon := hud.get_node("%s/Margin/Layout/Icon" % slot_path) as TextureRect
		hotbar_slot_panels.append(slot_panel)
		hotbar_slot_key_labels.append(key_label)
		hotbar_slot_name_labels.append(name_label)
		hotbar_slot_icons.append(slot_icon)
	inspect_panel_icon = hud.get_node("BoatInspectPanel/Margin/Layout/HeadingRow/InspectIcon") as TextureRect
	boat_label = hud.get_node("BoatInspectPanel/Margin/Layout/BoatLabel") as Label
	resource_label = hud.get_node("BoatInspectPanel/Margin/Layout/ResourceLabel") as Label
	run_label = hud.get_node("BoatInspectPanel/Margin/Layout/RunLabel") as Label
	interaction_label = hud.get_node("BoatInspectPanel/Margin/Layout/InteractionLabel") as Label
	status_label = hud.get_node("BoatInspectPanel/Margin/Layout/StatusLabel") as Label
	inventory_label = hud.get_node("InventoryPanel/Margin/Layout/InventoryLabel") as Label
	crosshair_label = hud.get_node("CrosshairLabel") as Label
	event_callout_label = hud.get_node("EventCalloutLabel") as Label

	hud_icons.configure_icon_rect(stage_clock_icon, Vector2(28.0, 28.0))
	hud_icons.configure_icon_rect(objective_icon, Vector2(22.0, 22.0))
	hud_icons.configure_icon_rect(inspect_panel_icon, Vector2(24.0, 24.0))
	for slot_icon_variant in hotbar_slot_icons:
		hud_icons.configure_icon_rect(slot_icon_variant as TextureRect, Vector2(28.0, 28.0))
	hud_icons.set_icon(stage_clock_icon, "brace")
	hud_icons.set_icon(inspect_panel_icon, "repair-kit")

	_apply_hud_panel_style(stage_clock_panel, ExpeditionHudSkin.BRASS_YELLOW, HUD_PANEL_BG_SOFT, "ghost")
	_apply_hud_panel_style(objective_panel, HUD_BORDER_ORANGE, HUD_PANEL_BG, "ghost")
	_apply_hud_panel_style(health_panel, ExpeditionHudSkin.SEA_GLASS_GREEN, HUD_PANEL_BG_SOFT, "ghost")
	_apply_hud_panel_style(stamina_panel, ExpeditionHudSkin.BUOY_ORANGE, HUD_PANEL_BG_SOFT, "ghost")
	_apply_hud_panel_style(tool_panel, HUD_BORDER_ORANGE, HUD_PANEL_BG_SOFT, "ghost")
	_apply_hud_panel_style(boat_inspect_panel, HUD_BORDER_GREEN, HUD_PANEL_BG, "ledger")
	_apply_hud_panel_style(inventory_panel, HUD_BORDER_BLUE, HUD_PANEL_BG_SOFT, "ledger")

	var clock_heading := hud.get_node("StageClockPanel/Margin/Layout/HeadingRow/ClockHeading") as Label
	var objective_heading := hud.get_node("ObjectivePanel/Margin/Layout/HeadingRow/ObjectiveHeading") as Label
	var tool_heading := hud.get_node("ToolPanel/Margin/Layout/Heading") as Label
	var inspect_heading := hud.get_node("BoatInspectPanel/Margin/Layout/HeadingRow/InspectHeading") as Label
	var inventory_heading := hud.get_node("InventoryPanel/Margin/Layout/Heading") as Label
	ExpeditionHudSkin.apply_heading(clock_heading, HUD_TEXT_WARNING)
	ExpeditionHudSkin.apply_body(clock_label, HUD_TEXT_PRIMARY)
	ExpeditionHudSkin.apply_muted(pressure_clock_label)
	ExpeditionHudSkin.apply_heading(objective_heading, HUD_TEXT_WARNING)
	ExpeditionHudSkin.apply_heading(objective_label, HUD_TEXT_PRIMARY)
	ExpeditionHudSkin.apply_muted(compass_label)
	ExpeditionHudSkin.apply_body(health_meter_label, HUD_TEXT_MUTED)
	ExpeditionHudSkin.apply_body(stamina_meter_label, HUD_TEXT_MUTED)
	ExpeditionHudSkin.apply_heading(tool_heading, HUD_TEXT_WARNING)
	ExpeditionHudSkin.apply_body(toolbelt_label, HUD_TEXT_PRIMARY)
	ExpeditionHudSkin.apply_muted(station_label)
	for key_label_variant in hotbar_slot_key_labels:
		ExpeditionHudSkin.apply_muted(key_label_variant as Label)
	for name_label_variant in hotbar_slot_name_labels:
		ExpeditionHudSkin.apply_body(name_label_variant as Label, HUD_TEXT_MUTED)
	ExpeditionHudSkin.apply_heading(inspect_heading, HUD_TEXT_SUCCESS)
	ExpeditionHudSkin.apply_body(boat_label, HUD_TEXT_PRIMARY)
	ExpeditionHudSkin.apply_body(resource_label, HUD_TEXT_PRIMARY)
	ExpeditionHudSkin.apply_muted(run_label)
	ExpeditionHudSkin.apply_muted(interaction_label)
	ExpeditionHudSkin.apply_muted(status_label)
	ExpeditionHudSkin.apply_heading(inventory_heading, HUD_TEXT_MUTED)
	ExpeditionHudSkin.apply_body(inventory_label, HUD_TEXT_PRIMARY)
	ExpeditionHudSkin.apply_crosshair(crosshair_label)
	ExpeditionHudSkin.apply_callout(event_callout_label, HUD_TEXT_PRIMARY)
	_apply_meter_bar_style(stage_clock_progress_bar, HUD_TEXT_WARNING)
	_apply_meter_bar_style(health_meter_bar, HUD_TEXT_SUCCESS)
	_apply_meter_bar_style(stamina_meter_bar, HUD_TEXT_WARNING)

func _apply_hud_panel_style(
	panel: PanelContainer,
	border_color: Color,
	background_color: Color,
	variant: String = "plate"
) -> void:
	ExpeditionHudSkin.apply_plate(panel, border_color, background_color, variant)

func _apply_meter_bar_style(bar: ProgressBar, fill_color: Color) -> void:
	ExpeditionHudSkin.apply_meter(bar, fill_color)

func _build_result_overlay() -> void:
	result_layer = get_node("ResultOverlay") as CanvasLayer
	var dimmer := result_layer.get_node("Dimmer") as ColorRect
	result_panel = result_layer.get_node("Center/ResultPanel") as PanelContainer
	result_panel_icon = result_layer.get_node("Center/ResultPanel/Inner/Layout/HeadingRow/ResultPanelIcon") as TextureRect
	result_title_label = result_layer.get_node("Center/ResultPanel/Inner/Layout/HeadingRow/ResultTitleLabel") as Label
	result_body_label = result_layer.get_node("Center/ResultPanel/Inner/Layout/ResultBodyLabel") as Label
	result_continue_button = result_layer.get_node("Center/ResultPanel/Inner/Layout/ResultContinueButton") as Button
	var hint_label := result_layer.get_node("Center/ResultPanel/Inner/Layout/HintLabel") as Label
	hud_icons.configure_icon_rect(result_panel_icon, Vector2(30.0, 30.0))
	if not result_continue_button.pressed.is_connected(_continue_to_dock):
		result_continue_button.pressed.connect(_continue_to_dock)
	dimmer.color = Color(0.02, 0.04, 0.05, 0.72)
	result_panel.custom_minimum_size = Vector2(560.0, 0.0)
	ExpeditionHudSkin.apply_plate(result_panel, ExpeditionHudSkin.BRASS_YELLOW, ExpeditionHudSkin.HANGAR_PANEL_SOFT, "manifest")
	ExpeditionHudSkin.apply_heading(result_title_label, HUD_TEXT_PRIMARY)
	ExpeditionHudSkin.apply_body(result_body_label, HUD_TEXT_PRIMARY)
	ExpeditionHudSkin.apply_muted(hint_label)
	hint_label.text = "Press Enter to bank the manifest and head back to the yard."
	ExpeditionHudSkin.apply_button(result_continue_button, ExpeditionHudSkin.SEA_GLASS_GREEN, ExpeditionHudSkin.RUST_BROWN)
	result_continue_button.text = "Return To Yard"
	result_layer.visible = false

func _get_run_toolbelt_entries() -> Array:
	return NetworkRuntime.get_toolbelt_entries(NetworkRuntime.SESSION_PHASE_RUN)

func _get_run_hotbar_entries() -> Array:
	return [
		{
			"label": "GRAPPLE",
			"icon": "salvage",
			"tool_id": "grapple",
			"type": "item",
			"hint": "Crane tool for salvage work.",
		},
		{
			"label": "HAMMER",
			"icon": "hammer",
			"tool_id": "repair",
			"type": "item",
			"hint": "Patch nearby hull sections.",
		},
		{
			"label": "",
			"icon": "",
			"tool_id": "",
			"type": "empty",
			"hint": "",
		},
	]

func _get_selected_run_tool_id() -> String:
	var entries := _get_run_hotbar_entries()
	if selected_run_tool_index < 0 or selected_run_tool_index >= entries.size():
		return ""
	var entry: Dictionary = entries[selected_run_tool_index]
	if str(entry.get("type", "")) != "item":
		return ""
	return str(entry.get("tool_id", ""))

func _select_run_tool(slot_index: int) -> void:
	var entries := _get_run_hotbar_entries()
	if slot_index < 0 or slot_index >= entries.size():
		return
	var entry: Dictionary = entries[slot_index]
	selected_run_tool_index = slot_index if str(entry.get("type", "")) == "item" else -1
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
	elif active_tool_id == "drive":
		selected_station_index = maxi(0, NetworkRuntime.get_claimable_station_ids().find("drive"))
	elif active_tool_id == "grapple":
		selected_station_index = maxi(0, NetworkRuntime.get_claimable_station_ids().find("grapple"))

func _build_run_toolbelt_text(active_tool_id: String = "", local_station_id: String = "") -> String:
	var base_text := "4-slot item belt. LMB uses item. F works stations. Space jumps/climbs. B braces."
	if active_tool_id.is_empty():
		return base_text
	return "%s Item ready: %s." % [base_text, _get_run_tool_label(active_tool_id)]

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
	var haul_lines := PackedStringArray()
	for entry_variant in Array(snapshot.get("item_manifest", [])):
		var entry: Dictionary = entry_variant
		haul_lines.append("- %s x%d" % [
			str(entry.get("label", "Material")),
			int(entry.get("quantity", 0)),
		])
	for entry_variant in Array(snapshot.get("schematic_manifest", [])):
		var entry: Dictionary = entry_variant
		haul_lines.append("- %s" % str(entry.get("label", "Schematic")))
	if haul_lines.is_empty():
		haul_lines.append("- No material haul secured yet.")
	var bonus_lines := PackedStringArray()
	for entry_variant in Array(snapshot.get("bonus_manifest", [])):
		var entry: Dictionary = entry_variant
		bonus_lines.append("- %s: %s" % [
			str(entry.get("label", "Bonus")),
			str(entry.get("detail", "")),
		])
	if bonus_lines.is_empty():
		bonus_lines.append("- No support bonuses secured yet.")
	return "On You\n%s\nCargo Hold %d/%d | Patch Kits %d/%d\nAboard\n%s\nMaterial Haul\n%s\nSupport\n%s\nCargo Lost To Sea %d | Bonus Gold %d" % [
		"\n".join(tool_lines),
		int(snapshot.get("cargo_count", 0)),
		int(snapshot.get("cargo_capacity", 0)),
		int(snapshot.get("patch_kits", 0)),
		int(snapshot.get("patch_kits_max", 0)),
		"\n".join(manifest_lines),
		"\n".join(haul_lines),
		"\n".join(bonus_lines),
		int(snapshot.get("cargo_lost_to_sea", 0)),
		int(snapshot.get("bonus_gold_bank", 0)),
	]

func _get_run_tool_label(tool_id: String) -> String:
	for slot_variant in _get_run_hotbar_entries():
		var slot: Dictionary = slot_variant
		if str(slot.get("tool_id", "")) == tool_id:
			return str(slot.get("label", tool_id.capitalize())).capitalize()
	for tool_variant in _get_run_toolbelt_entries():
		var tool: Dictionary = tool_variant
		if str(tool.get("id", "")) == tool_id:
			return str(tool.get("label", tool_id.capitalize()))
	return tool_id.capitalize()

func _get_run_tool_accent(tool_id: String) -> Color:
	match tool_id:
		"helm":
			return HUD_BORDER_BLUE
		"drive":
			return ExpeditionHudSkin.BRASS_YELLOW
		"brace":
			return HUD_TEXT_WARNING
		"grapple":
			return HUD_BORDER_ORANGE
		"repair":
			return ExpeditionHudSkin.SEA_GLASS_GREEN
		"recover":
			return ExpeditionHudSkin.OXIDIZED_TEAL
		_:
			return HUD_TEXT_MUTED

func _refresh_hotbar_slots(local_station_id: String) -> void:
	var entries := _get_run_hotbar_entries()
	for slot_index in range(hotbar_slot_panels.size()):
		var slot_panel := hotbar_slot_panels[slot_index] as PanelContainer
		var key_label := hotbar_slot_key_labels[slot_index] as Label
		var name_label := hotbar_slot_name_labels[slot_index] as Label
		var slot_icon := hotbar_slot_icons[slot_index] as TextureRect
		var has_entry := slot_index < entries.size()
		if slot_panel != null:
			slot_panel.visible = has_entry
		if not has_entry:
			continue
		var entry: Dictionary = entries[slot_index]
		var tool_id := str(entry.get("tool_id", ""))
		var slot_type := str(entry.get("type", "empty"))
		var accent_color := _get_run_tool_accent(tool_id)
		if slot_type == "empty":
			accent_color = HUD_TEXT_MUTED
		var is_active := slot_index == selected_run_tool_index and slot_type == "item"
		var is_occupied := slot_type == "item" and not local_station_id.is_empty() and local_station_id == tool_id
		ExpeditionHudSkin.apply_hotbar_slot(slot_panel, accent_color, is_active, is_occupied)
		if key_label != null:
			key_label.text = str(slot_index + 1)
			key_label.modulate = HUD_TEXT_PRIMARY if is_active else HUD_TEXT_MUTED
		if name_label != null:
			name_label.text = str(entry.get("label", ""))
			name_label.modulate = HUD_TEXT_PRIMARY if is_active or is_occupied else HUD_TEXT_MUTED
		if slot_icon != null:
			var icon_id := str(entry.get("icon", ""))
			if icon_id.is_empty():
				slot_icon.texture = null
				slot_icon.visible = false
				continue
			hud_icons.set_icon(slot_icon, icon_id)
			var icon_color := HUD_TEXT_MUTED
			if is_active:
				icon_color = accent_color.lightened(0.12)
			elif is_occupied:
				icon_color = accent_color
			slot_icon.modulate = icon_color

func _get_compass_cardinal(heading_degrees: float) -> String:
	var wrapped := fposmod(heading_degrees, 360.0)
	if wrapped < 22.5 or wrapped >= 337.5:
		return "N"
	if wrapped < 67.5:
		return "NE"
	if wrapped < 112.5:
		return "E"
	if wrapped < 157.5:
		return "SE"
	if wrapped < 202.5:
		return "S"
	if wrapped < 247.5:
		return "SW"
	if wrapped < 292.5:
		return "W"
	return "NW"

func _build_stage_clock_snapshot(phase: String, pressure_phase: String, elapsed_seconds: float) -> Dictionary:
	if phase == "success":
		return {
			"stage": "DONE",
			"title": "Extraction Secured",
			"progress": 100.0,
			"color": HUD_TEXT_SUCCESS,
		}
	if phase == "failed":
		return {
			"stage": "C",
			"title": "Failure Threshold",
			"progress": 100.0,
			"color": HUD_TEXT_DANGER,
		}
	match pressure_phase:
		NetworkRuntime.RUN_PRESSURE_PHASE_COLLAPSE:
			return {"stage": "C", "title": "Collapse Window", "progress": 98.0, "color": HUD_TEXT_DANGER}
		NetworkRuntime.RUN_PRESSURE_PHASE_CASCADE:
			return {"stage": "C", "title": "Cascade Window", "progress": 88.0, "color": HUD_TEXT_DANGER}
		NetworkRuntime.RUN_PRESSURE_PHASE_CRITICAL:
			return {"stage": "B", "title": "Night Surge", "progress": 74.0, "color": HUD_TEXT_WARNING}
		NetworkRuntime.RUN_PRESSURE_PHASE_STRAINED:
			return {"stage": "B", "title": "Pressure Rising", "progress": 56.0, "color": HUD_TEXT_WARNING}
		_:
			return {
				"stage": "A",
				"title": "Dawn Push %.0fs" % elapsed_seconds,
				"progress": 18.0,
				"color": HUD_TEXT_PRIMARY,
			}

func _build_goal_chain_text(local_overboard: bool, local_downed: bool, cargo_count: int, cargo_capacity: int, rescue_available: bool) -> String:
	if local_downed:
		return "Recover -> Rally"
	if local_overboard:
		return "Swim -> Jump / Climb -> Deck"
	if cargo_capacity > 0 and cargo_count >= cargo_capacity:
		return "Loaded -> Outpost -> Extract"
	if rescue_available:
		return "Salvage -> Rescue -> Outpost"
	return "Salvage -> Outpost"

func _build_station_prompt_compact(selected_station_id: String, local_station_id: String, local_overboard: bool, local_downed: bool) -> String:
	if local_downed:
		return "DOWNED | Hold still and wait for a rally."
	if local_overboard:
		var climb_surface := _get_local_climb_surface_candidate()
		if not climb_surface.is_empty():
			if str(climb_surface.get("type", "")) == "ladder":
				return "SWIM | Space climb ladder"
			return "SWIM | Space climb"
		return "SWIM | Space jump"
	if not local_station_id.is_empty():
		return "%s HELD | %s" % [
			NetworkRuntime.get_station_label(local_station_id),
			NetworkRuntime.get_station_prompt(local_station_id),
		]
	if selected_station_id.is_empty():
		return "Q / E select role. F to claim."
	if _is_local_near_station(selected_station_id):
		return "F to claim %s." % NetworkRuntime.get_station_label(selected_station_id)
	return "Move closer to %s." % NetworkRuntime.get_station_label(selected_station_id)

func _refresh_world() -> void:
	_refresh_chunk_visuals()
	_refresh_horizon_storm_wall()
	_refresh_runtime_block_visuals()
	_refresh_sinking_chunk_visuals()
	_refresh_local_run_avatar_controller()
	_refresh_station_visuals()
	_refresh_recovery_visuals()
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
	var local_avatar_state := _get_local_run_avatar_state()
	var local_mode := str(local_avatar_state.get("mode", NetworkRuntime.RUN_AVATAR_MODE_DECK))
	var local_overboard := local_mode == NetworkRuntime.RUN_AVATAR_MODE_SWIM or local_mode == NetworkRuntime.RUN_AVATAR_MODE_CLIMB or local_water_entry_active
	var local_downed := local_mode == NetworkRuntime.RUN_AVATAR_MODE_DOWNED
	var local_station_id := NetworkRuntime.get_peer_station_id(local_peer_id)
	var selected_station_id := _get_selected_station_id()
	var active_tool_id := _get_selected_run_tool_id()
	var local_health := float(local_avatar_state.get("health", NetworkRuntime.AVATAR_MAX_HEALTH))
	var local_max_health := maxf(1.0, float(local_avatar_state.get("max_health", NetworkRuntime.AVATAR_MAX_HEALTH)))
	var local_stamina := float(local_avatar_state.get("stamina", NetworkRuntime.AVATAR_MAX_STAMINA))
	var local_max_stamina := maxf(1.0, float(local_avatar_state.get("max_stamina", NetworkRuntime.AVATAR_MAX_STAMINA)))
	var local_stamina_exhausted := bool(local_avatar_state.get("stamina_exhausted", false))
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var nearest_salvage := _get_nearest_poi_site(RunWorldGenerator.SITE_SALVAGE, true)
	var nearest_rescue := _get_nearest_poi_site(RunWorldGenerator.SITE_DISTRESS, true)
	var nearest_cache := _get_nearest_poi_site(RunWorldGenerator.SITE_RESUPPLY, true)
	var nearest_extraction := _get_nearest_extraction_site(true)
	var hull_integrity: float = float(NetworkRuntime.boat_state.get("hull_integrity", 100.0))
	var max_hull_integrity: float = float(NetworkRuntime.boat_state.get("max_hull_integrity", 100.0))
	var breach_stacks := int(NetworkRuntime.boat_state.get("breach_stacks", 0))
	var extraction_distance := boat_position.distance_to(nearest_extraction.get("position", boat_position)) if not nearest_extraction.is_empty() else INF
	var wreck_distance := boat_position.distance_to(nearest_salvage.get("position", boat_position)) if not nearest_salvage.is_empty() else INF
	var rescue_distance := boat_position.distance_to(nearest_rescue.get("position", boat_position)) if not nearest_rescue.is_empty() else INF
	var cache_distance := boat_position.distance_to(nearest_cache.get("position", boat_position)) if not nearest_cache.is_empty() else INF
	var repair_supplies := int(NetworkRuntime.run_state.get("repair_supplies", 0))
	var repair_supplies_max := int(NetworkRuntime.run_state.get("repair_supplies_max", 0))
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
	var pressure_phase := str(NetworkRuntime.run_state.get("pressure_phase", NetworkRuntime.RUN_PRESSURE_PHASE_CALM))
	var pressure_label := str(NetworkRuntime.run_state.get("pressure_label", "Calm seas"))
	var current_cargo := int(NetworkRuntime.run_state.get("cargo_count", 0))
	var cargo_capacity := int(NetworkRuntime.run_state.get("cargo_capacity", int(NetworkRuntime.boat_state.get("cargo_capacity", 1))))
	var elapsed_seconds := float(NetworkRuntime.run_state.get("elapsed_time", 0.0))
	var revealed_extractions := _get_revealed_extraction_sites()
	var compass_heading_degrees := fposmod(rad_to_deg(boat_root.rotation.y), 360.0)
	var compass_cardinal := _get_compass_cardinal(compass_heading_degrees)

	var brace_timer := float(NetworkRuntime.boat_state.get("brace_timer", 0.0))
	var brace_cooldown := float(NetworkRuntime.boat_state.get("brace_cooldown", 0.0))
	var brace_state := "Ready"
	if brace_timer > 0.0:
		brace_state = "Holding %.1fs" % brace_timer
	elif brace_cooldown > 0.0:
		brace_state = "Recharging %.1fs" % brace_cooldown

	var objective_text := _build_objective_text().trim_prefix("Objective: ").strip_edges()
	var stage_snapshot := _build_stage_clock_snapshot(phase, pressure_phase, elapsed_seconds)
	var stage_color: Color = stage_snapshot.get("color", HUD_TEXT_PRIMARY)
	if clock_label != null:
		clock_label.text = "Stage %s | %s" % [
			str(stage_snapshot.get("stage", "A")),
			str(stage_snapshot.get("title", "Dawn Push")),
		]
		clock_label.modulate = stage_color
	if pressure_clock_label != null:
		pressure_clock_label.text = pressure_label
	if stage_clock_progress_bar != null:
		stage_clock_progress_bar.value = float(stage_snapshot.get("progress", 0.0))
		_apply_meter_bar_style(stage_clock_progress_bar, stage_color)
	if stage_clock_icon != null:
		if phase == "success":
			hud_icons.set_icon(stage_clock_icon, "extraction")
		elif phase == "failed":
			hud_icons.set_icon(stage_clock_icon, "brace")
		elif pressure_phase == NetworkRuntime.RUN_PRESSURE_PHASE_CALM:
			hud_icons.set_icon(stage_clock_icon, "helm")
		else:
			hud_icons.set_icon(stage_clock_icon, "brace")

	hud_icons.set_icon(objective_icon, _get_run_objective_icon_id(phase, local_station_id, selected_station_id, current_cargo, cargo_capacity))
	if objective_label != null:
		objective_label.text = objective_text
		if phase == "success":
			objective_label.modulate = HUD_TEXT_SUCCESS
		elif phase == "failed":
			objective_label.modulate = HUD_TEXT_DANGER
		else:
			objective_label.modulate = HUD_TEXT_PRIMARY

	var goal_name := "Search Sector"
	var goal_distance := INF
	if local_overboard:
		goal_name = "Boat"
		var climb_target := _get_local_climb_surface_candidate()
		if not climb_target.is_empty():
			var target_position: Vector3 = climb_target.get("attach_world_position", boat_position)
			goal_name = "Ladder" if str(climb_target.get("type", "")) == "ladder" else "Climb Point"
			goal_distance = local_run_avatar_world_position.distance_to(target_position)
	elif cargo_capacity > 0 and current_cargo >= cargo_capacity and not nearest_extraction.is_empty():
		goal_name = str(nearest_extraction.get("label", "Extraction Outpost"))
		goal_distance = extraction_distance
	elif not nearest_salvage.is_empty():
		goal_name = str(nearest_salvage.get("label", "Salvage Ring"))
		goal_distance = wreck_distance
	elif rescue_available and not nearest_rescue.is_empty():
		goal_name = str(nearest_rescue.get("label", "Distress Site"))
		goal_distance = rescue_distance
	elif bool(NetworkRuntime.run_state.get("cache_available", false)) and not nearest_cache.is_empty():
		goal_name = str(nearest_cache.get("label", "Resupply Cache"))
		goal_distance = cache_distance
	elif not nearest_extraction.is_empty():
		goal_name = str(nearest_extraction.get("label", "Extraction Outpost"))
		goal_distance = extraction_distance
	var goal_chain := _build_goal_chain_text(local_overboard, local_downed, current_cargo, cargo_capacity, rescue_available)
	if compass_label != null:
		var goal_distance_text := "--"
		if goal_distance < INF:
			goal_distance_text = "%.0fm" % goal_distance
		compass_label.text = "%s %03d | %s | %s %s" % [
			compass_cardinal,
			int(round(compass_heading_degrees)),
			goal_chain,
			goal_name,
			goal_distance_text,
		]

	var health_meter_color := HUD_TEXT_SUCCESS
	if local_downed or local_health <= NetworkRuntime.AVATAR_CRITICAL_THRESHOLD:
		health_meter_color = HUD_TEXT_DANGER
	elif local_health <= NetworkRuntime.AVATAR_WOUNDED_THRESHOLD:
		health_meter_color = HUD_TEXT_WARNING
	var stamina_meter_color := HUD_TEXT_WARNING if local_stamina_exhausted else HUD_TEXT_SUCCESS
	if local_stamina <= 0.0:
		stamina_meter_color = HUD_TEXT_DANGER
	elif local_stamina <= 25.0:
		stamina_meter_color = HUD_TEXT_WARNING
	if health_meter_label != null:
		health_meter_label.text = "CREW HP %d" % int(round(local_health))
		health_meter_label.modulate = health_meter_color
	if stamina_meter_label != null:
		stamina_meter_label.text = "STAMINA %d" % int(round(local_stamina))
		stamina_meter_label.modulate = stamina_meter_color
	if health_meter_bar != null:
		health_meter_bar.max_value = local_max_health
		health_meter_bar.value = local_health
		_apply_meter_bar_style(health_meter_bar, health_meter_color)
	if stamina_meter_bar != null:
		stamina_meter_bar.max_value = local_max_stamina
		stamina_meter_bar.value = local_stamina
		_apply_meter_bar_style(stamina_meter_bar, stamina_meter_color)

	_refresh_hotbar_slots(local_station_id)
	if toolbelt_label != null:
		toolbelt_label.text = _build_run_toolbelt_text(active_tool_id, local_station_id)
	if station_label != null:
		station_label.text = _build_station_prompt_compact(selected_station_id, local_station_id, local_overboard, local_downed)

	var local_hint := _build_onboarding_text(selected_station_id, local_station_id).trim_prefix("Onboarding: ").strip_edges()
	var propulsion_family := str(NetworkRuntime.boat_state.get("propulsion_family", NetworkRuntime.PROPULSION_FAMILY_RAFT_PADDLES))
	var propulsion_label := str(NetworkRuntime.boat_state.get("propulsion_label", NetworkRuntime.get_propulsion_family_label(propulsion_family)))
	var hull_ratio := hull_integrity / maxf(1.0, max_hull_integrity)
	var inspect_requested := Input.is_key_pressed(KEY_ALT) or Input.is_key_pressed(KEY_TAB)
	var inspect_forced := phase != "running" or hull_ratio <= 0.56 or breach_stacks > 0 or cargo_lost_to_sea > 0 or local_overboard or local_downed
	var inspect_visible := inspect_requested or inspect_forced
	if boat_inspect_panel != null:
		boat_inspect_panel.visible = inspect_visible

	if inspect_panel_icon != null:
		hud_icons.set_icon(inspect_panel_icon, "brace" if hull_ratio <= 0.56 or breach_stacks > 0 else "repair-kit")

	if boat_label != null:
		boat_label.text = "Hull %.0f/%.0f | Breaches %d | Brace %s\n%s | Speed %.1f | Cargo %d/%d | Kits %d/%d" % [
			hull_integrity,
			max_hull_integrity,
			breach_stacks,
			brace_state,
			propulsion_label,
			float(NetworkRuntime.boat_state.get("speed", 0.0)),
			current_cargo,
			cargo_capacity,
			repair_supplies,
			repair_supplies_max,
		]
		boat_label.modulate = HUD_TEXT_DANGER if hull_ratio <= 0.35 else HUD_TEXT_WARNING if hull_ratio <= 0.6 else HUD_TEXT_PRIMARY

	var storage_lines := PackedStringArray()
	storage_lines.append("Storage %d/%d | Outposts %d | Bonus Gold %d" % [
		current_cargo,
		cargo_capacity,
		revealed_extractions.size(),
		int(NetworkRuntime.run_state.get("bonus_gold_bank", 0)),
	])
	if not nearest_extraction.is_empty():
		storage_lines.append("Nearest outpost %.1fm" % extraction_distance)
	if rescue_available and not nearest_rescue.is_empty():
		storage_lines.append("Rescue window %.1f/%.1fs at %.1fm" % [rescue_progress, rescue_duration, rescue_distance])
	elif rescue_completed:
		storage_lines.append("Rescue secured")
	if bool(NetworkRuntime.run_state.get("cache_available", false)) and not nearest_cache.is_empty():
		storage_lines.append("Cache spotted %.1fm" % cache_distance)
	if cargo_lost_to_sea > 0:
		storage_lines.append("Cargo lost to sea %d" % cargo_lost_to_sea)
	if resource_label != null:
		resource_label.text = "\n".join(storage_lines)

	var risk_lines := PackedStringArray()
	risk_lines.append("%s | %s | Squalls %d" % [
		pressure_label,
		"Inside storm band" if _boat_inside_any_squall() else "Open water lane",
		squall_bands.size(),
	])
	if not nearest_salvage.is_empty():
		risk_lines.append("Nearest salvage %.1fm" % wreck_distance)
	if detached_chunk_count > 0:
		risk_lines.append("Detached chunks %d" % detached_chunk_count)
	if overboard_count > 0:
		risk_lines.append("Crew overboard %d | Recoveries %d" % [overboard_count, recoveries_completed])
	if run_label != null:
		run_label.text = "\n".join(risk_lines)

	if interaction_label != null:
		var debug_hint := " F3 debug %s." % ("on" if debug_overlay_enabled else "off")
		interaction_label.text = "Inspect: hold Alt (or Tab). %s%s" % [local_hint, debug_hint]
	if status_label != null:
		var item_label := "None"
		if not active_tool_id.is_empty():
			item_label = _get_run_tool_label(active_tool_id)
		status_label.text = "%s | Heading %s %03d | Item %s\nQ/E stations | F claim/use | Space jump/climb | B brace | I inventory | F3 debug" % [
			phase.capitalize(),
			compass_cardinal,
			int(round(compass_heading_degrees)),
			item_label,
		]
		status_label.modulate = HUD_TEXT_MUTED

	if not inspect_visible and phase == "running":
		if boat_label != null:
			boat_label.text = ""
		if resource_label != null:
			resource_label.text = ""
		if run_label != null:
			run_label.text = ""
		if interaction_label != null:
			interaction_label.text = ""
		if status_label != null:
			status_label.text = ""

	if inventory_label != null:
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
	elif local_station_id == "drive":
		var propulsion_family := str(NetworkRuntime.boat_state.get("propulsion_family", NetworkRuntime.PROPULSION_FAMILY_RAFT_PADDLES))
		if propulsion_family == NetworkRuntime.PROPULSION_FAMILY_SAIL_RIG:
			lines.append("Press G to trim the sail for the wind and R to reef before bad angles or squalls rob the hull of speed.")
		elif propulsion_family == NetworkRuntime.PROPULSION_FAMILY_STEAM_TUG:
			lines.append("Press G to stoke pressure and R to vent the boiler before the drive starts laboring.")
		elif propulsion_family == NetworkRuntime.PROPULSION_FAMILY_TWIN_ENGINE:
			lines.append("Press G to tune the engines and R to cool them before heat robs the boat of response.")
		else:
			lines.append("Press G to dig the paddles in for burst speed and R to backwater when the helm needs control.")
	elif local_station_id == "grapple":
		lines.append("Use your equipped grapple item here to recover nearby wreck salvage, rescue cargo, or bonus caches once the helm has slowed the boat.")
	else:
		lines.append("Brace anywhere with B, or use your equipped hammer item near damaged hull sections.")

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
		BoatBlockMaterials.apply_wood(body_material, block_color, 0.45)

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
	mesh.size = Vector3.ONE * NetworkRuntime.RUNTIME_BLOCK_SPACING
	mesh_instance.mesh = mesh
	block_node.add_child(mesh_instance)

	if not detached_visual:
		var collision_body := AnimatableBody3D.new()
		collision_body.name = "CollisionBody"
		collision_body.collision_layer = RUN_BLOCK_COLLISION_LAYER
		collision_body.collision_mask = RUN_BLOCK_COLLISION_LAYER
		var collision_shape := CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		var box_shape := BoxShape3D.new()
		box_shape.size = Vector3.ONE * NetworkRuntime.RUNTIME_BLOCK_SPACING
		collision_shape.shape = box_shape
		collision_body.add_child(collision_shape)
		_ensure_acoustic_body(collision_body, WOOD_ACOUSTIC_MATERIAL)
		block_node.add_child(collision_body)
	var facing_marker := MeshInstance3D.new()
	facing_marker.name = "Marker"
	var marker_mesh := BoxMesh.new()
	marker_mesh.size = Vector3(0.22, 0.14, 0.26) * NetworkRuntime.RUNTIME_BLOCK_SPACING
	facing_marker.mesh = marker_mesh
	facing_marker.position = Vector3(0.0, 0.0, -0.36 * NetworkRuntime.RUNTIME_BLOCK_SPACING)
	block_node.add_child(facing_marker)
	_apply_runtime_block_visual_style(
		block_node,
		block_def,
		float(block.get("current_hp", float(block.get("max_hp", 1.0)))),
		float(block.get("max_hp", 1.0)),
		detached_visual
	)

	return block_node

func _set_runtime_block_collision_enabled(block_node: Node3D, enabled: bool) -> void:
	if block_node == null:
		return
	var collision_body := block_node.get_node_or_null("CollisionBody") as CollisionObject3D
	if collision_body == null:
		return
	collision_body.collision_layer = RUN_BLOCK_COLLISION_LAYER if enabled else 0
	collision_body.collision_mask = RUN_BLOCK_COLLISION_LAYER if enabled else 0
	var collision_shape := collision_body.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision_shape != null:
		collision_shape.disabled = not enabled

func _update_runtime_block_visuals() -> void:
	var runtime_blocks: Array = Array(NetworkRuntime.boat_state.get("runtime_blocks", []))
	_update_placeholder_boat_visibility(runtime_blocks.is_empty())
	var seen_block_ids := {}
	for block_variant in runtime_blocks:
		var block_state: Dictionary = block_variant
		var block := _build_runtime_block_render_data(block_state)
		if block.is_empty():
			continue
		var block_id := int(block.get("id", 0))
		seen_block_ids[block_id] = true
		var block_node := main_block_visuals.get(block_id) as Node3D
		if bool(block.get("destroyed", false)) or bool(block.get("detached", false)):
			if block_node != null:
				block_node.visible = false
				_set_runtime_block_collision_enabled(block_node, false)
			continue
		if block_node == null:
			_refresh_runtime_block_visuals()
			return
		var block_local_position: Vector3 = block.get("local_position", Vector3.ZERO)
		block_node.position = block_local_position
		block_node.rotation_degrees.y = float(int(block.get("rotation_steps", 0)) * 90)
		block_node.visible = true
		_set_runtime_block_collision_enabled(block_node, true)
		_apply_runtime_block_visual_style(
			block_node,
			NetworkRuntime.get_builder_block_definition(str(block.get("type", "structure"))),
			float(block.get("current_hp", float(block.get("max_hp", 1.0)))),
			float(block.get("max_hp", 1.0)),
			false
		)
	for block_id_variant in main_block_visuals.keys():
		if seen_block_ids.has(int(block_id_variant)):
			continue
		_refresh_runtime_block_visuals()
		return

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
	var local_station_id := NetworkRuntime.get_peer_station_id(local_peer_id)
	var local_overboard := _is_local_off_deck()
	var local_downed := _is_local_downed()

	for station_id in NetworkRuntime.get_station_ids():
		var station_visual: Dictionary = station_visuals.get(station_id, {})
		var station_root := station_visual.get("root") as Node3D
		if station_root == null:
			continue

		var station_data: Dictionary = NetworkRuntime.station_state.get(station_id, {})
		var occupant_peer_id := int(station_data.get("occupant_peer_id", 0))
		var claimable := _get_claimable_station_ids().has(station_id)
		var color := STATION_BASE_COLOR if claimable else Color(0.36, 0.56, 0.62)
		if not bool(station_data.get("active", true)):
			color = color.lerp(Color(0.20, 0.20, 0.24), 0.55)
		if claimable:
			if occupant_peer_id == local_peer_id and occupant_peer_id != 0:
				color = STATION_LOCAL_COLOR
			elif occupant_peer_id != 0:
				color = STATION_OCCUPIED_COLOR
			if station_id == selected_station_id:
				color = color.lerp(STATION_SELECTED_COLOR, 0.45)
		else:
			color = color.lerp(STATION_SELECTED_COLOR, 0.18)

		var occupant_name := NetworkRuntime.get_station_occupant_name(station_id)
		var label_text := ""
		if claimable:
			label_text = NetworkRuntime.get_station_label(station_id)
			if occupant_peer_id != 0:
				label_text += "\n%s" % occupant_name
		else:
			label_text = NetworkRuntime.get_station_label(station_id)
			var burst_action := str(station_data.get("burst_action", ""))
			if not burst_action.is_empty():
				label_text += "\n%s" % burst_action.capitalize()
		if not bool(station_data.get("active", true)):
			label_text += "\nOffline"
		var show_label: bool = station_id == selected_station_id or occupant_peer_id == local_peer_id
		if not local_overboard and not local_downed and _is_local_near_station(station_id, 0.9):
			show_label = true
		if not local_station_id.is_empty() and local_station_id == station_id:
			show_label = true
		if local_overboard or local_downed:
			show_label = show_label and station_id == selected_station_id
		if station_root.has_method("set_marker_color"):
			station_root.call("set_marker_color", color)
		if station_root.has_method("set_marker_text"):
			station_root.call("set_marker_text", label_text)
		if station_root.has_method("set_label_visible"):
			station_root.call("set_label_visible", show_label and not label_text.is_empty())

func _refresh_recovery_visuals() -> void:
	if recovery_visuals.is_empty():
		return
	var local_overboard := _is_local_swimming() or _is_local_climbing() or _is_local_water_entry()
	var local_world_position := _get_local_avatar_world_position()
	for target_variant in NetworkRuntime.get_run_ladder_points():
		var target: Dictionary = target_variant
		var target_id := str(target.get("id", ""))
		var recovery_visual: Dictionary = recovery_visuals.get(target_id, {})
		var recovery_root := recovery_visual.get("root") as Node3D
		if recovery_root == null:
			continue
		var water_position: Vector3 = target.get("water_position", Vector3.ZERO)
		var world_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO) + water_position.rotated(Vector3.UP, float(NetworkRuntime.boat_state.get("rotation_y", 0.0)))
		world_position.y = NetworkRuntime.RUN_OVERBOARD_WATER_HEIGHT
		var is_active_target := local_overboard and local_world_position.distance_to(world_position) <= 2.25
		var near_marker: bool = local_world_position.distance_to(world_position) <= 2.6
		var show_label: bool = local_overboard or near_marker or is_active_target
		if recovery_root.has_method("set_marker_color"):
			var recovery_color := Color(0.20, 0.70, 0.74)
			if is_active_target:
				recovery_color = HUD_TEXT_SUCCESS
			recovery_root.call("set_marker_color", recovery_color)
		if recovery_root.has_method("set_label_visible"):
			recovery_root.call("set_label_visible", show_label)

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
		if int(peer_id) == _get_local_peer_id():
			continue
		var peer_data: Dictionary = NetworkRuntime.peer_snapshot[peer_id]
		var crew_member := RUN_PLAYER_CONTROLLER_SCENE.instantiate() as CharacterBody3D
		if crew_member == null:
			continue
		crew_member.name = "RemoteAvatar%d" % int(peer_id)
		crew_member.collision_layer = 0
		crew_member.collision_mask = 0
		var collision_shape := crew_member.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if collision_shape != null:
			collision_shape.disabled = true
			var station_id := NetworkRuntime.get_peer_station_id(int(peer_id))
			var avatar_state: Dictionary = NetworkRuntime.get_run_avatar_state().get(int(peer_id), {})
			var avatar_mode := str(avatar_state.get("mode", NetworkRuntime.RUN_AVATAR_MODE_DECK))
			var overboard := avatar_mode == NetworkRuntime.RUN_AVATAR_MODE_SWIM or avatar_mode == NetworkRuntime.RUN_AVATAR_MODE_CLIMB
			var climbing := avatar_mode == NetworkRuntime.RUN_AVATAR_MODE_CLIMB
			var downed := avatar_mode == NetworkRuntime.RUN_AVATAR_MODE_DOWNED
			if overboard:
				crew_member.top_level = true
				crew_container.add_child(crew_member)
				crew_member.global_position = avatar_state.get("world_position", boat_root.global_position)
				crew_member.rotation.y = float(avatar_state.get("facing_y", PI))
				if climbing:
					crew_member.rotation.x = -0.04
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
			var presentation_state := avatar_state.duplicate(true)
			presentation_state["peer_id"] = int(peer_id)
			_configure_run_avatar_controller(crew_member, str(peer_data.get("name", "Crew")), station_id, presentation_state, overboard, downed)
			crew_visuals[int(peer_id)] = {
				"root": crew_member,
			}

func _refresh_hazard_visuals() -> void:
	for child in hazard_container.get_children():
		child.queue_free()
	hazard_visuals = {}
	var active_lookup := {}
	for coord_variant in _get_active_chunk_coords():
		active_lookup[_chunk_coord_key(coord_variant)] = true

	for hazard in NetworkRuntime.hazard_state:
		var hazard_data: Dictionary = hazard
		var chunk_key := _chunk_coord_key(hazard_data.get("chunk_coord", []))
		if not chunk_key.is_empty() and not active_lookup.has(chunk_key):
			continue
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
	var active_lookup := {}
	for coord_variant in _get_active_chunk_coords():
		active_lookup[_chunk_coord_key(coord_variant)] = true

	for loot_target in NetworkRuntime.loot_state:
		var loot_data: Dictionary = loot_target
		var chunk_key := _chunk_coord_key(loot_data.get("chunk_coord", []))
		if not chunk_key.is_empty() and not active_lookup.has(chunk_key):
			continue
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

func _spawn_site_marker(
	scene: PackedScene,
	container: Node3D,
	site: Dictionary,
	ring_color: Color,
	body_color: Color
) -> Dictionary:
	var root := scene.instantiate() as Node3D
	if root == null:
		root = Node3D.new()
	root.name = "%s_%s" % [str(site.get("site_type", "site")), str(site.get("id", "site"))]
	container.add_child(root)
	if root.has_method("set_ring_radius"):
		root.call("set_ring_radius", float(site.get("radius", 4.0)))
	if root.has_method("set_ring_color"):
		root.call("set_ring_color", ring_color)
	if root.has_method("set_body_color"):
		root.call("set_body_color", body_color)
	var foam := _ensure_contact_foam_plane(root, "ContactFoam", Vector2(1.0, 1.0))
	foam.position = Vector3(0.0, WATER_SURFACE_Y + 0.05, 0.0)
	var radius := float(site.get("radius", 4.0))
	foam.scale = Vector3(radius * 0.72, 1.0, radius * 0.72)
	var foam_material := foam.material_override as ShaderMaterial
	return {
		"root": root,
		"foam_material": foam_material,
	}

func _refresh_wreck_visual() -> void:
	if salvage_site_container == null:
		return
	for child in salvage_site_container.get_children():
		child.queue_free()
	salvage_site_visuals.clear()
	var active_lookup := {}
	for coord_variant in _get_active_chunk_coords():
		active_lookup[_chunk_coord_key(coord_variant)] = true
	for site_variant in _get_poi_sites(RunWorldGenerator.SITE_SALVAGE, false):
		var site: Dictionary = site_variant
		var chunk_key := _chunk_coord_key(site.get("coord", []))
		if not active_lookup.has(chunk_key):
			continue
		salvage_site_visuals[str(site.get("id", ""))] = _spawn_site_marker(
			SALVAGE_SITE_MARKER_SCENE,
			salvage_site_container,
			site,
			Color(0.23, 0.79, 0.57, 0.26),
			Color(0.45, 0.29, 0.18)
		)

func _refresh_rescue_visual() -> void:
	if distress_site_container == null:
		return
	for child in distress_site_container.get_children():
		child.queue_free()
	distress_site_visuals.clear()
	var active_lookup := {}
	for coord_variant in _get_active_chunk_coords():
		active_lookup[_chunk_coord_key(coord_variant)] = true
	for site_variant in _get_poi_sites(RunWorldGenerator.SITE_DISTRESS, false):
		var site: Dictionary = site_variant
		var chunk_key := _chunk_coord_key(site.get("coord", []))
		if not active_lookup.has(chunk_key):
			continue
		distress_site_visuals[str(site.get("id", ""))] = _spawn_site_marker(
			DISTRESS_SITE_MARKER_SCENE,
			distress_site_container,
			site,
			Color(0.93, 0.72, 0.28, 0.28),
			Color(0.86, 0.46, 0.18)
		)

func _refresh_squall_visuals() -> void:
	for child in squall_container.get_children():
		child.queue_free()
	squall_visuals.clear()
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var chunk_size := float(NetworkRuntime.run_state.get("chunk_size_m", RunWorldGenerator.CHUNK_SIZE_M))
	var stream_distance := chunk_size * float(int(NetworkRuntime.run_state.get("stream_radius_chunks", RunWorldGenerator.STREAM_RADIUS_CHUNKS)) + 1)

	for band_variant in Array(NetworkRuntime.run_state.get("squall_bands", [])):
		var band: Dictionary = band_variant
		if boat_position.distance_to(band.get("center", Vector3.ZERO)) > stream_distance * 1.25:
			continue
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
		shell_material.albedo_color = Color(0.12, 0.20, 0.27, 0.18)
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

		var streak_root := Node3D.new()
		streak_root.name = "StreakRoot"
		root.add_child(streak_root)
		var streak_materials: Array = []
		for streak_index in range(3):
			var streak := MeshInstance3D.new()
			streak.name = "Streak%d" % streak_index
			var streak_mesh := QuadMesh.new()
			streak_mesh.size = Vector2(maxf(half_extents.x, half_extents.z) * 1.35, 6.8)
			streak.mesh = streak_mesh
			streak.position = Vector3(0.0, 3.2, 0.0)
			streak.rotation.y = deg_to_rad(60.0 * float(streak_index))
			streak.rotation.x = deg_to_rad(-8.0)
			var streak_material := ShaderMaterial.new()
			streak_material.shader = SquallStreaksShader
			streak_material.set_shader_parameter("intensity", 0.36 + float(band.get("pulse_damage", 0.0)) * 0.05)
			streak_material.set_shader_parameter("density", 9.0 + float(streak_index) * 2.0)
			streak.material_override = streak_material
			streak_root.add_child(streak)
			streak_materials.append(streak_material)

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
			"streak_materials": streak_materials,
			"label": label,
		}

func _refresh_cache_visual() -> void:
	if resupply_site_container == null:
		return
	for child in resupply_site_container.get_children():
		child.queue_free()
	resupply_site_visuals.clear()
	var active_lookup := {}
	for coord_variant in _get_active_chunk_coords():
		active_lookup[_chunk_coord_key(coord_variant)] = true
	for site_variant in _get_poi_sites(RunWorldGenerator.SITE_RESUPPLY, false):
		var site: Dictionary = site_variant
		var chunk_key := _chunk_coord_key(site.get("coord", []))
		if not active_lookup.has(chunk_key):
			continue
		resupply_site_visuals[str(site.get("id", ""))] = _spawn_site_marker(
			RESUPPLY_SITE_MARKER_SCENE,
			resupply_site_container,
			site,
			Color(0.23, 0.71, 0.84, 0.24),
			Color(0.21, 0.54, 0.62)
		)

func _refresh_extraction_visual() -> void:
	if extraction_site_container == null:
		return
	for child in extraction_site_container.get_children():
		child.queue_free()
	extraction_site_visuals.clear()
	var active_lookup := {}
	for coord_variant in _get_active_chunk_coords():
		active_lookup[_chunk_coord_key(coord_variant)] = true
	for site_variant in _get_revealed_extraction_sites():
		var site: Dictionary = site_variant
		var chunk_key := _chunk_coord_key(site.get("coord", []))
		if not active_lookup.has(chunk_key):
			continue
		extraction_site_visuals[str(site.get("id", ""))] = _spawn_site_marker(
			EXTRACTION_OUTPOST_MARKER_SCENE,
			extraction_site_container,
			site,
			Color(0.30, 0.62, 0.86, 0.24),
			Color(0.72, 0.80, 0.88)
		)

func _refresh_result_overlay() -> void:
	var phase := str(NetworkRuntime.run_state.get("phase", "running"))
	result_layer.visible = phase != "running"
	if phase == "running":
		if result_panel != null:
			result_panel.modulate = Color.WHITE
		return

	hud_icons.set_icon(result_panel_icon, "extraction" if phase == "success" else "brace")
	var cargo_count := int(NetworkRuntime.run_state.get("cargo_count", 0))
	var cargo_secured := int(NetworkRuntime.run_state.get("cargo_secured", 0))
	var cargo_lost: int = maxi(0, cargo_count - cargo_secured)
	var reward_items := Dictionary(NetworkRuntime.run_state.get("reward_items", {}))
	var loot_lost_items := Dictionary(NetworkRuntime.run_state.get("loot_lost_items", {}))
	var repair_debt_delta := Dictionary(NetworkRuntime.run_state.get("repair_debt_delta", {}))
	result_title_label.text = str(NetworkRuntime.run_state.get("result_title", "Run Complete"))
	result_body_label.text = "%s\n\nSECURED\nCargo %d / %d | Gold %d | Mats %d | Schematics %d\nCache %s | Patch Kits Left %d\n\nINCIDENT REPORT\nCargo Lost %d | Lost Haul %d | Blocks Destroyed %d | Chunks Lost %d\nSea Loss %d | Repair Debt %d gold / %d mats\n\nNEXT DOCK STATE\nBlueprint v%d | Spend it in the yard and relaunch." % [
		str(NetworkRuntime.run_state.get("result_message", "")),
		cargo_secured,
		cargo_count,
		int(NetworkRuntime.run_state.get("reward_gold", 0)),
		NetworkRuntime._sum_material_dict_ui(reward_items),
		Array(NetworkRuntime.run_state.get("reward_schematics", [])).size(),
		"Recovered" if bool(NetworkRuntime.run_state.get("cache_recovered", false)) else "Missed",
		int(NetworkRuntime.run_state.get("repair_supplies", 0)),
		cargo_lost,
		NetworkRuntime._sum_material_dict_ui(loot_lost_items),
		int(NetworkRuntime.run_state.get("destroyed_block_count", 0)),
		int(NetworkRuntime.run_state.get("detached_chunk_count", 0)),
		int(NetworkRuntime.run_state.get("cargo_lost_to_sea", 0)),
		int(repair_debt_delta.get("gold", 0)),
		NetworkRuntime._sum_material_dict_ui(repair_debt_delta.get("items", {})),
		int(NetworkRuntime.run_state.get("blueprint_version", 1)),
	]
	_apply_hud_panel_style(
		result_panel,
		ExpeditionHudSkin.SEA_GLASS_GREEN if phase == "success" else ExpeditionHudSkin.FLARE_RED,
		ExpeditionHudSkin.HANGAR_PANEL_SOFT,
		"manifest"
	)
	ExpeditionHudSkin.apply_heading(result_title_label, HUD_TEXT_SUCCESS if phase == "success" else HUD_TEXT_WARNING)
	ExpeditionHudSkin.apply_button(
		result_continue_button,
		ExpeditionHudSkin.SEA_GLASS_GREEN if phase == "success" else ExpeditionHudSkin.BUOY_ORANGE,
		ExpeditionHudSkin.RUST_BROWN
	)
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
	last_hud_downed_count = int(NetworkRuntime.run_state.get("crew_downed_count", 0))
	last_hud_phase = str(NetworkRuntime.run_state.get("phase", "running"))
	last_local_overboard = _is_local_off_deck()
	last_local_downed = _is_local_downed()

func _push_event_callout(text: String, color: Color, duration: float = 1.9) -> void:
	if event_callout_label == null:
		return
	event_callout_timer = duration
	event_callout_color = color
	event_callout_label.text = text.to_upper()
	event_callout_label.modulate = color
	event_callout_label.scale = Vector2(1.06, 1.06)
	event_callout_label.visible = true

func _update_event_callout(delta: float) -> void:
	if event_callout_label == null:
		return
	if event_callout_timer <= 0.0:
		event_callout_label.visible = false
		event_callout_label.scale = Vector2.ONE
		return
	event_callout_timer = maxf(0.0, event_callout_timer - delta)
	var fade_ratio := clampf(event_callout_timer / 1.9, 0.0, 1.0)
	event_callout_label.visible = true
	event_callout_label.modulate = Color(event_callout_color.r, event_callout_color.g, event_callout_color.b, clampf(0.2 + fade_ratio, 0.0, 1.0))
	var pulse := 1.0 + 0.06 * fade_ratio
	event_callout_label.scale = Vector2(pulse, pulse)

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
	if str(local_reaction.get("type", "")) == "impact":
		_spawn_splash_burst(NetworkRuntime.boat_state.get("position", Vector3.ZERO), clampf(float(local_reaction.get("strength", 0.5)) * 1.1, 0.45, 1.2))

func _update_crew_visuals(delta: float) -> void:
	_update_local_run_avatar_controller(delta)
	var idle_slot_index := 0
	for peer_id in NetworkRuntime.get_player_peer_ids():
		if int(peer_id) == _get_local_peer_id():
			continue
		var visual: Dictionary = crew_visuals.get(int(peer_id), {})
		var crew_root := visual.get("root") as Node3D
		if crew_root == null:
			continue
		var station_id := NetworkRuntime.get_peer_station_id(int(peer_id))
		var avatar_state: Dictionary = NetworkRuntime.get_run_avatar_state().get(int(peer_id), {})
		var avatar_mode := str(avatar_state.get("mode", NetworkRuntime.RUN_AVATAR_MODE_DECK))
		var overboard := avatar_mode == NetworkRuntime.RUN_AVATAR_MODE_SWIM or avatar_mode == NetworkRuntime.RUN_AVATAR_MODE_CLIMB
		var climbing := avatar_mode == NetworkRuntime.RUN_AVATAR_MODE_CLIMB
		var downed := avatar_mode == NetworkRuntime.RUN_AVATAR_MODE_DOWNED
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
		if climbing:
			var climb_world_position: Vector3 = avatar_state.get("world_position", boat_root.global_position)
			crew_root.top_level = true
			crew_root.global_position = crew_root.global_position.lerp(climb_world_position, minf(1.0, delta * 9.0))
			crew_root.rotation.y = lerp_angle(crew_root.rotation.y, target_yaw, minf(1.0, delta * 10.0))
			crew_root.rotation.x = lerp_angle(crew_root.rotation.x, -0.04 + clampf(local_knockback.z * -0.02 * intensity, -0.12, 0.12), minf(1.0, delta * 10.0))
			crew_root.rotation.z = lerp_angle(crew_root.rotation.z, clampf(local_knockback.x * 0.02 * intensity, -0.10, 0.10), minf(1.0, delta * 10.0))
		elif overboard:
			var target_world_position: Vector3 = avatar_state.get("world_position", boat_root.global_position)
			target_world_position.y += sin(connect_time_seconds * 2.8 + float(peer_id)) * 0.05
			crew_root.global_position = crew_root.global_position.lerp(target_world_position, minf(1.0, delta * 8.0))
			crew_root.rotation.y = lerp_angle(crew_root.rotation.y, target_yaw, minf(1.0, delta * 10.0))
			crew_root.rotation.x = lerp_angle(crew_root.rotation.x, 0.12 + clampf(local_knockback.z * -0.03 * intensity, -0.18, 0.18), minf(1.0, delta * 10.0))
			crew_root.rotation.z = lerp_angle(crew_root.rotation.z, clampf(local_knockback.x * 0.04 * intensity, -0.18, 0.18), minf(1.0, delta * 10.0))
		else:
			crew_root.top_level = false
			if downed:
				target_position.y = maxf(0.34, target_position.y - 0.38)
			crew_root.scale.y = lerpf(crew_root.scale.y, 0.55 if downed else 1.0, minf(1.0, delta * 8.0))
			crew_root.position = crew_root.position.lerp(target_position, minf(1.0, delta * 8.5))
			crew_root.rotation.y = lerp_angle(crew_root.rotation.y, target_yaw, minf(1.0, delta * 10.0))
			crew_root.rotation.x = lerp_angle(crew_root.rotation.x, -0.42 if downed else clampf(local_knockback.z * -0.05 * intensity, -0.42, 0.42), minf(1.0, delta * 12.0))
			crew_root.rotation.z = lerp_angle(crew_root.rotation.z, 1.08 if downed else clampf(local_knockback.x * 0.055 * intensity, -0.48, 0.48), minf(1.0, delta * 12.0))
		crew_root.velocity = avatar_state.get("velocity", Vector3.ZERO)
		var reaction_label := str(peer_reaction.get("type", "")).capitalize() if not peer_reaction.is_empty() else ""
		var presentation_state := avatar_state.duplicate(true)
		presentation_state["peer_id"] = int(peer_id)
		_configure_run_avatar_controller(
			crew_root,
			str(NetworkRuntime.peer_snapshot.get(int(peer_id), {}).get("name", "Crew")),
			station_id,
			presentation_state,
			overboard,
			downed,
			reaction_label
		)

func _get_run_avatar_highlight_color(peer_id: int, station_id: String, overboard: bool, downed: bool) -> Color:
	if peer_id == _get_local_peer_id():
		return Color(0.30, 0.82, 0.52)
	if overboard:
		return Color(0.36, 0.74, 0.96)
	if downed:
		return Color(0.84, 0.34, 0.30)
	if station_id == "helm":
		return Color(0.94, 0.76, 0.18)
	return Color(0.70, 0.84, 0.93)

func _get_run_avatar_motion_blend(avatar_state: Dictionary, overboard: bool, downed: bool) -> float:
	if overboard or downed:
		return 0.0
	var velocity: Vector3 = avatar_state.get("velocity", Vector3.ZERO)
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if horizontal_speed < 0.18:
		return 0.0
	return clampf(horizontal_speed / RUN_AVATAR_MOVE_SPEED, 0.0, 1.0)

func _get_run_avatar_motion_state(avatar_state: Dictionary, overboard: bool, downed: bool) -> String:
	var motion_blend := _get_run_avatar_motion_blend(avatar_state, overboard, downed)
	if motion_blend >= 0.75:
		return "run"
	if motion_blend >= 0.08:
		return "walk"
	return "idle"

func _process_local_run_avatar_movement(delta: float) -> void:
	if _is_local_downed():
		local_run_avatar_velocity = Vector3.ZERO
		local_run_avatar_world_position = boat_root.to_global(local_run_avatar_position)
		local_run_avatar_grounded = true
		local_water_entry_active = false
		local_water_entry_elapsed = 0.0
		local_overboard_transition_pending = false
		local_off_deck_entry_elapsed = RUN_OFF_DECK_BLEND_DURATION
		local_surface_tread_active = false
		local_surface_tread_elapsed = 0.0
		_reset_local_run_transition_state(local_run_avatar_position, local_run_avatar_world_position)
		if local_run_avatar_controller != null and not _is_local_off_deck():
			local_run_avatar_controller.velocity = Vector3.ZERO
		return
	local_swim_jump_cooldown = maxf(0.0, local_swim_jump_cooldown - delta)
	if _is_local_water_entry():
		local_off_deck_entry_elapsed = minf(RUN_OFF_DECK_BLEND_DURATION, local_off_deck_entry_elapsed + delta)
		local_water_entry_elapsed += delta
		local_run_avatar_velocity.y -= RUN_WATER_ENTRY_GRAVITY * delta
		var surface_height := NetworkRuntime.RUN_OVERBOARD_WATER_HEIGHT
		var height_above_surface := maxf(0.0, local_run_avatar_world_position.y - surface_height)
		var surface_blend := clampf(1.0 - (height_above_surface / RUN_WATER_ENTRY_SURFACE_BLEND_HEIGHT), 0.0, 1.0)
		if surface_blend > 0.0:
			var drag_strength := surface_blend * delta * 4.8
			local_run_avatar_velocity.x = lerpf(local_run_avatar_velocity.x, 0.0, drag_strength)
			local_run_avatar_velocity.z = lerpf(local_run_avatar_velocity.z, 0.0, drag_strength)
			if local_run_avatar_velocity.y < -1.6:
				local_run_avatar_velocity.y = lerpf(local_run_avatar_velocity.y, -1.6, drag_strength)
		local_run_avatar_world_position += local_run_avatar_velocity * delta
		if local_run_avatar_controller != null:
			local_run_avatar_controller.top_level = true
			local_run_avatar_controller.global_position = local_run_avatar_world_position
			local_run_avatar_controller.velocity = local_run_avatar_velocity
		if _try_reacquire_local_deck_from_water_entry():
			return
		if local_run_avatar_world_position.y <= surface_height or local_water_entry_elapsed >= RUN_WATER_ENTRY_MAX_DURATION:
			var committed_velocity := local_run_avatar_velocity
			local_run_avatar_world_position.y = surface_height
			local_water_entry_active = false
			local_overboard_transition_pending = true
			_set_local_run_avatar_collision_enabled(false)
			local_run_avatar_velocity.y = 0.0
			_emit_local_surface_contact_feedback(local_run_avatar_world_position, 1.05)
			NetworkRuntime.request_local_swim_transition(
				local_run_avatar_world_position,
				committed_velocity,
				local_avatar_facing_y
			)
		return
	var local_station_id := NetworkRuntime.get_peer_station_id(_get_local_peer_id())
	if not _is_local_off_deck() and not local_station_id.is_empty() and _station_anchors_avatar(local_station_id):
		local_run_avatar_position = _get_local_run_avatar_target()
		local_run_avatar_world_position = _get_local_avatar_world_position()
		local_run_avatar_velocity = Vector3.ZERO
		local_run_avatar_grounded = true
		local_overboard_transition_pending = false
		_reset_local_run_transition_state(local_run_avatar_position, local_run_avatar_world_position)
		if local_run_avatar_controller != null:
			local_run_avatar_controller.top_level = true
			local_run_avatar_controller.global_position = boat_root.to_global(local_run_avatar_position)
			local_run_avatar_controller.velocity = Vector3.ZERO
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
	var local_avatar_state := _get_local_run_avatar_state()
	var burst_active := Input.is_key_pressed(KEY_SHIFT) and float(local_avatar_state.get("stamina", NetworkRuntime.AVATAR_MAX_STAMINA)) > 0.0
	var jump_pressed := Input.is_physical_key_pressed(KEY_SPACE)
	var jump_just_pressed := jump_pressed and not local_jump_latched
	local_jump_latched = jump_pressed
	if active_reaction:
		move_direction_world = Vector3.ZERO
	elif recovering:
		move_direction_world *= 0.35

	if _is_local_climbing():
		var climb_surface := _get_local_climb_surface()
		if climb_surface.is_empty():
			local_run_avatar_mode = NetworkRuntime.RUN_AVATAR_MODE_SWIM
			local_surface_tread_active = true
			local_surface_tread_elapsed = 0.0
		else:
			local_off_deck_entry_elapsed = minf(RUN_OFF_DECK_BLEND_DURATION, local_off_deck_entry_elapsed + delta)
			local_surface_tread_active = false
			local_surface_tread_elapsed = 0.0
			var climb_local_position := boat_root.to_local(local_run_avatar_world_position)
			var climb_tangent: Vector3 = climb_surface.get("tangent", Vector3.RIGHT)
			climb_local_position.y += input_vector.y * RUN_CLIMB_SPEED * delta
			climb_local_position += climb_tangent * input_vector.x * RUN_CLIMB_SHIMMY_SPEED * delta
			var climb_world_position := boat_root.to_global(climb_local_position)
			var previous_world_position := local_run_avatar_world_position
			local_run_avatar_world_position = _clamp_world_position_to_climb_surface(climb_surface, climb_world_position)
			local_run_avatar_velocity = (local_run_avatar_world_position - previous_world_position) / maxf(delta, 0.001)
			local_run_avatar_grounded = false
			var climb_normal_world: Vector3 = Vector3(climb_surface.get("normal", Vector3.BACK)).rotated(Vector3.UP, boat_root.rotation.y)
			local_avatar_facing_y = atan2(-climb_normal_world.x, -climb_normal_world.z)
			if jump_just_pressed:
				_detach_local_climb(move_direction_world)
				return
			if input_vector.y > 0.15 and _try_top_out_local_climb(climb_surface):
				return
			if local_run_avatar_controller != null:
				_set_local_run_avatar_collision_enabled(false)
				local_run_avatar_controller.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
				local_run_avatar_controller.top_level = true
				local_run_avatar_controller.global_position = local_run_avatar_world_position
				local_run_avatar_controller.velocity = Vector3.ZERO
			return

	if _is_local_swimming():
		local_off_deck_entry_elapsed = minf(RUN_OFF_DECK_BLEND_DURATION, local_off_deck_entry_elapsed + delta)
		if not local_surface_tread_active:
			local_surface_tread_active = true
			local_surface_tread_elapsed = 0.0
		else:
			local_surface_tread_elapsed += delta
		var off_deck_blend := _get_local_off_deck_blend()
		var swim_speed := RUN_SWIM_MOVE_SPEED * lerpf(0.72, 1.0, off_deck_blend) * (RUN_SWIM_BURST_MULTIPLIER if burst_active else 1.0)
		var swim_acceleration := lerpf(RUN_SWIM_ACCELERATION * 0.55, RUN_SWIM_ACCELERATION, off_deck_blend)
		var swim_drift_velocity := _get_local_swim_drift_velocity(local_run_avatar_world_position)
		var climb_candidate := _get_local_climb_surface_candidate()
		if jump_just_pressed:
			if not climb_candidate.is_empty():
				var climb_attach_position: Vector3 = climb_candidate.get("attach_world_position", local_run_avatar_world_position)
				var climb_normal_local: Vector3 = climb_candidate.get("normal", Vector3.BACK)
				var climb_facing_y := atan2(-climb_normal_local.x, -climb_normal_local.z)
				local_run_avatar_mode = NetworkRuntime.RUN_AVATAR_MODE_CLIMB
				local_run_avatar_world_position = climb_attach_position
				local_run_avatar_velocity = Vector3.ZERO
				local_run_avatar_grounded = false
				local_avatar_facing_y = boat_root.rotation.y + climb_facing_y
				local_surface_tread_active = false
				local_surface_tread_elapsed = 0.0
				NetworkRuntime.request_local_climb_attach(str(climb_candidate.get("id", "")), climb_attach_position, climb_facing_y)
				return
			if local_swim_jump_cooldown <= 0.0:
				var jump_velocity := swim_drift_velocity * 0.45
				if move_direction_world.length() > 0.001:
					jump_velocity += move_direction_world * RUN_SWIM_JUMP_FORWARD_BOOST
				jump_velocity.y = RUN_SWIM_JUMP_VELOCITY
				_begin_local_swim_jump(jump_velocity)
				return
		var target_swim_velocity := swim_drift_velocity
		if move_direction_world.length() > 0.001:
			target_swim_velocity += move_direction_world * swim_speed
		if move_direction_world.length() > 0.001:
			local_run_avatar_velocity.x = move_toward(local_run_avatar_velocity.x, target_swim_velocity.x, swim_acceleration * delta)
			local_run_avatar_velocity.z = move_toward(local_run_avatar_velocity.z, target_swim_velocity.z, swim_acceleration * delta)
		else:
			local_run_avatar_velocity.x = move_toward(local_run_avatar_velocity.x, target_swim_velocity.x, swim_acceleration * delta * 1.2)
			local_run_avatar_velocity.z = move_toward(local_run_avatar_velocity.z, target_swim_velocity.z, swim_acceleration * delta * 1.2)
		local_run_avatar_world_position += Vector3(local_run_avatar_velocity.x, 0.0, local_run_avatar_velocity.z) * delta
		local_run_avatar_world_position = _clamp_local_swim_world_position(local_run_avatar_world_position)
		local_run_avatar_world_position = _resolve_local_swim_hull_core(local_run_avatar_world_position)
		if local_run_avatar_controller != null:
			_set_local_run_avatar_collision_enabled(false)
			local_run_avatar_controller.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
			local_run_avatar_controller.top_level = true
			local_run_avatar_controller.global_position = local_run_avatar_world_position
			local_run_avatar_controller.velocity = Vector3(local_run_avatar_velocity.x, 0.0, local_run_avatar_velocity.z)
		local_run_avatar_grounded = false
		local_overboard_transition_pending = false
		return
	local_off_deck_entry_elapsed = RUN_OFF_DECK_BLEND_DURATION
	local_surface_tread_active = false
	local_surface_tread_elapsed = 0.0

	var move_direction_local := Vector3.ZERO
	if move_direction_world.length() > 0.001:
		move_direction_local = boat_root.global_transform.basis.inverse() * move_direction_world
		move_direction_local.y = 0.0
		move_direction_local = move_direction_local.normalized()

	if local_run_avatar_controller == null:
		if move_direction_local.length() > 0.001:
			var move_speed := RUN_AVATAR_MOVE_SPEED * (RUN_AVATAR_SPRINT_MULTIPLIER if burst_active else 1.0)
			local_run_avatar_velocity.x = move_toward(local_run_avatar_velocity.x, move_direction_local.x * move_speed, RUN_AVATAR_ACCELERATION * delta)
			local_run_avatar_velocity.z = move_toward(local_run_avatar_velocity.z, move_direction_local.z * move_speed, RUN_AVATAR_ACCELERATION * delta)
		else:
			local_run_avatar_velocity.x = move_toward(local_run_avatar_velocity.x, 0.0, RUN_AVATAR_ACCELERATION * delta)
			local_run_avatar_velocity.z = move_toward(local_run_avatar_velocity.z, 0.0, RUN_AVATAR_ACCELERATION * delta)
		var previous_position := local_run_avatar_position
		local_run_avatar_position += Vector3(local_run_avatar_velocity.x, 0.0, local_run_avatar_velocity.z) * delta
		local_run_avatar_position = _sanitize_local_run_avatar_position(local_run_avatar_position, previous_position)
		local_run_avatar_world_position = _get_local_avatar_world_position()
		local_run_avatar_grounded = true
		_reset_local_run_transition_state(local_run_avatar_position, local_run_avatar_world_position)
		return

	var move_speed := RUN_AVATAR_MOVE_SPEED * (RUN_AVATAR_SPRINT_MULTIPLIER if burst_active else 1.0)
	local_run_avatar_controller.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	var acceleration := RUN_AVATAR_ACCELERATION if local_run_avatar_controller.is_on_floor() else RUN_AVATAR_AIR_ACCELERATION
	var boat_basis := boat_root.global_transform.basis.orthonormalized()
	var controller_velocity := local_run_avatar_controller.velocity
	var controller_local_velocity := boat_basis.inverse() * controller_velocity
	controller_local_velocity.x = move_toward(controller_local_velocity.x, move_direction_local.x * move_speed, acceleration * delta)
	controller_local_velocity.z = move_toward(controller_local_velocity.z, move_direction_local.z * move_speed, acceleration * delta)
	var planar_velocity_world := (boat_basis.x * controller_local_velocity.x) + (boat_basis.z * controller_local_velocity.z)
	controller_velocity.x = planar_velocity_world.x
	controller_velocity.z = planar_velocity_world.z
	controller_velocity.y -= RUN_AVATAR_GRAVITY * delta
	if jump_just_pressed and local_run_avatar_controller.is_on_floor() and not active_reaction and not recovering:
		controller_velocity.y = RUN_AVATAR_JUMP_VELOCITY
	local_run_avatar_controller.velocity = controller_velocity
	local_run_avatar_controller.move_and_slide()
	local_run_avatar_world_position = local_run_avatar_controller.global_position
	var previous_deck_position := local_run_avatar_position
	local_run_avatar_position = boat_root.to_local(local_run_avatar_world_position)
	local_run_avatar_velocity = local_run_avatar_controller.velocity
	local_run_avatar_grounded = local_run_avatar_controller.is_on_floor()
	if local_run_avatar_grounded:
		local_run_avatar_position = _sanitize_local_run_avatar_position(local_run_avatar_position, previous_deck_position)
		local_overboard_transition_pending = false
		_reset_local_run_transition_state(local_run_avatar_position, local_run_avatar_world_position)
		return
	if local_run_transition_state == LOCAL_RUN_TRANSITION_DECK:
		local_run_transition_state = LOCAL_RUN_TRANSITION_AIRBORNE_DECK
		local_run_transition_elapsed = 0.0
		local_run_offboard_elapsed = 0.0
	local_run_transition_elapsed += delta
	var stable_support_projection := NetworkRuntime.get_run_avatar_support_projection(
		local_run_avatar_position,
		NetworkRuntime.RUN_OVERBOARD_EDGE_MARGIN
	)
	var stable_support_valid := bool(stable_support_projection.get("valid", false))
	var catch_projection := _get_local_airborne_catch_projection()
	var catch_valid := bool(catch_projection.get("valid", false))
	var catch_deck_position: Vector3 = catch_projection.get("deck_position", local_last_stable_deck_position)
	var catch_world_position := boat_root.to_global(catch_deck_position)
	var catch_gap := float(catch_projection.get("horizontal_distance", INF))
	var near_water_surface := local_run_avatar_world_position.y <= NetworkRuntime.RUN_OVERBOARD_WATER_HEIGHT + RUN_AVATAR_OVERBOARD_ENTRY_BUFFER
	var dropped_below_catch := local_run_avatar_world_position.y <= catch_world_position.y - RUN_AVATAR_SUPPORT_DROP_THRESHOLD
	var beyond_catch_band := not catch_valid or catch_gap > RUN_AIRBORNE_OFFBOARD_COMMIT_DISTANCE
	if local_run_transition_state == LOCAL_RUN_TRANSITION_AIRBORNE_DECK and not stable_support_valid:
		local_run_transition_state = LOCAL_RUN_TRANSITION_AIRBORNE_OFFBOARD
		local_run_offboard_elapsed = 0.0
	if local_run_transition_state == LOCAL_RUN_TRANSITION_AIRBORNE_OFFBOARD:
		local_run_offboard_elapsed += delta
		if _can_recatch_local_deck(catch_projection, local_run_avatar_controller.velocity) and local_run_offboard_elapsed <= RUN_AIRBORNE_OFFBOARD_RETURN_WINDOW:
			local_run_transition_state = LOCAL_RUN_TRANSITION_AIRBORNE_DECK
			local_run_offboard_elapsed = 0.0
		elif not local_overboard_transition_pending and (
			near_water_surface
			or dropped_below_catch
			or (beyond_catch_band and local_run_offboard_elapsed >= RUN_AIRBORNE_OFFBOARD_COMMIT_DELAY)
		):
			_begin_local_water_entry(local_run_avatar_velocity)

func _sync_local_run_avatar_state(delta: float) -> void:
	run_avatar_sync_timer = maxf(0.0, run_avatar_sync_timer - delta)
	if run_avatar_sync_timer > 0.0:
		return
	run_avatar_sync_timer = RUN_AVATAR_SYNC_INTERVAL
	if (local_water_entry_active or local_overboard_transition_pending) and not _is_local_overboard():
		return
	var grounded := local_run_avatar_grounded
	if not _is_local_off_deck() and local_run_avatar_controller != null:
		local_run_avatar_world_position = local_run_avatar_controller.global_position
		local_run_avatar_position = _sanitize_local_run_avatar_position(
			boat_root.to_local(local_run_avatar_world_position),
			local_run_avatar_position
		)
		local_run_avatar_velocity = local_run_avatar_controller.velocity
		grounded = local_run_avatar_controller.is_on_floor()
		NetworkRuntime.send_local_run_avatar_state(
			local_run_avatar_position,
			local_run_avatar_world_position,
			local_run_avatar_velocity,
			local_avatar_facing_y,
			grounded if not _is_local_off_deck() else false,
			local_run_avatar_mode
		)

func _collect_input_state(delta: float) -> Dictionary:
	var input_state := {
		"claim_station": "",
		"request_brace": false,
		"request_grapple": false,
		"request_repair": false,
		"request_propulsion_primary": false,
		"request_propulsion_secondary": false,
		"assist_target_peer_id": 0,
		"throttle": 0.0,
		"steer": 0.0,
	}
	var local_reaction := _get_reaction_visual(_get_local_peer_id())
	var active_reaction := float(local_reaction.get("active_time", 0.0)) > 0.0
	var recovering := float(local_reaction.get("recovery_time", 0.0)) > 0.0
	var local_downed := _is_local_downed()

	if not active_reaction and not local_downed:
		_collect_station_selection_input()
		_collect_station_interaction_input(delta, input_state)
		if not recovering:
			_collect_action_input(input_state)
		_collect_drive_input(input_state)
		if recovering:
			input_state["throttle"] = float(input_state.get("throttle", 0.0)) * 0.35
			input_state["steer"] = float(input_state.get("steer", 0.0)) * 0.35
	else:
		assist_rally_hold_target_peer_id = 0
		assist_rally_hold_seconds = 0.0

	var autorun_role := str(launch_overrides.get("autorun_role", ""))
	if not active_reaction and not local_downed and not autorun_role.is_empty():
		_apply_autorun_role(delta, autorun_role, input_state)
	elif not active_reaction and not local_downed and bool(launch_overrides.get("autorun_demo", false)):
		_apply_autorun_demo(delta, input_state)
	elif not active_reaction and not local_downed:
		_apply_scripted_station_input(delta, input_state)

	return input_state

func _collect_station_selection_input() -> void:
	if _is_local_off_deck() or _is_local_downed():
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

func _collect_station_interaction_input(delta: float, input_state: Dictionary) -> void:
	var interact_pressed := Input.is_key_pressed(KEY_F)
	var rally_target := _get_local_rally_target()
	if not interact_pressed or rally_target.is_empty():
		assist_rally_hold_target_peer_id = 0
		assist_rally_hold_seconds = 0.0
	if interact_pressed and not rally_target.is_empty():
		var target_peer_id := int(rally_target.get("peer_id", 0))
		if assist_rally_hold_target_peer_id != target_peer_id:
			assist_rally_hold_target_peer_id = target_peer_id
			assist_rally_hold_seconds = 0.0
		assist_rally_hold_seconds += delta
		if assist_rally_hold_seconds >= ASSIST_RALLY_HOLD_SECONDS:
			if _can_local_use_stamina_action(NetworkRuntime.AVATAR_ASSIST_STAMINA_COST):
				input_state["assist_target_peer_id"] = target_peer_id
			else:
				_show_local_action_blocked("Too winded to rally")
			assist_rally_hold_target_peer_id = 0
			assist_rally_hold_seconds = 0.0
		interact_latched = interact_pressed
		return
	if interact_pressed and not interact_latched:
		if _is_local_downed():
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
	var item_use_pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if _is_local_off_deck() or _is_local_downed():
		item_use_request_latched = item_use_pressed
		brace_request_latched = Input.is_key_pressed(RUN_BRACE_KEY)
		grapple_request_latched = Input.is_key_pressed(KEY_G)
		repair_request_latched = Input.is_key_pressed(KEY_R)
		return
	var local_station_id := NetworkRuntime.get_peer_station_id(_get_local_peer_id())
	var active_tool_id := _get_selected_run_tool_id()

	if item_use_pressed and not item_use_request_latched:
		match active_tool_id:
			"grapple":
				if local_station_id == "grapple":
					input_state["request_grapple"] = true
				else:
					_show_local_action_blocked("Need the grapple station")
			"repair":
				if _can_local_use_stamina_action(NetworkRuntime.AVATAR_REPAIR_STAMINA_COST):
					input_state["request_repair"] = true
				else:
					_show_local_action_blocked("Too winded to patch")
	item_use_request_latched = item_use_pressed

	var brace_pressed := Input.is_key_pressed(RUN_BRACE_KEY)
	if brace_pressed and not brace_request_latched:
		if _can_local_use_stamina_action(NetworkRuntime.AVATAR_BRACE_STAMINA_COST):
			input_state["request_brace"] = true
		else:
			_show_local_action_blocked("Too winded to brace")
	brace_request_latched = brace_pressed

	var grapple_pressed := Input.is_key_pressed(KEY_G)
	if grapple_pressed and not grapple_request_latched:
		if local_station_id == "grapple":
			input_state["request_grapple"] = true
		elif local_station_id == "drive":
			input_state["request_propulsion_primary"] = true
	grapple_request_latched = grapple_pressed

	var repair_pressed := Input.is_key_pressed(KEY_R)
	if repair_pressed and not repair_request_latched:
		if local_station_id == "drive":
			input_state["request_propulsion_secondary"] = true
		else:
			if _can_local_use_stamina_action(NetworkRuntime.AVATAR_REPAIR_STAMINA_COST):
				input_state["request_repair"] = true
			else:
				_show_local_action_blocked("Too winded to patch")
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
	if _is_local_off_deck():
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
	if _is_local_off_deck():
		_apply_overboard_recovery_role(delta, input_state)
		return

	var local_station_id := NetworkRuntime.get_peer_station_id(_get_local_peer_id())
	var loot_remaining := int(NetworkRuntime.run_state.get("loot_remaining", 0))
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var boat_speed: float = float(NetworkRuntime.boat_state.get("speed", 0.0))
	var salvage_site := _get_nearest_poi_site(RunWorldGenerator.SITE_SALVAGE, true)
	var breach_stacks := int(NetworkRuntime.boat_state.get("breach_stacks", 0))
	var brace_timer: float = float(NetworkRuntime.boat_state.get("brace_timer", 0.0))
	var brace_cooldown: float = float(NetworkRuntime.boat_state.get("brace_cooldown", 0.0))
	var cache_site := _get_nearest_poi_site(RunWorldGenerator.SITE_RESUPPLY, true)
	var rescue_site := _get_nearest_poi_site(RunWorldGenerator.SITE_DISTRESS, true)
	var should_cash_out := _should_autorun_cash_out()

	if not should_cash_out and loot_remaining > 0 and not salvage_site.is_empty():
		var wreck_position: Vector3 = salvage_site.get("position", Vector3.ZERO)
		var wreck_radius: float = float(salvage_site.get("radius", 4.4))
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

	if not should_cash_out and not rescue_site.is_empty():
		var rescue_position: Vector3 = rescue_site.get("position", Vector3.ZERO)
		var rescue_radius: float = float(rescue_site.get("radius", 3.4))
		var rescue_max_speed: float = float(rescue_site.get("max_speed", NetworkRuntime.RESCUE_MAX_SPEED))
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

	if not should_cash_out and not cache_site.is_empty():
		var cache_position: Vector3 = cache_site.get("position", Vector3.ZERO)
		var cache_radius: float = float(cache_site.get("radius", 2.9))
		var cache_max_speed: float = float(cache_site.get("max_speed", 1.75))
		if boat_position.distance_to(cache_position) <= cache_radius and absf(boat_speed) <= cache_max_speed:
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
	var should_cash_out := _should_autorun_cash_out()
	var salvage_site := _get_nearest_poi_site(RunWorldGenerator.SITE_SALVAGE, true)
	if not should_cash_out and not salvage_site.is_empty():
		if not _station_is_crewed("grapple"):
			input_state["throttle"] = 0.0
			input_state["steer"] = 0.0
			_maybe_request_autobrace(input_state)
			return
		var wreck_position: Vector3 = salvage_site.get("position", Vector3.ZERO)
		var wreck_radius: float = float(salvage_site.get("radius", 4.4))
		if boat_position.distance_to(wreck_position) > wreck_radius * 0.55:
			_apply_drive_to_target(wreck_position + Vector3(0.0, 0.0, -1.1), input_state)
		else:
			_hold_position_over_target(wreck_position, float(salvage_site.get("max_speed", NetworkRuntime.SALVAGE_MAX_SPEED)), input_state)
		_maybe_request_autobrace(input_state)
		return

	var rescue_site := _get_nearest_poi_site(RunWorldGenerator.SITE_DISTRESS, true)
	if not should_cash_out and not rescue_site.is_empty():
		if not _station_is_crewed("grapple"):
			input_state["throttle"] = 0.0
			input_state["steer"] = 0.0
			_maybe_request_autobrace(input_state)
			return
		var rescue_position: Vector3 = rescue_site.get("position", Vector3.ZERO)
		var rescue_radius: float = float(rescue_site.get("radius", 3.4))
		if boat_position.distance_to(rescue_position) > rescue_radius * 0.8:
			_apply_drive_to_target(rescue_position + Vector3(0.0, 0.0, -0.8), input_state, 0.52)
		else:
			_hold_position_over_target(rescue_position, float(rescue_site.get("max_speed", NetworkRuntime.RESCUE_MAX_SPEED)), input_state)
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

	var should_cash_out := _should_autorun_cash_out()
	var salvage_site := _get_nearest_poi_site(RunWorldGenerator.SITE_SALVAGE, true)
	if not should_cash_out and not salvage_site.is_empty():
		if not _station_is_crewed("grapple"):
			input_state["throttle"] = 0.0
			input_state["steer"] = 0.0
			_maybe_request_autobrace(input_state)
			return
		var wreck_position: Vector3 = salvage_site.get("position", Vector3.ZERO)
		var wreck_radius: float = float(salvage_site.get("radius", 4.4))
		if NetworkRuntime.boat_state.get("position", Vector3.ZERO).distance_to(wreck_position) > wreck_radius * 0.55:
			_apply_drive_to_target(wreck_position + Vector3(0.0, 0.0, -1.1), input_state)
		else:
			_hold_position_over_target(wreck_position, float(salvage_site.get("max_speed", NetworkRuntime.SALVAGE_MAX_SPEED)), input_state)
		_maybe_request_autobrace(input_state)
		return

	if int(NetworkRuntime.run_state.get("detached_chunk_count", 0)) > 0 or int(NetworkRuntime.run_state.get("cargo_lost_to_sea", 0)) > 0:
		input_state["throttle"] = 0.0
		input_state["steer"] = 0.0
		_maybe_request_autobrace(input_state)
		return

	_apply_coordinated_return_route(input_state)
	_maybe_request_autobrace(input_state)

func _apply_grapple_role(delta: float, input_state: Dictionary) -> void:
	if str(NetworkRuntime.run_state.get("phase", "running")) != "running":
		return

	var local_station_id := NetworkRuntime.get_peer_station_id(_get_local_peer_id())
	_request_station_if_needed("grapple", input_state, delta)
	if local_station_id != "grapple":
		return

	if _should_autorun_cash_out():
		return

	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var rescue_site := _get_nearest_poi_site(RunWorldGenerator.SITE_DISTRESS, true)
	if not rescue_site.is_empty():
		if boat_position.distance_to(rescue_site.get("position", Vector3.ZERO)) <= float(rescue_site.get("radius", 3.4)) and absf(float(NetworkRuntime.boat_state.get("speed", 0.0))) <= float(rescue_site.get("max_speed", NetworkRuntime.RESCUE_MAX_SPEED)) and action_request_cooldown <= 0.0:
			input_state["request_grapple"] = true
			action_request_cooldown = 0.45
			return

	var cache_site := _get_nearest_poi_site(RunWorldGenerator.SITE_RESUPPLY, true)
	if not cache_site.is_empty():
		if boat_position.distance_to(cache_site.get("position", Vector3.ZERO)) <= float(cache_site.get("radius", 2.9)) and absf(float(NetworkRuntime.boat_state.get("speed", 0.0))) <= float(cache_site.get("max_speed", 1.75)) and action_request_cooldown <= 0.0:
			_request_station_if_needed("grapple", input_state, delta)
			input_state["request_grapple"] = true
			action_request_cooldown = 0.45
			return
	var salvage_site := _get_nearest_poi_site(RunWorldGenerator.SITE_SALVAGE, true)
	if salvage_site.is_empty():
		return
	if boat_position.distance_to(salvage_site.get("position", Vector3.ZERO)) > float(salvage_site.get("radius", 4.4)):
		return
	if float(NetworkRuntime.boat_state.get("brace_timer", 0.0)) <= 0.0:
		return
	if absf(float(NetworkRuntime.boat_state.get("speed", 0.0))) > float(salvage_site.get("max_speed", NetworkRuntime.SALVAGE_MAX_SPEED)):
		return
	if action_request_cooldown > 0.0:
		return
	input_state["request_grapple"] = true
	action_request_cooldown = 0.45

func _should_autorun_cash_out() -> bool:
	var cargo_count := int(NetworkRuntime.run_state.get("cargo_count", 0))
	if cargo_count <= 0:
		return false
	var revealed_extractions := _get_revealed_extraction_sites()
	if not revealed_extractions.is_empty():
		return true
	var cargo_capacity := int(NetworkRuntime.run_state.get("cargo_capacity", int(NetworkRuntime.boat_state.get("cargo_capacity", 1))))
	var cargo_target := 1 if revealed_extractions.is_empty() else mini(2, cargo_capacity)
	if cargo_count >= cargo_target:
		return true
	if int(NetworkRuntime.run_state.get("repair_supplies", 0)) <= 1:
		return true
	var hull_integrity := float(NetworkRuntime.boat_state.get("hull_integrity", NetworkRuntime.BOAT_MAX_INTEGRITY))
	var max_hull_integrity := maxf(1.0, float(NetworkRuntime.boat_state.get("max_hull_integrity", hull_integrity)))
	return hull_integrity / max_hull_integrity <= 0.65

func _apply_brace_role(_delta: float, input_state: Dictionary) -> void:
	if str(NetworkRuntime.run_state.get("phase", "running")) != "running":
		return
	if float(NetworkRuntime.boat_state.get("brace_cooldown", 0.0)) > 0.0 or action_request_cooldown > 0.0:
		return

	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var salvage_site := _get_nearest_poi_site(RunWorldGenerator.SITE_SALVAGE, true)
	var salvage_ready := not salvage_site.is_empty() and boat_position.distance_to(salvage_site.get("position", Vector3.ZERO)) <= float(salvage_site.get("radius", 4.4)) + 0.55 and absf(float(NetworkRuntime.boat_state.get("speed", 0.0))) <= float(salvage_site.get("max_speed", NetworkRuntime.SALVAGE_MAX_SPEED)) + 0.45
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
	if _is_local_swimming() or _is_local_climbing():
		var climb_target := _get_local_climb_surface_candidate()
		if climb_target.is_empty():
			return
		_scripted_move_local_avatar_toward_world(climb_target.get("attach_world_position", local_run_avatar_world_position), delta)
		return
	var stern_edge := NetworkRuntime.get_nearest_run_avatar_deck_position(Vector3(0.0, 0.92, 1.98))
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
	var extraction_site := _get_nearest_extraction_site(true)
	if extraction_site.is_empty():
		extraction_site = _get_nearest_extraction_site(false)
	if extraction_site.is_empty():
		input_state["throttle"] = 0.0
		input_state["steer"] = 0.0
		return
	var extraction_position: Vector3 = extraction_site.get("position", Vector3.ZERO)
	var extraction_radius: float = float(extraction_site.get("radius", 3.7))
	if boat_position.distance_to(extraction_position) <= extraction_radius + 0.6:
		_hold_position_over_target(extraction_position, NetworkRuntime.EXTRACTION_MAX_SPEED, input_state)
		return
	_apply_drive_to_target(extraction_position, input_state, 1.0)

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
	if _is_local_off_deck():
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
	var previous_position := boat_root.global_position
	var server_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var rotation_y: float = float(NetworkRuntime.boat_state.get("rotation_y", 0.0))
	var sea_pose := _sample_boat_wave_pose(server_position, rotation_y)
	var draft_ratio := float(NetworkRuntime.boat_state.get("draft_ratio", 0.72))
	var roll_resistance := clampf(float(NetworkRuntime.boat_state.get("roll_resistance", 50.0)) / 100.0, 0.0, 1.0)
	var pitch_resistance := clampf(float(NetworkRuntime.boat_state.get("pitch_resistance", 50.0)) / 100.0, 0.0, 1.0)
	var heel_bias := float(NetworkRuntime.boat_state.get("heel_bias", 0.0))
	var trim_bias := float(NetworkRuntime.boat_state.get("trim_bias", 0.0))
	var surface_offset := float(NetworkRuntime.boat_state.get("water_surface_offset", float(sea_pose.get("height", 0.0))))
	var buoyancy_heave := float(NetworkRuntime.boat_state.get("buoyancy_heave", 0.0))
	var ride_height_offset := -clampf((draft_ratio - 0.72) * 0.85, -0.04, 0.34)
	var pitch_wave_scale := lerpf(1.12, 0.45, pitch_resistance)
	var roll_wave_scale := lerpf(1.18, 0.40, roll_resistance)
	var hydro_pitch := clampf(trim_bias * 0.30, -0.22, 0.22)
	var hydro_roll := clampf(heel_bias * 0.38, -0.26, 0.26)
	var fallback_pitch := float(sea_pose.get("pitch", 0.0)) * pitch_wave_scale + hydro_pitch
	var fallback_roll := -(float(sea_pose.get("roll", 0.0)) * roll_wave_scale + hydro_roll)
	var preview_buoyancy_only := (NetworkRuntime.multiplayer == null or NetworkRuntime.multiplayer.multiplayer_peer == null) and int(NetworkRuntime.boat_state.get("tick", 0)) <= 0
	var resolved_surface_offset := surface_offset
	var resolved_heave := buoyancy_heave
	var target_pitch := float(NetworkRuntime.boat_state.get("buoyancy_pitch", fallback_pitch))
	var target_roll := float(NetworkRuntime.boat_state.get("buoyancy_roll", fallback_roll))
	if preview_buoyancy_only:
		resolved_surface_offset = float(sea_pose.get("height", 0.0))
		resolved_heave = 0.0
		target_pitch = fallback_pitch
		target_roll = fallback_roll
	var target_position := server_position + Vector3(0.0, 0.36 + ride_height_offset + resolved_surface_offset + resolved_heave, 0.0)
	boat_root.position = boat_root.position.lerp(target_position, minf(1.0, delta * 10.8))
	boat_root.rotation.y = lerp_angle(boat_root.rotation.y, rotation_y, minf(1.0, delta * 12.0))
	boat_root.rotation.x = lerpf(boat_root.rotation.x, target_pitch, minf(1.0, delta * 9.6))
	boat_root.rotation.z = lerpf(boat_root.rotation.z, target_roll, minf(1.0, delta * 9.6))
	if delta > 0.0:
		boat_visual_velocity = (boat_root.global_position - previous_position) / delta
	else:
		boat_visual_velocity = Vector3.ZERO

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
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var boat_speed: float = absf(float(NetworkRuntime.boat_state.get("speed", 0.0)))
	for site_variant in _get_poi_sites(RunWorldGenerator.SITE_SALVAGE, false):
		var site: Dictionary = site_variant
		var visual: Dictionary = salvage_site_visuals.get(str(site.get("id", "")), {})
		var root := visual.get("root") as Node3D
		if root == null:
			continue
		root.position = site.get("position", Vector3.ZERO) + Vector3(0.0, sin(connect_time_seconds * 0.72 + float(root.get_index())) * 0.06, 0.0)
		var in_zone := boat_position.distance_to(site.get("position", Vector3.ZERO)) <= float(site.get("radius", 4.4))
		var ready_color := Color(0.23, 0.79, 0.57) if in_zone and boat_speed <= float(site.get("max_speed", NetworkRuntime.SALVAGE_MAX_SPEED)) else Color(0.87, 0.56, 0.19)
		var foam_material := visual.get("foam_material") as ShaderMaterial
		if root.has_method("set_ring_color"):
			root.call("set_ring_color", ready_color)
		if foam_material != null:
			foam_material.set_shader_parameter("core_color", Color(0.88, 0.95, 1.0))
			foam_material.set_shader_parameter("edge_color", ready_color)
			foam_material.set_shader_parameter("intensity", 0.22 + (0.20 if in_zone else 0.06))
			foam_material.set_shader_parameter("foam_radius", 0.70)
			foam_material.set_shader_parameter("foam_width", 0.17)
			foam_material.set_shader_parameter("soft_fill", 0.11)
			foam_material.set_shader_parameter("breakup_strength", 0.22)
			foam_material.set_shader_parameter("scroll_speed", 0.38)
		if root.has_method("set_body_color"):
			root.call("set_body_color", Color(0.38, 0.24, 0.18).lerp(Color(0.58, 0.32, 0.18), 0.18 if in_zone else 0.0))
		if root.has_method("set_label_text"):
			root.call("set_label_text", "%s\nLoot %d | Max Speed %.1f" % [
				str(site.get("label", "Wreck Salvage")),
				int(site.get("loot_remaining", 0)),
				float(site.get("max_speed", NetworkRuntime.SALVAGE_MAX_SPEED)),
			])
		if root.has_method("set_label_color"):
			root.call("set_label_color", ready_color.lightened(0.18))

func _update_rescue_visual() -> void:
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var boat_speed: float = absf(float(NetworkRuntime.boat_state.get("speed", 0.0)))
	for site_variant in _get_poi_sites(RunWorldGenerator.SITE_DISTRESS, false):
		var site: Dictionary = site_variant
		var visual: Dictionary = distress_site_visuals.get(str(site.get("id", "")), {})
		var root := visual.get("root") as Node3D
		if root == null:
			continue
		root.visible = bool(site.get("available", false)) or bool(site.get("completed", false))
		root.position = site.get("position", Vector3.ZERO) + Vector3(0.0, sin(connect_time_seconds * 1.18) * 0.08, 0.0)
		var in_zone := boat_position.distance_to(site.get("position", Vector3.ZERO)) <= float(site.get("radius", 3.4))
		var ready_color := Color(0.93, 0.72, 0.28)
		if bool(site.get("completed", false)):
			ready_color = Color(0.29, 0.82, 0.58)
		elif bool(site.get("engaged", false)):
			ready_color = Color(0.95, 0.84, 0.36)
		elif in_zone and boat_speed <= float(site.get("max_speed", NetworkRuntime.RESCUE_MAX_SPEED)):
			ready_color = Color(0.98, 0.86, 0.36)
		var foam_material := visual.get("foam_material") as ShaderMaterial
		if root.has_method("set_ring_color"):
			root.call("set_ring_color", ready_color)
		if foam_material != null:
			foam_material.set_shader_parameter("core_color", Color(0.92, 0.97, 1.0))
			foam_material.set_shader_parameter("edge_color", ready_color)
			foam_material.set_shader_parameter("intensity", 0.28 + (0.24 if bool(site.get("engaged", false)) else 0.0) + (0.12 if in_zone else 0.0))
			foam_material.set_shader_parameter("foam_radius", 0.68)
			foam_material.set_shader_parameter("foam_width", 0.20)
			foam_material.set_shader_parameter("soft_fill", 0.14)
			foam_material.set_shader_parameter("breakup_strength", 0.28)
			foam_material.set_shader_parameter("scroll_speed", 0.52)
		if root.has_method("set_body_color"):
			root.call("set_body_color", Color(0.56, 0.37, 0.18).lerp(Color(0.93, 0.56, 0.18), 0.7 if bool(site.get("available", false)) else 0.2))
		var label_text := "%s\nHold %.1f/%.1fs | Max Speed %.1f" % [
			str(site.get("label", "Distress Rescue")),
			float(site.get("progress", 0.0)),
			float(site.get("duration", 1.0)),
			float(site.get("max_speed", NetworkRuntime.RESCUE_MAX_SPEED)),
		]
		if bool(site.get("completed", false)):
			label_text = "%s\nSecured gold, recovery materials, and %d kit" % [
				str(site.get("label", "Distress Rescue")),
				int(site.get("patch_kit_bonus", 0)),
			]
		if root.has_method("set_label_text"):
			root.call("set_label_text", label_text)
		if root.has_method("set_label_color"):
			root.call("set_label_color", ready_color.lightened(0.16))

func _update_cache_visual() -> void:
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var boat_speed: float = absf(float(NetworkRuntime.boat_state.get("speed", 0.0)))
	for site_variant in _get_poi_sites(RunWorldGenerator.SITE_RESUPPLY, false):
		var site: Dictionary = site_variant
		var visual: Dictionary = resupply_site_visuals.get(str(site.get("id", "")), {})
		var root := visual.get("root") as Node3D
		if root == null:
			continue
		root.position = site.get("position", Vector3.ZERO) + Vector3(0.0, sin(connect_time_seconds * 1.12 + 0.5) * 0.07, 0.0)
		var in_zone := boat_position.distance_to(site.get("position", Vector3.ZERO)) <= float(site.get("radius", NetworkRuntime.RESUPPLY_CACHE_RADIUS))
		var ready_color := Color(0.21, 0.82, 0.57) if bool(site.get("available", false)) and in_zone and boat_speed <= float(site.get("max_speed", NetworkRuntime.RESUPPLY_CACHE_MAX_SPEED)) else Color(0.23, 0.71, 0.84)
		if not bool(site.get("available", false)):
			ready_color = Color(0.44, 0.50, 0.56)
		var foam_material := visual.get("foam_material") as ShaderMaterial
		if root.has_method("set_ring_color"):
			root.call("set_ring_color", ready_color)
		if foam_material != null:
			foam_material.set_shader_parameter("core_color", Color(0.84, 0.96, 1.0))
			foam_material.set_shader_parameter("edge_color", ready_color)
			foam_material.set_shader_parameter("intensity", 0.20 + (0.10 if in_zone and bool(site.get("available", false)) else 0.0))
			foam_material.set_shader_parameter("foam_radius", 0.69)
			foam_material.set_shader_parameter("foam_width", 0.18)
			foam_material.set_shader_parameter("soft_fill", 0.10)
			foam_material.set_shader_parameter("breakup_strength", 0.20)
			foam_material.set_shader_parameter("scroll_speed", 0.34)
		if root.has_method("set_body_color"):
			root.call("set_body_color", Color(0.19, 0.48, 0.58).lerp(Color(0.50, 0.55, 0.60), 1.0 if not bool(site.get("available", false)) else 0.0))
		var label_text := "%s\nGold, cache materials, and %d patch kit | Max Speed %.1f" % [
			str(site.get("label", "Resupply Cache")),
			int(site.get("supply_grant", NetworkRuntime.RESUPPLY_CACHE_SUPPLY_GRANT)),
			float(site.get("max_speed", NetworkRuntime.RESUPPLY_CACHE_MAX_SPEED)),
		]
		if not bool(site.get("available", false)):
			label_text = "%s\nRecovered" % str(site.get("label", "Resupply Cache"))
		if root.has_method("set_label_text"):
			root.call("set_label_text", label_text)
		if root.has_method("set_label_color"):
			root.call("set_label_color", ready_color.lightened(0.18))

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
		var streak_materials: Array = visual.get("streak_materials", [])
		var label := visual.get("label") as Label3D
		var inside := _position_inside_squall(boat_position, band)
		if shell_material != null:
			shell_material.albedo_color = Color(0.10, 0.16, 0.22, 0.18).lerp(Color(0.18, 0.30, 0.42, 0.28), 1.0 if inside else 0.36)
		if core_material != null:
			core_material.albedo_color = Color(0.24, 0.56, 0.76, 0.30).lerp(Color(0.80, 0.88, 0.96, 0.58), 1.0 if inside else 0.0)
		var streak_strength := clampf(0.28 + float(band.get("pulse_damage", 0.0)) * 0.04 + (0.26 if inside else 0.0), 0.0, 1.0)
		for streak_material_variant in streak_materials:
			var streak_material := streak_material_variant as ShaderMaterial
			if streak_material == null:
				continue
			streak_material.set_shader_parameter("intensity", streak_strength)
			streak_material.set_shader_parameter("scroll_speed", 2.2 + float(band.get("drag_multiplier", 1.0)) * 0.9)
		if label != null:
			label.text = "%s\nDrag x%.2f | Surge %.1f" % [
				str(band.get("label", "Squall Front")),
				float(band.get("drag_multiplier", 1.0)),
				float(band.get("pulse_damage", 0.0)),
			]
			label.modulate = Color(0.90, 0.97, 1.0) if inside else Color(0.70, 0.84, 0.96)

func _update_extraction_visual(_delta: float) -> void:
	var cargo_count := int(NetworkRuntime.run_state.get("cargo_count", 0))
	var phase := str(NetworkRuntime.run_state.get("phase", "running"))
	for site_variant in _get_revealed_extraction_sites():
		var site: Dictionary = site_variant
		var visual: Dictionary = extraction_site_visuals.get(str(site.get("id", "")), {})
		var root := visual.get("root") as Node3D
		if root == null:
			continue
		root.position = site.get("position", Vector3.ZERO) + Vector3(0.0, sin(connect_time_seconds * 0.95) * 0.08, 0.0)
		var can_extract := cargo_count > 0 and _boat_within_extraction_zone(str(site.get("id", ""))) and float(NetworkRuntime.boat_state.get("speed", 0.0)) <= NetworkRuntime.EXTRACTION_MAX_SPEED
		var extraction_color := EXTRACTION_READY_COLOR if can_extract else EXTRACTION_IDLE_COLOR
		if phase == "failed":
			extraction_color = EXTRACTION_FAILED_COLOR
		elif phase == "success":
			extraction_color = EXTRACTION_READY_COLOR
		var foam_material := visual.get("foam_material") as ShaderMaterial
		if root.has_method("set_ring_color"):
			root.call("set_ring_color", extraction_color)
		if foam_material != null:
			foam_material.set_shader_parameter("core_color", Color(0.88, 0.97, 1.0))
			foam_material.set_shader_parameter("edge_color", extraction_color)
			foam_material.set_shader_parameter("intensity", 0.24 + (0.22 if can_extract else 0.06))
			foam_material.set_shader_parameter("foam_radius", 0.74)
			foam_material.set_shader_parameter("foam_width", 0.20)
			foam_material.set_shader_parameter("soft_fill", 0.14)
			foam_material.set_shader_parameter("breakup_strength", 0.24)
			foam_material.set_shader_parameter("scroll_speed", 0.42)
		if root.has_method("set_body_color"):
			root.call("set_body_color", extraction_color)
		var label_text := "%s\nCargo %d | %.1f/%.1fs" % [
			str(site.get("label", "Extraction")),
			cargo_count,
			float(NetworkRuntime.run_state.get("extraction_progress", 0.0)),
			float(NetworkRuntime.run_state.get("extraction_duration", 1.0)),
		]
		if root.has_method("set_label_text"):
			root.call("set_label_text", label_text)
		if root.has_method("set_label_color"):
			root.call("set_label_color", extraction_color.lightened(0.18))

func _update_camera(delta: float) -> void:
	if camera == null:
		return

	var speed_ratio := clampf(absf(float(NetworkRuntime.boat_state.get("speed", 0.0))) / NetworkRuntime.BOAT_TOP_SPEED, 0.0, 1.0)
	var pivot := _get_local_avatar_world_position() + Vector3(0.0, run_camera_look_height, 0.0)
	var global_yaw := local_avatar_facing_y if _is_local_off_deck() else boat_root.rotation.y + local_avatar_facing_y
	var yaw_basis := Basis(Vector3.UP, global_yaw)
	var aim_basis := yaw_basis * Basis(Vector3.RIGHT, local_camera_pitch)
	var forward := (aim_basis * Vector3.FORWARD).normalized()
	var right := (yaw_basis * Vector3.RIGHT).normalized()
	var off_deck := _is_local_off_deck()
	var off_deck_blend := _get_local_off_deck_blend() if off_deck else 1.0
	var reboard_settle_blend := _get_local_reboard_settle_blend()
	var off_deck_distance_bonus := lerpf(0.85, 0.32, off_deck_blend) if off_deck else 0.0
	var desired_position := pivot - forward * (run_camera_distance + speed_ratio * 1.4 + off_deck_distance_bonus)
	desired_position += right * run_camera_side_offset
	var off_deck_camera_drop := lerpf(0.18, 0.44, off_deck_blend) if off_deck else 0.0
	var off_deck_bob := sin(connect_time_seconds * 2.5 + float(_get_local_peer_id())) * 0.05 if off_deck else 0.0
	desired_position += Vector3.UP * (run_camera_height - off_deck_camera_drop + off_deck_bob * 0.4)
	desired_position += Vector3.UP * (0.12 * reboard_settle_blend)
	desired_position += local_camera_jolt
	var look_target := pivot + forward * (run_camera_look_ahead + speed_ratio * 0.8) + Vector3.UP * (off_deck_bob + reboard_settle_blend * 0.08) + local_camera_jolt * 0.42
	var camera_lag := lerpf(run_camera_lag * 0.5, run_camera_lag * 0.82, off_deck_blend) if off_deck else run_camera_lag
	var blend := minf(1.0, delta * camera_lag)
	var camera_roll := _get_local_surface_camera_roll(global_yaw) if _is_local_overboard() else 0.0
	var up_vector := Vector3.UP.rotated(forward, camera_roll)
	if AddonRuntime.runtime_camera_mode != AddonRuntime.CAMERA_MODE_LEGACY:
		_update_phantom_camera_state(desired_position, look_target, up_vector, 69.0 + speed_ratio * 7.0 + (1.3 if off_deck else 0.0))
		return
	if phantom_runtime_camera != null:
		phantom_runtime_camera.current = false
	if not camera.current:
		camera.current = true
		camera.make_current()
	camera.position = camera.position.lerp(desired_position, blend)
	camera.fov = lerpf(camera.fov, 69.0 + speed_ratio * 7.0 + (1.3 if off_deck else 0.0), blend)
	camera.look_at(look_target, up_vector)


func _ensure_phantom_camera_rig() -> void:
	phantom_runtime_camera = get_node_or_null("AddonPhantomCamera") as Camera3D
	if phantom_runtime_camera == null:
		phantom_runtime_camera = Camera3D.new()
		phantom_runtime_camera.name = "AddonPhantomCamera"
		add_child(phantom_runtime_camera)
	phantom_camera_host = phantom_runtime_camera.get_node_or_null("PhantomCameraHost")
	if phantom_camera_host == null:
		phantom_camera_host = Node.new()
		phantom_camera_host.name = "PhantomCameraHost"
		phantom_camera_host.set_script(PHANTOM_CAMERA_HOST_SCRIPT)
		phantom_runtime_camera.add_child(phantom_camera_host)
	phantom_follow_camera = get_node_or_null("AddonFollowPhantomCamera") as Node3D
	if phantom_follow_camera == null:
		phantom_follow_camera = Node3D.new()
		phantom_follow_camera.name = "AddonFollowPhantomCamera"
		phantom_follow_camera.top_level = true
		phantom_follow_camera.set_script(PHANTOM_CAMERA_3D_SCRIPT)
		add_child(phantom_follow_camera)
	phantom_follow_camera.set("follow_mode", 0)
	phantom_follow_camera.set("host_layers", 1)
	phantom_overview_camera = get_node_or_null("AddonOverviewPhantomCamera") as Node3D
	if phantom_overview_camera == null:
		phantom_overview_camera = Node3D.new()
		phantom_overview_camera.name = "AddonOverviewPhantomCamera"
		phantom_overview_camera.top_level = true
		phantom_overview_camera.set_script(PHANTOM_CAMERA_3D_SCRIPT)
		add_child(phantom_overview_camera)
	phantom_overview_camera.set("follow_mode", 0)
	phantom_overview_camera.set("host_layers", 1)


func _update_phantom_camera_state(desired_position: Vector3, look_target: Vector3, up_vector: Vector3, target_fov: float) -> void:
	_ensure_phantom_camera_rig()
	if phantom_runtime_camera == null or phantom_follow_camera == null or phantom_overview_camera == null:
		return
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var target_site := _get_nearest_extraction_site(true)
	var overview_focus := boat_position
	if not target_site.is_empty():
		overview_focus = boat_position.lerp(target_site.get("position", boat_position), 0.42)
	var overview_position := overview_focus + Vector3(18.0, 24.0, 18.0)
	phantom_follow_camera.global_transform = _make_look_transform(desired_position, look_target, up_vector)
	phantom_overview_camera.global_transform = _make_look_transform(overview_position, overview_focus, Vector3.UP)
	if AddonRuntime.runtime_camera_mode == AddonRuntime.CAMERA_MODE_OVERVIEW:
		phantom_follow_camera.set("priority", 5)
		phantom_overview_camera.set("priority", 25)
		phantom_runtime_camera.fov = 58.0
	else:
		phantom_follow_camera.set("priority", 25)
		phantom_overview_camera.set("priority", 5)
		phantom_runtime_camera.fov = target_fov
	camera.current = false
	if not phantom_runtime_camera.current:
		phantom_runtime_camera.current = true
		phantom_runtime_camera.make_current()


func _make_look_transform(origin: Vector3, target: Vector3, up_vector: Vector3) -> Transform3D:
	return Transform3D(Basis.IDENTITY, origin).looking_at(target, up_vector)


func _ensure_acoustic_body(parent: Node, acoustic_material: Resource) -> void:
	if parent == null or acoustic_material == null:
		return
	var acoustic_body := parent.get_node_or_null("AcousticBody")
	if acoustic_body == null:
		acoustic_body = ACOUSTIC_BODY_SCRIPT.new()
		acoustic_body.name = "AcousticBody"
		parent.add_child(acoustic_body)
	acoustic_body.set("acoustic_material", acoustic_material)


func _ensure_terrain_preview() -> void:
	terrain_preview_root = get_node_or_null("TerrainPreview") as Node3D
	if terrain_preview_root != null:
		return
	terrain_preview_root = TERRAIN_PREVIEW_SCENE.instantiate() as Node3D
	if terrain_preview_root == null:
		return
	terrain_preview_root.name = "TerrainPreview"
	terrain_preview_root.position = Vector3(WATER_SURFACE_SIZE * 0.34, WATER_SURFACE_Y - 1.4, -WATER_SURFACE_SIZE * 0.28)
	terrain_preview_root.visible = AddonRuntime.terrain_preview_enabled
	add_child(terrain_preview_root)


func _update_terrain_preview() -> void:
	if terrain_preview_root == null:
		return
	terrain_preview_root.visible = AddonRuntime.terrain_preview_enabled


func _draw_debug_draw_overlay() -> void:
	if not AddonRuntime.debug_draw_enabled or boat_root == null:
		return
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	for descriptor_variant in _get_active_chunk_descriptors():
		var descriptor: Dictionary = descriptor_variant
		var center: Vector3 = descriptor.get("world_center", Vector3.ZERO)
		var chunk_size := float(descriptor.get("chunk_size_m", RunWorldGenerator.CHUNK_SIZE_M))
		_debug_draw_call("draw_box", [center, Quaternion.IDENTITY, Vector3(chunk_size, 0.4, chunk_size), Color(0.28, 0.72, 0.88, 0.08)])
	var extraction_site := _get_nearest_extraction_site(true)
	if not extraction_site.is_empty():
		var extraction_position: Vector3 = extraction_site.get("position", Vector3.ZERO)
		var extraction_radius := float(extraction_site.get("radius", NetworkRuntime.EXTRACTION_RADIUS))
		_debug_draw_call("draw_line", [boat_position, extraction_position, EXTRACTION_READY_COLOR, 0.05])
		_debug_draw_call("draw_sphere", [extraction_position, extraction_radius, EXTRACTION_IDLE_COLOR, 0.05])
	_debug_draw_call("draw_line", [camera.global_position if camera != null else boat_position + Vector3.UP * 4.0, boat_position, Color(0.97, 0.83, 0.31), 0.05])


func _debug_draw_call(method: StringName, args: Array) -> void:
	if not Engine.has_singleton("DebugDrawManager"):
		return
	var debug_draw_manager := Engine.get_singleton("DebugDrawManager")
	if debug_draw_manager == null or not debug_draw_manager.has_method(method):
		return
	debug_draw_manager.callv(method, args)

func _update_boat_material() -> void:
	if hull_material == null:
		return

	var hull_integrity: float = float(NetworkRuntime.boat_state.get("hull_integrity", 100.0))
	var max_hull_integrity: float = maxf(1.0, float(NetworkRuntime.boat_state.get("max_hull_integrity", 100.0)))
	var health_ratio := clampf(hull_integrity / max_hull_integrity, 0.0, 1.0)
	var damaged_color := Color(0.45, 0.14, 0.12)
	var healthy_color := Color(0.44, 0.27, 0.16)
	hull_material.albedo_color = damaged_color.lerp(healthy_color, health_ratio)

func _boat_within_extraction_zone(site_id: String = "") -> bool:
	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var extraction_site := _get_nearest_extraction_site(true)
	if not site_id.is_empty():
		for site_variant in _get_revealed_extraction_sites():
			var site: Dictionary = site_variant
			if str(site.get("id", "")) == site_id:
				extraction_site = site
				break
	if extraction_site.is_empty():
		return false
	var extraction_position: Vector3 = extraction_site.get("position", Vector3.ZERO)
	var extraction_radius: float = float(extraction_site.get("radius", 3.7))
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
	return NetworkRuntime.get_local_peer_id()

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
			if event.keycode == RUN_DEBUG_OVERLAY_TOGGLE_KEY:
				_set_debug_overlay_enabled(not debug_overlay_enabled)
				return
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
		return
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
		_continue_to_dock()

func _on_status_changed(_message: String) -> void:
	_refresh_hud()

func _on_session_phase_changed(phase: String) -> void:
	if phase == NetworkRuntime.SESSION_PHASE_HANGAR:
		_set_mouse_capture(false)
		GameConfig.queue_scene_load(
			HANGAR_SCENE,
			"Returning To Dock",
			"Securing the haul, logging the damage, restoring the shared blueprint, and bringing the crew back into the build yard."
		)
		get_tree().change_scene_to_file(LOADING_SCENE)

func _on_peer_snapshot_changed(_snapshot: Dictionary) -> void:
	_refresh_local_run_avatar_controller()
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
		local_run_avatar_grounded = bool(local_state.get("grounded", local_run_avatar_grounded))
		var synced_facing := float(local_state.get("facing_y", local_avatar_facing_y))
		if previous_mode != local_run_avatar_mode:
			if local_run_avatar_mode == NetworkRuntime.RUN_AVATAR_MODE_SWIM:
				local_avatar_facing_y = boat_root.rotation.y + synced_facing
				local_overboard_transition_pending = false
				local_off_deck_entry_elapsed = 0.0
				local_surface_tread_active = true
				local_surface_tread_elapsed = 0.0
			elif local_run_avatar_mode == NetworkRuntime.RUN_AVATAR_MODE_CLIMB:
				local_avatar_facing_y = boat_root.rotation.y + synced_facing
				local_overboard_transition_pending = false
				local_off_deck_entry_elapsed = 0.0
				local_surface_tread_active = false
				local_surface_tread_elapsed = 0.0
			elif previous_mode == NetworkRuntime.RUN_AVATAR_MODE_SWIM or previous_mode == NetworkRuntime.RUN_AVATAR_MODE_CLIMB:
				local_avatar_facing_y = synced_facing - boat_root.rotation.y
				local_overboard_transition_pending = false
				local_off_deck_entry_elapsed = RUN_OFF_DECK_BLEND_DURATION
				local_surface_tread_active = false
				local_surface_tread_elapsed = 0.0
				local_reboard_settle_timer = RUN_REBOARD_SETTLE_DURATION
				local_camera_jolt += Vector3(0.0, 0.05, -0.08)
			else:
				local_avatar_facing_y = synced_facing
		else:
			local_avatar_facing_y = synced_facing
		if local_run_avatar_mode != NetworkRuntime.RUN_AVATAR_MODE_DECK:
			local_water_entry_active = false
			local_water_entry_elapsed = 0.0
			local_overboard_transition_pending = false
			local_run_transition_state = LOCAL_RUN_TRANSITION_AIRBORNE_OFFBOARD
			local_run_transition_elapsed = 0.0
			local_run_offboard_elapsed = 0.0
			if local_run_avatar_mode == NetworkRuntime.RUN_AVATAR_MODE_DOWNED:
				local_off_deck_entry_elapsed = RUN_OFF_DECK_BLEND_DURATION
				local_surface_tread_active = false
				local_surface_tread_elapsed = 0.0
			elif local_run_avatar_mode == NetworkRuntime.RUN_AVATAR_MODE_SWIM and not local_surface_tread_active:
				local_surface_tread_active = true
				local_surface_tread_elapsed = 0.0
		elif previous_mode != local_run_avatar_mode:
			local_water_entry_active = false
			local_water_entry_elapsed = 0.0
			local_off_deck_entry_elapsed = RUN_OFF_DECK_BLEND_DURATION
			local_surface_tread_active = false
			local_surface_tread_elapsed = 0.0
			_reset_local_run_transition_state(local_run_avatar_position, local_run_avatar_world_position)
			var force_controller_sync := previous_mode != local_run_avatar_mode and local_run_avatar_mode != NetworkRuntime.RUN_AVATAR_MODE_SWIM and local_run_avatar_mode != NetworkRuntime.RUN_AVATAR_MODE_CLIMB
			_sync_local_run_avatar_controller_from_state(force_controller_sync)
	var local_overboard := _is_local_off_deck()
	if local_overboard and not last_local_overboard:
		_push_event_callout("Overboard!", HUD_TEXT_DANGER, 2.4)
		if local_surface_contact_feedback_timer <= 0.0:
			_spawn_splash_burst(_get_local_avatar_world_position(), 1.15, Color(0.92, 0.96, 1.0), Color(0.54, 0.76, 0.86))
	elif not local_overboard and last_local_overboard:
		_push_event_callout("Back On Deck", HUD_TEXT_SUCCESS, 2.1)
		_spawn_splash_burst(_get_local_avatar_world_position(), 0.72, Color(0.80, 0.92, 0.98), Color(0.44, 0.68, 0.78))
	last_local_overboard = local_overboard
	var local_downed := _is_local_downed()
	if local_downed and not last_local_downed:
		_push_event_callout("Downed!", HUD_TEXT_DANGER, 2.0)
	elif not local_downed and last_local_downed:
		_push_event_callout("Recovered", HUD_TEXT_SUCCESS, 1.8)
	last_local_downed = local_downed
	var overboard_count := 0
	var downed_count := 0
	for peer_id_variant in snapshot.keys():
		var avatar_state: Dictionary = snapshot.get(peer_id_variant, {})
		var avatar_mode := str(avatar_state.get("mode", NetworkRuntime.RUN_AVATAR_MODE_DECK))
		if avatar_mode == NetworkRuntime.RUN_AVATAR_MODE_SWIM or avatar_mode == NetworkRuntime.RUN_AVATAR_MODE_CLIMB:
			overboard_count += 1
		elif avatar_mode == NetworkRuntime.RUN_AVATAR_MODE_DOWNED:
			downed_count += 1
	if overboard_count > last_hud_overboard_count:
		_push_event_callout("Crew Overboard", HUD_TEXT_WARNING, 2.0)
	if downed_count > last_hud_downed_count:
		_push_event_callout("Crew Downed", HUD_TEXT_DANGER, 2.0)
	last_hud_overboard_count = overboard_count
	last_hud_downed_count = downed_count
	_refresh_local_run_avatar_controller()
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
		var boat_forward := -Vector3.FORWARD.rotated(Vector3.UP, float(NetworkRuntime.boat_state.get("rotation_y", 0.0)))
		var impact_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO) + boat_forward * 2.5
		var impact_strength := clampf(float(NetworkRuntime.boat_state.get("last_impact_damage", 0.0)) / 14.0, 0.55, 1.35)
		_spawn_splash_burst(impact_position, impact_strength, Color(0.92, 0.97, 1.0), Color(0.56, 0.76, 0.86))
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
	_build_station_visuals()
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
	if not is_inside_tree():
		return
	_build_recovery_visuals()
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
		var scene_tree := get_tree()
		if scene_tree != null:
			scene_tree.create_timer(0.5).timeout.connect(_continue_to_dock)
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
	if _is_local_downed():
		return "Objective: Hold position until you self-recover, or let a nearby crewmate rally you."
	if _is_local_off_deck():
		if not _get_local_climb_surface_candidate().is_empty():
			return "Objective: Press Space near the hull or ladder to climb back aboard."
		return "Objective: Swim clear, jump for the deck, or reach a ladder to climb back aboard."

	var boat_position: Vector3 = NetworkRuntime.boat_state.get("position", Vector3.ZERO)
	var boat_speed: float = absf(float(NetworkRuntime.boat_state.get("speed", 0.0)))
	var loot_remaining := int(NetworkRuntime.run_state.get("loot_remaining", 0))
	var salvage_site := _get_nearest_poi_site(RunWorldGenerator.SITE_SALVAGE, true)
	var rescue_available := bool(NetworkRuntime.run_state.get("rescue_available", false))
	var rescue_engaged := bool(NetworkRuntime.run_state.get("rescue_engaged", false))
	var rescue_site := _get_nearest_poi_site(RunWorldGenerator.SITE_DISTRESS, true)
	if loot_remaining > 0:
		if salvage_site.is_empty():
			return "Objective: Hunt the sea for another salvage site."
		var wreck_position: Vector3 = salvage_site.get("position", Vector3.ZERO)
		var wreck_radius: float = float(salvage_site.get("radius", 4.4))
		if boat_position.distance_to(wreck_position) > wreck_radius:
			return "Objective: Bring the boat into the nearest salvage ring."
		if boat_speed > float(NetworkRuntime.run_state.get("salvage_max_speed", NetworkRuntime.SALVAGE_MAX_SPEED)):
			return "Objective: Hold below salvage speed."
		return "Objective: Brace anywhere on deck and let the grappler recover the remaining wreck loot."

	if rescue_available:
		if rescue_site.is_empty():
			return "Objective: Distress signal active. Sweep the nearby sea and decide whether to divert."
		var rescue_position: Vector3 = rescue_site.get("position", Vector3.ZERO)
		var rescue_radius: float = float(rescue_site.get("radius", 3.4))
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
		var extraction_site := _get_nearest_extraction_site(true)
		if extraction_site.is_empty():
			return "Objective: Search the open sea until an outpost beacon is revealed."
		if not _boat_within_extraction_zone(str(extraction_site.get("id", ""))):
			return "Objective: Bring the boat into the extraction ring."
		if boat_speed > NetworkRuntime.EXTRACTION_MAX_SPEED:
			return "Objective: Bleed speed and hold steady."
		return "Objective: Stay calm until extraction completes."

	return "Objective: Claim stations and prepare the shared boat."

func _build_onboarding_text(selected_station_id: String, local_station_id: String) -> String:
	var phase := str(NetworkRuntime.run_state.get("phase", "running"))
	var pressure_phase := str(NetworkRuntime.run_state.get("pressure_phase", NetworkRuntime.RUN_PRESSURE_PHASE_CALM))
	if phase == "success":
		return "Onboarding: Press Enter or Continue to return to the hangar and spend the rewards."
	if phase == "failed":
		return "Onboarding: Failed runs lose unbanked cargo. Rebuild and try a safer route."
	if _is_local_downed():
		return "Onboarding: You are downed. Stay clear of fresh impacts and wait out the timer, or have a nearby crewmate hold F to rally you faster."
	if _is_local_off_deck():
		return "Onboarding: You are in the water. Space jumps. Press Space near a ladder or exposed hull face to climb back onto the boat."

	if local_station_id.is_empty():
		var selected_label := "a station"
		if not selected_station_id.is_empty():
			selected_label = NetworkRuntime.get_station_label(selected_station_id)
		return "Onboarding: Mouse aim drives the camera. Walk the deck, then use Q/E and F to take %s. Space works anywhere." % selected_label

	if local_station_id == "drive":
		var propulsion_family := str(NetworkRuntime.boat_state.get("propulsion_family", NetworkRuntime.PROPULSION_FAMILY_RAFT_PADDLES))
		if propulsion_family == NetworkRuntime.PROPULSION_FAMILY_SAIL_RIG:
			return "Onboarding: Sail rigs care about wind angle. Claim the trim deck, use G to pull the canvas into the breeze, and reef with R when the weather turns ugly."
		if propulsion_family == NetworkRuntime.PROPULSION_FAMILY_STEAM_TUG:
			return "Onboarding: Helm sets intent, but the steam tug only answers cleanly when someone tends the boiler with G and keeps heat under control with R."
		if propulsion_family == NetworkRuntime.PROPULSION_FAMILY_TWIN_ENGINE:
			return "Onboarding: Twin engines reward attention. Use G to keep them in sync and R when heat starts eating response."
		return "Onboarding: This hull runs on raft paddles. Claim the drive station and use G to add burst labor when the helm needs speed."

	if _boat_inside_any_squall():
		return "Onboarding: Squalls drag the boat and fire surge pulses. Keep speed under control and brace through the slam."
	if pressure_phase == NetworkRuntime.RUN_PRESSURE_PHASE_COLLAPSE or pressure_phase == NetworkRuntime.RUN_PRESSURE_PHASE_CASCADE:
		return "Onboarding: The run is cascading. Stabilize propulsion, recover the crew, and stop taking optional risks until the machine settles."
	if pressure_phase == NetworkRuntime.RUN_PRESSURE_PHASE_CRITICAL:
		return "Onboarding: Pressure is critical. Repair, recover, and play the next thirty seconds clean before chasing more cargo."

	if int(NetworkRuntime.run_state.get("loot_remaining", 0)) > 0:
		return "Onboarding: Sail to any salvage ring, slow down, brace from anywhere, and keep the grappler safe."

	var repair_target := _find_local_repair_target()
	if not repair_target.is_empty():
		return "Onboarding: You are close enough to patch the damaged hull here. Press R if the kit spend is worth it."

	if bool(NetworkRuntime.run_state.get("rescue_available", false)):
		return "Onboarding: Distress rescues are optional. Hold inside the ring long enough to secure the bonus."

	if bool(NetworkRuntime.run_state.get("cache_available", false)):
		return "Onboarding: Resupply caches are quick bonus stops if the route still looks safe."

	if int(NetworkRuntime.run_state.get("cargo_count", 0)) > 0:
		if _get_revealed_extraction_sites().is_empty():
			return "Onboarding: Outposts stay hidden until you sail close enough to spot them. Keep scanning the horizon."
		return "Onboarding: Everything aboard is lost if the boat sinks before extraction. Cash out once risk climbs."

	return "Onboarding: Stay near the helm to steer, or roam the deck and support the crew where it hurts."
