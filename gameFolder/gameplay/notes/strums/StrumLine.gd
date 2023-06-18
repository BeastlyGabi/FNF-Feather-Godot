class_name StrumLine extends Node2D

@onready var game = $"../../"
@onready var receptors:Node2D = $Receptors
@onready var notes:CanvasGroup = $Notes

const colors:Array[String] = ["purple", "blue", "green", "red"]
const directions:Array[String] = ["left", "down", "up", "right"]

@export var is_cpu:bool = false

func _ready() -> void:
	for i in receptors.get_child_count():
		var receptor:AnimatedSprite2D = receptors.get_child(i)
		receptor.material = receptors.material.duplicate()
		receptor.material.set_shader_parameter("color", Note.default_colors["normal"][i % 4])

func _process(delta:float) -> void:
	for note in notes.get_children():
		var scroll_diff:int = 1 if Settings.get_setting("downscroll") else -1
		var distance:float = (Conductor.position - note.time) * (0.45 * note.speed)
		
		var receptor:AnimatedSprite2D = receptors.get_child(note.direction)
		note.position = Vector2(receptor.position.x, receptor.position.y + distance * scroll_diff)
		
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
				
				play_anim("confirm", note.direction, receptor.frame >= 2)
				
				if !is_cpu and note.must_press and note.length >= 80.0:
					if !Input.is_action_pressed("note_" + directions[note.direction]):
						note.was_good_hit = false
						note.can_be_hit = false
						note.modulate.a = 0.30
						
						game.note_miss(note)
						note._did_miss = true
						
						play_anim("static", note.direction, true)
	
	for i in receptors.get_child_count():
		var receptor:AnimatedSprite2D = receptors.get_child(i)
		if is_cpu and receptor.frame >= 2:
			play_anim("static", i, true)

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
		var key:int = StrumLine.get_key_dir(event)
		if key < 0: return
		
		if event.pressed:
			if not receptors.get_child(key).animation.ends_with("glow"):
				play_anim("press", key, true)
		else:
			play_anim("static", key, true)

static func get_key_dir(event:InputEventKey) -> int:
	var key:int = -1
	for i in directions.size():
		var action:String = "note_" + directions[i].to_lower()
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
