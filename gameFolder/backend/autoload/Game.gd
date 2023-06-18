extends Node2D

var SCREEN:Dictionary = {
	"width": ProjectSettings.get_setting("display/window/size/viewport_width"),
	"height": ProjectSettings.get_setting("display/window/size/viewport_height"),
}

func _ready():
	switch_scene("gameplay/Gameplay")

func switch_scene(next_scene:String) -> void:
	get_tree().change_scene_to_file("res://gameFolder/" + next_scene + ".tscn")
