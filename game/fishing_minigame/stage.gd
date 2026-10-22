extends Node2D

enum {
	STATE_WAITING,
	STATE_CASTING,
	STATE_CAST_ANIM,
	STATE_FISHING,
}

signal line_casted
signal hooked
signal good_catched
signal bad_catched

@export var cast_curve: Curve

@onready var _fishing_minigame: FishingMinigame = %FishingMinigame
@onready var _cast_progress: TextureProgressBar = %CastProgress
@onready var _igor: Igor = %Igor
@onready var _hooked_part: PathFollow2D = %HookedPart

var _cast_time: float = 0:
	set = _set_cast_time

var _state := -1:
	set = _on_enter_state

func _ready() -> void:
	_state = STATE_WAITING
	_fishing_minigame.reeled.connect(_on_fishing_minigame_reeled)
	

func _process(p_delta: float) -> void:
	match _state:
		STATE_WAITING:
			if Input.is_action_just_pressed(&"action"):
				_state = STATE_CASTING
		STATE_CASTING:
			_cast_time += p_delta
			if Input.is_action_just_released(&"action"):
				_state = STATE_CAST_ANIM

#region SetGet
func _set_cast_time(p_time: float) -> void:
	_cast_time = fmod(p_time, 1.0)
	if !!_cast_progress and !!cast_curve:
		_cast_progress.value = cast_curve.sample_baked(_cast_time)


func _on_enter_state(p_state: int) -> void:
	_state = p_state
	match p_state:
		STATE_WAITING:
			_cast_progress.hide()
			_fishing_minigame.set_state(FishingMinigame.STATE_UNSTARTED)
		STATE_CASTING:
			_igor.casting = true
			_cast_progress.show()
			_cast_time = 0
			_fishing_minigame.set_state(FishingMinigame.STATE_WAITING)
		STATE_CAST_ANIM:
			_igor.casting = false
			line_casted.emit()
			await get_tree().create_timer(0.5).timeout
			_on_enter_state(STATE_FISHING)
		STATE_FISHING:
			_cast_progress.hide()
			_fishing_minigame.set_state(FishingMinigame.STATE_HOOKED)
			hooked.emit()
#endregion SetGet

#region SignalHandlers
func _on_fishing_minigame_reeled() -> void:
	var tw: Tween = _hooked_part.create_tween()
	var advance = 0.1 # TODO Tweak depending on hooked part
	tw.tween_property(_hooked_part, ^"progress_ratio", _hooked_part.progress_ratio + advance, 0.2)
	await tw.finished
	if _hooked_part.progress_ratio >= 1.0:
		_fishing_minigame.set_process(false)
		good_catched.emit()
		await get_tree().create_timer(0.5).timeout
		_fishing_minigame.set_process(true)
		_state = STATE_WAITING
		_igor.end_fishing()
#endregion SignalHandlers
