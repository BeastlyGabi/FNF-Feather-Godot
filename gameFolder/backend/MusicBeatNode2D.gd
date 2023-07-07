class_name MusicBeatNode2D extends Node2D

var step:int:
	get: return Conductor.step
var beat:int:
	get: return Conductor.beat
var bar:int:
	get: return Conductor.bar
var tick:int:
	get: return Conductor.tick

func _init() -> void:
	Conductor.reset()
