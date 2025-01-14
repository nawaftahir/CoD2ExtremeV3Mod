#include extreme\_ex_controller_memory;
#include extreme\_ex_controller_hud;

init()
{
	[[level.ex_registerCallback]]("onPlayerConnecting", ::onPlayerConnecting);
	[[level.ex_registerCallback]]("onPlayerConnected", ::onPlayerConnected);
	[[level.ex_registerCallback]]("onJoinedTeam", ::onJoinedTeam);
	[[level.ex_registerCallback]]("onJoinedSpectators", ::onJoinedSpectators);
	[[level.ex_registerCallback]]("onPlayerDisconnected", ::onPlayerDisconnected);
}

onPlayerConnecting()
{
	// if roundbased, no need to display the connecting information if they've already been playing
	if(level.ex_roundbased && game["roundnumber"] > 1) return;

	// if using the ready-up system, no need to display the connecting information if they've already been playing
	if(level.ex_readyup && isDefined(game["readyup_done"]) && isDefined(self.pers["team"])) return;

	// check what clan they are in
	self extreme\_ex_player_security::checkClan();

	// connect message and sound
	if(!self.ex_clanID || level.ex_clanannc[self.ex_clanID])
	{
		if(level.ex_plcdmsg) iprintln(&"CLIENTCONTROL_CONNECTING", [[level.ex_pname]](self));
		if(level.ex_plcdsound)
		{
			players = level.players;
			for(i = 0; i < players.size; i++) players[i] playLocalSound("gomplayersjoined");
		}
	}
}

onPlayerConnected()
{	
	// add player to players array
	level.players[level.players.size] = self;

	// set one-off vars
	self.usedweapons = false;
	self.ex_sinbin = false;
	self.ex_glplay = undefined;
	self.pers["specmusic"] = false;
	self.pers["deathmusic"] = false;
	self.pers["intromusic"] = false;

	// initialize main stats
	if(!isDefined(self.pers["kill"])) self.pers["kill"] = 0;
	if(!isDefined(self.pers["teamkill"])) self.pers["teamkill"] = 0;
	if(!isDefined(self.pers["suicide"])) self.pers["suicide"] = 0;

	// check security status
	self extreme\_ex_player_security::main();

	// initialize score
	extreme\_ex_main_score::playerScoreInit();

	// restore points, kills, deaths and bonus if rejoining during grace period
	if(level.ex_scorememory)
	{
		memory = getScoreMemory(self.name);
		if(!memory.error)
		{
			self.pers["score"] = memory.score;
			self.pers["kill"] = memory.kills;
			self.pers["death"] = memory.deaths;
			self.pers["bonus"] = memory.bonus;
			self.pers["special"] = memory.special;

			self.score = self.pers["score"];
			self.deaths = self.pers["death"];

			// added to avoid perk abuse
			if(self.pers["score"]) self.specials_locked = (gettime() / 1000);
		}
	}

	// populate total stats variables
	if(level.ex_statstotal) self extreme\_ex_stats_total::readStats();

	// check if this player is excluded from the inactivity monitor
	self extreme\_ex_player_security::checkIgnoreInactivity();

	// initialize rcon
	self extreme\_ex_player_rcon::rconInitPlayer();

	// initialize weapon zoom
	if(level.ex_zoom) self extreme\_ex_weapons_zoom::initZoom();

	// remove existing ready-up spawn ticket
	if(!level.ex_readyup || (level.ex_readyup && !isDefined(game["readyup_done"])) )
		self.pers["readyup_spawnticket"] = undefined;

	// detect forced auto-assign (0 = off, 1 = all, 2 = non-clan only)
	self.ex_autoassign = 0;
	if(level.ex_autoassign == 1) self.ex_autoassign = 1;
		else if(level.ex_autoassign == 2 && self.ex_clanID != 1) self.ex_autoassign = 1;

	if(self.ex_autoassign) self setClientCvar("ui_allow_select_team", "0");
		else self setClientCvar("ui_allow_select_team", "1");

	// bots need to reselect weapon on round based games with swapteams enabled
	if(isDefined(self.pers["isbot"]))
	{
		if(level.ex_roundbased && level.ex_swapteams && game["roundsplayed"] > 0 && !isDefined(self.pers["weapon"]))
		{
			if(level.ex_log_bots) logprint("BOT: " + self.name + " reselecting new weapons\n");
			self thread extreme\_ex_main_bots::dbotLoadout();
		}
	}

	// if roundbased, no need to hear any intro sounds again if they've already been playing
	if(level.ex_roundbased && game["roundnumber"] > 1) return;

	// if using the ready-up system, no need to hear any intro sounds again if they've already been playing
	if(level.ex_readyup && isDefined(game["readyup_done"]) && isDefined(self.pers["team"])) return;

	// menu music
	if(level.ex_gameover && (level.ex_endmusic || level.ex_mvmusic || level.ex_statsmusic)) skip_intromusic = true;
		else skip_intromusic = false;

	// intro music
	if(!skip_intromusic && level.ex_intromusic > 0)
	{
		if(level.ex_intromusic == 1 && level.ex_music)
		{
			self.pers["intromusic"] = true;
			self playlocalsound(getCvar("mapname"));
		}
		else
		{
			if(level.ex_intromusic == 2 && level.ex_music)
			{
				self.pers["intromusic"] = true;
				self playlocalsound("mus_" + getCvar("mapname"));
			}
			else
			{
				if(level.ex_intromusic == 3 || !level.ex_music)
				{
					intro = randomInt(10) + 1;
					self.pers["intromusic"] = true;
					self playlocalsound("intromusic_" + intro);
				}
			}
		}
	}

	// join message
	if(level.ex_plcdmsg)
	{
		if(!self.ex_clanID || level.ex_clanannc[self.ex_clanID]) iprintln(&"CLIENTCONTROL_HASJOINED", [[level.ex_pname]](self));
	}
}

exPlayerPreServerInfo()
{
	if(level.ex_cinematic && !isDefined(self.pers["isbot"]))
	{
		cinematic_play = true;
		if(level.ex_cinematic == 1 || level.ex_cinematic == 2)
		{
			memory = self getMemory("memory", "cinematic", "status");
			if(!memory.error) cinematic_play = memory.value;
			if(cinematic_play) self setMemory("memory", "cinematic", "status", 0);
		}

		waittillframeend;
		if(cinematic_play) self extreme\_ex_main_utils::execClientCommand("unskippablecinematic poweredby");
		wait( level.ex_fps_frame );
	}
}

onJoinedTeam()
{
	team = self.pers["team"];
	if(isDefined(self.ex_autoassign_team) && (!self.ex_clanID || level.ex_clanannc[self.ex_clanID]) )
	{
		if(team == "allies")
		{
			switch(game["allies"])
			{
				case "american":
					iprintln(&"CLIENTCONTROL_FORCED_JOIN_AMERICAN", [[level.ex_pname]](self));
					break;
				case "british":
					iprintln(&"CLIENTCONTROL_FORCED_JOIN_BRITISH", [[level.ex_pname]](self));
					break;
				default:
					iprintln(&"CLIENTCONTROL_FORCED_JOIN_RUSSIAN", [[level.ex_pname]](self));
					break;
			}
		}
		else if(team == "axis")
		{
			switch(game["axis"])
			{
				case "german":
					iprintln(&"CLIENTCONTROL_FORCED_JOIN_GERMAN", [[level.ex_pname]](self));
					break;
			}
		}
	}
	else if(!self.ex_clanID || level.ex_clanannc[self.ex_clanID])
	{
		if(team == "allies")
		{
			switch(game["allies"])
			{
				case "american":
					iprintln(&"CLIENTCONTROL_RECRUIT_AMERICAN", [[level.ex_pname]](self));
					break;
				case "british":
					iprintln(&"CLIENTCONTROL_RECRUIT_BRITISH", [[level.ex_pname]](self));
					break;
				default:
					iprintln(&"CLIENTCONTROL_RECRUIT_RUSSIAN", [[level.ex_pname]](self));
					break;
			}
		}
		else if(team == "axis")
		{
			switch(game["axis"])
			{
				case "german":
					iprintln(&"CLIENTCONTROL_RECRUIT_GERMAN", [[level.ex_pname]](self));
					break;
			}
		}
	}
}

onJoinedSpectators()
{
	if(level.ex_specmusic && !self.pers["specmusic"])
	{
		self playLocalSound("spec_music_null");
		self.pers["specmusic"] = true;
		self playLocalSound("spec_music");
		self thread spectatorMusicMonitor();
	}
}

onPlayerDisconnected()
{
	// remove player from players array
	self removePlayerOnDisconnect();

	// handle disconnection procs that are not part of event handler (need entity)
	entity = self getEntityNumber();
	if((level.ex_store & 2) == 2) level thread extreme\_ex_specials::onPlayerDisconnected(entity);
	if(level.ex_readyup && !isDefined(game["readyup_done"])) level thread extreme\_ex_monitor_readyup::onPlayerDisconnected(entity);

	// update score memory
	if(level.ex_scorememory)
	{
		level thread setScoreMemory(self.name,
			self.pers["score"],
			self.pers["kill"],
			self.pers["death"],
			self.pers["bonus"],
			self.pers["special"]
		);
	}

	// write cinematic pref to memory
	if(level.ex_cinematic == 2) self setMemory("memory", "cinematic", "status", 1);

	// write statistics to memory
	if(level.ex_statstotal) self extreme\_ex_stats_total::writeStats();

	// clear cached rcon pin
	if(level.ex_rcon && (level.ex_rcon_mode == 1 || (level.ex_rcon_mode == 0 && !level.ex_rcon_autopass)) && level.ex_rcon_cachepin)
		self setDefault("memory", "rcon", "pin");

	// clear cached account password and update cash memory if logged in
	if(level.ex_accounts)
	{
		if(self extreme\_ex_main_accounts::isLoggedIn())
		{
			self setDefault("memory", "account", "password");
			if(level.ex_store && level.ex_store_savecash && level.ex_store_payment == 2)
				self setMemory("accounting", "account", "cash", self.pers["cash"]);
		}
	}
	else
	{
		if(level.ex_store && level.ex_store_savecash && level.ex_store_payment == 2)
			self setMemory("memory", "account", "cash", self.pers["cash"]);
	}

	// save all memory files
	self saveMemorySets();

	// disconnect message and sound
	if(!self.ex_clanID || level.ex_clanannc[self.ex_clanID])
	{
		if(level.ex_plcdmsg) iprintln(&"CLIENTCONTROL_DISCONNECTED", [[level.ex_pname]](self));

		if(level.ex_plcdsound)
		{
			players = level.players;
			for(i = 0; i < players.size; i++) players[i] playLocalSound("gomplayersleft");
		}
	}
}

removePlayerOnDisconnect()
{
	for(i = 0; i < level.players.size; i++ )
	{
		if(level.players[i] == self)
		{
			while(i < level.players.size-1)
			{
				level.players[i] = level.players[i+1];
				i++;
			}
			level.players[i] = undefined;
			break;
		}
	}
}

menuAutoAssign()
{
	if(isDefined(self.spawned)) return;

	assignment = "";

	if(level.ex_statstotal && level.ex_statstotal_balance)
	{
		my_skill = extreme\_ex_stats_total::getMySkillLevel(true);
		if(my_skill)
		{
			AlliedSkill = extreme\_ex_stats_total::getTeamSkillLevel("allies", true, false, false);
			AxisSkill = extreme\_ex_stats_total::getTeamSkillLevel("axis", true, false, false);

			if(level.ex_log_statstotal)
			{
				logprint("STT: " + self.name + " (skill " + my_skill + ") requested auto-assign based on skill levels\n");
				logprint("STT: current skill levels are Allies " + AlliedSkill + ", Axis " + AxisSkill + "\n");
			}

			if(AlliedSkill < AxisSkill) assignment = "allies";
				else if(AxisSkill < AlliedSkill) assignment = "axis";

			if(level.ex_log_statstotal)
			{
				if(assignment != "") logprint("STT: " + self.name + " (skill " + my_skill + ") assigned to team " + assignment + "\n");
					else logprint("STT: " + self.name + " (skill " + my_skill + ") will be balanced based on number of players\n");
			}
			if(level.ex_statstotal_balance == 1) assignment = "";
		}
	}

	if(assignment == "")
	{
		numonteam["allies"] = 0;
		numonteam["axis"] = 0;

		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(player == self || !isDefined(player.pers["team"]) || player.pers["team"] == "spectator" || !isDefined(player.pers["teamTime"])) continue;
			numonteam[player.pers["team"]]++;
		}

		// if teams are equal return the team with the lowest score
		if(numonteam["allies"] == numonteam["axis"])
		{
			if(getTeamScore("allies") == getTeamScore("axis"))
			{
				teams[0] = "allies";
				teams[1] = "axis";
				assignment = teams[randomInt(2)];
			}
			else if(getTeamScore("allies") < getTeamScore("axis")) assignment = "allies";
				else assignment = "axis";
		}
		else if(numonteam["allies"] < numonteam["axis"]) assignment = "allies";
			else assignment = "axis";
	}

	if(self.sessionstate == "playing" || self.sessionstate == "dead")
	{
		if(assignment == self.pers["team"])
		{
			if(!isDefined(self.pers["weapon"]))
			{
				if(self.pers["team"] == "allies") self openMenu(game["menu_weapon_allies"]);
					else self openMenu(game["menu_weapon_axis"]);
			}

			return;
		}
		else
		{
			self.switching_teams = true;
			self.joining_team = assignment;
			self.leaving_team = self.pers["team"];
			if(self.sessionstate == "playing") self suicide();
		}
	}

	self.pers["team"] = assignment;
	self.pers["savedmodel"] = undefined;

	// create the eXtreme+ weapon array
	self extreme\_ex_weapons::setWeaponArray();

	// clear game weapon array
	self clearWeapons();
	
	self setClientCvar("ui_allow_weaponchange", "1");

	self thread maps\mp\gametypes\_weapons::updateAllAllowedSingleClient();

	if(level.ex_gameover)
	{
		menuSpectator();
		return;
	}
	else
	{
		if(level.ex_frag_fest)
		{
			self.pers["weapon"] = "none";
			self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);

			if(!isDefined(self.ex_team_changed) && isDefined(self.WaitingToSpawn) || (level.ex_currentgt == "hq" && (self.pers["team"] == level.DefendingRadioTeam) && isDefined(self.WaitingOnNeutralize)) )
			{
				self [[level.respawnplayer]](true);
			}
			else
			{
				playerHudDestroy("respawn_timer");
				[[level.spawnplayer]]();
			}
		}
		else if(self.pers["team"] == "allies")
		{
			self openMenu(game["menu_weapon_allies"]);
			self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);
		}
		else
		{
			self openMenu(game["menu_weapon_axis"]);
			self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);
		}
	}

	self notify("joined_team");
	if(!level.ex_roundbased) self notify("end_respawn");
}

menuAutoAssignDM()
{
	if(self.pers["team"] != "allies" && self.pers["team"] != "axis")
	{
		if(self.sessionstate == "playing")
		{
			self.switching_teams = true;
			self suicide();
		}

		teams[0] = "allies";
		teams[1] = "axis";
		self.pers["team"] = teams[randomInt(2)];
		self.pers["savedmodel"] = undefined;

		// create the eXtreme+ weapon array
		self extreme\_ex_weapons::setWeaponArray();

		// clear game weapon array
		self clearWeapons();

		self setClientCvar("ui_allow_weaponchange", "1");

		self thread maps\mp\gametypes\_weapons::updateAllAllowedSingleClient();

		if(self.pers["team"] == "allies") self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);
		else self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);

		self notify("joined_team");
		self notify("end_respawn");
	}

	if(level.ex_gameover)
	{
		menuSpectator();
		return;
	}
	else
	{
		if(level.ex_frag_fest)
		{
			self.pers["weapon"] = "none";
			self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);

			if(!isDefined(self.ex_team_changed) && isDefined(self.WaitingToSpawn) || (level.ex_currentgt == "hq" && (self.pers["team"] == level.DefendingRadioTeam) && isDefined(self.WaitingOnNeutralize)) )
			{
				self [[level.respawnplayer]](true);
			}
			else
			{
				playerHudDestroy("respawn_timer");
				[[level.spawnplayer]]();
			}
		}
		else if(!isDefined(self.pers["weapon"]))
		{
			if(self.pers["team"] == "allies") self openMenu(game["menu_weapon_allies"]);
				else self openMenu(game["menu_weapon_axis"]);
		}
	}
}

menuAllies()
{
	if(isDefined(self.spawned)) return;
	
	if(self.pers["team"] != "allies")
	{
		if(self.pers["team"] != "spectator")
		{
			self.switching_teams = true;
			self.joining_team = "allies";
			self.leaving_team = self.pers["team"];
			if(self.sessionstate == "playing") self suicide();
		}

		self.pers["team"] = "allies";
		self.pers["savedmodel"] = undefined;

		// create the eXtreme+ weapon array
		self extreme\_ex_weapons::setWeaponArray();

		// clear game weapon array
		self clearWeapons();

		self setClientCvar("ui_allow_weaponchange", "1");

		self thread maps\mp\gametypes\_weapons::updateAllAllowedSingleClient();

		self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);

		// allow team change option on weapons menu if not deathmatch
		if(level.ex_currentgt == "dm" || level.ex_currentgt == "lms" || level.ex_autoassign) self setClientCvar("ui_allow_teamchange", 0);
		else self setClientCvar("ui_allow_teamchange", 1);

		self notify("joined_team");
		if(!level.ex_roundbased) self notify("end_respawn");
	}

	if(level.ex_gameover)
	{
		menuSpectator();
		return;
	}
	else
	{
		if(level.ex_frag_fest)
		{
			self.pers["weapon"] = "none";
			self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);

			if(!isDefined(self.ex_team_changed) && isDefined(self.WaitingToSpawn) || (level.ex_currentgt == "hq" && (self.pers["team"] == level.DefendingRadioTeam) && isDefined(self.WaitingOnNeutralize)) )
			{
				self [[level.respawnplayer]](true);
			}
			else
			{
				playerHudDestroy("respawn_timer");
				[[level.spawnplayer]]();
			}
		}
		else if(!isDefined(self.pers["weapon"])) self openMenu(game["menu_weapon_allies"]);
	}
}

menuAxis()
{
	if(isDefined(self.spawned)) return;

	if(self.pers["team"] != "axis")
	{
		if(self.pers["team"] != "spectator")
		{
			self.switching_teams = true;
			self.joining_team = "axis";
			self.leaving_team = self.pers["team"];
			if(self.sessionstate == "playing") self suicide();
		}

		self.pers["team"] = "axis";
		self.pers["savedmodel"] = undefined;

		// create the eXtreme+ weapon array
		self extreme\_ex_weapons::setWeaponArray();

		// clear game weapon array
		self clearWeapons();

		self setClientCvar("ui_allow_weaponchange", "1");

		self thread maps\mp\gametypes\_weapons::updateAllAllowedSingleClient();

		self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);

		// allow team change option on weapons menu if not deathmatch
		if(level.ex_currentgt == "dm" || level.ex_currentgt == "lms" || level.ex_autoassign) self setClientCvar("ui_allow_teamchange", 0);
		else self setClientCvar("ui_allow_teamchange", 1);

		self notify("joined_team");
		if(!level.ex_roundbased) self notify("end_respawn");
	}

	if(level.ex_gameover)
	{
		menuSpectator();
		return;
	}
	else
	{
		if(level.ex_frag_fest)
		{
			self.pers["weapon"] = "none";
			self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);

			if(!isDefined(self.ex_team_changed) && isDefined(self.WaitingToSpawn) || (level.ex_currentgt == "hq" && (self.pers["team"] == level.DefendingRadioTeam) && isDefined(self.WaitingOnNeutralize)) )
			{
				self [[level.respawnplayer]](true);
			}
			else
			{
				playerHudDestroy("respawn_timer");
				[[level.spawnplayer]]();
			}
		}
		else if(!isDefined(self.pers["weapon"])) self openMenu(game["menu_weapon_axis"]);
	}
}

menuSpectator()
{
	// do not allow anyone to go to spectators
	//if(isDefined(self.spawned)) return;

	// only allow clan 1 members (as set up in clancontrol.cfg) to go to spectators
	//if(isDefined(self.spawned) && self.ex_clanID != 1) return;

	// only allow clan members (clan 1 - 4 as set up in clancontrol.cfg) to go to spectators
	//if(isDefined(self.spawned) && !self.ex_clanID)) return;

	if(self.pers["team"] != "spectator")
	{
		self.switching_teams = true;
		self.joining_team = "spectator";
		self.leaving_team = self.pers["team"];
		if(self.sessionstate == "playing") self suicide();

		self.pers["team"] = "spectator";
		self.pers["savedmodel"] = undefined;
		self.sessionteam = "spectator";

		// create the eXtreme+ weapon array
		self extreme\_ex_weapons::setWeaponArray();

		// clear game weapon array
		self clearWeapons();

		self thread maps\mp\gametypes\_weapons::updateAllAllowedSingleClient();

		self setClientCvar("ui_allow_weaponchange", "0");

		extreme\_ex_player_spawn::spawnspectator();
		
		self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);
	}

	self notify("joined_spectators");
}

menuWeapon(response)
{
	self endon("disconnect");

	if(!isDefined(self.pers["team"]) || (self.pers["team"] != "allies" && self.pers["team"] != "axis")) return;

	weapon = self maps\mp\gametypes\_weapons::restrictWeaponByServerCvars(response);

	if(weapon == "restricted")
	{
		if(self.pers["team"] == "allies") self openMenu(game["menu_weapon_allies"]);
		else if(self.pers["team"] == "axis") self openMenu(game["menu_weapon_axis"]);

		return;
	}

	self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);

	if(level.ex_wepo_secondary)
	{
		if(isDefined(self.pers["weapon2"]) && self.pers["weapon2"] == response)
		{
			if(self.pers["team"] == "allies") self openMenu(game["menu_weapon_allies"]);
			else if(self.pers["team"] == "axis") self openMenu(game["menu_weapon_axis"]);
	
			return;
		}
	}
	else if(isDefined(self.pers["weapon"]) && self.pers["weapon"] == weapon) return;

	self maps\mp\gametypes\_weapons::updateDisabledSingleClient(weapon);

	if(!isDefined(self.pers["weapon"]))
	{
		self.pers["weapon"] = weapon;
		if(level.ex_wepo_secondary) self.pers["weapon1"] = weapon;

		if(!level.ex_wepo_secondary)
		{
			if(!isDefined(self.ex_team_changed) && isDefined(self.WaitingToSpawn) || (level.ex_currentgt == "hq" && (self.pers["team"] == level.DefendingRadioTeam) && isDefined(self.WaitingOnNeutralize)) )
			{
				self [[level.respawnplayer]](true);
			}
			else
			{
				playerHudDestroy("respawn_timer");
				[[level.spawnplayer]]();
			}
		}
		else
		{
			if(self.pers["team"] == "allies") self openMenu(game["menu_weapon_allies_sec"]);
			else if(self.pers["team"] == "axis") self openMenu(game["menu_weapon_axis_sec"]);

			return;
		}
	}
	else
	{
		self maps\mp\gametypes\_weapons::updateEnabledSingleClient(self.pers["weapon"]);

		self.pers["weapon"] = weapon;
		if(level.ex_wepo_secondary) self.pers["weapon1"] = weapon;

		weaponname = maps\mp\gametypes\_weapons::getWeaponName(weapon);
		if(level.ex_roundbased && (level.ex_currentgt == "sd" || level.ex_currentgt == "lts"))
		{
			if(maps\mp\gametypes\_weapons::useAn(self.pers["weapon2"])) self iprintln(&"MP_YOU_WILL_SPAWN_WITH_AN_NEXT_ROUND", weaponname);
				else self iprintln(&"MP_YOU_WILL_SPAWN_WITH_A_NEXT_ROUND", weaponname);
		}
		else
		{
			if(maps\mp\gametypes\_weapons::useAn(self.pers["weapon"])) self iprintln(&"MP_YOU_WILL_RESPAWN_WITH_AN", weaponname);
				else self iprintln(&"MP_YOU_WILL_RESPAWN_WITH_A", weaponname);
		}
	}

	level thread maps\mp\gametypes\_weapons::updateAllowed();

	self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
}

menuSecWeapon(response)
{
	self endon("disconnect");

	weapon = self maps\mp\gametypes\_weapons::restrictWeaponByServerCvars(response);

	if(weapon == "restricted" || (isDefined(self.pers["weapon1"]) && self.pers["weapon1"] == response))
	{
		if(self.pers["team"] == "allies") self openMenu(game["menu_weapon_allies_sec"]);
		else if(self.pers["team"] == "axis") self openMenu(game["menu_weapon_axis_sec"]);

		return;
	}

	self maps\mp\gametypes\_weapons::updateDisabledSingleClient(weapon);

	if(!isDefined(self.pers["weapon2"]))
	{
		self.pers["weapon2"] = weapon;

		if(!isDefined(self.ex_team_changed) && (isDefined(self.WaitingToSpawn) || (level.ex_currentgt == "hq" && (self.pers["team"] == level.DefendingRadioTeam) && isDefined(self.WaitingOnNeutralize))) )
		{
			self [[level.respawnplayer]](true);
		}
		else
		{
			playerHudDestroy("respawn_timer");
			[[level.spawnplayer]]();
		}
	}
	else
	{
		self maps\mp\gametypes\_weapons::updateEnabledSingleClient(self.pers["weapon2"]);

		self.pers["weapon2"] = weapon;

		weaponname = maps\mp\gametypes\_weapons::getWeaponName(weapon);
		if(level.ex_roundbased && (level.ex_currentgt == "sd" || level.ex_currentgt == "lts"))
		{
			if(maps\mp\gametypes\_weapons::useAn(self.pers["weapon2"])) self iprintln(&"MP_YOU_WILL_SPAWN_WITH_AN_NEXT_ROUND_SECONDARY", weaponname);
				else self iprintln(&"MP_YOU_WILL_SPAWN_WITH_A_NEXT_ROUND_SECONDARY", weaponname);
		}
		else
		{
			if(maps\mp\gametypes\_weapons::useAn(self.pers["weapon2"])) self iprintln(&"MP_YOU_WILL_RESPAWN_WITH_AN_SECONDARY", weaponname);
				else self iprintln(&"MP_YOU_WILL_RESPAWN_WITH_A_SECONDARY", weaponname);
		}
	}		

	level thread maps\mp\gametypes\_weapons::updateAllowed();

	self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
}

clearWeapons()
{
	self endon("disconnect");

	// clear weapon selection
	self.pers["weapon"] = undefined;
	self.pers["weapon1"] = undefined;
	self.pers["weapon2"] = undefined;
}

spectatorMusicMonitor()
{
	self endon("disconnect");

	mt = undefined;

	hud_index = playerHudCreate("spec_music", 322, 462, 1, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index == -1) return;
	playerHudSetText(hud_index, &"MISC_MELEE_CHANGE_MUSIC");

	for(;;)
	{
		if(self meleeButtonPressed())
		{
			self playLocalSound("spec_music_null");
			self playLocalSound("spec_music_stop");

			playerHudFade(hud_index, 0.2, 0.2, 0);
			playerHudSetText(hud_index, &"MISC_MUSIC_CHNG");
			playerHudFade(hud_index, 0.2, 0, 1);
			self playLocalSound("spec_music");
			mt = 30;
		}

		if(isDefined(mt))
		{
			if(mt <= 0)
			{
				mt = undefined;
				playerHudFade(hud_index, 0.2, 0.2, 0);
				playerHudSetText(hud_index, &"MISC_MELEE_CHANGE_MUSIC");
				playerHudFade(hud_index, 0.2, 0, 1);
			}
			else mt--;
		}

		if(!self.pers["specmusic"] || level.ex_gameover == true)
		{
			playerHudDestroy(hud_index);
			break;
		}

		wait( [[level.ex_fpstime]](0.1) );
	}
}
