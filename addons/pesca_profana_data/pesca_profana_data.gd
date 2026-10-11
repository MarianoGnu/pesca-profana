@tool
extends EditorPlugin

var _csbp_importer: EditorImportPlugin

func _enter_tree() -> void:
	_csbp_importer = ComaSeparatedBodyPartsImporter.new()
	add_import_plugin(_csbp_importer)

func _exit_tree() -> void:
	if _csbp_importer:
		remove_import_plugin(_csbp_importer)
		_csbp_importer = null

class ComaSeparatedBodyPartsImporter extends EditorImportPlugin:
	var _source_file: String
	var _line_n: int
	
	func _get_importer_name():
		return "coma.separated.body.parts"

	func _get_visible_name():
		return "Body Parts Registry"

	func _get_recognized_extensions():
		return ["csbp"]

	func _get_save_extension():
		return "res"

	func _get_resource_type():
		return "Resource"

	func _get_preset_count():
		return 1

	func _get_preset_name(preset_index: int):
		return "Default"

	func _get_import_options(path, preset_index):
		return []

	const HEADER_REMAP: Dictionary[StringName, StringName] = {
		&"id"       : &"id",
		&"rareza"   : &"rarity",
		&"tipo"     : &"type",
		&"genero"   : &"gender",
		&"variante" : &"variation",
		&"escena"   : &"scene",
		&"sprite"   : &"sprite",
	}
	
	func _import(source_file, save_path, options, platform_variants, gen_files):
		_source_file = source_file
		var file = FileAccess.open(source_file, FileAccess.READ)
		if file == null:
			return FAILED
		var library = BodyPartRegistry.new()
		
		var columns: Dictionary[int, StringName] # { column : property_name }
		var headers: PackedStringArray = file.get_csv_line()
		var h_check: Array[StringName] = HEADER_REMAP.keys()
		_line_n = 1
		for i: int in headers.size():
			var h: String = headers[i]
			if h in HEADER_REMAP:
				columns[i] = HEADER_REMAP[h]
				h_check.erase(h)
			else:
				_error("Unknown header '", h, "'")
				return ERR_FILE_CORRUPT
		if h_check.size():
			_error("Missing headers in file: ", h_check)
			return ERR_FILE_CORRUPT
		
		while !file.eof_reached():
			_line_n += 1
			var line = file.get_csv_line()
			var part = BodyPart.new()
			for c: int in columns:
				part.set(columns[c], _parse_value(columns[c], line[c]))
			if library._all_parts.has(part.id):
				_error("Repeated body part ID: ", part.id, ". Part will be discarded.")
				pass
			else:
				library._all_parts[part.id] = part

		var filename = save_path + "." + _get_save_extension()
		return ResourceSaver.save(library, filename)

	func _parse_value(p_property: StringName, p_value: String) -> Variant:
		match p_property:
			&"rarity":
				return int(p_value)
			&"type":
				const TYPE_MAP = {
					"cabeza" : BodyPart.Type.HEAD,
					"torso" : BodyPart.Type.TORSO,
					"brazo derecho" : BodyPart.Type.ARM_R,
					"brazo izquierdo" : BodyPart.Type.ARM_L,
					"pierna derecha" : BodyPart.Type.LEG_R,
					"pierna izquierda" : BodyPart.Type.LEG_L,
				}
				var type : BodyPart.Type = TYPE_MAP.get(p_value.to_lower(), BodyPart.Type.UNDEFINED)
				if type == BodyPart.Type.UNDEFINED: _error("Unknown body part type '", p_value, "'")
				return type
			&"gender":
				const GENDER_MAP = {
					"masculino" : BodyPart.Gender.MASCULINE,
					"femenino" : BodyPart.Gender.FEMENINE,
				}
				var gender : BodyPart.Gender = GENDER_MAP.get(p_value.to_lower(), BodyPart.Gender.UNDEFINED)
				if gender == BodyPart.Gender.UNDEFINED: _error("Unknown body part gender '", p_value, "'")
				return gender
			&"variation":
				const VARIATION_MAP = {
					"humano" : BodyPart.Variation.HUMAN,
					"vampiro" : BodyPart.Variation.VAMPIRE,
					"hombre lobo" : BodyPart.Variation.WEREWOLF,
				}
				var variation : BodyPart.Variation = VARIATION_MAP.get(p_value.to_lower(), BodyPart.Variation.UNDEFINED)
				if variation == BodyPart.Variation.UNDEFINED: _error("Unknown body part variation '", p_value, "'")
				return variation
			&"scene", &"sprite":
				if p_value.is_empty(): return null
				var obj = load(p_value)
				if obj == null:
					_error("Failed to load file '", p_value, "' for property ", p_property)
				return obj
			_:
				return p_value

	func _error(...args) -> void:
		var err: String = "%s@L%d " % [_source_file, _line_n]
		for arg: Variant in args:
			if typeof(arg) == TYPE_ARRAY:
				err += ", ".join(arg)
			else:
				err += str(arg)
		push_error(err)
