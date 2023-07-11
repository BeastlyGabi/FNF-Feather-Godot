extends Node2D

@onready var bg:Sprite2D = $Background
@onready var options:Node2D = $Options

var cur_selection:int = 0

func _select() -> void:
	var cur_option:String = options.get_child(cur_selection).name.to_lower()
	match cur_option:
		_: Game.switch_scene("menus/FreeplayMenu")

func _ready():
	Game.discord.update_status("Main Menu", "In the Menus")
	$Version_Text.text = "FNF v%s" % Game.VERSION.fnf_version + \
	" / Feather v%s" % Game.VERSION.ff_version
	
	Overlay.tween_in_out(false)
	Game.reset_menu_music(false)
	
	for i in options.get_child_count():
		var option:AnimatedSprite2D = options.get_child(i)
		option.position.x = 2000 if i % 2 == 0 else -2000
		
		var cur_tween:Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		cur_tween.tween_property(option, "position:x", 625, 0.35).set_delay(0.15 * i)
		if i >= options.get_child_count() - 1:
			cur_tween.finished.connect(func(): can_move = true)

func _process(_delta):
	animate_buttons()
	
	if can_move:
		if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
			var is_up:bool = Input.is_action_just_pressed("ui_up")
			update_selection(-1 if is_up else 1)
		
		if Input.is_action_just_pressed("ui_accept"):
			can_move = false
			Sound.play_sound("res://assets/sounds/sfx/confirmMenu.ogg")
			for i in options.get_child_count():
				var option = options.get_child(i)
				if i == cur_selection:
					Game.flicker_object(option, 0.06, 8, _select)
				else:
					get_tree().create_tween().tween_property(option, "modulate:a", 0.0, 0.85)

var can_move:bool = false
func update_selection(new_selection:int) -> void:
	cur_selection = wrapi(cur_selection + new_selection, 0, options.get_child_count())
	if new_selection != 0: Sound.play_sound("res://assets/sounds/sfx/scrollMenu.ogg")

func animate_buttons() -> void:
	for i in options.get_child_count():
		var option:AnimatedSprite2D = options.get_child(i)
		option.play("white" if i == cur_selection else "basic")
