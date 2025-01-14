
init()
{
	initShaders();
	initHeadIcons();
	if(level.ex_ranksystem) initRanks();
}

initShaders()
{
	// generic, used by almost everything
	[[level.ex_PrecacheShader]]("black");
	[[level.ex_PrecacheShader]]("white");

	// crybaby punishment from rcon
	if(level.ex_rcon) [[level.ex_PrecacheShader]]("exg_crybaby");

	// turrets
	if(level.ex_turrets > 1) [[level.ex_PrecacheShader]]("objpoint_star");
	if( (level.ex_turrets && level.ex_turretoverheat) || (level.ex_heli && level.ex_heli_damagehud) ) [[level.ex_PrecacheShader]]("hud_temperature_gauge");

	// landmines
	if(level.ex_landmines)
	{
		[[level.ex_PrecacheShader]]("mtl_weapon_bbetty_hud");
		if(level.ex_landmines_warning) [[level.ex_PrecacheShader]]("killiconsuicide");
	}

	// tripwires
	if(level.ex_tripwire && level.ex_tripwire_warning) [[level.ex_PrecacheShader]]("killiconsuicide");

	// bullet holes
	if(level.ex_bulletholes)
	{
		[[level.ex_PrecacheShader]]("gfx/custom/bullethit_glass.tga");
		[[level.ex_PrecacheShader]]("gfx/custom/bullethit_glass2.tga");
	}

	// ammo crates
	if(level.ex_amc && level.ex_amc_compass)
	{
		[[level.ex_PrecacheShader]]("compassping_ammocrate");
	}

	// blood on screen or pop helmet
	if(level.ex_bloodonscreen || level.ex_pophelmet)
	{
		[[level.ex_PrecacheShader]]("gfx/impact/flesh_hit2");
		[[level.ex_PrecacheShader]]("gfx/impact/flesh_hitgib");
	}

	// camper monitor
	if(level.ex_anticamp && (
	  (!level.ex_anticamp_punishment || level.ex_anticamp_punishment == 1) || (!level.ex_anticamp_punishment_sniper || level.ex_anticamp_punishment_sniper == 1)))
		[[level.ex_PrecacheShader]]("objpoint_radio");

	// health bar or sprint hud
	if(level.ex_healthbar == 2 || (level.ex_sprint && level.ex_sprinthud))
	{
		[[level.ex_PrecacheShader]]("gfx/hud/hud@health_back.tga");
		[[level.ex_PrecacheShader]]("gfx/hud/hud@health_bar.tga");
	}

	// first aid icon
	if(level.ex_healthbar == 2 || level.ex_medicsystem)
	{
		game["firstaidicon"] = "gfx/hud/hud@health_cross.tga";
		[[level.ex_PrecacheShader]](game["firstaidicon"]);
	}

	// hit blip
	if(level.ex_hitblip) [[level.ex_PrecacheShader]]("gfx/reticle/mg42_cross.tga");

	// wmd hud icons
	if(level.ex_wmd)
	{
		game["wmd_mortar_hudicon"] = "wmd_mortars_hudicon";
		[[level.ex_PrecacheShader]](game["wmd_mortar_hudicon"]);

		game["wmd_artillery_hudicon"] = "wmd_artillery_hudicon";
		[[level.ex_PrecacheShader]](game["wmd_artillery_hudicon"]);

		game["wmd_airstrike_hudicon"] = "wmd_airstrike_hudicon";
		[[level.ex_PrecacheShader]](game["wmd_airstrike_hudicon"]);

		game["wmd_napalm_hudicon"] = "wmd_napalm_hudicon";
		[[level.ex_PrecacheShader]](game["wmd_napalm_hudicon"]);
	}

	// gunship
	if(level.ex_gunship)
	{
		if(!level.ex_rank_statusicons) [[level.ex_PrecacheStatusIcon]]("gunship_statusicon");

		game["wmd_gunship_hudicon"] = "wmd_gunship_hudicon";
		[[level.ex_PrecacheShader]](game["wmd_gunship_hudicon"]);

		if(level.ex_gunship_25mm) [[level.ex_PrecacheShader]]("gunship_overlay_25mm");
		if(level.ex_gunship_40mm) [[level.ex_PrecacheShader]]("gunship_overlay_40mm");
		if(level.ex_gunship_105mm) [[level.ex_PrecacheShader]]("gunship_overlay_105mm");
		if(level.ex_gunship_nuke) [[level.ex_PrecacheShader]]("gunship_overlay_nuke");
		if(level.ex_gunship_grain) [[level.ex_PrecacheShader]]("gunship_overlay_grain");
		if(level.ex_gunship_clock)
		{
			[[level.ex_PrecacheShader]]("hudStopwatch");
			[[level.ex_PrecacheShader]]("hudstopwatchneedle");
		}
	}

	// spawn protection
	if(level.ex_spwn_time)
	{
		game["mod_protect_hudicon"] = "mod_protect_hudicon";
		[[level.ex_PrecacheShader]](game["mod_protect_hudicon"]);
	}

	// arcade shaders
	level.ex_gunship_arcade = 0;
	if(level.ex_arcade_shaders)
	{
		if((level.ex_gunship == 1 && (level.ex_arcade_shaders & 1) == 1) ||
		   (level.ex_gunship == 2 && (level.ex_arcade_shaders & 4) == 4) ||
		   (level.ex_gunship == 3 && (level.ex_arcade_shaders & 2) == 2) ||
		   (level.ex_gunship == 4 && (level.ex_arcade_shaders & 4) == 4)) level.ex_gunship_arcade = 1;
		if((level.ex_store & 2) == 2 && level.ex_gunship_special) level.ex_gunship_arcade = 1;

		if((level.ex_arcade_shaders & 1) == 1)
		{
			[[level.ex_PrecacheShader]]("x2_dominating");
			[[level.ex_PrecacheShader]]("x2_godlike");
			[[level.ex_PrecacheShader]]("x2_holyshit");
			[[level.ex_PrecacheShader]]("x2_humiliation");
			[[level.ex_PrecacheShader]]("x2_killingspree");
			[[level.ex_PrecacheShader]]("x2_rampage");
			[[level.ex_PrecacheShader]]("x2_slaughter");
			[[level.ex_PrecacheShader]]("x2_unstoppable");
			[[level.ex_PrecacheShader]]("x2_wickedsick");
		}

		if(level.ex_ladder && (level.ex_arcade_shaders & 2) == 2)
		{
			[[level.ex_PrecacheShader]]("x2_doublekill");
			[[level.ex_PrecacheShader]]("x2_triplekill");
			[[level.ex_PrecacheShader]]("x2_multikill");
			[[level.ex_PrecacheShader]]("x2_megakill");
			[[level.ex_PrecacheShader]]("x2_ultrakill");
			[[level.ex_PrecacheShader]]("x2_monsterkill");
			[[level.ex_PrecacheShader]]("x2_ludicrouskill");
			[[level.ex_PrecacheShader]]("x2_topgun");
		}

		if(level.ex_wmd && (level.ex_arcade_shaders & 4) == 4)
		{
			[[level.ex_PrecacheShader]]("x2_mortarsunlock");
			[[level.ex_PrecacheShader]]("x2_artilleryunlock");
			[[level.ex_PrecacheShader]]("x2_airstrikeunlock");
			[[level.ex_PrecacheShader]]("x2_napalmunlock");
		}

		if(level.ex_gunship_arcade)
		{
			[[level.ex_PrecacheShader]]("x2_gunshipunlock");
			if(level.ex_gunship_40mm) [[level.ex_PrecacheShader]]("x2_40mmunlock");
			if(level.ex_gunship_105mm) [[level.ex_PrecacheShader]]("x2_105mmunlock");
			if(level.ex_gunship_nuke) [[level.ex_PrecacheShader]]("x2_nukeunlock");
		}

		if((level.ex_arcade_shaders & 16) == 16)
		{
			[[level.ex_PrecacheShader]]("x2_headshot");
			if(level.ex_firstblood) [[level.ex_PrecacheShader]]("x2_firstblood");
		}
	}

	if(level.ex_livestats || (level.ex_overtime && level.ex_overtime_lastman))
	{
		// game["hudicon_x"] icons are precached by maps\mp\gametypes\_hud_teamscore.gsc
		[[level.ex_precacheShader]]("hud_status_alive");
		[[level.ex_precacheShader]]("hud_status_dead");
	}
}

initHeadIcons()
{
	if(level.ex_spwn_time) [[level.ex_PrecacheHeadIcon]](game["headicon_protect"]);

	if(level.ex_rcon && level.ex_crybaby)
	{
		game["headicon_crybaby"] = "headicon_crybaby";
		[[level.ex_PrecacheHeadIcon]](game["headicon_crybaby"]);
	}
}

initRanks()
{
	// ranksystem hudicon definitions
	if(level.ex_rank_hudicons)
	{
		game["hudicon_rank0"] = "private_hudicon";
		game["hudicon_rank1"] = "corporal_hudicon";
		game["hudicon_rank2"] = "sergeant_hudicon";
		game["hudicon_rank3"] = "lieutenant_hudicon";
		game["hudicon_rank4"] = "captain_hudicon";
		game["hudicon_rank5"] = "major_hudicon";
		game["hudicon_rank6"] = "colonel_hudicon";
		game["hudicon_rank7"] = "general_hudicon";

		[[level.ex_PrecacheShader]](game["hudicon_rank0"]);
		[[level.ex_PrecacheShader]](game["hudicon_rank1"]);
		[[level.ex_PrecacheShader]](game["hudicon_rank2"]);
		[[level.ex_PrecacheShader]](game["hudicon_rank3"]);
		[[level.ex_PrecacheShader]](game["hudicon_rank4"]);
		[[level.ex_PrecacheShader]](game["hudicon_rank5"]);
		[[level.ex_PrecacheShader]](game["hudicon_rank6"]);
		[[level.ex_PrecacheShader]](game["hudicon_rank7"]);
	}

	if(level.ex_rank_headicons)
	{
		// ranksystem headicon definitions
		game["headicon_rank0"] = "headicon_privateA";
		game["headicon_rank1"] = "headicon_corpor_a";
		game["headicon_rank2"] = "headicon_sergnt_a";
		game["headicon_rank3"] = "headicon_lieute_a";
		game["headicon_rank4"] = "headicon_captan_a";
		game["headicon_rank5"] = "headicon_major0_a";
		game["headicon_rank6"] = "headicon_colonl_a";
		game["headicon_rank7"] = "headicon_generl_a";

		[[level.ex_PrecacheHeadIcon]](game["headicon_rank0"]);
		[[level.ex_PrecacheHeadIcon]](game["headicon_rank1"]);
		[[level.ex_PrecacheHeadIcon]](game["headicon_rank2"]);
		[[level.ex_PrecacheHeadIcon]](game["headicon_rank3"]);
		[[level.ex_PrecacheHeadIcon]](game["headicon_rank4"]);
		[[level.ex_PrecacheHeadIcon]](game["headicon_rank5"]);
		[[level.ex_PrecacheHeadIcon]](game["headicon_rank6"]);
		[[level.ex_PrecacheHeadIcon]](game["headicon_rank7"]);
	}

	// ranksystem statusicon definitions
	if(level.ex_rank_statusicons)
	{
		game["statusicon_rank0"] = "rank_private";
		game["statusicon_rank1"] = "rank_corporal";
		game["statusicon_rank2"] = "rank_sergeant";
		game["statusicon_rank3"] = "rank_lieutenant";
		game["statusicon_rank4"] = "rank_captain";
		game["statusicon_rank5"] = "rank_major";
		game["statusicon_rank6"] = "rank_colonel";
		game["statusicon_rank7"] = "rank_general";

		[[level.ex_PrecacheStatusIcon]](game["statusicon_rank0"]);
		[[level.ex_PrecacheStatusIcon]](game["statusicon_rank1"]);
		[[level.ex_PrecacheStatusIcon]](game["statusicon_rank2"]);
		[[level.ex_PrecacheStatusIcon]](game["statusicon_rank3"]);
		[[level.ex_PrecacheStatusIcon]](game["statusicon_rank4"]);
		[[level.ex_PrecacheStatusIcon]](game["statusicon_rank5"]);
		[[level.ex_PrecacheStatusIcon]](game["statusicon_rank6"]);
		[[level.ex_PrecacheStatusIcon]](game["statusicon_rank7"]);
	}
}

initPost()
{
	// winner announcement
	if(level.ex_announcewinner)
	{
		switch(game["allies"])
		{
			case "american":
				game["winner_draw"] = "x2flag_german_american";
				break;
			case "british":
				game["winner_draw"] = "x2flag_german_british";
				break;
			default:
				game["winner_draw"] = "x2flag_german_russian";
				break;
		}

		game["winner_allies"] = "x2flag_" + game["allies"];
		game["winner_axis"] = "x2flag_german";

		[[level.ex_PrecacheShader]](game["winner_draw"]);
		[[level.ex_PrecacheShader]](game["winner_allies"]);
		[[level.ex_PrecacheShader]](game["winner_axis"]);
	}
}
