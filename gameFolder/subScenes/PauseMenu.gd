extends CanvasLayer

var cur_selection:int = 0
var lists:Dictionary = { # "Change Difficulty"
	"default": ["Resume", "Restart Song", "Exit to Menu"]
}
var current_list:Array

@onready var bg:ColorRect = $Background
@onready var list_node:Node2D = $List

var tween:Tween
func _ready() -> void:
	bg.modulate.a = 0.0
	
	tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUART)
	tween.tween_property(bg, "modulate:a", 0.8, 0.4)
	
	list_reload("default")
	update_selection()

func _process(_delta:float) -> void:
	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
		var is_up:bool = Input.is_action_just_pressed("ui_up")
		update_selection(-1 if is_up else 1)

	if Input.is_action_just_pressed("ui_accept"):
		match current_list[cur_selection].to_lower():
			"resume":
				close_menu()
			"restart song":
				close_menu(func(): Game.reset_scene())
			"exit to menu":
				close_menu(func(): Game.switch_scene("menus/FreeplayMenu"))

func close_menu(_func_to_call = null) -> void:
	get_tree().paused = false
	if _func_to_call != null and _func_to_call is Callable:
		_func_to_call.call()
	queue_free()

func update_selection(new_selection:int = 0) -> void:
	cur_selection = wrapi(cur_selection + new_selection, 0, current_list.size())
	
	if new_selection != 0:
		Sound.play_sound("res://assets/sounds/sfx/scrollMenu.ogg")
	
	var i:int = 0
	for item in list_node.get_children():
		item.id = i - cur_selection
		item.modulate.a = 1.0 if item.id == 0 else 0.6
		i += 1

func list_reload(new_list:String) -> void:
	current_list = lists[new_list]
	while list_node.get_child_count() > 0:
		var letter := list_node.get_child(0)
		letter.queue_free(); list_node.remove_child(letter)
	
	for i in current_list.size():
		var new_letter:Alphabet = $Template_Letter.duplicate()
		new_letter.is_menu_item = true
		new_letter.visible = true
		new_letter.text = current_list[i]
		new_letter.id = i
		list_node.add_child(new_letter)
