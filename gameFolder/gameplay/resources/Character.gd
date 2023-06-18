extends AnimatedSprite2D

@export var health_color:Color = Color8(255, 0, 0)
@export var sing_duration:float = 4.0
var hold_timer:float = 0.0

@export var dance_interval:int = 2
@export var is_player:bool = false

@onready var anim:AnimationPlayer = $Anim_Player

func _ready() -> void:
	dance(true)

func _process(delta:float) -> void:
	if anim != null:
		if is_singing():
			hold_timer += delta
		elif is_player:
			hold_timer = 0.0
		
		if !is_player:
			if hold_timer >= Conductor.step_crochet * sing_duration * 0.001:
				dance()
				hold_timer = 0.0

var danced:bool = false
func dance(forced:bool = false) -> void:
	var anim_name:String = "idle"
	if quick_dancer():
		danced = !danced
		anim_name = "dance" + "Right" if danced else "Left"
	
	play_anim(anim_name, forced)

var last_anim:String
func play_anim(anim_name:String, forced:bool = false, speed:float = 1.0, reversed:bool = false) -> void:
	if forced:
		anim.seek(0.0)
		frame = 0
	
	anim.play(anim_name, -1, speed, reversed)
	last_anim = anim_name

func quick_dancer() -> bool: return anim != null and anim.get_animation("danceLeft") != null and anim.get_animation("danceRight") != null
func is_singing() -> bool: return anim != null and anim.current_animation.begins_with("sing")
func is_missing() -> bool: return anim != null and anim.current_animation.ends_with("miss")
