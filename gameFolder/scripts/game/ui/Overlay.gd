extends CanvasLayer

var delta_timeout:float = 0.0
var process_every_frame:bool = false
var out_of_bounds:bool = false

func tween_in_out(out:bool = false):
	var to_y:int = -100 if out else 0
	
	for i in self.get_children():
		if i.position.y == to_y: break
		
		get_tree().create_tween().set_ease(Tween.EASE_IN if out else Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC) \
		.tween_property(i, "position:y", to_y, 1.35)
	
	out_of_bounds = to_y != 0

func _ready():
	$Version_Label.text = Game.VERSION.ff_version

func _process(delta:float) -> void:
	if not process_every_frame:
		delta_timeout += delta * 1000.0
		if delta_timeout < 1000.0: return
	
	do_text_update()
	position_texts()
	
	$FPS_Count.modulate = Color.RED if Engine.get_frames_per_second() < Engine.max_fps / 2.0 else Color.WHITE
	
	# Reset Timeout
	delta_timeout = 0.0

func position_texts() -> void:
	$Separator.position.x = $FPS_Count.position.x + $FPS_Count.size.x + 3.5
	$RAM_Label.position.x = $Separator.position.x + 5.0

#var vram:float:
#	get: return Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)

func do_text_update() -> void:
	$FPS_Count.text = str(Engine.get_frames_per_second()) + " FPS"
	if OS.is_debug_build():
		$RAM_Label.text = String.humanize_size(OS.get_static_memory_usage()) + " RAM"
		#$RAM_Label.text += "\n" + String.humanize_size(int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))) + " VRAM"

func _input(event:InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F11:
				var is_fullscreen:bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
				var new_mode := DisplayServer.WINDOW_MODE_FULLSCREEN if not is_fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
				DisplayServer.window_set_mode(new_mode)
			KEY_F12: tween_in_out(not out_of_bounds)
