class_name StrumLine extends Node2D

@export var is_cpu:bool = true
@onready var receptors:Node2D = $Receptors
@onready var notes:CanvasGroup = $Notes
@onready var game = $"../../../"

func fade_receptors_in():
	for i in receptors.get_child_count():
		receptors.get_child(i).modulate.a = 0.0
		receptors.get_child(i).material = receptors.material.duplicate()
		
		if receptors.get_child(i).modulate.a <= 0.0:
			get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC) \
			.tween_property(receptors.get_child(i), "modulate:a", 1.0, Conductor.crochet / 500) \
			.set_delay(i * 0.45)


func _process(delta:float):
	for note in notes.get_children():
		if note.in_edit:
			break
		
		var downscroll_multiplier = 1 if Settings.get_setting("downscroll") else -1
		var distance = (Conductor.position - note.time) * (0.45 * note.speed)
		var receptor:Receptor = receptors.get_child(note.direction)
		receptor.cpu_receptor = is_cpu
		
		note.position = Vector2(receptor.position.x, receptor.position.y + distance * downscroll_multiplier)
		
		var kill_position:float = -25
		if not is_cpu: kill_position = -200
		
		if -distance <= kill_position:
			if not is_cpu:
				
				if not note.was_good_hit:
					game.note_miss(note)
					if not note.is_hold:
						note.queue_free()
					
					else:
						note.can_be_missed = false
						note.can_be_hit = false
						note.modulate.a = 0.50
			else:
				# CPU Hit Script
				game.cpu_note_hit(note, self)
		
		# Kill player hotds
		if note.is_hold and not note.was_good_hit and not note.can_be_hit and not is_cpu and \
		(
			downscroll_multiplier > 0 and # Downcroll
			-distance < (kill_position + note.end.position.y)
			
			or downscroll_multiplier < 0 and # Upscroll
			-distance < (kill_position - note.end.position.y)
		): note.queue_free()
		
		# Swordcube's Hold Note input script, thanks I wouldn't be able to
		# Figure it out, @BeastlyGabi
		if note.was_good_hit:
			if note.is_hold:
				note.position.y = 25 if downscroll_multiplier else receptor.position.y
				note.arrow.visible = false
				note.z_index = -1
				
				if not is_cpu:
					receptor.play_anim(Game.note_dirs[note.direction].to_lower() + " confirm", true)
				
				var char:Character = game.player if note.must_press else game.opponent
				char.play_anim("sing" + Game.note_dirs[note.direction].to_upper(), true)
				
				note.hold_length -= (delta * 1000.0 * Conductor.pitch_scale)
				if note.hold_length <= -(Conductor.step_crochet / 1000.0):
					note.queue_free()
				
				if not is_cpu and note.must_press and note.hold_length >= 80.0:
					
					if not Input.is_action_pressed("note_" + Game.note_dirs[note.direction]):
						
						note.was_good_hit = false
						note.modulate.a = 0.30
						
						note.can_be_missed = true
						game.note_miss(note)
						note.can_be_missed = false
						
						receptor.play_anim(Game.note_dirs[note.direction] + " static", true)


func pop_splash(note:Note):
	if not Settings.get_setting("note_splashes") or \
		note == null or not note.has_node("Splash"):
		return
	
	var splash:AnimatedSprite2D = note.get_node("Splash").duplicate()
	
	splash.visible = true
	splash.modulate.a = 0.70
	
	splash.get_node("AnimationPlayer").play("splash " + str(randi_range(1, 2)))
	splash.get_node("AnimationPlayer").animation_finished.connect(
		func(anim_name:StringName):
			splash.queue_free()
	)
	splash.position = receptors.get_child(note.direction).position
	
	add_child(splash)

func _input(event:InputEvent):
	if event is InputEventKey:
		var dir:int = get_input_dir(event)
		if dir < 0 or is_cpu: # SOMEHOW
			return
		
		var receptor:Receptor = receptors.get_child(dir)
		
		if Input.is_action_just_pressed("note_" + Game.note_dirs[dir]):
			if !receptor.animation.ends_with("confirm"):
				receptor.play_anim(Game.note_dirs[dir].to_lower() + " press", true)
				if not receptor.material == null and receptor.material is ShaderMaterial:
					receptor.material.set_shader_parameter("enabled", true)
		
		if Input.is_action_just_released("note_" + Game.note_dirs[dir]):
			receptor.play_anim(Game.note_dirs[dir].to_lower() + " static", true)
			if not receptor.material == null and receptor.material is ShaderMaterial:
				receptor.material.set_shader_parameter("enabled", false)

func get_input_dir(e:InputEventKey):
	var stored_number:int = -1
	
	for i in Game.note_dirs.size():
		var a:String = "note_" + Game.note_dirs[i].to_lower()
		if e.is_action_pressed(a) or e.is_action_released(a):
			stored_number = i
			break
	
	return stored_number
