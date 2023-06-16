## #This is an Example Script to get you started with Funkin' Feather's scripts
## #Keep in mind to always extend "PlumaScript" as this is a script that affects only Gameplay
extends PlumaScript

func _ready(): pass
func _post_ready(): pass

func _process(delta:float): pass
func _post_process(delta:float): pass

func begin_countdown(): pass
func on_countdown(tick:int): pass

func on_beat(beat:int): pass
func on_step(step:int): pass
func on_bar(bar:int): pass

func note_spawn(note:Note): pass
func note_hit(note:Note): pass
func cpu_note_hit(note:Note, strum_line:StrumLine): pass

func note_miss(note:Note): pass
func ghost_miss(direction:int): pass
