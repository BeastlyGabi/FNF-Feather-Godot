extends Node2D

@onready var music:AudioStreamPlayer = $MUSIC_STREAM
@onready var sounds:Node = $SOUNDS_PLAYED

var music_file:String

func play_music(msc:String, at_volume:float = 1.0, looped:bool = true, start_time:float = 0.0):
	music.stream = load(msc)
	music.play(start_time)
	music.stream.loop = looped
	music.volume_db = 1 * at_volume
	music_file = msc

func play_sound(snd:String, sound_volume:float = 1.0, start_time:float = 0.0, pitch_scale:float = 1.0):
	var cool_sound:AudioStreamPlayer = AudioStreamPlayer.new()
	cool_sound.stream = load(snd)
	cool_sound.volume_db = sound_volume
	cool_sound.pitch_scale = pitch_scale
	sounds.add_child(cool_sound)
	cool_sound.play(start_time)
	cool_sound.finished.connect(cool_sound.queue_free)

func stop_music():
	if not music.stream == null:
		music.stop()

func get_music_time() -> float:
	return music.get_playback_position() if not music == null else 0.0
