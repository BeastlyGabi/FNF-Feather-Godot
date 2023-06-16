class_name Judgement extends Resource

var name:String = "sick"

var score:int = 300
var health:int = 100
var accuracy:float = 1.0
var timing:float = 22.5

var img:String = name
var note_splash:bool = false

static func get_timing(judgement:String) -> float:
	return Timings.timings[Settings.get_setting("timing_preset")][judgement]

static func get_lowest() -> float:
	return Timings.timings[Settings.get_setting("timing_preset")]["shit"]

func _init(_name:String = "sick", _score:int = 300, _health:int = 100, _accuracy:float = 1.0, \
	_note_splash:bool = false, _img:String = ""):
	
	self.name = _name
	self.score = _score
	self.health = _health
	self.accuracy = _accuracy
	self.note_splash = _note_splash
	self.img = _img if not img == null and _img.length() > 0 else name
	self.timing = Judgement.get_timing(name)
