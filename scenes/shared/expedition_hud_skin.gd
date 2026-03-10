extends RefCounted

const CHART_CREAM := Color(0.96, 0.93, 0.85, 1.0)
const STORM_PANEL := Color(0.05, 0.08, 0.10, 0.88)
const STORM_PANEL_SOFT := Color(0.09, 0.13, 0.15, 0.78)
const HANGAR_PANEL := Color(0.11, 0.11, 0.09, 0.84)
const HANGAR_PANEL_SOFT := Color(0.15, 0.13, 0.10, 0.74)
const OXIDIZED_TEAL := Color(0.28, 0.60, 0.60, 0.98)
const SEA_GLASS_GREEN := Color(0.35, 0.75, 0.60, 0.98)
const BUOY_ORANGE := Color(0.88, 0.60, 0.26, 0.98)
const FLARE_RED := Color(0.80, 0.33, 0.26, 0.98)
const BRASS_YELLOW := Color(0.84, 0.75, 0.39, 0.98)
const RUST_BROWN := Color(0.23, 0.13, 0.09, 0.98)
const TEXT_PRIMARY := CHART_CREAM
const TEXT_MUTED := Color(0.74, 0.82, 0.82, 1.0)
const TEXT_WARNING := Color(0.95, 0.82, 0.47, 1.0)
const TEXT_DANGER := Color(0.96, 0.58, 0.48, 1.0)
const TEXT_SUCCESS := Color(0.78, 0.94, 0.82, 1.0)
const TEXT_OUTLINE := Color(0.02, 0.03, 0.04, 0.94)

static func apply_plate(
	panel: PanelContainer,
	accent_color: Color,
	background_color: Color = STORM_PANEL,
	variant: String = "plate"
) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", _make_panel_stylebox(accent_color, background_color, variant))

static func apply_button(
	button: BaseButton,
	accent_color: Color,
	fill_color: Color = RUST_BROWN
) -> void:
	_apply_button_style(button, accent_color, fill_color, false)

static func apply_compact_button(
	button: BaseButton,
	accent_color: Color,
	fill_color: Color = RUST_BROWN
) -> void:
	_apply_button_style(button, accent_color, fill_color, true)

static func _apply_button_style(
	button: BaseButton,
	accent_color: Color,
	fill_color: Color,
	compact: bool
) -> void:
	if button == null:
		return
	var normal := _make_button_stylebox(fill_color.lerp(STORM_PANEL, 0.18), accent_color, compact)
	var hover := _make_button_stylebox(fill_color.lightened(0.10), accent_color.lightened(0.08), compact)
	var pressed := _make_button_stylebox(fill_color.darkened(0.14), accent_color, compact)
	var disabled := _make_button_stylebox(fill_color.darkened(0.28), accent_color.darkened(0.28), compact)
	var focus := _make_focus_stylebox(accent_color)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", TEXT_PRIMARY)
	button.add_theme_color_override("font_hover_color", TEXT_PRIMARY)
	button.add_theme_color_override("font_pressed_color", TEXT_PRIMARY)
	button.add_theme_color_override("font_disabled_color", TEXT_MUTED.darkened(0.28))
	button.add_theme_color_override("font_outline_color", TEXT_OUTLINE)
	button.add_theme_constant_override("outline_size", 1)
	button.custom_minimum_size = Vector2(button.custom_minimum_size.x, maxf(button.custom_minimum_size.y, 30.0 if compact else 38.0))

static func apply_item_list(
	item_list: ItemList,
	accent_color: Color,
	background_color: Color = STORM_PANEL_SOFT
) -> void:
	if item_list == null:
		return
	item_list.add_theme_stylebox_override("panel", _make_panel_stylebox(accent_color, background_color, "list"))
	item_list.add_theme_stylebox_override("focus", _make_focus_stylebox(accent_color))
	var selected := StyleBoxFlat.new()
	selected.bg_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.22)
	selected.border_color = accent_color
	selected.set_border_width_all(2)
	selected.corner_radius_top_left = 8
	selected.corner_radius_top_right = 8
	selected.corner_radius_bottom_left = 8
	selected.corner_radius_bottom_right = 8
	item_list.add_theme_stylebox_override("selected", selected)
	item_list.add_theme_stylebox_override("cursor", selected)
	item_list.add_theme_color_override("font_color", TEXT_PRIMARY)
	item_list.add_theme_color_override("font_hovered_color", TEXT_PRIMARY)
	item_list.add_theme_color_override("font_selected_color", TEXT_PRIMARY)
	item_list.add_theme_color_override("guide_color", TEXT_MUTED)
	item_list.add_theme_color_override("font_outline_color", TEXT_OUTLINE)
	item_list.add_theme_constant_override("outline_size", 1)

static func apply_meter(
	bar: ProgressBar,
	fill_color: Color,
	background_color: Color = STORM_PANEL_SOFT
) -> void:
	if bar == null:
		return
	bar.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = background_color
	background.border_color = Color(0.03, 0.05, 0.06, 0.92)
	background.set_border_width_all(1)
	background.corner_radius_top_left = 9
	background.corner_radius_top_right = 9
	background.corner_radius_bottom_left = 9
	background.corner_radius_bottom_right = 9
	bar.add_theme_stylebox_override("background", background)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.corner_radius_top_left = 9
	fill.corner_radius_top_right = 9
	fill.corner_radius_bottom_left = 9
	fill.corner_radius_bottom_right = 9
	bar.add_theme_stylebox_override("fill", fill)

static func apply_hotbar_slot(
	panel: PanelContainer,
	accent_color: Color,
	active: bool = false,
	occupied: bool = false
) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", _make_hotbar_slot_stylebox(accent_color, active, occupied))

static func apply_heading(label: Label, color: Color = TEXT_PRIMARY) -> void:
	_apply_label(label, color, 2)

static func apply_body(label: Label, color: Color = TEXT_PRIMARY) -> void:
	_apply_label(label, color, 1)

static func apply_muted(label: Label) -> void:
	_apply_label(label, TEXT_MUTED, 1)

static func apply_crosshair(label: Label) -> void:
	_apply_label(label, CHART_CREAM, 2)

static func apply_callout(label: Label, color: Color = TEXT_PRIMARY) -> void:
	_apply_label(label, color, 2)

static func _apply_label(label: Label, color: Color, outline_size: int) -> void:
	if label == null:
		return
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", TEXT_OUTLINE)
	label.add_theme_constant_override("outline_size", outline_size)

static func _make_panel_stylebox(accent_color: Color, background_color: Color, variant: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = accent_color
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.34)
	style.shadow_size = 9
	style.set_border_width_all(2)
	match variant:
		"ghost":
			style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
			style.border_color = Color(0.0, 0.0, 0.0, 0.0)
			style.shadow_color = Color(0.0, 0.0, 0.0, 0.0)
			style.shadow_size = 0
			style.set_border_width_all(0)
			style.corner_radius_top_left = 0
			style.corner_radius_top_right = 0
			style.corner_radius_bottom_left = 0
			style.corner_radius_bottom_right = 0
		"scrim":
			style.bg_color = Color(0.03, 0.05, 0.07, 0.32)
			style.border_color = Color(0.0, 0.0, 0.0, 0.0)
			style.shadow_color = Color(0.0, 0.0, 0.0, 0.18)
			style.shadow_size = 3
			style.set_border_width_all(0)
			style.corner_radius_top_left = 12
			style.corner_radius_top_right = 12
			style.corner_radius_bottom_left = 12
			style.corner_radius_bottom_right = 12
		"minimal_strip":
			style.bg_color = Color(background_color.r, background_color.g, background_color.b, 0.18)
			style.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.32)
			style.shadow_color = Color(0.0, 0.0, 0.0, 0.16)
			style.shadow_size = 4
			style.set_border_width_all(1)
			style.corner_radius_top_left = 10
			style.corner_radius_top_right = 10
			style.corner_radius_bottom_left = 10
			style.corner_radius_bottom_right = 10
		"banner":
			style.corner_radius_top_left = 18
			style.corner_radius_top_right = 6
			style.corner_radius_bottom_left = 6
			style.corner_radius_bottom_right = 18
		"ledger":
			style.corner_radius_top_left = 22
			style.corner_radius_top_right = 10
			style.corner_radius_bottom_left = 10
			style.corner_radius_bottom_right = 24
		"manifest":
			style.corner_radius_top_left = 28
			style.corner_radius_top_right = 8
			style.corner_radius_bottom_left = 10
			style.corner_radius_bottom_right = 28
		"list":
			style.corner_radius_top_left = 10
			style.corner_radius_top_right = 10
			style.corner_radius_bottom_left = 10
			style.corner_radius_bottom_right = 10
		_:
			style.corner_radius_top_left = 18
			style.corner_radius_top_right = 12
			style.corner_radius_bottom_left = 8
			style.corner_radius_bottom_right = 20
	return style

static func _make_button_stylebox(fill_color: Color, accent_color: Color, compact: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = accent_color
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8 if compact else 12
	style.corner_radius_top_right = 5 if compact else 6
	style.corner_radius_bottom_left = 5 if compact else 6
	style.corner_radius_bottom_right = 8 if compact else 12
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.26)
	style.shadow_size = 2 if compact else 4
	style.content_margin_left = 10 if compact else 14
	style.content_margin_right = 10 if compact else 14
	style.content_margin_top = 6 if compact else 10
	style.content_margin_bottom = 6 if compact else 10
	return style

static func _make_hotbar_slot_stylebox(accent_color: Color, active: bool, occupied: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var fill_color := Color(0.05, 0.07, 0.08, 0.30)
	var border_color := Color(0.88, 0.92, 0.94, 0.20)
	var shadow_alpha := 0.10
	if occupied:
		fill_color = Color(SEA_GLASS_GREEN.r, SEA_GLASS_GREEN.g, SEA_GLASS_GREEN.b, 0.18)
		border_color = Color(SEA_GLASS_GREEN.r, SEA_GLASS_GREEN.g, SEA_GLASS_GREEN.b, 0.42)
	if active:
		fill_color = Color(0.39, 0.64, 0.92, 0.74)
		border_color = Color(0.84, 0.93, 1.0, 0.92)
		shadow_alpha = 0.18
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(2 if active else 1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0.0, 0.0, 0.0, shadow_alpha)
	style.shadow_size = 3 if active else 1
	return style

static func _make_focus_stylebox(accent_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.70)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 14
	style.expand_margin_left = 2.0
	style.expand_margin_right = 2.0
	style.expand_margin_top = 2.0
	style.expand_margin_bottom = 2.0
	return style
