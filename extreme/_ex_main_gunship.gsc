#include extreme\_ex_controller_hud;
#include extreme\_ex_main_utils;

gsInit()
{
	// precaching and device registration
	[[level.ex_devRequest]]("gunship", ::cpxGunship);

	if(level.ex_gunship_25mm) [[level.ex_devRequest]]("gunship_25mm");
	if(level.ex_gunship_40mm) [[level.ex_devRequest]]("gunship_40mm");
	if(level.ex_gunship_105mm) [[level.ex_devRequest]]("gunship_105mm");
	if(level.ex_gunship_nuke)
	{
		switch(level.ex_gunship_nuke_wipeout)
		{
			case 1: [[level.ex_devRequest]]("gunship_nuke1"); break;
			case 2: [[level.ex_devRequest]]("gunship_nuke2"); break;
			case 3: [[level.ex_devRequest]]("gunship_nuke3"); break;
		}
	}
}

main()
{
	level.ex_gunship_attachz = 200;
	level.crashing_gunships = [];

	if(level.ex_gunship)
	{
		level.gunship = spawn("script_model", (0,0,0));
		if(level.ex_gunship_visible <= 1) level.gunship hide();
		level.gunship setmodel( extreme\_ex_controller_devices::getDeviceModel("gunship") );
		level.gunship linkTo(level.rotation_rig, "tag_0", (level.rotation_rig.maxradius,0,0), (0,90,-20));
		if(level.ex_gunship_ambientsound == 2) level.gunship playloopsound("gunship_ambient");

		level.gunship.health = level.ex_gunship_maxhealth;
		level.gunship.team = "neutral";
		level.gunship.owner = level.gunship;
	}

	if(level.ex_gunship_special)
	{
		level.gunship_special = spawn("script_model", (0,0,0));
		if(level.ex_gunship_visible <= 1) level.gunship_special hide();
		level.gunship_special setmodel( extreme\_ex_controller_devices::getDeviceModel("perkship") );
		level.gunship_special linkTo(level.rotation_rig, "tag_180", (level.rotation_rig.maxradius,0,0), (0,90,-20));
		if(level.ex_gunship_ambientsound == 2) level.gunship_special playloopsound("gunship_ambient");

		level.gunship_special.health = level.ex_gunship_maxhealth;
		level.gunship_special.team = "neutral";
		level.gunship_special.owner = level.gunship_special;
	}

	[[level.ex_registerLevelEvent]]("onSecond", ::onSecondHealthMonitor, false);

	rotations = 0;
	while(!level.ex_gameover)
	{
		level.rotation_rig waittill("rotated360");

		if(level.ex_gunship && isPlayer(level.gunship.owner))
		{
			player_z = int(level.gunship.owner.origin[2] + level.ex_gunship_attachz + 0.5);
			gunship_z = int(level.gunship.origin[2] + 0.5);

			if(player_z != gunship_z)
			{
				if(level.ex_gunship_visible == 1) level.gunship hide();
				if(level.ex_gunship_ambientsound == 1) level.gunship stoploopsound();
				level.gunship.owner show();
				level.gunship.owner = level.gunship;
			}
		}

		if(level.ex_gunship_special && isPlayer(level.gunship_special.owner))
		{
			player_z = int(level.gunship_special.owner.origin[2] + level.ex_gunship_attachz + 0.5);
			gunship_z = int(level.gunship_special.origin[2] + 0.5);

			if(player_z != gunship_z)
			{
				if(level.ex_gunship_visible == 1) level.gunship_special hide();
				if(level.ex_gunship_ambientsound == 1) level.gunship_special stoploopsound();
				level.gunship_special.owner show();
				level.gunship_special.owner = level.gunship_special;
			}
		}

		rotations++;
		if(rotations == level.ex_gunship_advertise)
		{
			rotations = 0;
			level thread gunshipAdvertise();
		}
	}

	if(level.ex_gunship)
	{
		level.gunship hide();
		if(level.ex_gunship_ambientsound) level.gunship stoploopsound();
	}

	if(level.ex_gunship_special)
	{
		level.gunship_special hide();
		if(level.ex_gunship_ambientsound) level.gunship_special stoploopsound();
	}
}

//------------------------------------------------------------------------------
// Health monitor
//------------------------------------------------------------------------------
onSecondHealthMonitor(eventID)
{
	if(level.ex_gunship && level.gunship.health <= 0)
	{
		level thread gunshipCrash(level.gunship, ::gunshipDetachPlayer);
		level.gunship.health = level.ex_gunship_maxhealth;
	}

	if(level.ex_gunship_special && level.gunship_special.health <= 0)
	{
		level thread gunshipCrash(level.gunship_special, extreme\_ex_specials_gunship::gunshipSpecialDetachPlayer);
		level.gunship_special.health = level.ex_gunship_maxhealth;
	}
}

//------------------------------------------------------------------------------
// Validation
//------------------------------------------------------------------------------
gunshipCheckEntity(entity)
{
	if(level.ex_gunship)
	{
		if(!isDefined(level.gunship) || !isPlayer(level.gunship.owner)) return(-1);
		if(entity == level.gunship) return(1);
	}
	return(-1);
}

gunshipValidateAsTarget(team)
{
	if(!level.ex_gunship || level.ex_gunship_protect == 1) return(false);
	if(!isPlayer(level.gunship.owner)) return(false);
	if(level.gunship.health <= 0) return(false);
	if(isDefined(team) && level.ex_teamplay && level.gunship.team == team) return(false);
	return(true);
}

//------------------------------------------------------------------------------
// Perk assignment
//------------------------------------------------------------------------------
startWmd(delay, first, next)
{
	self endon("kill_thread");

	if(!isDefined(self.ex_gunship)) self.ex_gunship = false;
	if(self.ex_gunship) return;

	if(isPlayer(level.gunship.owner) && level.gunship.owner == self) return;

	self notify("end_gunship");
	wait( [[level.ex_fpstime]](0.1) );
	self endon("end_gunship");

	self.ex_gunship = true;

	// wait if needed
	if(!isDefined(delay) || !delay) delay = first;
	wait( [[level.ex_fpstime]](delay) );

	while(self.ex_gunship)
	{
		if((level.ex_store & 2) == 2)
			while(extreme\_ex_specials::playerPerkIsLocked("stealth", false)) wait( [[level.ex_fpstime]](1) );

		if(level.ex_gunship_arcade) self thread extreme\_ex_player_arcade::showArcadeShader("x2_gunshipunlock", level.ex_arcade_shaders_perk);
			else self iprintlnbold(&"GUNSHIP_READY");

		playerHudCreateIcon("wmd_icon", 120, 390, game["wmd_gunship_hudicon"]);
		self thread playerHudAnnounce(&"WMD_ACTIVATE_HINT");
		self thread waitForBinocEnter();

		self waittill("gunship_over");

		if(next) wait( [[level.ex_fpstime]](next) );
			else break;
	}

	self.ex_gunship = false;
}

gunshipPerk(delay)
{
	self endon("kill_thread");

	if(!isDefined(self.ex_gunship)) self.ex_gunship = false;
	if(self.ex_gunship) return;

	if(isPlayer(level.gunship.owner) && level.gunship.owner == self) return;

	self notify("end_gunship");
	wait( [[level.ex_fpstime]](0.1) );
	self endon("end_gunship");

	self.ex_gunship = true;

	while(isDefined(self.ex_checkingwmd)) wait( level.ex_fps_frame );
	self extreme\_ex_player_wmd::wmdStop();

	// wait if needed
	if(!isDefined(delay) || !delay) delay = 1;
	wait( [[level.ex_fpstime]](delay) );

	if(self.ex_gunship)
	{
		if((level.ex_store & 2) == 2)
			while(extreme\_ex_specials::playerPerkIsLocked("stealth", false)) wait( [[level.ex_fpstime]](1) );

		if(level.ex_gunship_arcade) self thread extreme\_ex_player_arcade::showArcadeShader("x2_gunshipunlock", level.ex_arcade_shaders_perk);
			else self iprintlnbold(&"GUNSHIP_READY");

		playerHudCreateIcon("wmd_icon", 120, 390, game["wmd_gunship_hudicon"]);
		self thread playerHudAnnounce(&"WMD_ACTIVATE_HINT");
		self thread waitForBinocEnter();

		self waittill("gunship_over");
		self.ex_gunship = false;
	}
}

gunshipBoard()
{
	self endon("kill_thread");

	wait( [[level.ex_fpstime]](randomFloat(0.5)) );

	if(isPlayer(level.gunship.owner))
	{
		self iprintlnbold(&"GUNSHIP_OCCUPIED");
		while(self useButtonPressed()) wait( level.ex_fps_frame );
		self.ex_callingwmd = false;
		return;
	}

	if(level.ex_flagbased && isDefined(self.flag))
	{
		self iprintlnbold(&"GUNSHIP_FLAGCARRIER");
		while(self useButtonPressed()) wait( level.ex_fps_frame );
		self.ex_callingwmd = false;
		return;
	}

	self notify("end_binoc");
	playerHudDestroy("wmd_icon");
	self.usedweapons = true;
	self thread gunshipAttachPlayer();
	self.ex_callingwmd = false;
}

waitForBinocEnter()
{
	self endon("kill_thread");
	self endon("end_gunship");
	self endon("end_binoc");

	self.ex_callingwmd = false;

	for(;;)
	{
		self waittill("binocular_enter");
		if(!self.ex_callingwmd)
		{
			self thread waitForBinocUse();
			self thread playerHudAnnounce(&"WMD_GUNSHIP_HINT");
		}
	}
}

waitForBinocUse()
{
	self endon("kill_thread");
	self endon("binocular_exit");
	self endon("end_binoc");

	for(;;)
	{
		if(isPlayer(self) && self useButtonPressed() && !self.ex_callingwmd)
		{
			self.ex_callingwmd = true;
			self thread gunshipBoard();
		}
		wait( level.ex_fps_frame );
	}
}

//------------------------------------------------------------------------------
// Gunship assignment
//------------------------------------------------------------------------------
gunshipAttachPlayer()
{
	self endon("kill_thread");

	if(isPlayer(level.gunship.owner)) return;
	level.gunship.owner = self;
	level.gunship.team = self.pers["team"];
	level.gunship.health = level.ex_gunship_maxhealth;
	self.pers["gunship"] = true;

	self forceto("stand");
	self.gunship_org_origin = self.origin;
	self.gunship_org_angles = self.angles;

	extreme\_ex_weapons::stopWeaponChangeMonitor();

	if(level.ex_gunship_airraid) level.rotation_rig playsound("air_raid");
	if(level.ex_gunship_visible == 1) level.gunship show();
	if(level.ex_gunship_ambientsound == 1) level.gunship playloopsound("gunship_ambient");

	self.ex_gunship_ejected = false;
	playerHudSetStatusIcon("gunship_statusicon");
	if(level.ex_gunship == 1) self.pers["conseckill"] = 0;
	if(level.ex_gunship == 3) self.pers["conskillnumb"] = 0;
	if(level.ex_gunship_health) self.health = self.maxhealth;
	self.ex_gunship_kills = 0;
	self hide();
	self linkTo(level.rotation_rig, "tag_0", (level.rotation_rig.maxradius,0,0-level.ex_gunship_attachz), (0,0,0));
	self.dont_auto_balance = true;

	level thread gunshipTimer(self);
	if(level.ex_gunship_inform) self thread gunshipInform(true);
	if(level.ex_gunship_clock) self thread gunshipClock();
	self thread gunshipWeapon();
	if(level.ex_gunship_cm) self thread gunshipCounterMeasures();
}

gunshipTimer(player)
{
	player endon("gunship_over");

	gunship_time = level.ex_gunship_time;
	while(gunship_time > 0 && !level.ex_gameover)
	{
		wait( [[level.ex_fpstime]](1) );
		gunship_time--;

		// keep an eye on the player
		if(!isPlayer(player))
		{
			level thread gunshipDetachPlayerLevel(player, true);
			return;
		}
	}

	if(isPlayer(player))
	{
		// player is still there, and has a valid ticket
		if(isPlayer(level.gunship.owner))
		{
			if(level.gunship.owner == player)
			{
				if(!level.ex_gameover && (level.ex_gunship_eject & 1) == 1) player thread gunshipDetachPlayer(true);
					else player thread gunshipDetachPlayer();
			}
		}
		// player is still there, but seems to be in gunship without a valid ticket
		else if(player.origin[2] + level.ex_gunship_attachz == level.gunship.origin[2])
		{
			if(!level.ex_gameover) player thread gunshipDetachPlayer(false, true);
				else level thread gunshipDetachPlayerLevel(player, true);
		}
	}
}

gunshipDetachPlayer(eject, skipcheck)
{
	level endon("ex_gameover");
	self endon("disconnect");

	if(!isDefined(skipcheck)) skipcheck = false;
	if(!skipcheck && (!isPlayer(level.gunship.owner) || !isPlayer(self) || level.gunship.owner != self)) return;

	if(!isDefined(eject)) eject = false;
	if(self.ex_gunship_ejected) return;
	if(eject) self.ex_gunship_ejected = true;

	self notify("gunship_over");
	if(isDefined(self.ex_gunship_weapons)) self.ex_gunship_weapons = [];
	if(level.ex_gunship_inform) self thread gunshipInform(false);
	playerHudDestroy("gunship_overlay");
	playerHudDestroy("gunship_grain");
	playerHudDestroy("gunship_clock");

	self show();
	self unlink();
	self.ex_invulnerable = false;
	playerHudRestoreStatusIcon();
	if(level.ex_gunship == 1) self.pers["conseckill"] = 0;
	if(level.ex_gunship == 3) self.pers["conskillnumb"] = 0;
	self.dont_auto_balance = undefined;

	if(eject) thread gunshipPlayerEject();
	else
	{
		self setOrigin(self.gunship_org_origin);
		self setPlayerAngles(self.gunship_org_angles);
	}

	extreme\_ex_weapons::startWeaponChangeMonitor(true, level.ex_gunship_refill);

	if(level.ex_gunship_visible == 1) level.gunship hide();
	if(level.ex_gunship_ambientsound == 1) level.gunship stoploopsound();
	level.gunship.owner = level.gunship;
	level.gunship.team = "neutral";
}

gunshipDetachPlayerLevel(playerent, skipcheck)
{
	level endon("ex_gameover");

	if(!isDefined(skipcheck)) skipcheck = false;
	if(!skipcheck && (!isPlayer(level.gunship.owner) || !isPlayer(playerent) || level.gunship.owner != playerent)) return;

	if(isPlayer(playerent)) playerent notify("gunship_over");
	if(isPlayer(playerent) && isDefined(playerent.ex_gunship_weapons)) playerent.ex_gunship_weapons = [];
	if(isPlayer(playerent) && level.ex_gunship_inform) playerent thread gunshipInform(false);
	if(isPlayer(playerent)) playerent playerHudDestroy("gunship_overlay");
	if(isPlayer(playerent)) playerent playerHudDestroy("gunship_grain");
	if(isPlayer(playerent)) playerent playerHudDestroy("gunship_clock");

	if(isPlayer(playerent)) playerent show();
	if(isPlayer(playerent)) playerent unlink();
	if(isPlayer(playerent)) playerent.ex_invulnerable = false;
	if(isPlayer(playerent)) playerHudRestoreStatusIcon();
	if(level.ex_gunship == 1 && isPlayer(playerent)) playerent.pers["conseckill"] = 0;
	if(level.ex_gunship == 3 && isPlayer(playerent)) playerent.pers["conskillnumb"] = 0;
	if(isPlayer(playerent)) playerent.dont_auto_balance = undefined;

	if(level.ex_gunship_visible == 1) level.gunship hide();
	if(level.ex_gunship_ambientsound == 1) level.gunship stoploopsound();
	level.gunship.owner = level.gunship;
	level.gunship.team = "neutral";
}

gunshipPlayerEject()
{
	level endon("ex_gameover");
	self endon("disconnect");

	switch(self.pers["team"])
	{
		case "axis": chute_model = game["chute_player_axis"]; break;
		case "allies": chute_model = game["chute_player_allies"]; break;
		default: chute_model = game["chute_player_allies"]; break;
	}

	chute_start = self.origin;
	if(!level.ex_gunship_eject_dropzone)
	{
		spawnpoint = getNearestSpawnpoint(self.origin);
		chute_end = spawnpoint.origin + (0, 0, 30);
	}
	else chute_end = self.gunship_org_origin + (0, 0, 30);

	chute_speed = 3 + randomInt(3);

	chute_index = self parachuteMe(chute_model, chute_start, chute_end, chute_speed, self.angles, false);
	if(chute_index != -1)
	{
		if(level.ex_gunship_eject_protect) self.ex_invulnerable = true;

		while(isPlayer(self) && isAlive(self) && !parachuteIsDone(chute_index))
		{
			if(level.ex_gunship_eject_protect == 2 && isAlive(self) && self.sessionstate == "playing" &&
				(self attackButtonPressed() && self getCurrentWeapon() != "none" )) self.ex_invulnerable = false;

			self setClientCvar("cl_stance", "0");
			wait( [[level.ex_fpstime]](0.2) );
		}

		if(isPlayer(self)) self.ex_invulnerable = false;
	}
	else if(isPlayer(self) && isAlive(self))
	{
		self setOrigin(self.gunship_org_origin);
		self setPlayerAngles(self.gunship_org_angles);
	}
}

gunshipWeapon()
{
	self endon("kill_thread");
	self endon("gunship_over");

	wait( [[level.ex_fpstime]](0.2) );
	self takeAllWeapons();

	self.ex_gunship_weapons = [];
	for(i = 0; i < level.ex_gunship_weapons.size; i++)
	{
		self.ex_gunship_weapons[i] = spawnstruct();

		if(level.ex_gunship_weapons[i].clip >= level.ex_gunship_weapons[i].ammo)
		{
			weapon_clip = level.ex_gunship_weapons[i].ammo;
			weapon_reserve = 0;
		}
		else
		{
			weapon_clip = level.ex_gunship_weapons[i].clip;
			weapon_reserve = level.ex_gunship_weapons[i].ammo - level.ex_gunship_weapons[i].clip;
		}

		self.ex_gunship_weapons[i].clip = weapon_clip;
		self.ex_gunship_weapons[i].reserve = weapon_reserve;
		self.ex_gunship_weapons[i].enabled = level.ex_gunship_weapons[i].enabled;
		self.ex_gunship_weapons[i].locked = level.ex_gunship_weapons[i].locked;
	}

	current = -1;
	stop_switch = false;
	force_eject = false;
	manual_eject = false;
	weapon_switch = getTime();

	for(;;)
	{
		if(current != -1) while(!self useButtonPressed()) wait( level.ex_fps_frame );

		manual_eject = ((level.ex_gunship_eject & 8) == 8 && self useButtonPressed() && self meleeButtonPressed());

		if(force_eject || manual_eject)
		{
			if(force_eject) self iprintlnbold(&"GUNSHIP_FORCED_EJECT");
			thread gunshipDetachPlayer(true);
			break;
		}

		if(!stop_switch)
		{
			if(current != -1)
			{
				self.ex_gunship_weapons[current].clip = self getWeaponSlotClipAmmo("primary");
				self.ex_gunship_weapons[current].reserve = self getWeaponSlotAmmo("primary");
				if(self.ex_gunship_weapons[current].clip == 0)
				{
					if(self.ex_gunship_weapons[current].reserve > 0)
					{
						self.ex_gunship_weapons[current].clip = 1;
						self.ex_gunship_weapons[current].reserve--;
					}
					else self.ex_gunship_weapons[current].enabled = false;
				}
			}

			check_switch = false;
			newcurrent = current;
			while(1)
			{
				newcurrent++;
				if(newcurrent == current)
				{
					if(!self.ex_gunship_weapons[newcurrent].enabled || self.ex_gunship_weapons[newcurrent].locked) newcurrent = -1;
					break;
				}
				else if(newcurrent < self.ex_gunship_weapons.size)
				{
					if(self.ex_gunship_weapons[newcurrent].enabled && !self.ex_gunship_weapons[newcurrent].locked) break;
				}
				else
				{
					check_switch = true;
					newcurrent = -1;
				}
			}

			skip_switch = false;
			if(newcurrent == -1)
			{
				skip_switch = true;
				if((level.ex_gunship_eject & 4) == 4) force_eject = true;
			}
			else if(newcurrent == current) skip_switch = true;

			current = newcurrent;

			if(!skip_switch)
			{
				if(check_switch)
				{
					weapon_switch_prev = weapon_switch;
					weapon_switch = getTime();
					weapon_cycle = (weapon_switch - weapon_switch_prev) / 1000;
					if(weapon_cycle < level.ex_gunship_weapons.size * 1)
					{
						self takeAllWeapons();
						playerHudSetAlpha("gunship_overlay", 0);
						self iprintlnbold(&"GUNSHIP_SWITCH_TOO_FAST");
						wait( [[level.ex_fpstime]](3) );
						playerHudSetAlpha("gunship_overlay", 1);
					}
				}

				self setWeaponSlotWeapon("primary", level.ex_gunship_weapons[current].weapon);
				self setWeaponClipAmmo(level.ex_gunship_weapons[current].weapon, self.ex_gunship_weapons[current].clip);
				self setWeaponSlotAmmo("primary", self.ex_gunship_weapons[current].reserve);
				self switchToWeapon(level.ex_gunship_weapons[current].weapon);
				thread gunshipWeaponOverlay(level.ex_gunship_weapons[current].overlay);

				if(level.ex_gunship_weapons.size == 1) stop_switch = true;
			}
		}

		while(self useButtonPressed()) wait( level.ex_fps_frame );
	}
}

gunshipCounterMeasures()
{
	self endon("kill_thread");
	self endon("gunship_over");

	while(self meleeButtonPressed()) wait( level.ex_fps_frame );

	cm = level.ex_gunship_cm;

	while(cm > 0)
	{
		wait( [[level.ex_fpstime]](0.1) );

		if(self meleeButtonPressed())
		{
			self playlocalsound("gunship_flares");
			playfxontag(level.ex_effect["gunship_flares"], level.gunship, "tag_flares");
			level thread gunshipDecoy(level.gunship.origin);
			cm--;

			while(self meleeButtonPressed()) wait( level.ex_fps_frame );
			wait( [[level.ex_fpstime]](1) );
		}
	}
}

gunshipDecoy(origin)
{
	level notify("decoy_over");
	level endon("decoy_over");

	if(!isDefined(level.gunship_decoy))
	{
		level.gunship_decoy = spawn("script_model", origin);
		level.gunship_decoy setmodel("xmodel/tag_origin");
	}
	else level.gunship_decoy.origin = origin;

	level.gunship_decoy moveto( (origin[0], origin[1], int(origin[2] / 2)), level.ex_gunship_cm_ttl);
	wait( [[level.ex_fpstime]](level.ex_gunship_cm_ttl) );

	level.gunship_decoy delete();
}

gunshipWeaponUnlock(attacker)
{
	attacker endon("disconnect");

	if(isPlayer(attacker) && ( (level.ex_gunship && isPlayer(level.gunship.owner) && level.gunship.owner == attacker) || (level.ex_gunship_special && isPlayer(level.gunship_special.owner) && level.gunship_special.owner == attacker) ))
	{
		attacker.ex_gunship_kills++;

		// wait a brief moment to let other arcade shaders display first
		wait( [[level.ex_fpstime]](1) );
		if(!isPlayer(attacker)) return;

		for(i = 0; i < attacker.ex_gunship_weapons.size; i++)
		{
			switch(level.ex_gunship_weapons[i].weapon)
			{
				case "gunship_40mm_mp":
					if(level.ex_gunship_40mm_unlock && attacker.ex_gunship_kills >= level.ex_gunship_40mm_unlock)
					{
						if(attacker.ex_gunship_weapons[i].enabled && attacker.ex_gunship_weapons[i].locked)
						{
							attacker.ex_gunship_weapons[i].locked = false;
							if(level.ex_gunship_arcade) attacker thread extreme\_ex_player_arcade::showArcadeShader("x2_40mmunlock", level.ex_arcade_shaders_perk);
								else attacker iprintlnbold(&"GUNSHIP_40MM_UNLOCK");
						}
					}
					break;
				case "gunship_105mm_mp":
					if(level.ex_gunship_105mm_unlock && attacker.ex_gunship_kills >= level.ex_gunship_105mm_unlock)
					{
						if(attacker.ex_gunship_weapons[i].enabled && attacker.ex_gunship_weapons[i].locked)
						{
							attacker.ex_gunship_weapons[i].locked = false;
							if(level.ex_gunship_arcade) attacker thread extreme\_ex_player_arcade::showArcadeShader("x2_105mmunlock", level.ex_arcade_shaders_perk);
								else attacker iprintlnbold(&"GUNSHIP_105MM_UNLOCK");
						}
					}
					break;
				case "gunship_nuke_mp":
					if(level.ex_gunship_nuke_unlock && attacker.ex_gunship_kills >= level.ex_gunship_nuke_unlock)
					{
						if(attacker.ex_gunship_weapons[i].enabled && attacker.ex_gunship_weapons[i].locked)
						{
							attacker.ex_gunship_weapons[i].locked = false;
							if(level.ex_gunship_arcade) attacker thread extreme\_ex_player_arcade::showArcadeShader("x2_nukeunlock", level.ex_arcade_shaders_perk);
								else attacker iprintlnbold(&"GUNSHIP_NUKE_UNLOCK");
						}
					}
					break;
			}
		}
	}
}

gunshipWeaponOverlay(overlay)
{
	self endon("kill_thread");
	self endon("gunship_over");

	hud_index = playerHudCreate("gunship_overlay", 0, 0, 1, (1,1,1), 1, 0, "center", "middle", "center", "middle", false, true);
	if(hud_index == -1) return;
	playerHudSetShader(hud_index, overlay, 640, 480);

	if(level.ex_gunship_grain)
	{
		hud_index = playerHudCreate("gunship_grain", 0, 0, 0.5, (1,1,1), 1, 0, "fullscreen", "fullscreen", "left", "top", false, true);
		if(hud_index == -1) return;
		playerHudSetShader(hud_index, "gunship_overlay_grain", 640, 480);
	}
}

gunshipClock()
{
	hud_index = playerHudCreate("gunship_clock", 6, 76, 1, (1,1,1), 1, 0, "left", "top", "left", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetClock(hud_index, level.ex_gunship_time, level.ex_gunship_time, "hudStopwatch", 48, 48);
}

//------------------------------------------------------------------------------
// Gunship advertisement
//------------------------------------------------------------------------------
gunshipAdvertise()
{
	switch(level.ex_gunship)
	{
		case 1:
			iprintln(&"GUNSHIP_ADVERTISE_MODE1");
			iprintln(&"GUNSHIP_ADVERTISE_MODE1_HOW", level.ex_gunship_killspree);
			break;
		case 2:
			iprintln(&"GUNSHIP_ADVERTISE_MODE2");
			iprintln(&"GUNSHIP_ADVERTISE_MODE2_HOW", level.ex_gunship_rank);
			break;
		case 3:
			iprintln(&"GUNSHIP_ADVERTISE_MODE3");
			iprintln(&"GUNSHIP_ADVERTISE_MODE3_HOW", level.ex_gunship_ladder, gunshipGetLadderStr(level.ex_gunship_ladder));
			break;
		case 4:
			if(level.ex_streak_wmdtype)
			{
				iprintln(&"GUNSHIP_ADVERTISE_MODE1");
				switch(level.ex_streak_wmdtype)
				{
					case 1:
						iprintln(&"GUNSHIP_ADVERTISE_MODE1_HOW", 20);
						break;
					case 2:
						iprintln(&"GUNSHIP_ADVERTISE_MODE1_HOW", level.ex_streak_special);
						break;
					case 3:
						iprintln(&"GUNSHIP_ADVERTISE_MODE1_HOW", level.ex_streak_allow_on);
						break;
				}
			}
			else if(level.ex_rank_wmdtype)
			{
				iprintln(&"GUNSHIP_ADVERTISE_MODE2");
				switch(level.ex_rank_wmdtype)
				{
					case 1:
						iprintln(&"GUNSHIP_ADVERTISE_MODE2_HOW", 7);
						break;
					case 2:
						iprintln(&"GUNSHIP_ADVERTISE_MODE2_HOW", level.ex_rank_special);
						break;
					case 3:
						iprintln(&"GUNSHIP_ADVERTISE_MODE2_HOW", level.ex_rank_allow_on);
						break;
				}
			}
			else if(level.ex_ladder_wmdtype)
			{
				iprintln(&"GUNSHIP_ADVERTISE_MODE3");
				switch(level.ex_ladder_wmdtype)
				{
					case 1:
						iprintln(&"GUNSHIP_ADVERTISE_MODE3_HOW", 8, gunshipGetLadderStr(8));
						break;
					case 2:
						iprintln(&"GUNSHIP_ADVERTISE_MODE3_HOW", level.ex_ladder_special, gunshipGetLadderStr(level.ex_ladder_special));
						break;
					case 3:
						iprintln(&"GUNSHIP_ADVERTISE_MODE3_HOW", level.ex_ladder_allow_on, gunshipGetLadderStr(level.ex_ladder_allow_on));
						break;
				}
			}
			break;
		default:
			if(level.ex_gunship_special && extreme\_ex_specials::getPerkStock("gunship") > 0)
			{
				iprintln(&"GUNSHIP_ADVERTISE_MODE4");
				iprintln(&"GUNSHIP_ADVERTISE_MODE4_HOW");
			}
	}

	wait( [[level.ex_fpstime]](3) );

	random_hint = randomInt(3);
	switch(random_hint)
	{
		case 0:
			iprintln(&"GUNSHIP_ADVERTISE_HINT1");
			break;
		case 1:
			iprintln(&"GUNSHIP_ADVERTISE_HINT2");
			break;
		case 2:
			if(level.ex_gunship_eject)
			{
				if((level.ex_gunship_eject & 7) == 7) iprintln(&"GUNSHIP_ADVERTISE_HINT9");
				else if((level.ex_gunship_eject & 6) == 6) iprintln(&"GUNSHIP_ADVERTISE_HINT8");
				else if((level.ex_gunship_eject & 5) == 5) iprintln(&"GUNSHIP_ADVERTISE_HINT7");
				else if((level.ex_gunship_eject & 4) == 4) iprintln(&"GUNSHIP_ADVERTISE_HINT6");
				else if((level.ex_gunship_eject & 3) == 3) iprintln(&"GUNSHIP_ADVERTISE_HINT5");
				else if((level.ex_gunship_eject & 2) == 2) iprintln(&"GUNSHIP_ADVERTISE_HINT4");
				else if((level.ex_gunship_eject & 1) == 1) iprintln(&"GUNSHIP_ADVERTISE_HINT3");
			}
			break;
	}

	wait( [[level.ex_fpstime]](3) );

	if(level.ex_gunship_nuke && level.ex_gunship_nuke_unlock) iprintln(&"GUNSHIP_ADVERTISE_NUKE_UNLOCK", level.ex_gunship_nuke_unlock);
}

gunshipGetLadderStr(value)
{
	switch(value)
	{
		case 2: return(&"GUNSHIP_ADVERTISE_MODE3_DOUBLE");
		case 3: return(&"GUNSHIP_ADVERTISE_MODE3_TRIPLE");
		case 4: return(&"GUNSHIP_ADVERTISE_MODE3_MULTI");
		case 5: return(&"GUNSHIP_ADVERTISE_MODE3_MEGA");
		case 6: return(&"GUNSHIP_ADVERTISE_MODE3_ULTRA");
		case 7: return(&"GUNSHIP_ADVERTISE_MODE3_MONSTER");
		case 8: return(&"GUNSHIP_ADVERTISE_MODE3_LUDICROUS");
		case 9: return(&"GUNSHIP_ADVERTISE_MODE3_TOPGUN");
	}
}

gunshipInform(boarding)
{
	if(!level.ex_teamplay)
	{
		if(boarding) iprintln(&"GUNSHIP_ACTIVATED_ALL", [[level.ex_pname]](self));
			else iprintln(&"GUNSHIP_DEACTIVATED_ALL", [[level.ex_pname]](self));
	}
	else
	{
		if(level.ex_gunship_inform == 1)
		{
			if(boarding) gunshipInformTeam(&"GUNSHIP_ACTIVATED_TEAM", self.pers["team"]);
				else gunshipInformTeam(&"GUNSHIP_DEACTIVATED_TEAM", self.pers["team"]);
		}
		else
		{
			if(self.pers["team"] == "allies") enemyteam = "axis";
				else enemyteam = "allies";

			if(boarding)
			{
				gunshipInformTeam(&"GUNSHIP_ACTIVATED_TEAM", self.pers["team"]);
				gunshipInformTeam(&"GUNSHIP_ACTIVATED_ENEMY", enemyteam);
			}
			else
			{
				gunshipInformTeam(&"GUNSHIP_DEACTIVATED_TEAM", self.pers["team"]);
				gunshipInformTeam(&"GUNSHIP_DEACTIVATED_ENEMY", enemyteam);
			}
		}
	}

	if(!level.ex_gunship_clock) self iprintln(&"GUNSHIP_TIME", level.ex_gunship_time);
}

gunshipInformTeam(locstring, team)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isPlayer(player) && isDefined(player.pers) && isDefined(player.pers["team"]))
			if(player.pers["team"] == team) player iprintln(locstring, [[level.ex_pname]](self));
	}
}

//------------------------------------------------------------------------------
// Projectile monitoring
//------------------------------------------------------------------------------
gunshipMonitorProjectile(entity, gunship)
{
	weapon = gunship.owner getCurrentWeapon();
	if(!isDefined(weapon)) return;

	// Screen shaking when firing (on player in gunship)
	switch(weapon)
	{
		case "gunship_25mm_mp":
			earthquake(0.2, 0.1, gunship.owner.origin, 100);
			break;
		case "gunship_40mm_mp":
			earthquake(0.4, 0.3, gunship.owner.origin, 100);
			break;
		case "gunship_105mm_mp":
			earthquake(0.6, 0.5, gunship.owner.origin, 100);
			break;
		case "gunship_nuke_mp":
			earthquake(0.6, 0.5, gunship.owner.origin, 100);
			gunship.owner.ex_invulnerable = true; // begin nuke survival hack
			break;
	}

	// wait for projectile to explode
	lastorigin = entity.origin;
	while(isDefined(entity))
	{
		lastorigin = entity.origin;
		wait( level.ex_fps_frame );
	}

	// device info to pass on
	device_info = [[level.ex_devInfo]](gunship.owner, gunship.team);
	device_info.origin = lastorigin;
	device_info.dodamage = true;

	// Screen shaking on impact
	switch(weapon)
	{
		case "gunship_40mm_mp":
			earthquake(0.2, 1, lastorigin, 1000);
			level thread [[level.ex_devQueue]]("gunship_40mm", device_info);
			break;
		case "gunship_105mm_mp":
			earthquake(0.2, 2, lastorigin, 2000);
			level thread [[level.ex_devQueue]]("gunship_105mm", device_info);
			break;
		case "gunship_nuke_mp":
			if(level.ex_gunship_nuke_fx) playFx(level.ex_effect["gunship_nuke"], lastorigin);
			earthquake(0.8, 2, lastorigin, 5000);
			gunship.owner.ex_invulnerable = false; // end nuke survival hack

			impactloc = undefined;
			if(level.ex_gunship_nuke_wipeout)
			{
				switch(level.ex_gunship_nuke_wipeout)
				{
					case 1:
						level thread [[level.ex_devQueue]]("gunship_nuke1", device_info);
						break;
					case 2:
						level thread [[level.ex_devQueue]]("gunship_nuke2", device_info);
						break;
					case 3:
						impactloc = spawn("script_origin", lastorigin);
						impactloc thread [[level.ex_devDamage]]("gunship_nuke3", device_info, "nuke");
						level thread [[level.ex_devQueue]]("gunship_nuke3", device_info);
						break;
				}

				wait( [[level.ex_fpstime]](1) );
				level thread extreme\_ex_controller_airtraffic::planeCrashAll();
				if(extreme\_ex_specials_helicopter::perkValidateAsTarget(gunship.team)) level.helicopter.health = 0;
				if(level.ex_gunship && gunship == level.gunship && gunshipValidateAsTarget(gunship.team)) level.gunship.health = 0;
				if(level.ex_gunship_special && gunship == level.gunship_special && extreme\_ex_specials_gunship::perkValidateAsTarget(gunship.team)) level.gunship_special.health = 0;
			}

			if(isDefined(impactloc)) impactloc delete();
			break;
	}
}

//------------------------------------------------------------------------------
// Crash handling (both gunship and perkship)
//------------------------------------------------------------------------------
gunshipCrash(gunship, detach_callback)
{
	origin = gunship.origin;
	angles = anglesNormalize((0, gunship.angles[1], -20));

	// create dummy gunship
	index = gunshipCrashAllocate();
	level.crashing_gunships[index].model = spawn("script_model", origin);

	crashing_gunship = level.crashing_gunships[index].model;
	crashing_gunship.angles = angles;
	crashing_gunship setmodel( extreme\_ex_controller_devices::getDeviceModel("gunship") );
	crashing_gunship thread gunshipCrashFX();

	// eject player if necessary
	if(isDefined(detach_callback)) thread [[detach_callback]](true);

	// calculate speed
	gunship_speed = ((2 * 3.14159265358979 * level.rotation_rig.maxradius) / level.rotation_rig.rotationspeed) * 0.0254;

	// crash point (must be far enough to calculate bezier curve before reaching it)
	crashpos = posForward(origin, angles, 2000);

	movetime = calcTime(origin, crashpos, gunship_speed);
	crashing_gunship moveto(crashpos, movetime);

	// calculate bezier crash curve
	f1 = posForward(crashpos, angles, 2000 + randomInt(2000));
	f2 = posLeft(f1, angles, 2000 + randomInt(int(level.rotation_rig.maxradius)));
	dest = posDown(f2, angles, 0);
	if(dest[2] < game["mapArea_Min"][2]) dest = (dest[0], dest[1], game["mapArea_Min"][2] - 100);
	level.crashing_gunships[index].node_array = crashing_gunship quadraticBezier(20, crashpos, f1, dest, gunship_speed, 10);

	// commence crashing
	crashing_gunship thread moveBezier(level.crashing_gunships[index].node_array, gunship_speed, "crash_done");
	crashing_gunship stoploopsound();
	crashing_gunship playloopsound("plane_dive");

	// wait for crash to finish
	crashing_gunship waittill("crash_done");
	crashing_gunship notify("crashfx_done");

	crashing_gunship stoploopsound();
	playfx(level.ex_effect["planecrash_explosion"], crashing_gunship.origin);
	crashing_gunship playsound("plane_explosion_" + (1 + randomInt(3)));
	wait( [[level.ex_fpstime]](0.5) );
	playfx(level.ex_effect["planecrash_ball"], crashing_gunship.origin);
	wait( [[level.ex_fpstime]](5) );

	gunshipCrashFree(index);
}

gunshipCrashAllocate()
{
	for(i = 0; i < level.crashing_gunships.size; i++)
	{
		if(level.crashing_gunships[i].inuse == 0)
		{
			level.crashing_gunships[i].inuse = 1;
			return(i);
		}
	}

	level.crashing_gunships[i] = spawnstruct();
	level.crashing_gunships[i].inuse = 1;
	return(i);
}

gunshipCrashFree(index)
{
	level.crashing_gunships[index].model delete();
	level.crashing_gunships[index].node_array = undefined;
	level.crashing_gunships[index].inuse = 0;
}

gunshipCrashFX()
{
	self endon("crashfx_done");

	playfx(level.ex_effect["plane_explosion"], self.origin);
	self playsound("plane_explosion_" + (1 + randomInt(3)));
	wait( [[level.ex_fpstime]](0.5) );

	playfx(level.ex_effect["plane_explosion"], self.origin);
	self playsound("plane_explosion_" + (1 + randomInt(3)));
	wait( [[level.ex_fpstime]](0.5) );

	engine = randomInt(4);

	while(1)
	{
		playfxontag(level.ex_effect["planecrash_smoke"], self, "tag_engine" + engine);
		if(randomInt(100) < 5)
		{
			playfx(level.ex_effect["plane_explosion"], self.origin);
			self playsound("plane_explosion_" + (1 + randomInt(3)));
		}
		wait( [[level.ex_fpstime]](0.1) );
	}
}

//------------------------------------------------------------------------------
// Close proximity explosion callback
//------------------------------------------------------------------------------
cpxGunship(dev_index, cpx_flag, origin, owner, team, entity)
{
	if(gunshipValidateAsTarget(team))
	{
		switch(cpx_flag)
		{
			case 1:
				dist = int( distance(origin, level.gunship.origin) );
				if(dist <= level.ex_devices[dev_index].range)
				{
					damage = int(level.ex_devices[dev_index].maxdamage * ((level.ex_devices[dev_index].range - dist) / level.ex_devices[dev_index].range));
					level.gunship.health -= damage;
				}
				break;
			case 2:
				break;
			case 4:
				if(entity == level.gunship)
				{
					level.gunship.health -= level.ex_devices[dev_index].maxdamage;
					return;
				}
				break;
			case 8:
				level.gunship.health -= level.ex_devices[dev_index].maxdamage;
				break;
			case 16:
				level.gunship.health -= level.ex_devices[dev_index].maxdamage;
				break;
			case 32:
				level.gunship.health -= level.ex_devices[dev_index].maxdamage;
				break;
		}
	}
}
