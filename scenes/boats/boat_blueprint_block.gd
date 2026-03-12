@tool
class_name BoatBlueprintBlock
extends MeshInstance3D

const DEFAULT_BLOCK_TYPE := "structure"
const PREVIEW_SIZE := Vector3(1.08, 1.08, 1.08)
const BLOCK_PREVIEW_COLORS := {
	"core": Color(0.92, 0.77, 0.34),
	"hull": Color(0.31, 0.56, 0.78),
	"deck_plate": Color(0.56, 0.54, 0.50),
	"engine": Color(0.70, 0.40, 0.26),
	"light_crane": Color(0.82, 0.60, 0.30),
	"ladder_rig": Color(0.40, 0.72, 0.58),
	"cargo": Color(0.54, 0.46, 0.30),
	"utility": Color(0.58, 0.62, 0.72),
	"structure": Color(0.70, 0.70, 0.72),
}

@export var block_id: int = 0:
	set(value):
		block_id = maxi(0, value)
		_refresh_editor_name()

@export var block_type: String = DEFAULT_BLOCK_TYPE:
	set(value):
		var normalized := value.strip_edges().to_lower()
		block_type = normalized if not normalized.is_empty() else DEFAULT_BLOCK_TYPE
		_refresh_preview_material()
		_refresh_editor_name()

@export_range(0, 3, 1) var rotation_steps: int = 0:
	set(value):
		rotation_steps = wrapi(value, 0, 4)
		_apply_rotation_steps()
		_refresh_editor_name()

var _syncing_rotation := false

func _enter_tree() -> void:
	_ensure_preview_mesh()
	_sync_rotation_steps_from_transform()
	_refresh_preview_material()
	_refresh_editor_name()

func _ready() -> void:
	_ensure_preview_mesh()
	_refresh_preview_material()
	_refresh_editor_name()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and Engine.is_editor_hint():
		_sync_rotation_steps_from_transform()

func get_blueprint_cell(cell_size: float) -> Array:
	var safe_cell_size := maxf(0.01, cell_size)
	return [
		roundi(position.x / safe_cell_size),
		roundi(position.y / safe_cell_size),
		roundi(position.z / safe_cell_size),
	]

func get_blueprint_rotation_steps() -> int:
	var quarter_turns := int(round(rad_to_deg(rotation.y) / 90.0))
	return wrapi(quarter_turns, 0, 4)

func configure_from_blueprint(block: Dictionary, cell_size: float) -> void:
	var cell := _normalize_cell(block.get("cell", [0, 0, 0]))
	block_id = int(block.get("id", 0))
	block_type = str(block.get("type", DEFAULT_BLOCK_TYPE))
	position = Vector3(cell) * maxf(0.01, cell_size)
	rotation_steps = int(block.get("rotation_steps", 0))
	_refresh_preview_material()
	_refresh_editor_name()

func _ensure_preview_mesh() -> void:
	if mesh == null or not (mesh is BoxMesh):
		var preview_mesh := BoxMesh.new()
		preview_mesh.size = PREVIEW_SIZE
		mesh = preview_mesh
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

func _apply_rotation_steps() -> void:
	_syncing_rotation = true
	rotation_degrees.y = float(rotation_steps * 90)
	_syncing_rotation = false

func _sync_rotation_steps_from_transform() -> void:
	if _syncing_rotation:
		return
	var snapped_steps := get_blueprint_rotation_steps()
	if snapped_steps == rotation_steps:
		return
	rotation_steps = snapped_steps

func _refresh_preview_material() -> void:
	_ensure_preview_mesh()
	var preview_material := material_override as StandardMaterial3D
	if preview_material == null:
		preview_material = StandardMaterial3D.new()
	preview_material.albedo_color = _resolve_preview_color()
	preview_material.roughness = 0.62
	preview_material.metallic = 0.04
	preview_material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	material_override = preview_material

func _refresh_editor_name() -> void:
	var label := block_type if not block_type.is_empty() else DEFAULT_BLOCK_TYPE
	name = "%03d_%s" % [block_id, label]

func _resolve_preview_color() -> Color:
	if BLOCK_PREVIEW_COLORS.has(block_type):
		return BLOCK_PREVIEW_COLORS[block_type]
	var hue := fposmod(float(abs(block_type.hash()) % 1000) / 1000.0, 1.0)
	return Color.from_hsv(hue, 0.42, 0.84)

func _normalize_cell(cell_value: Variant) -> Vector3i:
	if cell_value is Vector3i:
		return cell_value as Vector3i
	if typeof(cell_value) == TYPE_ARRAY and cell_value.size() >= 3:
		return Vector3i(int(cell_value[0]), int(cell_value[1]), int(cell_value[2]))
	if typeof(cell_value) == TYPE_DICTIONARY:
		return Vector3i(
			int(cell_value.get("x", 0)),
			int(cell_value.get("y", 0)),
			int(cell_value.get("z", 0))
		)
	return Vector3i.ZERO
