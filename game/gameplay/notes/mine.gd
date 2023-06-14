extends Note

@onready var game = $"../../../"

func _ready():
	position = Vector2(-INF, INF)
	arrow.play(Game.note_dirs[direction] + " note")	
	
	# MINES DON'T HAVE SUSTAINS
	_sustain_loaded = false
	hold_length = 0.0

func _process(delta:float):
	super._process(delta)

func on_note_hit(player:bool = false):
	if player:
		game.health -= 0.875

func on_note_miss():
	return EVENT_STOP
