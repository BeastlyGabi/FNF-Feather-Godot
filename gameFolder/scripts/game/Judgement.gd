class_name Judgement extends Resource

var name:String = "sick"
var image:String = "sick"

var timing:float = 45.0
var hits:int = 0

var splash:bool = true
var accuracy:float = 100.0

func _init(_name:String, _accuracy:float, _splash:bool = false, _image:String = "") -> void:
	self.name = _name
	self.image = _name if image != null and image.length() > 0 else _name
	self.splash = _splash
	
	self.accuracy = _accuracy
	self.timing = Settings.get("timings")[name]

static func path_to_judge(_image:String, _skin:String = "normal") -> String:
	return "res://assets/images/UI/ratings/" + _skin + "/" + _image + ".png"

static func path_to_combo(_image:String, _skin:String = "normal") -> String:
	return "res://assets/images/UI/combo/" + _skin + "/" + _image + ".png"
