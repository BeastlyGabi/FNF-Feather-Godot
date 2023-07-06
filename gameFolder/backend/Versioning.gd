class_name Versioning extends Resource

enum DevBranch {STABLE, BETA, ALPHA}

var name:String
var branch:DevBranch = DevBranch.ALPHA

func get_fnf_ver() -> String:
	return "0.2.8"

func _init(major:int, minor:int, patch:int = -1) -> void:
	var _ver:String = str(major) + "." + str(minor)
	if patch != -1: _ver += str(patch)
	name = _ver

func branch_to_string() -> String:
	var branch_name:String = ""
	match branch:
		DevBranch.BETA: branch_name = "BETA"
		DevBranch.ALPHA: branch_name = "ALPHA"
	return branch_name
