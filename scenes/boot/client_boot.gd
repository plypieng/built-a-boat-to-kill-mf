extends Control

const RUN_CLIENT_SCENE := "res://scenes/run_client/run_client.tscn"

var host_input: LineEdit
var port_input: LineEdit
var name_input: LineEdit
var connect_button: Button
var status_label: Label

func _ready() -> void:
	_build_ui()
	_populate_defaults()

	NetworkRuntime.status_changed.connect(_on_status_changed)
	NetworkRuntime.connection_ready.connect(_on_connection_ready)
	NetworkRuntime.client_connect_failed.connect(_on_connect_interrupted)
	NetworkRuntime.client_disconnected.connect(_on_connect_interrupted)

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.05, 0.14, 0.24)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 0)
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
	subtitle.text = "Milestone 0 client bootstrap for the local dedicated server flow."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(subtitle)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	layout.add_child(grid)

	grid.add_child(_make_field_label("Host"))
	host_input = LineEdit.new()
	grid.add_child(host_input)

	grid.add_child(_make_field_label("Port"))
	port_input = LineEdit.new()
	grid.add_child(port_input)

	grid.add_child(_make_field_label("Player Name"))
	name_input = LineEdit.new()
	grid.add_child(name_input)

	connect_button = Button.new()
	connect_button.text = "Connect To Local Server"
	connect_button.pressed.connect(_on_connect_pressed)
	layout.add_child(connect_button)

	var instructions := Label.new()
	instructions.text = "Start a headless server with tools/run_server.sh, then connect from this screen."
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(instructions)

	status_label = Label.new()
	status_label.text = "Offline"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(status_label)

func _populate_defaults() -> void:
	var overrides := GameConfig.parse_cmdline_overrides()
	host_input.text = str(overrides["host"])
	port_input.text = str(overrides["port"])
	name_input.text = str(overrides["player_name"])
	status_label.text = "Ready to connect."

func _make_field_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _on_connect_pressed() -> void:
	var host := host_input.text.strip_edges()
	var port := max(1, port_input.text.to_int())
	var player_name := name_input.text.strip_edges()

	connect_button.disabled = true
	var error := NetworkRuntime.start_client(host, port, player_name)
	if error != OK:
		connect_button.disabled = false

func _on_status_changed(message: String) -> void:
	status_label.text = message

func _on_connection_ready() -> void:
	get_tree().change_scene_to_file(RUN_CLIENT_SCENE)

func _on_connect_interrupted() -> void:
	connect_button.disabled = false

