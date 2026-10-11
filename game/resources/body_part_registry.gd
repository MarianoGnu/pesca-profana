@tool
## updated list of parts can be downloaded from 
## https://docs.google.com/spreadsheets/d/1LvfvR6Xb7-vpI6kJMFmVmJL_-WpyoM2CPJHtwOOPosk/edit?usp=sharing
class_name BodyPartRegistry
extends Resource

@export_storage var _all_parts: Dictionary[StringName, BodyPart]

var _sorted: Dictionary[BodyPart.Type, Array]
var _filters_cache: Dictionary[PackedInt32Array, Array] = {
	# [max_rarity, type, gender, variation] : Array[BodyPart]
}

func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	_ensure_sorted_initialized()
	for type: BodyPart.Type in _sorted:
		var type_name: String = BodyPart.Type.find_key(type).to_lower()
		for part: BodyPart in _sorted[type]:
			var property: Dictionary = {
				name = type_name + "/" + part.id,
				type = TYPE_OBJECT,
				hint = PROPERTY_HINT_RESOURCE_TYPE,
				hint_string = "BodyPart",
				usage = PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY,
			}
			properties.append(property)
	return properties


func _get(property: StringName) -> Variant:
	if property.get_slice_count("/") == 2:
		# ignore type, just read id
		var id: StringName = property.get_slice("/", 1)
		return _all_parts.get(id)
	return null


func pick_random(
		p_max_rarity: int,
		p_type := BodyPart.Type.ANY,
		p_gender := BodyPart.Gender.ANY,
		p_variation := BodyPart.Variation.ANY) -> BodyPart:
	return _filter(p_max_rarity, p_type, p_gender, p_variation).pick_random()


#region private methods
func _ensure_sorted_initialized() -> void:
	if _sorted.is_empty():
		for part: BodyPart in _all_parts.values():
			if !part.type in _sorted:
				_sorted[part.type] = []
			_sorted[part.type].append(part)


func _filter(p_max_rarity: int,
		p_type := BodyPart.Type.ANY,
		p_gender := BodyPart.Gender.ANY,
		p_variation := BodyPart.Variation.ANY) -> Array:
	var key: PackedInt32Array = [p_max_rarity, p_type, p_gender, p_variation]
	if !_filters_cache.has(key):
		_filters_cache[key] = []
		for part: BodyPart in _all_parts.values():
			if part.rarity > p_max_rarity:
				continue
			if p_type != BodyPart.Type.ANY && part.type != p_type:
				continue
			if p_gender != BodyPart.Gender.ANY && part.gender != p_gender:
				continue
			if p_variation != BodyPart.Variation.ANY && part.variation != p_variation:
				continue
			_filters_cache[key].append(part)
	return _filters_cache[key]
#endregion (private methods)
