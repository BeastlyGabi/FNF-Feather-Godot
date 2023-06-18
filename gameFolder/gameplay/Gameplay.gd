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

@onready var strum_lines:CanvasLayer = $Strum_Lines
@onready var player_strums:StrumLine = $Strum_Lines/Player_Strums

var song_name:String = "argument"

var notes_list:Array[NoteData] = []
var events_list:Array[EventData] = []

func _init() -> void:
	super._init()
	SONG = Chart.load_chart(song_name, "hard")
	if SONG != null:
		notes_list = SONG.notes.duplicate()
		events_list = SONG.events.duplicate()

func _ready() -> void:
	Timings.reset()
	
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
	
	for i in player_strums.receptors.get_children():
		key_presses.append(false)
	
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
	while notes_list.size() > 0:
		var note_data:NoteData = notes_list[0]
		var speed:float = SONG.speed
		
		if note_data.time - Conductor.position > (3500 * speed):
			break
		
		var new_note:Note = NOTE_STYLES["default"].instantiate()
		new_note.time = note_data.time
		new_note.speed = speed
		
		new_note.direction = note_data.direction % SONG.key_amount
		new_note.strum_line = note_data.strum_line
		new_note.length = note_data.length
		
		if strum_lines.get_child(new_note.strum_line) != null:
			strum_lines.get_child(new_note.strum_line).notes.add_child(new_note)
		
		notes_list.erase(note_data)

func event_processing() -> void:
	while events_list.size() > 0:
		var cur_event:EventData = events_list[0]
		if cur_event.time > Conductor.position + cur_event.delay:
			break
		
		#print("event requested: " +cur_event.name+" timestep: "+str(cur_event.time))
		events_list.erase(cur_event)

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

var key_presses:Array[bool] = []

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
		
		var key:int = StrumLine.get_key_dir(event)
		if key < 0: return
		
		key_presses[key] = Input.is_action_pressed("note_" + player_strums.directions[key])
		
		var notes_to_hit:Array[Note] = []
		for note in player_strums.notes.get_children().filter(func(note:Note):
			return (note.direction == key and note.can_be_hit and !note.too_late
			and note.must_press and !note.was_good_hit)
		): notes_to_hit.append(note)
		
		notes_to_hit.sort_custom(func(a, b):
			return int(a.time - b.time)
		)
		
		if Input.is_action_just_pressed("note_" + player_strums.directions[key]):
			if notes_to_hit.size() > 0:
				var cool_note:Note = notes_to_hit[0]
				
				if notes_to_hit.size() > 1:
					for i in notes_to_hit.size():
						if i == 0: continue
						var dumb_note:Note = notes_to_hit[i]
						
						if dumb_note.direction == cool_note.direction:
							# Same note twice at 5ms of distance? die
							if absf(dumb_note.time - cool_note.time) <= 5:
								dumb_note.queue_free()
								break
							# No? then Replace the cool note if its earlier than the dumb one
							elif dumb_note.time < cool_note.time:
								cool_note = dumb_note
								break
				
				note_hit(cool_note)
				player_strums.play_anim("confirm", key, true)
			
			else:
				if not Settings.get_setting("ghost_tapping"):
					ghost_miss(key)

func note_hit(note:Note) -> void:
	if note.was_good_hit: return
	note.was_good_hit = true
	
	var judge:Judgement = Timings.judge_values(note.time, Conductor.position)
	Timings.score += Timings.score_from_judge(judge.name)
	Timings.health += 0.023
	
	$bf.play_anim("sing" + StrumLine.directions[note.direction].to_upper(), true)
	
	if Timings.combo < 0: Timings.combo = 0
	Timings.combo += 1
	
	var needs_sick:bool = Settings.get_setting("note_splashes") == "sick only"
	if needs_sick and judge.name == "sick" or !needs_sick:
		player_strums.pop_splash(note)
	
	Timings.update_accuracy(judge)
	
	update_score()
	if not note.is_hold:
		note.queue_free()

func cpu_note_hit(note:Note, strum_line:StrumLine) -> void:
	note.was_good_hit = true
	
	strum_line.play_anim("confirm", note.direction, true)
	if !note.is_hold:
		note.queue_free()

# I ran out of function names -BeastlyGabi
func note_miss(note:Note, include_anim:bool = true) -> void:
	if note._did_miss: return
	do_miss_damage(note.is_hold)

func ghost_miss(direction:int, include_anim:bool = true) -> void:
	do_miss_damage(true)

var damage_mult:float = 0.0

func do_miss_damage(ignore_dmg_mult:bool = false):
	if damage_mult == 0.0 and !ignore_dmg_mult:
		damage_mult = 1
	
	var mult_thing:float = damage_mult if !ignore_dmg_mult else 0.1
	Timings.health -= 0.475 * mult_thing
	if !ignore_dmg_mult: damage_mult += 0.175
	Timings.misses += 1
	
	if Timings.combo > 0: Timings.combo == 0
	else: Timings.combo -= 1
	
	Timings.update_rank()
	update_score()
