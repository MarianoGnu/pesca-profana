class_name GlobalEventBus
extends Node

@warning_ignore_start("unused_signal")
signal input_source_changed(input_source: InputSource)
signal joystick_iconset_changed(input_source: InputSource)
signal input_remaped()
@warning_ignore_restore("unused_signal")


enum InputSource {
	KEYBOARD,
	JOYSTICK,
}


var input_source: InputSource:
	set = _set_input_source
var joystick_iconset: int = ProjectSettings.get_setting("application/config/joystick_iconset"):
	set = _set_joystick_iconset


func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		input_source = InputSource.KEYBOARD
	elif event is InputEventJoypadButton:
		input_source = InputSource.JOYSTICK


func _set_input_source(source: InputSource) -> void:
	if input_source != source:
		input_source = source
		input_source_changed.emit(input_source)


func _set_joystick_iconset(iconset: int) -> void:
	if joystick_iconset != iconset:
		joystick_iconset = iconset
		joystick_iconset_changed.emit(joystick_iconset)
