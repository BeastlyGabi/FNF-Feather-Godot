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
	if _file == null: _file = ConfigFile.new()
	if not path.begins_with("user://"): path = "user://%s" % path
	if not path.ends_with(".cfg"): path = path + ".cfg'"
	
	var err:Error = _file.load(path)
	if err != OK: _file.save(path)

func flush(_path:String) -> void:
	if not _path.begins_with("user://"): _path = "user://%s" % _path
	if not _path.ends_with(".cfg"): _path = _path + ".cfg'"
	
	if _file == null: _load_file(_path)
	var _err:Error = _file.load(_path)
	if _err != OK:
		_file.clear()
		return
	
	_file.save(_path)
	_file.clear()
	_file = null
