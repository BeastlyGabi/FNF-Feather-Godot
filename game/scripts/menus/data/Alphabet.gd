class_name Alphabet extends ReferenceRect

var width:float = 0.0
var height:float = 0.0

var chars:Dictionary = {
	"letters": "abcdefghijklmnopqrstuvwxyz",
	"numbers": "0123456789",
	"symbols": "!@#$%&*()[]{}'`´~^.,;:/|\\?<>+-_=<>"
}

@export_category("Style")
@export var bold:bool = false
@export var letter_size:float = 1.0
@export var letter_color:Color = Color8(255, 255, 255)

@export_multiline var text:String:
	set(new_text):
		if not text == new_text:
			text = new_text.replace("\\n", "\n")
			_on_change_text()

var menu_item:bool = false
var list_speed:float = 0.16
var vertical_spacing:int = 150
var id_off:Vector2 = Vector2(35, 0.28)
var force_X:float = -1
var disable_X:bool = false
var disable_Y:bool = false

var id:int = 0
var last_letters:Array[AnimatedSprite2D] = []

# func _init(_text:String, _bold:bool, x:float, y:float, _scale:float = 1):
#	# super._init()
#	position = Vector2(x, y)
#	scale = Vector2(_scale, _scale)
#	bold = _bold
#	text = _text

func _process(delta:float):
	if menu_item:
		var lerp_speed:float = list_speed
		var remap_y:float = remap(id, 0, 1, 0, 1.1)
		var scroll:Vector2 = Vector2(
			force_X if force_X != -1 else lerpf(position.x, (id * id_off.x) + 100, (delta / lerp_speed)),
			lerpf(position.y, (remap_y * vertical_spacing) + (Game.SCREEN["width"] * id_off.y), (delta / lerp_speed))
		)
		
		if !disable_X: position.x = scroll.x
		if !disable_Y: position.y = scroll.y

var offset_x:float = 0.0
var offset_y:float = 0.0
var text_spaces:int = 0
var line_breaks:int = 0

func set_text():
	var _width:float = 0.0
	
	for txt in text.split(""):
		var last_was_space:bool = txt == " " and txt == "_"
		if last_was_space: text_spaces += 1
		
		if txt == "\n":
			offset_x = -100
			text_spaces = 0
			line_breaks += 1
			offset_y = 60 * line_breaks
			#return
		
		elif not get_last_letter() == null:
			var last = get_last_letter()
			offset_x = get_last_letter().position.x + last.sprite_frames.get_frame_texture(last.animation, 0).get_width() * letter_size
		
		if text_spaces > 0:
			offset_x += 25 * text_spaces * letter_size
		text_spaces = 0
		
		var img:String = "normal"
		if bold: img = "bold"
		
		var let:AnimatedSprite2D = AnimatedSprite2D.new()
		let.sprite_frames = load("res://assets/images/ui/letters/" + img + ".res")
		let.position = Vector2(offset_x, offset_y)
		let.apply_scale(Vector2(letter_size, letter_size))
		let.modulate = letter_color
		
		if not txt == null and not txt == "" and not txt == " " and not txt == "\n":
			var letter_anim:String = get_letter_anim(txt)
			if not letter_anim == null:
				let.offset = get_letter_offset(txt)
				let.play(letter_anim)
			else:
				let.visible = false
		else:
			let.visible = false
		
		_width += let.sprite_frames.get_frame_texture(let.animation, 0).get_width()
		add_child(let)
		last_letters.append(let)
		
		text_spaces = 0
		offset_x = 0
	
	width = _width
	
	var last = get_last_letter()
	height = last.sprite_frames.get_frame_texture(last.animation, 0).get_width()

func get_letter_anim(txt:String):
	match txt:
		"-": return "dash"
		"!": return "exclamation"
		">": return "greater"
		"<": return "less"
		"\"": return "left double quotes"
		".": return "period"
		",": return "comma"
		"+": return "plus"
		"?": return "question"
		"'": return "single quotes"
		"*": return "star"
		"=": return "equals"
		"|": return "pipe"
		_:
			if txt == null or txt == "" or txt == " ": return null
			if bold: return txt.to_upper()
			else:
				if txt.to_lower() != txt: return txt.to_upper() + " upper"
				else: return txt.to_upper() + " lower"

func get_letter_offset(txt:String):
	match txt:
		'.': return Vector2(-15, 25)
		_: return Vector2(0, 0)

func get_last_letter():
	if last_letters.size() > 0:
		return last_letters[last_letters.size() - 1]
	return null

func screen_center(axis:String):
	match axis.to_upper():
		"X": position.x = (0.5 * Game.SCREEN["width"]) - (width / 2.0)
		"Y": position.y = (0.5 * Game.SCREEN["height"]) - (height / 2.0)
		"XY": position = Vector2(
			(0.5 * Game.SCREEN["width"]) - (width / 2.0),
			(0.5 * Game.SCREEN["height"]) - (height / 2.0)
		)

func _on_change_text():
	while last_letters.size() -1 > 0:
		last_letters[0].queue_free()
		last_letters.erase(last_letters[0])
		remove_child(last_letters[0])
	last_letters = []
	offset_x = 0
	offset_y = 0
	set_text()
