class_name VelocitySprite2D extends Sprite2D

var width:float:
	get: return texture.get_width()
var height:float:
	get: return texture.get_height()

var img_width:float:
	get: return texture.get_image().get_width()
var img_height:float:
	get: return texture.get_image().get_height()

var moves:bool = false

var velocity:Vector2 = Vector2.ZERO:
	set(v):
		var does_move:bool = v.x != 0 or v.y != 0
		moves = does_move; velocity = v

var acceleration:Vector2 = Vector2.ZERO:
	set(v):
		var does_move:bool = v.x != 0 or v.y != 0
		moves = does_move; acceleration = v

func _process(delta:float) -> void:
	if moves: _process_motion(delta / 2.0)

# Velocity and Acceleration Functions
# This implementation relies a lot on code from HaxeFlixel
# I ain't got a math degree so that's the best I can do
# @BeastlyGabi
func _process_motion(delta:float) -> void:
	var computed_velocity:Vector2 = Vector2(
		0.5 * _compute_velocity(velocity.x, acceleration.x, delta) - velocity.x,
		0.5 * _compute_velocity(velocity.y, acceleration.y, delta) - velocity.y,
	)
	
	# set new velocity
	velocity += Vector2(computed_velocity.x * 2.0, computed_velocity.y * 2.0)
	
	# set up new position
	position += Vector2(
		velocity.x + computed_velocity.x * delta,
		velocity.y + computed_velocity.y * delta
	)

func _compute_velocity(vel:float, accel:float, delta:float) -> float:
	return vel + (accel * delta if not accel == 0.0 else 0.0)
