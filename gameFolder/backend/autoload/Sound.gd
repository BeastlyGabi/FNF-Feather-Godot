extends Node2D

@onready var music:AudioStreamPlayer = $Music
@onready var sounds:Node = $Sounds

func play_music(path:String, volume:float = 1.0, start_time:float = 0.0, looped:bool = true) -> void:
	music.stream = load(path)
	music.volume_db = linear_to_db(volume)
	music.stream.loop = looped
	music.play(start_time)

func play_sound(path:String, volume:float = 1.0, start_time:float = 0.0) -> void:
	var new_sound:AudioStreamPlayer = AudioStreamPlayer.new()
	new_sound.stream = load(path)
	new_sound.volume_db = linear_to_db(volume)
	
	sounds.add_child(new_sound)
	
	new_sound.play(start_time)
	new_sound.finished.connect(new_sound.queue_free)
