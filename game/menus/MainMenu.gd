extends Node2D

var cur_selection:int = 0

@onready var buttons:Node = $Buttons

func _change_scene():
	match buttons.get_child(cur_selection).name:
		"story_mode": Game.switch_scene("menus/StoryMenu")
		"freeplay": Game.switch_scene("menus/FreeplayMenu")
		"credits": Game.switch_scene("menus/CreditsMenu")
		"options": Game.switch_scene("menus/OptionsMenu")
		_:
			print_debug("invalid state, selected ", buttons.get_child(cur_selection).name)
			Game.switch_scene("menus/MainMenu")

func _ready():
	if SoundHelper.music.stream == null or not SoundHelper.music.playing:
		SoundHelper.play_music(Game.MENU_MUSIC)
		Conductor.change_bpm(102)
	
	update_selection()

var is_input_locked:bool = false

func _process(_delta:float):
	for i in buttons.get_child_count():
		var button:AnimatedSprite2D = buttons.get_child(i)
		button.play("white" if i == cur_selection else "basic")
	
	if not is_input_locked:
		if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
			var is_up:bool = Input.is_action_just_pressed("ui_up")
			update_selection(-1 if is_up else 1)
		
		if Input.is_action_just_pressed("ui_accept"):
			is_input_locked = true
			
			SoundHelper.play_sound("res://assets/audio/sfx/confirmMenu.ogg")
			
			for i in buttons.get_child_count():
				var button:AnimatedSprite2D = buttons.get_child(i)
				if not i == cur_selection:
					create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE) \
					.tween_property(button, "modulate:a", 0.0, 0.40)
			
			if Settings.get_setting("flashing_lights"):
				Game.do_object_flick($Magenta, 0.10, false)
				await Game.do_object_flick(buttons.get_child(cur_selection), 0.08, false, func():
					await get_tree().create_timer(0.25).timeout
					Game.flicker_loops = 8 # TODO: find a better way to handle flickering objects
					_change_scene()
				)
			else:
				await get_tree().create_timer(1.0).timeout
				_change_scene()

func update_selection(new_selection:int = 0) -> void:
	cur_selection = wrapi(cur_selection + new_selection, 0, buttons.get_child_count())
	if not new_selection == 0:
		SoundHelper.play_sound("res://assets/audio/sfx/scrollMenu.ogg")
