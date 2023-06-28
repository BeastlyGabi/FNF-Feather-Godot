extends CanvasLayer

@onready var rect:Sprite2D = $Rectangle

func _ready() -> void:
	if !is_inside_tree():
		return
	
	create_tween().set_ease(Tween.EASE_IN_OUT) \
	.tween_property(rect, "position:y", 2000.0, 0.80) \
	.finished.connect(queue_free)
