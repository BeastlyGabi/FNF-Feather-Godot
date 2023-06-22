class_name Note extends Node2D

enum NoteEvent {STOP, CONTINUE}

const E_STOP = NoteEvent.STOP
const E_CONTINUE = NoteEvent.CONTINUE

var time:float = 0.0
var direction:int = 0
var style:String = "default"
var strum_line:int = 0

var parent:StrumLine

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

@onready var arrow := $Arrow # assuming the type here since you can have AnimatedSprite2D as an arrow
@onready var hold:Line2D = $Hold
@onready var end:Sprite2D = $End

var _did_miss:bool = false
var _sustain_loaded:bool = false

var copy_opacity:bool = true
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

### for notestyles ###
func on_hit(): pass
func on_miss(): pass
####################################

func _ready() -> void:
	if style == "default":
		for node in _existing_nodes():
			node.material = material.duplicate()
			node.material.set_shader_parameter("color", default_colors["normal"][direction])

func _process(delta:float) -> void:
	if is_hold and _sustain_exists():
		var scroll_diff:int = -1 if Settings.get_setting("downscroll") and not in_edit else 1
		var sustain_scale:float = ((length / 2.5) * ((speed / Conductor.pitch_scale) / scale.y))
		
		hold.points = [Vector2.ZERO, Vector2(0, sustain_scale)]
		var last_point = hold.points.size() - 1
		var end_point:float = (hold.points[last_point].y + ((end.texture.get_height() \
			* end.scale.y) / 2.0)) * scroll_diff
		
		end.position = Vector2(hold.points[last_point].x, end_point)
		end.flip_v = scroll_diff < 0
		end.modulate.a = hold.modulate.a
		
		if was_good_hit:
			length -= (delta * 1000.0 * Conductor.pitch_scale)
			if length <= -(Conductor.step_crochet / 1000.0):
				queue_free()
	
	if !in_edit:
		var hit_area:float = (Timings.worst_timing() / (1.2 * Conductor.pitch_scale))
		can_be_hit = time > Conductor.position - hit_area and time < Conductor.position + hit_area
		too_late = (time < Conductor.position - hit_area and not was_good_hit)

func _sustain_exists() -> bool:
	var has_sustain:bool = has_node("Hold") and has_node("End")
	if has_sustain:
		get_node("Hold").visible = true
		get_node("End").visible = true
		get_node("Hold").scale.y = -1 if Settings.get_setting("downscroll") and not in_edit else 1
	
	return has_sustain

func _existing_nodes() -> Array:
	var parts:Array = [arrow]
	if _sustain_exists(): parts.append_array([hold, end])
	if has_node("Splash"): parts.append(get_node("Splash"))
	return parts
