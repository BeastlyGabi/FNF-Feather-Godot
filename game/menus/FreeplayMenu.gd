extends Node2D

var cur_selection:int = 0
var cur_difficulty:int = 1
var last_selection:int = -1
var last_difficulty:String = "none"

@onready var song_group:Node = $Song_Group
@onready var icon_group:Node = $Icon_Group

@onready var score_box:ColorRect = $UI/Score_Box
@onready var score_text:Label = $UI/Score_Text
@onready var diff_text:Label = $UI/Diff_Text

@export var songs:Array[FreeplaySong] = []

func _ready():
	for i in Game.game_weeks.size():
		songs.append_array(Game.game_weeks[i].songs)
	
	_load_songs()

var is_input_locked:bool = false
var score_lerp:float = 0.0
var score_final:int = 0

func _process(delta):
	if SoundHelper.music.volume_db < 0.5:
		SoundHelper.music.volume_db += 80.0 * delta
	
	score_lerp = lerp(score_lerp, float(score_final), 0.4)
	score_text.text = "PERSONAL BEST:" + str(roundf(score_lerp))
	_position_highscore()
	
	if not is_input_locked:
		if Input.is_action_just_pressed("ui_cancel"):
			if not Input.is_key_pressed(KEY_SHIFT) and not SoundHelper.music_file == Game.MENU_MUSIC:
				SoundHelper.play_music(Game.MENU_MUSIC)
			
			is_input_locked = true
			SoundHelper.play_sound("res://assets/audio/sfx/cancelMenu.ogg")
			Game.switch_scene("menus/MainMenu")
		
		if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
			var is_up:bool = Input.is_action_just_pressed("ui_up")
			update_selection(-1 if is_up else 1)
		
		if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
			var is_left:bool = Input.is_action_just_pressed("ui_left")
			update_difficulty(-1 if is_left else 1)
		
		if Input.is_action_just_pressed("ui_accept"):
			is_input_locked = true
			
			Song.gameplay_mode = Song.FREEPLAY_MODE
			Song.data["name"] = songs[cur_selection].name
			Song.data["folder"] = songs[cur_selection].folder
			Song.data["difficulty"] = songs[cur_selection].difficulties[cur_difficulty]
			Song.difficulty_list = songs[cur_selection].difficulties
			
			Game.switch_scene("gameplay/Gameplay")
			SoundHelper.stop_music()

var bg_tween:Tween

func update_selection(new_selection:int = 0):
	cur_selection = wrapi(cur_selection + new_selection, 0, song_group.get_child_count())
	
	if not new_selection == 0:
		SoundHelper.play_sound("res://assets/audio/sfx/scrollMenu.ogg")
	
	var bs:int = 0
	for item in song_group.get_children():
		item.id = bs - cur_selection
		item.modulate.a = 1.0 if item.id == 0 else 0.6
		bs += 1
	
	for i in icon_group.get_child_count():
		icon_group.get_child(i).modulate.a = 1.0 if i == cur_selection else 0.6
	
	if not bg_tween == null:
		bg_tween.stop()
	
	bg_tween = create_tween().set_ease(Tween.EASE_IN)
	bg_tween.tween_property($Background, "modulate", songs[cur_selection].color, 0.6)
	
	last_selection = cur_selection
	
	update_difficulty()

func update_difficulty(new_difficulty:int = 0):
	var difficulties:Array[String] = songs[cur_selection].difficulties
	
	if difficulties.size() > 1:
		if (last_selection != cur_selection and difficulties.has(last_difficulty)
				and difficulties[cur_difficulty] != last_difficulty):
			cur_difficulty = difficulties.find(last_difficulty)
	
	cur_difficulty = wrapi(cur_difficulty + new_difficulty, 0, difficulties.size())
	
	if not new_difficulty == 0:
		SoundHelper.play_sound("res://assets/audio/sfx/scrollMenu.ogg")
	
	if difficulties.size() > 1:
		diff_text.text = "< " + difficulties[cur_difficulty].to_upper() + " >"
	else:
		diff_text.text = difficulties[cur_difficulty].to_upper()
	
	if difficulties[cur_difficulty] != last_difficulty:
		last_difficulty = difficulties[cur_difficulty]
	
	score_final = Song.get_score(songs[cur_selection].folder + '-' + difficulties[cur_difficulty], "songs")
	
	await(get_tree().create_timer(0.15).timeout)
	play_selected_song()

var prev_played_song:String = "???"

func play_selected_song():
	# change current song
	var def_inst = "res://assets/songs/" + songs[cur_selection].folder + "/audio/Inst.ogg"
	var diff_inst = "res://assets/songs/" + songs[cur_selection].folder + "/audio/Inst" \
	+ "-" + last_difficulty.to_lower() + ".ogg"
	
	prev_played_song = SoundHelper.music_file
	
	if ResourceLoader.exists(diff_inst) and not SoundHelper.music_file == diff_inst:
		SoundHelper.play_music(diff_inst, -50.0, true)
	
	elif ResourceLoader.exists(def_inst) and not SoundHelper.music_file == def_inst:
		SoundHelper.play_music(def_inst, -50.0, true)
	
	if prev_played_song != SoundHelper.music_file:
		SoundHelper.music.seek(randi_range(0, SoundHelper.music.stream.get_length() / 2.0))

func _position_highscore():
	score_text.size.x = 0
	score_text.position.x = Game.SCREEN["width"] - score_text.size.x - 6
	
	score_box.position.x = score_text.position.x - 3
	score_box.size.x = Game.SCREEN["width"] - score_text.size.x / 2.0
	
	for txt in [diff_text]:
		txt.size.x = score_text.size.x / 1.0
		txt.position.x = score_box.position.x

func _load_songs():
	for i in songs.size():
		var cool_text:Alphabet = $Alphabet_Template.duplicate()
		cool_text.text = songs[i].name
		cool_text.menu_item = true
		cool_text.visible = true
		cool_text.id = i
		song_group.add_child(cool_text)
		
		var icon:AttachedSprite2D = AttachedSprite2D.new()
		
		if ResourceLoader.exists("res://assets/images/icons/" + songs[i].icon + ".png"):
			icon.texture = load("res://assets/images/icons/" + songs[i].icon + ".png")
		else:
			icon.texture = load("res://assets/images/icons/face.png")
		
		icon.tracker_position = Vector2(50, 15)
		icon.spr_tracker = cool_text
		icon.hframes = 2
		icon_group.add_child(icon)
	
	cur_selection = 0
	update_selection()
