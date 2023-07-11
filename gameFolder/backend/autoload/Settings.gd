extends Node

enum ComboCamera {WORLD = 0, HUD}
enum ComboStyle {FEATHER = 0, VANILLA}

var _game_settings:Dictionary = {
	## GAMEPLAY
	"downscroll": false, # Whether notes should scroll downards
	"ghost_tapping": true, # Whether you should be able to press there are no notes to be able to hit
	"timings": {"sick": 45.0, "good": 90.0, "bad": 135.0, "shit": 180.0}, # Define your Judgement Timings
	
	## VISUALS
	"combo_style": ComboStyle.FEATHER, # Choose your combo popup style
	"combo_camera": ComboCamera.HUD, # Choose where the combo should be in gameplay
	"note_splashes": true, # Whether a splash effect should be shown when hitting "Sick!"s on Notes
	
	## MISC
	"auto_pause": true, # Whether the game should pause itself when unfocused
}

var volume:float = 1.0:
	set(v):
		volume = v
		AudioServer.set_bus_volume_db(0, linear_to_db(v))

func _ready() -> void:
	load_cfg()

var file:ConfigFile = ConfigFile.new()
const cfg_filepath:String = "user://settings.cfg"

func load_cfg() -> void:
	_load_file(cfg_filepath)
	
	for key in _game_settings:
		if not file.has_section_key("Settings", key):
			file.set_value("Settings", key, _game_settings[key])
		
		_game_settings[key] = file.get_value("Settings", key, _game_settings[key])
	
	if file.has_section_key("System", "volume"):
		volume = file.get_value("System", "volume", 1.0)
	
	flush(cfg_filepath)

func _load_file(path:String) -> void:
	if file == null: file = ConfigFile.new()
	if not path.begins_with("user://"): path = "user://%s" % path
	if not path.ends_with(".cfg"): path = path + ".cfg'"
	
	var err:Error = file.load(path)
	if err != OK: file.save(path)

func get_setting(setting:String) -> Variant:
	return _game_settings[setting]

func set_setting(setting:String, new_value:Variant) -> void:
	if _game_settings.has(setting) and not get_setting(setting) == new_value:
		_game_settings[setting] = new_value

func flush(path:String) -> void:
	if not path.begins_with("user://"): path = "user://%s" % path
	if not path.ends_with(".cfg"): path = path + ".cfg'"
	
	if file == null: _load_file(path)
	var err:Error = file.load(path)
	if err != OK:
		file.clear()
		return
	
	file.save(path)
	file.clear()
	file = null
