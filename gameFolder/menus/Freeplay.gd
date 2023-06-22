extends Node2D

var cur_selection:int = 0
@onready var songs_node:Node = $Songs_Node
@export var songs:Array[Song] = []

func _ready() -> void:
	for i in songs.size():
		var new_song:Alphabet = $Template_Letter.duplicate()
		new_song.visible = true
		new_song.is_menu_item = true
		new_song.text = songs[i].name
		new_song.id = i
		songs_node.add_child(new_song)
	
	update_selection()

func _process(_delta:float) -> void:
	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
		var is_up:bool = Input.is_action_just_pressed("ui_up")
		update_selection(-1 if is_up else 1)
	
	if Input.is_action_just_pressed("ui_accept"):
		var meta_data:Chart.SongMetaData = Chart.SongMetaData.new()
		meta_data.display_name = songs[cur_selection].name
		meta_data.chart_offset = 0.0
		Game.META_DATA = meta_data
		
		Game.bind_song(songs[cur_selection].folder)

var color_tween:Tween
func update_selection(new_selection:int = 0) -> void:
	cur_selection = wrapi(cur_selection + new_selection, 0, songs_node.get_child_count())
	
	if new_selection != 0:
		Sound.play_sound("res://assets/audio/sfx/scrollMenu.ogg")
	
	var i:int = 0
	for item in songs_node.get_children():
		item.id = i - cur_selection
		item.modulate.a = 1.0 if item.id == 0 else 0.6
		i += 1
	
	if color_tween != null:
		color_tween.stop()
	
	# ACCORDING TO ALL KNOWN LAWS OF AVIATION (1)
	
	color_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	color_tween.tween_property($Background, "modulate", songs[cur_selection].color, 0.50)
