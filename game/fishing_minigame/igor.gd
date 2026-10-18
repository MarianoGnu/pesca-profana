@tool
extends Node2D

@export var casting: bool:
	set(v):
		casting = v
		if !!_playback: _playback.travel("cast" if v else "idle")
@export var pull: bool:
	set(v):
		if !!_playback && v: _playback.travel("pull")

@onready var _playback: AnimationNodeStateMachinePlayback = $AnimationTree.get("parameters/playback")

func _validate_property(property: Dictionary) -> void:
	if property.name in [&"casting", &"pull"]:
		property.usage = PROPERTY_USAGE_EDITOR
