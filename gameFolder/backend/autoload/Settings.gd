extends Node

var _game_settings:Dictionary = {
	"downscroll": true,
	"ghost_tapping": false,
	"note_splashes": "sick only",
	"volume": 1.0,
}

var timings:Dictionary = {"sick": 45.0, "good": 90.0, "bad": 135.0, "shit": 180.0}

func get_setting(setting:String) -> Variant:
	return _game_settings[setting]

func set_setting(setting:String, new_value:Variant) -> void:
	if _game_settings.has(setting) and get_setting(setting) != new_value:
		_game_settings[setting] = new_value
