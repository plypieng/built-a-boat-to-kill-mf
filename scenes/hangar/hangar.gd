extends Control

const CLIENT_BOOT_SCENE := "res://scenes/boot/client_boot.tscn"

var totals_label: Label
var last_run_label: Label

func _ready() -> void:
	if NetworkRuntime.get_mode_name() != "offline":
		NetworkRuntime.shutdown()

	_build_ui()
	_refresh_labels()
	DockState.profile_changed.connect(_on_profile_changed)
	print("Hangar ready: gold=%d salvage=%d runs=%d" % [
		DockState.get_total_gold(),
		DockState.get_total_salvage(),
		DockState.get_total_runs(),
	])

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.05, 0.10, 0.14)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(680.0, 0.0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "Dock Hangar"
	title.add_theme_font_size_override("font_size", 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Prototype post-run handoff. Extracted rewards are now banked locally here."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(subtitle)

	totals_label = Label.new()
	totals_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(totals_label)

	last_run_label = Label.new()
	last_run_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(last_run_label)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	layout.add_child(actions)

	var reconnect_button := Button.new()
	reconnect_button.text = "Return To Connect Screen"
	reconnect_button.pressed.connect(_on_return_to_connect_pressed)
	actions.add_child(reconnect_button)

	var quit_button := Button.new()
	quit_button.text = "Quit"
	quit_button.pressed.connect(_on_quit_pressed)
	actions.add_child(quit_button)

	var hint := Label.new()
	hint.text = "Next step: spin up a dedicated server, connect a crew, and launch another run."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(hint)

func _refresh_labels() -> void:
	var total_runs := DockState.get_total_runs()
	var successful_runs := DockState.get_successful_runs()
	var extraction_rate := 0.0
	if total_runs > 0:
		extraction_rate = float(successful_runs) / float(total_runs) * 100.0

	totals_label.text = "Dock Totals\nGold: %d\nSalvage: %d\nRuns: %d\nSuccessful Extractions: %d (%.0f%%)" % [
		DockState.get_total_gold(),
		DockState.get_total_salvage(),
		total_runs,
		successful_runs,
		extraction_rate,
	]

	var last_run := DockState.get_last_run()
	if last_run.is_empty():
		last_run_label.text = "Last Run\nNo runs recorded yet."
		return

	last_run_label.text = "Last Run\n%s\n%s\nSeed: %d | Gold: %d | Salvage: %d | Cargo Secured: %d | Cargo Lost: %d | Repairs: %d | Cache Recovered: %s | Supplies Left: %d\nRecorded: %s" % [
		str(last_run.get("title", "Run Complete")),
		str(last_run.get("message", "")),
		int(last_run.get("seed", 0)),
		int(last_run.get("reward_gold", 0)),
		int(last_run.get("reward_salvage", 0)),
		int(last_run.get("cargo_secured", 0)),
		int(last_run.get("cargo_lost", 0)),
		int(last_run.get("repair_actions", 0)),
		"yes" if bool(last_run.get("cache_recovered", false)) else "no",
		int(last_run.get("repair_supplies_left", 0)),
		str(last_run.get("timestamp", "")),
	]

func _on_profile_changed(_snapshot: Dictionary) -> void:
	_refresh_labels()

func _on_return_to_connect_pressed() -> void:
	get_tree().change_scene_to_file(CLIENT_BOOT_SCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()
