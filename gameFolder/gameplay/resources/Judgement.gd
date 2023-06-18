class_name Judgement extends Resource

var name:String = "sick"
var image:String = "sick"

var timing:float = 45.0

var splash:bool = true
var accuracy:float = 100.0
var health:int = 100

func _init(_name:String, _accuracy:float, _health:int, _splash:bool = false, _image:String = "") -> void:
	self.name = _name
	self.image = _name if image != null and image.length() > 0 else _name
	self.splash = _splash
	
	self.accuracy = _accuracy
	self.timing = Settings.timings[name]
	self.health = _health

static func path_to_judge(image:String, skin:String = "normal") -> String:
	return "res://assets/images/UI/ratings/" + skin + "/" + image + ".png"

static func path_to_combo(image:String, skin:String = "normal") -> String:
	return "res://assets/images/UI/combo/" + skin + "/" + image + ".png"
