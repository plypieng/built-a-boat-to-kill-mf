@tool
extends Node3D

@onready var tile_mesh: MeshInstance3D = $Tile
@onready var border_mesh: MeshInstance3D = $Border
@onready var props_root: Node3D = $Props

func set_chunk_size(chunk_size: float) -> void:
	var tile_box := tile_mesh.mesh as BoxMesh
	if tile_box == null:
		tile_box = BoxMesh.new()
		tile_mesh.mesh = tile_box
	tile_box.size = Vector3(chunk_size * 0.98, 0.08, chunk_size * 0.98)
	tile_mesh.position = Vector3(0.0, -0.82, 0.0)

	var border_box := border_mesh.mesh as BoxMesh
	if border_box == null:
		border_box = BoxMesh.new()
		border_mesh.mesh = border_box
	border_box.size = Vector3(chunk_size * 0.96, 0.05, chunk_size * 0.96)
	border_mesh.position = Vector3(0.0, -0.58, 0.0)

func set_tile_color(color: Color) -> void:
	var material := tile_mesh.material_override as StandardMaterial3D
	if material == null:
		material = StandardMaterial3D.new()
		tile_mesh.material_override = material
	material.albedo_color = color
	material.roughness = 0.38
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func set_outline_color(color: Color) -> void:
	var material := border_mesh.material_override as StandardMaterial3D
	if material == null:
		material = StandardMaterial3D.new()
		border_mesh.material_override = material
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.32

func clear_props() -> void:
	for child in props_root.get_children():
		child.queue_free()

func get_props_root() -> Node3D:
	return props_root
