class_name FollowerSprite2D extends Sprite2D

var parent:Variant

func _process(_delta:float) -> void:
	if parent != null:
		var size_ref:Vector2 = parent.size
		if parent is Alphabet: size_ref = parent.rect_size
		
		position = Vector2(parent.position.x + size_ref.x + 50, parent.position.y)
