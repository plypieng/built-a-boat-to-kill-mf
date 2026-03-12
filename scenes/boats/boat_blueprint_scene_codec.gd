class_name BoatBlueprintSceneCodec
extends RefCounted

const ROOT_SCRIPT = preload("res://scenes/boats/boat_blueprint_root.gd")

static func load_snapshot(scene_path: String) -> Dictionary:
	var scene_resource := load(scene_path)
	if not (scene_resource is PackedScene):
		return {}
	var root := (scene_resource as PackedScene).instantiate()
	if root == null or not root.has_method("build_snapshot"):
		if root != null:
			root.free()
		return {}
	var snapshot := Dictionary(root.call("build_snapshot")).duplicate(true)
	root.free()
	return snapshot

static func save_snapshot(scene_path: String, snapshot: Dictionary) -> int:
	var root := ROOT_SCRIPT.new()
	if root == null or not root.has_method("rebuild_from_snapshot"):
		if root != null:
			root.free()
		return ERR_CANT_CREATE
	root.name = "SharedBoatBlueprint"
	root.call("rebuild_from_snapshot", snapshot)
	_assign_scene_owners(root, root)
	var packed_scene := PackedScene.new()
	var pack_error := packed_scene.pack(root)
	if pack_error != OK:
		root.free()
		return pack_error
	var save_error := ResourceSaver.save(packed_scene, scene_path)
	root.free()
	return save_error

static func _assign_scene_owners(node: Node, owner: Node) -> void:
	for child_variant in node.get_children():
		var child := child_variant as Node
		if child == null:
			continue
		child.owner = owner
		_assign_scene_owners(child, owner)
