extends Node2D

var cur_selection:int = 0
var cur_key:int = 0

@onready var keys:Node2D = $Keys
@onready var binds:Node2D = $Binds
@onready var alts:Node2D = $Alts

@onready var section_text:Label = $Section_Name

var page:String = "note"

var key_shit:Dictionary = {
	"note": ["left", "down", "up", "right"],
	"ui": ["left", "down", "up", "right", "accept", "cancel", "pause", "volume_up", "volume_down"],
}

func _ready():
	$Background.color.a = 0.0
	var tweener:Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tweener.tween_property($Background, "color:a", 0.8, 0.50)
	
	generate_options()


var is_binding:bool = false

func _process(delta):
	
	if not is_binding:
	
		if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
			var is_up:bool = Input.is_action_just_pressed("ui_up")
			update_selection(-1 if is_up else 1)
		
		if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
			var is_left:bool = Input.is_action_just_pressed("ui_left")
			update_key(-1 if is_left else 1)
	
	if Input.is_action_just_pressed("ui_accept"):
		var bind_node:Node2D = alts if cur_key == 1 else binds
		bind_node.get_child(cur_selection).text = "[ --- ]"
		is_binding = true
	
	if Input.is_action_just_pressed("ui_cancel"):
		if is_binding:
			var bind_node:Node2D = alts if cur_key == 1 else binds
			bind_node.get_child(cur_selection).text = "[ " + receive_key().to_upper() + " ]"
			
			SoundHelper.play_sound("res://assets/audio/sfx/cancelMenu.ogg")
			await(get_tree().create_timer(0.05).timeout)
			is_binding = false
		else:
			get_tree().paused = false
			$"../".is_input_locked = false
			queue_free()

func _input(event:InputEvent):
	if event is InputEventKey:
		if event.pressed:
			if is_binding and not event.keycode == KEY_ESCAPE:
				var bind_node:Node2D = alts if cur_key == 1 else binds
				bind_node.get_child(cur_selection).text = "[ " + OS.get_keycode_string(event.keycode).to_upper() + " ]"
				
				send_key(OS.get_keycode_string(event.keycode))
				await(get_tree().create_timer(0.05).timeout)
				is_binding = false
		
			match event.keycode:
				KEY_Q:
					page = "ui" if not page == "ui" else "note"
					generate_options()
				KEY_E:
					page = "ui" if not page == "ui" else "note"
					generate_options()

func update_selection(new_selection:int = 0):
	cur_selection = wrapi(cur_selection + new_selection, 0, keys.get_child_count())
	
	if not new_selection == 0:
		SoundHelper.play_sound("res://assets/audio/sfx/scrollMenu.ogg")
	
	for i in keys.get_child_count():
		keys.get_child(i).modulate.a = 1.0 if i == cur_selection else 0.6
	
	update_key()

func receive_key() -> String:
	var key:String = page.to_lower() + "_" + key_shit[page][cur_selection]
	return Settings._controls[key][cur_key]

func send_key(new_key:String):
	var key:String = page.to_lower() + "_" + key_shit[page][cur_selection]
	Settings._controls[key][cur_key] = new_key.replace(" ", "_")
	Settings.refresh_keys(key)

func update_key(new_key:int = 0):
	cur_key = wrapi(cur_key + new_key, 0, 2)
	
	if not new_key == 0:
		SoundHelper.play_sound("res://assets/audio/sfx/scrollMenu.ogg")
	
	for i in binds.get_child_count():
		binds.get_child(i).modulate.a = 1.0 if i == cur_selection and cur_key == 0 else 0.6
	
	for i in alts.get_child_count():
		alts.get_child(i).modulate.a = 1.0 if i == cur_selection and cur_key == 1 else 0.6

func generate_options():
	for key in keys.get_children(): key.queue_free()
	for bind in binds.get_children(): bind.queue_free()
	for alt in alts.get_children(): alt.queue_free()
	
	section_text.text = "[BINDING: " + page.replace("note", "notes").to_upper() + "]"
	section_text.text += "\nQ or E to Switch Categories."
	
	for key in key_shit[page].size():
		var bind_name:Label = $Template_Text.duplicate()
		bind_name.text = key_shit[page][key].to_upper().replace("_", " ")
		
		var why_thing:float = 250 if page == "note" else 150
		
		bind_name.position = Vector2(110, (50 * key) + why_thing)
		keys.add_child(bind_name)
		
		for bind in 2:
			var kb:Label = $Template_Text.duplicate()
			
			var key_string:String = page.to_lower() + "_" + key_shit[page][key]
			
			kb.text = "[ " + Settings._controls[key_string][bind].to_upper() + " ]"
			kb.position = Vector2(500 + (310 * bind), bind_name.position.y)
			
			var bind_node:Node2D = alts if bind == 1 else binds
			bind_node.add_child(kb)
	
	cur_key = 0
	cur_selection = 0
	
	update_selection()

func _exit_tree():
	Settings.save_controls()
