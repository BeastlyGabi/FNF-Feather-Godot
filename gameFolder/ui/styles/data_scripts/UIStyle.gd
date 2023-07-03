class_name UIStyle extends Node2D

@export var note_style:String = "default"
@export var strum_style:String = "default"
@export var countdown_config:Dictionary = {
	"sprites": ["prepare", "ready", "set", "go"],
	"sounds": ["intro3", "intro2", "intro1", "introGo"]
}

@export var judgement_textures:Dictionary = {}

func get_asset(folder:String, asset:String) -> String:
	var _base:String = "res://assets/" + folder + "/"
	
	var path:String = _base + name + "/" + asset
	if not ResourceLoader.exists(path):
		path = _base + "normal/" + asset
	
	return path

func get_template(template:String) -> Node:
	return get_node("Templates/" + template)

func get_judgement_texture(_judge:String) -> Texture2D:
	var tex:Texture2D = load("res://assets/images/UI/ratings/" + name + "/shit.png")
	
	for i in judgement_textures:
		if i == _judge and judgement_textures[i] != null:
			tex = judgement_textures[i]
	
	return tex
