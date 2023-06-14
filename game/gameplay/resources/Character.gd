class_name Character extends Node2D

@export_category("Character Node")
@export var health_icon:String = "face"
@export var sing_duration:float = 4.0
@export var health_color:Color:
	get:
		if health_color == null:
			health_color = Color.RED if not is_player else Color8(102, 255, 51)
		return health_color

@export var is_player:bool = false
@export var camera_offset:Vector2 = Vector2.ZERO

var hold_timer:float = 0.0
var is_flipped:bool = false
var finished_anim:bool = false
var headbop_beat:int = 2

var midpoint:Vector2 = Vector2.ZERO
var miss_animations:Array[String] = []

@onready var sprite:AnimatedSprite2D = $Sprite
@onready var anim_player:AnimationPlayer = $Animator

func _ready():
	if not is_player and not sprite == null:
		if name.begins_with("bf"):
			sprite.scale.x *= -1
			is_flipped = true
	
	midpoint = Vector2(sprite.position.x * 0.5, sprite.position.y * 0.5)
	anim_player.animation_finished.connect(
		func(name:StringName):
			finished_anim = true
	)
	
	if anim_player.has_animation("danceLeft") and anim_player.has_animation("danceRight"):
		headbop_beat = 1
	
	for i in Game.note_dirs.size():
		var direction:String = Game.note_dirs[i].to_upper()
		if anim_player.has_animation("sing" + direction + "miss"):
			miss_animations.append("sing" + direction + "miss")
	
	dance(true)

func get_camera_midpoint():
	if sprite == null: return
	var vec:Vector2 = position
	vec += Vector2(sprite.position.x, sprite.position.y)
	return vec

func _process(delta:float):
	if not anim_player == null:
		if not is_player:
			if is_singing():
				hold_timer += delta
			
			if hold_timer >= Conductor.step_crochet * sing_duration * 0.0011:
				dance(true)
				hold_timer = 0.0
		else:
			hold_timer += delta if is_singing() else 0.0
			if is_missing() and finished_anim:
				dance(true)


var danced:bool = false

func dance(forced:bool = false):
	if anim_player == null:
		return
	
	if anim_player.has_animation("danceLeft") and anim_player.has_animation("danceRight"):
		var anim:String = "danceRight" if danced else "danceLeft"
		play_anim(anim, forced)
		danced = not danced
	else:
		play_anim("idle", forced)


var last_anim:String

func play_anim(anim_name:String, forced:bool = false, speed:float = 1.0, from_end:bool = false):
	if anim_player == null: 
		return
	
	if is_flipped:
		if anim_name == "singLEFT": anim_name = "singRIGHT"
		elif anim_name == "singRIGHT": anim_name = "singLEFT"
	
	if not anim_player.has_animation(anim_name):
		return
	
	if forced or not last_anim == anim_name or finished_anim:
		if forced:
			anim_player.seek(0.0)
			sprite.frame = 0
		
		last_anim = anim_name
		finished_anim = false
		anim_player.play(anim_name, -1, speed * Conductor.pitch_scale, from_end)


func is_singing(): return anim_player.current_animation.begins_with("sing") if anim_player != null else false
func is_missing(): return anim_player.current_animation.ends_with("miss") if anim_player != null else false
