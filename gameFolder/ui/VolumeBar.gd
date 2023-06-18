extends CanvasLayer

@onready var beep:AudioStreamPlayer = $Scroll

func _ready():
	$ProgressBar.modulate.a = 0.0

var tween:Tween
func show_the_thing():
	$ProgressBar.value = Settings.get_setting("volume")
	$ProgressBar.modulate.a = 1.0
	if not tween == null:
		tween.stop()
	
	tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property($ProgressBar, "modulate:a", 0.0, 0.35).set_delay(0.85)

func _input(_event:InputEvent):
	if Input.is_action_just_pressed("volume_up") or Input.is_action_just_pressed("volume_down"):
		var is_up:bool = Input.is_action_just_pressed("volume_up")
		var value:float = 0.1 if is_up else -0.1
		
		Settings.set_setting("volume", clampf(Settings.get_setting("volume") + value, 0.0, 1.0))
		AudioServer.set_bus_volume_db(0, linear_to_db(Settings.get_setting("volume")))
		show_the_thing()
		beep.play(0.0)
		
		#Settings.save_settings()
