#include extreme\_ex_controller_hud;

main()
{
	level.callbackStartGameType = ::Callback_StartGameType;
	level.callbackPlayerConnect = ::Callback_PlayerConnect;
	level.callbackPlayerDisconnect = ::Callback_PlayerDisconnect;
	level.callbackPlayerDamage = ::Callback_PlayerDamage;
	level.callbackPlayerKilled = ::Callback_PlayerKilled;
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();

	level.autoassign = extreme\_ex_main_clientcontrol::menuAutoAssign;
	level.allies = extreme\_ex_main_clientcontrol::menuAllies;
	level.axis = extreme\_ex_main_clientcontrol::menuAxis;
	level.spectator = extreme\_ex_main_clientcontrol::menuSpectator;
	level.weapon = extreme\_ex_main_clientcontrol::menuWeapon;
	level.secweapon = extreme\_ex_main_clientcontrol::menuSecWeapon;
	level.spawnplayer = ::spawnplayer;
	level.respawnplayer = ::respawn;
	level.updatetimer = ::updatetimer;
	level.endgameconfirmed = ::endMap;
	level.checkscorelimit = ::checkScoreLimit;

	// set eXtreme+ variables and precache
	extreme\_ex_varcache::main();
}

Callback_StartGameType()
{
	// defaults if not defined in level script
	if(!isDefined(game["allies"])) game["allies"] = "american";
	if(!isDefined(game["axis"])) game["axis"] = "german";

	// server cvar overrides
	if(level.game_allies != "") game["allies"] = level.game_allies;
	if(level.game_axis != "") game["axis"] = level.game_axis;

	level.compassflag_allies = "compass_flag_" + game["allies"];
	level.compassflag_axis = "compass_flag_" + game["axis"];
	level.objpointflag_allies = "objpoint_flagpatch1_" + game["allies"];
	level.objpointflag_axis = "objpoint_flagpatch1_" + game["axis"];
	level.objpointflagmissing_allies = "objpoint_flagmissing_" + game["allies"];
	level.objpointflagmissing_axis = "objpoint_flagmissing_" + game["axis"];
	level.hudflag_allies = "compass_flag_" + game["allies"];
	level.hudflag_axis = "compass_flag_" + game["axis"];

	switch(game["allies"])
	{
		case "american":
			game["flag_taken"] = "US_mp_flagtaken";
			break;
		case "british":
			game["flag_taken"] = "UK_mp_flagtaken";
			break;
		default:
			game["flag_taken"] = "RU_mp_flagtaken";
			break;
	}

	if(!isDefined(game["precachedone"]))
	{
		[[level.ex_PrecacheRumble]]("damage_heavy");
		if(!level.ex_rank_statusicons)
		{
			[[level.ex_PrecacheStatusIcon]]("hud_status_dead");
			[[level.ex_PrecacheStatusIcon]]("hud_status_connecting");
		}
		if(!level.ex_rank_statusicons)
		{
			[[level.ex_PrecacheStatusIcon]](level.hudflag_allies);
			[[level.ex_PrecacheStatusIcon]](level.hudflag_axis);
		}
		[[level.ex_PrecacheShader]](level.compassflag_allies);
		[[level.ex_PrecacheShader]](level.compassflag_axis);
		[[level.ex_PrecacheShader]](level.objpointflag_allies);
		[[level.ex_PrecacheShader]](level.objpointflag_axis);
		[[level.ex_PrecacheShader]](level.hudflag_allies);
		[[level.ex_PrecacheShader]](level.hudflag_axis);
		[[level.ex_PrecacheShader]](level.objpointflag_allies);
		[[level.ex_PrecacheShader]](level.objpointflag_axis);
		[[level.ex_PrecacheShader]](level.objpointflagmissing_allies);
		[[level.ex_PrecacheShader]](level.objpointflagmissing_axis);
		[[level.ex_PrecacheModel]]("xmodel/prop_flag_" + game["allies"]);
		[[level.ex_PrecacheModel]]("xmodel/prop_flag_" + game["axis"]);
		[[level.ex_PrecacheModel]]("xmodel/prop_flag_" + game["allies"] + "_carry");
		[[level.ex_PrecacheModel]]("xmodel/prop_flag_" + game["axis"] + "_carry");
		[[level.ex_PrecacheString]](&"MP_TIME_TILL_SPAWN");
		[[level.ex_PrecacheString]](&"PLATFORM_PRESS_TO_SPAWN");
	}

	thread maps\mp\gametypes\_menus::init();
	thread maps\mp\gametypes\_serversettings::init();
	thread maps\mp\gametypes\_clientids::init();
	thread maps\mp\gametypes\_teams::init();
	thread maps\mp\gametypes\_weapons::init();
	thread maps\mp\gametypes\_scoreboard::init();
	thread maps\mp\gametypes\_killcam::init();
	thread maps\mp\gametypes\_shellshock::init();
	thread maps\mp\gametypes\_hud_teamscore::init();
	thread maps\mp\gametypes\_deathicons::init();
	thread maps\mp\gametypes\_damagefeedback::init();
	thread maps\mp\gametypes\_healthoverlay::init();
	thread maps\mp\gametypes\_friendicons::init();
	thread maps\mp\gametypes\_spectating::init();
	thread maps\mp\gametypes\_grenadeindicators::init();
	thread maps\mp\gametypes\_quickmessages::init();
	extreme\_ex_varcache::mainPost();

	game["precachedone"] = true;
	setClientNameMode("auto_change");

	spawnpointname = "mp_ctf_spawn_allied";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		spawnpoints = getentarray(spawnpointname, "targetname");
		if(!spawnpoints.size)
		{
			maps\mp\gametypes\_callbacksetup::AbortLevel();
			return;
		}
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	spawnpointname = "mp_ctf_spawn_axis";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		spawnpoints = getentarray(spawnpointname, "targetname");
		if(!spawnpoints.size)
		{
			maps\mp\gametypes\_callbacksetup::AbortLevel();
			return;
		}
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] PlaceSpawnpoint();

	allowed[0] = "ctf";
	maps\mp\gametypes\_gameobjects::main(allowed);

	level.mapended = false;

	game["matchpaused"] = 0;
	if(!isDefined(game["matchovertime"])) game["matchovertime"] = 0;
	if(!isDefined(game["state"])) game["state"] = "playing";

	level.starttime = getTime();
	if(!level.ex_readyup || (level.ex_readyup && isDefined(game["readyup_done"])) )
	{
		thread initFlags();
		thread startGame();
		thread updateGametypeCvars();
	}

	// launch eXtreme+
	extreme\_ex_main::main();
}

dummy()
{
	waittillframeend;
	if(isDefined(self)) level notify("connecting", self);
}

Callback_PlayerConnect()
{
	thread dummy();

	playerHudSetStatusIcon("hud_status_connecting");
	self waittill("begin");
	self.statusicon = "";

	level notify("connected", self);
	self waittill("events_initialized");

	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	logPrint("J;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");

	if(game["state"] == "intermission")
	{
		extreme\_ex_player_spawn::spawnIntermission();
		return;
	}

	level endon("intermission");

	if(level.mapended)
	{
		extreme\_ex_player_spawn::spawnPreIntermission();
		return;
	}

	scriptMainMenu = game["menu_ingame"];

	if(isDefined(self.pers["team"]) && self.pers["team"] != "spectator")
	{
		self setClientCvar("ui_allow_weaponchange", "1");

		if(self.pers["team"] == "allies")
			self.sessionteam = "allies";
		else
			self.sessionteam = "axis";

		// Fix for spectate problem
		self maps\mp\gametypes\_spectating::setSpectatePermissions();

		if(isDefined(self.pers["weapon"]))
		{
			spawnPlayer();
		}
		else
		{
			extreme\_ex_player_spawn::spawnspectator();

			if(self.pers["team"] == "allies")
			{
				self openMenu(game["menu_weapon_allies"]);
				scriptMainMenu = game["menu_weapon_allies"];
			}
			else
			{
				self openMenu(game["menu_weapon_axis"]);
				scriptMainMenu = game["menu_weapon_axis"];
			}
		}
	}
	else
	{
		self setClientCvar("ui_allow_weaponchange", "0");

		if(!isDefined(self.pers["skipserverinfo"]))
		{
			extreme\_ex_main_clientcontrol::exPlayerPreServerInfo();
			self openMenu(game["menu_serverinfo"]);
			self.pers["skipserverinfo"] = true;
		}

		self.pers["team"] = "spectator";
		self.sessionteam = "spectator";

		extreme\_ex_player_spawn::spawnspectator();
	}

	self setClientCvar("g_scriptMainMenu", scriptMainMenu);
}

Callback_PlayerDisconnect()
{
	self dropFlag();

	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	logPrint("Q;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");
}

Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if(self.sessionteam == "spectator" || self.ex_invulnerable) return;
	if(game["matchpaused"]) return;

	friendly = undefined;

	// Don't do knockback if the damage direction was not specified
	if(!isDefined(vDir)) iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

	// check for completely getting out of the damage
	if(!(iDFlags & level.iDFLAGS_NO_PROTECTION))
	{
		if(isPlayer(eAttacker) && (self != eAttacker) && (self.pers["team"] == eAttacker.pers["team"]))
		{
			if(level.friendlyfire == "0")
			{
				return;
			}
			else if(level.friendlyfire == "1")
			{
				// Make sure at least one point of damage is done
				if(iDamage < 1) iDamage = 1;

				self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				self playrumble("damage_heavy");
			}
			else if(level.friendlyfire == "2")
			{
				eAttacker.friendlydamage = true;

				iDamage = int(iDamage * level.ex_friendlyfire_reflect);

				// Make sure at least one point of damage is done
				if(iDamage < 1) iDamage = 1;

				eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				eAttacker.friendlydamage = undefined;
				eAttacker thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				eAttacker playrumble("damage_heavy");

				friendly = 1;
			}
			else if(level.friendlyfire == "3")
			{
				eAttacker.friendlydamage = true;

				iDamage = int(iDamage * .5);

				// Make sure at least one point of damage is done
				if(iDamage < 1) iDamage = 1;

				self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				self playrumble("damage_heavy");

				eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				eAttacker.friendlydamage = undefined;
				eAttacker thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				eAttacker playrumble("damage_heavy");

				friendly = 2;
			}
		}
		else
		{
			// Make sure at least one point of damage is done
			if(iDamage < 1) iDamage = 1;

			self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
			self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
			self playrumble("damage_heavy");
		}

		if(isDefined(eAttacker) && eAttacker != self) eAttacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback();
	}

	// Do debug print if it's enabled
	if(getCvarInt("g_debugDamage"))
	{
		println("client:" + self getEntityNumber() + " health:" + self.health +
			" damage:" + iDamage + " hitLoc:" + sHitLoc);
	}

	if(level.ex_log_damage && self.sessionstate != "dead")
	{
		lpselfguid = self getGuid();
		lpselfnum = self getEntityNumber();
		lpselfteam = self.pers["team"];
		lpselfname = self.name;

		if(isPlayer(eAttacker))
		{
			lpattackguid = eAttacker getGuid();
			lpattacknum = eAttacker getEntityNumber();
			lpattackteam = eAttacker.pers["team"];
			lpattackname = eAttacker.name;
		}
		else
		{
			lpattackguid = "";
			lpattacknum = -1;
			lpattackteam = "world";
			lpattackname = "";
		}

		if(!isDefined(friendly) || friendly == 2)
			logPrint("D;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

		if(isDefined(friendly) && eAttacker.sessionstate != "dead")
		{
			lpselfguid = lpattackguid;
			lpselfnum = lpattacknum;
			lpselfname = lpattackname;
			logPrint("D;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");
		}
	}
}

Callback_PlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	self endon("spawned");
	self notify("killed_player");

	if(self.sessionteam == "spectator") return;
	if(game["matchpaused"]) return;

	// If the player was killed by a head shot, let players know it was a head shot kill
	if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE") sMeansOfDeath = "MOD_HEAD_SHOT";

	// get confirmed kill status
	self.ex_confirmkill = self extreme\_ex_main_killconfirmed::kcCheck(attacker, sMeansOfDeath, sWeapon);

	// handle eXtreme features related to kills
	self thread extreme\_ex_player::exPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	self maps\mp\gametypes\_weapons::dropWeapon();
	self maps\mp\gametypes\_weapons::dropOffhand();

	flagrunner = false;
	if(isDefined(self.flag))
	{
		flagrunner = true;
		self dropFlag();
	}

	self.sessionstate = "dead";
	playerHudSetStatusIcon("hud_status_dead");
	self.dead_origin = self.origin;
	self.dead_angles = self.angles;

	if(!isDefined(self.switching_teams) && !self.ex_confirmkill)
	{
		self.pers["death"]++;
		self.deaths = self.pers["death"];
	}

	lpselfguid = self getGuid();
	lpselfnum = self getEntityNumber();
	lpselfteam = self.pers["team"];
	lpselfname = self.name;

	if(isPlayer(attacker))
	{
		if(attacker == self) // killed himself
		{
			lpattackguid = lpselfguid;
			lpattacknum = lpselfnum;
			lpattackteam = lpselfteam;
			lpattackname = lpselfname;
			doKillcam = false;

			// switching teams
			if(isDefined(self.switching_teams))
			{
				if((self.leaving_team == "allies" && self.joining_team == "axis") || (self.leaving_team == "axis" && self.joining_team == "allies"))
				{
					players = maps\mp\gametypes\_teams::CountPlayers();
					players[self.leaving_team]--;
					players[self.joining_team]++;

					if((players[self.joining_team] - players[self.leaving_team]) > 1) self thread [[level.ex_scorePlayer]](-1);
				}
			}

			if(isDefined(attacker.friendlydamage)) attacker iprintln(&"MP_FRIENDLY_FIRE_WILL_NOT");
		}
		else
		{
			lpattackguid = attacker getGuid();
			lpattacknum = attacker getEntityNumber();
			lpattackteam = attacker.pers["team"];
			lpattackname = attacker.name;
			doKillcam = true;

			// Check if reward points should be given for bash or headshot
			reward_points = 0;
			if(isDefined(sMeansOfDeath))
			{
				if(sMeansOfDeath == "MOD_MELEE") reward_points = level.ex_reward_melee;
					else if(sMeansOfDeath == "MOD_HEAD_SHOT") reward_points = level.ex_reward_headshot;
			}

			// Check if extra points should be given for GT specific achievement
			if(flagrunner) reward_points += level.ex_ctfpoints_playerkf;

			points = level.ex_points_kill + reward_points;

			if(self.pers["team"] == lpattackteam) // killed by a friendly
			{
				if(level.ex_reward_teamkill) attacker thread [[level.ex_scorePlayer]](0 - points);
					else attacker thread [[level.ex_scorePlayer]](0 - level.ex_points_kill);
			}
			else
			{
				if(self.ex_confirmkill)
				{
					if(level.ex_kc_pdistr == 1)
					{
						kc_points = level.ex_points_kill;
						kc_reward = 0;
						points = reward_points;
					}
					else if(level.ex_kc_pdistr == 2)
					{
						kc_points = 0;
						kc_reward = reward_points;
						points = level.ex_points_kill;
						reward_points = 0;
					}
					else if(level.ex_kc_pdistr == 3)
					{
						kc_points = 0;
						kc_reward = level.ex_kc_confirmed_bonus;
					}
					else
					{
						kc_points = level.ex_points_kill;
						kc_reward = reward_points;
						points = 0;
						reward_points = 0;
					}

					self thread extreme\_ex_main_killconfirmed::kcMain(kc_points, kc_reward, false, attacker);
				}

				attacker thread [[level.ex_scorePlayer]](points, "bonus", reward_points);
			}
		}
	}
	else // If you weren't killed by a player, you were in the wrong place at the wrong time
	{
		lpattackguid = "";
		lpattacknum = -1;
		lpattackteam = "world";
		lpattackname = "";
		doKillcam = false;

		self thread [[level.ex_scorePlayer]](-1);
	}

	logPrint("K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

	// Stop thread if map ended on this death
	if(level.mapended) return;

	if(isDefined(self.switching_teams))
		self.ex_team_changed = true;

	self.switching_teams = undefined;
	self.joining_team = undefined;
	self.leaving_team = undefined;

	body = self cloneplayer(deathAnimDuration);
	thread maps\mp\gametypes\_deathicons::addDeathicon(body, self.clientid, self.pers["team"], 5);

	if(game["matchovertime"] && level.ex_overtime_lastman)
	{
		level checkTeamStatus();
		if(!level.exist[self.pers["team"]]) return;
	}

	delay = 2; // Delay the player becoming a spectator till after he's done dying
	if(isDefined(self.spawned))
	{
		self thread respawn_staydead(delay);
	}
	else if(level.respawndelay) self thread respawn_timer(delay);
	wait( [[level.ex_fpstime]](delay) ); // Also required for Callback_PlayerKilled to complete before killcam can execute

	if(doKillcam && level.killcam)
		self maps\mp\gametypes\_killcam::killcam(lpattacknum, delay, psOffsetTime, level.respawndelay);

	self thread respawn();
}

spawnPlayer()
{
	self endon("disconnect");
	self notify("spawned");
	self notify("end_respawn");

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	if(game["matchovertime"] && level.ex_overtime_lastman) self.spawned = true;

	self.sessionteam = self.pers["team"];
	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;
	self.statusicon = "";
	self.maxhealth = level.ex_player_maxhealth;
	self.health = self.maxhealth;
	self.dead_origin = undefined;
	self.dead_angles = undefined;

	self extreme\_ex_player::initPreSpawn();

	if(self.pers["team"] == "allies") spawnpointname = "mp_ctf_spawn_allied";
		else spawnpointname = "mp_ctf_spawn_axis";

	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);

	if(isDefined(spawnpoint)) self extreme\_ex_player::spawnPlayer(spawnpoint);
		else maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");

	if(!isDefined(self.pers["savedmodel"])) extreme\_ex_main_models::getModel();
		else extreme\_ex_main_models::loadModel(self.pers["savedmodel"]);

	extreme\_ex_weapons::loadout();

	if(game["scorelimit"] > 0) self setClientCvar("cg_objectiveText", &"MP_CTF_OBJ_TEXT", game["scorelimit"]);
		else self setClientCvar("cg_objectiveText", &"MP_CTF_OBJ_TEXT_NOSCORE");

	self thread updateTimer();

	waittillframeend;
	self extreme\_ex_player::initPostSpawn();
	self notify("spawned_player");
}

respawn(updtimer)
{
	self endon("disconnect");
	self endon("end_respawn");

	if(!isDefined(self.pers["weapon"])) return;

	if(level.ex_spectatedead || isDefined(self.spawned))
	{
		self.sessionteam = self.pers["team"];
		self.sessionstate = "spectator";

		if(isDefined(self.dead_origin) && isDefined(self.dead_angles))
		{
			origin = self.dead_origin + (0, 0, 16);
			angles = self.dead_angles;
		}
		else
		{
			origin = self.origin + (0, 0, 16);
			angles = self.angles;
		}

		self spawn(origin, angles);
	}

	if(!isDefined(updtimer)) updtimer = false;
	if(updtimer) self thread updateTimer();

	while(isDefined(self.WaitingToSpawn)) wait( level.ex_fps_frame );

	if(!level.forcerespawn)
	{
		self thread waitRespawnButton();
		self waittill("respawn");
	}

	self thread spawnPlayer();
}

startGame()
{
	if(game["timelimit"] > 0)
	{
		if(level.ex_swapteams)
		{
			createClock(game["halftimelimit"] * 60);
			if(game["halftime"] == 0) levelHudSetLabel("mainclock", &"MISC_CLOCK_1H");
				else levelHudSetLabel("mainclock", &"MISC_CLOCK_2H");
		}
		else createClock(game["timelimit"] * 60);
	}

	while(!level.ex_gameover)
	{
		checkTimeLimit();
		wait( [[level.ex_fpstime]](1) );
	}
}

endMap()
{
	level notify("game_ended");
	level notify("finish_staydead");

	alliedscore = getTeamScore("allies");
	axisscore = getTeamScore("axis");

	if(alliedscore == axisscore)
	{
		winningteam = "tie";
		losingteam = "tie";
	}
	else if(alliedscore > axisscore)
	{
		winningteam = "allies";
		losingteam = "axis";
	}
	else
	{
		winningteam = "axis";
		losingteam = "allies";
	}

	levelAnnounceWinner(winningteam);

	extreme\_ex_main::exEndMap();

	game["state"] = "intermission";
	level notify("intermission");

	winners = "";
	losers = "";
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(winningteam == "allies" || winningteam == "axis")
		{
			lpselfguid = player getGuid();
			if((isDefined(player.pers["team"])) && (player.pers["team"] == winningteam))
				winners = (winners + ";" + lpselfguid + ";" + player.name);
			else if((isDefined(player.pers["team"])) && (player.pers["team"] == losingteam))
				losers = (losers + ";" + lpselfguid + ";" + player.name);
		}

		player closeMenu();
		player closeInGameMenu();
		player extreme\_ex_player_spawn::spawnIntermission();
		player playerHudRestoreStatusIcon();
	}

	if(winningteam == "allies" || winningteam == "axis")
	{
		logPrint("W;" + winningteam + winners + "\n");
		logPrint("L;" + losingteam + losers + "\n");
	}

	wait( [[level.ex_fpstime]](level.ex_intermission) );

	level notify("restarting");
	wait( [[level.ex_fpstime]](1) );
	exitLevel(false);
}

checkTeamStatus()
{
	if(level.mapended) return;

	level.exist["allies"] = 0;
	level.exist["axis"] = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player)) continue;
		if(isDefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
			level.exist[player.pers["team"]]++;
	}

	if(game["matchpaused"]) return;

	if(!level.exist["allies"] && !level.exist["axis"])
	{
		iprintlnbold(&"MP_ALLPLAYERSHAVEBEENELIMINATED");
		level.mapended = true;
		level thread endMap();
		return;
	}

	if(!level.exist["allies"])
	{
		iprintlnbold(&"MP_ALLIESHAVEBEENELIMINATED");
		level thread [[level.ex_psop]]("mp_announcer_allieselim");
		thread [[level.ex_scoreTeam]]("axis", 1);
		return;
	}

	if(!level.exist["axis"])
	{
		iprintlnbold(&"MP_AXISHAVEBEENELIMINATED");
		level thread [[level.ex_psop]]("mp_announcer_axiselim");
		thread [[level.ex_scoreTeam]]("allies", 1);
		return;
	}
}

checkTimeLimit()
{
	if(game["timelimit"] <= 0) return;
	if(game["matchpaused"]) return;

	timepassed = (getTime() - level.starttime) / 1000;
	timepassed = timepassed / 60.0;

	if(level.ex_swapteams && !game["matchovertime"])
	{
		if(timepassed < game["halftimelimit"]) return;

		if(game["halftime"] == 0)
		{
			thread extreme\_ex_gametype::swapTeams(::returnFlag);
			return;
		}
	}
	else if(timepassed < game["timelimit"]) return;

	if(level.ex_overtime && !game["matchovertime"])
	{
		if(getTeamScore("allies") == getTeamScore("axis"))
		{
			thread extreme\_ex_gametype::startOvertime(::returnFlag);
			return;
		}
	}

	if(level.mapended) return;
	level.mapended = true;

	iprintln(&"MP_TIME_LIMIT_REACHED");

	level thread endMap();
}

checkScoreLimit()
{
	if(game["scorelimit"] <= 0) return;
	if(game["matchpaused"]) return;

	if(level.ex_bestof)
	{
		if(getTeamScore("allies") < level.bestoflimit && getTeamScore("axis") < level.bestoflimit) return;
	}
	else if(getTeamScore("allies") < game["scorelimit"] && getTeamScore("axis") < game["scorelimit"]) return;

	if(level.mapended) return;
	level.mapended = true;

	iprintln(&"MP_SCORE_LIMIT_REACHED");

	level thread endMap();
}

updateGametypeCvars()
{
	while(!level.ex_gameover && !game["matchpaused"] && !game["matchovertime"])
	{
		timelimit = getCvarFloat("scr_ctf_timelimit");
		if(game["timelimit"] != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_ctf_timelimit", "1440");
			}

			if(timelimit < game["timelimit"])
			{
				timepassed = 0;
				level.starttime = getTime();
			}
			else timepassed = ((getTime() - level.starttime) / 1000) / 60.0;

			game["timelimit"] = timelimit;
			setCvar("ui_timelimit", game["timelimit"]);

			if(game["timelimit"] > 0)
			{
				if(level.ex_swapteams)
				{
					game["halftimelimit"] = game["timelimit"] / 2;
					halftimelimit = game["halftimelimit"] - timepassed;
					createClock(halftimelimit * 60);
					if(game["halftime"] == 0) levelHudSetLabel("mainclock", &"MISC_CLOCK_1H");
						else levelHudSetLabel("mainclock", &"MISC_CLOCK_2H");
				}
				else
				{
					timelimit = game["timelimit"] - timepassed;
					createClock(timelimit * 60);
				}

				checkTimeLimit();
			}
			else destroyClock();
		}

		scorelimit = getCvarInt("scr_ctf_scorelimit");
		if(game["scorelimit"] != scorelimit)
		{
			game["scorelimit"] = scorelimit;
			setCvar("ui_scorelimit", game["scorelimit"]);

			checkScoreLimit();
		}

		wait( [[level.ex_fpstime]](1) );
	}
}

initFlags()
{
	maperrors = [];

	allied_flags = getentarray("allied_flag", "targetname");
	if(allied_flags.size < 1)
		maperrors[maperrors.size] = "^1No entities found with \"targetname\" \"allied_flag\"";
	else if(allied_flags.size > 1)
		maperrors[maperrors.size] = "^1More than 1 entity found with \"targetname\" \"allied_flag\"";

	axis_flags = getentarray("axis_flag", "targetname");
	if(axis_flags.size < 1)
		maperrors[maperrors.size] = "^1No entities found with \"targetname\" \"axis_flag\"";
	else if(axis_flags.size > 1)
		maperrors[maperrors.size] = "^1More than 1 entity found with \"targetname\" \"axis_flag\"";

	if(maperrors.size)
	{
		println("^1------------ Map Errors ------------");
		for(i = 0; i < maperrors.size; i++)
			println(maperrors[i]);
		println("^1------------------------------------");

		return;
	}

	allied_flag = getent("allied_flag", "targetname");
	allied_flag.home_origin = allied_flag.origin;
	allied_flag.home_angles = allied_flag.angles;
	allied_flag.flagmodel = spawn("script_model", allied_flag.home_origin);
	allied_flag.flagmodel.angles = allied_flag.home_angles;
	allied_flag.flagmodel setmodel("xmodel/prop_flag_" + game["allies"]);
	allied_flag.basemodel = spawn("script_model", allied_flag.home_origin);
	allied_flag.basemodel.angles = allied_flag.home_angles;
	allied_flag.basemodel setmodel("xmodel/prop_flag_base");
	allied_flag.team = "allies";
	allied_flag.atbase = true;
	allied_flag.objective = 0;
	allied_flag.compassflag = level.compassflag_allies;
	allied_flag.objpointflag = level.objpointflag_allies;
	allied_flag.objpointflagmissing = level.objpointflagmissing_allies;
	allied_flag thread flag();
	if(level.ex_flagbase_anim_allies) allied_flag thread flagbaseAnimation(allied_flag.team, allied_flag.home_origin);

	axis_flag = getent("axis_flag", "targetname");
	axis_flag.home_origin = axis_flag.origin;
	axis_flag.home_angles = axis_flag.angles;
	axis_flag.flagmodel = spawn("script_model", axis_flag.home_origin);
	axis_flag.flagmodel.angles = axis_flag.home_angles;
	axis_flag.flagmodel setmodel("xmodel/prop_flag_" + game["axis"]);
	axis_flag.basemodel = spawn("script_model", axis_flag.home_origin);
	axis_flag.basemodel.angles = axis_flag.home_angles;
	axis_flag.basemodel setmodel("xmodel/prop_flag_base");
	axis_flag.team = "axis";
	axis_flag.atbase = true;
	axis_flag.objective = 1;
	axis_flag.compassflag = level.compassflag_axis;
	axis_flag.objpointflag = level.objpointflag_axis;
	axis_flag.objpointflagmissing = level.objpointflagmissing_axis;
	axis_flag thread flag();
	if(level.ex_flagbase_anim_axis) axis_flag thread flagbaseAnimation(axis_flag.team, axis_flag.home_origin);

	level.flags	= [];
	level.flags["allies"] = allied_flag;
	level.flags["axis"] = axis_flag;
}

flagbaseAnimation(team, origin)
{
	if(isDefined(self.fxlooper)) self.fxlooper delete();
	self.fxlooper = playLoopedFx(game["flagbase_anim_" + team], 1.6, origin + (0,0,level.ex_flagbase_anim_height), 0, vectorNormalize((origin + (0,0,100)) - origin));
}

flag()
{
	objective_add(self.objective, "current", self.origin, self.compassflag);
	self createFlagWaypoint();

	for(;;)
	{
		wait( level.ex_fps_frame );

		self waittill("trigger", other);

		// do not handle flag if match is paused
		if(game["matchpaused"]) continue;

		if(isPlayer(other) && isAlive(other) && (other.pers["team"] != "spectator"))
		{
			// prevent pick up after dropping it
			if(other meleeButtonPressed()) continue;

			// do not allow player in stealth mode to pick up flag
			if(level.ex_stealth && isDefined(other.ex_stealth)) continue;

			if(other.pers["team"] == self.team) // Touched by team
			{
				if(self.atbase)
				{
					if(isDefined(other.flag)) // Captured flag
					{
						if(self.team == "axis")
						{
							enemy = "allies";
							if((level.ex_flag_voiceover & 2) == 2) level thread [[level.ex_psop]]("GE_mp_flagcap");
						}
						else
						{
							enemy = "axis";
							if((level.ex_flag_voiceover & 2) == 2) level thread [[level.ex_psop]]("mp_announcer_axisflagcap");
						}

						level thread [[level.ex_psop]]("ctf_touchcapture", self.team);
						level thread [[level.ex_psop]]("ctf_enemy_touchcapture", enemy);

						thread printOnTeam(&"MP_CTFB_ENEMY_FLAG_CAPTURED", self.team, other);
						thread printOnTeam(&"MP_CTFB_YOUR_FLAG_WAS_CAPTURED", enemy, other);

						other.flag returnFlag();
						other detachFlag(other.flag);
						other.flag = undefined;
						other playerHudRestoreStatusIcon();

						lpselfnum = other getEntityNumber();
						lpselfguid = other getGuid();
						logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + other.pers["team"] + ";" + other.name + ";" + "ctf_captured" + "\n");

						other.pers["flagcap"]++;
						other thread [[level.ex_scorePlayer]](level.ex_ctfpoints_playercf, "special");
						thread [[level.ex_scoreTeam]](other.pers["team"], 1);

						if(level.ex_statshud) other thread extreme\_ex_stats_hud::showStatsHUD();
					}
				}
				else // Returned flag
				{
					if(self.team == "axis")
					{
						enemy = "allies";
						if((level.ex_flag_voiceover & 4) == 4) level thread [[level.ex_psop]]("mp_announcer_axisflagret");
					}
					else
					{
						enemy = "axis";
						if((level.ex_flag_voiceover & 4) == 4) level thread [[level.ex_psop]]("mp_announcer_alliedflagret");
					}

					level thread [[level.ex_psop]]("ctf_touchown", self.team);

					thread printOnTeam(&"MP_CTFB_YOUR_FLAG_WAS_RETURNED", self.team, other);

					self returnFlag();

					lpselfnum = other getEntityNumber();
					lpselfguid = other getGuid();
					logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + other.pers["team"] + ";" + other.name + ";" + "ctf_returned" + "\n");

					other.pers["flagret"]++;
					other thread [[level.ex_scorePlayer]](level.ex_ctfpoints_playerrf, "special");
				}
			}
			else if(other.pers["team"] != self.team) // Touched by enemy
			{
				if(self.team == "axis")
					enemy = "allies";
				else
					enemy = "axis";

				level thread [[level.ex_psop]]("ctf_touchenemy", self.team);
				level thread [[level.ex_psop]]("ctf_enemy_touchenemy", enemy);

				thread printOnTeam(&"MP_CTFB_YOUR_FLAG_WAS_TAKEN", self.team, other);
				thread printOnTeam(&"MP_CTFB_ENEMY_FLAG_TAKEN", enemy, other);

				if(self.atbase) // Stolen flag
				{
					if((level.ex_flag_voiceover & 1) == 1)
					{
						if(self.team == "axis")
							level thread [[level.ex_psop]](game["flag_taken"]);
						else
							level thread [[level.ex_psop]]("GE_mp_flagtaken");
					}

					lpselfnum = other getEntityNumber();
					lpselfguid = other getGuid();
					logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + other.pers["team"] + ";" + other.name + ";" + "ctf_take" + "\n");

					other thread [[level.ex_scorePlayer]](level.ex_ctfpoints_playersf, "special");
				}
				else // Picked up flag
				{
					lpselfnum = other getEntityNumber();
					lpselfguid = other getGuid();
					logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + other.pers["team"] + ";" + other.name + ";" + "ctf_pickup" + "\n");

					if(!isDefined(other.flagDropped))
						other thread [[level.ex_scorePlayer]](level.ex_ctfpoints_playertf, "special");
				}

				other pickupFlag(self);
			}
		}
	}
}

pickupFlag(flag)
{
	self endon("disconnect");

	flag notify("end_autoreturn");

	flag.origin = flag.origin + (0, 0, -10000);
	flag.flagmodel hide();
	self.flag = flag;

	if(self.pers["team"] == "allies") playerHudSetStatusIcon(level.hudflag_axis);
		else if(self.pers["team"] == "axis") playerHudSetStatusIcon(level.hudflag_allies);

	self.dont_auto_balance = true;

	flag deleteFlagWaypoint();
	flag createFlagMissingWaypoint();

	objective_onEntity(self.flag.objective, self);
	objective_team(self.flag.objective, self.pers["team"]);

	self attachFlag();
}

dropFlag(dropspot)
{
	if(isDefined(self.flag))
	{
		if(isDefined(dropspot)) start = dropspot + (0, 0, 10);
			else start = self.origin + (0, 0, 10);
		end = start + (0, 0, -10000);
		trace = bulletTrace(start, end, false, undefined);

		self.flag.origin = trace["position"];
		self.flag.flagmodel.origin = self.flag.origin;
		self.flag.flagmodel show();
		self.flag.atbase = false;
		playerHudRestoreStatusIcon();

		objective_position(self.flag.objective, self.flag.origin);
		objective_team(self.flag.objective, "none");

		self.flag createFlagWaypoint();
		self.flag thread autoReturn();
		self detachFlag(self.flag);

		// check if it's in a flag returner
		for(i = 0; i < level.ex_returners.size; i++)
		{
			if(self.flag.flagmodel istouching(level.ex_returners[i]))
			{
				self.flag returnFlag();
				break;
			}
		}

		if((level.ex_flag_voiceover & 8) == 8)
		{
			if(self.flag.team == "axis")
				level thread [[level.ex_psop]]("mp_announcer_axisflagdrop");
			else
				level thread [[level.ex_psop]]("mp_announcer_alliedflagdrop");
		}

		self.flag = undefined;
		self.dont_auto_balance = undefined;
	}
}

returnFlag()
{
	self notify("end_autoreturn");

	if(level.ex_flag_drop)
	{
		if(self.team == "axis") enemy = "allies";
			else enemy = "axis";
		level thread dropflagUntag(enemy);
	}

	self.origin = self.home_origin;
	self.flagmodel.origin = self.home_origin;
	self.flagmodel.angles = self.home_angles;
	self.flagmodel show();
	self.atbase = true;

	objective_position(self.objective, self.origin);
	objective_team(self.objective, "none");

	self createFlagWaypoint();
	self deleteFlagMissingWaypoint();
}

autoReturn()
{
	level endon("ex_gameover");
	self endon("end_autoreturn");

	wait( [[level.ex_fpstime]](level.flagautoreturndelay) );

	if(level.ex_gameover) announce_return = false;
		else announce_return = true;

	if(announce_return)
	{
		if(self.team == "axis")
		{
			level thread [[level.ex_psop]]("mp_announcer_axisflagret");
			iprintln(&"MP_CTFB_AUTO_RETURN", &"MP_DOWNTEAM");
		}
		else
		{
			level thread [[level.ex_psop]]("mp_announcer_alliedflagret");
			iprintln(&"MP_CTFB_AUTO_RETURN", &"MP_UPTEAM");
		}
	}

	self thread returnFlag();
}

attachFlag()
{
	self endon("disconnect");

	if(isDefined(self.flagAttached)) return;

	if(self.pers["team"] == "allies")
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";
	else
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";
	
	self attach(flagModel, "J_Spine4", true);
	self.flagAttached = true;
	
	self thread createHudIcon();
	if(level.ex_flag_drop) self thread dropFlagMonitor();
}

detachFlag(flag)
{
	self endon("disconnect");

	if(!isDefined(self.flagAttached)) return;

	if(flag.team == "allies")
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";
	else
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";
		
	self detach(flagModel, "J_Spine4");
	self.flagAttached = undefined;

	self thread deleteHudIcon();
}

dropFlagMonitor()
{
	level endon("ex_gameover");
	self endon("disconnect");

	while(isAlive(self) && isDefined(self.flagAttached))
	{
		if(self useButtonPressed() && self meleeButtonPressed())
		{
			dropspot = self extreme\_ex_main_utils::getDropSpot(100);
			if(isDefined(dropspot))
			{
				self.flagDropped = true;
				self dropFlag(dropspot);
				break;
			}
		}
		wait( level.ex_fps_frame );
	}
}

dropflagUntag(team)
{
	players = level.players;

	if(isDefined(team))
	{
		for(i = 0; i < players.size; i++)
		{
			if((isDefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
				players[i].flagDropped = undefined;
		}
	}
	else
	{
		for(i = 0; i < players.size; i++)
			players[i].flagDropped = undefined;
	}
}

createHudIcon()
{
	self endon("disconnect");

	hud_index = playerHudCreate("ctf_flagicon", 320, 30, 1, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index != -1)
	{
		iconSize = 40;
		if(self.pers["team"] == "allies")
			playerHudSetShader(hud_index, level.hudflag_axis, iconSize, iconSize);
		else
			playerHudSetShader(hud_index, level.hudflag_allies, iconSize, iconSize);

		self thread pulsateHudIcon(self.pers["team"]);
	}
}

pulsateHudIcon(team)
{
	self endon("kill_thread");
	self endon("delete_hud_flag");

	if(team == "allies")
		base = level.flags["axis"].home_origin;
	else
		base = level.flags["allies"].home_origin;

	basedist = distance(self.origin, base);
	lastdist = basedist;

	while(isAlive(self))
	{
		wait( [[level.ex_fpstime]](0.2) );

		basedist = distance(self.origin, base);
		if(basedist < lastdist)
		{
			playerHudSetAlpha("ctf_flagicon", 0);
			wait( [[level.ex_fpstime]](0.2) );
			playerHudSetAlpha("ctf_flagicon", 1);
		}

		lastdist = basedist;
	}
}

deleteHudIcon()
{
	self notify("delete_hud_flag");

	playerHudDestroy("ctf_flagicon");
}

createFlagWaypoint()
{
	if(!level.ex_objindicator) return;

	self deleteFlagWaypoint();

	hud_index = levelHudCreate("waypoint_flag_" + self.team, undefined, self.origin[0], self.origin[1], .61, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, self.objpointflag, 7, 7);
	levelHudSetWaypoint(hud_index, self.origin[2] + 100, true);

	self.waypoint_flag = hud_index;
}

deleteFlagWaypoint()
{
	if(isDefined(self.waypoint_flag))
	{
		levelHudDestroy(self.waypoint_flag);
		self.waypoint_flag = undefined;
	}
}

createFlagMissingWaypoint()
{
	if(!level.ex_objindicator) return;

	self deleteFlagMissingWaypoint();

	hud_index = levelHudCreate("waypoint_flagmissing_" + self.team, undefined, self.home_origin[0], self.home_origin[1], .61, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, self.objpointflagmissing, 7, 7);
	levelHudSetWaypoint(hud_index, self.home_origin[2] + 100, true);

	self.waypoint_base = hud_index;
}

deleteFlagMissingWaypoint()
{
	if(isDefined(self.waypoint_base))
	{
		levelHudDestroy(self.waypoint_base);
		self.waypoint_base = undefined;
	}
}

printOnTeam(text, team, player)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if((isDefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
			players[i] iprintln(text, [[level.ex_pname]](player));
	}
}

respawn_timer(delay)
{
	self endon("disconnect");
	self endon("end_respawntimer");

	self.WaitingToSpawn = true;

	respawndelay = extreme\_ex_gametype::getRespawnDelay();

	hud_index = playerHudCreate("respawn_timer", 0, -50, 0, (1,1,1), 2, 0, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index != -1)
	{
		playerHudSetKeepOnKill(hud_index, true);
		playerHudSetLabel(hud_index, &"MP_TIME_TILL_SPAWN");
		playerHudSetTimer(hud_index, respawndelay + delay);
	}

	wait( [[level.ex_fpstime]](delay) );
	self thread updateTimer();

	wait( [[level.ex_fpstime]](respawndelay) );

	playerHudDestroy("respawn_timer");

	self.WaitingToSpawn = undefined;
}

respawn_staydead(delay)
{
	self endon("disconnect");

	if(isDefined(self.WaitingToSpawn)) return;
	self.WaitingToSpawn = true;

	wait( [[level.ex_fpstime]](delay) );

	hud_index = playerHudCreate("respawn_staydead", 0, -50, 1, (1,1,1), 2, 0, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index != -1)
	{
		playerHudSetKeepOnKill(hud_index, true);
		playerHudSetText(hud_index, &"MISC_OVERTIME_WAIT");
	}

	level waittill("finish_staydead");

	playerHudDestroy("respawn_staydead");

	self.WaitingToSpawn = undefined;
}

updateTimer()
{
	if(isDefined(self.pers["team"]) && (self.pers["team"] == "allies" || self.pers["team"] == "axis") && isDefined(self.pers["weapon"]))
		playerHudSetAlpha("respawn_timer", 1);
	else
		playerHudSetAlpha("respawn_timer", 0);
}

waitRespawnButton()
{
	self endon("disconnect");
	self endon("end_respawn");
	self endon("respawn");

	wait 0; // Required or the "respawn" notify could happen before it's waittill has begun

	hud_index = playerHudCreate("respawn_text", 0, -50, 1, (1,1,1), 2, 0, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index != -1) playerHudSetLabel(hud_index, &"PLATFORM_PRESS_TO_SPAWN");

	thread removeRespawnText();
	thread waitRemoveRespawnText("end_respawn");
	thread waitRemoveRespawnText("respawn");

	while(self useButtonPressed() != true) wait( level.ex_fps_frame );

	self notify("remove_respawntext");
	self notify("respawn");
}

removeRespawnText()
{
	self waittill("remove_respawntext");

	playerHudDestroy("respawn_text");
}

waitRemoveRespawnText(message)
{
	self endon("remove_respawntext");

	self waittill(message);
	self notify("remove_respawntext");
}
