extends Node2D

@onready var bg:Sprite2D = $Background
@onready var options:Node2D = $Options

var cur_selection:int = 0

func _select() -> void:
	var cur_option:String = options.get_child(cur_selection).name.to_lower()
	match cur_option:
		_: Game.switch_scene("menus/Freeplay")

func _ready():
	$Version_Text.text = "FNF v" + Game.VERSION.get_fnf_ver() + \
	" / Feather v" + Game.VERSION.name + " [" + Game.VERSION.branch_to_string() + "]"
	
	Game.reset_menu_music(false)

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

var can_move:bool = true
func update_selection(new_selection:int) -> void:
	cur_selection = wrapi(cur_selection + new_selection, 0, options.get_child_count())
	if new_selection != 0: Sound.play_sound("res://assets/sounds/sfx/scrollMenu.ogg")

func animate_buttons() -> void:
	for i in options.get_child_count():
		var option:AnimatedSprite2D = options.get_child(i)
		option.play("white" if i == cur_selection else "basic")
