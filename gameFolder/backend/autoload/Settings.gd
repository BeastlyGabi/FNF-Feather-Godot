extends Node

var _game_settings:Dictionary = {
	"downscroll": true,
	"ghost_tapping": true,
	"note_splashes": "sick only",
}

var timings:Dictionary = {"sick": 45.0, "good": 90.0, "bad": 135.0, "shit": 180.0}

var volume:float = 1.0

func get_setting(setting:String) -> Variant:
	return _game_settings[setting]

func set_setting(setting:String, new_value:Variant) -> void:
	if _game_settings.has(setting) and not get_setting(setting) == new_value:
		_game_settings[setting] = new_value
