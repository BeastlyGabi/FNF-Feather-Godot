class_name Stage extends Node2D

@export_category("Camera")
@export var camera_speed:float = 1.0
@export var camera_zoom:float = 1.05
@export var hud_zoom:float = 1.0

@export_category("Positioning")
@export var player_position:Vector2 = Vector2(800, 400)
@export var opponent_position:Vector2 = Vector2(100, 400)
@export var spectator_position:Vector2 = Vector2(300, 100)

@export_category("Offsets")
@export var player_camera:Vector2 = Vector2.ZERO
@export var opponent_camera:Vector2 = Vector2.ZERO
@export var spectator_camera:Vector2 = Vector2.ZERO
