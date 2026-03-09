@tool
extends Node3D

@export_group("Geometry")
@export_range(0.05, 1.0, 0.01) var base_height := 0.12:
	set(value):
		base_height = value
		_apply_geometry()
@export_range(0.05, 1.0, 0.01) var base_top_radius := 0.24:
	set(value):
		base_top_radius = value
		_apply_geometry()
@export_range(0.05, 1.0, 0.01) var base_bottom_radius := 0.28:
	set(value):
		base_bottom_radius = value
		_apply_geometry()
@export_range(0.05, 1.0, 0.01) var beacon_radius := 0.18:
	set(value):
		beacon_radius = value
		_apply_geometry()
@export_range(0.2, 2.0, 0.01) var label_height := 0.92:
	set(value):
		label_height = value
		_apply_geometry()

@onready var base_mesh: MeshInstance3D = $Base
@onready var beacon_mesh: MeshInstance3D = $Beacon
@onready var label: Label3D = $Label

func _ready() -> void:
	_apply_geometry()

func set_marker_text(text: String) -> void:
	if label != null:
		label.text = text

func set_marker_color(color: Color) -> void:
	if base_mesh != null:
		var base_material := base_mesh.material_override as StandardMaterial3D
		if base_material == null:
			base_material = StandardMaterial3D.new()
			base_mesh.material_override = base_material
		base_material.albedo_color = color.darkened(0.08)
		base_material.roughness = 0.24
	if beacon_mesh != null:
		var beacon_material := beacon_mesh.material_override as StandardMaterial3D
		if beacon_material == null:
			beacon_material = StandardMaterial3D.new()
			beacon_mesh.material_override = beacon_material
		beacon_material.albedo_color = color
		beacon_material.roughness = 0.16
	if label != null:
		label.modulate = color.lightened(0.22)

func _apply_geometry() -> void:
	if base_mesh != null:
		var base_shape := base_mesh.mesh as CylinderMesh
		if base_shape == null:
			base_shape = CylinderMesh.new()
			base_mesh.mesh = base_shape
		base_shape.height = base_height
		base_shape.top_radius = base_top_radius
		base_shape.bottom_radius = base_bottom_radius
		base_mesh.position = Vector3(0.0, base_height * 0.5, 0.0)
	if beacon_mesh != null:
		var beacon_shape := beacon_mesh.mesh as SphereMesh
		if beacon_shape == null:
			beacon_shape = SphereMesh.new()
			beacon_mesh.mesh = beacon_shape
		beacon_shape.radius = beacon_radius
		beacon_shape.height = beacon_radius * 2.0
		beacon_mesh.position = Vector3(0.0, base_height + beacon_radius + 0.04, 0.0)
	if label != null:
		label.position = Vector3(0.0, label_height, 0.0)
