extends MusicBeatNode2D

var cur_selection:int = 0
var cur_difficulty:int = 1
var last_difficulty:String = "???"

@onready var track_list:Label = $Bottom_Bar/Track_List
@onready var namespace_text:Label = $Top_Bar/Namespace
@onready var week_container:Node2D = $Bottom_Bar/Week_Container
@onready var week_characters:Node2D = $Yellow_Background/Week_Characters
@onready var difficulty_selectors:Node2D = $Bottom_Bar/Difficulty_Selectors


func _ready():
	if SoundHelper.music.stream == null or not SoundHelper.music.playing:
		SoundHelper.play_music(Game.MENU_MUSIC)
		Conductor.change_bpm(102)
	
	for i in Game.game_weeks.size():
		var week_sprite:AttachedSprite2D = AttachedSprite2D.new()
		week_sprite.texture = load("res://assets/images/menus/storyMenu/weeks/" + Game.game_weeks[i].week_image + ".png")
		week_sprite.position.y += ((week_sprite.texture.get_height() + 30) * i)
		week_sprite.sprite_id = i
		week_container.add_child(week_sprite)
	
	update_selection()

func _process(delta:float):
	for character in week_characters.get_children():
		character.play("idle")
	
	for week_sprite in week_container.get_children():
		var lerp_thing:float = lerpf(week_sprite.position.y, (week_sprite.sprite_id * 120), (delta / 0.17))
		week_sprite.position.y = lerp_thing
	
	
	if Input.is_action_pressed("ui_left"):
		difficulty_selectors.get_child(0).play("push")
	else:
		difficulty_selectors.get_child(0).play("static")
	
	if Input.is_action_pressed("ui_right"):
		difficulty_selectors.get_child(2).play("push")
	else:
		difficulty_selectors.get_child(2).play("static")
	
	
	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
		var is_up:bool = Input.is_action_just_pressed("ui_up")
		update_selection(-1 if is_up else 1)
	
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
		var is_left_p:bool = Input.is_action_just_pressed("ui_left")
		update_difficulty(-1 if is_left_p else 1)
	
	if Input.is_action_just_pressed("ui_cancel"):
		Game.switch_scene("scenes/menus/MainMenu")


func update_selection(new_selection:int = 0):
	cur_selection = wrapi(cur_selection + new_selection, 0, week_container.get_child_count())
	
	if not new_selection == 0:
		SoundHelper.play_sound("res://assets/sounds/scrollMenu.ogg")
	
	var bs:int = 0
	for item in week_container.get_children():
		item.sprite_id = bs - cur_selection
		item.modulate.a = 1.0 if item.sprite_id == 0 else 0.6
		bs += 1
	
	update_difficulty()
	update_tracks_label()
	update_menu_characters()


var diff_tween_alpha:Tween
var arrow_twweners:Array[Tween] = [null, null]

func update_difficulty(new_difficulty:int = 0):
	var difficulties:Array[String] = ["easy", "normal", "hard"]
	
	cur_difficulty = wrapi(cur_difficulty + new_difficulty, 0, difficulties.size())
	
	if not new_difficulty == 0:
		SoundHelper.play_sound("res://assets/sounds/scrollMenu.ogg")
	
	
	var diff_sprite:Sprite2D = difficulty_selectors.get_child(1)
	
	for i in arrow_twweners.size():
		if not arrow_twweners[i] == null:
			arrow_twweners[i].stop()
		
		arrow_twweners[i] = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	
	
	if not last_difficulty == difficulties[cur_difficulty]:
		difficulty_selectors.get_child(1).modulate.a = 0.0
		difficulty_selectors.get_child(1).texture = load("res://assets/images/menus/storyMenu/difficulties/" + \
			difficulties[cur_difficulty].to_lower() + ".png")
		
		if not diff_tween_alpha == null:
			diff_tween_alpha.stop()
		
		
		diff_tween_alpha = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		diff_tween_alpha.tween_property(diff_sprite, "modulate:a", 1.0, 0.55)
		
		for i in [0, 2]:
			for j in [0, 1]:
				arrow_twweners[j].tween_property(difficulty_selectors.get_child(i), "position:x", \
				diff_sprite.position.x + diff_sprite.texture.get_width() / 1.58 if i == 2 else \
				diff_sprite.position.x - diff_sprite.texture.get_width() / 1.58, 0.15)
	
	last_difficulty = difficulties[cur_difficulty]

func update_tracks_label():
	track_list.text = ""
	namespace_text.text = Game.game_weeks[cur_selection].week_namespace
	
	var string_thing:Array[FreeplaySong] = Game.game_weeks[cur_selection].songs
	for song in string_thing: track_list.text += '\n' + song.name
	
	track_list.text += '\n'


func update_menu_characters():
	for i in Game.game_weeks[cur_selection].characters.size():
		var cur_char = Game.game_weeks[cur_selection].characters[i]
		
		var folder_chars:String = "res://assets/images/menus/storyMenu/characters/" + cur_char + ".res"
		week_characters.get_child(i).visible = ResourceLoader.exists(folder_chars)
		
		if ResourceLoader.exists(folder_chars):
			week_characters.get_child(i).sprite_frames = load(folder_chars)
			week_characters.get_child(i).play("idle")
