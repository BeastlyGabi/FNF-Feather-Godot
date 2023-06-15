extends CanvasLayer

var _show_ram:bool = false
var _vram_peak:float = 0.0

func _process(_delta:float):
	$Text.text = "FPS: " + str(Engine.get_frames_per_second())
	if _show_ram:
		if OS.is_debug_build():
			$Text.text += "\nRAM: " + Game.humanize_bytes(OS.get_static_memory_usage()) + " / " + \
				Game.humanize_bytes(OS.get_static_memory_peak_usage())
		
		var _vram:float = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
		if _vram > _vram_peak:
			_vram_peak = _vram
		
		$Text.text += "\nVRAM: " + Game.humanize_bytes(_vram) + " / " + \
			Game.humanize_bytes(_vram_peak)

func _input(event:InputEvent):
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_F3: _show_ram = not _show_ram
				KEY_F10: visible = not visible
