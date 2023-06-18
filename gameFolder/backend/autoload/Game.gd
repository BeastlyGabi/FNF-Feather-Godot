extends Node2D

var SCREEN:Dictionary = {
	"width": ProjectSettings.get_setting("display/window/size/viewport_width"),
	"height": ProjectSettings.get_setting("display/window/size/viewport_height"),
}

var LAST_SCENE:String

func _ready() -> void:
	LAST_SCENE = get_tree().current_scene.scene_file_path
	switch_scene("gameplay/Gameplay")

func switch_scene(next_scene:String) -> void:
	var scene_path:String = "res://gameFolder/" + next_scene + ".tscn"
	get_tree().change_scene_to_file(scene_path)
	LAST_SCENE = scene_path

func reset_scene() -> void: switch_scene(LAST_SCENE)
