class_name StrumLine extends CanvasGroup

@onready var game = $"../../"
@onready var receptors:Node2D = $Receptors
@onready var notes:Node2D = $Notes

@export var controls:Array[String] = ["note_left", "note_down", "note_up", "note_right"]
@export var is_cpu:bool = true

## Characters that sing when a note is hit ##
var singers:Array[Character] = []

func _ready() -> void:
	for i in receptors.get_child_count():
		var receptor:Receptor = receptors.get_child(i)
		receptor.material = receptors.material.duplicate()
		receptor.modulate.a = 0.0
		
		if not is_cpu:
			key_presses.append(false)
			receptor.reset_anim = "press"
		
		play_anim("static", i, true, 1.0)
		
		get_tree().create_tween().set_ease(Tween.EASE_IN) \
		.tween_property(receptor, "modulate:a", 1.0, (i) * Conductor.rate_crochet / 1000.0) \
		.set_delay(0.35)

var update_notes:bool = true

func _process(_delta:float) -> void:
	if update_notes: note_process()

func note_process() -> void:
	for note in notes.get_children():
		if note == null:
			note.queue_free()
			return
		
		var scroll_diff:int = 1 if Settings.get_setting("downscroll") else -1
		var distance:float = (Conductor.position - note.time) * (0.45 * note.speed)
		
		var receptor:AnimatedSprite2D = receptors.get_child(note.direction)
		note.position = Vector2(receptor.position.x, receptor.position.y + distance * scroll_diff)
		
		if receptor.material.get_shader_parameter("color") != note.color:
			receptor.material.set_shader_parameter("color", note.color)
		
		if note.copy_rotation: note.arrow.rotation = receptor.rotation
		if note.copy_opacity: note.modulate.a = receptor.modulate.a
		
		var kill_position:float = -25 if is_cpu else -200
		if -distance <= kill_position:
			if not is_cpu:
				if not note.was_good_hit:
					game.note_miss(note)
					if not note.is_hold:
						note.queue_free()
					
					else:
						note._did_miss = true
						note.can_be_hit = false
						note.modulate.a = 0.50
			else:
				game.note_hit(note, self)
		
		# Kill player hotds
		if note.is_hold and not note.was_good_hit and not note.can_be_hit and not is_cpu and \
		(
			scroll_diff > 0 and # Downcroll
			-distance < (kill_position + note.end.position.y)
			
			or scroll_diff < 0 and # Upscroll
			-distance < (kill_position - note.end.position.y)
		): note.queue_free()
		
		# Swordcube's Hold Note input script, thanks I wouldn't be able to
		# Figure it out, @BeastlyGabi
		if note.was_good_hit and note.is_hold:
			note.position.y = 25 if scroll_diff > -1 else receptor.position.y
			note.arrow.visible = false
			note.z_index = -1
			
			if not is_cpu:
				play_anim("confirm", note.direction, receptor.frame >= 2)
			
			for _char in singers:
				var index:int = note.direction % _char.sing_anims.size()
				_char.play_anim(_char.sing_anims[index], true)
				_char.hold_timer = 0.0
			
			if game.voices != null and game.voices.stream != null:
				game.voices.volume_db = linear_to_db(1.0)
			
			if not is_cpu and note.must_press and note.length >= 80.0:
				if not Input.is_action_pressed(controls[note.direction]):
					note.was_good_hit = false
					note.can_be_hit = false
					note.modulate.a = 0.30
					
					game.note_miss(note)
					note._did_miss = true

func pop_splash(note:Note) -> void:
	if not Settings.get_setting("note_splashes") or not note.has_node("Splash"):
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
	
	if note.style == "default":
		le_splash.rotate(randi_range(-360, 360))

func _input(event:InputEvent) -> void:
	if event is InputEventKey and not is_cpu:
		var key:int = get_key_dir(event)
		if key < 0: return
		
		var glowing:bool = receptors.get_child(key).animation.ends_with("glow")
		play_anim("press" if not glowing and event.pressed else "static", key, true)
		key_shit(key)

var key_presses:Array[bool] = []

func sort_notes(a:Note, b:Note) -> float:
	return b.time if b.time > a.time else a.time

func key_shit(key:int) -> void:
	key_presses[key] = Input.is_action_pressed(controls[key])
	
	var notes_to_hit:Array[Note] = []
	for note in notes.get_children().filter(func(note:Note):
		return (note.direction == key and note.can_be_hit and not note.too_late
		and note.parent == self and not note.was_good_hit)
	): notes_to_hit.append(note)
	
	notes_to_hit.sort_custom(sort_notes)
	
	if Input.is_action_just_pressed(controls[key]):
		if notes_to_hit.size() > 0:
			var cool_note:Note = notes_to_hit[0]
			
			for i in notes_to_hit.size():
				if i <= 0: continue
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
		var action:String = controls[i].to_lower()
		if event.is_action_pressed(action) or event.is_action_released(action):
			key = i
			break
	return key

func play_anim(anim:String, direction:int, forced:bool = false, speed:float = 1.0, reverse:bool = false) -> void:
	receptors.get_child(direction).play_anim(anim, forced, speed, reverse)

func set_lane_speed(new_speed:float) -> void:
	pass
