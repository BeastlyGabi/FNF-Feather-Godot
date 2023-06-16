class_name Note extends Node2D

enum NoteActionEvent {STOP, KEEP}

var time:float = 0.0
var direction:int = 0
var strum_line:int = 0
var type:String = "default"
var hold_length:float = 0.0
var speed:float = 1.0

var splash:bool = false
var in_edit:bool = false

var is_hold:bool:
	get: return hold_length > 0.0

var can_be_hit:bool = false
var was_good_hit:bool = false
var was_too_late:bool = false
var can_be_missed:bool = true
var must_press:bool = false

var _sustain_loaded:bool = false

@onready var arrow:AnimatedSprite2D = $Arrow
@onready var hold:Line2D = $Hold
@onready var end:Sprite2D = $End

var note_colors:Array[Color] = [
	Color8(194, 75, 153), # PURPLE
	Color8(0, 255, 255), # BLUE
	Color8(18, 250, 5), # GREEN
	Color8(249, 57, 63), # RED
]

func on_step(step:int): pass
func on_beat(beat:int): pass
func on_sect(sect:int): pass

const EVENT_STOP = NoteActionEvent.STOP
const EVENT_KEEP = NoteActionEvent.KEEP

func on_note_hit(player:bool = false): pass
func on_note_miss(): pass

func set_note(_time:float, _dir:int, _type:String = "default"):
	time = _time
	direction = _dir
	type = _type
	
	return self

func _ready():
	position = Vector2(-INF, INF)
	arrow.play(Game.note_dirs[direction] + " note")
	if is_hold: _load_sustain()
	
	if type == "default":
		var parts:Array = [arrow, hold, end]
		if has_node("Splash"): parts.append(get_node("Splash"))
		
		for node in parts:
			node.material = material.duplicate()
			node.material.set_shader_parameter("color", note_colors[direction])

func _process(delta:float):
	if not in_edit:
		if is_hold and _sustain_loaded:
			var downscroll_multiplier = -1 if Settings.get_setting("downscroll") else 1
			var sustain_scale:float = ((hold_length / 2.5 / Conductor.pitch_scale) * ((speed) / scale.y))
			
			hold.points = [Vector2.ZERO, Vector2(0, sustain_scale)]
			var last_point = hold.points.size()-1
			var end_point:float = (hold.points[last_point].y + ((end.texture.get_height() \
				* end.scale.y) / 2.0)) * downscroll_multiplier
			
			end.position = Vector2(hold.points[last_point].x, end_point + 24.0)
			end.flip_v = downscroll_multiplier < 0
			end.modulate.a = hold.modulate.a
		
		var safe_threshold:float = Judgement.get_lowest() / (1.25 * Conductor.pitch_scale)
		can_be_hit = time > Conductor.position - safe_threshold and time < Conductor.position + safe_threshold
		was_too_late = (time < Conductor.position - safe_threshold and not was_good_hit)

func _load_sustain():
	_sustain_loaded = false
	var sustain_path:String = "res://assets/images/notes/default/"
	
	hold.texture = load(sustain_path + "note hold.png")
	end.texture = load(sustain_path + "note tail.png")
	
	hold.modulate.a = 0.60 if not Settings.get_setting("opaque_sustains") else 1.0
	hold.texture_mode = Line2D.LINE_TEXTURE_TILE
	hold.width = 50.0
	
	hold.visible = true
	end.visible = true
	
	hold.scale.y = -1 if Settings.get_setting("downscroll") else 1
	
	_sustain_loaded = true
