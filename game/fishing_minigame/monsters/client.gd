
@tool
class_name Client
extends Node2D

signal paid(money: int)

@export var _price_per_part: Dictionary[BodyPart.Type, int] = {
	BodyPart.Type.HEAD  : 100,
	BodyPart.Type.TORSO : 100,
	BodyPart.Type.ARM_L : 50,
	BodyPart.Type.ARM_R : 50,
	BodyPart.Type.LEG_L : 50,
	BodyPart.Type.LEG_R : 50,
	BodyPart.Type.EYES : 30,
}

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
@export var _money_label: Label
@export var _money_timer: Timer
@export var _body_part_nodes: Dictionary[BodyPart.Type, Node2D] = {
	BodyPart.Type.HEAD  : null,
	BodyPart.Type.TORSO : null,
	BodyPart.Type.ARM_L : null,
	BodyPart.Type.ARM_R : null,
	BodyPart.Type.LEG_L : null,
	BodyPart.Type.LEG_R : null,
	BodyPart.Type.EYES : null,
}

var _get_part_curve: Curve = preload("uid://drk3lld3sy5vn")

var _has_part: Dictionary[BodyPart.Type, bool] = {
	BodyPart.Type.HEAD  : true,
	BodyPart.Type.TORSO : true,
	BodyPart.Type.ARM_L : true,
	BodyPart.Type.ARM_R : true,
	BodyPart.Type.LEG_L : true,
	BodyPart.Type.LEG_R : true,
	BodyPart.Type.EYES : true,
}

var _accum_money: int = 0:
	set = _set_accum_money
var _money_flip_flop: bool = false
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

func get_missing_part_types() -> Array[BodyPart.Type]:
	var missing: Array[BodyPart.Type] = []
	for type: BodyPart.Type in _has_part:
		if _has_part[type] == false and _body_part_nodes.get(type) != null:
			missing.append(type)
	return missing

func add_part_from_position(p_type: BodyPart.Type, p_from_position: Vector2) -> void:
	assert(_has_part.get(p_type, false) == false)
	var part_node: Node2D = _body_part_nodes.get(p_type)
	assert(part_node != null)
	var final_pos: Vector2 = part_node.global_position
	_accum_money += _price_per_part.get(p_type, 0)
	_set_has_part(p_type, true)
	
	part_node.global_position = p_from_position
	var tween_callback: Callable = func(p_percent: float):
		part_node.global_position = p_from_position.lerp(final_pos, p_percent)
		part_node.global_position.y -= _get_part_curve.sample_baked(p_percent)
	var tw: Tween = create_tween()
	tw.tween_method(tween_callback, 0.0, 1.0, 0.5)
	await tw.finished
	part_node.global_position = final_pos
	if get_missing_part_types().is_empty():
		_money_label.queue_free()
		_money_timer.queue_free()
	else:
		patience += 1.0

func _set_has_part(p_type: BodyPart.Type, p_has_part: bool) -> void:
	_has_part[p_type] = p_has_part
	if not is_node_ready(): await ready
	if _body_part_nodes.get(p_type, null) != null:
		_body_part_nodes[p_type].visible = p_has_part
	_request_bubble.update(self)

func _ready() -> void:
	assert(_request_bubble != null)
	assert(_patience_bar != null)
	_money_timer.timeout.connect(_update_money_label)

func queue_leave() -> void:
	_leaving = true
	_request_bubble.queue_free()
	if patience > 0:
		paid.emit(_accum_money)
	else:
		paid.emit(floori(_accum_money / 2.0))

func _update_money_label():
	if !_money_timer.is_stopped():
		_money_flip_flop = !_money_flip_flop
	if _money_flip_flop:
		_money_label.text = "$ %d" % floori(_accum_money / 2.0)
	else:
		_money_label.text = "$ %d" % _accum_money

#region SetGet
func _set_slot(p_slot: Node2D):
	slot = p_slot
	var distance = global_position.distance_to(slot.global_position)
	if is_zero_approx(distance): return
	const MOVE_SPEED = 1000.0
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
	if patience < 5 and _money_timer.is_stopped():
		_money_timer.start()

func _set_accum_money(p_money: int):
	_accum_money = p_money
	_update_money_label()

func _get_patience() -> float:
	if !is_node_ready():
		return patience
	return _patience_bar.value
#endregion SetGet
