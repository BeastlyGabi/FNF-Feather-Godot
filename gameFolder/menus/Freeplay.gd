extends Node2D

var cur_selection:int = 0

@onready var songs_node:Node = $Songs_Node
@onready var icons_node:Node = $Icons_Node
@export var songs:Array[Song] = []

func _ready() -> void:
	Game.reset_menu_music(false)
	for week in Game.weeks:
		songs.append_array(week.songs)
	
	for i in songs.size():
		var new_song:Alphabet = $Templates/Template_Letter.duplicate()
		new_song.visible = true
		new_song.is_menu_item = true
		new_song.text = songs[i].name
		new_song.id = i
		songs_node.add_child(new_song)
		
		var new_icon:FollowerSprite2D = $Templates/Template_Icon.duplicate()
		new_icon.texture = load("res://assets/images/icons/%s.png" % songs[i].icon)
		new_icon.hframes = 2
		new_icon.parent = new_song
		new_icon.visible = true
		icons_node.add_child(new_icon)
	
	update_selection()

var can_move:bool = true
func _process(_delta:float) -> void:
	if can_move:
		if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
			var is_up:bool = Input.is_action_just_pressed("ui_up")
			update_selection(-1 if is_up else 1)
		
		if Input.is_action_just_pressed("ui_cancel"):
			Game.switch_scene("menus/Main")
		
		if Input.is_action_just_pressed("ui_accept"):
			can_move = false
			var meta_data:Chart.SongMetaData = Chart.SongMetaData.new()
			meta_data.display_name = songs[cur_selection].name
			meta_data.chart_offset = 0.0
			Game.META_DATA = meta_data
			
			Sound.music.stop()
			Sound.play_sound("res://assets/sounds/sfx/confirmMenu.ogg")
			for letter in songs_node.get_children():
				Game.flicker_object(icons_node.get_child(cur_selection))
				
				if letter.id != 0:
					get_tree().create_tween().tween_property(letter, "position:x", 5000, 0.85)
				else:
					Game.flicker_object(letter, 0.06, 8, func():
						Game.bind_song(songs[cur_selection].folder)
					)

func _input(event:InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_7:
					var mods_menu:PackedScene = load("res://gameFolder/menus/Mods.tscn")
					get_tree().paused = true
					add_child(mods_menu.instantiate())

var color_tween:Tween
func update_selection(new_selection:int = 0) -> void:
	cur_selection = wrapi(cur_selection + new_selection, 0, songs_node.get_child_count())
	
	if new_selection != 0:
		Sound.play_sound("res://assets/sounds/sfx/scrollMenu.ogg")
	
	var i:int = 0
	for item in songs_node.get_children():
		item.id = i - cur_selection
		item.modulate.a = 1.0 if item.id == 0 else 0.6
		i += 1
	
	for icon in icons_node.get_children():
		var selected_icon := icons_node.get_child(cur_selection) 
		icon.modulate.a = 1.0 if selected_icon == icon else 0.6
	
	if color_tween != null:
		color_tween.stop()
	
	# ACCORDING TO ALL KNOWN LAWS OF AVIATION (1)
	
	color_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	color_tween.tween_property($Background, "modulate", songs[cur_selection].color, 0.50)
