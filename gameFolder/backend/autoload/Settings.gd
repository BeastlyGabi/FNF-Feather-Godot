extends Node

### <-- INTERNAL, IGNORE THESE --> ###
var _file:ConfigFile = ConfigFile.new()
const _cfg_filepath:String = "user://settings.cfg"

### <-- SETTINGS --> ###

## GAMEPLAY
var downscroll:bool = false # Whether notes should scroll downards
var ghost_tapping:bool = true # Whether you should be able to press there are no notes to be able to hit
var timings:Dictionary = {"sick": 45.0, "good": 90.0, "bad": 135.0, "shit": 180.0} # Define your Judgement Timings

## VISUALS
var combo_style := ComboStyle.FEATHER # Choose your combo popup style
var combo_camera := ComboCamera.HUD # Choose where the combo should be in gameplay
var note_splashes:bool = true # Whether a splash effect should be shown when hitting "Sick!"s on Notes

## MISC
var auto_pause:bool = true # Whether the game should pause itself when unfocused

enum ComboCamera {WORLD = 0, HUD}
enum ComboStyle {FEATHER = 0, VANILLA}

var volume:float = 1.0:
	set(v):
		volume = v
		AudioServer.set_bus_volume_db(0, linear_to_db(v))

### <-- FUNCTIONS --> ###

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	load_cfg()

func load_cfg() -> void:
	_load_file(_cfg_filepath)
	
	var _game_settings:Array[Dictionary] = get_script().get_script_property_list()
	_game_settings.remove_at(0)
	
	for key in _game_settings:
		if key.name.begins_with("_"): continue
		if _file.get_value("Settings", key.name) == null:
			_file.set_value("Settings", key.name, get(key.name))
		else:
			set(key.name, _file.get_value("Settings", key.name))
	
	if _file.has_section_key("System", "volume"):
		volume = _file.get_value("System", "volume", 1.0)
	
	flush(_cfg_filepath)

func _load_file(path:String) -> void:
	path = _format_path(path)
	
	if _file == null: _file = ConfigFile.new()
	var err:Error = _file.load(path)
	if err != OK: _file.save(path)

func flush(path:String) -> void:
	if _file == null: _load_file(path)
	var err:Error = _file.load(path)
	if err != OK:
		_file.clear()
		_file = null
		return
	
	_file.save(path)
	_file.clear()
	_file = null

func _format_path(path:String) -> String:
	if not path.begins_with("user://"): path = "user://%s" % path
	if not path.ends_with(".cfg"): path = path + ".cfg'"
	return path
