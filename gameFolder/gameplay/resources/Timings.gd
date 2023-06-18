extends Node

## Here a Script that stores Judgements and Calculats Score and Accuracy ##

var judgements:Array[Judgement] = [
	# Name, Accuracy, Health, Note Splash, Image (Optional
	Judgement.new("sick", 100.0, 100, true, "sick"),
	Judgement.new("good", 75.0, 80, false, "good"),
	Judgement.new("bad", 35.0, 30, false, "bad"),
	Judgement.new("shit", 0.0, -20, false, "shit")
]

var judgements_hit:Dictionary = {}

func reset():
	notes_hit = 0
	accuracy = 0.0
	notes_acc = 0.0
	cur_clear = "?"
	cur_grade = "N/A"
	misses = 0
	combo = 0
	
	judgements_hit.clear()
	for i in judgements.size():
		judgements_hit[judgements[i].name] = 0

var score:int = 0
var misses:int = 0
var health:int = 50
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
	var note_ms:float = absf(value_a - value_b) * Conductor.pitch_scale
	
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
	var score:int = 0
	match judge:
		"sick": score = 350
		"good": score = 100
		"bad": score = 50
		"shit": score = 0
	return score

func health_balance(mult:float) -> float:
	return (mult / 50)

var cur_clear:String = "?"
var cur_grade:String = "N/A"

var grades:Dictionary = {
	"S": 100.0, "A+": 95.0, "A": 90.0, "B": 85.0, "B-": 80.0, "C": 70.0,
	"SX": 69.0, "D+": 68.0, "D": 50.0, "D-": 15.0, "F": 0
}

func update_rank():
	# loop through the rankings map
	var biggest:float = 0.0
	for grade in grades.keys():
		if grades[grade] <= accuracy and grades[grade] >= biggest:
			cur_grade = grade
			biggest = accuracy
	
	cur_clear = ""
	if misses == 0: # Etterna shit
		if judgements_hit["sick"] > 0:
			cur_clear = "SFC"
		if judgements_hit["good"] > 0:
			cur_clear = "GFC"
		if judgements_hit["bad"] > 0 and judgements_hit["shit"] > 0:
			cur_clear = "FC"
	else:
		if misses < 10:
			cur_clear = "SDCB"
