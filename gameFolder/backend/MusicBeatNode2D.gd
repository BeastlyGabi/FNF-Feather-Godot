class_name MusicBeatNode2D extends Node2D

var step:int:
	get: return Conductor.step
var beat:int:
	get: return Conductor.beat
var sect:int:
	get: return Conductor.sect
var tick:int:
	get: return Conductor.tick

func _init() -> void:
	Conductor.reset()
