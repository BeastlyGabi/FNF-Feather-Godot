# ONLY REALLY USED FOR FREEPLAY BULLSHIT
class_name AttachedSprite2D extends Sprite2D

@export var spr_tracker:Alphabet
@export var use_spr_tracker_x:bool = true
@export var use_spr_tracker_y:bool = true
@export var tracker_position:Vector2 = Vector2(0, 0)
var sprite_id:int = 0

func _process(_delta:float):
	if not spr_tracker == null:
		
		if use_spr_tracker_x:
			position.x = spr_tracker.position.x + spr_tracker.width + tracker_position.x
		
		if use_spr_tracker_y:
			position.y = spr_tracker.position.y + tracker_position.y
