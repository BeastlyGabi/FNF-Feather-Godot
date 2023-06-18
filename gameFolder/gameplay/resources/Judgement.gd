class_name Judgement extends Resource

var name:String = "sick"
var image:String = "sick"

var timing:float = 45.0

var splash:bool = true
var accuracy:float = 100.0

func _init(_name:String, _accuracy:float, _splash:bool = false, _image:String = "") -> void:
	self.name = _name
	self.image = _name if image != null and image.length() > 0 else _name
	self.splash = _splash
	
	self.accuracy = _accuracy
	self.timing = Settings.timings[name]

static func path_to_judge(image:String, skin:String = "normal") -> String:
	return "res://assets/images/UI/ratings/" + skin + "/" + image + ".png"

static func path_to_combo(image:String, skin:String = "normal") -> String:
	return "res://assets/images/UI/combo/" + skin + "/" + image + ".png"
