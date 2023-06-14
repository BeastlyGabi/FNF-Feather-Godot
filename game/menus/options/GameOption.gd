# Pretty bleh class to handle option stuffs
# I should rewrite options as a whole later since I'm not really happy
# with this current system as it's too clunky and hard to understand tbh
class_name GameOption extends Resource

@export var option:String
@export var reference:String
@export var description:String

var value:Variant:
	get: return Settings.get_setting(reference)
	set(v): Settings.set_setting(reference, v)

@export var num_min:float = 0.0
@export var num_max:float = 1.0
@export var num_factor:float =  0.0
@export var display_mode:String = "%.1f"
@export var choices:Array[String] = []
