class_name UIStyle extends Node2D

@export var note_style:String = "default"
@export var strum_style:String = "default"
@export var countdown_config:Dictionary = {
	"sprites": ["prepare", "ready", "set", "go"],
	"sounds": ["intro3", "intro2", "intro1", "introGo"]
}

var fallback_style:String = "normal"

func get_asset(folder:String, asset:String) -> String:
	var _base:String = "res://assets/" + folder + "/"
	
	var path:String = _base + name + "/" + asset
	if not ResourceLoader.exists(path):
		path = _base + fallback_style + "/" + asset
	
	return path

func get_template(template:String) -> Node:
	return get_node("Templates/" + template)
