extends Node2D

var SCREEN:Dictionary = {
	"width": ProjectSettings.get_setting("display/window/size/viewport_width"),
	"height": ProjectSettings.get_setting("display/window/size/viewport_height"),
}

var LAST_SCENE:String

func _ready() -> void:
	LAST_SCENE = get_tree().current_scene.scene_file_path
	switch_scene("menus/Freeplay")

func switch_scene(next_scene:String) -> void:
	var scene_path:String = "res://gameFolder/" + next_scene + ".tscn"
	get_tree().change_scene_to_file(scene_path)
	LAST_SCENE = scene_path

var CUR_SONG:Chart
var META_DATA:Chart.SongMetaData
func bind_song(_song_name:String, _diff:String = "hard") -> void:
	CUR_SONG = Chart.load_chart(_song_name, _diff)
	switch_scene("gameplay/Gameplay")

func reset_scene() -> void: switch_scene(LAST_SCENE)

func float_to_minute(value:float): return int(value / 60)
func float_to_seconds(value:float): return fmod(value, 60)
func format_to_time(value:float): return "%02d:%02d" % [float_to_minute(value), float_to_seconds(value)]
