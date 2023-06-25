extends CanvasLayer

var cur_selection:int = 0

@onready var background:ColorRect = $Background
@onready var options:Node2D = $Options

func _ready() -> void:
	background.modulate.a = 0.0
	var tween:Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_property(background, "modulate:a", 0.60, 0.15)
	update_selection()

func _process(_delta:float) -> void:
	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
		var is_up:bool = Input.is_action_just_pressed("ui_up")
		update_selection(-1 if is_up else 1)
	
	if Input.is_action_just_pressed("ui_accept"):
		match options.get_child(cur_selection).text.to_lower():
			"xml converter": Game.switch_scene("backend/tools/XML Converter")
			"txt converter": Game.switch_scene("backend/tools/TXT Converter")
	
	if Input.is_action_just_pressed("ui_cancel"):
		queue_free()
		get_tree().paused = false

func update_selection(new_selection:int = 0) -> void:
	cur_selection = wrapi(cur_selection + new_selection, 0, options.get_child_count())
	
	if new_selection != 0:
		Sound.play_sound("res://assets/audio/sfx/scrollMenu.ogg")
	
	var i:int = 0
	for item in options.get_children():
		item.id = i - cur_selection
		item.modulate.a = 1.0 if item.id == 0 else 0.6
		i += 1
