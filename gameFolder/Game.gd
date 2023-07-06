extends Node2D

var SCREEN:Dictionary = {
	"width": ProjectSettings.get_setting("display/window/size/viewport_width"),
	"height": ProjectSettings.get_setting("display/window/size/viewport_height"),
}

var VERSION:Versioning
var LAST_SCENE:String

func _ready() -> void:
	VERSION = Versioning.new(0, 0, 1)
	LAST_SCENE = get_tree().current_scene.scene_file_path
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	switch_scene("menus/Main", true)

const focus_lost_volume:float = 0.08

func _notification(what):
	match what:
		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			if Settings.get_setting("auto_pause"):
				if get_tree().paused: get_tree().paused = false
			else:
				VolumeBar.set_system_volume(Settings.volume)
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			if Settings.get_setting("auto_pause"):
				if not get_tree().paused: get_tree().paused = true
			else:
				# Tween this maybe?
				VolumeBar.set_system_volume(focus_lost_volume)

const TRANSITIONS:Dictionary = {
	"default": preload("res://gameFolder/backend/transition/LinearVertical.tscn")
}

func switch_scene(next_scene:String, skip_transition:bool = false) -> void:
	if !skip_transition:
		get_tree().paused = true
		add_child(TRANSITIONS["default"].instantiate())
		await(get_tree().create_timer(0.45).timeout)
		get_tree().paused = false
	
	var scene_path:String = "res://gameFolder/" + next_scene + ".tscn"
	get_tree().change_scene_to_file(scene_path)
	LAST_SCENE = scene_path

var CUR_SONG:Chart
var META_DATA:Chart.SongMetaData
@export var weeks:Array[Week] = []

func bind_song(_song_name:String, _diff:String = "hard") -> void:
	CUR_SONG = Chart.load_chart(_song_name, _diff)
	switch_scene("gameplay/Gameplay")

func reset_scene(skip_trans:bool = false) -> void:
	switch_scene(LAST_SCENE, skip_trans)

func float_to_minute(value:float) -> int: return int(value / 60)
func float_to_seconds(value:float) -> float: return fmod(value, 60)
func format_to_time(value:float) -> String: return "%02d:%02d" % [float_to_minute(value), float_to_seconds(value)]

# @voiddev
var last_log:String
func safe_call(node:Node, fn:String, args:Array = []) -> void:
	if node.has_method(fn):
		node.callv(fn, args)
	else:
		var to_print:String = "\"%s\" has no function \"%s\"" %[get_tree().current_scene.name, fn]
		if last_log != to_print:
			print_debug(to_print)
			last_log = to_print

var current_scene:
	get: return get_tree().current_scene

var flicker_timer:SceneTreeTimer
func flicker_object(obj:CanvasItem, duration:float = 0.06, interval:int = 8, end_call = null, end_visibility:bool = false) -> void:
	if obj == null or not obj.is_inside_tree(): return
	
	if interval <= 0:
		if obj != null and obj.is_inside_tree():
			obj.visible = end_visibility
		
		if end_call != null:
			end_call.call()
			flicker_timer = null
		return
	
	if obj != null and obj.is_inside_tree(): obj.visible = false
	
	if flicker_timer == null or interval > 0:
		flicker_timer = get_tree().create_timer(duration)
		flicker_timer.timeout.connect(
			func():
				await get_tree().create_timer(duration).timeout
				interval -= 1
				if obj != null and obj.is_inside_tree():
					flicker_object(obj, duration, interval, end_call)
		)
	
	await flicker_timer.timeout
	if obj != null and obj.is_inside_tree():
		obj.visible = true

func get_screen_center(base:Vector2) -> Vector2:
	return Vector2(
		(Game.SCREEN["width"] - base.x) / 2.0,
		(Game.SCREEN["height"] - base.y) / 2.0
	)

func reset_menu_music(fade_in:bool = false) -> void:
	if Sound.music.stream != null and Sound.music.playing: return
	Sound.play_music("res://assets/sounds/music/freakyMenu.ogg")
	Sound.music.volume_db = linear_to_db(0.7) if not fade_in else -35.0
	if fade_in: Sound.ask_to_fade(0.7, 35.0)
