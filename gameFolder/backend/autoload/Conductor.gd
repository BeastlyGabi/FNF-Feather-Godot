extends Node

var position:float = 0.0
var playback_rate:float = 1.0:
	set(v):
		Engine.time_scale = v
		AudioServer.playback_speed_scale = v
		playback_rate = v

var offset:float = 0.0
var crochet:float = 0.0
var step_crochet:float = 0.0

var rate_crochet:float:
	get: return crochet / playback_rate
var rate_step_crochet:float:
	get: return step_crochet / playback_rate

var bpm:float = 100.0:
	set(b):
		crochet = ((60 / b) * 1000.0)
		step_crochet = crochet / 4.0
		bpm = b

var step:int = 0
var beat:int = 0:
	get: return step / 4

var sect:int = 0:
	get: return beat / 4

var tick:int = 0:
	get: return floor(_get_tick())

var prev_step:int = -1; var prev_beat:int = -1;
var prev_sect:int = -1; var prev_tick:int = -1

func _process(_delta:float) -> void:
	var last_event:Dictionary = {"step": 0, "time": 0.0, "bpm": 0.0}
	var dumb_calc:float = ((position - offset) - last_event["time"]) / step_crochet
	step = last_event["step"] + floor(dumb_calc)
	
	if position >= 0:
		if prev_step != step:
			if step > prev_step:
				Game.safe_call(get_tree().current_scene, "on_step")
				prev_step = step
		
		if prev_beat != beat:
			if step % 4 == 0 and beat > prev_beat:
				Game.safe_call(get_tree().current_scene, "on_beat")
				prev_beat = beat
		
		if prev_sect != sect:
			if beat % 4 == 0 and sect > prev_sect:
				Game.safe_call(Game.current_scene, "on_sect")
				prev_sect = sect
				
		if tick > prev_tick:
			Game.safe_call(Game.current_scene, "on_tick")
			prev_tick = tick

const rows_per_beat:int = 48

func _get_tick() -> float: return _get_beat() * rows_per_beat
func _get_beat() -> float: return (position * bpm) / 60.0

func reset():
	position = 0.0
	step = 0; beat = 0; sect = 0; tick = 0
	prev_step = -1; prev_beat = -1; prev_sect = -1; prev_tick = -1
