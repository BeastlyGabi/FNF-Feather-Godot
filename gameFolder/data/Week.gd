class_name Week extends Resource # Wanted to call them levels but everyone knows them by weeks

@export var week_name:String = "Your Week Name"
@export var songs:Array[Song] = []
@export var difficulties:Array[String] = ["easy", "normal", "hard"]
@export var characters:Array[String] = ["dad", "bf", "gf"]

func _ready() -> void:
	for song in songs:
		song.difficulties = self.difficulties
