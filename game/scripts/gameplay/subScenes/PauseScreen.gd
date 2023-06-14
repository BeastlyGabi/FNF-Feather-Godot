extends Node2D

@onready var game = $"../../"

var cur_selection:int = 0
var current_list:Array[String] = []
var main_options:Array[String] = ["Resume", "Restart Song", "Change Options", "Exit to Menu"]

@onready var background:ColorRect = $Background
@onready var pause_items:Node2D = $Pause_Items
@onready var song_text:Label = $Song_Text
@onready var diff_text:Label = $Diff_Text
@onready var time_text:Label = $Time_Text

func _ready():
	SoundHelper.play_music(Game.PAUSE_MUSIC, -30, true)
	SoundHelper.music.seek(randi_range(0, SoundHelper.music.stream.get_length() / 2.0))
	
	if Game.gameplay_song["difficulties"].size() > 1:
		main_options.insert(2, "Change Difficulty")
	
	var tweener:Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUART)
	
	background.color.a = 0.0
	tweener.tween_property(background, "color:a", 0.6, 0.40)
	song_text.text = Game.gameplay_song["name"]
	time_text.text = Game.format_to_time(game.inst.get_playback_position()) \
	+ " / " + Game.format_to_time(game.inst.stream.get_length()) if not game.inst == null else "00:00 / 00:00"
	diff_text.text = Game.gameplay_song["difficulty"].to_upper()
	
	if Settings.get_setting("show_keybinds"):
		var key_text:Label = song_text.duplicate()
		key_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		key_text.text = ""
		for i in game.player_strums.receptors.get_child_count():
			key_text.text += Settings._controls["note_" + Game.note_dirs[i]][0]
			if not i == game.player_strums.receptors.get_child_count() - 1:
				key_text.text += " / "
		
		key_text.modulate.a = 0.0
		key_text.position.x = (Game.SCREEN["width"] - key_text.size.x) / 2.0
		add_child(key_text)
		
		tweener.tween_property(key_text, "modulate:a", 1.0, 0.40)
	
	for info in [song_text, time_text, diff_text]:
		info.modulate.a = 0.0
		info.size.x = 0
		info.position.x = Game.SCREEN["width"] - (info.size.x + 6)
		tweener.tween_property(info, "modulate:a", 1.0, 0.40)
	
	reload_options_list(main_options)

func _process(delta):
	if SoundHelper.music.volume_db < 0.8:
		SoundHelper.music.volume_db += 2.5 * delta
	
	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
		var is_up:bool = Input.is_action_just_pressed("ui_up")
		update_selection(-1 if is_up else 1)
	
	if Input.is_action_just_pressed("ui_accept"):
		if current_list == Game.gameplay_song["difficulties"]:
			if not current_list[cur_selection] == "BACK":
				Game.gameplay_song["difficulty"] = current_list[cur_selection]
				SoundHelper.stop_music()
				Game.reset_scene()
				queue_free()
			else:
				reload_options_list(main_options)
		else:
			match pause_items.get_child(cur_selection).text.to_lower():
				"resume":
					queue_free()
					SoundHelper.stop_music()
					get_tree().paused = false
				
				"restart song":
					game.stop_music()
					Game.reset_scene()
					SoundHelper.stop_music()
					queue_free()
				
				"change difficulty":
					reload_options_list(Game.gameplay_song["difficulties"])
				
				"change options":
					game.stop_music()
					Game.options_to_gameplay = true
					Game.switch_scene("scenes/menus/OptionsMenu")
					SoundHelper.stop_music()
					queue_free()
				
				"exit to menu":
					game.stop_music()
					match Game.gameplay_mode:
						0: Game.switch_scene("scenes/menus/StoryMenu")
						_: Game.switch_scene("scenes/menus/FreeplayMenu")
						#2: Game.switch_scene("scenes/editors/ChartEditor")
					
					SoundHelper.stop_music()
					queue_free()

func update_selection(new_selection:int = 0):
	cur_selection = wrapi(cur_selection + new_selection, 0, pause_items.get_child_count())
	
	if not new_selection == 0:
		SoundHelper.play_sound("res://assets/audio/sfx/scrollMenu.ogg")
	
	var bs:int = 0
	for item in pause_items.get_children():
		item.id = bs - cur_selection
		item.modulate.a = 1.0 if item.id == 0 else 0.6
		bs += 1

func reload_options_list(new_list:Array[String]):
	for letter in pause_items.get_children():
		pause_items.remove_child(letter)
	
	current_list = new_list
	if current_list == Game.gameplay_song["difficulties"] and not current_list.has("BACK"):
		current_list.insert(current_list.size(), "BACK")
	
	for i in new_list.size():
		var new_item:Alphabet = $Alphabet_Template.duplicate()
		new_item.menu_item = true
		new_item.visible = true
		new_item.position = Vector2(0, (60 * i))
		new_item.text = new_list[i]
		new_item.id = i
		pause_items.add_child(new_item)
	
	cur_selection = 0
	update_selection()
