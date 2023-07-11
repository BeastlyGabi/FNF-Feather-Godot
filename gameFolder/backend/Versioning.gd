class_name Versioning extends Resource

enum DevCycle {STABLE, BETA, ALPHA}

var name:String
var cycle:DevCycle = DevCycle.ALPHA

var ff_version:String:
	get:
		var branch_name:String = ""
		match cycle:
			DevCycle.BETA: branch_name = "BETA"
			DevCycle.ALPHA: branch_name = "ALPHA"
		
		return name + " [%s]" % branch_name if branch_name != "" else name

var fnf_version:String:
	get: return "0.2.8"

func _init(major:int, minor:int, patch:int = -1) -> void:
	var _ver:String = str(major) + "." + str(minor)
	if patch != -1: _ver += str(patch)
	name = _ver
