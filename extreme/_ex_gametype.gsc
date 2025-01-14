#include extreme\_ex_controller_hud;

init()
{
	switch(getcvar("g_gametype"))
	{
		case "chq":
			thread extreme\_ex_gametype_chq::main();
			break;
		case "cnq":
			thread extreme\_ex_gametype_cnq::main();
			break;
		case "ctf":
			thread extreme\_ex_gametype_ctf::main();
			break;
		case "ctfb":
			thread extreme\_ex_gametype_ctfb::main();
			break;
		case "dm":
			thread extreme\_ex_gametype_dm::main();
			break;
		case "dom":
			thread extreme\_ex_gametype_dom::main();
			break;
		case "esd":
			thread extreme\_ex_gametype_esd::main();
			break;
		case "ft":
			thread extreme\_ex_gametype_ft::main();
			break;
		case "hm":
			thread extreme\_ex_gametype_hm::main();
			break;
		case "hq":
			thread extreme\_ex_gametype_hq::main();
			break;
		case "htf":
			thread extreme\_ex_gametype_htf::main();
			break;
		case "ihtf":
			thread extreme\_ex_gametype_ihtf::main();
			break;
		case "lib":
			thread extreme\_ex_gametype_lib::main();
			break;
		case "lms":
			thread extreme\_ex_gametype_lms::main();
			break;
		case "lts":
			thread extreme\_ex_gametype_lts::main();
			break;
		case "ons":
			thread extreme\_ex_gametype_ons::main();
			break;
		case "rbcnq":
			thread extreme\_ex_gametype_rbcnq::main();
			break;
		case "rbctf":
			thread extreme\_ex_gametype_rbctf::main();
			break;
		case "sd":
			thread extreme\_ex_gametype_sd::main();
			break;
		case "tdm":
			thread extreme\_ex_gametype_tdm::main();
			break;
		case "tkoth":
			thread extreme\_ex_gametype_tkoth::main();
			break;
		case "vip":
			thread extreme\_ex_gametype_vip::main();
			break;
	}
}

//------------------------------------------------------------------------------
// Respawn Delay
//------------------------------------------------------------------------------
getRespawnDelay()
{
	respawndelay = level.respawndelay;

	// additional delay depending on number of players
	if(level.ex_respawndelay_dyn)
	{
		active_players = getActivePlayers();
		if(active_players)
		{
			respawndelay_add = 0;

			if(active_players <= level.ex_respawndelay_dyn_array.size)
				respawndelay_add = level.ex_respawndelay_dyn_array[active_players - 1];
			else
				respawndelay_add = level.ex_respawndelay_dyn_array[level.ex_respawndelay_dyn_array.size - 1];

			//logprint("DEBUG: " + respawndelay_add + " seconds additional respawn delay based on " + active_players + " active players\n");
			if(respawndelay_add) respawndelay += respawndelay_add;
		}
	}

	// additional delay depending on weapon class
	if(level.ex_respawndelay_class && isDefined(self.pers["weapon"]))
	{
		respawndelay_add = 0;

		weapon = self.pers["weapon"];
		if(level.ex_respawndelay_sniper && extreme\_ex_weapons::isWeaponType(weapon, "sniper")) respawndelay_add = level.ex_respawndelay_sniper;
		else if(level.ex_respawndelay_rifle && extreme\_ex_weapons::isWeaponType(weapon, "rifle")) respawndelay_add = level.ex_respawndelay_rifle;
		else if(level.ex_respawndelay_mg && extreme\_ex_weapons::isWeaponType(weapon, "mg")) respawndelay_add = level.ex_respawndelay_mg;
		else if(level.ex_respawndelay_smg && extreme\_ex_weapons::isWeaponType(weapon, "smg")) respawndelay_add = level.ex_respawndelay_smg;
		else if(level.ex_respawndelay_shot && extreme\_ex_weapons::isWeaponType(weapon, "shotgun")) respawndelay_add = level.ex_respawndelay_shot;
		else if(level.ex_respawndelay_rl && extreme\_ex_weapons::isWeaponType(weapon, "rl")) respawndelay_add = level.ex_respawndelay_rl;

		if(!respawndelay_add && level.ex_respawndelay_class == 2 && level.ex_wepo_secondary && isDefined(self.pers["weapon2"]))
		{
			weapon = self.pers["weapon2"];
			if(level.ex_respawndelay_sniper && extreme\_ex_weapons::isWeaponType(weapon, "sniper")) respawndelay_add = level.ex_respawndelay_sniper;
			else if(level.ex_respawndelay_rifle && extreme\_ex_weapons::isWeaponType(weapon, "rifle")) respawndelay_add = level.ex_respawndelay_rifle;
			else if(level.ex_respawndelay_mg && extreme\_ex_weapons::isWeaponType(weapon, "mg")) respawndelay_add = level.ex_respawndelay_mg;
			else if(level.ex_respawndelay_smg && extreme\_ex_weapons::isWeaponType(weapon, "smg")) respawndelay_add = level.ex_respawndelay_smg;
			else if(level.ex_respawndelay_shot && extreme\_ex_weapons::isWeaponType(weapon, "shotgun")) respawndelay_add = level.ex_respawndelay_shot;
			else if(level.ex_respawndelay_rl && extreme\_ex_weapons::isWeaponType(weapon, "rl")) respawndelay_add = level.ex_respawndelay_rl;
		}

		//logprint("DEBUG: " + respawndelay_add + " seconds additional respawn delay based on weapon class\n");
		if(respawndelay_add) respawndelay += respawndelay_add;
	}

	// additional delay if subzero score
	if(level.ex_respawndelay_subzero && self.pers["score"] < 0)
	{
		respawndelay_add = level.ex_respawndelay_subzero;
		//logprint("DEBUG: " + respawndelay_add + " seconds additional respawn delay due to subzero score\n");
		if(respawndelay_add) respawndelay += respawndelay_add;
	}

	return(respawndelay);
}

getActivePlayers()
{
	active_players = 0;
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isPlayer(player))
		{
			if(!isDefined(player.pers["team"])) continue;
			if(player.pers["team"] == "spectator" || player.sessionteam == "spectator") continue;
			active_players++;
		}
	}
	return(active_players);
}

//------------------------------------------------------------------------------
// Team Swapping (halftime or every round)
//------------------------------------------------------------------------------
swapTeams(flagproc)
{
	level endon("ex_gameover");

	// block checkTimeLimit(), checkScoreLimit() and updateGametypeCvars()
	game["matchpaused"] = 1;

	// remove perks and dog tags
	if((level.ex_store & 2) == 2) thread extreme\_ex_specials::removeAllPerks();
	if(level.ex_kc) thread extreme\_ex_main_killconfirmed::removeAllTags();

	// remove clock
	destroyClock();

	// freeze players and make them drop flag if necessary
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player) || player.sessionteam == "spectator") continue;
		player freezecontrols(true);
		player.health = player.maxhealth;
		player extreme\_ex_main_utils::dropTheFlag(true);
		wait( level.ex_fps_frame );
	}

	// flag based: return flags to base
	if(level.ex_currentgt == "ctf" || level.ex_currentgt == "ctfb" || level.ex_currentgt == "rbctf")
	{
		if(isDefined(flagproc)) level.flags["allies"] [[flagproc]]();
		if(isDefined(flagproc)) level.flags["axis"] [[flagproc]]();
	}

	// inform players
	hud_ybase = 0;
	hud_index = levelHudCreate("swapteam_bg", undefined, 0, hud_ybase, 0.5, (1,1,1), 1, 1, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index != -1) levelHudSetShader(hud_index, "black", 320, 75);

	hud_y = hud_ybase - 20;
	hud_index = levelHudCreate("swapteam_head", undefined, 0, hud_y, 1, (0,1,0), 2.5, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index != -1)
	{
		if(level.ex_roundbased) levelHudSetText(hud_index, &"MISC_SWAPTEAM");
			else levelHudSetText(hud_index, &"MISC_HALFTIME");
	}

	hud_y = hud_ybase + 5;
	hud_index = levelHudCreate("swapteam_switch", undefined, 0, hud_y, 1, (1,1,0), 1.2, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index != -1) levelHudSetLabel(hud_index, &"MISC_SWAPTEAM_SWITCH");

	hud_y += 15;
	hud_index = levelHudCreate("swapteam_min", undefined, 0, hud_y, 1, (1,1,1), 1.2, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index != -1)
	{
		levelHudSetLabel(hud_index, &"MISC_SWAPTEAM_CONTINUE");
		levelHudSetValue(hud_index, level.ex_swapteams_hudtime);
	}

	wait( [[level.ex_fpstime]](level.ex_swapteams_hudtime) );

	levelHudDestroy("swapteam_min");
	levelHudDestroy("swapteam_switch");
	levelHudDestroy("swapteam_head");
	levelHudDestroy("swapteam_bg");

	// switch scores
	tempscore = getTeamScore("allies");
	game["alliedscore"] = getTeamScore("axis");
	game["axisscore"] = tempscore;
	setTeamScore("allies", game["alliedscore"]);
	setTeamScore("axis", game["axisscore"]);

	// save models
	axismodels = [];
	alliedmodels = [];

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player) || player.sessionteam == "spectator") continue;

		if(isDefined(player.pers["team"]) && isDefined(player.pers["savedmodel"]))
		{
			if(player.pers["team"] == "axis") axismodels[axismodels.size] = player.pers["savedmodel"];
				else if(player.pers["team"] == "allies") alliedmodels[alliedmodels.size] = player.pers["savedmodel"];
		}
	}

	// switch teams and reset weapons if necessary
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player) || player.sessionteam == "spectator") continue;

		if(isDefined(player.pers["team"]))
		{
			//player unlink();
			//player.archivetime = 0;
			//player thread maps\mp\gametypes\_spectating::setSpectatePermissions();
			resetweapons = false;
			if(!level.ex_all_weapons && !level.ex_modern_weapons)
			{
				if(!level.ex_wepo_class || level.ex_wepo_team_only) resetweapons = true;
				if(level.ex_wepo_secondary && !level.ex_wepo_sec_enemy) resetweapons = true;
			}

			if(resetweapons)
			{
				player thread extreme\_ex_main_clientcontrol::clearWeapons();
				player thread extreme\_ex_weapons::setWeaponArray();
				player thread maps\mp\gametypes\_weapons::updateAllAllowedSingleClient();
			}

			if(player.pers["team"] == "axis")
			{
				player.pers["team"] = "allies";
				if(alliedmodels.size) player.pers["savedmodel"] = alliedmodels[randomInt(alliedmodels.size)];
					else player.pers["savedmodel"] = undefined;
			}
			else if(player.pers["team"] == "allies")
			{
				player.pers["team"] = "axis";
				if(axismodels.size) player.pers["savedmodel"] = axismodels[randomInt(axismodels.size)];
					else player.pers["savedmodel"] = undefined;
			}
			wait( level.ex_fps_frame );
		}
	}

	// let varcache know we passed halftime
	game["halftime"] = 1;

	level notify("restarting");
	wait( [[level.ex_fpstime]](1) );
	map_restart(true);
}

//------------------------------------------------------------------------------
// Overtime handling
//------------------------------------------------------------------------------
startOvertime(flagproc)
{
	// block checkTimeLimit(), checkScoreLimit() and updateGametypeCvars()
	game["matchpaused"] = 1;

	// turn off features that would interfere
	if((level.ex_store & 2) == 2) thread extreme\_ex_specials::removeAllPerks();
	level.ex_bestof = 0;
	if(level.ex_kc)
	{
		level.ex_kc = 0;
		thread extreme\_ex_main_killconfirmed::removeAllTags();
	}

	// remove clock
	destroyClock();

	// handle players 1 - end respawn timer and confirmation
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player) || player.sessionteam == "spectator") continue;

		// kill respawn_timer
		if(level.respawndelay && isDefined(player.WaitingToSpawn))
		{
			player notify("end_respawntimer");
			player playerHudDestroy("respawn_timer");
			player.WaitingToSpawn = undefined;
		}

		// kill respawn confirmation
		if(!level.forcerespawn) player notify("end_respawn");
	}

	// handle players 2 - reset health, optionally freeze and drop flag
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player) || player.sessionteam == "spectator") continue;

		player.health = player.maxhealth;
		if(level.ex_overtime_resetteam) player freezecontrols(true);
		if(level.ex_overtime_resetflag) player extreme\_ex_main_utils::dropTheFlag(true);
		wait( level.ex_fps_frame );
	}

	// flag based: return flags to base
	if(level.ex_overtime_resetflag)
	{
		if(level.ex_currentgt == "ctf" || level.ex_currentgt == "ctfb" || level.ex_currentgt == "rbctf")
		{
			if(isDefined(flagproc)) level.flags["allies"] [[flagproc]]();
			if(isDefined(flagproc)) level.flags["axis"] [[flagproc]]();
		}
	}

	// inform players
	hud_ybase = 0;
	hud_index = levelHudCreate("overtime_bg", undefined, 0, hud_ybase, 0.5, (1,1,1), 1, 1, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index != -1) levelHudSetShader(hud_index, "black", 320, 85);

	hud_y = hud_ybase - 20;
	hud_index = levelHudCreate("overtime_head", undefined, 0, hud_y, 1, (0,1,0), 2.5, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index != -1) levelHudSetText(hud_index, &"MISC_OVERTIME");

	hud_y = hud_ybase + 5;
	hud_index = levelHudCreate("overtime_min", undefined, 0, hud_y, 1, (1,1,0), 1.2, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index != -1)
	{
		levelHudSetLabel(hud_index, &"MISC_OVERTIME_MINUTES");
		levelHudSetValue(hud_index, level.ex_overtime);
	}

	if(level.ex_flagbased)
	{
		hud_y += 15;
		hud_index = levelHudCreate("overtime_cap", undefined, 0, hud_y, 1, (1,1,1), 1.2, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
		if(hud_index != -1) levelHudSetText(hud_index, &"MISC_OVERTIME_FIRSTCAP");
	}

	if(level.ex_overtime_lastman)
	{
		hud_y += 10;
		hud_index = levelHudCreate("overtime_lts", undefined, 0, hud_y, 1, (1,1,1), 1.2, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
		if(hud_index != -1) levelHudSetText(hud_index, &"MISC_OVERTIME_LASTTEAM");
	}

	wait( [[level.ex_fpstime]](level.ex_overtime_hudtime) );

	levelHudDestroy("overtime_lts");
	levelHudDestroy("overtime_cap");
	levelHudDestroy("overtime_min");
	levelHudDestroy("overtime_head");
	levelHudDestroy("overtime_bg");

	// handle players 3 - spawn
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player) || player.sessionteam == "spectator") continue;

		player.health = player.maxhealth;
		if(level.ex_overtime_lastman) player.spawned = true;

		if(level.ex_overtime_resetteam)
		{
			if(player.sessionstate != "dead")
			{
				player freezecontrols(false);
				spawnpoint = undefined;

				switch(level.ex_currentgt)
				{
					case "tdm":
						spawnpointname = "mp_tdm_spawn";
						spawnpoints = getentarray(spawnpointname, "classname");
						spawnpoint = player maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);
						break;
					case "ctf":
					case "ctfb":
						if(player.pers["team"] == "allies") spawnpointname = "mp_ctf_spawn_allied";
							else spawnpointname = "mp_ctf_spawn_axis";
						spawnpoints = getentarray(spawnpointname, "classname");
						spawnpoint = player maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearOwnFlag(spawnpoints);
						break;
				}

				if(isDefined(spawnpoint))
				{
					player setOrigin(spawnpoint.origin);
					player setPlayerAngles(spawnpoint.angles);
				}
				wait( level.ex_fps_frame );
			}
		}
	}

	// flag based: set new score limit to current team score + 1
	if(level.ex_flagbased) game["scorelimit"] = getTeamScore("allies") + 1;

	// start live stats for last team standing if not active already
	if(!level.ex_livestats && level.ex_overtime_lastman) thread extreme\_ex_stats_live::init();

	// restart clock
	game["timelimit"] = level.ex_overtime;
	setCvar("scr_" + level.ex_currentgt + "_timelimit", game["timelimit"]);
	//setCvar("ui_timelimit", game["timelimit"]);
	level.starttime = getTime();
	createClock(game["timelimit"] * 60);
	levelHudSetLabel("mainclock", &"MISC_CLOCK_OT");

	// allow checkTimeLimit() and checkScoreLimit() to run again
	game["matchpaused"] = 0;
	game["matchovertime"] = 1;
}
