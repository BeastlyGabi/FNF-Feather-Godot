class_name GameWeek extends Resource

@export var week_namespace:String = "Your Week"

@export var songs:Array[FreeplaySong] = []
@export var characters:Array[String] = ["dad", "bf", "gf"]
@export var difficulties:Array[String] = ["easy", "normal", "hard"]

@export var hide_on:Dictionary = {"story": false, "freeplay": false}
@export var week_image:String = "week1"
