extends Node2D

@onready var splash_icon:Sprite2D = $Bird
@onready var powered_text:Alphabet = $Powered_Text

func _ready():
	splash_icon.modulate.a = 0.0
	powered_text.modulate.a = 0.0
	
	####################
	### Start Tweens ###
	####################
	
	var tween_a:Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	var tween_b:Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	
	tween_a.tween_property(splash_icon, "modulate:a", 1.0, 0.50)
	tween_b.tween_property(powered_text, "modulate:a", 1.0, 0.80).set_delay(0.50)
	
	await(tween_b.finished)
	
	SoundHelper.play_sound("res://assets/audio/sfx/hey.ogg")
	
	##################
	### End Tweens ###
	##################
	
	await(get_tree().create_timer(0.35).timeout)
	
	var tween_icon:Tween = create_tween().set_ease(Tween.EASE_OUT)
	tween_icon.tween_property(splash_icon, "position:x", 5000, 1).set_delay(0.35)
	tween_icon.finished.connect(splash_icon.queue_free)
	
	for i in powered_text.get_child_count():
		var letter:AnimatedSprite2D = powered_text.get_child(i)
		var tween_letter:Tween = create_tween().set_ease(Tween.EASE_OUT)
		
		tween_letter.tween_property(letter, "modulate:a", 0.0, i * 0.05).set_delay(0.38) \
		.finished.connect(letter.queue_free)
	
	#####################
	### End Functions ###
	#####################
	
	await(get_tree().create_timer(2.15).timeout)
	Game.switch_scene("menus/TitleScreen", true)
