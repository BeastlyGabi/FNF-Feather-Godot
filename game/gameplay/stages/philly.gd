extends Stage

@onready var window:Sprite2D = $P_Canvas/P_Layer/City/Win

func _ready():
	window.modulate.a = 0.0

var light_colors:Array[Color] = [
	Color.from_string("#31A2FD", Color.WHITE),
	Color.from_string("#31FD8C", Color.WHITE),
	Color.from_string("#FB33F5", Color.WHITE),
	Color.from_string("#FD4531", Color.WHITE),
	Color.from_string("#FBA633", Color.WHITE),
]
var window_tweener:Tween

func on_beat(beat:int):
	if beat % 4 == 0:
		window.modulate = light_colors[randi_range(0, light_colors.size() - 1)]
		window.modulate.a = 1.0
		
		if not window_tweener == null:
			window_tweener.stop()
		
		window_tweener = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		window_tweener.tween_property(window, "modulate:a", 0.0, 1.0)
		
