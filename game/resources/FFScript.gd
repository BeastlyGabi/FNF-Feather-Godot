class_name FFScript extends Node

var game:Gameplay
static func load_script(path:String, game:Gameplay):
	var new_script:FFScript = load(path).new()
	new_script.game = game
	return new_script

## #When Gameplay is ready to start
func _ready(): pass

## #After everything is set up on gameplay (inst, characters, etc)
func _post_ready(): pass

## Function that runs every frame, happens while managing the song position, spawning notes, etc
##
## [delta] the Elapsed time since the last frame.
func _process(delta:float): pass

## Ditto, but after the operations mentioned.
##
## [delta] the Elapsed time since the last frame.
func _post_process(delta:float): pass

## Called when the countdown begins on gameplay
func begin_countdown(): pass

## Called whole the countdown is ticking, use the "tick" variable if needed
##
## [tick] the position of the countdown, goes from 0 to 4 at maximum.
func on_countdown(tick:int): pass

## Called every song beat
##
## [beat] the current Song Beat.
func on_beat(beat:int): pass

## Called every song step
##
## [step] the current Song Step.
func on_step(step:int): pass

## Called every song section
##
## [sect] the current Song Section.
func on_sect(sect:int): pass

## Called whenever a note spawns in and before it gets added to its targeted strumline
##
## [note] the Note that just spawned.
func note_spawn(note:Note): pass

## Called whenever the player hits a note
##
## [note] the Note that was just hit by the player.
func note_hit(note:Note): pass

## Called whenever a cpu hits a note, this includes your own cpu hits when using autoplay/botplay
##
## [note] the Note that was just hit by the cpu.
## [strum_line] the CPU's StrumLine on gameplay.
func cpu_note_hit(note:Note, strum_line:StrumLine): pass

## Called whenever the player misses a note
##
## [note] the Note that was missed
func note_miss(note:Note): pass

## Called whenever the player taps where no notes are there to be hit
##
## [direction] the Direction value that was passed to this function on gameplay
func ghost_miss(direction:int): pass
