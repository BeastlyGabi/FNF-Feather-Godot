extends Node

## Here a Script that stores Judgements and Calculats Score and Accuracy ##

var judgements:Array[Judgement] = [
	# Name, Accuracy, Note Splash, Image (Optional)
	Judgement.new("sick", 100.0, true, "sick"),
	Judgement.new("good", 75.0, false, "good"),
	Judgement.new("bad", 35.0, false, "bad"),
	Judgement.new("shit", 0.0, false, "shit")
]

var judgements_hit:Dictionary = {}

func reset():
	notes_hit = 0
	health = 1.0
	accuracy = 0.0
	notes_acc = 0.0
	cur_clear = "?"
	cur_grade = Grade.empty()
	misses = 0
	combo = 0
	
	judgements_hit.clear()
	for i in judgements.size():
		judgements_hit[judgements[i].name] = 0

var score:int = 0
var misses:int = 0
var health:float = 1.0
var combo:int = 0

var notes_acc:float = 0.0
var notes_hit:int = 0

var accuracy:float:
	get:
		if notes_acc > 0.0:
			return (notes_acc / (notes_hit + misses))
		return 0.0

func worst_timing() -> float:
	return Settings.timings["shit"]

func judge_values(value_a:float, value_b:float) -> Judgement:
	var judgement:Judgement = judgements[3]
	var note_ms:float = absf(value_a - value_b)
	
	for i in judgements.size():
		if note_ms > judgements[i].timing:
			continue
		else:
			judgement = judgements[i]
			break
	
	return judgement

func update_accuracy(judge:Judgement) -> void:
	notes_hit += 1
	notes_acc += maxf(0, judge.accuracy)
	judgements_hit[judge.name] += 1
	update_rank()

func score_from_judge(judge:String) -> int:
	var _score:int = 0
	match judge:
		"sick": _score = 350
		"good": _score = 100
		"bad": _score = 50
		"shit": _score = 0
	return _score

class Grade extends Resource:
	var name:String = "S"
	var accuracy:float = 100.0
	var color:Color = Color.CYAN
	
	func _init(_name:String = "N/A", _acc:float = -1.0, _color:Color = Color.WHITE) -> void:
		name = _name
		accuracy = _acc
		color = _color
	
	static func empty() -> Grade:
		return Grade.new("N/A")

var cur_clear:String = "?"
var cur_grade:Grade = Grade.empty()

var grades:Array[Grade] = [
	Grade.new("S", 100.0, Color.CYAN), Grade.new("A+", 95.0, Color.GREEN_YELLOW), Grade.new("A", 90.0, Color.GREEN), Grade.new("B", 85.0, Color.YELLOW),
	Grade.new("B-", 80.0, Color.LIGHT_SKY_BLUE), Grade.new("C", 70.0, Color.FIREBRICK), Grade.new("SX", 69.0, Color.VIOLET), Grade.new("D+", 68.0, Color.LAVENDER),
	Grade.new("D", 50.0, Color.SLATE_GRAY), Grade.new("D-", 15.0, Color.RED), Grade.new("F", 0, Color.GHOST_WHITE)
]

func update_rank():
	# loop through the rankings map
	for grade in grades:
		if grade.accuracy <= accuracy:
			cur_grade = grade
			break
	
	cur_clear = ""
	if misses == 0: # Etterna shit
		if judgements_hit["sick"] > 0: cur_clear = "SFC"
		if judgements_hit["good"] > 0: cur_clear = "GFC"
		if judgements_hit["bad"] > 0 or judgements_hit["shit"] > 0:
			cur_clear = "FC"
	else:
		if misses < 10: cur_clear = "SDCB"
