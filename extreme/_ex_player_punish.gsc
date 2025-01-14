#include extreme\_ex_controller_hud;
#include extreme\_ex_main_utils;

punishment(weaponstatus, movestatus)
{
	if(!isDefined(weaponstatus)) weaponstatus = "keep";
	if(!isDefined(movestatus)) movestatus = "same";

	if(isDefined(self.ex_anchor))
	{
		self unlink();
		self.ex_anchor delete();
	}

	if(weaponstatus == "enable") self [[level.ex_eWeapon]]();
	else if(weaponstatus == "disable") self [[level.ex_dWeapon]]();
	else if(weaponstatus == "random" && !randomInt(2))
	{
		if(!randomInt(2)) self [[level.ex_dWeapon]]();
			else self extreme\_ex_weapons::dropcurrentweapon();
	}
	else if(weaponstatus == "drop") self extreme\_ex_weapons::dropcurrentweapon();

	if(movestatus == "freeze")
	{
		while(isDefined(self.ex_isparachuting)) wait( [[level.ex_fpstime]](1) );
		// spawn a script origin, and lock the players in place
		self.ex_anchor = spawn("script_origin", self.origin);
		self.ex_anchor.angles = self.angles;
		self linkTo(self.ex_anchor);
	}
}

setWeaponStatus(weaponstatus)
{
	self endon("kill_thread");

	if(weaponstatus) self [[level.ex_dWeapon]]();
		else self [[level.ex_eWeapon]]();
}

doWarp(readrules)
{
	self endon("kill_thread");

	if(!isDefined(readrules)) readrules = true;

	ix = self.origin[0];
	iy = self.origin[1];
	iz = 1000;
	if(iz > (game["mapArea_Max"][2] - 200)) iz = game["mapArea_Max"][2] - 200;
	startpoint = self.origin + (0, 0, 24);
	endpoint = (ix, iy, iz);
	distance = distance(startpoint, endpoint);

	self.ex_anchor = spawn("script_model", self.origin);
	self.ex_anchor.angles = self.angles;
	self linkto(self.ex_anchor);

	// drop flag
	self dropTheFlag(true);

	lifttime = (distance / 100) + randomInt(6);
	self.ex_anchor.origin = startpoint;
	self.ex_anchor moveto(endpoint, lifttime);

	// drop weapon
	self maps\mp\gametypes\_weapons::dropWeapon();

	// allow player to read the command monitor message
	wait( [[level.ex_fpstime]](3) );
	self [[level.ex_dWeapon]]();
	iprintlnboldCLEAR("self", 5);
	
	self thread warpShowRules(readrules);

	self waittill("warp_over");

	if(isPlayer(self))
	{
		self unlink();
		if(isDefined(self.ex_anchor)) self.ex_anchor delete();
		self.health = 1;
	}

	wait( [[level.ex_fpstime]](3) );

	// huh? Still here? Stupid map! Blow them up
	if(isPlayer(self) && self.sessionstate == "playing")
	{
		playfx(level.ex_effect["barrel"], self.origin);
		self playsound("mortar_explosion1");
		wait( level.ex_fps_frame );
		if(isPlayer(self))
		{
			self.ex_forcedsuicide = true;
			self suicide();
		}
	}
}

warpShowRules(readrules)
{
	self endon("kill_thread");

	if(readrules)
	{
		svrrules = justNumbers(level.ex_svrrules);
		self iprintlnbold(&"CUSTOM_SERVER_RULES_FAIL");
		wait( [[level.ex_fpstime]](3) );
		for(i = 1; i < svrrules.size; i++)
		{
			ruleno = int(svrrules[i]);
			showrule = warpGetRule(i);
			self iprintlnbold(showrule);
			wait( [[level.ex_fpstime]](3) );
		}
		self iprintlnbold(&"CUSTOM_SERVER_RULES_WARN");
		wait( [[level.ex_fpstime]](3) );
	}
	else wait( [[level.ex_fpstime]](10) );

	self notify("warp_over");
}

warpGetRule(ruleno)
{
	rulestr = "";

	switch(ruleno)
	{
		case 1: { rulestr = &"CUSTOM_SERVER_RULE_1"; break; }
		case 2: { rulestr = &"CUSTOM_SERVER_RULE_2"; break; }
		case 3: { rulestr = &"CUSTOM_SERVER_RULE_3"; break; }
		case 4: { rulestr = &"CUSTOM_SERVER_RULE_4"; break; }
		case 5: { rulestr = &"CUSTOM_SERVER_RULE_5"; break; }
		case 6: { rulestr = &"CUSTOM_SERVER_RULE_6"; break; }
		case 7: { rulestr = &"CUSTOM_SERVER_RULE_7"; break; }
		case 8: { rulestr = &"CUSTOM_SERVER_RULE_8"; break; }
		case 9: { rulestr = &"CUSTOM_SERVER_RULE_9"; break; }
		case 0: { rulestr = &"CUSTOM_SERVER_RULE_10"; break; }
	}
	return(rulestr);
}

doAnchor(lever)
{
	self endon("kill_thread");

	if(lever)
	{
		self.anchor = spawn("script_origin", self.origin);
		self linkTo(self.anchor);
	}
	else
	{
		self unlink();
		if(isDefined(self.anchor)) self.anchor delete();
	}
}

doSuicide()
{
	self endon("kill_thread");

	wait( [[level.ex_fpstime]](0.25) );
	if(isPlayer(self))
	{
		self.ex_forcedsuicide = true;
		self suicide();
	}
}

doSmite()
{
	self endon("kill_thread");

	wait( [[level.ex_fpstime]](1.5) );

	if(isPlayer(self))
	{
		playfx(level.ex_effect["barrel"], self.origin);
		self playsound("artillery_explosion");
		self.ex_forcedsuicide = true;
		self suicide();
	}
}

doTorch(time, surekill)
{
	self endon("kill_thread");

	if(!isDefined(time)) time = 10;
	if(!isDefined(surekill)) surekill = false;

	self thread doFire(time, false);

	// device info to pass on
	device_info = [[level.ex_devInfo]](self, self.pers["team"]);
	device_info.dodamage = true;
	device_info.damage = 10;

	for(i = 0; i < time; i++)
	{
		if(isPlayer(self)) self thread [[level.ex_devPlayer]]("dotorch", device_info);
		wait( [[level.ex_fpstime]](1) );
	}

	if(!surekill) return;

	if(isPlayer(self))
	{
		playfx(level.ex_effect["fire_ground"], self.origin);
		self.ex_forcedsuicide = true;
		self suicide();
	}
}

doFire(time, surekill)
{
	self endon("kill_thread");

	self playsound("scream");

	for(i = 0; i < time; i++)
	{
		if(isPlayer(self))
		{
			playfxontag(level.ex_effect["fire_arm"], self, "j_elbow_le");
			playfxontag(level.ex_effect["fire_arm"], self, "j_elbow_ri");
			playfxontag(level.ex_effect["fire_torso"], self, "torso_stabilizer");
		}
		wait( [[level.ex_fpstime]](1) );
	}

	if(!surekill) return;

	if(isPlayer(self))
	{
		self.ex_forcedsuicide = true;
		self suicide();
	}
}

doSpank(time)
{
	self endon("kill_thread");

	self notify("ex_spankme");
	self endon("ex_spankme");

	self shellshock("default", 10);
	for(i = 0; i < time; i++)
	{
		if(isPlayer(self))
		{
			self forceto("prone");
			self thread extreme\_ex_weapons::dropcurrentweapon();
		}
		wait( [[level.ex_fpstime]](2) );
	}
}

doSilence()
{
	self endon("kill_thread");

	self thread execClientCommand("bind T say");
	wait( [[level.ex_fpstime]](0.25) );
	self thread execClientCommand("bind Y say");
	wait( [[level.ex_fpstime]](0.25) );
	self setClientCvar("cg_chatHeight", "0");
	self setClientCvar("cg_chatTime", "0");
}

doCrybaby(time)
{
	self endon("kill_thread");

	if(!level.ex_crybaby) return;
	if(isDefined(self.ex_crybaby)) return;

	// mark and make invulnerable
	self.ex_invulnerable = true;
	self.ex_crybaby = true;

	// save and replace head icon
	playerHudSetHeadIcon(game["headicon_crybaby"], "none");

	// lock player
	self freezecontrols(true);

	// play sound
	self.ex_headmarker playloopsound("crybaby_loop");

	// show crybaby image and txt
	hud_index = playerHudCreate("crybaby_img", 320, 240, 0, (1,1,1), 1, 100, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index != -1)
	{
		playerHudSetShader(hud_index, "exg_crybaby", 64, 64);
		playerHudScale(hud_index, 1.5, 0, 384, 384);
		playerHudFade(hud_index, 1.5, 1.5, 1 - (level.ex_crybaby_transp / 10));

		hud_index = playerHudCreate("crybaby_txt", 320, 420, 0, (1,0,0), 1.3, 101, "fullscreen", "fullscreen", "center", "middle", false, false);
		if(hud_index != -1) playerHudSetText(hud_index, &"MISC_CRYBABY");
	}

	for(i = 0; i < time; i++)
	{
		wait( [[level.ex_fpstime]](0.5) );
		playerHudSetAlpha("crybaby_txt", 1);
		wait( [[level.ex_fpstime]](0.5) );
		playerHudSetAlpha("crybaby_txt", 0);
	}

	// stop sound
	self.ex_headmarker stopLoopSound();

	// remove crybaby image and txt
	playerHudDestroy("crybaby_img");
	playerHudDestroy("crybaby_txt");

	// release player
	self freezecontrols(false);

	// restore head icon
	playerHudRestoreHeadIcon();

	// unmark and make vulnerable
	self.ex_invulnerable = false;
	self.ex_crybaby = undefined;

	// smite
	if(isPlayer(self)) self thread doSmite();
}

doArty()
{
	self endon("kill_thread");

	wait( [[level.ex_fpstime]](2) );
	self iprintlnbold(&"CMDMONITOR_ARTY_SELF_RUN");
	wait( [[level.ex_fpstime]](5) );

	// device info to pass on
	device_info = [[level.ex_devInfo]](self, self.pers["team"]);
	device_info.damage = 25;

	self.ex_forcedsuicide = true;
	while(isPlayer(self) && isAlive(self))
	{
		// adjust device info
		device_info.origin = (self.origin[0]-100, self.origin[1]-100, game["mapArea_Max"][2]-200);
		device_info.impactpos = self.origin;
		device_info.dodamage = false;

		// inbound projectile - no (radius) damage
		[[level.ex_devInbound]]("kaboom", device_info);

		// adjust device info
		device_info.dodamage = true;

		// damage this player only
		if(isPlayer(self)) self thread [[level.ex_devPlayer]]("doarty", device_info);

		wait( [[level.ex_fpstime]](3) );
	}
}

doSinbin()
{
	self endon("kill_thread");

	if(self.ex_sinbin) return;

	if(isPlayer(self) && self.sessionstate == "playing")
	{
		self.ex_sinbin = true;

		if(!randomInt(2) && isOutside(self.origin)) self sinSplat();
			else self sinFreeze();

		if(isPlayer(self)) self.ex_sinbin = false;
	}
}

sinFreeze()
{
	self endon("kill_thread");

	if(isPlayer(self))
	{
		self thread sinTimer(level.ex_sinfrztime);

		if(level.ex_sinbinmsg)
		{
			msg1 = &"SINBIN_FREEZE";
			msg2 = getLocalizedSeconds(level.ex_sinfrztime);

			switch(level.ex_sinbinmsg)
			{
				case 0:
					self iprintln(msg1);
					self iprintln(msg2);
					break;
				case 1:
					self iprintlnbold(msg1);
					self iprintlnbold(msg2);
					break;
			}
		}

		if(isPlayer(self))
		{
			self dropTheFlag(true);
			self thread punishment("random", "freeze");
			self waittill("sinbin_timer_done");
			if(isPlayer(self)) self thread punishment("enable", "release");
		}
	}
}

sinSplat()
{
	self endon("kill_thread");

	// stop unknown soldier and duplicate name handler
	self notify("ex_freefall");

	if(isPlayer(self))
	{
		if(level.ex_sinbinmsg)
		{
			msg1 = &"SINBIN_FREEFALL";

			switch(level.ex_sinbinmsg)
			{
				case 0: self iprintln(msg1); break;
				case 1: self iprintlnbold(msg1); break;
			}
		}

		if(isPlayer(self))
		{
			self dropTheFlag(true);
			self thread doWarp(false);
		}
	}
}

sinTimer(time)
{
	self endon("kill_thread");

	while(isPlayer(self) && time > 0)
	{
		wait( [[level.ex_fpstime]](1) );
		time--;
	}

	if(isPlayer(self)) self notify("sinbin_timer_done");
}
