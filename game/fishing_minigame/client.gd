
@tool
class_name Client
extends Node2D

var slot: Node2D:
	set = _set_slot
var patience: float:
	set = _set_patience, get = _get_patience

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
@export var _patience_bar: ProgressBar
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

var _leaving: bool = false

func setup(max_patience: float, missing_parts_count: int) -> void:
	_patience_bar.max_value = max_patience
	_patience_bar.value = max_patience
	_patience_bar.min_value = 0
	var removable: Array[BodyPart.Type]
	for part: BodyPart.Type in _body_part_nodes.keys():
		if _body_part_nodes.get(part, null) == null:
			continue
		removable.append(part)
	removable.shuffle()
	for i in missing_parts_count:
		if removable.is_empty():
			return
		var type = removable.pop_back()
		_set_has_part(type, false)

func _set_has_part(p_type: BodyPart.Type, p_has_part: bool) -> void:
	_has_part[p_type] = p_has_part
	if not is_node_ready(): await ready
	if _body_part_nodes.get(p_type, null) != null:
		_body_part_nodes[p_type].visible = p_has_part
	_request_bubble.update(self)

func _ready() -> void:
	assert(_request_bubble != null)
	assert(_patience_bar != null)
	# TODO: Delete me when we have real assets
	if Engine.is_editor_hint(): return
	var color := Color.from_hsv(randf(), randf_range(0.3, 0.7), randf_range(0.5, 1.0))
	$Body.modulate = color

func queue_leave() -> void:
	_leaving = true
	_request_bubble.queue_free()

#region SetGet
func _set_slot(p_slot: Node2D):
	slot = p_slot
	var distance = global_position.distance_to(slot.global_position)
	if is_zero_approx(distance): return
	const MOVE_SPEED = 200.0
	var move_time: float = distance / MOVE_SPEED
	var tw: Tween = create_tween()
	tw.tween_property(self, ^"global_position", slot.global_position, move_time)
	if _leaving:
		await tw.finished
		queue_free()


func _set_patience(p_value: float) -> void:
	if !is_node_ready(): await ready
	_patience_bar.value = p_value
	patience = _patience_bar.value


func _get_patience() -> float:
	if !is_node_ready():
		return patience
	return _patience_bar.value
#endregion SetGet
