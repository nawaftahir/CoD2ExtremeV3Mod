#include extreme\_ex_controller_hud;

/*------------------------------------------------------------------------------
Conquest TDM
Original Developers: innocent bystander, admin, after hourz
Port Over to COD2: Tally & UncleBone
Credits:
	* Mark 'Slyk' Dittman - Mapper extrodanaire and the initial developer of
		Conquest TDM on Spearhead.
	* [MC]Hammer - Some utility string transform code is incorporated, and his
		CoDaM HUD code was used and modified for this gametype.
	* The whole After Hourz community, but especially Painkiller, Fart, Shep,
		Kamikazee Driver, Poopybuttocks, and Shep for ideas, motivation and friendship.
	* Last but not least, many members of the COD community with help in learning this
		language and patiently answering my questions, including [MC]Hammer,
		ScorpioMidget, Ravir, [IW]HkySk8r187, and others I probably fail to mention.
------------------------------------------------------------------------------*/

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

blank(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
{
	wait(0);
}

Callback_StartGameType()
{
	// defaults if not defined in level script
	if(!isDefined(game["allies"])) game["allies"] = "american";
	if(!isDefined(game["axis"])) game["axis"] = "german";

	// server cvar overrides
	if(level.game_allies != "") game["allies"] = level.game_allies;
	if(level.game_axis != "") game["axis"] = level.game_axis;

	if(!isDefined(game["precachedone"]))
	{
		if(level.rbcnq_campaign_mode)
		{
			level.rbcnq_lastwinner = getCvar("scr_rbcnq_lastwinner");
			setCvar("scr_rbcnq_lastwinner", "");

			if(level.rbcnq_lastwinner != "")
			{
				if(level.rbcnq_lastwinner == "allies") // Last map winner attacks, loser defends
				{
					game["attackers"] = "allies";
					game["defenders"] = "axis";
				}
				else
				{
					game["attackers"] = "axis";
					game["defenders"] = "allies";
				}
			}
			else //they want campaign, but it's the first map
			{
				game["attackers"] = "allies";
				game["defenders"] = "axis";
			}
		}
		else
		{
			if(!isDefined(game["attackers"])) game["attackers"] = "allies";
			if(!isDefined(game["defenders"])) game["defenders"] = "axis";
		}
	}

	if(level.rbcnq_swap_roundwinner)
	{
		level.rbcnq_roundwinner = getCvar("scr_rbcnq_roundwinner");
		setCvar("scr_rbcnq_roundwinner", "");

		if(level.rbcnq_roundwinner != "")
		{
			if(level.rbcnq_roundwinner == "allies") // Last round winner attacks, loser defends
			{
				game["attackers"] = "allies";
				game["defenders"] = "axis";
			}
			else
			{
				game["attackers"] = "axis";
				game["defenders"] = "allies";
			}
		}
		else //they want to swap, but it's the first round
		{
			if(!isDefined(game["attackers"])) game["attackers"] = "allies";
			if(!isDefined(game["defenders"])) game["defenders"] = "axis";
		}
	}

	switch(game["allies"])
	{
		case "american":
			game["objecticon_allies"] = "hud_flag_american";
			game["objective_allies"] = "objective_american";
			game["allies_area_secured"] = "US_area_secured";
			game["allies_ground_taken"] = "US_ground_taken";
			game["allies_losing_ground"] = "US_losing_ground";
			break;
		case "british":
			game["objecticon_allies"] = "hud_flag_british";
			game["objective_allies"] = "objective_british";
			game["allies_area_secured"] = "UK_area_secured";
			game["allies_ground_taken"] = "UK_ground_taken";
			game["allies_losing_ground"] = "UK_losing_ground";
			break;
		default:
			game["objecticon_allies"] = "hud_flag_russian";
			game["objective_allies"] = "objective_russian";
			game["allies_area_secured"] = "RU_area_secured";
			game["allies_ground_taken"] = "RU_ground_taken";
			game["allies_losing_ground"] = "RU_losing_ground";
			break;
	}

	game["objecticon_axis"] = "hud_flag_german";
	game["objective_axis"] = "objective_german";
	game["german_area_secured"] = "GE_area_secured";
	game["german_ground_taken"] = "GE_ground_taken";
	game["german_losing_ground"] = "GE_losing_ground";

	if(!isDefined(game["rbcnq_attackers_obj_text"]))
	{
		if(game["attackers"] == "allies" )
			game["rbcnq_attackers_obj_text"] = (&"MP_KILL_AXIS_PLAYERS");
		else
			game["rbcnq_attackers_obj_text"] = (&"MP_KILL_ALLIED_PLAYERS");
	}

	if(!isDefined(game["rbcnq_defenders_obj_text"]))
	{
		if(game["defenders"] == "allies" )
			game["rbcnq_defenders_obj_text"] = (&"MP_KILL_AXIS_PLAYERS");
		else
			game["rbcnq_defenders_obj_text"] = (&"MP_KILL_ALLIED_PLAYERS");
	}

	if(!isDefined(game["rbcnq_neutral_obj_text"]))
		game["rbcnq_neutral_obj_text"] = (&"MP_ALLIES_KILL_AXIS_PLAYERS");

	if(!isDefined(game["precachedone"]))
	{
		[[level.ex_PrecacheRumble]]("damage_heavy");
		if(!level.ex_rank_statusicons)
		{
			[[level.ex_PrecacheStatusIcon]]("hud_status_dead");
			[[level.ex_PrecacheStatusIcon]]("hud_status_connecting");
		}
		[[level.ex_PrecacheShader]](game["objecticon_allies"]);
		[[level.ex_PrecacheShader]](game["objecticon_axis"]);
		[[level.ex_PrecacheString]](&"MP_TIME_TILL_SPAWN");
		[[level.ex_PrecacheString]](&"PLATFORM_PRESS_TO_SPAWN");
		[[level.ex_PrecacheString]](&"MP_CNQ_ACTIVATE_OBJECTIVE");
		[[level.ex_PrecacheString]](&"MP_CNQ_DEACTIVATE_OBJECTIVE");
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

	spawnpointname = "mp_tdm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	allowed[0] = "cnq";
	allowed[1] = "conquest";
	allowed[2] = "tdm";
	maps\mp\gametypes\_gameobjects::main(allowed);

	level.progressBarY = 104;
	level.progressBarHeight = 12;
	level.progressBarWidth = 192;

	level.roundended = false;
	level.mapended = false;
	level.exist["allies"] = 0;
	level.exist["axis"] = 0;
	level.allies_cap_count = 0;
	level.axis_cap_count = 0;
	level.axis_eliminated = undefined;
	level.allied_eliminated = undefined;

	level.objectivearray = [];
	level.objCount = [];
	level.objCount["attackers"] = 0;
	level.objCount["defenders"] = 0;

	game["matchpaused"] = 0;
	if(!isDefined(game["matchovertime"])) game["matchovertime"] = 0;
	if(!isDefined(game["matchstarted"])) game["matchstarted"] = false;
	if(!isDefined(game["timepassed"])) game["timepassed"] = 0;
	if(!isDefined(game["roundnumber"])) game["roundnumber"] = 0;
	if(!isDefined(game["roundsplayed"])) game["roundsplayed"] = 0;
	if(!isDefined(game["state"])) game["state"] = "playing";

	level.starttime = getTime();
	if(!level.ex_readyup || (level.ex_readyup && isDefined(game["readyup_done"])) )
	{
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
	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	logPrint("Q;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");

	level updateTeamStatus();
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

	if(!level.exist[self.pers["team"]]) // If the last player on a team was just killed, don't do killcam
	{
		doKillcam = false;
		self.skip_setspectatepermissions = true;
	}

	delay = 2; // Delay the player becoming a spectator till after he's done dying
	if(level.respawndelay) self thread respawn_timer(delay);
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

	// Handle ready-up spawn tickets
	if(level.ex_readyup == 2 && isDefined(game["readyup_done"]))
	{
		if(!isDefined(self.pers["readyup_spawnticket"]))
		{
			if(level.ex_readyup_status == 2 && level.ex_readyup_ticketing == 1)
				self.pers["readyup_spawnticket"] = 1;
			else if(level.ex_readyup_status == 3)
				self.pers["readyup_spawnticket"] = 1;
			else
			{
				self extreme\_ex_monitor_readyup::moveToSpectators();
				playerHudSetStatusIcon("hud_status_dead");
				self extreme\_ex_monitor_readyup::waitForNextRound();
				return;
			}
		}
	}

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

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

	spawnpointname = "mp_tdm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(isDefined(level.objectivearray))
	{
		locationToUse = level.rbcnq_initialobj;
		for(n = 0; n < level.objectivearray.size; n++)
		{
			spawnObjective = level.objectivearray[n];
			if(isOff(spawnObjective)) continue;
			locationToUse = spawnObjective.script_idnumber;
		}

		if(self.pers["team"] == game["attackers"]) teamRole = "attackers";
			else teamRole = "defenders";
		spawngroup = teamRole + locationToUse;
		spawnpoints = getentarray(spawngroup, "targetname");
		if(!isDefined(spawnpoints) || !spawnpoints.size) spawnpoints = getentarray(spawnpointname, "classname");
	}

	if(level.spawnmethod == "random")
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);
	else
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);

	if(isDefined(spawnpoint)) self extreme\_ex_player::spawnPlayer(spawnpoint);
		else maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");

	if(!isDefined(self.pers["savedmodel"])) extreme\_ex_main_models::getModel();
		else extreme\_ex_main_models::loadModel(self.pers["savedmodel"]);

	extreme\_ex_weapons::loadout();

	level updateTeamStatus();
	self setObjectiveTextAll();

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

	if(level.ex_spectatedead)
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

	self.spawned = undefined;
	
	for(;;)
	{	
		if(!isDefined(self.deathcount))
			self.deathcount = 0;
		
		self.deathcount++;
		
		if(self.deathcount <= level.spawnlimit)
		{
			if(!level.forcerespawn)
			{
				self thread waitRespawnButton();
				self waittill("respawn");
			}
			
			self thread spawnPlayer();
		}
		else
		{
			level updateTeamStatus();
			self.spawned = true;
			self thread extreme\_ex_player_spawn::spawnspectator();
		}
	
		wait( level.ex_fps_frame );
	}
}

startGame()
{
	thread startRound();
}

startRound()
{
	level endon("round_ended");

	game["matchstarted"] = true; // mainly to control UpdateTeamStatus
	game["roundnumber"]++;

	createClock(game["roundlength"] * 60);

	thread startHUD();
	thread startObjectives();
	thread sayObjective();
	
	level.allies_cap_count = 0;
	level.axis_cap_count = 0;

	wait( [[level.ex_fpstime]](game["roundlength"] * 60) );

	if(level.roundended) return;

	iprintln(&"MP_TIMEHASEXPIRED");

	if(!level.exist[game["attackers"]] || !level.exist[game["defenders"]])
	{
		level thread endRound("draw");
	}
	else
	{
		game["alliedscore"] = getTeamScore("allies");
		game["axisscore"] = getTeamScore("axis");

		if(game["alliedscore"] == game["axisscore"]) level thread endRound("draw");
			else if(game["alliedscore"] > game["axisscore"]) level thread endRound("allies");
				else level thread endRound("axis");
	}
}

resetScores()
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		player.pers["score"] = 0;
		player.pers["death"] = 0;
	}

	game["alliedscore"] = 0;
	setTeamScore("allies", game["alliedscore"]);
	game["axisscore"] = 0;
	setTeamScore("axis", game["axisscore"]);
}

endRound(roundwinner)
{
	if(level.roundended) return;
	level.roundended = true;

	level notify("round_ended");

	destroyClock();

	if(level.ex_readyup == 2)
	{
		players = level.players;
		for(i = 0; i < players.size; i++) players[i].pers["readyup_spawnticket"] = 1;
	}

	points = level.roundwin_points;

	if(roundwinner == "allies")
	{
		if(isDefined(level.axis_eliminated)) points += 5;
		GivePointsToTeam("allies", points);
	}
	else if(roundwinner == "axis")
	{
		if(isDefined(level.allied_eliminated)) points += 5;
		GivePointsToTeam("axis", points);
	}

	levelAnnounceWinner(roundwinner);

	game["roundsplayed"]++;
	checkRoundLimit();

	game["timepassed"] = game["timepassed"] + ((getTime() - level.starttime) / 1000) / 60.0;
	checkTimeLimit();

	if(level.mapended) return;

	if(level.rbcnq_swap_roundwinner)
	{
		if(roundwinner != "draw") setcvar("scr_rbcnq_roundwinner", roundwinner);
			else setcvar("scr_rbcnq_roundwinner", game["attackers"]);
	}

	iprintlnbold(&"MP_STARTING_NEW_ROUND");
	wait( [[level.ex_fpstime]](1) );

	if(level.reset_scores) thread resetScores();

	if(level.ex_swapteams == 1) extreme\_ex_gametype::swapTeams();
	else if(level.ex_swapteams == 2 && game["roundnumber"] == game["halftimelimit"]) extreme\_ex_gametype::swapTeams();
	else
	{
		level notify("restarting");
		wait( [[level.ex_fpstime]](1) );
		map_restart(true);
	}
}

endMap()
{
	level notify("game_ended");

	game["alliedscore"] = getTeamScore("allies");
	game["axisscore"] = getTeamScore("axis");

	if(game["alliedscore"] == game["axisscore"])
	{
		winningteam = "tie";
		losingteam = "tie";
	}
	else if(game["alliedscore"] > game["axisscore"])
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

	if(level.rbcnq_campaign_mode) 
	{
		if(winningteam != "tie") setcvar("scr_rbcnq_lastwinner", winningteam);
			else setcvar("scr_rbcnq_lastwinner", game["attackers"]);
	}

	wait( [[level.ex_fpstime]](level.ex_intermission) );

	exitLevel(false);
}

checkTimeLimit()
{
	if(game["timelimit"] <= 0) return;
	if(game["matchpaused"]) return;

	if(game["timepassed"] < game["timelimit"]) return;

	if(level.mapended) return;
	level.mapended = true;

	iprintln(&"MP_TIME_LIMIT_REACHED");

	level thread endMap();
}

checkScoreLimit()
{
	if(game["scorelimit"] <= 0) return;
	if(game["matchpaused"]) return;

	if(game["alliedscore"] < game["scorelimit"] && game["axisscore"] < game["scorelimit"]) return;

	if(level.mapended) return;
	level.mapended = true;

	iprintln(&"MP_SCORE_LIMIT_REACHED");

	level thread endMap();
}

checkRoundLimit()
{
	if(game["roundlimit"] <= 0) return;
	if(game["matchpaused"]) return;

	if(game["roundsplayed"] < game["roundlimit"]) return;

	if(level.mapended) return;
	level.mapended = true;

	iprintln(&"MP_ROUND_LIMIT_REACHED");

	level thread endMap();
}

updateGametypeCvars()
{
	while(!level.ex_gameover && !game["matchpaused"])
	{
		timelimit = getCvarFloat("scr_rbcnq_timelimit");
		if(game["timelimit"] != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_rbcnq_timelimit", "1440");
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
				//timelimit = game["timelimit"] - timepassed;
				//createClock(timelimit * 60);

				if(game["matchstarted"]) checkTimeLimit();
			}
			//else destroyClock();
		}

		scorelimit = getCvarInt("scr_rbcnq_scorelimit");
		if(game["scorelimit"] != scorelimit)
		{
			game["scorelimit"] = scorelimit;
			setCvar("ui_scorelimit", game["scorelimit"]);

			if(game["matchstarted"]) checkScoreLimit();
		}

		roundlimit = getCvarInt("scr_rbcnq_roundlimit");
		if(game["roundlimit"] != roundlimit)
		{
			game["roundlimit"] = roundlimit;
			setCvar("ui_roundlimit", game["roundlimit"]);

			if(level.ex_swapteams == 2 && game["roundnumber"] < game["halftimelimit"])
				game["halftimelimit"] = int((roundlimit / 2) + 0.5);

			if(game["matchstarted"]) checkRoundLimit();
		}

		wait( [[level.ex_fpstime]](1) );
	}
}

updateTeamStatus()
{
	wait 0; // Required for Callback_PlayerDisconnect to complete before updateTeamStatus can execute

	if(!game["matchstarted"]) return;

	resettimeout();

	oldvalue["allies"] = level.exist["allies"];
	oldvalue["axis"] = level.exist["axis"];
	level.exist["allies"] = 0;
	level.exist["axis"] = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isDefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
			level.exist[player.pers["team"]]++;
	}

	if(level.roundended || game["matchpaused"]) return;

	// if both allies and axis were alive and now they are both dead in the same instance
	if(oldvalue["allies"] && !level.exist["allies"] && oldvalue["axis"] && !level.exist["axis"])
	{
		iprintln(&"MP_ROUNDDRAW");
		level thread endRound("draw");
		return;
	}

	// if allies were alive and now they are not
	if(oldvalue["allies"] && !level.exist["allies"])
	{
		level.allied_eliminated = true;
		iprintln(&"MP_ALLIESHAVEBEENELIMINATED");
		level thread [[level.ex_psop]]("mp_announcer_allieselim");
		level thread endRound("axis");
		return;
	}

	// if axis were alive and now they are not
	if(oldvalue["axis"] && !level.exist["axis"])
	{
		level.axis_eliminated = true;
		iprintln(&"MP_AXISHAVEBEENELIMINATED");
		level thread [[level.ex_psop]]("mp_announcer_axiselim");
		level thread endRound("allies");
		return;
	}
}

sayObjective()
{
	wait( [[level.ex_fpstime]](2) );

	attacksounds["american"] = "US_mp_cmd_movein";
	attacksounds["british"] = "UK_mp_cmd_movein";
	attacksounds["russian"] = "RU_mp_cmd_movein";
	attacksounds["german"] = "GE_mp_cmd_movein";

	level thread [[level.ex_psop]](attacksounds[game[game["attackers"]]], game["attackers"]);
}

startObjectives()
{
	startSpawnObjectives();
	startBonusObjectives();
	setObjectives();
	adjustObjectivesCount();
	printObjectiveStates();
}

startSpawnObjectives()
{
	level.conquest_objectives = getentarray("spawnobjective", "targetname");
	printDebug("Found " + level.conquest_objectives.size + " spawn objectives in this map.");
		
	for(i = 0; i < level.conquest_objectives.size; i++)
	{
		// first, find the triggers each objective targets and set them
		objective = level.conquest_objectives[i];
		flipOff(objective); //turn all off to start
		
		if(isDefined(objective.target) )
		{
			targets = getentarray(objective.target,"targetname");
			for(t = 0; t < targets.size; t++)
			{
				if(targets[t].classname == "trigger_use" || targets[t].classname == "trigger_multiple")
				{
					objective.trigger = targets[t];
				}
			}
		}

		objective notify("round_ended");
		objective thread objective_think();
		
		level.objectivearray[objective.script_idnumber - 1] = objective;
	}
	
	found = 0;
	for(i = 0; i < level.objectivearray.size; i++)
	{
		if(level.objectivearray[i].script_idnumber <= level.rbcnq_initialobj)
		{
			flipObjective(level.objectivearray[i]);
			found = 1;
		} 
		else 
		{
			break;
		}
	}
}

startBonusObjectives() 
{
	level endon("round_ended");

	level.bonus_objectives = getentarray("bonusobjective","targetname");
	printDebug("Found " + level.bonus_objectives.size + " bonus objectives in this map.");
	
	for(i = 0; i < level.bonus_objectives.size; i++)
	{
		// first, find the triggers each objective targets and set them
		objective = level.bonus_objectives[i];
		if(isDefined(objective.target))
		{
			targets = getentarray(objective.target,"targetname");

			for(t = 0; t < targets.size; t++)
			{
				if(targets[t].classname == "trigger_use" || targets[t].classname == "trigger_multiple")
				{
					objective.trigger = targets[t];
					objective thread bonus_objective_think();
					break;
				}
			}
		}
	}
}

objective_think()
{
	for(;;)
	{
		delaytime = 0.9;
	
		self.trigger waittill("trigger", other);

		if(isDefined(self.beingCapped)) continue;

		if(isPlayer(other))
		{	
			allSpawnObjectives = level.objectivearray;
	
			if(!isDefined(allSpawnObjectives))
				continue;
	
			for(n = 0; n < allSpawnObjectives.size; n++)
			{	
				if(self.script_idnumber == allSpawnObjectives[n].script_idnumber)
				{
					if(other.pers["team"] == game["attackers"])
					{
						// if it's already on, fugeddabowdit
						if(isOn(self))
						{
							other iprintln(&"MP_CNQ_OBJ1");
							continue;
						}

						// attackers can always turn on the 1st objective
						// otherwise, they can turn an objective on only if the previous one is also on.
						previousObjective = allSpawnObjectives[n-1];
						if((n == 0) || (isDefined(previousObjective) && isOn(previousObjective)))
						{
							while(other isTouching(self.trigger) && isAlive(other) && other isOnGround() && other useButtonPressed())
							{
								self.beingCapped = true;

								hud_index = other playerHudCreate("cnq_progress1", 0, level.progressBarY, 0.5, (1,1,1), 1, 0, "center_safearea", "center_safearea", "center", "middle", false, true);
								if(hud_index != -1) other playerHudSetShader(hud_index, "black", level.progressBarWidth, level.progressBarHeight);

								hud_index = other playerHudCreate("cnq_progress2", level.progressBarWidth / -2, level.progressBarY, 1, (1,1,1), 1, 1, "center_safearea", "center_safearea", "left", "middle", false, true);
								if(hud_index != -1)
								{
									other playerHudSetShader(hud_index, "white", 1, level.progressBarHeight);
									other playerHudScale(hud_index, level.captime, 0, level.progressBarWidth, level.progressBarHeight);
								}

								hud_index = other playerHudCreate("cnq_progress3", 0, level.progressBarY + 20, 1, (1,1,1), 1.6, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
								if(hud_index != -1) other playerHudSetText(hud_index, &"MP_CNQ_ACTIVATE_OBJECTIVE");

								other playsound("MP_bomb_plant");
								other linkto(self);
								other [[level.ex_dWeapon]]();

								other.progresstime = 0;
								while(isAlive(other) && other useButtonPressed())
								{
									wait( level.ex_fps_frame );
									other.progresstime += 0.05;
									if(other.progresstime >= level.captime) break;
								}

								other [[level.ex_eWeapon]]();
								other unlink();
								self.beingCapped = undefined;

								other playerHudDestroy("cnq_progress1");
								other playerHudDestroy("cnq_progress2");
								other playerHudDestroy("cnq_progress3");

								if(other.progresstime >= level.captime)
								{
									thread performObjectiveCompleteTasks(self, other, "spawn");
									if(isDefined(self.trigger.delay) && (self.trigger.delay > 0.5))
										delaytime = self.trigger.delay / 1000;
								}
								else continue;
							}
						} 
						else other iprintln(&"MP_CNQ_OBJ2");
					}
					else // defenders
					{ 
						// if it's already off, fugeddabowdit
						if(isOff(self))
						{
							other iprintln(&"MP_CNQ_OBJ1");
							continue;
						}
	
						// defenders can always turn on the last objective and the next to be turned off
						previousObjective = allSpawnObjectives[n+1];
						if((n == allSpawnObjectives.size - 1) || (isDefined(previousObjective) && isOff(previousObjective)))
						{
							while(other isTouching(self.trigger) && isAlive(other) && other isOnGround() && other useButtonPressed())
							{
								self.beingCapped = true;

								hud_index = other playerHudCreate("cnq_progress1", 0, level.progressBarY, 0.5, (1,1,1), 1, 0, "center_safearea", "center_safearea", "center", "middle", false, true);
								if(hud_index != -1) other playerHudSetShader(hud_index, "black", level.progressBarWidth, level.progressBarHeight);

								hud_index = other playerHudCreate("cnq_progress2", level.progressBarWidth / -2, level.progressBarY, 1, (1,1,1), 1, 1, "center_safearea", "center_safearea", "left", "middle", false, true);
								if(hud_index != -1)
								{
									other playerHudSetShader(hud_index, "white", 1, level.progressBarHeight);
									other playerHudScale(hud_index, level.captime, 0, level.progressBarWidth, level.progressBarHeight);
								}

								hud_index = other playerHudCreate("cnq_progress3", 0, level.progressBarY + 20, 1, (1,1,1), 1.6, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
								if(hud_index != -1) other playerHudSetText(hud_index, &"MP_CNQ_DEACTIVATE_OBJECTIVE");

								other playsound("MP_bomb_plant");
								other linkto(self);
								other [[level.ex_dWeapon]]();

								other.progresstime = 0;
								while(isAlive(other) && other useButtonPressed())
								{
									wait( level.ex_fps_frame );
									other.progresstime += 0.05;
									if(other.progresstime >= level.captime) break;
								}

								other [[level.ex_eWeapon]]();
								other unlink();
								self.beingCapped = undefined;

								other playerHudDestroy("cnq_progress1");
								other playerHudDestroy("cnq_progress2");
								other playerHudDestroy("cnq_progress3");

								if(other.progresstime >= level.captime)
								{
									if(level.roundended) break;
									thread performObjectiveCompleteTasks(self, other, "spawn");
									if(isDefined(self.trigger.delay) && (self.trigger.delay > 0.5))
										delaytime = self.trigger.delay / 1000;
								}
								else continue;
							}
						} 
						else other iprintln(&"MP_CNQ_OBJ2");
					}
				}
			}
		}

		wait( [[level.ex_fpstime]](delaytime) );
	}
}

bonus_objective_think()
{
	if(!isDefined(self.radius))
		self.radius = 256;
	
	// initial wait, so teams don't earn bonus in 1st minute before everyone is spawned in.
	self thread countdownUntilAvailable(30);

	for(;;)
	{	
		self.trigger waittill("trigger", other);

		if(isDefined(self.beingCapped)) continue;

		printDebug("Bonus triggered by " + other.name + " playing for the " + other.pers["team"]);
	
		if(isPlayer(other))
		{
			if(!isDefined(level.objectivearray))
				continue;

			teamRole = "attackers";
			if(other.pers["team"] == game["defenders"])
				teamRole = "defenders";

			if(isDefined(self.script_team) && (self.script_team == teamRole)) // if it's their bonus objective
			{ 
				if(level.objCount[teamRole] == level.objectivearray.size) // and they control all the regular objectives
				{ 
					if(self.isAvailable == 1) // and it's not in a wait state
					{
						while(other isTouching(self.trigger) && isAlive(other) && other isOnGround() && other useButtonPressed())
						{
							wait( level.ex_fps_frame );

							self.beingCapped = true;

							hud_index = other playerHudCreate("cnq_progress1", 0, level.progressBarY, 0.5, (1,1,1), 1, 0, "center_safearea", "center_safearea", "center", "middle", false, true);
							if(hud_index != -1) other playerHudSetShader(hud_index, "black", level.progressBarWidth, level.progressBarHeight);

							hud_index = other playerHudCreate("cnq_progress2", level.progressBarWidth / -2, level.progressBarY, 1, (1,1,1), 1, 1, "center_safearea", "center_safearea", "left", "middle", false, true);
							if(hud_index != -1)
							{
								other playerHudSetShader(hud_index, "white", 1, level.progressBarHeight);
								other playerHudScale(hud_index, level.captime, 0, level.progressBarWidth, level.progressBarHeight);
							}

							hud_index = other playerHudCreate("cnq_progress3", 0, level.progressBarY + 20, 1, (1,1,1), 1.6, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
							if(hud_index != -1) other playerHudSetText(hud_index, &"MP_CNQ_ACTIVATE_OBJECTIVE");

							other playsound("MP_bomb_plant");
							other linkto(self);
							other [[level.ex_dWeapon]]();

							other.progresstime = 0;
							while(isAlive(other) && other useButtonPressed())
							{
								other.progresstime += 0.05;
								wait( level.ex_fps_frame );
								if(other.progresstime >= level.captime) break;
							}

							other [[level.ex_eWeapon]]();
							other unlink();
							self.beingCapped = undefined;

							other playerHudDestroy("cnq_progress1");
							other playerHudDestroy("cnq_progress2");
							other playerHudDestroy("cnq_progress3");

							if(other.progresstime >= level.captime)
							{
								if(level.roundended) break;
								self.isAvailable = 0;
								thread performObjectiveCompleteTasks(self, other, "bonus");
								self thread countdownUntilAvailable();
							}
							else continue;
						}
					} 
					else other iprintln(&"MP_CNQ_OBJ3");
				} 
				else other iprintln(&"MP_CNQ_OBJ2");
			} 
			else other iprintln(&"MP_CNQ_OBJ4");
		}

		wait( [[level.ex_fpstime]](0.5) );
	}
}

countdownUntilAvailable(delayTime) 
{ 
	self.isAvailable = 0;
	if(!isDefined(delayTime))
	{
		if(isDefined(self.trigger.delay) && (self.trigger.delay > 0.5))
			delayTime = self.trigger.delay / 1000; //don't know why, but delay comes through as map # * 1000
		else delayTime = 60;
	}

	printDebug("Delay time on trigger is " + delaytime + " seconds.");
	wait( [[level.ex_fpstime]](delayTime) );
	self.isAvailable = 1;
	thread updatePlayerInfo();
}

flipObjective(spawnObjective) 
{
	if(isOn(spawnObjective)) flipOff(spawnObjective);
		else flipOn(spawnObjective);
	printObjectiveStates();
}

getNumObjectivesControlled(team)
{
	if(team == game["attackers"])
		return(level.objCount["attackers"]);
	else
		return(level.objCount["defenders"]);
}

setObjectives() 
{
	deleteObjectivesFromHud();
	addObjectiveToHud_attackers(getNextObjective(game["attackers"]), game["attackers"]);
	addObjectiveToHud_defenders(getNextObjective(game["defenders"]), game["defenders"]);
}

addObjectiveToHud_attackers(objective, team) 
{
	if(isDefined(objective)) 
	{	
		hudIndex = 0;
		
		if(game["attackers"] == "allies")
		{
			objective_add(hudIndex, "current", objective.origin, game["objective_allies"]);
			objective_position(hudIndex, objective.origin);
			objective_team(hudIndex,team);
		}
		else
		{
			objective_add(hudIndex, "current", objective.origin, game["objective_axis"]);
			objective_position(hudIndex, objective.origin);
			objective_team(hudIndex,team);
		}
	}
}

addObjectiveToHud_defenders(objective, team) 
{
	if(isDefined(objective)) 
	{	
		hudIndex = 1;
		
		if(game["defenders"] == "axis")
		{
			objective_add(hudIndex, "current", objective.origin, game["objective_axis"]);
			objective_position(hudIndex, objective.origin);
			objective_team(hudIndex,team);
		}
		else
		{
			objective_add(hudIndex, "current", objective.origin, game["objective_allies"]);
			objective_position(hudIndex, objective.origin);
			objective_team(hudIndex,team);
		}
	}
}

deleteObjectivesFromHud() 
{
	objective_delete(0);
	objective_delete(1);
}

adjustObjectivesCount() 
{
	if( isDefined(level.objCount) )
	{
		if(isDefined(level.objCount["attackers"]) )
			level.objCount["attackers"] = 0;	
		if(isDefined(level.objCount["defenders"]) )
			level.objCount["defenders"] = 0;

		for(n = 0; n < level.objectivearray.size; n++)
		{	
			if(isOn(level.objectivearray[n]))
			{
				level.objCount["attackers"] = level.objCount["attackers"] +1;
			} 
			else 
			{
				level.objCount["defenders"] = level.objCount["defenders"]+1;
			}
		}
	}
}

flipOff(objective) 
{
	objective.script_nodestate = "0";
	objective.team = game["defenders"];
}

flipOn(objective) 
{
	objective.script_nodestate = "1";
	objective.team = game["attackers"];
}

printObjectiveStates() 
{
	if(!level.cnq_debug) return;

	if(isDefined(level.objectivearray))
	{
		for(n = 0; n < level.objectivearray.size; n++)
		{
			spawnObjective = level.objectivearray[n];
			if( isDefined(spawnObjective))
			{
				if(isOn(spawnObjective)) printDebug("Objective number " + spawnObjective.script_idnumber + " is on.");
				else printDebug("Objective number " + spawnObjective.script_idnumber + " is off.");
			}			
			else printDebug("The spawnObjective at position " + n + " is not defined!!!!");
		}
	}
	else printDebug("level.objectivearray is not defined!!!!");
}

printDebug(text) 
{
	if(level.cnq_debug) logprint("CNQ DEBUG: " + text + "\n");
}

performObjectiveCompleteTasks(objective, player, objectiveType) 
{
	if(objectiveType == "spawn")
	{
		flipObjective(objective);
		level.firstSwitchThrown = true;
	}

	lpselfnum = player getEntityNumber();
	lpselfname = player.name;
	lpselfteam = player.pers["team"];
	lpselfguid = player getGuid();
	logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + "cnq_objective" + "\n");

	awardPoints(player, objectiveType);
	if(level.mapended) return;
	
	updatePlayerInfo();
	displayGameMessage(objective, player, objectiveType);
}

updatePlayerInfo() 
{
	setObjectives();
	adjustObjectivesCount();
	setObjectiveTextAll();
}

displayGameMessage(objective, player, objectiveType)
{
	if(isDefined(objective.script_objective_name))
		objectiveName = objective.script_objective_name;
	else
		objectiveName = "the objective";

	message = player.name + " ^7has reached ^2" + objectiveName;

	if(objectiveType == "spawn")
	{
		message = message + " ^7. The " + toUpper(player.pers["team"]) + " are advancing!";

		if(player.pers["team"] == "allies")
			player thread allied_ObjectiveSounds();
		else
			player thread axis_ObjectiveSounds();
	}

	if(objectiveType == "bonus")
	{
		message = message + " ^7. The " + toUpper(player.pers["team"]) + " have earned a bonus!";
		
		if(player.pers["team"] == "allies")
			player thread allied_BonusObjSounds();
		else
			player thread axis_BonusObjSounds();
	}

	iprintln(message);
	self setObjectiveTextAll();
}

awardPoints(player, objectiveType)
{
	if(objectiveType == "bonus")
	{
		player thread [[level.ex_scorePlayer]](level.player_bonus_points, "special");
		thread [[level.ex_scoreTeam]](player.pers["team"], level.team_bonus_points);
	}
	else
	{
		player thread [[level.ex_scorePlayer]](level.player_obj_points, "special");
		thread [[level.ex_scoreTeam]](player.pers["team"], level.team_obj_points);
	}
}

isOn(spawnObjective) 
{
	return(spawnObjective.script_nodestate == "1");
}

isOff(spawnObjective) 
{
	return(spawnObjective.script_nodestate == "0");
}

startHUD()
{
	if(!level.showobj_hud) return;

	level endon("ex_gameover");

	[[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerSpawned);
	[[level.ex_registerCallback]]("onJoinedTeam", ::onJoinedTeam);
	[[level.ex_registerCallback]]("onJoinedSpectators", ::onJoinedSpectators);
	level thread onUpdateTeamHUD();
}

onPlayerSpawned()
{
	self endon("disconnect");

	hud_index = playerHudCreate("cnq_teamobj", 100, 26, 1, (0.98, 0.827, 0.58), 2, 0, "left", "top", "left", "top", false, false);
	if(hud_index == -1) return;
	playerHudSetKeepOnKill(hud_index, true);

	hud_index = playerHudCreate("cnq_enemyobj", 100, 48, 1, (0.98, 0.827, 0.58), 2, 0, "left", "top", "left", "top", false, false);
	if(hud_index == -1) return;
	playerHudSetKeepOnKill(hud_index, true);

	self thread updatePlayerHUD();
}

onJoinedTeam()
{
	self thread removePlayerHUD();
}

onJoinedSpectators()
{
	self thread removePlayerHUD();
}

onUpdateTeamHUD()
{
	while(!level.ex_gameover)
	{
		//self waittill("update_obj_hud");
		wait( [[level.ex_fpstime]](1) );
		level thread updateTeamHUD();
	}
}

updatePlayerHUD()
{
	allied_obj = getNumObjectivesControlled("allies");
	axis_obj = getNumObjectivesControlled("axis");

	if(self.pers["team"] == "allies")
	{
		playerHudSetValue("cnq_teamobj" , allied_obj);
		playerHudSetValue("cnq_enemyobj" , axis_obj);
	}
	else if(self.pers["team"] == "axis")
	{
		playerHudSetValue("cnq_teamobj" , axis_obj);
		playerHudSetValue("cnq_enemyobj" , allied_obj);
	}
}

updateTeamHUD()
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isDefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
			player thread updatePlayerHUD();
	}
}

removePlayerHUD()
{
	playerHudDestroy("cnq_teamobj");
	playerHudDestroy("cnq_enemyobj");
}

getNextObjective(team)
{
	if(team == game["attackers"])
	{
		for(i = 0; i < level.objectivearray.size; i++)
			if(isOff(level.objectivearray[i])) return(level.objectivearray[i]);
		teamRole = "attackers";
	}
	else 
	{ 
		for(i = level.objectivearray.size - 1; i >= 0; i--)
			if(isOn(level.objectivearray[i])) return(level.objectivearray[i]);
		teamRole = "defenders";
	}

	// no spawn objectives currently, so check for a bonus objective
	for(i = 0; i < level.bonus_objectives.size; i++)
	{
		available = 0;
		if(isDefined(level.bonus_objectives[i].isAvailable))
			available = level.bonus_objectives[i].isAvailable;

		if(level.bonus_objectives[i].script_team == teamRole && (available == 1))
			return(level.bonus_objectives[i]);
	}

	// no current objective, return nil
	return(undefined);
}

setObjectiveTextAll() 
{
	printDebug("setObjectiveTextAll() was called.");
	players = level.players;
	for(i = 0; i < players.size; i++)
		setObjectiveText(players[i]);
}

setObjectiveText(player)
{
	printDebug("setObjectiveText( player ) was called.");

	nextObj = getNextObjective(player.pers["team"]);

	if(isDefined(nextObj))
	{
		printDebug("nextObj is defined.");
		if(isDefined(nextObj.script_objective_name))
		{
			objectiveName = nextObj.script_objective_name;
			printDebug("nextObj.script_objective_name is defined and is " + objectiveName);
		}
		else
			objectiveName = "the next objective";

		objText = toUpper(player.pers["team"]) + "^7 must take ^2" + objectiveName;
	} 
	else
	{
		if(player.pers["team"] == game["attackers"])
			objText = game["rbcnq_attackers_obj_text"];
		else if(player.pers["team"] == game["defenders"])
			objText = game["rbcnq_defenders_obj_text"];
		else
			objText = game["rbcnq_neutral_obj_text"];
	}

	player setClientCvar("cg_objectiveText", objText); 
}

printOnTeam(text, team)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if((isDefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
			players[i] iprintln(text);
	}
}

GivePointsToTeam(team, points)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isAlive(player) && player.pers["team"] == team) player thread [[level.ex_scorePlayer]](points);
	}
}

allied_ObjectiveSounds()
{
	if(level.roundended || level.mapended) return;

	if(self.pers["team"] == "allies")
	{
		level thread [[level.ex_psop]]("ctf_enemy_touchcapture", "allies");
		level thread [[level.ex_psop]]("mp_announcer_objective_captured");
		wait( [[level.ex_fpstime]](1) );
		level thread [[level.ex_psop]](game["allies_area_secured"], "allies");
	}
	else
		level thread [[level.ex_psop]](game["german_losing_ground"], "axis");
}

axis_ObjectiveSounds()
{
	if(level.roundended || level.mapended) return;

		if(self.pers["team"] == "axis")
		{
			level thread [[level.ex_psop]]("ctf_enemy_touchcapture", "axis");
			level thread [[level.ex_psop]]("mp_announcer_objective_captured");
			wait( [[level.ex_fpstime]](1) );
			level thread [[level.ex_psop]](game["german_area_secured"], "axis");
		}
		else
			level thread [[level.ex_psop]](game["allies_losing_ground"], "allies");

}

allied_BonusObjSounds()
{
	if(level.roundended || level.mapended) return;

	if(self.pers["team"] == "allies")
	{
		level thread [[level.ex_psop]]("ctf_touchcapture", "allies");
		wait( [[level.ex_fpstime]](1.4) );
		level thread [[level.ex_psop]](game["allies_ground_taken"], "allies");
	}
	else
		level thread [[level.ex_psop]](game["german_losing_ground"], "axis");
}

axis_BonusObjSounds()
{
	if(level.roundended || level.mapended) return;

	if(self.pers["team"] == "axis")
	{
		level thread [[level.ex_psop]]("ctf_touchcapture", "axis");
		wait( [[level.ex_fpstime]](1.4) );
		level thread [[level.ex_psop]](game["german_ground_taken"], "axis");
	}
	else
		level thread [[level.ex_psop]](game["allies_losing_ground"], "allies");
}

toUpper(str)
{
	return(mapChar(str, "L-U"));
}

mapChar(str_in, conv)
{
	if(!isDefined(str_in) || str_in == "") return("");

	conv = tolower(conv);
	switch(conv)
	{
		case "u-l":
			from = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
			to = "abcdefghijklmnopqrstuvwxyz";
			break;
		case "l-u":
			from = "abcdefghijklmnopqrstuvwxyz";
			to = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
			break;
		default:
			return(str_in);
	}

	str_out = "";
	for(i = 0; i < str_in.size; i++)
	{
		chr = str_in[i];
		for(j = 0; j < from.size; j++)
		{
			if(chr == from[j])
			{
				chr = to[j];
				break;
			}
		}

		str_out += chr;
	}

	return(str_out);
}

respawn_timer(delay)
{
	self endon("disconnect");

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
