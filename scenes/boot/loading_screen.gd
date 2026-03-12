extends Control

const FALLBACK_SCENE := "res://scenes/boot/client_boot.tscn"
const MAX_TRACE_ENTRIES := 6

@onready var title_label: Label = $Center/Panel/Margin/Layout/TitleLabel
@onready var detail_label: Label = $Center/Panel/Margin/Layout/DetailLabel
@onready var trace_label: RichTextLabel = $Center/Panel/Margin/Layout/TraceLog
@onready var progress_bar: ProgressBar = $Center/Panel/Margin/Layout/ProgressBar
@onready var status_label: Label = $Center/Panel/Margin/Layout/StatusLabel

var _target_scene_path := ""
var _load_started := false
var _load_progress := []
var _spinner_time := 0.0
var _trace_entries := PackedStringArray()
var _logged_request_accept := false
var _logged_midway_load := false
var _logged_finalizing_load := false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var request := GameConfig.consume_scene_load()
	_target_scene_path = str(request.get("scene_path", ""))
	title_label.text = str(request.get("title", "Loading"))
	detail_label.text = str(request.get("detail", "Preparing the next scene."))
	progress_bar.value = 0.0
	status_label.text = "Starting loader..."
	_seed_trace(Array(request.get("trace", [])))
	if not NetworkRuntime.status_changed.is_connected(_on_network_status_changed):
		NetworkRuntime.status_changed.connect(_on_network_status_changed)
	var current_status := _normalize_trace_message(NetworkRuntime.status_message)
	if not current_status.is_empty():
		_append_trace(current_status)
	if _target_scene_path.is_empty():
		status_label.text = "No target scene was queued. Returning to connect."
		_append_trace("No scene was queued. Returning to connect.")
		get_tree().create_timer(0.3).timeout.connect(func() -> void:
			get_tree().change_scene_to_file(FALLBACK_SCENE)
		)
		return

	var request_error := ResourceLoader.load_threaded_request(_target_scene_path)
	if request_error != OK:
		status_label.text = "Threaded loading was unavailable. Falling back..."
		_append_trace("Threaded loading was unavailable. Falling back to direct scene change.")
		get_tree().call_deferred("change_scene_to_file", _target_scene_path)
		return

	_load_started = true
	status_label.text = "Loading scene data..."
	_append_trace("Scene load request accepted.")
	_logged_request_accept = true
	set_process(true)

func _process(delta: float) -> void:
	if not _load_started:
		return
	_spinner_time += delta
	_load_progress.clear()
	var load_status := ResourceLoader.load_threaded_get_status(_target_scene_path, _load_progress)
	if _load_progress.size() > 0:
		progress_bar.value = clampf(float(_load_progress[0]) * 100.0, 0.0, 100.0)
		_maybe_trace_progress(float(_load_progress[0]))
	else:
		progress_bar.value = fposmod(_spinner_time * 35.0, 100.0)

	match load_status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var dots := ".".repeat(int(_spinner_time * 3.0) % 4)
			status_label.text = "Loading scene data%s" % dots
		ResourceLoader.THREAD_LOAD_LOADED:
			var scene_resource := ResourceLoader.load_threaded_get(_target_scene_path) as PackedScene
			if scene_resource == null:
				status_label.text = "The scene loaded, but it could not be opened."
				_append_trace("Scene payload was ready, but the PackedScene was invalid.")
				return
			set_process(false)
			status_label.text = "Entering scene..."
			_append_trace("Scene resources loaded. Entering scene.")
			get_tree().change_scene_to_packed(scene_resource)
		ResourceLoader.THREAD_LOAD_FAILED:
			set_process(false)
			status_label.text = "Scene loading failed. Returning to connect."
			_append_trace("Scene loading failed. Returning to connect.")
			get_tree().create_timer(0.6).timeout.connect(func() -> void:
				get_tree().change_scene_to_file(FALLBACK_SCENE)
			)
		_:
			pass

func _exit_tree() -> void:
	if NetworkRuntime.status_changed.is_connected(_on_network_status_changed):
		NetworkRuntime.status_changed.disconnect(_on_network_status_changed)

func _seed_trace(trace_entries: Array) -> void:
	_trace_entries.clear()
	for entry_variant in trace_entries:
		var entry := _normalize_trace_message(str(entry_variant))
		if entry.is_empty():
			continue
		_trace_entries.append(entry)
	_update_trace_label()

func _append_trace(message: String) -> void:
	var normalized := _normalize_trace_message(message)
	if normalized.is_empty():
		return
	if _trace_entries.is_empty() or _trace_entries[_trace_entries.size() - 1] != normalized:
		_trace_entries.append(normalized)
	while _trace_entries.size() > MAX_TRACE_ENTRIES:
		_trace_entries.remove_at(0)
	_update_trace_label()

func _update_trace_label() -> void:
	if trace_label == null:
		return
	var lines := PackedStringArray()
	for entry in _trace_entries:
		lines.append("> %s" % str(entry))
	trace_label.text = "\n".join(lines)

func _normalize_trace_message(message: String) -> String:
	var normalized := message.strip_edges()
	if normalized.is_empty():
		return ""
	if normalized == "Offline":
		return ""
	return normalized

func _maybe_trace_progress(progress_ratio: float) -> void:
	if progress_ratio >= 0.35 and not _logged_midway_load:
		_logged_midway_load = true
		_append_trace("Streaming scene resources and runtime state.")
	if progress_ratio >= 0.78 and not _logged_finalizing_load:
		_logged_finalizing_load = true
		_append_trace("Finalizing scene instance and handoff.")

func _on_network_status_changed(message: String) -> void:
	_append_trace(message)
