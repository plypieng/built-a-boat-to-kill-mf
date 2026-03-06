extends Node

const RUN_SERVER_SCENE := preload("res://scenes/run_server/run_server.tscn")

func _ready() -> void:
	var overrides := GameConfig.parse_cmdline_overrides()
	var port := int(overrides["port"])
	var seed := int(overrides["seed"])
	var error := NetworkRuntime.start_server(port, seed)
	if error != OK:
		push_error("Server bootstrap failed with code %s." % str(error))
		get_tree().quit(error)
		return

	add_child(RUN_SERVER_SCENE.instantiate())

