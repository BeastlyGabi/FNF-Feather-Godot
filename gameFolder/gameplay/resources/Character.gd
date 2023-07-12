class_name Character extends AnimatedSprite2D

@export var health_icon:Texture2D = load("res://assets/images/icons/face.png")
@export var health_color:Color
@export var camera_offset:Vector2 = Vector2.ZERO
@export var sing_duration:float = 4.0
@export var flip_if_opponent:bool = false

@export var allowed_to_dance:bool = true
@export var dance_interval:int = 2

var hold_timer:float = 0.0
var is_player:bool = false

@onready var anim:AnimationPlayer = $Anim_Player

var sing_anims:Array[String] = ["singLEFT", "singDOWN", "singUP", "singRIGHT"]
var miss_anims:Array[String] = []

var _swapped_horizontals:bool = false

func _ready() -> void:
	dance(true)
	
	for i in sing_anims:
		if anim.has_animation(i + "miss"):
			miss_anims.append(i + "miss")
		else: miss_anims.append(i)
	
	if not is_player and flip_if_opponent:
		_swapped_horizontals = true
		scale.x *= -1
		
		for _i in sing_anims.size():
			var i:String = sing_anims[_i]
			if i == "singLEFT": sing_anims[_i] = "singRIGHT"
			if i == "singRIGHT": sing_anims[_i] = "singLEFT"

func _process(delta:float) -> void:
	if anim != null:
		if is_singing():
			hold_timer += delta
		elif is_player:
			hold_timer = 0.0
		
		if not is_player:
			if hold_timer >= Conductor.crochet * (sing_duration * Engine.time_scale) * 0.001:
				dance()
				hold_timer = 0.0

var danced:bool = false
func dance(forced:bool = false) -> void:
	if not allowed_to_dance: return
	
	var anim_name:String = "idle"
	if quick_dancer():
		danced = not danced
		anim_name = "danceRight" if danced else "danceLeft"
	
	play_anim(anim_name, forced)

var last_anim:String
func play_anim(anim_name:String, forced:bool = false, speed:float = 1.0, reversed:bool = false) -> void:
	if forced:
		anim.seek(0.0)
		frame = 0
	
	anim.play(anim_name, -1, speed, reversed)
	last_anim = anim_name

func quick_dancer() -> bool: return anim != null and anim.has_animation("danceLeft") and anim.has_animation("danceRight")
func is_singing() -> bool: return anim != null and anim.current_animation.begins_with("sing")
func is_missing() -> bool: return anim != null and anim.current_animation.ends_with("miss")
