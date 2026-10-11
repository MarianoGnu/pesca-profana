#autoload_name GameState
extends Node

signal game_saved

const SAVEGAME_FILE = "user://game_0.save"
const PLAYGROUND_SAVEGAME_FILE = "user://playground_0.save"
const SAVEGAME_FILE_DEBUG: Dictionary[String, String] = {
	SAVEGAME_FILE : "user://debug_0.json",
	PLAYGROUND_SAVEGAME_FILE : "user://playground_debug_0.json"
}
const SAVEFILE_PASSWORD = "password"

var is_playground_hint: bool

var _current_save_file: String
var _persistent_data_holders: Dictionary[StringName, PersistentDataHolder]


func _ready() -> void:
	_initialize_game_settings()
	_block_persistent_data_holders.call_deferred()
	var launch_scene: String = ProjectSettings.get_setting("application/run/main_scene") as String
	var args: PackedStringArray = OS.get_cmdline_args()
	for i in args.size():
		if args[i] == "--scene":
			launch_scene = args[i+1]
			break
	if launch_scene.begins_with("uid://"):
		launch_scene = ResourceUID.get_id_path(ResourceUID.text_to_id(launch_scene))
	
	var playground_folder: String = ProjectSettings.get_setting_with_override("application/config/playground_folder")
	
	var is_menu: bool = launch_scene.begins_with("res://menus/")
	is_playground_hint = launch_scene.begins_with(playground_folder)
	if OS.has_feature("editor") and is_playground_hint:
		if FileAccess.file_exists(PLAYGROUND_SAVEGAME_FILE):
			load_game.call_deferred(PLAYGROUND_SAVEGAME_FILE)
		else:
			new_game.call_deferred()
			set_deferred(&"_current_save_file", PLAYGROUND_SAVEGAME_FILE)
	elif OS.has_feature("editor") and not is_menu:
		if FileAccess.file_exists(SAVEGAME_FILE):
			load_game.call_deferred()
		else:
			new_game.call_deferred()


func _initialize_game_settings() -> void:
	var language: String = ProjectSettings.get_setting("application/config/language", TranslationServer.get_locale())
	if not language.is_empty() and language != TranslationServer.get_locale():
		TranslationServer.set_locale(language)
	var show_hud: bool = ProjectSettings.get_setting("application/config/show_hud", true)
	set_show_hud(show_hud)
	var show_tutorials: bool = ProjectSettings.get_setting("application/config/show_tutorials", true)
	set_show_tutorials(show_tutorials)
	var max_fps: int = ProjectSettings.get_setting("application/run/max_fps", 0)
	set_fps_limit(max_fps)
	for bus_name: String in ["Master", "sfx", "music"]:
		var volume_level: float = ProjectSettings.get_setting("audio/buses/volume/" + bus_name.to_lower(), 10)
		set_bus_volume_level(bus_name, volume_level)


func set_show_hud(in_show: bool) -> void:
	_set_show_canvas_layer(in_show, "HUD")


func set_show_tutorials(in_show: bool) -> void:
	_set_show_canvas_layer(in_show, "Tutorials")


func _set_show_canvas_layer(in_show: bool, in_layer_name: String) -> void:
	var hud_layer: int = 0
	for i in range(1, 21):
		var layer_name: String = ProjectSettings.get_setting("layer_names/2d_render/layer_%d" % i)
		if layer_name == in_layer_name:
			hud_layer = i
			break
	if hud_layer != 0:
		var layer_bit: int = 1 << hud_layer
		if in_show:
			get_window().canvas_cull_mask |= layer_bit
		else:
			get_window().canvas_cull_mask &= ~layer_bit
	else:
		push_error("Canvas Layer with name '%s' not found" % in_layer_name)


func set_fps_limit(in_limit: int) -> void:
	if DisplayServer.window_get_vsync_mode() in [DisplayServer.VSYNC_DISABLED, DisplayServer.VSYNC_MAILBOX]:
		Engine.max_fps = 0
	else:
		Engine.max_fps = in_limit


## Sets the volume to the bus, volume level is meant to be a value from 0 to 10
func set_bus_volume_level(bus_name: StringName, volume_level: float) -> void:
	var bus: int = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_linear(bus, volume_level / 10.0)

func register_persistent_dataholder(unique_name: StringName, out_object: PersistentDataHolder) -> void:
	assert(not unique_name in _persistent_data_holders.keys(),
		"An object with unique name %s is already registered" % unique_name)
	_persistent_data_holders[unique_name] = out_object


func new_game() -> void:
	_current_save_file = ""
	for obj: PersistentDataHolder in _persistent_data_holders.values():
		obj.on_new_game()


func quit_game() -> void:
	for obj: PersistentDataHolder in _persistent_data_holders.values():
		obj.on_quit_game()


func savegame_exists() -> bool:
	return FileAccess.file_exists(SAVEGAME_FILE)


func save_game() -> void:
	var path: String = SAVEGAME_FILE if _current_save_file.is_empty() else _current_save_file
	if OS.is_debug_build():
		_save(FileAccess.open(SAVEGAME_FILE_DEBUG[path], FileAccess.WRITE))
	_save(FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, SAVEFILE_PASSWORD))


func load_game(in_filepath := String()) -> void:
	var path: String = SAVEGAME_FILE if in_filepath.is_empty() else in_filepath
	_load(FileAccess.open_encrypted_with_pass(path, FileAccess.READ, SAVEFILE_PASSWORD))
	_current_save_file = path


func _block_persistent_data_holders() -> void:
	_persistent_data_holders.make_read_only()


func _save(out_save_file: FileAccess) -> void:
	if FileAccess.get_open_error() != OK:
		push_error("Failed to save game with error ", error_string(FileAccess.get_open_error()))
		return
	var savefile_data: Dictionary = {}
	for obj_name: StringName in _persistent_data_holders.keys():
		var obj: PersistentDataHolder = _persistent_data_holders[obj_name]
		var data: Dictionary = obj.get_persistent_data()
		savefile_data[String(obj_name)] = data
	
	out_save_file.store_string(JSON.stringify(savefile_data, "\t"))
	out_save_file.close()
	game_saved.emit()
	$SaveAnimationPlayer.play(&"on_save")


func _load(out_save_file: FileAccess) -> void:
	if FileAccess.get_open_error() != OK:
		push_error("Failed to load game with error ", error_string(FileAccess.get_open_error()))
		return
	var json: String = out_save_file.get_as_text()
	var savefile_data: Dictionary = JSON.parse_string(json)
	for obj_name: StringName in _persistent_data_holders.keys():
		if not savefile_data.has(String(obj_name)):
			push_error("Save file is missing persistent data block: %s. Running on_new_game() instead" % obj_name)
			_persistent_data_holders[obj_name].on_new_game()
			continue
		var obj: PersistentDataHolder = _persistent_data_holders[obj_name]
		var data: Dictionary = savefile_data[String(obj_name)]
		obj.load_persistent_data(data)
