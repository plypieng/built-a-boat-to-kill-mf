extends Control

const HANGAR_SCENE := "res://scenes/hangar/hangar.tscn"
const RUN_CLIENT_SCENE := "res://scenes/run_client/run_client.tscn"
const HOST_CONNECT_RETRY_DELAY := 0.8
const MAX_HOST_CONNECT_RETRIES := 40

@onready var host_input: LineEdit = $Center/Panel/Margin/Layout/FieldsGrid/HostInput
@onready var port_input: LineEdit = $Center/Panel/Margin/Layout/FieldsGrid/PortInput
@onready var name_input: LineEdit = $Center/Panel/Margin/Layout/FieldsGrid/NameInput
@onready var host_button: Button = $Center/Panel/Margin/Layout/ButtonRow/HostButton
@onready var connect_button: Button = $Center/Panel/Margin/Layout/ButtonRow/ConnectButton
@onready var status_label: Label = $Center/Panel/Margin/Layout/StatusLabel
@onready var instructions_label: Label = $Center/Panel/Margin/Layout/InstructionsLabel
@onready var share_label: Label = $Center/Panel/Margin/Layout/ShareLabel

var launch_overrides: Dictionary = {}
var host_start_in_progress := false
var host_retry_pending := false
var host_retry_attempts := 0
var hosted_server_pid := -1
var hosted_lan_ip := "127.0.0.1"

func _ready() -> void:
	launch_overrides = GameConfig.parse_cmdline_overrides()
	host_input.text_changed.connect(_on_connect_fields_changed)
	port_input.text_changed.connect(_on_connect_fields_changed)
	name_input.text_changed.connect(_on_connect_fields_changed)
	host_button.pressed.connect(_on_host_pressed)
	connect_button.pressed.connect(_on_connect_pressed)
	_populate_defaults()

	NetworkRuntime.status_changed.connect(_on_status_changed)
	NetworkRuntime.connection_ready.connect(_on_connection_ready)
	NetworkRuntime.client_connect_failed.connect(_on_connect_interrupted)
	NetworkRuntime.client_disconnected.connect(_on_connect_interrupted)

	if bool(launch_overrides.get("autohost", false)):
		call_deferred("_on_host_pressed")
	elif bool(launch_overrides.get("autoconnect", false)):
		call_deferred("_on_connect_pressed")

func _populate_defaults() -> void:
	host_input.text = str(launch_overrides.get("host", GameConfig.DEFAULT_HOST))
	port_input.text = str(launch_overrides.get("port", GameConfig.DEFAULT_PORT))
	name_input.text = str(launch_overrides.get("player_name", GameConfig.DEFAULT_PLAYER_NAME))
	hosted_lan_ip = _get_preferred_local_ip()
	_refresh_host_help()
	_refresh_buttons()
	status_label.text = "Choose Host Game to launch a local authoritative server, or Join By IP to connect to a friend."

func _on_connect_fields_changed(_value: String) -> void:
	_refresh_host_help()
	_refresh_buttons()

func _refresh_buttons() -> void:
	var has_name := not _get_player_name().is_empty()
	host_button.disabled = host_start_in_progress or not has_name
	connect_button.disabled = host_start_in_progress or not has_name

func _refresh_host_help() -> void:
	instructions_label.text = "Host Game starts a local authoritative server for the crew. Join By IP connects to an existing host. The server stays authoritative either way."
	share_label.text = "Share with friends: %s:%d" % [hosted_lan_ip, _get_port()]

func _get_port() -> int:
	return max(1, port_input.text.strip_edges().to_int())

func _get_player_name() -> String:
	return name_input.text.strip_edges()

func _on_host_pressed() -> void:
	if host_start_in_progress:
		return

	host_start_in_progress = true
	host_retry_pending = false
	host_retry_attempts = 0
	host_input.text = GameConfig.DEFAULT_HOST
	hosted_lan_ip = _get_preferred_local_ip()
	_refresh_host_help()
	_refresh_buttons()

	var launch_error := _launch_local_server(_get_port(), _generate_host_seed())
	if launch_error != OK:
		host_start_in_progress = false
		_refresh_buttons()
		status_label.text = "Could not launch a local authoritative server from this build. Start the server manually and use Join By IP."
		return

	status_label.text = "Starting a local server on 127.0.0.1:%d. Share %s:%d with friends." % [_get_port(), hosted_lan_ip, _get_port()]
	_queue_host_retry()

func _on_connect_pressed() -> void:
	host_start_in_progress = false
	host_retry_pending = false
	_refresh_buttons()
	_attempt_connect()

func _attempt_connect() -> void:
	var host := host_input.text.strip_edges()
	var port := _get_port()
	var player_name := _get_player_name()
	var error := NetworkRuntime.start_client(host, port, player_name)
	if error != OK and not host_start_in_progress:
		_refresh_buttons()

func _queue_host_retry() -> void:
	if host_retry_pending:
		return
	if host_retry_attempts >= MAX_HOST_CONNECT_RETRIES:
		host_start_in_progress = false
		host_retry_pending = false
		_refresh_buttons()
		status_label.text = "The local server did not answer in time. Try Join By IP at 127.0.0.1:%d or restart the host." % _get_port()
		return

	host_retry_pending = true
	get_tree().create_timer(HOST_CONNECT_RETRY_DELAY).timeout.connect(_attempt_host_join)

func _attempt_host_join() -> void:
	host_retry_pending = false
	if not host_start_in_progress:
		return
	host_retry_attempts += 1
	status_label.text = "Local server is starting. Connecting attempt %d/%d..." % [host_retry_attempts, MAX_HOST_CONNECT_RETRIES]
	_attempt_connect()

func _generate_host_seed() -> int:
	var configured_seed := int(launch_overrides.get("seed", GameConfig.DEFAULT_RUN_SEED))
	if configured_seed != GameConfig.DEFAULT_RUN_SEED:
		return configured_seed
	return int(Time.get_unix_time_from_system()) % 1000000

func _launch_local_server(port: int, seed: int) -> int:
	var executable_path := OS.get_executable_path()
	var executable_name := executable_path.get_file().to_lower()
	var project_path := ProjectSettings.globalize_path("res://")
	var candidate_launches: Array = []

	var candidate_server_paths := [
		executable_path.get_base_dir().path_join("BuiltaBoatServer.exe"),
		executable_path.get_base_dir().path_join("server").path_join("BuiltaBoatServer.exe"),
		executable_path.get_base_dir().path_join("run_server.bat"),
		executable_path.get_base_dir().path_join("server").path_join("run_server.bat"),
	]

	for server_path_variant in candidate_server_paths:
		var server_path := str(server_path_variant)
		if not FileAccess.file_exists(server_path):
			continue
		if server_path.get_extension().to_lower() == "bat":
			candidate_launches.append({
				"path": "cmd.exe",
				"args": PackedStringArray(["/c", server_path, "--port=%d" % port, "--seed=%d" % seed]),
				"open_console": true,
			})
		else:
			candidate_launches.append({
				"path": server_path,
				"args": PackedStringArray(["--server", "--port=%d" % port, "--seed=%d" % seed]),
				"open_console": true,
			})

	var my_pid := OS.get_process_id()
	
	if executable_name.contains("godot"):
		candidate_launches.push_front({
			"path": executable_path,
			"args": PackedStringArray(["--path", project_path, "--headless", "--", "--server", "--port=%d" % port, "--seed=%d" % seed, "--parent-pid=%d" % my_pid]),
			"open_console": false,
		})
		var script_path := ProjectSettings.globalize_path("res://tools/run_server.sh")
		if FileAccess.file_exists(script_path):
			candidate_launches.append({
				"path": script_path,
				"args": PackedStringArray(["--port=%d" % port, "--seed=%d" % seed]),
				"open_console": true,
			})
	else:
		candidate_launches.append({
			"path": executable_path,
			"args": PackedStringArray(["--headless", "--server", "--port=%d" % port, "--seed=%d" % seed, "--parent-pid=%d" % my_pid]),
			"open_console": true,
		})

	for candidate_variant in candidate_launches:
		var candidate: Dictionary = candidate_variant
		var pid := OS.create_process(
			str(candidate.get("path", "")),
			PackedStringArray(candidate.get("args", PackedStringArray())),
			bool(candidate.get("open_console", false))
		)
		if pid != -1:
			hosted_server_pid = pid
			return OK

	return FAILED

func _get_preferred_local_ip() -> String:
	for address_variant in IP.get_local_addresses():
		var address := str(address_variant)
		if address.is_empty():
			continue
		if address.begins_with("127.") or address == "::1":
			continue
		if address.contains(":"):
			continue
		return address
	return "127.0.0.1"

func _on_status_changed(message: String) -> void:
	status_label.text = message

func _on_connection_ready() -> void:
	host_start_in_progress = false
	host_retry_pending = false
	var target_scene := HANGAR_SCENE if NetworkRuntime.get_session_phase() == NetworkRuntime.SESSION_PHASE_HANGAR else RUN_CLIENT_SCENE
	get_tree().change_scene_to_file(target_scene)

func _on_connect_interrupted() -> void:
	if host_start_in_progress:
		_queue_host_retry()
		return
	_refresh_buttons()
