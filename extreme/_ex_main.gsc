#include extreme\_ex_controller_hud;

main()
{
	if(level.ex_roundbased) [[level.ex_registerCallback]]("onRoundOver", ::onRoundOver);
	[[level.ex_registerCallback]]("onGameOver", ::onGameOver);

	// trigger areas for flag return and map edge detection
	// keep after _ex_monitor_entities::init and _gameobjects::main, because they
	// can remove minefield and trigger_hurt entities!
	level.ex_returners = getentarray("minefield", "targetname");
	trigger_hurts = getentarray("trigger_hurt", "classname");
	for(i = 0; i < trigger_hurts.size; i++)
		level.ex_returners[level.ex_returners.size] = trigger_hurts[i];
	trigger_hurts = undefined;

	// report removed entities
	if(level.ex_entities)
	{
		// dump entities after the level script has completed
		extreme\_ex_monitor_entities::dumpMapEntitiesAFTER();
		if((level.ex_entities & 1) == 1) thread extreme\_ex_monitor_entities::reportRemovedEntities();
	}

	// report precached items
	if(level.ex_log_precache) extreme\_ex_main_utils::reportPrecache();

	// we only need to initialize the mbots in mbot development mode
	if(level.ex_mbot && level.ex_mbot_dev)
	{
		// initialize spawnpoint markers array
		level.ex_spawnmarkers = [];

		// initialize mbots
		thread extreme\_ex_main_bots::main(true);

		// tell DRM to stop processing "small", "medium" and "large" extensions
		game["drm_modstate"] = "initialized";

		return;
	}

	// reposition flags to fix placement bug on linux
	if(level.ex_flagbased)
	{
		axis_flag = getent("axis_flag", "targetname");
		if(isDefined(axis_flag))
		{
			//axis_flag placeSpawnpoint();
			trace = bulletTrace(axis_flag.origin + (0,0,50), axis_flag.origin - (0,0,100), true, axis_flag);
			axis_flag.origin = trace["position"];
			axis_flag.home_origin = axis_flag.origin;
			if(isDefined(axis_flag.flagmodel)) axis_flag.flagmodel.origin = axis_flag.home_origin;
			if(isDefined(axis_flag.basemodel)) axis_flag.basemodel.origin = axis_flag.home_origin;
		}

		allied_flag = getent("allied_flag", "targetname");
		if(isDefined(allied_flag))
		{
			//allied_flag placeSpawnpoint();
			trace = bulletTrace(allied_flag.origin + (0,0,50), allied_flag.origin - (0,0,100), true, allied_flag);
			allied_flag.origin = trace["position"];
			allied_flag.home_origin = allied_flag.origin;
			if(isDefined(allied_flag.flagmodel)) allied_flag.flagmodel.origin = allied_flag.home_origin;
			if(isDefined(allied_flag.basemodel)) allied_flag.basemodel.origin = allied_flag.home_origin;
		}
	}

	// get the map dimensions and playing field dimensions
	if(!isDefined(game["mapArea_Centre"])) extreme\_ex_main_utils::getMapDim(false);

	// create spawnpoints array
	if(!isDefined(level.ex_current_spawnpoints)) extreme\_ex_spawnpoints::spawnpointArray();

	// update spawnpoints in designer mode
	if(level.ex_designer) thread extreme\_ex_spawnpoints::markSpawnpoints();

	// initialize bots (dumb or meat)
	if(level.ex_testclients || level.ex_mbot) thread extreme\_ex_main_bots::main();

	// setup weather FX
	if(level.ex_weather) thread extreme\_ex_ambient_weather::main();

	// set up map rotation (executed only once)
	if(getCvar("ex_maprotdone") == "")
	{
		// set up player based rotation
		if(level.ex_pbrotate)
		{
			// includes fixing player based strings if level.ex_fixmaprotation is enabled
			extreme\_ex_main_rotation::pbRotation();
		}
		else
		{
			// fix the other map rotation strings (includes stacker strings if enabled)
			if(level.ex_fixmaprotation) level extreme\_ex_main_rotation::fixMapRotation();

			// randomize map rotation
			if(level.ex_randommaprotation) level thread extreme\_ex_main_rotation::randomMapRotation();

			// save rotation for rotation stacker
			setCvar("ex_maprotation", getCvar("sv_maprotation"));
		}
		setCvar("ex_maprotdone","1");
	}

	// check if we are playing a next map set by RCON, and have to restore the rotation
	maprotsaved = getCvar("saved_maprotationcurrent");
	if(maprotsaved != "")
	{
		setCvar("sv_maprotationcurrent", maprotsaved);
		setCvar("saved_maprotationcurrent", "");
	}

	// rotation stacker
	if(!level.ex_pbrotate && !isDefined(game["stacker_done"]))
	{
		maprotcur = getCvar("sv_maprotationcurrent");
		if(maprotcur == "")
		{
			maprotno = getCvar("ex_maprotno");
			if(maprotno == "") maprotno = 0;
				else maprotno = getCvarInt("ex_maprotno");
			maprotno++;
			maprot = getCvar("sv_maprotation" + maprotno);
			if(maprot != "")
			{
				setCvar("sv_maprotation", maprot);
				setCvar("ex_maprotno", maprotno);
			}
			else if(maprotno != 1)
			{
				maprotno = 0;
				setCvar("sv_maprotation", getCvar("ex_maprotation"));
				setCvar("ex_maprotno", maprotno);
			}
			else setCvar("ex_maprotno", maprotno);
		}
		game["stacker_done"] = 1;
	}

	// start rotation rig for gunships and uav (needs to go below getMapDim)
	if(level.ex_gunship || level.ex_gunship_special || (level.ex_uav && level.ex_uav_model))
		level thread extreme\_ex_main_rotationrig::main();

	// start gunships
	if(level.ex_gunship || level.ex_gunship_special) level thread extreme\_ex_main_gunship::main();

	// clear any camping players
	if(level.ex_anticamp) level thread extreme\_ex_player_camper::removeCampers();

	// bash-mode level announcement
	if( (level.ex_bash_only && level.ex_bash_only_msg > 1) || (level.ex_frag_fest && level.ex_frag_fest_msg > 1) )
		level thread modeAnnounceLevel();

	// clan-mode level announcement
	if(level.ex_clanvsnonclan && level.ex_clanvsnonclan_msg > 1) level thread clanAnnounceLevel();

	// ammo crates
	if(level.ex_amc) level thread extreme\_ex_weapons_ammocrates::main();

	// turrets monitor
	if(level.ex_turrets) level thread extreme\_ex_weapons_turrets::main();

	// retreat monitor
	if(level.ex_flag_retreat) level thread retreatMonitor();

	// toolbox
	if(level.ex_toolbox) level thread extreme\_ex_main_toolbox::main();

	// player callback events
	extreme\_ex_player::initEvents();

	// tell DRM to stop processing "small", "medium" and "large" extensions
	game["drm_modstate"] = "initialized";

	// start bot system
	level notify("gobots");
}

//------------------------------------------------------------------------------
// Retreat monitor
//------------------------------------------------------------------------------
retreatMonitor()
{
	level endon("ex_gameover");

	// the flags are not initialized while readying up, so return and wait for it to finish
	if(level.ex_readyup && !isDefined(game["readyup_done"])) return;

	axis_flag = getent("axis_flag", "targetname");
	allied_flag = getent("allied_flag", "targetname");

	// distance between axis and allies base divided by 2 to mark hypothetical middle of map
	flag_dist = int(distance(axis_flag.basemodel.origin, allied_flag.basemodel.origin) / 2);

	// loop delay initialization (regular checks each second; after announcements 5 seconds)
	loop_delay = 1;

	while(1)
	{
		wait( [[level.ex_fpstime]](loop_delay) );

		// loop delay reset
		loop_delay = 1;

		// are flags on base? if both flags are, no need to do additional checking
		axis_flag_onbase = (axis_flag.origin == axis_flag.home_origin);
		allies_flag_onbase = (allied_flag.origin == allied_flag.home_origin);
		if(!axis_flag_onbase || !allies_flag_onbase)
		{
			// are flags on the move?
			flag["axis"] = "none";
			flag["allies"] = "none";

			players = level.players;
			for(i = 0; i < players.size; i++)
			{
				player = players[i];
				if(isPlayer(player) && player.sessionstate == "playing" && isDefined(player.flag))
				{
					if(level.ex_currentgt == "ctfb")
					{
						if(isDefined(player.ownflagAttached)) flag[player.pers["team"]] = player.pers["team"];
						if(isDefined(player.enemyflagAttached)) flag[getEnemyTeam(player.pers["team"])] = player.pers["team"];
					}
					else flag[getEnemyTeam(player.pers["team"])] = player.pers["team"];
				}
				if(flag["axis"] != "none" && flag["allies"] != "none") break;
			}

			// check if axis have both flags
			if( flag["allies"] == "axis" && (axis_flag_onbase || flag["axis"] == "axis") )
			{
				retreat_team = "axis";
				retreat_origin = axis_flag.home_origin;
			}
			// check if allies have both flags
			else if( flag["axis"] == "allies" && (allies_flag_onbase || flag["allies"] == "allies") )
			{
				retreat_team = "allies";
				retreat_origin = allied_flag.home_origin;
			}
			// no retreat_team (only reset retreatwarning flags)
			else
			{
				retreat_team = "none";
				retreat_origin = undefined;
			}
		}
		// no retreat_team (only reset retreatwarning flags)
		else
		{
			retreat_team = "none";
			retreat_origin = undefined;
		}

		// warn players on retreat_team to retreat when in warning range
		// if retreat_team is "none" only reset retreatwarning flag for all players
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(isPlayer(player) && player.sessionstate == "playing")
			{
				// 3 warnings until flag status changes; decrement if on retreat_team, reset to 3 if not
				if(player.pers["team"] == retreat_team )
				{
					if(!isDefined(player.retreatwarning)) player.retreatwarning = 3;
					retreat_dist = int(distance(retreat_origin, player.origin));
					if(!isDefined(player.flag))
					{
						if( (retreat_dist < (flag_dist + (flag_dist * 0.25))) && (retreat_dist > (flag_dist * 0.1)) )
						{
							if(player.retreatwarning)
							{
								player.retreatwarning--;
								if((level.ex_flag_retreat & 1) == 1) player iprintln(&"MISC_FLAG_RETREAT");
									else if((level.ex_flag_retreat & 2) == 2) player iprintlnbold(&"MISC_FLAG_RETREAT");
										else if((level.ex_flag_retreat & 4) == 4) player thread playerHudAnnounce(&"MISC_FLAG_RETREAT");
								if((level.ex_flag_retreat & 8) == 8) player playlocalsound("US_mcc_order_move_back");
							}
						}
					}
					else if((level.ex_flag_retreat & 16) == 16)
					{
						if( retreat_dist < (flag_dist + (flag_dist * 0.5)) )
						{
							if(player.retreatwarning)
							{
								player.retreatwarning--;
								if((level.ex_flag_retreat & 1) == 1) player iprintln(&"MISC_FLAG_BRINGIN");
									else if((level.ex_flag_retreat & 2) == 2) player iprintlnbold(&"MISC_FLAG_BRINGIN");
										else if((level.ex_flag_retreat & 4) == 4) player thread playerHudAnnounce(&"MISC_FLAG_BRINGIN");
								if((level.ex_flag_retreat & 8) == 8) player playlocalsound("US_mcc_order_move_back");
							}
						}
					}
				}
				else player.retreatwarning = 3;
			}
		}

		// 5 seconds delay after announcements
		if(retreat_team != "none") loop_delay = 5;
	}
}

getEnemyTeam(ownteam)
{
	if(ownteam == "axis") return("allies");
		else if(ownteam == "allies") return("axis");
			else return("none");
}

//------------------------------------------------------------------------------
// Bash mode or nade fest announcement
//------------------------------------------------------------------------------
modeAnnounceLevel()
{
	if(level.ex_bash_only && level.ex_bash_only_msg != 1 && level.ex_bash_only_msg != 4 && level.ex_bash_only_msg != 5) return;
	if(level.ex_frag_fest && level.ex_frag_fest_msg != 1 && level.ex_frag_fest_msg != 4 && level.ex_frag_fest_msg != 5) return;

	hud_index = levelHudCreate("announcer_mode_level", undefined, 0-20, 20, 1, (1,1,1), 1.3, 0, "right", "top", "right", "top", false, false);
	if(hud_index == -1) return;
	levelHudSetText(hud_index, level.ex_specialmodemsg);
}

modeAnnouncePlayer()
{
	self endon("kill_thread");

	if(level.ex_bash_only && (level.ex_bash_only_msg == 2 || level.ex_bash_only_msg == 4) && isDefined(self.ex_modeann)) return;
	if(level.ex_frag_fest && (level.ex_frag_fest_msg == 2 || level.ex_frag_fest_msg == 4) && isDefined(self.ex_modeann)) return;
	self.ex_modeann = true;

	hud_index = playerHudCreate("announcer_mode_player", 320, 120, 1, (1,1,1), 3, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	playerHudSetText(hud_index, level.ex_specialmodemsg);

	wait( [[level.ex_fpstime]](1.5) );

	playerHudFade(hud_index, 0.5, 0.5, 0);
	playerHudDestroy(hud_index);
}

//------------------------------------------------------------------------------
// Clan mode annoucement
//------------------------------------------------------------------------------
clanAnnounceLevel()
{
	if(level.ex_clanvsnonclan_msg != 1 && level.ex_clanvsnonclan_msg != 4 && level.ex_clanvsnonclan_msg != 5) return;

	hud_index = levelHudCreate("announcer_clan_level", undefined, 0-20, 35, 1, (1,1,1), 1.3, 0, "right", "top", "right", "top", false, false);
	if(hud_index == -1) return;
	levelHudSetText(hud_index, level.ex_clanmodemsg);
}

clanAnnouncePlayer()
{
	self endon("kill_thread");

	if( (level.ex_clanvsnonclan_msg == 2 || level.ex_clanvsnonclan_msg == 4) && isDefined(self.ex_clanann) ) return;
	self.ex_clanann = true;

	hud_index = playerHudCreate("announcer_clan_player", 320, 150, 1, (1,1,1), 3, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	playerHudSetText(hud_index, level.ex_clanmodemsg);

	wait( [[level.ex_fpstime]](1.5) );

	playerHudFade(hud_index, 0.5, 0.5, 0);
	playerHudDestroy(hud_index);
}

//------------------------------------------------------------------------------
// End-round routine
//------------------------------------------------------------------------------
onRoundOver()
{
	// nothing yet
}

//------------------------------------------------------------------------------
// End-map routine
//------------------------------------------------------------------------------
onGameOver()
{
	// handle mbots
	if(level.ex_mbot) spectateBots();

	// prepare players for intermission
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player)) continue;

		// stop pain sounds by restoring health
		player.health = player.maxhealth;

		// drop flag
		player extreme\_ex_main_utils::dropTheFlag(true);

		// close and set menu
		player setClientCvar("g_scriptMainMenu", "");
		player closeMenu();
		player closeInGameMenu();

		// init end-of-game music
		player playLocalSound("spec_music_null");

		// move to spectators
		player thread extreme\_ex_player_spawn::spawnSpectator();

		// set spectate permissions
		player allowSpectateTeam("allies", false);
		player allowSpectateTeam("axis", false);
		player allowSpectateTeam("freelook", false);
		player allowSpectateTeam("none", true);

		// restore status icon
		player playerHudRestoreStatusIcon();
	}

	// end-of-game music start
	if(level.ex_endmusic) level thread exEndMapMusic();
}

exEndMap()
{
	// launch statsboard
	if(level.ex_stbd) extreme\_ex_stats_board::main();

	// if player based map rotation is enabled and map voting is disabled, change the rotation
	if(level.ex_pbrotate && !level.ex_mapvote) extreme\_ex_main_rotation::pbRotation();

	// check if we have a next map set by RCON
	nextmap = getCvar("ex_nextmap");
	if(nextmap != "")
	{
		setCvar("ex_nextmap", "");
		setCvar("saved_maprotationcurrent", getCvar("sv_maprotationcurrent"));
		setCvar("sv_maprotationcurrent", "map " + nextmap);
	}
	else
	{
		// launch mapvote
		if(level.ex_mapvote) extreme\_ex_main_mapvote::main();
		else
		{
			// check if we have to skip the next map (RCON)
			skipmap = getCvar("ex_skipmap");
			if(skipmap != "")
			{
				setCvar("ex_skipmap", "");
				extreme\_ex_main_rotation::defNextMap(true);
			}
		}
	}

	// report DRM requests
	extreme\_ex_varcache_drm::drm_report();

	// fade the end-of-game music during intermission
	level notify("endmusic");

	// save the number of players for map sizing in DRM
	setCvar("drm_players", level.players.size);
}

spectateBots()
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isPlayer(player) && isDefined(player.pers["isbot"]))
			player thread extreme\_ex_main_bots::botJoin("spectator");
	}
}

disconnectBots()
{
	bot_entities = [];
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isPlayer(players[i]) && isDefined(players[i].pers["isbot"]))
		{
			bot_entity = players[i] getEntityNumber();
			bot_entities[bot_entities.size] = bot_entity;
			kick(bot_entity);
			wait( level.ex_fps_frame );
		}
	}

	if(bot_entities.size)
	{
		entities = getEntArray();
		for(i = 0; i < level.ex_maxclients; i++)
		{
			for(j = 0; j < bot_entities.size; j++)
			{
				if(i == bot_entities[j])
					entities[i] = undefined;
			}
		}
	}
}

exEndMapMusic()
{
	// play random track
	musicplay("gom_music_" + (randomInt(10) + 1));

	// wait here till stats and mapvote are done
	level waittill("endmusic");
	
	// wait for intermission time minus music fade time
	music_fade = 5;
	if(music_fade > level.ex_intermission) music_fade = level.ex_intermission;
	wait( [[level.ex_fpstime]](level.ex_intermission - music_fade) );

	// fade music in last 5 seconds
	musicstop(music_fade);
	wait( [[level.ex_fpstime]](music_fade) );
}
