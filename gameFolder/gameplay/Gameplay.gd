extends MusicBeatNode2D

var NOTE_STYLES:Dictionary = {
	"default": preload("res://gameFolder/gameplay/notes/default.tscn")
}

const SUBSCENES:Dictionary = {
	"pause" = preload("res://gameFolder/subScenes/PauseMenu.tscn")
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
@onready var combo_counter:Label = $UI/Judge_Counter
@onready var combo_group:Node2D = $UI/Combo_Group

@onready var icon_P1 := $UI/Health_Bar/Player_icon
@onready var icon_P2 := $UI/Health_Bar/Opponent_icon

@onready var strum_lines:CanvasLayer = $Strum_Lines
@onready var player_strums:StrumLine = $Strum_Lines/Player

var player:Character
var opponent:Character
var spectator:Character

var stage:Stage

var notes_list:Array[Chart.NoteData] = []
var events_list:Array[Chart.EventData] = []

###################################################
### LOADING FUNCTIONS YOU MAY WANNA IGNORE THESE ###

func setup_stage() -> void:
	var base:String = "res://gameFolder/gameplay/stages/"
	if not ResourceLoader.exists(base + SONG.stage + ".tscn"):
		SONG.stage = "stage"
	
	stage = load(base + SONG.stage + ".tscn").instantiate()
	add_child(stage)

func _load_char(_new_char:String, player:bool = false) -> Character:
	var base_path:String = "res://gameFolder/gameplay/characters/"
	if not ResourceLoader.exists(base_path + _new_char + ".tscn"):
		_new_char = "bf"
	
	var _char:Character = load(base_path + _new_char + ".tscn").instantiate()
	_char.name = _new_char
	_char.is_player = player
	return _char

func setup_characters() -> void:
	player = _load_char(SONG.characters[0], true)
	opponent = _load_char(SONG.characters[1])
	
	if not stage.hide_spectator:
		spectator = _load_char(SONG.characters[2])
		stage.add_child(spectator)
	
	stage.add_child(opponent)
	stage.add_child(player)
	
	player.position = stage.player_position
	opponent.position = stage.opponent_position
	
	icon_P1.texture = load("res://assets/images/icons/" + player.health_icon + ".png")
	icon_P2.texture = load("res://assets/images/icons/" + opponent.health_icon + ".png")
	
	# kinda eh sysm probably gonna redo later
	var opponent_strums:StrumLine = $Strum_Lines/Opponent
	for shit in [opponent_strums.singers]: shit.append(opponent)
	for piss in [player_strums.singers]: piss.append(player)

###################################################

func _init() -> void:
	super._init()
	SONG = Game.CUR_SONG if Game.CUR_SONG != null else Chart.load_chart("test", "normal")
	
	var style_folder:String = "res://gameFolder/ui/styles/" + SONG.ui_style + ".tscn"
	if not ResourceLoader.exists(style_folder): style_folder = style_folder.replace(SONG.ui_style, "normal")
	STYLE = load(style_folder).instantiate()
	add_child(STYLE)
	
	notes_list = SONG.notes.duplicate()
	events_list = SONG.events.duplicate()

func _ready() -> void:
	Timings.reset()
	Overlay.tween_in_out(true)
	
	setup_stage()
	setup_characters()
	fire_event("Simple Camera Movement", ["opponent"])
	
	match Settings.get_setting("combo_camera"):
		Settings.ComboCamera.WORLD:
			combo_group.reparent(self)
	
	Game.discord.update_status("Gameplay", "Playing %s" % Game.META_DATA.display_name)
	
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
	update_healthbar()
	start_cutscene()

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
	Conductor.position = -(Conductor.rate_crochet * 5)
	await get_tree().create_timer(0.35).timeout
	process_countdown(true)

func process_countdown(reset:bool = false) -> void:
	if reset:
		count_position = 0
		count_timer = Timer.new()
		add_child(count_timer)
	
	var countdown_spr:Sprite2D = STYLE.get_template("Countdown_Sprite").duplicate()
	countdown_spr.texture = load(STYLE.get_asset("images/UI/countdown", \
	STYLE.countdown_config["sprites"][count_position] + ".png"))
	
	countdown_spr.visible = true
	countdown_spr.modulate.a = 0.0
	if STYLE.name != "pixel":
		countdown_spr.scale.y *= 1.25
	ui.add_child(countdown_spr)
	
	if count_tweener != null: count_tweener.stop()
	count_tweener = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	# THERE'S NO WAY A BEE SHOULD BE ABLE TO FLY (2)
	if STYLE.name != "pixel":
		get_tree().create_tween().tween_property(countdown_spr, "scale:y", 1.0, 0.10)
	count_tweener.tween_property(countdown_spr, "modulate:a", 1.0, 0.05)
	count_tweener.tween_property(countdown_spr, "modulate:a", 0.0, Conductor.rate_crochet / 1100.0)
	
	Sound.play_sound(STYLE.get_asset("sounds/sfx/game", \
	STYLE.countdown_config["sounds"][count_position] + ".ogg"))
	
	count_position += 1
	
	count_timer.start(Conductor.rate_crochet / 1000.0)
	await count_timer.timeout
	if count_position < 4:
		dance_characters(count_position)
		process_countdown()
		return
	else:
		can_pause = true
		# ITS WINGS ARE TOO SMALL TO GET ITS FAT BODY OFF THE GROUND. (3)
		if countdown_spr != null: countdown_spr.queue_free()
		count_timer.queue_free()
	
	if starting_song:
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
	stop_music()
	ending_song = true
	can_pause = false
	
	if not _skip_cutscene:
		start_cutscene()
	else:
		Game.switch_scene("menus/FreeplayMenu")

var can_pause:bool = false

func _process(delta:float) -> void:
	if starting_song:
		Conductor.position += delta * 1000.0 * Engine.time_scale
	else:
		if (absf((inst.get_playback_position() * 1000.0) -  Conductor.position) > 8.0):
			Conductor.position = inst.get_playback_position() * 1000.0
	
	Timings.health = clampf(Timings.health, 0.0, 2.0)
	
	if not get_tree().paused:
		if can_pause and Input.is_action_just_pressed("ui_pause"):
			pause_game()
	
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

func pause_game() -> void:
	get_tree().paused = true
	add_child(SUBSCENES["pause"].instantiate())

func note_processing() -> void:
	if notes_list.size() > 0:
		if notes_list[0].time - Conductor.position > (3500.0 * (SONG.speed / Conductor.playback_rate)):
			return
		
		var note_data:Chart.NoteData = notes_list[0]
		
		var new_note:Note = NOTE_STYLES["default"].instantiate()
		new_note.time = note_data.time
		new_note.speed = SONG.speed
		
		new_note.direction = int(note_data.direction % 4)
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
		"BPM Change":
			var prev_bpm:float = Conductor.bpm
			Conductor.bpm = args[0]
			print_debug("BPM Changed! previous was %s, now changed to %s" % [prev_bpm, Conductor.bpm])
		"Simple Camera Movement":
			var char:Character = player
			var stage_offset:Vector2 = Vector2.ZERO
			match args[0]:
				"player":
					char = player
					if stage != null:
						stage_offset = stage.player_camera
				"spectator":
					char = spectator
					if stage != null:
						stage_offset = stage.spectator_camera
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
	var format:String = "%.2f"
	var true_accuracy:float = Timings.accuracy * 100 / 100
	if true_accuracy >= 100 or true_accuracy <= 0:
		format = "%.0f"
	
	var score_temp:String
	
	score_temp = "- SCORE: %s" % str(Timings.score)
	score_temp += score_divider + "MISSES: %s" % str(Timings.misses)
	score_temp += score_divider + "RANK: %s" % [Timings.cur_grade.name]
	
	if Timings.notes_hit > 0:
		score_temp += " [%s" % [format % true_accuracy] + "%"
		if Timings.cur_clear != "":
			score_temp += score_divider + "%s" % Timings.cur_clear
		score_temp += "]"
	score_temp += ' -'
	
	score_text.text = score_temp + "\n"
	update_judgement_counter()

func update_judgement_counter() -> void:
	if combo_counter == null or not combo_counter.visible:
		return
	
	var text:String = ""
	for i in Timings.judgements_hit:
		text += "\n%s: %s" % [i.to_pascal_case() + "s", Timings.get_hits(i)]
	combo_counter.text = text

func update_healthbar() -> void:
	var health_bar_width:float = health_bar.texture_progress.get_size().x
	health_bar.value = clampi(Timings.health * 50.0, 0, 100)
	
	icon_P1.position.x = health_bar.position.x + ((health_bar_width * (1 - health_bar.value / 100)) - icon_P1.texture.get_width()) - 50
	icon_P2.position.x = health_bar.position.x + ((health_bar_width * (1 - health_bar.value / 100)) - icon_P2.texture.get_width()) - 125

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
	dance_characters(beat)
	for i in [icon_P1, icon_P2]:
		var factor:float = 0.15 if beat % 2 == 0 else 0.25
		i.scale = Vector2(i.scale.x + factor, i.scale.y + factor)
	
	# camera beat stuffs
	if beat % cam_zoom["zoom_interval"] == 0:
		camera.zoom += Vector2(cam_zoom["bump_strength"], cam_zoom["bump_strength"])
	
	if beat % cam_zoom["hud_interval"] == 0:
		ui.scale += Vector2(cam_zoom["hud_bump_strength"], cam_zoom["hud_bump_strength"])
		hud_bump_reposition()

func on_sect() -> void: pass
func on_tick() -> void:
	update_healthbar()

func _notification(what):
	match what:
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			if Settings.get_setting("auto_pause"):
				if can_pause and not get_tree().paused:
					pause_game()

func dance_characters(_beat:int) -> void:
	for bopper in stage.get_children():
		if bopper is Character and not bopper.is_singing() and not bopper.is_missing():
			if _beat % bopper.dance_interval == 0:
				bopper.dance()

# @swordcube
func hud_bump_reposition():
	ui.offset.x = (ui.scale.x - 1.0) * -(Game.SCREEN["width"] * 0.5)
	ui.offset.y = (ui.scale.y - 1.0) * -(Game.SCREEN["height"] * 0.5)

func _input(event:InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_Q:
					Conductor.playback_rate -= 0.01
				KEY_E:
					Conductor.playback_rate += 0.01
		
		# Looking for inputs? i moved the to the StrumLine Script!

func note_hit(note:Note, strum:StrumLine) -> void:
	note.on_hit()
	if note.was_good_hit or note.event.get_event("cancelled"): return
	note.was_good_hit = true
	
	voices.volume_db = linear_to_db(1.0)
	
	for char in strum.singers:
		var index:int = note.direction % char.sing_anims.size()
		char.play_anim(char.sing_anims[index], true)
		char.hold_timer = 0.0
	
	if not strum.is_cpu:
		var judge:Judgement = Timings.judge_values(note.time, Conductor.position)
		
		if note.event.get_event("increase_score"):
			Timings.score += Timings.score_from_judge(judge.name)
		if note.event.get_event("increase_combo"):
			Timings.update_combo(true)
		
		Timings.health += 0.023
		if judge.name == "sick" and note.event.get_event("splash"):
			strum.pop_splash(note)
		
		if combo_group.get_child_count() > 0:
			for sprite in combo_group.get_children():
				sprite.queue_free()
		
		if note.event.get_event("display_judgement"): display_judgement(judge.name)
		if note.event.get_event("display_combo"):
			display_combo()
			if Timings.combo % 10 == 0:
				display_combo_sprite()
		
		Timings.update_accuracy(judge)
		update_score()
	
	if not note.is_hold:
		note.queue_free()

# I ran out of function names -BeastlyGabi
func note_miss(note:Note, include_anim:bool = true) -> void:
	if note._did_miss: return
	note.on_miss()
	if note.event.get_event("cancelled"):
		return
	
	do_miss_damage()
	voices.volume_db = linear_to_db(0.0)

func ghost_miss(direction:int, include_anim:bool = true) -> void:
	do_miss_damage()
	voices.volume_db = linear_to_db(0.0)

func do_miss_damage():
	Timings.health -= 0.087
	Timings.misses += 1
	
	Timings.update_combo(false)
	Timings.update_rank()
	update_score()

var judgement_tween:Tween

func display_judgement(_name:String) -> void:
	var new_judgement:Sprite2D = STYLE.get_template("Judgement_Sprite").duplicate()
	new_judgement.texture = STYLE.get_judgement_texture(_name)
	new_judgement.visible = true
	combo_group.add_child(new_judgement)
	
	new_judgement.position.x = Game.get_screen_center(new_judgement.get_rect().position).x
	new_judgement.position.x -= new_judgement.texture.get_width() / 5.0
	
	if judgement_tween != null:
		judgement_tween.stop()
	
	if not new_judgement.is_inside_tree(): return
	judgement_tween = create_tween().set_ease(Tween.EASE_IN_OUT)
	
	match Settings.get_setting("combo_style"):
		Settings.ComboStyle.FEATHER:
			var scale_og:Vector2 = new_judgement.scale; new_judgement.scale *= 1.25
			judgement_tween.tween_property(new_judgement, "scale", scale_og, Conductor.rate_step_crochet / 1000.0)
		
		Settings.ComboStyle.VANILLA:
			#new_judgement.acceleration.y = 550
			#new_judgement.velocity.y = -randi_range(140, 175)
			#new_judgement.velocity.x = -randi_range(0, 10)
			pass
	
	judgement_tween.tween_property(new_judgement, "modulate:a", 0.0, \
	1.25 * Conductor.rate_crochet / 1000.0).set_delay(0.15)

func display_combo() -> void:
	var combo:String = str(Timings.combo).pad_zeros(3)
	var numbers:PackedStringArray = combo.split("")
	
	for i in numbers.size():
		var new_combo:Sprite2D = STYLE.get_template("Number_Sprite").duplicate()
		new_combo.texture = load(STYLE.get_asset("images/UI/combo", "num" + numbers[i] + ".png"))
		new_combo.visible = true
		combo_group.add_child(new_combo)
		
		new_combo.position.x = Game.get_screen_center(new_combo.get_rect().position).x - 60
		new_combo.position.x += 35 * i
		
		if not new_combo.is_inside_tree(): return
		
		match Settings.get_setting("combo_style"):
			Settings.ComboStyle.FEATHER:
				get_tree().create_tween().set_ease(Tween.EASE_OUT) \
				.tween_property(new_combo, "scale", Vector2.ZERO, 0.50 * Conductor.rate_crochet / 1000.0) \
				.set_delay(0.55)
			
			Settings.ComboStyle.VANILLA:
				#new_combo.acceleration.y = randi_range(200, 300)
				#new_combo.velocity.y -= randi_range(140, 160)
				#new_combo.velocity.x = randf_range(-5, 5)
				get_tree().create_tween().set_ease(Tween.EASE_OUT) \
				.tween_property(new_combo, "modulate:a", 0.0, 0.50 * Conductor.rate_crochet / 1000.0) \
				.set_delay(0.55)

func display_combo_sprite() -> void:
	var combo_spr:Sprite2D = STYLE.get_template("Combo_Sprite").duplicate()
	combo_spr.visible = true
	combo_group.get_parent().add_child(combo_spr)
	
	combo_spr.position.x = Game.get_screen_center(combo_spr.get_rect().position).x
	combo_spr.position.x -= combo_spr.texture.get_width() / 4.0
	
	if not combo_spr.is_inside_tree(): return
	match Settings.get_setting("combo_style"):
		Settings.ComboStyle.VANILLA:
			#combo_spr.acceleration.y = randi_range(200, 300)
			#combo_spr.velocity.y = -randi_range(140, 160)
			pass
	
	create_tween().set_ease(Tween.EASE_IN_OUT) \
	.tween_property(combo_spr, "modulate:a", 0.0, 1.35 * \
	Conductor.rate_crochet / 1000.0).set_delay(0.15)

func is_combo_on_hud() -> bool: return combo_group.get_parent() == ui
