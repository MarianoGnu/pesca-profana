extends Node

enum {
	STATE_BEFORE_OPEN_STORE,
	STATE_WAITING,
	STATE_CASTING,
	STATE_CAST_ANIM,
	STATE_FISHING,
	STATE_AFTER_STORE_CLOSED,
	STATE_DAY_PASSES,
}

signal line_casted
signal hooked
signal good_catched
signal bad_catched
signal client_entered(client: Client)
signal client_leaving(client: Client)
signal night_started(night_id: int)
signal night_ratio_changed(percent: float)
signal night_finished(night_id: int)

@export var cast_curve: Curve
@export var night_duration_seconds: float = 120
@export var config: Dictionary[int, StageConfig] = {
	# nigth_id : config
}

@onready var _end_day_fade: ColorRect = %EndDayFade
@onready var _end_day_toaster: PanelContainer = %EndDayToaster
@onready var _fishing_minigame: FishingMinigame = %FishingMinigame
@onready var _cast_progress: TextureProgressBar = %CastProgress
@onready var _igor: Igor = %Igor
@onready var _hooked_part: PathFollow2D = %HookedPart
@onready var _new_client_timer: Timer = %NewClientTimer
@onready var _client_slots: Array[Node2D] = [
	%ClientSlot1,
	%ClientSlot2,
	%ClientSlot3,
]
@onready var _client_spawn: Node2D = %ClientSpawn

var _night: int = 1
var _night_progress: float
var _night_money: int
var _active_config: StageConfig
var _active_clients: Array[Client]

var _money: int = 0

var _cast_time: float = 0:
	set = _set_cast_time

var _state := -1:
	set = _on_enter_state

func _ready() -> void:
	assert(config.has(1)) # at least first night should exists
	_night = 0
	_fishing_minigame.reeled.connect(_on_fishing_minigame_reeled)
	await get_tree().physics_frame
	_state = STATE_BEFORE_OPEN_STORE


func _process(p_delta: float) -> void:
	if not _state in [STATE_BEFORE_OPEN_STORE, STATE_AFTER_STORE_CLOSED]:
		_night_progress += p_delta / night_duration_seconds
		_night_progress = clampf(_night_progress, 0.0, 1.0)
		night_ratio_changed.emit(_night_progress)
		if _night_progress >= 1.0:
			_state = STATE_AFTER_STORE_CLOSED
			night_finished.emit()
		else:
			for i: int in range(_active_clients.size() - 1, -1, -1):
				var c: Client = _active_clients[i]
				c.patience -= p_delta
				if c.patience <= 0:
					client_leaving.emit(c)
					c.queue_leave()
					c.slot = _client_spawn # move run to spawner pos
					_active_clients.remove_at(i)
					_update_client_slots()
	match _state:
		STATE_WAITING:
			if Input.is_action_just_pressed(&"action"):
				_state = STATE_CASTING
		STATE_CASTING:
			_cast_time += p_delta
			if Input.is_action_just_released(&"action"):
				_state = STATE_CAST_ANIM

func _update_client_slots():
	for i: int in _active_clients.size():
		_active_clients[i].slot = _client_slots[i]

#region SetGet
func _set_cast_time(p_time: float) -> void:
	_cast_time = fmod(p_time, 1.0)
	if !!_cast_progress and !!cast_curve:
		_cast_progress.value = cast_curve.sample_baked(_cast_time)


func _on_enter_state(p_state: int) -> void:
	_state = p_state
	match p_state:
		STATE_BEFORE_OPEN_STORE:
			_night += 1
			_night_money = 0
			_night_progress = 0.0
			_active_config = config.get(_night, _active_config)
			night_ratio_changed.emit(0)
			night_started.emit(_night)
			_new_client_timer.start()
			_on_new_client_timer_timeout()
			_on_enter_state(STATE_WAITING)
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
		STATE_AFTER_STORE_CLOSED:
			_new_client_timer.stop()
			# TODO: show night results
		STATE_DAY_PASSES:
			_end_day_fade.color = Color.TRANSPARENT
			_end_day_toaster.hide()
			_end_day_fade.show()
			var tw: Tween = create_tween()
			tw.tween_property(_end_day_fade, ^"color:a", 1.0, 3.0)
			tw.tween_property(_end_day_fade, ^"color", Color.BLACK, 1.5)
			tw.tween_callback(_end_day_toaster.show)
			tw.tween_property(_end_day_fade, ^"color:a", 0.0, 1.5).set_delay(3.0)
			tw.tween_callback(_end_day_toaster.hide)
			tw.tween_callback(_end_day_fade.hide)
			await tw.finished
			_on_enter_state(STATE_BEFORE_OPEN_STORE)
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

func _on_new_client_timer_timeout() -> void:
	if _active_clients.size() < _active_config.max_clients and _active_clients.size() < _client_slots.size():
		if _active_clients.size() > 0 and randf() > 0.5:
			return
		var custom_scene: PackedScene = null if _active_config.client_scenes.is_empty() else _active_config.client_scenes.pick_random()
		if custom_scene == null:
			const FALLBACK_MONSTER = preload("uid://dgrxpiet1h5x0")
			custom_scene = FALLBACK_MONSTER
		var c: Node = custom_scene.instantiate()
		assert(c is Client)
		var client := c as Client
		_client_spawn.add_child(client)
		var patience: float = randf_range(_active_config.client_min_patience, _active_config.client_max_patience, )
		var missing_parts_count: int = randi_range(1, _active_config.max_parts_per_client)
		client.setup(patience, missing_parts_count)
		_active_clients.append(client)
		_update_client_slots()
		client_entered.emit(client)
#endregion SignalHandlers
