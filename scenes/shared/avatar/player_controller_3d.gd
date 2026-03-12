@tool
extends CharacterBody3D
class_name PlayerController3D

@export_group("Collision")
@export_range(0.15, 1.0, 0.01) var capsule_radius := 0.34:
	set(value):
		capsule_radius = value
		_apply_capsule_shape()
@export_range(0.4, 2.5, 0.01) var capsule_height := 1.08:
	set(value):
		capsule_height = value
		_apply_capsule_shape()

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var avatar_visual: Node3D = $AvatarVisual

func _ready() -> void:
	_apply_capsule_shape()

func get_avatar_visual() -> Node3D:
	return avatar_visual

func configure_presentation(
	display_name: String,
	highlight_color: Color,
	tool_color: Color,
	nameplate_color: Color,
	secondary_text: String = ""
) -> void:
	set_display_text(display_name, secondary_text)
	set_highlight_color(highlight_color)
	set_tool_color(tool_color)
	set_nameplate_color(nameplate_color)

func set_display_text(primary: String, secondary: String = "") -> void:
	if avatar_visual != null and avatar_visual.has_method("set_display_text"):
		avatar_visual.call("set_display_text", primary, secondary)

func set_highlight_color(color: Color) -> void:
	if avatar_visual != null and avatar_visual.has_method("set_highlight_color"):
		avatar_visual.call("set_highlight_color", color)

func set_tool_color(color: Color) -> void:
	if avatar_visual != null and avatar_visual.has_method("set_tool_color"):
		avatar_visual.call("set_tool_color", color)

func set_nameplate_color(color: Color) -> void:
	if avatar_visual != null and avatar_visual.has_method("set_nameplate_color"):
		avatar_visual.call("set_nameplate_color", color)

func set_tool_visible(visible: bool) -> void:
	if avatar_visual != null and avatar_visual.has_method("set_tool_visible"):
		avatar_visual.call("set_tool_visible", visible)

func set_motion_blend(blend: float) -> void:
	if avatar_visual != null and avatar_visual.has_method("set_motion_blend"):
		avatar_visual.call("set_motion_blend", blend)

func set_motion_state(state: String) -> void:
	if avatar_visual != null and avatar_visual.has_method("set_motion_state"):
		avatar_visual.call("set_motion_state", state)

func _apply_capsule_shape() -> void:
	if collision_shape == null:
		return
	var shape := collision_shape.shape as CapsuleShape3D
	if shape == null:
		shape = CapsuleShape3D.new()
		collision_shape.shape = shape
	shape.radius = capsule_radius
	shape.height = capsule_height
	# Keep the CharacterBody3D origin at foot level.
	collision_shape.position = Vector3(0.0, capsule_radius + capsule_height * 0.5, 0.0)
