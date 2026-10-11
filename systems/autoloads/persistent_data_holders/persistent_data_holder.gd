#@abstract
class_name PersistentDataHolder
extends Node


#@abstract
func on_new_game() -> void:
	assert(false, "Implement me twin")
	pass

#@abstract
func get_persistent_data() -> Dictionary:
	assert(false, "Implement me twin")
	return {}

#@abstract
func load_persistent_data(_in_data: Dictionary) -> void:
	assert(false, "Implement me twin")
	pass


#@abstract
func on_quit_game() -> void:
	assert(false, "Implement me twin")
	pass
