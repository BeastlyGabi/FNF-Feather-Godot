extends Node

enum GameplayMode {STORY, FREEPLAY, CHART}

const STORY_MODE = GameplayMode.STORY
const FREEPLAY_MODE = GameplayMode.FREEPLAY
const CHARTING_MODE = GameplayMode.CHART

var current:Chart

var data:Dictionary = {
	"name": "Test",
	"folder": "test",
	"difficulty": "normal",
}
var cur_week:String

var playlist:Array[FreeplaySong] = []
var difficulty_list:Array[String] = []

### Mode 0 is Story Mode, Mode 2 is Charting Mode, anything else is freeplay
var gameplay_mode = FREEPLAY_MODE
var total_week_score:int = 0

func reset_story_song(difficulty:String = "normal"):
	if playlist.size() > 0 and gameplay_mode == 0:
		data["name"] = playlist[0].name
		data["folder"] = playlist[0].folder
		data["difficulty"] = difficulty
		total_week_score = 0


func save_score(song:String, score:int, save_name:String):
	var score_container:Dictionary = _score_container_file()
	if not save_name in score_container:
		score_container[save_name] = {}
		
	if song in score_container[save_name]:
		if score_container[save_name][song] < score:
			score_container[save_name][song] = score
	else:
		score_container[save_name][song] = score
	
	var file = FileAccess.open("user://scores.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(score_container, '\t'))

func get_score(song:String, save_name:String) -> int:
	var score_container:Dictionary = _score_container_file()
	if save_name in score_container and song in score_container[save_name]:
		return score_container[save_name][song]
	
	return 0

func _score_container_file():
	if not ResourceLoader.exists("user://scores.json"):
		var file = FileAccess.open("user://scores.json", FileAccess.WRITE)
		file.store_string("{}")
	else:
		var file = FileAccess.open("user://scores.json", FileAccess.READ)
		if not file.get_as_text() == null or len(file.get_as_text()) > 1:
			return JSON.parse_string(file.get_as_text())
	
	return {}
