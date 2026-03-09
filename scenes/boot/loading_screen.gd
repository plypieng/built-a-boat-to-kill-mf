extends Control

const FALLBACK_SCENE := "res://scenes/boot/client_boot.tscn"

@onready var title_label: Label = $Center/Panel/Margin/Layout/TitleLabel
@onready var detail_label: Label = $Center/Panel/Margin/Layout/DetailLabel
@onready var progress_bar: ProgressBar = $Center/Panel/Margin/Layout/ProgressBar
@onready var status_label: Label = $Center/Panel/Margin/Layout/StatusLabel

var _target_scene_path := ""
var _load_started := false
var _load_progress := []
var _spinner_time := 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var request := GameConfig.consume_scene_load()
	_target_scene_path = str(request.get("scene_path", ""))
	title_label.text = str(request.get("title", "Loading"))
	detail_label.text = str(request.get("detail", "Preparing the next scene."))
	progress_bar.value = 0.0
	status_label.text = "Starting loader..."
	if _target_scene_path.is_empty():
		status_label.text = "No target scene was queued. Returning to connect."
		get_tree().create_timer(0.3).timeout.connect(func() -> void:
			get_tree().change_scene_to_file(FALLBACK_SCENE)
		)
		return

	var request_error := ResourceLoader.load_threaded_request(_target_scene_path)
	if request_error != OK:
		status_label.text = "Threaded loading was unavailable. Falling back..."
		get_tree().call_deferred("change_scene_to_file", _target_scene_path)
		return

	_load_started = true
	status_label.text = "Loading scene data..."
	set_process(true)

func _process(delta: float) -> void:
	if not _load_started:
		return
	_spinner_time += delta
	_load_progress.clear()
	var load_status := ResourceLoader.load_threaded_get_status(_target_scene_path, _load_progress)
	if _load_progress.size() > 0:
		progress_bar.value = clampf(float(_load_progress[0]) * 100.0, 0.0, 100.0)
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
				return
			set_process(false)
			status_label.text = "Entering scene..."
			get_tree().change_scene_to_packed(scene_resource)
		ResourceLoader.THREAD_LOAD_FAILED:
			set_process(false)
			status_label.text = "Scene loading failed. Returning to connect."
			get_tree().create_timer(0.6).timeout.connect(func() -> void:
				get_tree().change_scene_to_file(FALLBACK_SCENE)
			)
		_:
			pass
