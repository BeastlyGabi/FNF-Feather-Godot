class_name Receptor extends AnimatedSprite2D

var cpu_receptor:bool = false
var finished_anim:bool = false

func _ready():
	get_node("AnimationPlayer").animation_finished.connect(
		func(anim:StringName):
			finished_anim = true
	)

func _process(delta:float):
	if cpu_receptor:
		if get_node("AnimationPlayer").current_animation.ends_with("confirm") and finished_anim:
			play_anim(name + " static", true)


var last_anim:String

func play_anim(anim_name:String, forced:bool = false, speed:float = 1.0, from_end:bool = false):
	if forced or not last_anim == anim_name or finished_anim:
		if forced:
			frame = 0
			get_node("AnimationPlayer").seek(0.0)
		
		last_anim = anim_name
		finished_anim = false
		get_node("AnimationPlayer").play(anim_name, -1, speed * Conductor.pitch_scale, from_end)
