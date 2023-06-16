extends PlumaScript

func on_beat(beat:int):
	if beat % 8 == 7 and game.player.anim_player.has_animation("hey"):
		game.player.anim_player.stop()
		game.player.play_anim("hey", true)
