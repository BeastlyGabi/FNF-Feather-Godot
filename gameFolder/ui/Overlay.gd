extends CanvasLayer

var label_separator:String = " / "
func _process(_delta:float) -> void:
	$Label.text = "FPS: " + str(Engine.get_frames_per_second())
	$Label.text += label_separator + "RAM: " + String.humanize_size(OS.get_static_memory_usage())
	$Label.text += label_separator + "VRAM: " + String.humanize_size(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))
