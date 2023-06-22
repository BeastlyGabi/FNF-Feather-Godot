class_name StrumLine extends CanvasGroup

@onready var game = $"../../../"
@onready var receptors:Node2D = $Receptors
@onready var notes:Node2D = $Notes

@export var controls:Array[String] = ["left", "down", "up", "right"]

@export var is_cpu:bool = true

func _ready() -> void:
	for i in receptors.get_child_count():
		var receptor:AnimatedSprite2D = receptors.get_child(i)
		receptor.material = receptors.material.duplicate()
		receptor.material.set_shader_parameter("color", Note.default_colors["normal"][i % 4])
		
		if !is_cpu:
			key_presses.append(false)

func _process(delta:float) -> void:
	for note in notes.get_children():
		var scroll_diff:int = 1 if Settings.get_setting("downscroll") else -1
		var distance:float = (Conductor.position - note.time) * (0.45 * note.speed)
		
		var receptor:AnimatedSprite2D = receptors.get_child(note.direction)
		note.position = Vector2(receptor.position.x - 5, receptor.position.y + distance * scroll_diff)
		
		if note.copy_rotation: note.arrow.rotation = receptor.rotation
		if note.copy_opacity: note.modulate.a = receptor.modulate.a
		
		var kill_position:float = -25 if is_cpu else -200
		if -distance <= kill_position:
			if !is_cpu:
				if !note.was_good_hit:
					game.note_miss(note)
					if !note.is_hold:
						note.queue_free()
					
					else:
						note._did_miss = true
						note.can_be_hit = false
						note.modulate.a = 0.50
			else:
				game.cpu_note_hit(note, self)
		
		# Kill player hotds
		if note.is_hold and !note.was_good_hit and !note.can_be_hit and !is_cpu and \
		(
			scroll_diff > 0 and # Downcroll
			-distance < (kill_position + note.end.position.y)
			
			or scroll_diff < 0 and # Upscroll
			-distance < (kill_position - note.end.position.y)
		): note.queue_free()
		
		# Swordcube's Hold Note input script, thanks I wouldn't be able to
		# Figure it out, @BeastlyGabi
		if note.was_good_hit:
			if note.is_hold:
				note.position.y = 25 if scroll_diff > -1 else receptor.position.y
				note.arrow.visible = false
				note.z_index = -1
				
				if !is_cpu:
					play_anim("confirm", note.direction, receptor.frame >= 2)
				
				var char:Character = game.player # if note.must_press else game.opponent
				var index:int = note.direction % char.sing_anims.size()
				char.play_anim(char.sing_anims[index], true)
				char.hold_timer = 0.0
				
				if game.voices != null and game.voices.stream != null:
					game.voices.volume_db = linear_to_db(1.0)
				
				if !is_cpu and note.must_press and note.length >= 80.0:
					if !Input.is_action_pressed("note_" + controls[note.direction]):
						note.was_good_hit = false
						note.can_be_hit = false
						note.modulate.a = 0.30
						
						game.note_miss(note)
						note._did_miss = true
						
						play_anim("static", note.direction, true)

func pop_splash(note:Note) -> void:
	if Settings.get_setting("note_splashes") == "never" or !note.has_node("Splash"):
		return
	
	var receptor := receptors.get_child(note.direction)
	var le_splash := note.get_node("Splash").duplicate()
	le_splash.position = receptor.position
	le_splash.modulate.a = 0.80
	le_splash.visible = true
	add_child(le_splash)
	
	var has_two_anims:bool = le_splash.get_node("Anim_Player").has_animation("splash_2")
	var animation:String = "splash"
	
	if has_two_anims:
		animation = "splash_" + str(randi_range(1, 2))
	
	le_splash.get_node("Anim_Player").play(animation)
	le_splash.get_node("Anim_Player").animation_finished.connect(
		func(_anim:StringName):
			le_splash.queue_free()
	)

func _input(event:InputEvent) -> void:
	if event is InputEventKey and !is_cpu:
		var key:int = get_key_dir(event)
		if key < 0: return
		
		var glowing:bool = receptors.get_child(key).animation.ends_with("glow")
		play_anim("press" if !glowing and event.pressed else "static", key, true)
		key_shit(key)

var key_presses:Array[bool] = []

func key_shit(key:int) -> void:
	key_presses[key] = Input.is_action_pressed("note_" + controls[key])
	
	var notes_to_hit:Array[Note] = []
	for note in notes.get_children().filter(func(note:Note):
		return (note.direction == key and note.can_be_hit and !note.too_late
		and note.parent == self and !note.was_good_hit)
	): notes_to_hit.append(note)
	
	notes_to_hit.sort_custom(func(a, b):
		return int(a.time - b.time)
	)
	
	if Input.is_action_just_pressed("note_" + controls[key]):
		if notes_to_hit.size() > 0:
			var cool_note:Note = notes_to_hit[0]
			
			if notes_to_hit.size() > 1:
				for i in notes_to_hit.size():
					if i == 0: continue
					var dumb_note:Note = notes_to_hit[i]
					
					if dumb_note.direction == cool_note.direction:
						# Same note twice at 5ms of distance? die
						if absf(dumb_note.time - cool_note.time) <= 5:
							dumb_note.queue_free()
							break
						# No? then Replace the cool note if its earlier than the dumb one
						elif dumb_note.time < cool_note.time:
							cool_note = dumb_note
							break
			
			game.note_hit(cool_note, self)
			play_anim("confirm", key, true)
		
		else:
			if not Settings.get_setting("ghost_tapping"):
				game.ghost_miss(key)

func get_key_dir(event:InputEventKey) -> int:
	var key:int = -1
	for i in controls.size():
		var action:String = "note_" + controls[i].to_lower()
		if event.is_action_pressed(action) or event.is_action_released(action):
			key = i
			break
	return key

var receptor_last_anim:String
func play_anim(anim:String, direction:int, forced:bool = false, speed:float = 1.0, reverse:bool = false) -> void:
	var receptor:AnimatedSprite2D = receptors.get_child(direction)
	if forced or receptor_last_anim != anim:
		if forced:
			receptor.frame = 0
			receptor.get_node("Anim_Player").seek(0.0)
		
		receptor.get_node("Anim_Player").play(anim, -1, speed, reverse)
		receptor.material.set_shader_parameter("enabled", anim != "static")
		receptor_last_anim = anim
