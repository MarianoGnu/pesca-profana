@tool
class_name Igor
extends Node2D

@export var casting: bool:
	set(v):
		casting = v
		if !!_playback: _playback.travel("cast" if v else "idle")

@export var test_pull: bool:
	set(v): if !!_playback && v: _playback.travel("pull")
@export var done: bool:
	set(v): if !!_playback && v: end_fishing()

@onready var _playback: AnimationNodeStateMachinePlayback = $AnimationTree.get("parameters/playback")

func _validate_property(property: Dictionary) -> void:
	if property.name in [&"casting", &"test_pull", &"done"]:
		property.usage = PROPERTY_USAGE_EDITOR

func pull() -> void:
	if !!_playback: _playback.travel("pull")

func end_fishing() -> void:
	if !!_playback: _playback.travel("wait")
