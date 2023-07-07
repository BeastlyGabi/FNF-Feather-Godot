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

var bar:int = 0:
	get: return beat / 4

var tick:int = 0:
	get: return floor(_get_tick(self.position))

var bpm_changes:Array = []
func pull_bpm_changes(chart:Chart):
	bpm_changes = []
	
	var event_steps:int = 0
	var event_time:float = 0.0
	var current_bpm:float = bpm
	
	if chart.events.size() > 1:
		for i in chart.events.size():
			var event:Chart.EventData = chart.events[i]
			if event.name == "BPM Change":
				event_steps += 16
				current_bpm = event.args[0]
				event_time += ((60 / current_bpm) * 1000.0 / 4.0) * 16;
				
				var change:Dictionary = {
					"step": int(event_steps),
					"time": float(event_time),
					"bpm": float(current_bpm)
				}
				bpm_changes.append(change)
	
	print("bpm change list size ", bpm_changes.size())

var prev_step:int = -1; var prev_beat:int = -1;
var prev_bar:int = -1; var prev_tick:int = -1

func _process(_delta:float) -> void:
	var last_event:Dictionary = {"step": 0, "time": 0.0, "bpm": 0.0}
	
	for i in bpm_changes.size():
		if position >= bpm_changes[i]["time"]:
			last_event = bpm_changes[i]
	
	var dumb_calc:float = ((position - offset) - last_event["time"]) / step_crochet
	step = last_event["step"] + floor(dumb_calc)
	
	if position >= 0:
		if step > prev_step:
			Game.safe_call(get_tree().current_scene, "on_step")
			prev_step = step
		
		if beat > prev_beat:
			Game.safe_call(get_tree().current_scene, "on_beat")
			prev_beat = beat
		
		if bar > prev_bar:
			Game.safe_call(Game.current_scene, "on_bar")
			prev_bar = bar
		
		if tick > prev_tick:
			Game.safe_call(Game.current_scene, "on_tick")
			prev_tick = tick

const rows_per_beat:int = 48

func _get_tick(pos:float) -> float: return _get_beat(pos) * rows_per_beat
func _get_beat(pos:float) -> float: return (pos * bpm) / 60.0

func reset():
	position = 0.0; step = 0; beat = 0; bar = 0; tick = 0
	prev_step = -1; prev_beat = -1; prev_bar = -1; prev_tick = -1
