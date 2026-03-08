extends Control

const HANGAR_SCENE := "res://scenes/hangar/hangar.tscn"
const RUN_CLIENT_SCENE := "res://scenes/run_client/run_client.tscn"
const HOST_CONNECT_RETRY_DELAY := 0.8
const MAX_HOST_CONNECT_RETRIES := 8

var host_input: LineEdit
var port_input: LineEdit
var name_input: LineEdit
var host_button: Button
var connect_button: Button
var status_label: Label
var instructions_label: Label
var share_label: Label
var launch_overrides: Dictionary = {}
var host_start_in_progress := false
var host_retry_pending := false
var host_retry_attempts := 0
var hosted_server_pid := -1
var hosted_lan_ip := "127.0.0.1"

func _ready() -> void:
	launch_overrides = GameConfig.parse_cmdline_overrides()
	_build_ui()
	_populate_defaults()

	NetworkRuntime.status_changed.connect(_on_status_changed)
	NetworkRuntime.connection_ready.connect(_on_connection_ready)
	NetworkRuntime.client_connect_failed.connect(_on_connect_interrupted)
	NetworkRuntime.client_disconnected.connect(_on_connect_interrupted)

	if bool(launch_overrides.get("autohost", false)):
		call_deferred("_on_host_pressed")
	elif bool(launch_overrides.get("autoconnect", false)):
		call_deferred("_on_connect_pressed")

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.05, 0.14, 0.24)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "BuiltaBoat"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Host or join an authoritative server, co-build the crew boat, and push for extraction before the sea takes everything."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(subtitle)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	layout.add_child(grid)

	grid.add_child(_make_field_label("Server IP"))
	host_input = LineEdit.new()
	host_input.text_changed.connect(_on_connect_fields_changed)
	grid.add_child(host_input)

	grid.add_child(_make_field_label("Port"))
	port_input = LineEdit.new()
	port_input.text_changed.connect(_on_connect_fields_changed)
	grid.add_child(port_input)

	grid.add_child(_make_field_label("Player Name"))
	name_input = LineEdit.new()
	name_input.text_changed.connect(_on_connect_fields_changed)
	grid.add_child(name_input)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)
	layout.add_child(button_row)

	host_button = Button.new()
	host_button.text = "Host Game"
	host_button.pressed.connect(_on_host_pressed)
	button_row.add_child(host_button)

	connect_button = Button.new()
	connect_button.text = "Join By IP"
	connect_button.pressed.connect(_on_connect_pressed)
	button_row.add_child(connect_button)

	instructions_label = Label.new()
	instructions_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(instructions_label)

	share_label = Label.new()
	share_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	share_label.modulate = Color(0.85, 0.94, 1.0)
	layout.add_child(share_label)

	status_label = Label.new()
	status_label.text = "Offline"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(status_label)

func _populate_defaults() -> void:
	host_input.text = str(launch_overrides.get("host", GameConfig.DEFAULT_HOST))
	port_input.text = str(launch_overrides.get("port", GameConfig.DEFAULT_PORT))
	name_input.text = str(launch_overrides.get("player_name", GameConfig.DEFAULT_PLAYER_NAME))
	hosted_lan_ip = _get_preferred_local_ip()
	_refresh_host_help()
	_refresh_buttons()
	status_label.text = "Choose Host Game to launch a local authoritative server, or Join By IP to connect to a friend."

func _make_field_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

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

	if executable_name.contains("godot"):
		candidate_launches.append({
			"path": executable_path,
			"args": PackedStringArray(["--path", project_path, "--headless", "--", "--server", "--port=%d" % port, "--seed=%d" % seed]),
			"open_console": true,
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
			"args": PackedStringArray(["--headless", "--server", "--port=%d" % port, "--seed=%d" % seed]),
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
