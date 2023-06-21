extends MusicBeatNode2D

var NOTE_STYLES:Dictionary = {
	"default": preload("res://gameFolder/gameplay/notes/default.tscn")
}

var SONG:Chart

@onready var sounds:Node = $Sounds
@onready var inst:AudioStreamPlayer = $Sounds/Inst
@onready var voices:AudioStreamPlayer = $Sounds/Voices

@onready var ui:CanvasLayer = $User_Interface
@onready var health_bar:TextureProgressBar = $User_Interface/Health_Bar
@onready var score_text:Label = $User_Interface/Health_Bar/Score_Text

@onready var strum_lines:CanvasLayer = $User_Interface/Strum_Lines
@onready var player_strums:StrumLine = $User_Interface/Strum_Lines/Player_Strums

var song_name:String = "kaio-ken"

var notes_list:Array[Chart.NoteData] = []
var events_list:Array[Chart.EventData] = []

###################################################
### LODING FUNCTIONS YOU M4Y W4NN4 IGNORE THESE ###

func lo4d_strumlines() -> void:
	if SONG.key_amount != 4:
		for strum in strum_lines.get_children():
			var path:String = "res://gameFolder/gameplay/notes/strums/" + str(SONG.key_amount) + "K.tscn"
			if !ResourceLoader.exists(path):
				push_error("Strumline with " + str(SONG.key_amount) + " keys doesn't exist, defaulting to 4")
				SONG.key_amount = 4
				break
			
			var old_name:String = strum.name
			var old_pos:Vector2 = strum.position
			
			strum_lines.remove_child(strum)
			
			strum = load(path).instantiate()
			strum.name = old_name
			strum.position = old_pos
			
			if strum.name == "Player_Strums":
				strum.is_cpu = false
				player_strums = strum
			
			strum_lines.add_child(strum)

###################################################

func _init() -> void:
	super._init()
	SONG = Chart.load_chart(song_name, "hard")
	if SONG != null:
		notes_list = SONG.notes.duplicate()
		events_list = SONG.events.duplicate()

func _ready() -> void:
	Timings.reset()
	
	lo4d_strumlines()
	
	var audio_folder:String = "res://assets/songs/" + song_name + "/audio"
	for file in DirAccess.get_files_at(audio_folder):
		
		if file.ends_with(".import"):
			var file_path:String = audio_folder + "/" + file.replace(".import", "")
			var stream_with_scene_node:bool = false
			
			if file.begins_with("Inst"):
				stream_with_scene_node = true
				inst.stream = load(file_path)
				inst.stream.loop = false
				#inst.finished.connect(end_song)
			
			if file.begins_with("Voices") or file.begins_with("Vocals"):
				stream_with_scene_node = true
				voices.stream = load(file_path)
				voices.stream.loop = false
			
			if !stream_with_scene_node:
				var new_stream:AudioStreamPlayer = AudioStreamPlayer.new()
				new_stream.stream = load(file_path)
				new_stream.stream.loop = false
				sounds.add_child(new_stream)
	
	if !Settings.get_setting("downscroll"):
		health_bar.position.y = Game.SCREEN["height"] - 85
		for strum_line in strum_lines.get_children():
			strum_line.position.y = 100
	
	play_music(0.0)
	update_score()

func play_music(start_time:float = 0.0) -> void:
	for sound in sounds.get_children():
		sound.play(start_time)

func stop_music() -> void:
	for sound in sounds.get_children():
		sound.stop()

func _process(_delta:float) -> void:
	if (absf((inst.get_playback_position() * 1000.0) -  Conductor.position) > 8.0):
		Conductor.position = inst.get_playback_position() * 1000.0
	
	Timings.health = clampf(Timings.health, 0.0, 2.0)
	health_bar.value = clampf(Timings.health, 0.0, 2.0)
	
	if SONG != null and inst.stream != null:
		note_processing()
		event_processing()

func note_processing() -> void:
	if notes_list.size() > 0:
		if notes_list[0].time - Conductor.position > (3500 * (SONG.speed / Conductor.pitch_scale)):
			return
		
		var note_data:Chart.NoteData = notes_list[0]
		
		var new_note:Note = NOTE_STYLES["default"].instantiate()
		new_note.time = note_data.time
		new_note.speed = SONG.speed
		
		new_note.direction = int(note_data.direction % SONG.key_amount)
		new_note.strum_line = note_data.strum_line
		new_note.length = note_data.length
		
		if strum_lines.get_child(new_note.strum_line) != null:
			new_note.parent = strum_lines.get_child(new_note.strum_line)
			strum_lines.get_child(new_note.strum_line).notes.add_child(new_note)
		
		notes_list.erase(note_data)

func event_processing() -> void:
	if events_list.size() > 0:
		var cur_event:Chart.EventData = events_list[0]
		if cur_event.time > Conductor.position + cur_event.delay:
			return
		
		if ResourceLoader.exists("res://gameFolder/gameplay/events/" + cur_event.name + ".tscn"):
			var event_scene = load("res://gameFolder/gameplay/events/" + cur_event.name + ".tscn")
			add_child(event_scene.instantiate())
			event_scene.game = self
		
		else:
			fire_event(cur_event)
		
		events_list.erase(cur_event)

func fire_event(event:Chart.EventData) -> void:
	pass

var score_divider:String = " / "
func update_score() -> void:
	var score_temp:String = ""
	
	score_temp += "SCORE: " + str(Timings.score)
	score_temp += score_divider + "ACCURACY: " + "%.2f" % (Timings.accuracy * 100 / 100) + "%"
	score_temp += score_divider + "MISSES: " + str(Timings.misses)
	
	if Timings.cur_clear != "":
		score_temp += " (" + Timings.cur_clear + ")"
	
	score_temp += score_divider + Timings.cur_grade
	score_text.text = score_temp

func on_beat(beat:int) -> void:
	if !$bf.is_singing() and !$bf.is_missing():
		if beat % $bf.dance_interval == 0:
			$bf.dance(true)

func _input(event:InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_8:
					get_tree().paused = true
					var options = load("res://gameFolder/menus/Options.tscn")
					add_child(options.instantiate())
				
				KEY_6: Game.switch_scene("backend/tools/XML Converter")
				KEY_7: Game.switch_scene("backend/tools/TXT Converter")
		
		# Looking for inputs? i moved the to the StrumLine Script!

func note_hit(note:Note, strum:StrumLine) -> void:
	if note.was_good_hit: return
	note.was_good_hit = true
	
	var hit_event = note.on_hit()
	if hit_event == Note.E_STOP:
		return
	
	var judge:Judgement = Timings.judge_values(note.time, Conductor.position)
	Timings.score += Timings.score_from_judge(judge.name)
	Timings.health += 0.023
	
	var index:int = note.direction % $bf.sing_anims.size()
	$bf.play_anim($bf.sing_anims[index], true)
	
	if Timings.combo < 0: Timings.combo = 0
	Timings.combo += 1
	
	var needs_sick:bool = Settings.get_setting("note_splashes") == "sick only"
	if needs_sick and judge.name == "sick" or !needs_sick:
		strum.pop_splash(note)
	
	Timings.update_accuracy(judge)
	
	update_score()
	if not note.is_hold:
		note.queue_free()

func cpu_note_hit(note:Note, strum_line:StrumLine) -> void:
	note.was_good_hit = true
	if !note.is_hold:
		note.queue_free()

# I ran out of function names -BeastlyGabi
func note_miss(note:Note, include_anim:bool = true) -> void:
	if note._did_miss: return
	var miss_event = note.on_miss()
	if miss_event == Note.E_STOP:
		return
	
	do_miss_damage()

func ghost_miss(direction:int, include_anim:bool = true) -> void:
	do_miss_damage()

func do_miss_damage():
	Timings.health -= 0.47
	Timings.misses += 1
	
	if Timings.combo > 0: Timings.combo == 0
	else: Timings.combo -= 1
	
	Timings.update_rank()
	update_score()
