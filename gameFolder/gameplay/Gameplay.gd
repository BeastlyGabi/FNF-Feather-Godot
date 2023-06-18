extends MusicBeatNode2D

var NOTE_TYPES:Dictionary = {
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

var song_name:String = "bopeebo"

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
	
	inst.stream = load("res://assets/songs/" + song_name + "/audio/Inst.ogg")
	voices.stream = load("res://assets/songs/" + song_name + "/audio/Voices.ogg")
	#inst.finished.connect(end_song)
	
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
	
	Timings.health = clampi(Timings.health, 0, 100)
	health_bar.value = clampi(Timings.health, 0, 100)
	
	if SONG != null and inst.stream != null:
		note_processing()
		event_processing()

func note_processing() -> void:
	while notes_list.size() > 0:
		var note_data:NoteData = notes_list[0]
		var speed:float = 2.0
		
		if note_data.time - Conductor.position > (3500 * speed):
			break
		
		var new_note:Note = NOTE_TYPES["default"].instantiate()
		new_note.time = note_data.time
		new_note.speed =  roundf(speed)
		
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
		
		print("event requested: " +cur_event.name+" timestep: "+str(cur_event.time))
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

var key_presses:Array[bool] = []

func _input(event:InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_7:
					Game.switch_scene("resources/tools/XML Converter")
		
		var key:int = StrumLine.get_key_dir(event)
		if key < 0: return
		
		key_presses[key] = Input.is_action_pressed("note_" + player_strums.directions[key])
		
		var notes_to_hit:Array[Note] = []
		for note in player_strums.notes.get_children().filter(func(note:Note):
			return (note.direction == key and note.can_be_hit and !note.too_late
			and note.must_press and !note.was_good_hit)
		): notes_to_hit.append(note)
		
		notes_to_hit.sort_custom(func(a, b):
			return b.time if a.time > b.time else a.time
		)
		
		if Input.is_action_just_pressed("note_" + player_strums.directions[key]):
			if notes_to_hit.size() > 0:
				note_hit(notes_to_hit[0])
				player_strums.play_anim("confirm", key, true)
				
				if notes_to_hit.size() > 1:
					for i in notes_to_hit.size():
						if i == 0: continue
						
						if notes_to_hit[i].direction == notes_to_hit[0].direction and \
							absf(notes_to_hit[i].time - notes_to_hit[0].time) <= 5.0:
							notes_to_hit[i].queue_free()
							break
			
			else:
				if not Settings.get_setting("ghost_tapping"):
					ghost_miss(key)

func note_hit(note:Note) -> void:
	if note.was_good_hit: return
	note.was_good_hit = true
	
	var judge:Judgement = Timings.judge_values(note.time, Conductor.position)
	damage_mult = 0.0
	
	Timings.score += Timings.score_from_judge(judge.name)
	Timings.health += Timings.health_balance(judge.health)
	
	if Timings.combo < 0: Timings.combo = 0
	Timings.combo += 1
	
	Timings.update_accuracy(judge)
	
	update_score()
	if not note.is_hold:
		note.queue_free()

func cpu_note_hit(note:Note, strum_line:StrumLine) -> void:
	note.was_good_hit = true
	
	strum_line.play_anim("confirm", note.direction, true)
	if not note.is_hold:
		note.queue_free()

var damage_mult:float = 0.0

# I ran out of function names -BeastlyGabi
func note_miss(note:Note, include_anim:bool = true) -> void:
	do_miss_damage()

func ghost_miss(direction:int, include_anim:bool = true) -> void:
	do_miss_damage(true)

func do_miss_damage(ignore_dmg_mult:bool = false):
	if damage_mult == 0.0 and !ignore_dmg_mult:
		damage_mult = 1
	
	var mult_thing:float = damage_mult if !ignore_dmg_mult else 0.1
	Timings.health -= 0.475 * mult_thing
	
	if !ignore_dmg_mult:
		damage_mult += 0.175
	
	Timings.misses += 1
	
	if Timings.combo < 0: Timings.combo == 0
	else: Timings.combo -= 1
	
	Timings.update_rank()
	update_score()
