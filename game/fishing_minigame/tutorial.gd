extends ColorRect

@export_group("Fade", "_fade_")
@export var _fade_time: float = 0.5
@export var _fade_alpha: float = 0.5

@onready var _panel_container: PanelContainer = $PanelContainer
@onready var _tab_container: TabContainer = %TabContainer

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

#region SignalHandlers
func _on_stage_night_started(night_id: int) -> void:
	if !_tab_container.has_node(str(night_id)):
		return
	_tab_container.current_tab = _tab_container.get_node(str(night_id)).get_index()
	color.a = 0
	show()
	_panel_container.hide()
	get_tree().paused = true
	var tw: Tween = create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(self, ^"color:a", _fade_alpha, _fade_time)
	await tw.finished
	_panel_container.show()


func _on_end_tutorial_button_pressed() -> void:
	_panel_container.hide()
	var tw = create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(self, ^"color:a", 0, _fade_time)
	await tw.finished
	get_tree().paused = false
	hide()
#endregion SignalHandlers
