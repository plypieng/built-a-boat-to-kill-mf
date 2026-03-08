extends Node

const RUN_SERVER_SCENE := preload("res://scenes/run_server/run_server.tscn")

var _parent_pid := 0

func _ready() -> void:
	var overrides := GameConfig.parse_cmdline_overrides()
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
	if _parent_pid > 0 and not OS.is_process_running(_parent_pid):
		print("Parent process (PID %d) is no longer running. Server terminating to prevent zombie." % _parent_pid)
		get_tree().quit()
