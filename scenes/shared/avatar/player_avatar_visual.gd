extends Node3D

const STATE_IDLE := "idle"
const STATE_WALK := "walk"
const STATE_RUN := "run"

const IDLE_SCENE: PackedScene = preload("res://assets/characters/player/source/idle_with_skin.glb")
const WALK_SCENE: PackedScene = preload("res://assets/characters/player/source/walk_with_skin.glb")
const RUN_SCENE: PackedScene = preload("res://assets/characters/player/source/run_with_skin.glb")

const HIPS_TRACK_PATH := NodePath("Armature/Skeleton3D:Hips")
const BLEND_PARAMETER_PATH := "parameters/blend_position"
const WALK_BLEND_POSITION := 0.45

static var cached_motion_animations: Dictionary = {}
static var motion_cache_ready := false

@export_range(0.5, 2.0, 0.01) var avatar_scale := 1.15
@export var nameplate_height := 2.05
@export var tool_offset := Vector3(0.36, 1.0, -0.10)
@export_range(1.0, 14.0, 0.1) var locomotion_blend_response := 7.5

var model_root: Node3D
var foot_ring: MeshInstance3D
var tool: MeshInstance3D
var nameplate: Label3D

var rig_root: Node3D
var animation_player: AnimationPlayer
var animation_tree: AnimationTree
var animation_library: AnimationLibrary

var active_motion_state := STATE_IDLE
var current_motion_blend := 0.0
var target_motion_blend := 0.0
var highlight_color := Color(0.32, 0.84, 0.56)
var tool_color := Color(0.48, 0.92, 0.70)
var nameplate_color := Color(0.96, 0.99, 0.96)
var primary_text := "Crew"
var secondary_text := ""

func _ready() -> void:
	_ensure_nodes()
	_ensure_avatar_rig()
	_apply_avatar_scale()
	_apply_highlight()
	_apply_tool_color()
	_apply_nameplate()
	_apply_motion_blend(true)
	set_process(false)

func _process(delta: float) -> void:
	if is_equal_approx(current_motion_blend, target_motion_blend):
		current_motion_blend = target_motion_blend
		_apply_motion_blend()
		set_process(false)
		return
	current_motion_blend = move_toward(current_motion_blend, target_motion_blend, delta * locomotion_blend_response)
	_apply_motion_blend()

func set_motion_state(state: String) -> void:
	var normalized_state := state.strip_edges().to_lower()
	match normalized_state:
		STATE_RUN:
			active_motion_state = STATE_RUN
			set_motion_blend(1.0)
		STATE_WALK:
			active_motion_state = STATE_WALK
			set_motion_blend(WALK_BLEND_POSITION)
		_:
			active_motion_state = STATE_IDLE
			set_motion_blend(0.0)

func set_motion_blend(blend: float) -> void:
	target_motion_blend = clampf(blend, 0.0, 1.0)
	if target_motion_blend >= 0.75:
		active_motion_state = STATE_RUN
	elif target_motion_blend >= 0.08:
		active_motion_state = STATE_WALK
	else:
		active_motion_state = STATE_IDLE
	if not is_node_ready():
		return
	if is_equal_approx(current_motion_blend, target_motion_blend):
		_apply_motion_blend()
		set_process(false)
		return
	set_process(true)

func set_highlight_color(color: Color) -> void:
	highlight_color = color
	_apply_highlight()

func set_tool_color(color: Color) -> void:
	tool_color = color
	_apply_tool_color()

func set_tool_visible(visible: bool) -> void:
	_ensure_nodes()
	tool.visible = visible

func set_display_text(primary: String, secondary: String = "") -> void:
	primary_text = primary
	secondary_text = secondary
	_apply_nameplate()

func set_nameplate_color(color: Color) -> void:
	nameplate_color = color
	_apply_nameplate()

func _ensure_nodes() -> void:
	model_root = get_node_or_null("ModelRoot") as Node3D
	if model_root == null:
		model_root = Node3D.new()
		model_root.name = "ModelRoot"
		add_child(model_root)

	foot_ring = get_node_or_null("FootRing") as MeshInstance3D
	if foot_ring == null:
		foot_ring = MeshInstance3D.new()
		foot_ring.name = "FootRing"
		var ring_mesh := CylinderMesh.new()
		ring_mesh.top_radius = 0.38
		ring_mesh.bottom_radius = 0.42
		ring_mesh.height = 0.05
		foot_ring.mesh = ring_mesh
		foot_ring.position = Vector3(0.0, 0.05, 0.0)
		add_child(foot_ring)

	tool = get_node_or_null("Tool") as MeshInstance3D
	if tool == null:
		tool = MeshInstance3D.new()
		tool.name = "Tool"
		var tool_mesh := BoxMesh.new()
		tool_mesh.size = Vector3(0.18, 0.18, 0.85)
		tool.mesh = tool_mesh
		tool.position = tool_offset
		tool.rotation_degrees = Vector3(0.0, 18.0, -18.0)
		add_child(tool)
	else:
		tool.position = tool_offset

	nameplate = get_node_or_null("Nameplate") as Label3D
	if nameplate == null:
		nameplate = Label3D.new()
		nameplate.name = "Nameplate"
		nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		nameplate.font_size = 16
		nameplate.outline_size = 8
		add_child(nameplate)
	nameplate.position = Vector3(0.0, nameplate_height, 0.0)

func _ensure_avatar_rig() -> void:
	if rig_root != null and animation_player != null and animation_tree != null:
		return
	if rig_root == null:
		rig_root = model_root.get_node_or_null("Rig") as Node3D
	if rig_root == null:
		var idle_instance := IDLE_SCENE.instantiate() as Node3D
		if idle_instance == null:
			return
		idle_instance.name = "Rig"
		model_root.add_child(idle_instance)
		rig_root = idle_instance

	animation_player = _find_animation_player(rig_root)
	if animation_player == null:
		return
	animation_player.stop()

	animation_library = animation_player.get_animation_library("")
	if animation_library == null:
		animation_library = AnimationLibrary.new()
		animation_player.add_animation_library("", animation_library)

	var idle_source_name := _get_first_animation_name(animation_player)
	var reference_position := Vector3.ZERO
	if not idle_source_name.is_empty():
		var idle_animation := animation_player.get_animation(idle_source_name)
		if idle_animation != null:
			reference_position = _get_hips_reference_position(idle_animation)
			_register_animation_clip(STATE_IDLE, idle_animation, reference_position)

	_ensure_motion_cache(reference_position)
	_register_cached_animation_clip(STATE_WALK, reference_position)
	_register_cached_animation_clip(STATE_RUN, reference_position)
	_ensure_animation_tree()

func _ensure_motion_cache(reference_position: Vector3) -> void:
	if motion_cache_ready:
		return
	cached_motion_animations.clear()
	_cache_animation_from_scene(STATE_WALK, WALK_SCENE, reference_position)
	_cache_animation_from_scene(STATE_RUN, RUN_SCENE, reference_position)
	motion_cache_ready = true

func _cache_animation_from_scene(clip_name: String, scene: PackedScene, reference_position: Vector3) -> void:
	if scene == null:
		return
	var source_instance := scene.instantiate()
	if source_instance == null:
		return
	var source_player := _find_animation_player(source_instance)
	if source_player == null:
		source_instance.free()
		return
	var source_animation_name := _get_first_animation_name(source_player)
	if source_animation_name.is_empty():
		source_instance.free()
		return
	var source_animation := source_player.get_animation(source_animation_name)
	if source_animation != null:
		var cached_animation := source_animation.duplicate(true) as Animation
		if cached_animation != null:
			cached_animation.loop_mode = Animation.LOOP_LINEAR
			_align_hips_track(cached_animation, reference_position)
			cached_motion_animations[clip_name] = cached_animation
	source_instance.free()

func _register_cached_animation_clip(clip_name: String, reference_position: Vector3) -> void:
	var cached_animation := cached_motion_animations.get(clip_name) as Animation
	if cached_animation == null:
		return
	_register_animation_clip(clip_name, cached_animation, reference_position)

func _register_animation_clip(clip_name: String, source_animation: Animation, reference_position: Vector3) -> void:
	if animation_library == null or source_animation == null:
		return
	var animation_copy := source_animation.duplicate(true) as Animation
	if animation_copy == null:
		return
	animation_copy.loop_mode = Animation.LOOP_LINEAR
	_align_hips_track(animation_copy, reference_position)
	if animation_library.has_animation(clip_name):
		animation_library.remove_animation(clip_name)
	animation_library.add_animation(clip_name, animation_copy)

func _ensure_animation_tree() -> void:
	animation_tree = rig_root.get_node_or_null("AnimationTree") as AnimationTree
	if animation_tree == null:
		animation_tree = AnimationTree.new()
		animation_tree.name = "AnimationTree"
		rig_root.add_child(animation_tree)
	if animation_player == null:
		return

	var blend_space := AnimationNodeBlendSpace1D.new()
	blend_space.min_space = 0.0
	blend_space.max_space = 1.0
	blend_space.value_label = "speed"
	blend_space.set_use_sync(true)
	blend_space.add_blend_point(_make_animation_node(STATE_IDLE), 0.0)
	blend_space.add_blend_point(_make_animation_node(STATE_WALK), WALK_BLEND_POSITION)
	blend_space.add_blend_point(_make_animation_node(STATE_RUN), 1.0)

	animation_tree.tree_root = blend_space
	animation_tree.anim_player = animation_tree.get_path_to(animation_player)
	animation_tree.root_node = animation_tree.get_path_to(rig_root)
	animation_tree.active = true

func _make_animation_node(animation_name: String) -> AnimationNodeAnimation:
	var animation_node := AnimationNodeAnimation.new()
	animation_node.animation = animation_name
	return animation_node

func _get_first_animation_name(source_player: AnimationPlayer) -> String:
	if source_player == null:
		return ""
	var animation_list := source_player.get_animation_list()
	if animation_list.is_empty():
		return ""
	return str(animation_list[0])

func _get_hips_reference_position(animation: Animation) -> Vector3:
	var track_index := _find_hips_position_track(animation)
	if track_index == -1 or animation.track_get_key_count(track_index) == 0:
		return Vector3.ZERO
	return animation.track_get_key_value(track_index, 0)

func _align_hips_track(animation: Animation, reference_position: Vector3) -> void:
	var track_index := _find_hips_position_track(animation)
	if track_index == -1:
		return
	var key_count := animation.track_get_key_count(track_index)
	if key_count == 0:
		return
	var source_origin: Vector3 = animation.track_get_key_value(track_index, 0)
	var offset := reference_position - source_origin
	for key_index in range(key_count):
		var track_value: Vector3 = animation.track_get_key_value(track_index, key_index)
		animation.track_set_key_value(track_index, key_index, track_value + offset)

func _find_hips_position_track(animation: Animation) -> int:
	if animation == null:
		return -1
	for track_index in range(animation.get_track_count()):
		if animation.track_get_type(track_index) != Animation.TYPE_POSITION_3D:
			continue
		if animation.track_get_path(track_index) == HIPS_TRACK_PATH:
			return track_index
	return -1

func _apply_avatar_scale() -> void:
	_ensure_nodes()
	model_root.scale = Vector3.ONE * avatar_scale

func _apply_highlight() -> void:
	_ensure_nodes()
	var ring_material := foot_ring.material_override as StandardMaterial3D
	if ring_material == null:
		ring_material = StandardMaterial3D.new()
		ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring_material.roughness = 0.18
		foot_ring.material_override = ring_material
	ring_material.albedo_color = highlight_color.lightened(0.08)

func _apply_tool_color() -> void:
	_ensure_nodes()
	var tool_material := tool.material_override as StandardMaterial3D
	if tool_material == null:
		tool_material = StandardMaterial3D.new()
		tool_material.roughness = 0.24
		tool.material_override = tool_material
	tool_material.albedo_color = tool_color

func _apply_nameplate() -> void:
	_ensure_nodes()
	nameplate.text = primary_text if secondary_text.is_empty() else "%s\n%s" % [primary_text, secondary_text]
	nameplate.modulate = nameplate_color

func _apply_motion_blend(force_snap := false) -> void:
	_ensure_nodes()
	_ensure_avatar_rig()
	if animation_tree == null:
		return
	if force_snap:
		current_motion_blend = target_motion_blend
	elif not is_equal_approx(current_motion_blend, target_motion_blend):
		return
	animation_tree.set(BLEND_PARAMETER_PATH, current_motion_blend)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null
