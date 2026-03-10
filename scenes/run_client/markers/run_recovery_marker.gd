@tool
extends Node3D

@export_group("Geometry")
@export_range(0.05, 1.0, 0.01) var ring_height := 0.05:
	set(value):
		ring_height = value
		_apply_geometry()
@export_range(0.05, 1.0, 0.01) var ring_radius := 0.34:
	set(value):
		ring_radius = value
		_apply_geometry()
@export_range(0.2, 2.0, 0.01) var pole_height := 0.95:
	set(value):
		pole_height = value
		_apply_geometry()
@export_range(0.02, 0.2, 0.01) var pole_radius := 0.05:
	set(value):
		pole_radius = value
		_apply_geometry()
@export_range(0.2, 2.5, 0.01) var label_height := 1.18:
	set(value):
		label_height = value
		_apply_geometry()

@onready var ring_mesh: MeshInstance3D = $Ring
@onready var pole_mesh: MeshInstance3D = $Pole
@onready var label: Label3D = $Label

func _ready() -> void:
	_apply_geometry()

func set_marker_text(text: String) -> void:
	if label != null:
		label.text = text

func set_label_visible(is_visible: bool) -> void:
	if label != null:
		label.visible = is_visible

func set_marker_color(color: Color) -> void:
	if ring_mesh != null:
		var ring_material := ring_mesh.material_override as StandardMaterial3D
		if ring_material == null:
			ring_material = StandardMaterial3D.new()
			ring_mesh.material_override = ring_material
		ring_material.albedo_color = Color(color.r, color.g, color.b, 0.74)
		ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring_material.roughness = 0.18
	if pole_mesh != null:
		var pole_material := pole_mesh.material_override as StandardMaterial3D
		if pole_material == null:
			pole_material = StandardMaterial3D.new()
			pole_mesh.material_override = pole_material
		pole_material.albedo_color = color.lightened(0.52)
		pole_material.roughness = 0.42
	if label != null:
		label.modulate = color.lightened(0.24)

func _apply_geometry() -> void:
	if ring_mesh != null:
		var ring_shape := ring_mesh.mesh as CylinderMesh
		if ring_shape == null:
			ring_shape = CylinderMesh.new()
			ring_mesh.mesh = ring_shape
		ring_shape.height = ring_height
		ring_shape.top_radius = ring_radius
		ring_shape.bottom_radius = ring_radius
		ring_mesh.position = Vector3(0.0, ring_height * 0.6, 0.0)
	if pole_mesh != null:
		var pole_shape := pole_mesh.mesh as CylinderMesh
		if pole_shape == null:
			pole_shape = CylinderMesh.new()
			pole_mesh.mesh = pole_shape
		pole_shape.height = pole_height
		pole_shape.top_radius = pole_radius
		pole_shape.bottom_radius = pole_radius
		pole_mesh.position = Vector3(0.0, pole_height * 0.5 + ring_height, 0.0)
	if label != null:
		label.position = Vector3(0.0, label_height, 0.0)
