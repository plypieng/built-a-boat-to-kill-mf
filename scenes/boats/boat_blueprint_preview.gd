extends Node3D

const CAMERA_DIRECTION := Vector3(0.5421, 0.3144, 0.7861)

@onready var boat_root: Node3D = $Boat
@onready var camera: Camera3D = $Camera3D
@onready var preview_floor: MeshInstance3D = $PreviewFloor

func _ready() -> void:
	_frame_preview()

func _frame_preview() -> void:
	var bounds := _compute_bounds()
	if bool(bounds.get("empty", true)):
		camera.position = Vector3(5.0, 4.0, 7.0)
		camera.look_at(Vector3.ZERO, Vector3.UP)
		return

	var min_point: Vector3 = bounds.get("min", Vector3.ZERO)
	var max_point: Vector3 = bounds.get("max", Vector3.ZERO)
	var center := (min_point + max_point) * 0.5
	var size := max_point - min_point
	var focus := center + Vector3(0.0, size.y * 0.18, 0.0)
	var radius := maxf(maxf(size.length() * 0.5, maxf(size.x, size.z) * 0.75), 2.0)
	var distance := radius * 2.6
	camera.position = focus + CAMERA_DIRECTION * distance
	camera.look_at(focus, Vector3.UP)

	var floor_mesh := preview_floor.mesh as BoxMesh
	if floor_mesh != null:
		floor_mesh.size = Vector3(maxf(10.0, size.x + 8.0), 0.2, maxf(12.0, size.z + 10.0))
	preview_floor.position = Vector3(center.x, min_point.y - 0.18, center.z)

func _compute_bounds() -> Dictionary:
	var found := false
	var min_point := Vector3(INF, INF, INF)
	var max_point := Vector3(-INF, -INF, -INF)
	for mesh_instance in _collect_mesh_instances(boat_root):
		var mesh := mesh_instance.mesh
		if mesh == null:
			continue
		var aabb := mesh.get_aabb()
		for corner in _aabb_corners(aabb):
			var local_point := to_local(mesh_instance.to_global(corner))
			min_point.x = minf(min_point.x, local_point.x)
			min_point.y = minf(min_point.y, local_point.y)
			min_point.z = minf(min_point.z, local_point.z)
			max_point.x = maxf(max_point.x, local_point.x)
			max_point.y = maxf(max_point.y, local_point.y)
			max_point.z = maxf(max_point.z, local_point.z)
			found = true
	if not found:
		return {"empty": true}
	return {
		"empty": false,
		"min": min_point,
		"max": max_point,
	}

func _collect_mesh_instances(root: Node) -> Array[MeshInstance3D]:
	var results: Array[MeshInstance3D] = []
	for child_variant in root.get_children():
		var child := child_variant as Node
		if child == null:
			continue
		if child is MeshInstance3D:
			results.append(child as MeshInstance3D)
		results.append_array(_collect_mesh_instances(child))
	return results

func _aabb_corners(aabb: AABB) -> Array[Vector3]:
	var position := aabb.position
	var end := aabb.position + aabb.size
	return [
		Vector3(position.x, position.y, position.z),
		Vector3(end.x, position.y, position.z),
		Vector3(position.x, end.y, position.z),
		Vector3(end.x, end.y, position.z),
		Vector3(position.x, position.y, end.z),
		Vector3(end.x, position.y, end.z),
		Vector3(position.x, end.y, end.z),
		Vector3(end.x, end.y, end.z),
	]
