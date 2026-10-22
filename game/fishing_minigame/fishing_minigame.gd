@tool
class_name FishingMinigame
extends Control

signal reeled()
signal reel_miss

enum _State {
	UNSTARTED,
	WAITING,
	HOOKED
}

const STATE_UNSTARTED = _State.UNSTARTED
const STATE_WAITING = _State.WAITING
const STATE_HOOKED = _State.HOOKED

const BASE_SPEED = 1.0 # Radians per second

@export var max_rarity: int = 0
@export var speed_factor: float = 1.0
@export_group("Draw", "draw_")
@export var draw_line_color := Color.WHITE
@export var draw_line_width: float = 2
@export var draw_outer_radius: float = 150
@export var draw_inner_radius: float = 120
@export var draw_mark_color := Color.AQUAMARINE

var _state := STATE_UNSTARTED

# _State waiting
var _waiting_timer: float

# _State bitten
var _part_library: BodyPartRegistry = load("uid://cb0f4kgpfdlny")
var _hooked_part: BodyPart
var _position: float
var _dir: float = 1.0
var _marks: Array[Mark]
var _bg_color := Color.TRANSPARENT


func _ready() -> void:
	set_state(STATE_UNSTARTED)


func _process(p_delta: float) -> void:
	match _state:
		STATE_UNSTARTED:
			#if _is_action_just_pressed(&"action"):
				#set_state(STATE_WAITING)
			pass
		STATE_WAITING:
			if _is_action_just_pressed(&"ui_cancel"):
				set_state(STATE_UNSTARTED)
				return
			#_waiting_timer -= p_delta
			#print(_waiting_timer)
			#if _waiting_timer <= 0:
				#set_state(STATE_HOOKED)
		STATE_HOOKED:
			_position += BASE_SPEED * speed_factor * p_delta * _dir
			_position = fmod(_position, TAU)
			if _is_action_just_pressed(&"action"):
				var found := false
				for mark: Mark in _marks:
					if mark.has_point(_position):
						found = true
						_marks.erase(mark)
						break
				if !found:
					_on_action_failed()
					reel_miss.emit()
				else:
					reeled.emit()
				if _marks.size() == 0:
					_init_marks()
			queue_redraw()


func _validate_property(property: Dictionary) -> void:
	if property.name == &"_state":
		property.usage = PROPERTY_USAGE_EDITOR


func _draw() -> void:
	if _state != STATE_HOOKED:
		return
	
	if _bg_color.a > 0:
		draw_rect(Rect2(0, 0, size.x, size.y), _bg_color)
	
	var center: Vector2 = size / 2
	draw_circle(center, draw_outer_radius, draw_line_color, false, draw_line_width, true)
	_draw_marks()
	
	var position_line := (Vector2.RIGHT * draw_outer_radius).rotated(_position)
	draw_line(center, center + position_line, draw_line_color, draw_line_width, true)

func _draw_marks() -> void:
	var center: Vector2 = size / 2
	var mark_width: float = draw_outer_radius - draw_inner_radius
	var mark_radius: float = draw_inner_radius + mark_width * 0.5
	for mark in _marks:
		draw_arc(center, mark_radius, mark.start, mark.end, 20, draw_mark_color, mark_width, true)


func set_state(p_state: _State) -> void:
	_on_state_exit(_state)
	_state = p_state
	_on_state_enter(_state)


func _on_state_exit(old_state) -> void:
	match old_state:
		STATE_UNSTARTED:
			%StartLabel.hide()


func _on_state_enter(new_state) -> void:
	match new_state:
		STATE_UNSTARTED:
			%StartLabel.show()
			queue_redraw()
		STATE_WAITING:
			_waiting_timer = randf_range(1.0, 2.0)
			queue_redraw()
		STATE_HOOKED:
			_hooked_part = _part_library.pick_random(max_rarity)
			_init_marks()


func _on_action_failed() -> void:
	_bg_color = Color.RED
	var tw = create_tween()
	tw.tween_property(self, ^"_bg_color", Color.TRANSPARENT, 0.5)


func _is_action_just_pressed(p_action: StringName) -> bool:
	if Engine.is_editor_hint():
		return false
	return Input.is_action_just_pressed(p_action)


func _init_marks():
	_marks.clear()
	var count: int = roundi(randf() * 4)
	for i in count:
		var candidate_size: float = (2 * PI) / randf_range(6, 10)
		var overlaps := true
		while overlaps:
			var candidate_pos: float = randf() * 2 * PI
			var candidate := Mark.new(candidate_pos, candidate_size)
			overlaps = false
			for existing: Mark in _marks:
				overlaps = overlaps || candidate.overlaps(existing)
			if !overlaps:
				_marks.append(candidate)
		


class Mark:
	## Mark is an start/end range in randians
	## Center of the position goes from TAU to 2*TAU (2*PI to 4*PI)
	## This warrantes no warping when calcularing overlaps with otehr marks
	var start: float
	var end: float
	
	func _init(pos: float, size: float) -> void:
		assert(size < PI)
		pos = fmod(pos, TAU) # clamp from 0 to 2PI
		pos += TAU
		start = pos - size / 2
		end = pos + size / 2
	
	func has_point(point: float) -> bool:
		point = fmod(point, 2 * TAU)
		while point < TAU:
			point += TAU
		return point >= start && point <= end
	
	func overlaps(other: Mark) -> bool:
		return (
			other.has_point(start) || other.has_point(end) || has_point(other.start) || has_point(other.end)
		)
	
