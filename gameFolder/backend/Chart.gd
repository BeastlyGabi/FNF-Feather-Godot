class_name Chart extends Node

class NoteData extends Resource:
	var time:float = 0.0
	var direction:int = 0
	var lane:int = 0
	var style:String = "default"
	var suffix:String = ""
	var length:float = 0.0

class EventData extends Resource:
	var name:String = ""
	var args:Array[Variant] = []
	var time:float = 0.0
	var delay:float = 0.0

class SongMetaData extends Resource:
	var display_name:String
	var chart_offset:float = 0.0

var notes:Array[NoteData] = []
var events:Array[EventData] = []

var characters:Array[String] = ["bf", "bf", "bf"]

var ui_style:String = "normal"
var stage:String = "stage"

var note_count:int = 0
var speed:float = 1.0
var bpm:float = 100.0

static func load_chart(folder:String = "test", diff:String = "normal") -> Chart:
	var path:String = "res://assets/songs/" + folder + "/" + diff + ".json"
	
	if not ResourceLoader.exists(path):
		if ResourceLoader.exists(path.replace(diff, "normal")):
			path = path.replace(diff, "normal")
		else:
			path = path.replace(diff, folder)
	
	var json = JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text()).song
	
	var chart:Chart = Chart.new()
	chart.name = folder
	chart.speed = json.speed
	chart.bpm = json.bpm
	
	chart.notes = []
	chart.events = []
	
	if "player1" in json: chart.characters[0] = json.player1
	if "player2" in json: chart.characters[1] = json.player2
	if "player3" in json and json.player3 != null:
		chart.characters[2] = json.player3
	
	if "gfVersion" in json and json.gfVersion != null:
		chart.characters[2] = json.gfVersion
	
	if "stage" in json and json.stage != null:
		chart.stage = json.stage
	
	if "uiSkin" in json: chart.ui_style = json.uiSkin
	if "uiStyle" in json: chart.ui_style = json.uiStyle
	if "songStyle" in json: chart.ui_style = json.songStyle
	if "noteStyle" in json: chart.ui_style = json.noteStyle
	if "assetModifier" in json: chart.ui_style = json.assetModifier
	
	var bpm_bar:float = json.bpm
	for bar in json.notes:
		if "changeBPM" in bar and bar.changeBPM and bar.bpm != null:
			bpm_bar = bar.bpm
		
		var sect_len:int = bar.lengthInSteps if "lengthInSteps" in bar else 16
		var bar_time:float = ((60 / bpm_bar) * 1000.0) / 4.0 * sect_len * json.notes.find(bar)
		
		## CAMERA MOVEMENT EVENT
		var cam_thing:EventData = EventData.new()
		cam_thing.name = "Simple Camera Movement"
		cam_thing.time = bar_time
		
		var cam_char:String = "opponent"
		if "mustHitSection" in bar and bar.mustHitSection:
			cam_char = "player"
		
		if "gfSection" in bar and bar.gfSection:
			cam_char = "spectator"
		
		cam_thing.args.append(cam_char)
		chart.events.append(cam_thing)
		##########################
		
		# BPM CHANGE EVENT
		if "changeBPM" in bar and bar.changeBPM and bar.bpm != null:
			var bpm_change:EventData = EventData.new()
			bpm_change.name = "BPM Change"
			bpm_change.time = bar_time
			bpm_change.args.append(bar.bpm)
			chart.events.append(bpm_change)
		############################
		
		# this format is actually so fucking dumb.
		for note in bar.sectionNotes:
			var epic_note:NoteData = NoteData.new()
			epic_note.time = float(note[0])
			epic_note.direction = int(note[1])
			epic_note.length = float(note[2])
			
			var gotta_hit:bool = bar.mustHitSection
			if note[1] > 3: gotta_hit = not bar.mustHitSection
			epic_note.lane = 1 if gotta_hit else 0
			
			if note.size() > 3 and note[3] != null:
				if note[3] is bool: epic_note.suffix = "-alt"
				elif note[3] is String:
					match note[3]:
						_: epic_note.style = note[3]
			else:
				epic_note.style = "default"
			
			chart.notes.append(epic_note)
	
	chart.note_count = chart.notes.size()
	Conductor.bpm = chart.bpm
	Conductor.pull_bpm_changes(chart)
	return chart
