extends Node2D

@onready var music:AudioStreamPlayer = $Music
@onready var sounds:Node = $Sounds

func play_music(path:String, volume:float = 1.0, start_time:float = 0.0, looped:bool = true) -> void:
	music.stream = load(path); music.volume_db = linear_to_db(volume)
	if music.stream != null: music.stream.loop = looped
	music.play(start_time)

func play_sound(path:String, volume:float = 1.0, start_time:float = 0.0) -> void:
	var new_sound:AudioStreamPlayer = AudioStreamPlayer.new()
	new_sound.stream = load(path)
	new_sound.volume_db = linear_to_db(volume)
	
	sounds.add_child(new_sound)
	
	new_sound.play(start_time)
	new_sound.finished.connect(new_sound.queue_free)

var need_to_fade:bool = false
var fade_max_vol:float = 0.7
var fade_speed:float = 50.0

func ask_to_fade(max_vol:float = 0.7, speed:float = 50.0) -> void:
	fade_max_vol = max_vol; fade_speed = speed
	need_to_fade = true

func _process(delta:float) -> void:
	if music.stream != null and music.playing and need_to_fade:
		if music.volume_db < linear_to_db(fade_max_vol):
			print("fading ", music.volume_db)
			music.volume_db += fade_speed * delta
		else:
			print("done fading")
			need_to_fade = false
