extends Node

const RUN_SERVER_SCENE := preload("res://scenes/run_server/run_server.tscn")
const PARENT_PID_VERIFY_GRACE_SECONDS := 3.0
const PARENT_PID_EXIT_GRACE_SECONDS := 1.0

var _parent_pid := 0
var _parent_pid_verified := false
var _parent_pid_missing_seconds := 0.0
var _parent_pid_guard_disabled := false

func _ready() -> void:
	var overrides := GameConfig.parse_cmdline_overrides()
	if bool(overrides.get("editor_clean_blueprint", false)):
		DockState.use_default_boat_blueprint_runtime()
	var port := int(overrides["port"])
	var seed := int(overrides["seed"])
	_parent_pid = int(overrides.get("parent_pid", 0))
	var error := NetworkRuntime.start_server(port, seed)
	if error != OK:
		push_error("Server bootstrap failed with code %s." % str(error))
		get_tree().quit(error)
		return

	add_child(RUN_SERVER_SCENE.instantiate())

func _process(_delta: float) -> void:
	if _parent_pid <= 0 or _parent_pid_guard_disabled:
		return

	if OS.is_process_running(_parent_pid):
		_parent_pid_verified = true
		_parent_pid_missing_seconds = 0.0
		return

	_parent_pid_missing_seconds += _delta
	if not _parent_pid_verified:
		if _parent_pid_missing_seconds >= PARENT_PID_VERIFY_GRACE_SECONDS:
			print("Parent process (PID %d) could not be verified. Disabling the parent watchdog for this server process." % _parent_pid)
			_parent_pid_guard_disabled = true
		return

	if _parent_pid_missing_seconds < PARENT_PID_EXIT_GRACE_SECONDS:
		return

	print("Parent process (PID %d) is no longer running. Server terminating to prevent zombie." % _parent_pid)
	get_tree().quit()
