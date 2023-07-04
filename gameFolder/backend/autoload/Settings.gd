extends Node

var _game_settings:Dictionary = {
	"downscroll": false,
	"ghost_tapping": true,
	"note_splashes": true,
	"auto_pause": false,
	"note_skin": "default",
	"timings": {"sick": 45.0, "good": 90.0, "bad": 135.0, "shit": 180.0}
}

var volume:float = 1.0

func _ready() -> void:
	load_cfg()

var file:ConfigFile = ConfigFile.new()
const cfg_filepath:String = "user://settings.cfg"

func load_cfg() -> void:
	var err:Error = file.load(cfg_filepath)
	if err != OK: file.save(cfg_filepath)
	
	for key in _game_settings:
		if not file.has_section_key("Settings", key):
			file.set_value("Settings", key, _game_settings[key])
		
		_game_settings[key] = file.get_value("Settings", key, _game_settings[key])
	
	file.save(cfg_filepath)
	file.clear()

func get_setting(setting:String) -> Variant:
	return _game_settings[setting]

func set_setting(setting:String, new_value:Variant) -> void:
	if _game_settings.has(setting) and not get_setting(setting) == new_value:
		_game_settings[setting] = new_value
