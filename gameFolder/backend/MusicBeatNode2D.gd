class_name MusicBeatNode2D extends Node2D

var cur_step:int:
	get: return Conductor.current_step
var cur_beat:int:
	get: return Conductor.current_beat
var cur_sect:int:
	get: return Conductor.current_sect

func _init() -> void:
	Conductor.reset()
	
	Conductor.step_caller.connect(on_step)
	Conductor.beat_caller.connect(on_beat)
	Conductor.sect_caller.connect(on_sect)

func _exit_tree() -> void:
	Conductor.step_caller.disconnect(on_step)
	Conductor.beat_caller.disconnect(on_beat)
	Conductor.sect_caller.disconnect(on_sect)

func on_step(step:int) -> void: pass
func on_beat(beat:int) -> void: pass
func on_sect(sect:int) -> void: pass
