extends Node2D

var cur_section:int = 0
var cur_selection:int = 0

@onready var top_bar:Node2D = $Top_Bar
@onready var credits_node:Node2D = $Credits_Node
@onready var icons_node:Node2D = $Icons_Node

@export var credits_list:Array[CreditsData] = []

var _test:Array[String] = ["the penis"]

func _ready():
	_reload_list(credits_list)
	
	update_selection()
	update_section()

func _process(delta):
	if Input.is_action_pressed("ui_left"):
		top_bar.get_child(1).play("push")
	else:
		top_bar.get_child(1).play("static")
	
	if Input.is_action_pressed("ui_right"):
		top_bar.get_child(3).play("push")
	else:
		top_bar.get_child(3).play("static")
	
	if Input.is_action_just_pressed("ui_cancel"):
		SoundHelper.play_sound("res://assets/audio/sfx/cancelMenu.ogg")
		Game.switch_scene("menus/MainMenu")
	
	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
		var is_up:bool = Input.is_action_just_pressed("ui_up")
		update_selection(-1 if is_up else 1)
	
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
		var is_left_p:bool = Input.is_action_just_pressed("ui_left")
		update_section(-1 if is_left_p else 1)
	
	if Input.is_action_just_pressed("ui_accept"):
		if credits_list[cur_selection].url.length() > 0:
			OS.shell_open(credits_list[cur_selection].url)

var bg_tween:Tween

func update_selection(new_selection:int = 0):
	cur_selection = wrapi(cur_selection + new_selection, 0, credits_node.get_child_count())
	
	if not new_selection == 0:
		SoundHelper.play_sound("res://assets/audio/sfx/scrollMenu.ogg")
	
	var bs:int = 0
	for item in credits_node.get_children():
		item.id = bs - cur_selection
		item.modulate.a = 1.0 if item.id == 0 else 0.6
		bs += 1
	
	if not bg_tween == null:
		bg_tween.stop()
	
	bg_tween = create_tween().set_ease(Tween.EASE_IN)
	bg_tween.tween_property($Background, "modulate", credits_list[cur_selection].color, 0.6)

func update_section(new_section:int = 0):
	cur_section = wrapi(cur_section + new_section, 0, _test.size())
	if not new_section == 0:
		SoundHelper.play_sound("res://assets/audio/sfx/scrollMenu.ogg")
	
	var section_text:Alphabet = top_bar.get_child(2)
	section_text.text = _test[cur_section]
	section_text.screen_center("X")
	
	top_bar.get_child(1).position.x = section_text.position.x - 50
	top_bar.get_child(3).position.x = section_text.position.x + section_text.width

func _reload_list(new_list:Array[CreditsData]):
	for credit in credits_node.get_children(): credit.queue_free()
	for icon in icons_node.get_children(): icon.queue_free()
	
	for i in new_list.size():
		var icon:AttachedSprite2D = AttachedSprite2D.new()
		
		if ResourceLoader.exists("res://assets/images/menus/creditsMenu/" + new_list[i].icon + ".png"):
			icon.texture = load("res://assets/images/menus/creditsMenu/" + new_list[i].icon + ".png")
		else:
			icon.texture = load("res://assets/images/icons/face.png")
			icon.hframes = 2
		
		icon.position.x = new_list[i].icon_offset.x
		icon.tracker_position.y = new_list[i].icon_offset.y
		icon.use_spr_tracker_x = false
		
		var new_letter:Alphabet = $Alphabet_Template.duplicate()
		new_letter.text = new_list[i].user
		new_letter.visible = true
		
		new_letter.menu_item = true
		new_letter.force_X = 220
		new_letter.vertical_spacing = 110
		
		new_letter.id = i
		
		icon.spr_tracker = new_letter
		
		credits_node.add_child(new_letter)
		icons_node.add_child(icon)
