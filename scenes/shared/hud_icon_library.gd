extends RefCounted

const DEFAULT_ICON_ID := "cargo"
const DEFAULT_ICON_SIZE := Vector2(26.0, 26.0)
const GENERATED_ICON_DIRS := [
	"res://assets/generated/hud-icons-ai",
	"res://assets/generated/hud-icons",
]
const SVG_ICON_DIR := "res://assets/ui/icons"

var icon_cache: Dictionary = {}

func add_section_header(
	parent: Container,
	title: String,
	icon_id: String,
	font_size: int = 14,
	label_color: Color = Color(0.96, 0.95, 0.90),
	icon_size: Vector2 = DEFAULT_ICON_SIZE
) -> TextureRect:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var icon := make_icon_rect(icon_id, icon_size)
	row.add_child(icon)

	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", font_size)
	label.modulate = label_color
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	return icon

func make_icon_rect(icon_id: String, size: Vector2 = DEFAULT_ICON_SIZE) -> TextureRect:
	var icon := TextureRect.new()
	configure_icon_rect(icon, size)
	set_icon(icon, icon_id)
	return icon

func configure_icon_rect(icon_rect: TextureRect, size: Vector2 = DEFAULT_ICON_SIZE) -> void:
	if icon_rect == null:
		return
	icon_rect.custom_minimum_size = size
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_icon(icon_rect: TextureRect, icon_id: String) -> void:
	if icon_rect == null:
		return
	var texture := load_icon(icon_id)
	icon_rect.texture = texture
	icon_rect.visible = texture != null

func load_icon(icon_id: String) -> Texture2D:
	var normalized_icon_id := _normalize_icon_id(icon_id)
	if icon_cache.has(normalized_icon_id):
		return icon_cache[normalized_icon_id] as Texture2D

	var texture: Texture2D = null
	for candidate_path in _build_candidate_paths(normalized_icon_id):
		if ResourceLoader.exists(candidate_path):
			texture = load(candidate_path) as Texture2D
			if texture != null:
				break

	icon_cache[normalized_icon_id] = texture
	return texture

func get_block_icon_id(block_id: String) -> String:
	match block_id.strip_edges().to_lower():
		"core", "hull", "reinforced_hull", "structure":
			return "reinforced-hull"
		"engine", "twin_engine":
			return "twin-engine"
		"cargo":
			return "cargo"
		"utility":
			return "repair-kit"
		"stabilizer":
			return "stabilizer"
		"helm":
			return "helm"
		"brace":
			return "brace"
		"gold":
			return "gold"
		"salvage":
			return "salvage"
		"extraction":
			return "extraction"
		_:
			return DEFAULT_ICON_ID

func _normalize_icon_id(icon_id: String) -> String:
	var normalized := icon_id.strip_edges().to_lower()
	if normalized.is_empty():
		return DEFAULT_ICON_ID
	return normalized

func _build_candidate_paths(icon_id: String) -> Array[String]:
	var normalized_icon_id := _normalize_icon_id(icon_id)
	var paths: Array[String] = []
	for generated_dir in GENERATED_ICON_DIRS:
		paths.append("%s/%s.png" % [generated_dir, normalized_icon_id])
	paths.append("%s/%s.svg" % [SVG_ICON_DIR, normalized_icon_id])
	if normalized_icon_id != DEFAULT_ICON_ID:
		paths.append("%s/%s.svg" % [SVG_ICON_DIR, DEFAULT_ICON_ID])
	return paths
