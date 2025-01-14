#include extreme\_ex_controller_hud;
#include extreme\_ex_main_utils;

startWmd(delay, first, next)
{
	self endon("kill_thread");

	if(self.ex_mortars) return;

	self notify("end_mortar");
	wait( [[level.ex_fpstime]](0.1) );
	self endon("end_mortar");

	self.ex_mortars = true;

	// wait if needed
	if(!isDefined(delay) || !delay) delay = first;
	wait( [[level.ex_fpstime]](delay) );

	while(self.ex_mortars)
	{
		// let them know the mortar strike is available
		if((level.ex_arcade_shaders & 4) == 4) self thread extreme\_ex_player_arcade::showArcadeShader("x2_mortarsunlock", level.ex_arcade_shaders_perk);
			else self iprintlnbold(&"MORTAR_READY");
		self playTeamSoundOnPlayer("morta_ready", 1);

		// set up the on screen icon
		self thread playerHudCreateIcon("wmd_icon", 120, 390, game["wmd_mortar_hudicon"]);

		// monitor for binocular fire
		self thread waitForUse();

		// show hint
		self thread playerHudAnnounce(&"WMD_ACTIVATE_HINT");

		// wait until they use mortars
		self waittill("mortar_over");

		if((level.ex_arcade_shaders & 4) != 4) self iprintlnbold(&"MORTAR_RELOAD");
		self playTeamSoundOnPlayer("morta_reload", 3);

		// now wait for one interval
		wait( [[level.ex_fpstime]](next) );
	}
}

waitForUse()
{
	self endon("kill_thread");
	self endon("end_mortar");
	self endon("end_waitforuse");

	self.ex_callingwmd = false;

	for(;;)
	{
		self waittill("binocular_enter");
		if(!self.ex_callingwmd && ((level.ex_store & 2) != 2 || !extreme\_ex_specials::playerPerkIsLocked("cam")))
		{
			self thread waitForBinocUse();
			self thread playerHudAnnounce(&"WMD_MORTAR_HINT");
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

	if((level.ex_arcade_shaders & 4) != 4) self iprintlnbold(&"MORTAR_RADIO_IN");

	targetpos = self getTargetPosEye();
	friendly = extreme\_ex_player_wmd::friendlyInstrikezone(targetpos);

	if(!level.ex_wmd_speedup)
	{
		self playTeamSoundOnPlayer("morta_firemission", 3.6);
		for(i = 1; i < 4; i++) self playTeamSoundOnPlayer("morta_" + randomInt(8), 0.6);
		self playTeamSoundOnPlayer("morta_pointfuse", 3);
	}

	if(isDefined(targetpos) && isDefined(friendly) && friendly == false)
	{
		// notify threads
		self notify("end_waitforuse");

		playerHudDestroy("wmd_icon");
		if((level.ex_arcade_shaders & 4) != 4) self iprintlnbold(&"MORTAR_FIRED");
		self playTeamSoundOnPlayer("morta_shot", 3);
		self.usedweapons = true;

		level thread fireBarrage(targetpos, self);
	}
	else if(!isDefined(targetpos) && !isDefined(friendly))
	{
		friendly = undefined;
		self iprintlnbold(&"MORTAR_NOT_VALID");
		self playTeamSoundOnPlayer("morta_novalid", 3);
	}
	else if(isDefined(friendly) && friendly == true)
	{
		friendly = undefined;
		self iprintlnbold(&"MORTAR_FRIENDLY_WARNING");
		self playTeamSoundOnPlayer("morta_frndly", 3);
	}
	else if(isDefined(targetpos) && !isDefined(friendly))
	{
		friendly = undefined;
		self iprintlnbold(&"MORTAR_TO_CLOSE_WARNING");
		self playTeamSoundOnPlayer("morta_tooclose", 3);
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
	for(i = 0; i < shell_count; i++ )
	{
		players = level.players;
		for(j = 0; j < players.size; j++) players[j] playLocalSound("mortar_fire");
		wait(0.5);
	}

	// fire mortars
	for(i = 0; i < shell_count; i++)
	{
		// drop point
		droppos = getDropPosFromTarget(targetpos, 400);

		// impact point
		impactpos = getImpactPos(targetpos, level.ex_wmd_mortar_accuracy);
		if(!isDefined(impactpos)) continue;

		// device info to pass on
		device_info = [[level.ex_devInfo]](owner, owner.pers["team"]);
		device_info.origin = droppos;
		device_info.impactpos = impactpos;
		device_info.dodamage = true;

		thread [[level.ex_devInbound]]("mortar_wmd", device_info);
		wait( [[level.ex_fpstime]]( randomFloatRange(2, 5)) );
	}

	// wait for all mortars to explode
	wait( [[level.ex_fpstime]](10) );

	if(isPlayer(owner)) owner notify("mortar_over");
}
