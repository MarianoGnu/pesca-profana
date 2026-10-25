extends ProgressBar

@onready var label: Label = $Label

var _shown_time: float = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


#region SignalHandlers
func _on_stage_night_ratio_changed(percent: float) -> void:
	value = percent
	if _shown_time == value: # value is stepified noe
		return
	_shown_time = value
	var quarters: int = int(remap(value, 0.0, 1.0, 0.0, 9.0 * 4.0)) #night lasts 4 hours, from 22pm to 7am
	var hours: int = 22 + floori(float(quarters) / 4.0)
	var mins: int = (quarters % 4) * 15
	var suf: String = " PM"
	if hours >= 24:
		hours -= 24
		suf = " AM"
	label.text = "%02d:%02d%s" % [hours, mins, suf]
#endregion SignalHandlers
