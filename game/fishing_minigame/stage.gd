extends Node2D

enum {
	STATE_WAITING,
	STATE_CASTING,
	STATE_CAST_ANIM,
	STATE_FISHING,
}

signal line_casted

@export var cast_curve: Curve

@onready var _fishing_minigame: FishingMinigame = %FishingMinigame
@onready var _cast_progress: TextureProgressBar = %CastProgress
@onready var _igor: Igor = %Igor

var _cast_time: float = 0:
	set = _set_cast_time

var _state := -1:
	set = _on_enter_state

func _ready() -> void:
	_state = STATE_WAITING
	_fishing_minigame.reeled.connect(_igor.pull)

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
#endregion SetGet
