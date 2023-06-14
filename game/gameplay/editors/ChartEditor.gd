extends MusicBeatNode2D

func _ready():
	SoundHelper.stop_music()
	Overlay.visible = false

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		Game.switch_scene("gameplay/Gameplay")

func _exit_tree():
	Overlay.visible = true

###################################
### TOP BAR UI SIGNAL FUNCTIONS ###
###################################

func _on_file_button_pressed(id:int = -1):
	$UI_Layer/Top_Bar/File_Button/Popup.show()
	
	if id > -1:
		match id:
			2: Game.switch_scene("menus/OptionsMenu")

func _on_edit_button_pressed(id:int = -1):
	$UI_Layer/Top_Bar/Edit_Button/Popup.show()

func _on_notes_button_pressed(id:int = -1):
	$UI_Layer/Top_Bar/Notes_Button/Popup.show()

func _on_play_button_pressed(id:int = -1):
	$UI_Layer/Top_Bar/Play_Button/Popup.show()

func _on_help_button_pressed(id:int = -1):
	$UI_Layer/Top_Bar/Help_Button/Popup.show()
