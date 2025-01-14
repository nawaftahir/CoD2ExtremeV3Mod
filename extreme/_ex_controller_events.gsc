
eventInit()
{
	if(level.ex_log_events) logprint("EVT: Initializing events controller\n");

	// initialize level based waittill events handler
	level.callbacks = [];

	// start level based waittill events handler
	level thread onPlayerConnecting();
	level thread onPlayerConnected();
	level thread onRoundOver();
	level thread onGameOver();

	// initialize level based timed events handler
	level.eventcatalog = [];
	level.events = [];

	// start level based timed events handler
	level thread onLevelFrame();
	level thread onLevelSecond();
}

/*------------------------------------------------------------------------------
LEVEL WAITTILL EVENTS
	"onPlayerConnecting" (handled by onPlayerConnecting, started by init)
	"onPlayerConnected" (handled by onPlayerConnected, started by init)
	"onRoundOver" (handled by onRoundOver, started by init)
	"onGameOver" (handled by onGameOver, started by init)

PLAYER WAITTILL EVENTS
	"onJoinedTeam" (handled by onJoinedTeam, started by onPlayerConnected)
	"onJoinedSpectators" (handled by onJoinedSpectators, started by onPlayerConnected)
	"onPlayerSpawn" (handled by onPlayerSpawn, started by onPlayerConnected)
	"onPlayerSpawned" (handled by onPlayerSpawned, started by onPlayerConnected)
	"onPlayerKilled" (handled by onPlayerKilled, started by onPlayerConnected)
	"onBinocEnter" (handled by onBinocEnter, started by onPlayerSpawned)
	"onBinocExit" (handled by onBinocExit, started by onPlayerSpawned)
------------------------------------------------------------------------------*/

registerCallback(callback, func)
{
	callback = tolower(callback);
	if(!isDefined(level.callbacks[callback])) level.callbacks[callback] = [];
	if(level.ex_log_events) logprint("EVT: Registered callback \"" + callback + "\" (" + (level.callbacks[callback].size + 1) + ")\n");
	level.callbacks[callback][level.callbacks[callback].size] = func;
}

processCallback(callback)
{
	callback = tolower(callback);
	if(!isDefined(level.callbacks[callback])) return;

	for(i = 0; i < level.callbacks[callback].size; i++)
		thread [[level.callbacks[callback][i]]]();
}

onPlayerConnecting()
{
	for(;;)
	{
		level waittill("connecting", player);

		// process callback
		player thread processCallBack("onPlayerConnecting");
	}
}

onPlayerConnected()
{
	for(;;)
	{
		level waittill("connected", player);

		// make sure we load memory before allowing anything else
		player extreme\_ex_controller_memory::playerInit();

		// process callback
		player thread processCallBack("onPlayerConnected");

		// start player based waittill events handlers (pre-spawn)
		player thread onJoinedTeam();
		player thread onJoinedSpectators();
		player thread onPlayerSpawn();
		player thread onPlayerSpawned();
		player thread onPlayerKilled();

		// the following notification will notify Callback_PlayerConnect() that the
		// event controller finished handling the "connected" notification. Only
		// then the player is allowed to proceed into the server info screen, or
		// spawn directly into the map after a map_restart. Absolutely necessary for
		// the latter, because the event controller was still handling the "connected"
		// notification, and would miss the "spawned" notifications
		if(level.ex_log_events) logprint("EVT: Player threads initialized. Sending \"events_initialized\" notification to player " + player.name + "\n");
		player notify("events_initialized");
	}
}

onRoundOver()
{
	for(;;)
	{
		level waittill("round_ended");

		level.ex_roundover = true;
		level notify("ex_roundover");

		// process callback
		level thread processCallBack("onRoundOver");
	}
}

onGameOver()
{
	for(;;)
	{
		level waittill("game_ended");

		level.ex_gameover = true;
		level notify("ex_gameover");

		// process callback
		level thread processCallBack("onGameOver");
	}
}

onJoinedTeam()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("joined_team");

		// process callback
		self thread processCallBack("onJoinedTeam");
	}
}

onJoinedSpectators()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("joined_spectators");

		// process callback
		self thread processCallBack("onJoinedSpectators");
	}
}

onPlayerSpawn()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("spawned");

		// initialize player based timed events handlers
		self.eventcatalog = [];
		self.events = [];

		// when the game is over, trigger the onPlayerKilled event handler by
		// sending the proper notification (_ex_player_spawn::spawnSpectator will send
		// the "spawned" notification that will trigger this event)
		if(game["state"] != "intermission")
		{
			if(level.ex_gameover)
			{
				self notify("kill_thread");
				self notify("killed_player");
			}
			// process callback
			else self thread processCallBack("onPlayerSpawn");
		}
	}
}

onPlayerSpawned()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("spawned_player");

		// start player based waittill events handlers (post-spawn)
		self thread onBinocEnter();
		self thread onBinocExit();

		// start player based timed events handlers
		self thread onPlayerFrame();
		self thread onPlayerTenthSecond();
		self thread onPlayerHalfSecond();
		self thread onPlayerSecond();

		// process callback
		self thread processCallBack("onPlayerSpawned");
	}
}

onPlayerKilled()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("killed_player");

		// process callback
		self thread processCallBack("onPlayerKilled");
	}
}

onBinocEnter()
{
	self endon("kill_thread");

	for(;;)
	{
		self waittill("binocular_enter");

		// process callback
		self thread processCallBack("onBinocEnter");
	}
}

onBinocExit()
{
	self endon("kill_thread");

	for(;;)
	{
		self waittill("binocular_exit");

		// process callback
		self thread processCallBack("onBinocExit");
	}
}

onCallbackDisconnected()
{
	self notify("kill_thread");

	// process callback (no threading! Handle events before we lose the player's entity)
	self processCallBack("onPlayerDisconnected");

	// call original callback
	[[level.ex_callbackPlayerDisconnect]]();
}

/*------------------------------------------------------------------------------
LEVEL TIMED EVENTS
	"onFrame" (handled by onLevelFrame, started by init)
	"onSecond" (handled by onLevelSecond, started by init)
	"onRandom" (handled by onLevelSecond)
------------------------------------------------------------------------------*/

registerLevelEvent(event, func, pause_exec, random_min, random_max, random_init)
{
	event = tolower(event);
	if(!isDefined(level.events[event]))
	{
		level.eventcatalog[level.eventcatalog.size] = event;
		level.events[event] = [];
	}

	index = level.events[event].size;
	if(level.ex_log_events) logprint("EVT: Registered level event \"" + event + "\" (" + (index + 1) + ")\n");
	level.events[event][index] = spawnstruct();
	level.events[event][index].func = func;
	level.events[event][index].delay = 0;
	level.events[event][index].random = false;
	level.events[event][index].random_min = 0;
	level.events[event][index].random_max = 0;
	level.events[event][index].pause_exec = false;
	level.events[event][index].enabled = true;

	if(isDefined(pause_exec)) level.events[event][index].pause_exec = pause_exec;
	if(isDefined(random_min))
	{
		level.events[event][index].random = true;

		if(random_min < 5) random_min = 5;
			else random_min = int(random_min);
		level.events[event][index].random_min = random_min;

		if(isDefined(random_max))
		{
			if(random_max < random_min) random_max = random_min;
				else random_max = int(random_max);
			level.events[event][index].random_max = random_max;
		}
		else
		{
			random_max = random_min;
			level.events[event][index].random_max = random_max;
		}

		if(isDefined(random_init))
		{
			if(random_init < 5) random_init = 5;
				else random_init = int(random_init);
			level.events[event][index].delay = random_init;
		}
	}
}

enableLevelEvent(event, eventID)
{
	event = tolower(event);
	level.events[event][eventid].enabled = true;
}

disableLevelEvent(event, eventID)
{
	event = tolower(event);
	level.events[event][eventid].enabled = false;
}

processLevelEvent(event)
{
	level endon("ex_gameover");

	event = tolower(event);
	if(!isDefined(level.events[event])) return;

	for(i = 0; i < level.events[event].size; i++)
	{
		// skip disabled events
		if(!level.events[event][i].enabled) continue;

		// skip random events
		if(level.events[event][i].random) continue;

		// pause after exec
		if(level.events[event][i].pause_exec) level.events[event][i].enabled = false;

		// exec function (pass i as eventID)
		level thread [[level.events[event][i].func]](i);
	}
}

onLevelFrame()
{
	level endon("ex_gameover");

	while(!level.ex_gameover)
	{
		wait( level.ex_fps_frame );
		processLevelEvent("onFrame");
	}
}

onLevelSecond()
{
	level endon("ex_gameover");

	while(!level.ex_gameover)
	{
		wait( [[level.ex_fpstime]](1) );
		processLevelEvent("onSecond");

		// check and handle random events
		for(i = 0; i < level.eventcatalog.size; i++)
		{
			event = level.eventcatalog[i];
			for(j = 0; j < level.events[event].size; j++)
			{
				// only exec onRandom events here
				if(!level.events[event][j].random) continue;
				if(level.events[event][j].enabled)
				{
					if(level.events[event][j].delay) level.events[event][j].delay--;
					else
					{
						if(level.events[event][j].pause_exec) level.events[event][j].enabled = false;
						if(level.events[event][j].random_min == level.events[event][j].random_max) level.events[event][j].delay = level.events[event][j].random_min;
							else level.events[event][j].delay = level.events[event][j].random_min + randomInt(level.events[event][j].random_max - level.events[event][j].random_min);

						// exec function (pass j as eventID)
						level thread [[level.events[event][j].func]](j);
					}
				}
			}
		}
	}
}

/*------------------------------------------------------------------------------
PLAYER TIMED EVENTS
	"onFrame" (handled by onPlayerFrame, started by onPlayerSpawned)
	"onTenthSecond" (handled by onPlayerTenthSecond, started by onPlayerSpawned)
	"onHalfSecond" (handled by onPlayerHalfSecond, started by onPlayerSpawned)
	"onSecond" (handled by onPlayerSecond, started by onPlayerSpawned)
	"onRandom" (handled by onPlayerSecond)
------------------------------------------------------------------------------*/

registerPlayerEvent(event, func, pause_exec, random_min, random_max, random_init)
{
	event = tolower(event);
	if(!isDefined(self.events[event]))
	{
		self.eventcatalog[self.eventcatalog.size] = event;
		self.events[event] = [];
	}

	index = self.events[event].size;
	if(level.ex_log_events) logprint("EVT: Registered player event \"" + event + "\" (" + (index + 1) + ")\n");
	self.events[event][index] = spawnstruct();
	self.events[event][index].func = func;
	self.events[event][index].delay = 0;
	self.events[event][index].random = false;
	self.events[event][index].random_min = 0;
	self.events[event][index].random_max = 0;
	self.events[event][index].pause_exec = false;
	self.events[event][index].enabled = true;

	if(isDefined(pause_exec)) self.events[event][index].pause_exec = pause_exec;
	if(isDefined(random_min))
	{
		self.events[event][index].random = true;

		if(random_min < 5) random_min = 5;
			else random_min = int(random_min);
		self.events[event][index].random_min = random_min;

		if(isDefined(random_max))
		{
			if(random_max < random_min) random_max = random_min;
				else random_max = int(random_max);
			self.events[event][index].random_max = random_max;
		}
		else
		{
			random_max = random_min;
			self.events[event][index].random_max = random_max;
		}

		if(isDefined(random_init))
		{
			if(random_init < 5) random_init = 5;
				else random_init = int(random_init);
			self.events[event][index].delay = random_init;
		}
	}
}

enablePlayerEvent(event, eventID)
{
	event = tolower(event);
	self.events[event][eventid].enabled = true;
}

disablePlayerEvent(event, eventID)
{
	event = tolower(event);
	self.events[event][eventid].enabled = false;
}

processPlayerEvent(event)
{
	self endon("kill_thread");

	event = tolower(event);
	if(!isDefined(self.events[event])) return;

	for(i = 0; i < self.events[event].size; i++)
	{
		// skip disabled events
		if(!self.events[event][i].enabled) continue;

		// skip random events
		if(self.events[event][i].random) continue;

		// pause after exec
		if(self.events[event][i].pause_exec) self.events[event][i].enabled = false;

		// exec function (pass i as eventID)
		self thread [[self.events[event][i].func]](i);
	}
}

onPlayerFrame()
{
	self endon("kill_thread");

	while(1)
	{
		wait( level.ex_fps_frame );
		processPlayerEvent("onFrame");
	}
}

onPlayerTenthSecond()
{
	self endon("kill_thread");

	while(1)
	{
		wait( [[level.ex_fpstime]](0.1) );
		processPlayerEvent("onTenthSecond");
	}
}

onPlayerHalfSecond()
{
	self endon("kill_thread");

	while(1)
	{
		wait( [[level.ex_fpstime]](0.5) );
		processPlayerEvent("onHalfSecond");
	}
}

onPlayerSecond()
{
	self endon("kill_thread");

	while(1)
	{
		wait( [[level.ex_fpstime]](1) );
		processPlayerEvent("onSecond");

		// check and handle random events
		for(i = 0; i < self.eventcatalog.size; i++)
		{
			event = self.eventcatalog[i];
			for(j = 0; j < self.events[event].size; j++)
			{
				// only exec onRandom events here
				if(!self.events[event][j].random) continue;
				if(self.events[event][j].enabled)
				{
					if(self.events[event][j].delay) self.events[event][j].delay--;
					else
					{
						if(self.events[event][j].pause_exec) self.events[event][j].enabled = false;
						if(self.events[event][j].random_min == self.events[event][j].random_max) self.events[event][j].delay = self.events[event][j].random_min;
							else self.events[event][j].delay = self.events[event][j].random_min + randomInt(self.events[event][j].random_max - self.events[event][j].random_min);

						// exec function (pass j as eventID)
						self thread [[self.events[event][j].func]](j);
					}
				}
			}
		}
	}
}
