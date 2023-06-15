extends Node

func scan_mods() -> Array[String]:
	var my_mods:Array[String] = ["Friday Night Funkin'"]
	for i in DirAccess.get_files_at("user://mods"):
		if i.ends_with(".pck"):
			my_mods.append(i.replace(".pck", ""))
	
	return my_mods

func load_mod(mod:String):
	if mod == "Friday Night Funkin'":
		ProjectSettings.load_resource_pack("res://FNF-Feather.pck")
		return
	
	ProjectSettings.load_resource_pack("user://mods/" + mod + ".pck")
