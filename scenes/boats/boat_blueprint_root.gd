@tool
class_name BoatBlueprintRoot
extends Node3D

const BOAT_BLUEPRINT_GEOMETRY_SCHEMA_VERSION := 2
const BOAT_CELL_SIZE := 1.25
const BLOCK_SCRIPT = preload("res://scenes/boats/boat_blueprint_block.gd")

@export var blueprint_version: int = 1
@export var next_block_id: int = 2

func build_snapshot() -> Dictionary:
	var blocks: Array = []
	var seen_cells := {}
	var seen_ids := {}
	var resolved_next_block_id := maxi(1, next_block_id)
	for child in get_children():
		if not (child is BoatBlueprintBlock):
			continue
		var block := child as BoatBlueprintBlock
		var cell := block.get_blueprint_cell(BOAT_CELL_SIZE)
		var cell_key := _cell_to_key(cell)
		if seen_cells.has(cell_key):
			continue
		var block_id := maxi(0, block.block_id)
		if block_id <= 0 or seen_ids.has(block_id):
			while seen_ids.has(resolved_next_block_id):
				resolved_next_block_id += 1
			block_id = resolved_next_block_id
		resolved_next_block_id = maxi(resolved_next_block_id, block_id + 1)
		seen_ids[block_id] = true
		seen_cells[cell_key] = true
		blocks.append({
			"id": block_id,
			"type": block.block_type,
			"cell": cell,
			"rotation_steps": block.get_blueprint_rotation_steps(),
		})
	if blocks.is_empty():
		return {
			"geometry_schema_version": BOAT_BLUEPRINT_GEOMETRY_SCHEMA_VERSION,
			"version": 1,
			"next_block_id": 2,
			"blocks": [{
				"id": 1,
				"type": "core",
				"cell": [0, 0, 0],
				"rotation_steps": 0,
			}],
		}
	return {
		"geometry_schema_version": BOAT_BLUEPRINT_GEOMETRY_SCHEMA_VERSION,
		"version": maxi(1, blueprint_version),
		"next_block_id": maxi(1, resolved_next_block_id),
		"blocks": blocks,
	}

func rebuild_from_snapshot(snapshot: Dictionary) -> void:
	for child in get_children():
		if child is BoatBlueprintBlock:
			remove_child(child)
			child.free()
	blueprint_version = maxi(1, int(snapshot.get("version", 1)))
	next_block_id = maxi(1, int(snapshot.get("next_block_id", 1)))
	for block_variant in Array(snapshot.get("blocks", [])):
		if typeof(block_variant) != TYPE_DICTIONARY:
			continue
		var block := Dictionary(block_variant)
		var block_node := BLOCK_SCRIPT.new() as BoatBlueprintBlock
		add_child(block_node)
		block_node.owner = self
		block_node.configure_from_blueprint(block, BOAT_CELL_SIZE)
		block_node.name = "%03d_%s" % [
			int(block.get("id", 0)),
			str(block.get("type", "structure")),
		]

func _cell_to_key(cell: Array) -> String:
	return "%d:%d:%d" % [int(cell[0]), int(cell[1]), int(cell[2])]
