class_name Judgement extends Resource

var name:String = "sick"

var score:int = 300
var health:int = 100
var accuracy:float = 1.0
var timing:float = 22.5

var img:String = name
var note_splash:bool = false

const timings:Dictionary = {
	"feather": {"sick": 25.0, "good": 75.0, "bad": 125.0, "shit": 155.0}, # 15.0 (Sick)
	"funkin": {"sick": 33.33, "good": 91.67, "bad": 133.33, "shit": 166.67}, # 18.35 (Sick)
	"etterna": {"sick": 45.0, "good": 90.0, "bad": 135.0, "shit": 180.0}, # 22.0 (Sick)
	"leather": {"sick": 50.0,  "good": 70.0, "bad": 100.0, "shit": 130.0}, # 35.0 (Sick)
	"freestyle": {"sick": 39.0, "good": 102.0, "bad": 127.0, "shit": 160.0} # 18.0 (Sick)
}

static func get_timing(judgement:String) -> float:
	return timings[Settings.get_setting("timing_preset")][judgement]

static func get_lowest() -> float:
	return timings[Settings.get_setting("timing_preset")]["shit"]

func _init(_name:String = "sick", _score:int = 300, _health:int = 100, _accuracy:float = 1.0, \
	_note_splash:bool = false, _img:String = ""):
	
	self.name = _name
	self.score = _score
	self.health = _health
	self.accuracy = _accuracy
	self.note_splash = _note_splash
	self.img = _img if not img == null and _img.length() > 0 else name
	self.timing = Judgement.get_timing(name)
