class_name Chart extends Node

var notes:Array[NoteData] = []
var events:Array[EventData] = []

var characters:Array[String] = ["bf", "bf", "bf"]

var key_amount:int = 4
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
	
	for section in json.notes:
		var cam_char:String = "opponent"
		var cam_thing:EventData = EventData.new()
		cam_thing.name = "Simple Camera Movement"
		cam_thing.args.resize(1) # making sure it has a single argument
		
		# I gotta take changes into account, god.
		var bpm_condition:bool = "changeBPM" in section and "bpm" in section and section.changeBPM
		var cur_bpm:float = section.bpm if bpm_condition else json.bpm
		
		var sect_len:int = section.lengthInSteps if "lengthInSteps" in section else 16
		cam_thing.time = ((60 / cur_bpm) * 1000.0) / 4.0 * sect_len * json.notes.find(section)
		
		if "mustHitSection" in section and section.mustHitSection:
			cam_char = "player"
		
		if "gfSection" in section and section.gfSection:
			cam_char = "spectator"
		
		cam_thing.args.append(cam_char)
		chart.events.append(cam_thing)
		
		# this format is actually so fucking dumb.
		for note in section.sectionNotes:
			var epic_note:NoteData = NoteData.new()
			epic_note.time = float(note[0])
			epic_note.direction = int(note[1])
			epic_note.length = float(note[2])
			
			var gotta_hit:bool = section.mustHitSection
			if note[1] > 3: gotta_hit = !section.mustHitSection
			epic_note.strum_line = gotta_hit
			
			if note.size() > 3 and note[3] != null:
				if note[3] is bool: epic_note.suffix = "-alt"
				elif note[3] is String:
					match note[3]:
						_: epic_note.style = note[3]
			else:
				epic_note.style = "default"
			
			chart.notes.append(epic_note)
	
	Conductor.bpm = chart.bpm
	return chart
