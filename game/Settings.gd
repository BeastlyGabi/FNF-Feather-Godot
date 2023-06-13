extends Node

var _prefs:Dictionary = {
	### GAMEPLAY ###
	"downscroll": false,
	"centered_receptors": false,
	"ghost_tapping": true,
	"note_speed": 0.0, #0 for default chart speed
	"note_offset": 0.0,
	
	### VISUAL ###
	"note_quantization": false,
	"judgement_counter": false,
	"character_healthcolors": true,
	"show_keybinds": true,
	
	"stage_visibility": 100,
	
	"flashing_lights": true,
	"combo_stacking": true,
	"cpu_receptors": true,
	"opaque_sustains": false,
	"note_splashes": true,
	
	"hide_score": false,
	
	### BEHAVIOR ###
	"timing_preset": "etterna",
	"combo_break_judgement": "miss",
	"song_pitch": 1.0,
	
	### OTHER ###
	"framerate": 60,
	"vsync": true,
}

var _controls:Dictionary = {
	"note_left": ["A", "LEFT"],
	"note_down": ["S", "DOWN"],
	"note_up": ["W", "UP"],
	"note_right": ["D", "RIGHT"],
	
	"ui_left": ["A", "LEFT"],
	"ui_down": ["S", "DOWN"],
	"ui_up": ["W", "UP"],
	"ui_right": ["D", "RIGHT"],
	
	"ui_accept": ["ENTER", "SPACE"],
	"ui_cancel": ["ESCAPE", "BACKSPACE"],
	"ui_pause": ["ENTER", "ESCAPE"],
	
	"ui_volume_up": ["EQUAL", "KP ADD"],
	"ui_volume_down": ["MINUS", "KP SUBTRACT"],
}

const settings_path:String = "user://settings.json"
const controls_path:String = "user://controls.json"

func _ready():
	_ready_settings()
	_ready_controls()
	update_prefs()

func _ready_settings():
	var config_file:Dictionary = _settings_save_file(settings_path)
	for pref in _prefs:
		if not pref in config_file:
			config_file[pref] = _prefs[pref] # Store nonexistant preferences
		else:
			_prefs[pref] = config_file[pref] # Set existing preferences
	
	var file = FileAccess.open(settings_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(config_file, '\t'))

func _ready_controls():
	var controls_file:Dictionary = _settings_save_file(controls_path)
	for key in _controls:
		if not key in controls_file:
			controls_file[key] = _controls[key] # Store nonexistant keys
		else:
			_controls[key] = controls_file[key] # Set existing keys
		refresh_keys(key)
	
	var file = FileAccess.open(controls_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(controls_file, '\t'))

func save_settings():
	var save_file:Dictionary = {}
	var file = FileAccess.open(settings_path, FileAccess.READ_WRITE)
	if not ResourceLoader.exists(settings_path):
		_ready_settings()
	else:
		if not file.get_as_text() == null or len(file.get_as_text()) > 1:
			save_file = JSON.parse_string(file.get_as_text())
	
	for pref in _prefs:
		save_file[pref] = _prefs[pref]
	
	file.store_string(JSON.stringify(save_file, '\t'))
	update_prefs()

func save_controls():
	var save_file:Dictionary = {}
	var file = FileAccess.open(controls_path, FileAccess.READ_WRITE)
	if not ResourceLoader.exists(controls_path):
		_ready_controls()
	else:
		if not file.get_as_text() == null or len(file.get_as_text()) > 1:
			save_file = JSON.parse_string(file.get_as_text())
	
	for key in _controls:
		save_file[key] = _controls[key]
	
	file.store_string(JSON.stringify(save_file, '\t'))

func update_prefs():
	Engine.max_fps = _prefs["framerate"]
	var v_sync_mode = DisplayServer.VSYNC_DISABLED
	if _prefs["vsync"]: v_sync_mode = DisplayServer.VSYNC_ADAPTIVE
	DisplayServer.window_set_vsync_mode(v_sync_mode)

func refresh_keys(key:String):
	var key_mapper:Array[InputEvent] = InputMap.action_get_events(key)
	var key1:InputEventKey = InputEventKey.new()
	var key2:InputEventKey = InputEventKey.new()
	
	key1.set_keycode(OS.find_keycode_from_string(_controls[key][0]))
	key2.set_keycode(OS.find_keycode_from_string(_controls[key][1]))
	
	if not key_mapper.size() - 1 == -1:
		for i in key_mapper:
			InputMap.action_erase_event(key, i)
	else:
		InputMap.add_action(key)
	
	InputMap.action_add_event(key, key1)
	InputMap.action_add_event(key, key2)

func get_setting(_name:String):
	if _prefs.has(_name):
		return _prefs[_name]
	return null

func set_setting(_name:String, value:Variant):
	if _prefs.has(_name):
		_prefs[_name] = value

func _settings_save_file(_le_file:String):
	if not ResourceLoader.exists(_le_file):
		var file = FileAccess.open(_le_file, FileAccess.WRITE)
		file.store_string("{}")
	else:
		var file = FileAccess.open(_le_file, FileAccess.READ)
		if not file.get_as_text() == null and not file.get_as_text().is_empty():
				return JSON.parse_string(file.get_as_text())
	
	return {}
