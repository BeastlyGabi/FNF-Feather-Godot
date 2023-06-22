extends Node

signal step_caller(step:int)
signal beat_caller(beat:int)
signal sect_caller(sect:int)

var position:float = 0.0
var pitch_scale:float = 1.0
var step_crochet:float = 0.0
var crochet:float = 0.0

var bpm:float = 100.0:
	set(b):
		step_crochet = ((60 / b) * 1000.0)
		crochet = step_crochet * 4
		bpm = b

var current_step:int = 0
var current_beat:int = 0:
	get: return current_step / 4

var current_sect:int = 0:
	get: return current_beat / 4

var prev_step:int = -1
var prev_beat:int = -1
var prev_sect:int = -1

func _process(_delta:float) -> void:
	var last_event:Dictionary = {
		"step": 0,
		"time": 0.0,
		"bpm": 0.0
	}
	
	var dumb_calc:float = last_event["step"] + (position - last_event["time"]) / step_crochet
	current_step = floor(dumb_calc)
	
	if current_step > prev_step:
		step_caller.emit(current_step)
		prev_step = current_step
	
	if current_step % 4 == 0 and current_beat > prev_beat:
		beat_caller.emit(current_beat)
		prev_beat = current_beat
	
	if current_beat % 4 == 0 and current_sect > prev_sect:
		sect_caller.emit(current_sect)
		prev_sect = current_sect

func reset():
	position = 0.0
	
	current_step = 0; current_beat = 0; current_sect = 0
	prev_step = -1; prev_beat = -1; prev_sect = -1
