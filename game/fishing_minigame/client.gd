
@tool
class_name Client
extends Node2D


@export_group("Part Completion")
@export var has_head: bool = true:
	set(v): has_head = v; _set_has_part(BodyPart.Type.HEAD, v)
	get(): return _has_part[BodyPart.Type.HEAD]
@export var has_left_arm: bool = true:
	set(v): has_left_arm = v; _set_has_part(BodyPart.Type.ARM_L, v)
	get(): return _has_part[BodyPart.Type.ARM_L]
@export var has_rigth_arm: bool = true:
	set(v): has_rigth_arm = v; _set_has_part(BodyPart.Type.ARM_R, v)
	get(): return _has_part[BodyPart.Type.ARM_R]
@export var has_left_leg: bool = true:
	set(v): has_left_leg = v; _set_has_part(BodyPart.Type.LEG_L, v)
	get(): return _has_part[BodyPart.Type.LEG_L]
@export var has_rigth_leg: bool = true:
	set(v): has_rigth_leg = v; _set_has_part(BodyPart.Type.LEG_R, v)
	get(): return _has_part[BodyPart.Type.LEG_R]
@export var has_eyes: bool = true:
	set(v): has_eyes = v; _set_has_part(BodyPart.Type.EYES, v)
	get(): return _has_part[BodyPart.Type.EYES]

@export_group("Scene Setup", "_")
@export var _request_bubble: RequestBubble
@export var _body_part_nodes: Dictionary[BodyPart.Type, Node2D] = {
	BodyPart.Type.HEAD  : null,
	BodyPart.Type.TORSO : null,
	BodyPart.Type.ARM_L : null,
	BodyPart.Type.ARM_R : null,
	BodyPart.Type.LEG_L : null,
	BodyPart.Type.LEG_R : null,
	BodyPart.Type.EYES : null,
}

var _has_part: Dictionary[BodyPart.Type, bool] = {
	BodyPart.Type.HEAD  : true,
	BodyPart.Type.TORSO : true,
	BodyPart.Type.ARM_L : true,
	BodyPart.Type.ARM_R : true,
	BodyPart.Type.LEG_L : true,
	BodyPart.Type.LEG_R : true,
	BodyPart.Type.EYES : true,
}

func _set_has_part(p_type: BodyPart.Type, p_has_part: bool) -> void:
	_has_part[p_type] = p_has_part
	if not is_node_ready(): await ready
	if _body_part_nodes.get(p_type, null) != null:
		_body_part_nodes[p_type].visible = p_has_part
	_request_bubble.update(self)

func _ready() -> void:
	# TODO: Delete me when we have real assets
	if Engine.is_editor_hint(): return
	var color := Color.from_hsv(randf(), randf_range(0.3, 0.7), randf_range(0.5, 1.0))
	$Body.modulate = color
