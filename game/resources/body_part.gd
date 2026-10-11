@tool
class_name BodyPart
extends Resource


enum Type {
	ANY = -1,
	HEAD,
	TORSO,
	ARM_L,
	ARM_R,
	LEG_L,
	LEG_R,
	UNDEFINED,
}

enum Gender {
	ANY = -1,
	FEMENINE,
	MASCULINE,
	UNDEFINED,
}

enum Variation {
	ANY = -1,
	HUMAN,
	VAMPIRE,
	WEREWOLF,
	UNDEFINED,
}

@export var id: StringName
@export var rarity: int
@export var type := Type.UNDEFINED
@export var gender := Gender.UNDEFINED
@export var variation := Variation.UNDEFINED
@export var scene: PackedScene
@export var sprite: Texture2D


func instantiate() -> BodyPart2D:
	if !scene:
		push_error("Scene not assigned, cannot instantiate. returning null.")
		return null
	var instance: Node = scene.instantiate()
	if instance is BodyPart2D:
		instance.part = self
		if sprite:
			instance.set_sprite_texture(sprite)
		return instance
	else:
		instance.queue_free()
		push_error("Asociated scene is not a BodyPart2D. returning null.")
		return null
