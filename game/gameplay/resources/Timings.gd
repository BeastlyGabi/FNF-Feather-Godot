class_name Timings extends Node

var game
func _init(_game):
	game = _game

const timings:Dictionary = {
	"feather": {"sick": 25.0, "good": 75.0, "bad": 125.0, "shit": 155.0}, # 15.0 (Sick)
	"funkin": {"sick": 33.33, "good": 91.67, "bad": 133.33, "shit": 166.67}, # 18.35 (Sick)
	"etterna": {"sick": 45.0, "good": 90.0, "bad": 135.0, "shit": 180.0}, # 22.0 (Sick)
	"leather": {"sick": 50.0,  "good": 70.0, "bad": 100.0, "shit": 130.0}, # 35.0 (Sick)
	"freestyle": {"sick": 39.0, "good": 102.0, "bad": 127.0, "shit": 160.0} # 18.0 (Sick)
}

var cur_rank:String = "N/A"
var cur_clear:String = ""

var rankings:Dictionary = {
	"S": 100.0, "A+": 95.0, "A": 90.0, "B": 85.0, "B-": 80.0, "C": 70.0,
	"SX": 69.0, "D+": 68.0, "D": 50.0, "D-": 15.0, "F": 0
}

var judgements_hit:Dictionary = {}

var misses:int:
	get: return game.misses

var notes_accuracy:float = 0.00
var total_notes_hit:int = 0
var accuracy:float = 0.00:
	get:
		if notes_accuracy <= 0.00: return 0.00
		return (notes_accuracy / (total_notes_hit + misses))

func update_accuracy(judgement:Judgement):
	total_notes_hit += 1
	notes_accuracy += maxf(0, judgement.accuracy)
	judgements_hit[judgement.name] += 1
	
func update_rank():
	# loop through the rankings map
	var biggest:float = 0.0
	for rank in rankings.keys():
		if rankings[rank] <= accuracy and rankings[rank] >= biggest:
			cur_rank = rank
			biggest = accuracy
	
	cur_clear = ""
	if misses == 0: # Etterna shit
		if judgements_hit["sick"] > 0:
			cur_clear = "MFC"
			
		if judgements_hit["good"] > 0:
			if judgements_hit["good"] >= 10:
				cur_clear = "GFC"
			else:
				cur_clear = "SDG"
			
		if judgements_hit["bad"] > 0:
			if judgements_hit["bad"] >= 10:
				cur_clear = "FC"
			else:
				cur_clear = "SDB"
	else:
		if misses < 10:
			cur_clear = "SDCB"
