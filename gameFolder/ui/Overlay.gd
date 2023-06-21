extends CanvasLayer

var delta_timeout:float = 0.0
var process_every_frame:bool = false

func _ready() -> void:
	do_text_update()

func _process(delta:float) -> void:
	if !process_every_frame:
		delta_timeout += delta * 1000.0
		if delta_timeout < 1000.0: return
	
	do_text_update()
	
	$FPS_Count.modulate = Color.RED if Engine.get_frames_per_second() < Engine.max_fps / 2.0 else Color.WHITE
	$FPS_Label.position.x = $FPS_Count.size.x / 2.0
	$ColorRect.size.x = $RAM_Label.size.x
		
	# Reset Timeout
	delta_timeout = 0.0

var vram:float:
	get: return Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)

func do_text_update() -> void:
	$FPS_Count.text = str(Engine.get_frames_per_second())
	if OS.is_debug_build():
		$RAM_Label.text = String.humanize_size(OS.get_static_memory_usage()) + " RAM"
		$RAM_Label.text += "\n" + String.humanize_size(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)) + " VRAM"
