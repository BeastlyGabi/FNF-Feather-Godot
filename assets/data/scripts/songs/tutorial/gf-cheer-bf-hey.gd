extends PlumaScript

func on_beat(beat:int):
	if beat % 16 == 15 and beat > 16 && beat < 48:
		if game.player.anim_player.has_animation("hey"):
			game.player.anim_player.stop()
			game.player.play_anim("hey", true);
		
		if game.opponent.anim_player.has_animation("cheer"):
			game.opponent.anim_player.stop()
			game.opponent.play_anim("cheer", true);
