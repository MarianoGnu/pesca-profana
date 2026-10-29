@tool
extends Path2D

@export var _fishing_rod: Marker2D
@export var _hooked_part: PathFollow2D
@export var _fishing_line: Line2D

var _last_rod_pos: Vector2
var _last_part_pos: Vector2

func _process(_delta: float) -> void:
	visible = _fishing_rod.visible && _hooked_part.visible
	if !visible: return
	
	var rod_pos: Vector2 = _fishing_rod.global_position
	var rod_moved: bool = rod_pos != _last_rod_pos
	var part_moved: bool = _hooked_part.global_position != _last_part_pos
	
	if rod_moved or part_moved:
		_last_rod_pos = rod_pos
		_last_part_pos = _hooked_part.global_position
		curve.set_point_position(0, _last_rod_pos)
		curve.set_point_position(1, _last_part_pos)
		_fishing_line.points = curve.get_baked_points()
