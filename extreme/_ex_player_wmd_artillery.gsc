#include extreme\_ex_controller_hud;
#include extreme\_ex_main_utils;

startWmd(delay, first, next)
{
	self endon("kill_thread");

	if(self.ex_artillery) return;

	self notify("end_artillery");
	wait( [[level.ex_fpstime]](0.1) );
	self endon("end_artillery");

	self.ex_artillery = true;

	// wait if needed
	if(!isDefined(delay) || !delay) delay = first;
	wait( [[level.ex_fpstime]](delay) );

	while(self.ex_artillery)
	{
		// let them know the artillery strike is available
		if((level.ex_arcade_shaders & 4) == 4) self thread extreme\_ex_player_arcade::showArcadeShader("x2_artilleryunlock", level.ex_arcade_shaders_perk);
			else self iprintlnbold(&"ARTILLERY_READY");
		self playTeamSoundOnPlayer("arty_ready", 1);

		// set up the on screen icon
		playerHudCreateIcon("wmd_icon", 120, 390, game["wmd_artillery_hudicon"]);

		// monitor for binocular fire
		self thread waitForUse();

		// show hint
		self thread playerHudAnnounce(&"WMD_ACTIVATE_HINT");

		// wait until they use artillery
		self waittill("artillery_over");

		if((level.ex_arcade_shaders & 4) != 4) self iprintlnbold(&"ARTILLERY_RELOAD");
		self playTeamSoundOnPlayer("arty_reload", 3);

		// now wait for one interval
		wait( [[level.ex_fpstime]](next) );
	}
}

waitForUse()
{
	self endon("kill_thread");
	self endon("end_artillery");
	self endon("end_waitforuse");

	self.ex_callingwmd = false;

	for(;;)
	{
		self waittill("binocular_enter");
		if(!self.ex_callingwmd && ((level.ex_store & 2) != 2 || !extreme\_ex_specials::playerPerkIsLocked("cam")))
		{
			self thread waitForBinocUse();
			self thread playerHudAnnounce(&"WMD_ARTILLERY_HINT");
		}

		wait( [[level.ex_fpstime]](0.2) );
	}
}

waitForBinocUse()
{
	self endon("kill_thread");
	self endon("binocular_exit");
	self endon("end_waitforuse");

	for(;;)
	{
		if(isPlayer(self) && self useButtonPressed() && !self.ex_callingwmd)
		{
			self.ex_callingwmd = true;
			self thread callRadio();
			while(self usebuttonpressed()) wait( level.ex_fps_frame );
		}
		wait( level.ex_fps_frame );
	}
}

callRadio()
{
	self endon("kill_thread");

	// end binoculars animated crosshair
	self notify("kill_aimrig");

	if((level.ex_arcade_shaders & 4) != 4) self iprintlnbold(&"ARTILLERY_RADIO_IN");

	targetpos = self getTargetPosEye();
	friendly = extreme\_ex_player_wmd::friendlyInstrikezone(targetpos);

	if(!level.ex_wmd_speedup)
	{
		self playTeamSoundOnPlayer("arty_firemission", 3.6);
		for(i = 1; i < 4; i++) self playTeamSoundOnPlayer("arty_" + randomInt(8), 0.6);
		self playTeamSoundOnPlayer("arty_pointfuse", 3);
	}

	if(isDefined(targetpos) && isDefined(friendly) && friendly == false)
	{
		// notify threads
		self notify("end_waitforuse");

		playerHudDestroy("wmd_icon");
		if((level.ex_arcade_shaders & 4) != 4) self iprintlnbold(&"ARTILLERY_FIRED");
		self playTeamSoundOnPlayer("arty_shot", 3);
		self.usedweapons = true;

		level thread fireBarrage(targetpos, self);
	}
	else if(!isDefined(targetpos) && !isDefined(friendly))
	{
		friendly = undefined;
		self iprintlnbold(&"ARTILLERY_NOT_VALID");
		self playTeamSoundOnPlayer("arty_novalid", 3);
	}
	else if(isDefined(friendly) && friendly == true)
	{
		friendly = undefined;
		self iprintlnbold(&"ARTILLERY_FRIENDLY_WARNING");
		self playTeamSoundOnPlayer("arty_frndly", 3);
	}
	else if(isDefined(targetpos) && !isDefined(friendly))
	{
		friendly = undefined;
		self iprintlnbold(&"ARTILLERY_TO_CLOSE_WARNING");
		self playTeamSoundOnPlayer("arty_tooclose", 3);
	}

	self.ex_callingwmd = false;
}

fireBarrage(targetpos, owner)
{
	// drop flare
	if(level.ex_wmd_flare) playfx(level.ex_effect["flare_indicator"], targetpos);
	wait(1);

	// number of shells
	shell_count = 5;

	// play firing sounds
	for(i = 0; i < shell_count; i++)
	{
		players = level.players;
		for(j = 0; j < players.size; j++) players[j] playLocalSound("artillery_fire");
		wait(0.5);
	}

	// fire shells
	for(i = 0; i < shell_count; i++)
	{
		// drop point
		droppos = getDropPosFromTarget(targetpos, 400);

		// impact point
		impactpos = getImpactPos(targetpos, level.ex_wmd_artillery_accuracy);
		if(!isDefined(impactpos)) continue;

		// device info to pass on
		device_info = [[level.ex_devInfo]](owner, owner.pers["team"]);
		device_info.origin = droppos;
		device_info.impactpos = impactpos;
		device_info.dodamage = true;

		thread [[level.ex_devInbound]]("artillery_wmd", device_info);
		wait( [[level.ex_fpstime]]( randomFloatRange(2, 5)) );
	}

	// wait for all shells to explode
	wait( [[level.ex_fpstime]](10) );

	if(isPlayer(owner)) owner notify ("artillery_over");
}
