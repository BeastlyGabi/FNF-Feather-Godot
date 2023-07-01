extends MusicBeatNode2D

var NOTE_STYLES:Dictionary = {
	"default": preload("res://gameFolder/gameplay/notes/default.tscn")
}

var SONG:Chart
var STYLE:UIStyle

@onready var camera:Camera2D = $Camera2D

@onready var sounds:Node = $Sounds
@onready var inst:AudioStreamPlayer = $Sounds/Inst
@onready var voices:AudioStreamPlayer = $Sounds/Voices

@onready var ui:CanvasLayer = $UI
@onready var health_bar:TextureProgressBar = $UI/Health_Bar
@onready var score_text:Label = $UI/Health_Bar/Score_Text
@onready var combo_group:Node2D = $UI/Combo_Group

@onready var icon_P1 := $UI/Health_Bar/Player_icon
@onready var icon_P2 := $UI/Health_Bar/Opponent_icon

@onready var strum_lines:CanvasLayer = $Strum_Lines
@onready var player_strums:StrumLine = $Strum_Lines/Player_Strums

@onready var player:Character = $Player
@onready var opponent:Character = $Opponent

@onready var stage:Stage = $Stage

var notes_list:Array[Chart.NoteData] = []
var events_list:Array[Chart.EventData] = []

###################################################
### LOADING FUNCTIONS YOU MAY WANNA IGNORE THESE ###

func setup_stage() -> void: pass

func load_strumlines() -> void:
	if SONG.key_amount != 4:
		for strum in strum_lines.get_children():
			var path:String = "res://gameFolder/gameplay/notes/strums/" + str(SONG.key_amount) + "K.tscn"
			if not ResourceLoader.exists(path):
				print_debug("Strumline with " + str(SONG.key_amount) + " keys doesn't exist, defaulting to 4")
				SONG.key_amount = 4
				break
			
			var old_name:String = strum.name
			var old_pos:Vector2 = strum.position
			
			strum.queue_free()
			
			strum = load(path).instantiate()
			strum.name = old_name
			strum.position = old_pos
			
			if strum.name == "Player_Strums":
				strum.is_cpu = false
				player_strums = strum
			
			strum_lines.add_child(strum)

func _load_char(_new_char:String) -> Character:
	var base_path:String = "res://gameFolder/gameplay/characters/"
	var _char:Character = load(base_path + _new_char + ".tscn").instantiate()
	_char.name = _new_char
	return _char

func setup_characters() -> void:
	#var number:int = 0
	#for char in [player, opponent]:
	#	var to_load:String = "bf"
	#	if ResourceLoader.exists("res://gameFolder/gameplay/characters/" + SONG.characters[number] + ".tscn"):
	#		to_load = SONG.characters[number]
	#	
	#	char = _load_char(to_load)
	#	char.is_player = char == player
	#	add_child(char)
	
	player.position = stage.player_position
	opponent.position = stage.opponent_position
	
	icon_P1.texture = load("res://assets/images/icons/" + player.health_icon + ".png")
	icon_P2.texture = load("res://assets/images/icons/" + opponent.health_icon + ".png")
	
	# kinda eh sysm probably gonna redo later
	var opponent_strums:StrumLine = $Strum_Lines/Opponent_Strums
	for shit in [opponent_strums.dancers, opponent_strums.singers]:
		shit.append(opponent)
	
	for piss in [player_strums.dancers, player_strums.singers]:
		piss.append(player)

###################################################

func _init() -> void:
	super._init()
	SONG = Game.CUR_SONG if Game.CUR_SONG != null else Chart.load_chart("test", "normal")
	
	var style_folder:String = "res://gameFolder/ui/styles/" + SONG.ui_style + ".tscn"
	if not ResourceLoader.exists(style_folder):
		style_folder = "res://gameFolder/ui/styles/normal.tscn"
	STYLE = load(style_folder).instantiate()
	add_child(STYLE)
	
	notes_list = SONG.notes.duplicate()
	events_list = SONG.events.duplicate()

func _ready() -> void:
	Timings.reset()
	
	setup_stage()
	load_strumlines()
	setup_characters()
	fire_event("Simple Camera Movement", ["opponent"])
	
	if stage != null:
		camera.zoom = Vector2(stage.camera_zoom, stage.camera_zoom)
		camera.position_smoothing_speed = 3 * stage.camera_speed * Conductor.playback_rate
	
	var audio_folder:String = "res://assets/songs/" + SONG.name + "/audio"
	for file in DirAccess.get_files_at(audio_folder):
		
		if file.ends_with(".import"):
			var file_path:String = audio_folder + "/" + file.replace(".import", "")
			var stream_with_scene_node:bool = false
			
			if file.begins_with("Inst"):
				stream_with_scene_node = true
				inst.stream = load(file_path)
				inst.stream.loop = false
				inst.finished.connect(end_song)
			
			if file.begins_with("Voices") or file.begins_with("Vocals"):
				stream_with_scene_node = true
				voices.stream = load(file_path)
				voices.stream.loop = false
			
			if not stream_with_scene_node:
				var new_stream:AudioStreamPlayer = AudioStreamPlayer.new()
				new_stream.stream = load(file_path)
				new_stream.stream.loop = false
				sounds.add_child(new_stream)
	
	if not Settings.get_setting("downscroll"):
		health_bar.position.y = Game.SCREEN["height"] - 85
		for strum_line in strum_lines.get_children():
			strum_line.position.y = 100
	
	update_score()
	begin_countdown()

func _exit_tree():
	Conductor.playback_rate = 1.0

func start_cutscene() -> void:
	if ResourceLoader.exists("res://gameFolder/gameplay/cutscenes/" + SONG.name + ".tscn"):
		var cutscene_bs:PackedScene = load("res://gameFolder/gameplay/cutscenes/" + SONG.name + ".tscn")
		
		cutscene_bs.game = self
		cutscene_bs.call("song_beginning" if not ending_song else "song_ending", [])
		add_child(cutscene_bs.instantiate())
	
	else:
		if ending_song:
			end_song(true)
		else:
			begin_countdown()

var count_position:int = 0
var count_tweener:Tween
var count_timer:Timer

func begin_countdown() -> void:
	Conductor.position = -(Conductor.crochet * 1.2)
	count_timer = Timer.new()
	add_child(count_timer)
	
	await get_tree().create_timer(0.35).timeout
	process_countdown(true)

func process_countdown(reset:bool = false) -> void:
	if reset:
		count_position = 0
	
	var countdown_spr:Sprite2D = STYLE.get_template("Countdown_Sprite").duplicate()
	countdown_spr.texture = load(STYLE.get_asset("images/UI/countdown", \
	STYLE.countdown_config["sprites"][count_position] + ".png"))
	
	countdown_spr.visible = true
	countdown_spr.modulate.a = 0.0
	ui.add_child(countdown_spr)
	
	if count_tweener != null: count_tweener.stop()
	count_tweener = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	# THERE'S NO WAY A BEE SHOULD BE ABLE TO FLY (2)
	count_tweener.tween_property(countdown_spr, "modulate:a", 1.0, 0.05)
	count_tweener.tween_property(countdown_spr, "modulate:a", 0.0, Conductor.step_crochet / 1100.0)
	
	Sound.play_sound(STYLE.get_asset("audio/sfx/game", \
	STYLE.countdown_config["sounds"][count_position] + ".ogg"))
	
	count_position += 1
	
	count_timer.start(Conductor.step_crochet / 1000.0)
	await count_timer.timeout
	if count_position < 4:
		process_countdown()
		return
	else:
		# ITS WINGS ARE TOO SMALL TO GET ITS FAT BODY OFF THE GROUND. (3)
		if countdown_spr != null: countdown_spr.queue_free()
		count_timer.queue_free()
	
	start_song()

var starting_song:bool = true
var ending_song:bool = false

func play_music(start_time:float = 0.0) -> void:
	for sound in sounds.get_children():
		sound.play(start_time)

func stop_music() -> void:
	for sound in sounds.get_children():
		sound.stop()

func start_song() -> void:
	starting_song = false
	play_music(0.0)

func end_song(_skip_cutscene:bool = false) -> void:
	if not ending_song: ending_song = true
	if not _skip_cutscene: start_cutscene()
	stop_music()

func _process(delta:float) -> void:
	if starting_song:
		Conductor.position += (delta * 1000.0) / Engine.time_scale
	else:
		if (absf((inst.get_playback_position() * 1000.0) -  Conductor.position) > 8.0):
			Conductor.position = inst.get_playback_position() * 1000.0
	
	Timings.health = clampf(Timings.health, 0.0, 2.0)
	
	### CAMERA ZOOMING ###
	var cam_lerp:float = lerpf(camera.zoom.x, stage.camera_zoom, 0.01)
	var hud_lerp:float = lerpf(ui.scale.x, stage.hud_zoom, 0.03)
	
	camera.zoom = Vector2(cam_lerp, cam_lerp)
	ui.scale = Vector2(hud_lerp, hud_lerp)
	hud_bump_reposition()
	
	for i in [icon_P1, icon_P2]:
		var i_lerp:float = lerpf(i.scale.x, 0.8, 0.15)
		i.scale.x = i_lerp
		i.scale.y = i_lerp
	
	if SONG != null and inst.stream != null:
		note_processing()
		event_processing()

func note_processing() -> void:
	if notes_list.size() > 0:
		if notes_list[0].time - Conductor.position > (3500.0 * (SONG.speed / Conductor.playback_rate)):
			return
		
		var note_data:Chart.NoteData = notes_list[0]
		
		var new_note:Note = NOTE_STYLES["default"].instantiate()
		new_note.time = note_data.time
		new_note.speed = SONG.speed
		
		new_note.direction = int(note_data.direction % SONG.key_amount)
		new_note.lane = note_data.lane
		new_note.length = note_data.length
		
		if strum_lines.get_child(new_note.lane) != null:
			new_note.parent = strum_lines.get_child(new_note.lane)
			strum_lines.get_child(new_note.lane).notes.add_child(new_note)
		
		notes_list.erase(note_data)

func event_processing() -> void:
	if events_list.size() > 0:
		var cur_event:Chart.EventData = events_list[0]
		if cur_event.time > Conductor.position + cur_event.delay:
			return
		
		fire_event(cur_event.name, cur_event.args)
		events_list.erase(cur_event)

func fire_event(name:String, args:Array[Variant]) -> void:
	match name:
		"Simple Camera Movement":
			var char:Character = player
			var stage_offset:Vector2 = Vector2.ZERO
			match args[0]:
				"player":
					char = player
					if stage != null:
						stage_offset = stage.player_camera
				#"spectator":
				#	char = spectator
				#	if stage != null:
				#		stage_offset = stage.spectator_camera
				_:
					char = opponent
					if stage != null:
						stage_offset = stage.opponent_camera
			
			var offset:Vector2 = Vector2(char.camera_offset.x + stage_offset.x, char.camera_offset.y + stage_offset.y)
			camera.position = Vector2(char.position.x + offset.x, char.position.y + offset.y)
		_:
			if ResourceLoader.exists("res://gameFolder/gameplay/events/" + name + ".tscn"):
				var event_scene = load("res://gameFolder/gameplay/events/" + name + ".tscn")
				add_child(event_scene.instantiate())
				event_scene.game = self

var score_divider:String = " / "
func update_score() -> void:
	var score_temp:String = ""
	var format:String = "%.2f"
	var true_accuracy:float = Timings.accuracy * 100 / 100
	if true_accuracy >= 100 or true_accuracy <= 0:
		format = "%.0f"
	
	score_temp += "SCORE: " + str(Timings.score)
	score_temp += score_divider + "ACCURACY: " + format % true_accuracy + "%"
	score_temp += score_divider + "MISSES: " + str(Timings.misses)
	
	score_temp += score_divider + Timings.cur_grade.name
	
	if Timings.cur_clear != "":
		score_temp += " (" + Timings.cur_clear + ")"
	
	score_text.text = score_temp + "\n"

func update_healthbar() -> void:
	var health_bar_width:float = health_bar.texture_progress.get_size().x
	health_bar.value = clampi(Timings.health * 45.0, 0, 100)
	
	icon_P1.position.x = health_bar.position.x + ((health_bar_width * (1 - health_bar.value / 100)) - icon_P1.texture.get_width())
	icon_P2.position.x = health_bar.position.x + ((health_bar_width * (1 - health_bar.value / 100)) - icon_P2.texture.get_width()) - 65

	icon_P1.frame = 1 if health_bar.value < 20 else 0
	icon_P2.frame = 1 if health_bar.value > 80 else 0

var cam_zoom:Dictionary = {
	"zoom_interval": 4,
	"hud_interval": 4,
	"bump_strength": 0.050,
	"hud_bump_strength": 0.035
}

func on_step() -> void: pass

func on_beat() -> void:
	for strum in strum_lines.get_children():
		for char in strum.dancers:
			if not char.is_singing() and not char.is_missing():
				if beat % char.dance_interval == 0:
					char.dance()
	
	for i in [icon_P1, icon_P2]:
		i.scale = Vector2(i.scale.x + 0.25, i.scale.y + 0.25)
	
	# camera beat stuffs
	if beat % cam_zoom["zoom_interval"] == 0:
		camera.zoom += Vector2(cam_zoom["bump_strength"], cam_zoom["bump_strength"])
	
	if beat % cam_zoom["hud_interval"] == 0:
		ui.scale += Vector2(cam_zoom["hud_bump_strength"], cam_zoom["hud_bump_strength"])
		hud_bump_reposition()

func on_sect() -> void: pass
func on_tick() -> void:
	update_healthbar()

# @swordcube
func hud_bump_reposition():
	ui.offset.x = (ui.scale.x - 1.0) * -(Game.SCREEN["width"] * 0.5)
	ui.offset.y = (ui.scale.y - 1.0) * -(Game.SCREEN["height"] * 0.5)

func _input(event:InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_ESCAPE: Game.switch_scene("menus/Freeplay")
				KEY_8:
					get_tree().paused = true
					var options = load("res://gameFolder/menus/Options.tscn")
					add_child(options.instantiate())
				KEY_Q:
					Conductor.playback_rate -= 0.01
				KEY_E:
					Conductor.playback_rate += 0.01
		
		# Looking for inputs? i moved the to the StrumLine Script!

func note_hit(note:Note, strum:StrumLine) -> void:
	if note.was_good_hit: return
	note.was_good_hit = true
	
	var hit_event = note.on_hit()
	if hit_event == Note.E_STOP:
		return
	
	voices.volume_db = linear_to_db(1.0)
	
	var judge:Judgement = Timings.judge_values(note.time, Conductor.position)
	Timings.score += Timings.score_from_judge(judge.name)
	Timings.health += 0.023
	
	for char in strum.singers:
		var index:int = note.direction % char.sing_anims.size()
		char.play_anim(char.sing_anims[index], true)
		char.hold_timer = 0.0
	
	if Timings.combo < 0: Timings.combo = 0
	Timings.combo += 1
	
	var needs_sick:bool = Settings.get_setting("note_splashes") == "sick only"
	if needs_sick and judge.name == "sick" or not needs_sick:
		strum.pop_splash(note)
	
	if combo_group.get_child_count() > 0:
		for sprite in combo_group.get_children():
			sprite.queue_free()
	
	display_judgement(judge.name)
	display_combo()
	
	Timings.update_accuracy(judge)
	
	update_score()
	if not note.is_hold:
		note.queue_free()

func cpu_note_hit(note:Note, strum:StrumLine) -> void:
	note.was_good_hit = true
	voices.volume_db = linear_to_db(1.0)
	
	for char in strum.singers:
		var index:int = note.direction % char.sing_anims.size()
		char.play_anim(char.sing_anims[index], true)
		char.hold_timer = 0.0
	
	if not note.is_hold:
		note.queue_free()

# I ran out of function names -BeastlyGabi
func note_miss(note:Note, include_anim:bool = true) -> void:
	if note._did_miss: return
	var miss_event = note.on_miss()
	if miss_event == Note.E_STOP:
		return
	
	do_miss_damage()
	voices.volume_db = linear_to_db(0.0)

func ghost_miss(direction:int, include_anim:bool = true) -> void:
	do_miss_damage()
	voices.volume_db = linear_to_db(0.0)

func do_miss_damage():
	Timings.health -= 0.47
	Timings.misses += 1
	
	if Timings.combo > 0: Timings.combo = 0
	else: Timings.combo -= 1
	
	Timings.update_rank()
	update_score()

var judgement_tween:Tween

func display_judgement(_name:String) -> void:
	var new_judgement:Sprite2D = STYLE.get_template("Judgement_Sprite").duplicate()
	new_judgement.texture = load(STYLE.get_asset("images/UI/ratings", _name + ".png"))
	new_judgement.visible = true
	combo_group.add_child(new_judgement)
	
	if judgement_tween != null:
		judgement_tween.stop()
	
	if new_judgement.is_inside_tree():
		var scale_og:Vector2 = new_judgement.scale
		new_judgement.scale *= 1.25
		
		judgement_tween = create_tween().set_ease(Tween.EASE_IN_OUT)
		judgement_tween.tween_property(new_judgement, "scale", scale_og, 0.08)
		judgement_tween.tween_property(new_judgement, "modulate:a", 0.0, 1.25 * Conductor.step_crochet / 1000.0) \
		.set_delay(0.15)
	
	last_judge = new_judgement

var last_judge:Sprite2D

func display_combo() -> void:
	var combo:String = str(Timings.combo).pad_zeros(3)
	var numbers:PackedStringArray = combo.split("")
	
	for i in numbers.size():
		var new_combo:Sprite2D = STYLE.get_template("Number_Sprite").duplicate()
		new_combo.texture = load(STYLE.get_asset("images/UI/combo", "num" + numbers[i] + ".png"))
		new_combo.visible = true
		combo_group.add_child(new_combo)
		
		new_combo.position.x = Game.get_screen_center(new_combo.get_rect().size).x - 15
		new_combo.position.x += 50 * i
		
		if new_combo.is_inside_tree():
			get_tree().create_tween().set_ease(Tween.EASE_OUT) \
			.tween_property(new_combo, "scale", Vector2.ZERO, 0.50 * Conductor.step_crochet / 1000.0) \
			.set_delay(0.55)
