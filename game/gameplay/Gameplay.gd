class_name Gameplay extends MusicBeatNode2D

var NOTE_TYPES:Dictionary = {
	"default": preload("res://game/gameplay/notes/default.tscn"),
	"quant": preload("res://game/gameplay/notes/default-quant.tscn")
}

const PAUSE_SCREEN = preload("res://game/gameplay/subScenes/PauseScreen.tscn")
const DEFAULT_CHAR = preload("res://game/gameplay/characters/bf.tscn")
const DEFAULT_STAGE = preload("res://game/gameplay/stages/stage.tscn")

var judgements:Array[Judgement] = [
	# Name, Score Gain, Health Gain/Loss Accuracy Modifier, Note Splashes, Image
	Judgement.new("sick", 300, 100, 100.0, true),
	Judgement.new("good", 180, 80, 80.0, false),
	Judgement.new("bad", 50, 30, 60.0, false),
	Judgement.new("shit", -45, -20, 25.0, false)
]

var SONG:Chart
var song_time:float = 0.0
var note_list:Array[ChartNote] = []
var event_list:Array[ChartEvent] = []

@onready var camera:Camera2D = $Game_Camera

@onready var sounds:Node = $Sounds
@onready var inst:AudioStreamPlayer = $Sounds/Inst
@onready var voices:AudioStreamPlayer = $Sounds/Voices


@onready var ui:CanvasLayer = $UI
@onready var layer_other:CanvasLayer = $Other

@onready var score_text:Label = $UI/Health_Bar/Score_Text

@onready var counter_text:Label = $UI/Judgement_Counter
@onready var health_bar:TextureProgressBar = $UI/Health_Bar

@onready var icon_P1:PlumaSprite2D = $UI/Health_Bar/Player_Icon
@onready var icon_P2:PlumaSprite2D = $UI/Health_Bar/Cpu_Icon

@onready var strum_lines:Node2D = $UI/Strum_Lines
@onready var player_strums:StrumLine = $UI/Strum_Lines/Player
@onready var cpu_strums:StrumLine = $UI/Strum_Lines/CPU

@onready var combo_group:Node = $Combo_Group

var stage:Stage
var spectator:Character
var opponent:Character
var player:Character

var valid_score:bool = true
var script_stack:Array[PlumaScript] = []

func _init():
	super._init()
	
	SONG = Chart.load_chart(Song.data["folder"], Song.data["difficulty"])
	if not SONG == null:
		note_list = SONG.notes.duplicate()
		event_list = SONG.events.duplicate()
		Song.current = SONG

func load_scripts_at(path:String):
	for file in DirAccess.get_files_at(path):
		if file.ends_with(".gd") or file.ends_with(".gdscript"):
			var script:PlumaScript = PlumaScript.load_script(path + "/" + file, self)
			if not script_stack.has(script):
				script_stack.append(script)

func _ready():
	load_scripts_at("res://assets/data/scripts/global")
	load_scripts_at("res://assets/data/scripts/songs/" + SONG.name)
	
	var stage_path:String = "res://game/gameplay/stages/" + SONG.stage + ".tscn"
	if ResourceLoader.exists(stage_path):
		stage = load(stage_path).instantiate()
	else:
		stage = DEFAULT_STAGE.instantiate()
	
	var opponent_is_spectator:bool = SONG.characters[1] == SONG.characters[2]
	
	var character_path:String = "res://game/gameplay/characters/"
	if ResourceLoader.exists(character_path + SONG.characters[1] + ".tscn"):
		opponent = load(character_path + SONG.characters[1] + ".tscn").instantiate()
	else:
		opponent = DEFAULT_CHAR.instantiate()
	
	opponent.position = stage.spectator_position if opponent_is_spectator else stage.opponent_position
	opponent.is_player = false
	
	if ResourceLoader.exists(character_path + SONG.characters[0] + ".tscn"):
		player = load(character_path + SONG.characters[0] + ".tscn").instantiate()
	else:
		player = DEFAULT_CHAR.instantiate()
	
	player.position = stage.player_position
	player.is_player = true
	
	if ResourceLoader.exists(character_path + SONG.characters[2] + ".tscn"):
		spectator = load(character_path + SONG.characters[2] + ".tscn").instantiate()
	else:
		spectator = DEFAULT_CHAR.instantiate()
	
	spectator.position = stage.spectator_position
	spectator.is_player = false
	if opponent_is_spectator:
		spectator.queue_free()
	
	add_child(stage)
	stage.add_child(spectator)
	stage.add_child(opponent)
	stage.add_child(player)
	
	remove_child(combo_group)
	add_child(combo_group)
	
	stage.modulate.a = Settings.get_setting("stage_visibility") * 0.01
	
	trigger_event(event_list[0])
	
	for i in script_stack.size():
		script_stack[i]._ready()
	
	if Settings.get_setting("character_healthcolors"):
		health_bar.tint_progress = player.health_color
		health_bar.tint_under = opponent.health_color
	
	health_bar.position.y = 63 if Settings.get_setting("downscroll") else 630
	
	icon_P1.texture = load("res://assets/images/icons/" + player.health_icon + ".png")
	icon_P2.texture = load("res://assets/images/icons/" + opponent.health_icon + ".png")
	
	for strum_line in strum_lines.get_children():
		strum_line.position.y = 625 if Settings.get_setting("downscroll") else 95
	
	if Settings.get_setting("centered_receptors"):
		player_strums.position.x = Game.SCREEN["width"] / 2.0
		cpu_strums.scale = Vector2(0.5, 0.5)
		cpu_strums.position.x += 100
		cpu_strums.modulate.a = 0.6
		
		for i in [2, 3]:
			cpu_strums.receptors.get_child(i).position.x += player_strums.position.x + 255
	
	cpu_strums.visible = Settings.get_setting("cpu_receptors")
	
	# Setup the Game Camera
	camera.zoom = Vector2(stage.camera_zoom, stage.camera_zoom)
	camera.position_smoothing_speed = 3 * stage.camera_speed * Conductor.pitch_scale
	camera.position_smoothing_enabled = true
	
	# And the Audio Tracks
	for file in DirAccess.get_files_at("res://assets/songs/" + SONG.name + "/audio"):
		
		if file.ends_with(".import"):
			var built_in:bool = false
			
			if file.begins_with("Inst"):
				built_in = true
				inst.stream = load("res://assets/songs/" + SONG.name + "/audio/" + file.replace(".import", ""))
				inst.pitch_scale = Settings.get_setting("song_pitch")
				inst.finished.connect(end_song)
				inst.stream.loop = false
			
			if file.begins_with("Voices") or file.begins_with("Vocals"):
				built_in = true
				voices.stream = load("res://assets/songs/" + SONG.name + "/audio/" + file.replace(".import", ""))
				voices.pitch_scale = Settings.get_setting("song_pitch")
				voices.stream.loop = false
			
			if not built_in:
				var new_music:AudioStreamPlayer = AudioStreamPlayer.new()
				new_music.stream = load("res://assets/songs/" + SONG.name + "/audio/" + file.replace(".import", ""))
				new_music.pitch_scale = Settings.get_setting("song_pitch")
				new_music.stream.loop = false
				sounds.add_child(new_music)
	
	counter_text.visible = Settings.get_setting("judgement_counter")
	
	# Setup Keys for Inputs later
	for key in player_strums.receptors.get_child_count():
		keys_held.append(false)
	
	for i in judgements.size():
		judgements_gotten[judgements[i].name] = 0
	
	update_score_text()
	if counter_text.visible:
		update_judgement_counter()
	
	# Start Countdown
	begin_countdown()
	
	for i in script_stack.size():
		script_stack[i]._post_ready()

var starting_song:bool = true
var began_count:bool = false

var count_tween:Tween
var count_timer:SceneTreeTimer
var count_tick:int = 0

func begin_countdown():
	Conductor.position = -(Conductor.crochet * 5.3)

	#if Game.gameplay_mode == 0:
	for i in strum_lines.get_children():
		i.fade_receptors_in()
	
	for i in script_stack.size():
		script_stack[i].begin_countdown()
	
	began_count = true
	reset_countdown_timer()

func process_countdown(reset:bool = false):
	for i in script_stack.size():
		script_stack[i].on_countdown(count_tick)
	
	if not count_tween == null:
		count_tween.stop()
	
	if reset:
		count_tick = 0
	
	var intro_images:Array[String] = ["prepare", "ready", "set", "go"]
	var intro_sounds:Array[String] = ["intro3", "intro2", "intro1", "introGo"]
	
	var countdown_sprite:PlumaSprite2D = $UI/Countdown_Template.duplicate()
	countdown_sprite.texture = load("res://assets/images/ui/countdown/" + SONG.song_style + "/" + intro_images[count_tick] + ".png")
	countdown_sprite.visible = true
	countdown_sprite.modulate.a = 1.0
	if SONG.song_style == "pixel":
		countdown_sprite.scale = Vector2(6, 6)
		countdown_sprite.texture_filter = TEXTURE_FILTER_NEAREST
	ui.add_child(countdown_sprite)
	
	# tween out
	var scaled_crochet:float = 0.85 * (Conductor.crochet / 1000) / Conductor.pitch_scale
	
	count_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	count_tween.tween_property(countdown_sprite, "modulate:a", 0.0, scaled_crochet) \
	.finished.connect(countdown_sprite.queue_free)
	
	SoundHelper.play_sound("res://assets/audio/sfx/game/" + SONG.song_style + "/" + intro_sounds[count_tick] + ".ogg")
	count_tick += 1
	
	_characters_dance(count_tick)
	
	if count_tick < 4:
		reset_countdown_timer()

func reset_countdown_timer():
	var scaled_crochet:float = (Conductor.crochet / 1000) / Conductor.pitch_scale
	count_timer = get_tree().create_timer(scaled_crochet, false)
	count_timer.timeout.connect(process_countdown)

func start_song():
	starting_song = false
	play_music(0.0)

var health_bar_width:float:
	get: return health_bar.texture_progress.get_size().x

func _process(delta:float):
	for i in script_stack.size():
		script_stack[i]._process(delta)
	
	if starting_song and began_count:
		Conductor.position += ((delta * 1000.0) * Conductor.pitch_scale)
		if Conductor.position >= 0:
			start_song()
	else:
		if (absf((inst.get_playback_position() * 1000.0) -  Conductor.position) > 8.0):
			Conductor.position = inst.get_playback_position() * 1000.0
	
	if (player.hold_timer >= Conductor.step_crochet * player.sing_duration * 0.0011
		and not keys_held.has(true)):
		player.dance()
		player.hold_timer = 0.0
	
	# Update the UI elements and such
	for i in [icon_P1, icon_P2]:
		var i_lerp:float = lerpf(i.scale.x, 0.9, 0.05)
		i.scale.x = i_lerp
		i.scale.y = i_lerp
	
	health = clampi(health, 0, 100)
	health_bar.value = clampi(health, 0, 100)
	
	icon_P1.position.x = health_bar.position.x + ((health_bar_width*(1 - health_bar.value / 100)) - icon_P1.width)
	icon_P2.position.x = health_bar.position.x + ((health_bar_width*(1 - health_bar.value / 100)) - icon_P2.width) - 80

	icon_P1.frame = 1 if health_bar.value < 20 else 0
	icon_P2.frame = 1 if health_bar.value > 80 else 0
	
	var cam_lerp:float = lerpf(camera.zoom.x, stage.camera_zoom, 0.01)
	camera.zoom = Vector2(cam_lerp, cam_lerp)
	
	var hud_lerp:float = lerpf(ui.scale.x, 1, 0.03)
	ui.scale = Vector2(hud_lerp, hud_lerp)
	hud_bump_reposition()
	
	if Input.is_action_just_pressed("ui_pause"):
		layer_other.add_child(PAUSE_SCREEN.instantiate())
		get_tree().paused = true
	
	if not SONG == null and not inst.stream == null:
		process_notes()
		process_events()

	for i in script_stack.size():
		script_stack[i]._post_process(delta)

func process_notes():
	while note_list.size() > 0:
		var note:ChartNote = note_list[0]
		
		var note_speed:float = SONG.speed if Settings.get_setting("note_speed") <= 0.0 else Settings.get_setting("note_speed")
		if note.time - Conductor.position > (3500 * (note_speed / Conductor.pitch_scale)):
			break
		
		var note_type:String = "default"
		if ResourceLoader.exists("res://game/gameplay/notes/" + note.type + ".tscn"):
			NOTE_TYPES[note.type] = load("res://game/gameplay/notes/" + note.type + ".tscn")
			note_type = note.type
		
		if note_type == "default" and Settings.get_setting("note_quantization"):
			note_type = "quant"
		
		var new_note:Note = NOTE_TYPES[note_type].instantiate() \
		.set_note(note.time - Conductor.note_offset, note.direction % SONG.key_amount, note_type)
		
		new_note.speed = note_speed
		new_note.hold_length = note.length
		new_note.strum_line = note.strum_line
		new_note.must_press = new_note.strum_line == 1
		
		for i in script_stack.size():
			script_stack[i].note_spawn(new_note)
		
		strum_lines.get_child(note.strum_line).notes.add_child(new_note)
		note_list.erase(note)

func process_events():
	while event_list.size() > 0:
		var event:ChartEvent = event_list[0]
		if event == null or Conductor.position < event.time:
			return
		
		trigger_event(event)
		event_list.erase(event)

var score_separator:String = " / "

func update_score_text():
	var rank_string:String = rank_name
	var score_final:String = ""
	
	var misses_name:String = "MISSES"
	var miss_count:int = misses
	
	if not Settings.get_setting("combo_break_judgement") == "miss":
		misses_name = "COMBO BREAKS"
		miss_count = breaks
	
	score_final = ""
	
	if not Settings.get_setting("hide_accuracy"):
		if not Settings.get_setting("hide_score"):
			score_final += "SCORE: " + "%s" % score + score_separator
		
		score_final += misses_name + ": " + "%s" % miss_count
		if not clear_rank == null and not clear_rank == "":
			score_final += " [" + clear_rank + "]"
		
		score_final += score_separator + "RANK: " + rank_name
		if total_notes_hit > 0:
			score_final += " [" + "%.2f" % (accuracy * 100 / 100) + "%" + "]"
	
	else:
		if not Settings.get_setting("hide_score"):
			score_final += "SCORE: " + str(score) + score_separator
		
		score_final += misses_name + ": " + str(miss_count)

	score_text.text = score_final

func update_judgement_counter():
	var counter_final:String = ""
	for i in judgements_gotten:
		counter_final += i.to_upper() + ": " + str(judgements_gotten[i]) + '\n'
	if not Settings.get_setting("combo_break_judgement") == "miss": 
		counter_final += "MISS: " + str(misses)
	
	counter_text.text = counter_final

var cam_zoom:Dictionary = {
	"interval": 4,
	"hud_interval": 4,
	"bump_strength": 0.050,
	"hud_bump_strength": 0.035
}
var icon_beat_scale:float = 0.25

func on_beat(beat:int):
	for i in script_stack.size():
		script_stack[i].on_beat(beat)
	
	stage.on_beat(beat)
	_characters_dance(beat)
	
	for i in [icon_P1, icon_P2]:
		i.scale = Vector2(i.scale.x + icon_beat_scale, i.scale.y + icon_beat_scale)
	
	# camera beat stuffs
	if beat % cam_zoom["interval"] == 0:
		camera.zoom += Vector2(cam_zoom["bump_strength"], cam_zoom["bump_strength"])
	
	if beat % cam_zoom["hud_interval"] == 0:
		ui.scale += Vector2(cam_zoom["hud_bump_strength"], cam_zoom["hud_bump_strength"])
		hud_bump_reposition()
	
	for strum in strum_lines.get_children():
		for note in strum.notes.get_children():
			note.on_beat(beat)

# @swordcube
func hud_bump_reposition():
	ui.offset.x = (ui.scale.x - 1.0) * -(Game.SCREEN["width"] * 0.5)
	ui.offset.y = (ui.scale.y - 1.0) * -(Game.SCREEN["height"] * 0.5)

func _characters_dance(beat:int):
	var characters:Array[Character] = [player, opponent]
	if not spectator == null: characters.append(spectator)
	
	for char in characters:
		if beat % char.headbop_beat == 0:
			if not char.is_singing() or not char.is_missing() \
			and char.finished_anim:
				char.dance()

func on_step(step:int):
	for i in script_stack.size():
		script_stack[i].on_step(step)
	
	for strum in strum_lines.get_children():
		for note in strum.notes.get_children():
			note.on_step(step)
	
	stage.on_step(step)

func on_sect(sect:int):
	for i in script_stack.size():
		script_stack[i].on_sect(sect)
	
	for strum in strum_lines.get_children():
		for note in strum.notes.get_children():
			note.on_sect(sect)
	
	stage.on_sect(sect)

func trigger_event(event:ChartEvent):
	match event.name:
		"BPM Change":
			if not event.arguments[0] == null:
				Conductor.change_bpm(event.arguments[0])
			
		"Camera Pan":
			var arg = event.arguments[0]
			
			var char:Character = opponent
			var stage_offset:Vector2 = stage.opponent_camera
			
			match arg:
				"player":
					char = player
					stage_offset = stage.player_camera
				"opponent":
					char = opponent
					stage_offset = stage.opponent_camera
			
			var offset:Vector2 = Vector2(char.camera_offset.x + stage_offset.x, char.camera_offset.y + stage_offset.y)
			camera.position = Vector2(char.get_camera_midpoint().x + offset.x, char.get_camera_midpoint().y + offset.y)

func play_music(time:float = 0.0):
	for sound in sounds.get_children():
		if not sound.stream == null:
			sound.play(time)

func stop_music():
	for sound in sounds.get_children():
		if not sound.stream == null:
			sound.stop()
	
func end_song():
	stop_music()
	
	if valid_score:
		Song.save_score(Song.data["folder"] + '-' + Song.data["difficulty"], score, "songs")
	
	match Song.gameplay_mode:
		Song.STORY_MODE:
			if Song.playlist.size() > 1:
				Song.playlist.pop_front()
				Song.total_week_score += score
				
				Song.data["name"] = Song.playlist[0].name
				Song.data["folder"] = Song.playlist[0].folder
				Song.reset_scene()
				
			else:
				if valid_score:
					Song.save_score(Song.cur_week + " Week -" + Game.gameplay_song["difficulty"], Game.total_week_score, "weeks")
				Game.switch_scene("menus/StoryMenu")
			
		_: Game.switch_scene("menus/FreeplayMenu")
		Song.CHARTING_MODE: Game.switch_scene("gameplay/editors/ChartEditor")

var keys_held:Array[bool] = []

func _input(event:InputEvent):
	if event is InputEventKey:
		if event.pressed: match event.keycode:
			KEY_6:
				player_strums.is_cpu = not player_strums.is_cpu
				$UI/Autoplay_Text.visible = player_strums.is_cpu
				valid_score = false
			KEY_7: Game.switch_scene("gameplay/editors/ChartEditor")
			
		var dir:int = get_input_dir(event)
		if dir < 0 or player_strums.is_cpu:
			return
		
		keys_held[dir] = Input.is_action_pressed("note_" + Game.note_dirs[dir].to_lower())
		
		var hit_notes:Array[Note] = []
		# cool thanks swordcube
		for note in player_strums.notes.get_children().filter(func(note:Note):
			return (note.direction == dir and not note.was_too_late \
			and note.can_be_hit and note.must_press \
			and not note.was_good_hit)
		): hit_notes.append(note)
		
		# the actual dumb thing
		if Input.is_action_just_pressed("note_" + Game.note_dirs[dir].to_lower()):
			
			if hit_notes.size() > 0:
				note_hit(hit_notes[0])
				
				# handles stacked notes
				if hit_notes.size() > 1:
					for i in hit_notes.size():
						if i == 0: continue
						
						var bad_note:Note = hit_notes[i]
						if absf(bad_note.time - hit_notes[0].time) <= 5.0 \
							and hit_notes[0].direction == dir:
								bad_note.queue_free()
						break
			else:
				if not Settings.get_setting("ghost_tapping"):
					ghost_miss(dir)

func get_input_dir(e:InputEventKey):
	var stored_number:int = -1
	
	for i in Game.note_dirs.size():
		var a:String = "note_" + Game.note_dirs[i].to_lower()
		if e.is_action_pressed(a) or e.is_action_released(a):
			stored_number = i
			break
	
	return stored_number

var score:int = 0
var misses:int = 0
var breaks:int = 0:
	get:
		if not Settings.get_setting("combo_break_judgement") == "miss":
			return misses + judgements_gotten[Settings.get_setting("combo_break_judgement")]
		
		return misses

var health:float = 50
var combo:int = 0

var notes_accuracy:float = 0.00
var total_notes_hit:int = 0
var accuracy:float = 0.00:
	get:
		if notes_accuracy <= 0.00: return 0.00
		return (notes_accuracy / (total_notes_hit + breaks))

var judgements_gotten:Dictionary = {}

func note_hit(note:Note):
	var event = note.on_note_hit(true)
	if event == Note.EVENT_STOP:
		return
	
	if note.was_good_hit: return
	note.was_good_hit = true
	
	for i in script_stack.size():
		script_stack[i].note_hit(note)
	
	player.play_anim("sing" + Game.note_dirs[note.direction].to_upper(), true)
	player.hold_timer = 0.0
	
	var receptor:Receptor = player_strums.receptors.get_child(note.direction)
	if not receptor.material == null and receptor.material is ShaderMaterial:
		var new_color = Color8(255, 255, 255)
		
		if not note.arrow.material == null and note.arrow.material is ShaderMaterial:
			new_color = note.arrow.material.get_shader_parameter("color")
		
		receptor.material.set_shader_parameter("color", new_color)
	
	receptor.play_anim(Game.note_dirs[note.direction].to_lower() + " confirm")
	
	if not voices.stream == null:
		voices.volume_db = 0
	
	var judging_allowed:bool = not player_strums.is_cpu
	
	if judging_allowed:
		var note_ms:float = absf(note.time - Conductor.position) * Conductor.pitch_scale
		var note_judgement:Judgement
		
		for i in judgements.size():
			if note_ms > judgements[i].timing:
				continue
			else:
				note_judgement = judgements[i]
				break
		
		score += note_judgement.score
		if combo < 0:
			combo = 0
		combo += 1
		health += note_judgement.health / 50
		
		# Accuracy
		total_notes_hit += 1
		notes_accuracy += maxf(0, note_judgement.accuracy)
		judgements_gotten[note_judgement.name] += 1
		
		if note_judgement.name == "sick" or note.splash:
			player_strums.pop_splash(note)
		
		if note_judgement.name == Settings.get_setting("combo_break_judgement"):
			if player.miss_animations.size() > 0:
				player.play_anim(player.miss_animations[note.direction], true)
				health -= 0.875 * damage_multiplier
		
		damage_multiplier = 0.0
		
		if not Settings.get_setting("combo_stacking"):
			for c in combo_group.get_children():
				c.queue_free()
		
		display_judgement(note_judgement.img)
		#if combo >= 10 or combo == 0 or combo == 1:
		display_combo()
		
		update_ranking()
		update_score_text()
		if counter_text.visible:
			update_judgement_counter()
	
	if not note.is_hold:
		note.queue_free()

func cpu_note_hit(note:Note, strum_line:StrumLine):
	var event = note.on_note_hit(strum_line == player_strums)
	if event == Note.EVENT_STOP:
		return
	
	if note.arrow.visible and note.must_press:
		strum_line.pop_splash(note)
	
	var char:Character = player if note.must_press else opponent
	char.play_anim("sing" + Game.note_dirs[note.direction].to_upper(), true)
	char.hold_timer = 0.0
	
	if not voices.stream == null:
		voices.volume_db = 0.0

	note.was_good_hit = true
	if not note.is_hold:
		note.queue_free()

func note_miss(note:Note, play_anim:bool = true):
	var event = note.on_note_miss()
	if event == Note.EVENT_STOP:
		return
	
	if not note.can_be_missed:
		return
	
	for i in script_stack.size():
		script_stack[i].note_miss(note)
	
	ghost_miss(note.direction, play_anim)

var damage_multiplier:float = 0.0

func ghost_miss(direction:int, play_anim:bool = true):
	for i in script_stack.size():
		script_stack[i].ghost_miss(direction)
	
	misses += 1
	health -= 0.875 * damage_multiplier
	score -= 50
	
	damage_multiplier += 0.25
	
	if play_anim and player.miss_animations.size() > 0:
		player.play_anim(player.miss_animations[direction], true)
		SoundHelper.play_sound("res://assets/audio/sfx/game/" + SONG.song_style + "/miss" + str(randi_range(1, 3)) + ".ogg", randf_range(-20, -10))
	
	decrease_combo(true)
	if not voices.stream == null:
		voices.volume_db = -50
	
	if not Settings.get_setting("combo_stacking"):
		for c in combo_group.get_children():
			c.queue_free()
	
	display_judgement("miss")
	#if combo <= -10 or combo == -1 or combo == 0:
	display_combo(Color8(96, 96, 96))
	
	update_ranking()
	update_score_text()
	if counter_text.visible:
		update_judgement_counter()

func decrease_combo(missing:bool, force:bool = false):
	if combo > 0 or force: combo = 0
	if missing: combo -= 1

func display_judgement(judge:String, color = null):
	var judgement:PlumaSprite2D = $Templates/Judgement.duplicate()
	judgement.texture = load("res://assets/images/ui/ratings/" + SONG.song_style + "/" + judge + ".png")
	var og_scale:Vector2 = judgement.scale
	
	if SONG.song_style == "pixel":
		judgement.scale = Vector2(4.5, 4.5)
		judgement.texture_filter = TEXTURE_FILTER_NEAREST
	else:
		judgement.scale = og_scale * 1.15
	judgement.visible = true
	
	if not SONG.song_style == "pixel":
		get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC) \
		.tween_property(judgement, "scale", og_scale, 0.15)
	
	if not color == null:
		judgement.modulate = color
	
	combo_group.add_child(judgement)
	
	judgement.acceleration.y = 550 * Conductor.pitch_scale
	judgement.velocity.y = -randi_range(140, 175) * Conductor.pitch_scale
	judgement.velocity.x = -randi_range(0, 10) * Conductor.pitch_scale
	
	get_tree().create_tween().tween_property(judgement, "modulate:a", 0.0, 0.50) \
	.set_delay(Conductor.step_crochet * 0.001).finished.connect(judgement.queue_free)

func display_combo(color = null):
	# split combo in half
	var combo_string:String = ("x" + str(combo).pad_zeros(3)) if not combo < 0 else str(combo).pad_zeros(3)
	var numbers:PackedStringArray = combo_string.split("")
	
	for i in numbers.size():
		var combo_num:PlumaSprite2D = $Templates/Combo_Number.duplicate()
		combo_num.texture = load("res://assets/images/ui/combo/" + SONG.song_style + "/num" + numbers[i] + ".png")
		var og_scale:Vector2 = combo_num.scale
		
		if SONG.song_style == "pixel":
			combo_num.scale = 10.0 * og_scale
			combo_num.texture_filter = TEXTURE_FILTER_NEAREST
		else:
			combo_num.scale = og_scale * 0.85
		
		combo_num.visible = true
		combo_num.position.x += (45 * i)
		
		if not SONG.song_style == "pixel":
			get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC) \
			.tween_property(combo_num, "scale", og_scale, 0.05)
		
		if not color == null:
			combo_num.modulate = color
		
		# offset for new sprites woo
		if numbers[i] == 'x':
			combo_num.position.y += 15
		elif numbers[i] == '-':
			combo_num.position.y += 5
		
		combo_group.add_child(combo_num)
		
		combo_num.acceleration.y = randi_range(200, 350) * Conductor.pitch_scale
		combo_num.velocity.y = -randi_range(140, 160) * Conductor.pitch_scale
		combo_num.velocity.x = -randi_range(-5, 5) * Conductor.pitch_scale
		
		get_tree().create_tween().tween_property(combo_num, "modulate:a", 0.0,  0.2) \
		.set_delay(Conductor.step_crochet * 0.002).finished.connect(combo_num.queue_free)
	
	display_combo_sprite(color)

func display_combo_sprite(color = null):
	var combo_label:PlumaSprite2D = $Templates/Combo_Label.duplicate()
	combo_label.texture = load("res://assets/images/ui/ratings/" + SONG.song_style + "/combo.png")
	var og_scale:Vector2 = combo_label.scale
	
	if SONG.song_style == "pixel":
		combo_label.scale = og_scale * 8.0
		combo_label.texture_filter = TEXTURE_FILTER_NEAREST
	else:
		combo_label.scale = og_scale * 0.65
	combo_label.visible = true
	
	if not color == null:
		combo_label.modulate = color
	
	if not SONG.song_style == "pixel":
		get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC) \
		.tween_property(combo_label, "scale", og_scale, 0.05)
	
	combo_group.add_child(combo_label)
	
	combo_label.acceleration.y = 600 * Conductor.pitch_scale
	combo_label.velocity.y = -150 * Conductor.pitch_scale
	combo_label.velocity.x = -randi_range(1, 10) * Conductor.pitch_scale
	
	get_tree().create_tween().tween_property(combo_label, "modulate:a", 0.0, 0.30) \
	.set_delay(Conductor.step_crochet * 0.0005).finished.connect(combo_label.queue_free)

var rank_name:String = "N/A"
var clear_rank:String = ""
var rankings:Dictionary = {
	"S": 100.0, "A+": 95.0, "A": 90.0, "B": 85.0, "B-": 80.0, "C": 70.0,
	"SX": 69.0, "D+": 68.0, "D": 50.0, "D-": 15.0, "F": 0
}

func update_ranking():
	# loop through the rankings map
	var biggest:float = 0.0
	for rank in rankings.keys():
		if rankings[rank] <= accuracy and rankings[rank] >= biggest:
			rank_name = rank
			biggest = accuracy
	
	clear_rank = ""
	if breaks == 0: # Etterna shit
		if judgements_gotten["sick"] > 0:
			
			clear_rank = "MFC"
			
		if judgements_gotten["good"] > 0:
			
			if judgements_gotten["good"] >= 10:
				clear_rank = "GFC"
			else:
				clear_rank = "SDG"
			
		if judgements_gotten["bad"] > 0:
			
			if judgements_gotten["bad"] >= 10:
				clear_rank = "FC"
			else:
				clear_rank = "SDB"
	else:
		if breaks < 10:
			clear_rank = "SDCB"
