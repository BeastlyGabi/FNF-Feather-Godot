extends CanvasLayer

func _ready() -> void:
	pass

func _process(_delta:float) -> void:
	pass

###############
### SIGNALS ###
###############

func _ghost_tapping_toggle(state:bool) -> void:
	Settings.set_setting("ghost_tapping", state)

func _on_scroll_item_selection(index:int) -> void:
	Settings.set_setting("downscroll", index == 1)

func _on_reset_scene_pressed() -> void:
	get_tree().paused = false
	#Game.reset_scene()
	Game.switch_scene("gameplay/Gameplay")
	queue_free()


func _on_note_splash_selection(index:int) -> void:
	match index:
		0: Settings.set_setting("note_splashes", "sick only")
		1: Settings.set_setting("note_splashes", "always")
		2: Settings.set_setting("note_splashes", "never")
