#include extreme\_ex_weapons;
#include extreme\_ex_controller_hud;
#include extreme\_ex_main_utils;

main()
{
	self endon("kill_thread");

	count = 0;
	beepcount = 0;
	exit_ads = false;
	exit_nadeuse = false;
	exit_attackuse = false;
	exit_meleeuse = false;
	exit_range = false;
	spos = self.origin;
	sdist = int(level.ex_spwn_range / 12);

	self.ex_invulnerable = true;
	self.ex_spawnprotected = true;

	if(level.ex_spwn_headicon) playerHudSetHeadIcon(game["headicon_protect"], "none");

	if(level.ex_spwn_hud)
	{
		hud_index = playerHudCreate("spawnprot_icon", 120, 390, level.ex_iconalpha, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
		if(hud_index != -1)
		{
			playerHudSetShader(hud_index, game["mod_protect_hudicon"], 32, 32);
			playerHudScale(hud_index, 0.5, 0, 24, 24);
		}

		if(level.ex_spwn_hud == 2)
		{
			hud_index = playerHudCreate("spawnprot_time", 140, 375, 1, (1,1,1), 0.8, 0, "fullscreen", "fullscreen", "left", "middle", false, true);
			if(hud_index != -1)
			{
				playerHudSetLabel(hud_index, &"SPAWNPROTECTION_TIME");
				playerHudSetValue(hud_index, level.ex_spwn_time);
			}

			hud_index = playerHudCreate("spawnprot_timeleft", 140, 385, 1, (0,1,0), 1, 0, "fullscreen", "fullscreen", "left", "middle", false, true);
			if(hud_index != -1) playerHudSetValue(hud_index, level.ex_spwn_time);

			if(level.ex_spwn_range)
			{
				hud_index = playerHudCreate("spawnprot_range", 140, 400, 0.8, (1,1,1), 0.8, 0, "fullscreen", "fullscreen", "left", "middle", false, true);
				if(hud_index != -1)
				{
					playerHudSetLabel(hud_index, &"SPAWNPROTECTION_RANGE");
					playerHudSetValue(hud_index, sdist);
				}

				hud_index = playerHudCreate("spawnprot_rangeleft", 140, 410, 1, (0,1,0), 1, 0, "fullscreen", "fullscreen", "left", "middle", false, true);
				if(hud_index != -1) playerHudSetValue(hud_index, sdist);
			}
		}
	}

	if(level.ex_spwn_msg)
	{
		if(level.ex_spwn_invisible) msg1 = &"SPAWNPROTECTION_ENABLED_INVISIBLE";
			else msg1 = &"SPAWNPROTECTION_ENABLED";
		msg2 = getLocalizedSeconds(level.ex_spwn_time);

		switch(level.ex_spwn_msg)
		{
			case 1:
				self iprintln(msg1);
				self iprintln(msg2);
				break;
			default:
				self iprintlnbold(msg1);
				self iprintlnbold(msg2);
				break;
		}
	}

	if(level.ex_spwn_wepdisable) self [[level.ex_dWeapon]]();

	// invisible Spawn Protection ON
	// WARNING: also part of pre-spawn settings in ex_player::initPreSpawn()
	if(level.ex_spwn_invisible) self hide();

	while(isAlive(self) && self.sessionstate == "playing" && self.ex_invulnerable)
	{
		if(count >= level.ex_spwn_time) break;

		currweapon = self getCurrentWeapon();
		if( (!isDefined(self.ex_disabledWeapon) || !self.ex_disabledWeapon) && isWeaponType(currweapon, "valid"))
		{
			if(self playerAds())
			{
				exit_ads = true;
				break;
			}
			if(self.usedweapons)
			{
				exit_nadeuse = true;
				break;
			}
			if(self attackButtonPressed())
			{
				exit_attackuse = true;
				break;
			}
			if(self meleeButtonPressed())
			{
				exit_meleeuse = true;
				break;
			}
		}

		if(level.ex_spwn_range && !isDefined(self.ex_isparachuting))
		{
			distmoved = distance(spos, self.origin);
			if(level.ex_spwn_hud == 2)
			{
				sdist = level.ex_spwn_range - distmoved;
				sdistperc = 1 - (sdist / level.ex_spwn_range);
				playerHudSetValue("spawnprot_rangeleft", int(sdist / 12));
				playerHudSetColor("spawnprot_rangeleft", (sdistperc, 1 - sdistperc, 0));
			}
			if(distmoved > level.ex_spwn_range)
			{
				exit_range = true;
				break;
			}
		}

		wait( level.ex_fps_frame );

		beepcount++;
		if(beepcount == 20)
		{
			if((level.ex_parachutes && !level.ex_parachutes_protection) || !isDefined(self.ex_isparachuting))
			{
				count++;
				if(level.ex_spwn_hud == 2)
				{
					playerHudSetValue("spawnprot_timeleft", level.ex_spwn_time - count);
					if(level.ex_spwn_time <= 3 || (count >= level.ex_spwn_time - 3) ) playerHudSetColor("spawnprot_timeleft", (1,0,0));
				}
			}
			beepcount = 0;
		}
	}

	if(level.ex_spwn_msg)
	{
		msg3 = undefined;
		if(exit_ads) msg3 = &"SPAWNPROTECTION_TOOK_AIM";
		if(exit_attackuse || exit_meleeuse) msg3 = &"SPAWNPROTECTION_FIRE_BUTTON_PRESSED";
		if(self.sessionstate == "playing" && exit_range) msg3 = &"SPAWNPROTECTION_MOVED_AWAY_AREA";
		msg4 = &"SPAWNPROTECTION_DISABLED";

		switch(level.ex_spwn_msg)
		{
			case 1:
				if(isDefined(msg3)) self iprintln(msg3);
				self iprintln(msg4);
				break;
			default:
				if(isDefined(msg3)) self iprintlnbold(msg3);
				self iprintlnbold(msg4);
				break;
		}
	}

	// restore the headicon if changed
	if(level.ex_spwn_headicon && self.sessionstate == "playing") playerHudRestoreHeadIcon();

	playerHudDestroy("spawnprot_icon");
	playerHudDestroy("spawnprot_time");
	playerHudDestroy("spawnprot_timeleft");
	playerHudDestroy("spawnprot_range");
	playerHudDestroy("spawnprot_rangeleft");

	// invisible Spawn Protection OFF
	if(level.ex_spwn_invisible) self show();

	if(level.ex_spwn_wepdisable) self [[level.ex_eWeapon]]();
	self.ex_spawnprotected = undefined;
	self.ex_invulnerable = false;
}

spawnSpectator(origin, angles)
{
	self notify("spawned");
	self notify("end_respawn");

	// small delay to let eventcontroller execute all onPlayerSpawn() and all
	// onPlayerKilled() events caused by the "spawned" notification of this procedure
	// when the game is over
	if(level.ex_gameover) wait( [[level.ex_fpstime]](0.1) );
	if(!isPlayer(self)) return;

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	self.sessionstate = "spectator";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;

	if(isDefined(self.pers["team"]) && self.pers["team"] == "spectator")
		self.statusicon = "";

	if(level.ex_currentgt != "dm" && level.ex_currentgt != "sd" && level.ex_currentgt != "lms" || level.ex_currentgt != "hm")
		maps\mp\gametypes\_spectating::setSpectatePermissions();

	if(level.ex_currentgt == "sd" || level.ex_currentgt == "rbctf" || level.ex_currentgt == "rbcnq" || level.ex_currentgt == "esd")
	{
		if(!isDefined(self.skip_setspectatepermissions))
			maps\mp\gametypes\_spectating::setSpectatePermissions();
	}

	if(isDefined(origin) && isDefined(angles))
		self spawn(origin, angles);
	else
	{
		spawnpointname = "mp_global_intermission";
		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

		if(isDefined(spawnpoint))
			self spawn(spawnpoint.origin, spawnpoint.angles);
		else
			maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}

	if(!level.ex_roundbased) self setClientCvar("cg_objectiveText", "");

	if(level.ex_currentgt == "esd") level extreme\_ex_gametype_esd::updateTeamStatus();
	if(level.ex_currentgt == "ft") level extreme\_ex_gametype_ft::updateTeamStatus();
	if(level.ex_currentgt == "lts") level extreme\_ex_gametype_lts::updateTeamStatus();
	if(level.ex_currentgt == "rbcnq") level extreme\_ex_gametype_rbcnq::updateTeamStatus();
	if(level.ex_currentgt == "rbctf") level extreme\_ex_gametype_rbctf::updateTeamStatus();
	if(level.ex_currentgt == "sd") level extreme\_ex_gametype_sd::updateTeamStatus();

	if(!level.ex_gameover) thread monitorSpec();

	[[level.updatetimer]]();
}

spawnPreIntermission()
{
	self setClientCvar("g_scriptMainMenu", "");
	self closeMenu();
	self spawnSpectator();
	self allowSpectateTeam("allies", false);
	self allowSpectateTeam("axis", false);
	self allowSpectateTeam("freelook", false);
	self allowSpectateTeam("none", true);
}

spawnIntermission()
{
	self notify("spawned");
	self notify("end_respawn");

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	self.sessionstate = "intermission";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;

	spawnpointname = "mp_global_intermission";
	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

	if(isDefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");

	[[level.updatetimer]]();
}

monitorSpec()
{
	self endon("disconnect");
	self endon("spawned");

	sticky_spec = false;
	sticky_valid = false;
	sticky_spec_player = -1;

	while(1)
	{
		wait( level.ex_fps_frame );

		if(sticky_spec)
		{
			sticky_valid = monitorSpecVerify(sticky_spec_player);

			if(self meleebuttonpressed() || !sticky_valid)
			{
				self.spectatorclient = -1;
				sticky_spec = false;
				while(self meleebuttonpressed()) wait( level.ex_fps_frame );
			}
			else if(self attackbuttonpressed())
			{
				sticky_spec_player = monitorSpecNext(sticky_spec_player);
				self.spectatorclient = sticky_spec_player;
				if(sticky_spec_player == -1) sticky_spec = false;
				while(self attackbuttonpressed()) wait( level.ex_fps_frame );
			}
			else if(self usebuttonpressed())
			{
				sticky_spec_player = monitorSpecPrevious(sticky_spec_player);
				self.spectatorclient = sticky_spec_player;
				if(sticky_spec_player == -1) sticky_spec = false;
				while(self usebuttonpressed()) wait( level.ex_fps_frame );
			}
		}
		else if(self usebuttonpressed())
		{
			if(sticky_spec_player == -1 || !monitorSpecVerify(sticky_spec_player)) sticky_spec_player = monitorSpecNext(sticky_spec_player);
			self.spectatorclient = sticky_spec_player;
			if(sticky_spec_player != -1) sticky_spec = true;
			while(self usebuttonpressed()) wait( level.ex_fps_frame );
		}
	}
}

monitorSpecNext(spec_player)
{
	self endon("disconnect");

	// do not use level.players as we need an array sorted on entity numbers
	players = getentarray("player", "classname");

	// no need to search if there's only one player (that would be me)
	if(players.size == 1) return(-1);

	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isPlayer(player))
		{
			entity = player getEntityNumber();
			if(entity > spec_player && player.sessionteam != "spectator") return(entity);
		}
	}

	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isPlayer(player) && player.sessionteam != "spectator")
		{
			entity = player getEntityNumber();
			return(entity);
		}
	}

	return(-1);
}

monitorSpecPrevious(spec_player)
{
	self endon("disconnect");

	// do not use level.players as we need an array sorted on entity numbers
	players = getentarray("player", "classname");

	// no need to search if there's only one player (that would be me)
	if(players.size == 1) return(-1);

	for(i = players.size - 1; i >= 0; i--)
	{
		player = players[i];
		if(isPlayer(player))
		{
			entity = player getEntityNumber();
			if(entity < spec_player && player.sessionteam != "spectator") return(entity);
		}
	}

	for(i = players.size - 1; i >= 0; i--)
	{
		player = players[i];
		if(isPlayer(player) && player.sessionteam != "spectator")
		{
			entity = player getEntityNumber();
			return(entity);
		}
	}

	return(-1);
}

monitorSpecVerify(spec_player)
{
	self endon("disconnect");

	// level.players is OK as we're only validating the player we (want to) spectate
	players = level.players;

	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isPlayer(player) && player getEntityNumber() == spec_player)
		{
			if(player.sessionteam != "spectator") return(true);
			return(false);
		}
	}

	return(false);
}

punish(reason)
{
	self endon("kill_thread");

	if(isDefined(self.ex_spwn_punish)) return;
	self.ex_spwn_punish = true;

	// spawn protection punishment threshold reset
	if(level.ex_spwn_punish_threshold) self.ex_spwn_punish_counter = 0;

	if(isPlayer(self))
	{
		if(reason == "abusing")
		{
			iprintln(&"SPAWNPROTECTION_PUNISH_ABUSER_MSG", [[level.ex_pname]](self));
			self iprintlnbold(&"SPAWNPROTECTION_PUNISH_ABUSER_PMSG");
		}

		if(reason == "attacking" || reason == "turretattack")
		{
			iprintln(&"SPAWNPROTECTION_PUNISH_ATTACKER_MSG", [[level.ex_pname]](self));
			self iprintlnbold(&"SPAWNPROTECTION_PUNISH_ATTACKER_PMSG");
		}
	}

	if(reason == "turretattack")
	{
		if(isPlayer(self)) self thread execClientCommand("-attack; +activate; wait 10; -activate");
	}
	else
	{
		pun = randomInt(100);

		if(pun < 50)
		{
			if(isPlayer(self)) self [[level.ex_dWeapon]]();
			wait( [[level.ex_fpstime]](2) );
		}
		else for(i = 0; i < 2; i++)
		{
			if(isPlayer(self)) self extreme\_ex_weapons::dropcurrentweapon();
			wait( [[level.ex_fpstime]](1) );
		}

		if(isPlayer(self))
		{
			if(reason == "abusing") self iprintlnbold(&"SPAWNPROTECTION_FREE_ABUSER_PMSG");
			else if(reason == "attacking") self iprintlnbold(&"SPAWNPROTECTION_FREE_ATTACKER_PMSG");

			self [[level.ex_eWeapon]]();
			self.ex_spwn_punish = undefined;
		}
	}
}
