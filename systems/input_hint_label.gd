class_name InputHintLabel
extends Label

static var _keyboard_input: Dictionary[StringName, String]
static var _joystick_input: Dictionary[StringName, String]

var _translation_key: String

static func _static_init() -> void:
	for action: StringName in InputMap.get_actions():
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey :
				if event.physical_keycode != 0:
					_keyboard_input[action] = event.as_text_physical_keycode()
				else:
					_keyboard_input[action] = event.as_text_key_label()
			elif  event is InputEventMouseButton:
				const MAP = {
					MOUSE_BUTTON_LEFT : "'🖱",
					MOUSE_BUTTON_RIGHT : "🖱'",
					MOUSE_BUTTON_MIDDLE : "🖱",
					MOUSE_BUTTON_WHEEL_UP : "🖱⬆",
					MOUSE_BUTTON_WHEEL_DOWN : "🖱⬇",
				}
				_keyboard_input[action] = MAP.get(event.button_index, "🖱?")
			elif event is InputEventJoypadButton:
				const JOYMAP = {
					JOY_BUTTON_A : "A",
					JOY_BUTTON_B : "B",
					JOY_BUTTON_X : "X",
					JOY_BUTTON_Y : "Y",
					JOY_BUTTON_BACK : "[back]",
					JOY_BUTTON_GUIDE : "[guide]",
					JOY_BUTTON_START : "[start]",
					JOY_BUTTON_LEFT_STICK : "L1",
					JOY_BUTTON_RIGHT_STICK : "R1",
					JOY_BUTTON_LEFT_SHOULDER : "L2",
					JOY_BUTTON_RIGHT_SHOULDER : "R2",
					JOY_BUTTON_DPAD_UP : "⬆",
					JOY_BUTTON_DPAD_DOWN : "⬇",
					JOY_BUTTON_DPAD_LEFT : "⬅",
					JOY_BUTTON_DPAD_RIGHT : "➡",
				}
				_joystick_input[action] = JOYMAP.get(event.button_index, "?")

func _ready() -> void:
	_translation_key = text
	_update_text()
	EventBus.input_source_changed.connect(_update_text.unbind(1))

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		if !is_node_ready(): return
		_update_text()


func _update_text() -> void:
	if EventBus.input_source == EventBus.InputSource.KEYBOARD:
		text = tr(_translation_key).format(_keyboard_input)
	else:
		print(_joystick_input)
		text = tr(_translation_key).format(_joystick_input)
	
