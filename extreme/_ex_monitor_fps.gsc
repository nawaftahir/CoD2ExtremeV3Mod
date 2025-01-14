
prep()
{
	// sv_fps: default "20", domain is any integer from 10 to 1000
	level.ex_fps = 20;

	if(getCvar("sv_fps") != "") level.ex_fps = getCvarInt("sv_fps");
		else setCvar("sv_fps", level.ex_fps);

	setMultiplier();
}

init()
{
	[[level.ex_registerLevelEvent]]("onRandom", ::onRandom, true, 5);
}

onRandom(eventID)
{
	new_fps = getCvarInt("sv_fps");
	if(new_fps != level.ex_fps)
	{
		level.ex_fps = new_fps;
		setMultiplier();

		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(isPlayer(player) && player.sessionstate == "playing") player setClientCvar("snaps", level.ex_snaps);
		}
	}

	[[level.ex_enableLevelEvent]]("onRandom", eventID);
}

setMultiplier()
{
	level.ex_fps_multiplier = level.ex_fps / 20;
	level.ex_fps_frame = 1 / level.ex_fps;

	// snaps: default "20", domain is any integer 1 to 30
	level.ex_snaps = level.ex_fps;
	if(level.ex_snaps > 30) level.ex_snaps = 30;
}

funcFpsTime(time)
{
	return(level.ex_fps_multiplier * time);
}
