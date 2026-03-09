@tool
extends Node3D

const KIND_WRECK := "wreck"
const KIND_DISTRESS := "distress"
const KIND_CRATE := "crate"
const KIND_OUTPOST := "outpost"

@export_enum("wreck", "distress", "crate", "outpost") var default_body_kind := KIND_WRECK:
	set(value):
		default_body_kind = value
		_apply_body_kind()

@onready var ring_mesh_instance: MeshInstance3D = $Ring
@onready var body_mesh_instance: MeshInstance3D = $Body
@onready var accent_mesh_instance: MeshInstance3D = $Accent
@onready var label: Label3D = $Label

func _ready() -> void:
	_apply_body_kind()

func set_ring_radius(radius: float) -> void:
	var ring_mesh := ring_mesh_instance.mesh as CylinderMesh
	if ring_mesh == null:
		ring_mesh = CylinderMesh.new()
		ring_mesh_instance.mesh = ring_mesh
	ring_mesh.height = 0.08
	ring_mesh.top_radius = radius
	ring_mesh.bottom_radius = radius
	ring_mesh_instance.position = Vector3(0.0, 0.05, 0.0)

func set_ring_color(color: Color) -> void:
	var material := ring_mesh_instance.material_override as StandardMaterial3D
	if material == null:
		material = StandardMaterial3D.new()
		ring_mesh_instance.material_override = material
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.2

func set_body_color(color: Color) -> void:
	for mesh_instance in [body_mesh_instance, accent_mesh_instance]:
		if mesh_instance == null or not mesh_instance.visible:
			continue
		var material := mesh_instance.material_override as StandardMaterial3D
		if material == null:
			material = StandardMaterial3D.new()
			mesh_instance.material_override = material
		material.albedo_color = color
		material.roughness = 0.28

func set_label_text(text: String) -> void:
	if label != null:
		label.text = text

func set_label_color(color: Color) -> void:
	if label != null:
		label.modulate = color

func set_body_kind(kind: String) -> void:
	default_body_kind = kind
	_apply_body_kind()

func _apply_body_kind() -> void:
	if body_mesh_instance == null or accent_mesh_instance == null or label == null:
		return
	match default_body_kind:
		KIND_DISTRESS:
			var raft_mesh := BoxMesh.new()
			raft_mesh.size = Vector3(1.4, 0.32, 1.0)
			body_mesh_instance.mesh = raft_mesh
			body_mesh_instance.position = Vector3(0.0, 0.38, 0.0)

			var flare_mesh := CylinderMesh.new()
			flare_mesh.height = 1.6
			flare_mesh.top_radius = 0.09
			flare_mesh.bottom_radius = 0.11
			accent_mesh_instance.mesh = flare_mesh
			accent_mesh_instance.position = Vector3(0.0, 1.45, 0.0)
			accent_mesh_instance.visible = true
			label.position = Vector3(0.0, 3.0, 0.0)
		KIND_CRATE:
			var crate_mesh := BoxMesh.new()
			crate_mesh.size = Vector3(0.95, 0.72, 0.95)
			body_mesh_instance.mesh = crate_mesh
			body_mesh_instance.position = Vector3(0.0, 0.55, 0.0)

			var beacon_mesh := CylinderMesh.new()
			beacon_mesh.height = 1.9
			beacon_mesh.top_radius = 0.12
			beacon_mesh.bottom_radius = 0.18
			accent_mesh_instance.mesh = beacon_mesh
			accent_mesh_instance.position = Vector3(0.0, 1.85, 0.0)
			accent_mesh_instance.visible = true
			label.position = Vector3(0.0, 3.0, 0.0)
		KIND_OUTPOST:
			var outpost_mesh := CylinderMesh.new()
			outpost_mesh.height = 2.2
			outpost_mesh.top_radius = 0.95
			outpost_mesh.bottom_radius = 1.2
			body_mesh_instance.mesh = outpost_mesh
			body_mesh_instance.position = Vector3(0.0, 1.1, 0.0)

			var cap_mesh := SphereMesh.new()
			cap_mesh.radius = 0.32
			cap_mesh.height = 0.64
			accent_mesh_instance.mesh = cap_mesh
			accent_mesh_instance.position = Vector3(0.0, 2.55, 0.0)
			accent_mesh_instance.visible = true
			label.position = Vector3(0.0, 3.35, 0.0)
		_:
			var hull_mesh := BoxMesh.new()
			hull_mesh.size = Vector3(1.1, 0.75, 1.8)
			body_mesh_instance.mesh = hull_mesh
			body_mesh_instance.position = Vector3(0.0, 0.55, 0.0)

			var mast_mesh := CylinderMesh.new()
			mast_mesh.height = 1.0
			mast_mesh.top_radius = 0.08
			mast_mesh.bottom_radius = 0.08
			accent_mesh_instance.mesh = mast_mesh
			accent_mesh_instance.position = Vector3(0.0, 1.32, -0.18)
			accent_mesh_instance.visible = true
			label.position = Vector3(0.0, 1.7, 0.0)
