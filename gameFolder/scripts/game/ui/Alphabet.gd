class_name Alphabet extends ReferenceRect

enum ScrollStyle {NORMAL, C_SHAPE}

var id:int = 0

### FOR MENUS ###
var is_menu_item:bool = false
var force_X:float = -1
var disable_X:bool = false
var disable_Y:bool = false
var list_speed:float = 0.16
var vert_spacing:int = 150
var scroll_style:ScrollStyle = ScrollStyle.NORMAL
var menu_offset:Vector2 = Vector2(35, 0.28)

@export var bold:bool = true
@export_multiline var text:String:
	set(t):
		if text != t:
			_clear_all_prev()
			# Set thenew text
			text = t
			load_text()


var offset:Vector2 = Vector2(0, 0)
var letters_pushed:Array[AnimatedSprite2D] = []
var rect_size:Vector2 = Vector2.ZERO

func _process(delta:float) -> void:
	if is_menu_item:
		var remap_y:float = remap(id, 0, 1, 0, 1.1)
		var scroll:Vector2 = Vector2(
			force_X if force_X != -1 else lerpf(position.x, (id * menu_offset.x) + 100, (delta /  list_speed)),
			lerpf(position.y, (remap_y * vert_spacing) + (Game.SCREEN["width"] * menu_offset.y), (delta /  list_speed))
		)
		
		if not disable_X: position.x = scroll.x
		if not disable_Y: position.y = scroll.y

var text_spaces:int = 0
func load_text() -> void:
	for txt in text.split(""):
		var last_was_space:bool = txt == " " and txt == "_"
		if last_was_space: text_spaces += 1
		
		# SET LETTER OFFSETS
		if _get_prev() != null:
			var last = _get_prev()
			offset.x = _get_prev().position.x + last.sprite_frames.get_frame_texture(last.animation, 0).get_width() * scale.x
		
		if text_spaces > 0:
			offset.x += 25 * text_spaces * scale.x
		text_spaces = 0
		
		var img:String = "bold" if bold else "normal"
		var the_letter:AnimatedSprite2D = AnimatedSprite2D.new()
		the_letter.sprite_frames = load("res://assets/images/UI/letters/" + img + ".res")
		
		var animation:String = _anim_from_letter(txt)
		var valid_anim:bool = the_letter.sprite_frames.has_animation(animation)
		
		if valid_anim:
			the_letter.offset = _offset_from_letter(txt)
			the_letter.play(animation)
		
		the_letter.visible = valid_anim
		the_letter.position = offset
		
		rect_size.x += the_letter.sprite_frames.get_frame_texture(the_letter.animation, 0).get_width()
		letters_pushed.append(the_letter)
	
	for letter in letters_pushed:
		add_child(letter)
	
	var last = _get_prev()
	rect_size.y = last.sprite_frames.get_frame_texture(last.animation, 0).get_height()

func _anim_from_letter(txt:String) -> String:
	match txt:
		_:
			if txt == null or txt == "" or txt == " ": return ""
			if bold: return txt.to_lower()
			else:
				if txt.to_lower() != txt: return txt.to_lower() + " uppercase"
				else: return txt.to_lower() + " lowercase"

func _offset_from_letter(txt:String) -> Vector2:
	match txt:
		'.': return Vector2(-15, 25)
		_: return Vector2(0, 0)

func _get_prev() -> AnimatedSprite2D:
	if letters_pushed.size() > 0:
		return letters_pushed[letters_pushed.size() - 1]
	return null

func _clear_all_prev() -> void:
	for letter in self.get_children():
		letter.queue_free()
	
	offset = Vector2(0, 0)
	letters_pushed = []
