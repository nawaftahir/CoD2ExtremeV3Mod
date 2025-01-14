#include extreme\_ex_controller_hud;
#include extreme\_ex_controller_airtraffic;
#include extreme\_ex_main_utils;

startWmd(delay, first, next, napalm)
{
	self endon("kill_thread");

	if(self.ex_airstrike) return;

	self notify("end_airstrike");
	wait( [[level.ex_fpstime]](0.1) );
	self endon("end_airstrike");
	
	self.ex_airstrike = true;
	self.ex_napalm = napalm;

	// wait if needed
	if(!isDefined(delay) || !delay) delay = first;
	wait( [[level.ex_fpstime]](delay) );

	while(self.ex_airstrike)
	{
		// let them know the airstrike is available
		if(!self.ex_napalm)
		{
			if((level.ex_arcade_shaders & 4) == 4) self thread extreme\_ex_player_arcade::showArcadeShader("x2_airstrikeunlock", level.ex_arcade_shaders_perk);
				else self iprintlnbold(&"AIRSTRIKE_READY");
		}
		else
		{
			if((level.ex_arcade_shaders & 4) == 4) self thread extreme\_ex_player_arcade::showArcadeShader("x2_napalmunlock", level.ex_arcade_shaders_perk);
				else self iprintlnbold(&"AIRSTRIKE_READY_NAPALM");
		}

		self playTeamSoundOnPlayer("airstk_ready", 1);
			
		// set up the screen icon
		if(self.ex_napalm) playerHudCreateIcon("wmd_icon", 120, 390, game["wmd_napalm_hudicon"]);
			else playerHudCreateIcon("wmd_icon", 120, 390, game["wmd_airstrike_hudicon"]);

		// monitor for binocular fire
		self thread waitForUse();
		
		// show hint
		self thread playerHudAnnounce(&"WMD_ACTIVATE_HINT");

		// wait until they use airstrike
		self waittill("airstrike_over");

		if((level.ex_arcade_shaders & 4) != 4) self iprintlnbold(&"AIRSTRIKE_WAIT");
		self playTeamSoundOnPlayer("airstk_reload", 3);

		// now wait for one interval
		wait( [[level.ex_fpstime]](next) );

		// randomize napalm again
		if(self.ex_napalm && randomInt(100) > level.ex_wmd_napalm_chance) self.ex_napalm = false;
	}
}	

waitForUse()
{
	self endon("kill_thread");
	self endon("end_airstrike");
	self endon("end_waitforuse");

	self.ex_callingwmd = false;

	for(;;)
	{
		self waittill("binocular_enter");
		if(!self.ex_callingwmd && ((level.ex_store & 2) != 2 || !extreme\_ex_specials::playerPerkIsLocked("cam")))
		{
			self thread waitForBinocUse();
			if(!self.ex_napalm) self thread playerHudAnnounce(&"WMD_AIRSTRIKE_HINT");
				else self thread playerHudAnnounce(&"WMD_NAPALM_HINT");
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

	if((level.ex_arcade_shaders & 4) != 4) self iprintlnbold(&"AIRSTRIKE_RADIO_IN");

	targetpos = self getTargetPosEye();
	friendly = extreme\_ex_player_wmd::friendlyInstrikezone(targetpos);

	if(!level.ex_wmd_speedup)
	{
		self playTeamSoundOnPlayer("airstk_firemission", 3.6);
		for(i = 1; i < 4; i++) self playTeamSoundOnPlayer("airstk_" + randomInt(8), 0.6);
		self playTeamSoundOnPlayer("airstk_pointfuse", 3);
	}

	if(isDefined(targetpos) && isDefined(friendly) && friendly == false)
	{
		// notify threads
		self notify("end_waitforuse");

		playerHudDestroy("wmd_icon");
		if((level.ex_arcade_shaders & 4) != 4) self iprintlnbold(&"AIRSTRIKE_ONWAY");
		self playTeamSoundOnPlayer("airstk_ontheway", 4);
		self.usedweapons = true;

		// the napalm flag has to propagate this way, 'cause it will reset on player death
		level thread fireBarrage(targetpos, self, self.ex_napalm);
	}
	else if(!isDefined(targetpos) && !isDefined(friendly))
	{
		friendly = undefined;
		self iprintlnbold(&"AIRSTRIKE_NOT_VALID");
		self playTeamSoundOnPlayer("airstk_novalid", 3);
	}
	else if(isDefined(friendly) && friendly == true)
	{
		friendly = undefined;
		self iprintlnbold(&"AIRSTRIKE_FRIENDLY_WARNING");
		self playTeamSoundOnPlayer("airstk_frndly", 3);
	}
	else if(isDefined(targetpos) && !isDefined(friendly))
	{
		friendly = undefined;
		self iprintlnbold(&"AIRSTRIKE_TO_CLOSE_WARNING");
		self playTeamSoundOnPlayer("airstk_tooclose", 3);
	}

	self.ex_callingwmd = false;
}

fireBarrage(targetpos, owner, napalm)
{
	// optional alarm
	if(level.ex_wmd_airstrike_alert) playSoundLoc("air_raid");

	// drop flare
	if(level.ex_wmd_flare) playfx(level.ex_effect["flare_indicator"], targetpos);

	// optional flak effects
	if(level.ex_planes_flak) level thread extreme\_ex_ambient_skyeffects::fireFlaks(10);

	// number of planes
	plane_count = 1;
	if(!napalm)
	{
		if(!level.ex_wmd_airstrike_planes) plane_count = 1 + randomInt(3);
			else plane_count = level.ex_wmd_airstrike_planes;
	}

	// create support entity
	airsupport = spawn("script_origin", (0,0,0));

	// preferred angle
	plane_angle = randomInt(360);

	// create planes
	plane_xcount = 0;
	for(i = 0; i < plane_count; i++)
	{
		wait( level.ex_fps_frame );

		// adjust target point
		if(i > 0)
		{
			if(i % 2 == 0) targetpos = posLeft(targetpos, (0,plane_angle,0), 1500);
				else targetpos = posRight(targetpos, (0,plane_angle,0), 1500);
		}

		// drop point
		droppos = getDropPosFromTarget(targetpos, 500);
		if(!isDefined(droppos)) continue;

		// approve distance
		dist = distance(droppos, targetpos);
		if(dist > game["mapArea_Max"][2] + 1000) continue;

		// keep track of airplane requests that make it through
		plane_xcount++;

		// request a slot
		plane_slot = planeSlot(level.PLANE_PURP_WMD);

		// create the airplane
		plane_index = airsupport planeCreate(plane_slot, level.PLANE_TYPE_BOMBER, owner, owner.pers["team"], droppos, plane_angle);

		// add payload to airplane
		if(!napalm) planeAddPayload(plane_index, "airstrike_wmd", targetpos, 4 + randomInt(3), true);
			else planeAddPayload(plane_index, "napalm", targetpos, 4 + randomInt(3), true);

		// fly baby
		thread planeGo(plane_index, "plane_finished");
	}

	// play cockpit comms
	if(isPlayer(owner)) owner thread playCockpitSounds();

	// wait for all planes to finish
	for(i = 0; i < plane_xcount; i++) airsupport waittill("plane_finished");

	// delete support entity
	airsupport delete();

	if(isPlayer(owner)) owner notify ("airstrike_over");
}

playCockpitSounds()
{
	self endon("disconnect");

	self playTeamSoundOnPlayer("pilot_cmg_target", 4);
	if(isPlayer(self)) self playTeamSoundOnPlayer("flack_hang_on", 3);
}
