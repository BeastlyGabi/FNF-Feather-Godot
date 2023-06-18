class_name Note extends Node2D

var time:float = 0.0
var direction:int = 0
var type:String = "default"
var strum_line:int = 0

var speed:float = 1.0
var length:float = 0.0
var is_hold:bool:
	get: return length > 0.0

var in_edit:bool = false

var too_late:bool = false
var can_be_hit:bool = false
var was_good_hit:bool = false

var must_press:bool:
	get: return strum_line == 1

@onready var arrow:Sprite2D = $Arrow
@onready var hold:Line2D = $Hold
@onready var end:Sprite2D = $End

var _sustain_loaded:bool = false
var copy_rotation:bool = true

const default_colors:Dictionary = {
	"normal": [
		Color8(194, 75, 153), # PURPLE
		Color8(0, 255, 255), # BLUE
		Color8(18, 250, 5), # GREEN
		Color8(249, 57, 63), # RED
	],
	"pixel": [
		Color8(194, 75, 153), # PURPLE
		Color8(0, 255, 255), # BLUE
		Color8(18, 250, 5), # GREEN
		Color8(249, 57, 63), # RED
	]
}

func _ready() -> void:
	if is_hold: _load_sustain()
	
	if type == "default":
		var parts:Array = [arrow, hold, end]
		if has_node("Splash"): parts.append(get_node("Splash"))
		
		for node in parts:
			node.material = material.duplicate()
			node.material.set_shader_parameter("color", default_colors["normal"][direction])

func _process(_delta:float) -> void:
	if is_hold and _sustain_loaded:
		var downscroll_multiplier:int = -1 if Settings.get_setting("downscroll") and not in_edit else 1
		var sustain_scale:float = ((length / 2.5 / Conductor.pitch_scale) * ((speed) / scale.y))
		
		hold.points = [Vector2.ZERO, Vector2(0, sustain_scale)]
		var last_point = hold.points.size() - 1
		var end_point:float = (hold.points[last_point].y + ((end.texture.get_height() \
			* end.scale.y) / 2.0)) * downscroll_multiplier
		
		end.position = Vector2(hold.points[last_point].x, end_point - 5.0)
		end.flip_v = downscroll_multiplier < 0
		end.modulate.a = hold.modulate.a
	
	if !in_edit:
		var hit_area:float = Timings.worst_timing() / (1.25 * Conductor.pitch_scale)
		can_be_hit = time > Conductor.position - hit_area and time < Conductor.position + hit_area
		too_late = (time < Conductor.position - hit_area and not was_good_hit)

func _load_sustain() -> void:
	_sustain_loaded = false
	var sustain_path:String = "res://assets/images/notetypes/default/"
	
	hold.texture = load(sustain_path + "note hold.png")
	end.texture = load(sustain_path + "note tail.png")
	
	hold.modulate.a = 0.60
	hold.texture_mode = Line2D.LINE_TEXTURE_TILE
	hold.width = 50.0
	
	hold.visible = true
	end.visible = true
	
	hold.scale.y = -1 if Settings.get_setting("downscroll") and not in_edit else 1
	
	_sustain_loaded = true
