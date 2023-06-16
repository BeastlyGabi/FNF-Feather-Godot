extends Node2D

var cur_selection:int = 0
@onready var mods_node:Node2D = $Mods_Node

func _ready():
	var mods = ModLoader.scan_mods()
	
	if mods.size() > 0:
		for i in mods.size():
			var new_letter:Alphabet = $Alphabet_Template.duplicate()
			new_letter.id = i
			new_letter.text = mods[i]
			new_letter.menu_item = true
			new_letter.visible = true
			mods_node.add_child(new_letter)
	
	else:
		var you_suck:Alphabet = $Alphabet_Template.duplicate()
		you_suck.visible = true
		you_suck.position = Vector2(250, 300)
		you_suck.text = "NO MODS INSTALLED"
		add_child(you_suck)
	
	update_selection()

var is_input_locked:bool = false

func _process(delta):
	if not is_input_locked:
		if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
			var is_up = Input.is_action_just_pressed("ui_up")
			update_selection(-1 if is_up else 1)
		
		if Input.is_action_just_pressed("ui_cancel"):
			is_input_locked = true
			SoundHelper.play_sound("res://assets/audio/sfx/cancelMenu.ogg")
			get_tree().paused = false
			queue_free()
		
		if Input.is_action_just_pressed("ui_accept"):
			ModLoader.load_mod(mods_node.get_child(cur_selection).text)
			get_tree().paused = false
			Game.reset_scene()
			queue_free()

func update_selection(new_selection:int = 0):
	cur_selection = wrapi(cur_selection + new_selection, 0, mods_node.get_child_count())
	
	if not new_selection == 0:
		SoundHelper.play_sound("res://assets/audio/sfx/scrollMenu.ogg")
	
	var bs:int = 0
	for item in mods_node.get_children():
		item.id = bs - cur_selection
		item.modulate.a = 1.0 if item.id == 0 else 0.6
		bs += 1
