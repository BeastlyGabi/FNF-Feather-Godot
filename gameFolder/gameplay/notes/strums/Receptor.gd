class_name Receptor extends AnimatedSprite2D

var reset_anim:String = ""
@onready var anim:AnimationPlayer = $Anim_Player
var finished_playing:bool = false

func _ready():
	anim.animation_finished.connect(
		func(anim_name:StringName):
			finished_playing = true
	)

func _process(_delta:float):
	if reset_anim != "":
		if frame >= 3 and last_played.ends_with("confirm"):
			play_anim(reset_anim, true)

var last_played:String

func play_anim(anim_name:String, forced:bool = false, speed:float = 1.0, reverse:bool = false) -> void:
	if forced or last_played != anim_name:
		if forced:
			frame = 0
			anim.seek(0.0)
		
		finished_playing = false
		anim.play(anim_name, -1, speed, reverse)
		material.set_shader_parameter("enabled", anim_name != "static")
		last_played = anim_name
