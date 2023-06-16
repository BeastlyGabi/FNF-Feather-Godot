extends MusicBeatNode2D

var NOTE_TYPES:Dictionary = {
	"default": preload("res://game/gameplay/notes/default.tscn"),
	"quant": preload("res://game/gameplay/notes/default-quant.tscn")
}

var _SONG:Chart
var current_zoom:float = 1.0

func _ready():
	SoundHelper.stop_music()
	Overlay.visible = false
	
	if not Song.current == null:
		_SONG = Song.current
	else:
		_SONG = Chart.load_chart("test", "normal")
	
	Conductor.position = 0.0
	
	_load_audio()
	render_notes()

func _process(_delta:float):
	if not inst == null and inst.playing:
		Conductor.position = inst.get_playback_position() * 1000.0
		_update_info()

func _input(event:InputEvent):
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_SPACE:
					for sound in sounds.get_children():
						if not sound.playing:
							sound.play()
						else:
							sound.stop()
				KEY_ESCAPE: Game.switch_scene("gameplay/Gameplay")

func _exit_tree():
	Overlay.visible = true

#########################################
### CHART AND AUDIO LOADING FUNCTIONS ###
#########################################

@onready var sounds:Node = $Sounds
@onready var inst:AudioStreamPlayer = $Sounds/Inst
@onready var voices:AudioStreamPlayer = $Sounds/Voices

func _load_audio():
	for file in DirAccess.get_files_at("res://assets/songs/" + _SONG.name + "/audio"):
		
		if file.ends_with(".import"):
			var built_in:bool = false
			
			if file.begins_with("Inst"):
				built_in = true
				inst.stream = load("res://assets/songs/" + _SONG.name + "/audio/" + file.replace(".import", ""))
				inst.pitch_scale = Settings.get_setting("song_pitch")
				inst.stream.loop = false
			
			if file.begins_with("Voices") or file.begins_with("Vocals"):
				built_in = true
				voices.stream = load("res://assets/songs/" + _SONG.name + "/audio/" + file.replace(".import", ""))
				voices.pitch_scale = Settings.get_setting("song_pitch")
				voices.stream.loop = false
			
			if not built_in:
				var new_music:AudioStreamPlayer = AudioStreamPlayer.new()
				new_music.stream = load("res://assets/songs/" + _SONG.name + "/audio/" + file.replace(".import", ""))
				new_music.pitch_scale = Settings.get_setting("song_pitch")
				new_music.stream.loop = false
				sounds.add_child(new_music)

@onready var grid:TextureRect = $Grid_Layer/Grid
@onready var rendered_notes:Control = $Grid_Layer/Rendered_Notes
var grid_size:int = 40

func _update_grid_layer(): pass

func _generate_notes(_time:float, _direction:int, _hold_length:float, _type:String = "default"):
	var my_note:Note = NOTE_TYPES["default"].instantiate().set_note(_time, _direction, _type)
	my_note.hold_length = _hold_length
	
	my_note.scale = Vector2(0.45, 0.45)
	my_note.position.y = floor(y_from_time(_time))
	
	rendered_notes.add_child(my_note)

func render_notes():
	while rendered_notes.get_child_count() > 0:
		rendered_notes.get_child(0).queue_free()
		rendered_notes.remove_child(rendered_notes.get_child(0))
	
	for i in _SONG.notes.size():
		var note:ChartNote = _SONG.notes[i]
		_generate_notes(note.time, note.direction % _SONG.key_amount, note.length)

func y_from_time(time:float) -> float:
	return remap(time, 0, inst.stream.get_length(), 0, _crochet_from_length())

func time_from_y(y_pos:float) -> float:
	return remap(y_pos, 0, _crochet_from_length(), 0, inst.stream.get_length())

func _crochet_from_length() -> float:
	return (inst.stream.get_length() / Conductor.step_crochet) * grid_size

@onready var info_text:Label = $UI_Layer/Info_Text

func _update_info():
	info_text.text = "BPM: " + "%.2f" % _SONG.bpm
	info_text.text += "\nSPEED: " + "%.2f" % _SONG.speed
	
	info_text.text += "\nTIME: " + Game.format_to_time(inst.get_playback_position()) \
		+ " / " + Game.format_to_time(inst.stream.get_length())
	
	info_text.text += "\nZOOM: " + "%.2f" % current_zoom + "x / 3.0x"

###################################
### TOP BAR UI SIGNAL FUNCTIONS ###
###################################

func _on_file_button_pressed(id:int = -1):
	$UI_Layer/Top_Bar/File_Button/Popup.show()
	
	if id > -1:
		match id:
			2: Game.switch_scene("menus/OptionsMenu")

func _on_edit_button_pressed(id:int = -1):
	$UI_Layer/Top_Bar/Edit_Button/Popup.show()

func _on_notes_button_pressed(id:int = -1):
	$UI_Layer/Top_Bar/Notes_Button/Popup.show()

func _on_play_button_pressed(id:int = -1):
	$UI_Layer/Top_Bar/Play_Button/Popup.show()

func _on_help_button_pressed(id:int = -1):
	$UI_Layer/Top_Bar/Help_Button/Popup.show()
