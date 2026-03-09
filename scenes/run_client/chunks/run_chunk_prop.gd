@tool
extends Node3D

func set_prop_color(color: Color) -> void:
	var mesh_instance := get_node_or_null("Body") as MeshInstance3D
	if mesh_instance == null:
		return
	var material := mesh_instance.material_override as StandardMaterial3D
	if material == null:
		material = StandardMaterial3D.new()
		mesh_instance.material_override = material
	material.albedo_color = color
	material.roughness = 0.4
