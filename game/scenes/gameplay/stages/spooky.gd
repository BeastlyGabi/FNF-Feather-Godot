extends Stage

@onready var game = $"../"

func on_beat(beat:int):
	var seed = randf_range(0, 100)
	if seed < 10 and beat > strike_beat + strike_offset:
		lightning_strike(beat)

var strike_beat:int = 0
var strike_offset:int = 8

func lightning_strike(le_beat:int) -> void:
	var base:String = "res://assets/images/stages/spooky/audio/sfx/"
	SoundHelper.play_sound(base + "thunder_" + str(randi_range(1, 2)) + ".ogg")
	
	$bg.play("halloweem bg lightning strike")
	$bg.animation_finished.connect(func():
		$bg.play("halloweem bg")
	)
	
	strike_beat = le_beat
	strike_offset = randi_range(8, 24)
	
	game.player.play_anim('scared', true);
	game.spectator.play_anim('scared', true);
