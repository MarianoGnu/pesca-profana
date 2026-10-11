@abstract
class_name BodyPart2D
extends Node2D

@export var part: BodyPart:
	set = _set_part

@abstract func _set_part(in_part) -> void

@abstract func set_sprite_texture(in_texture: Texture2D) -> void
