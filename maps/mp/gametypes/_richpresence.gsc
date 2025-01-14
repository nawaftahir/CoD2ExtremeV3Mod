init()
{
	level thread updateRichPresence();
}

updateRichPresence()
{
	for(;;)
	{
		players = getEntArray("player", "classname");
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(isDefined(player))
			{
				player updateScores();
				wait .05;
			}
		}
		
		wait 60;
	}
}
