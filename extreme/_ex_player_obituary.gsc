#include maps\mp\gametypes\_weapons;
#include extreme\_ex_weapons;

main(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc)
{
	self endon("disconnect");

	if(level.ex_deathsound && randomInt(100) < 50) self thread extreme\_ex_main_utils::playSoundLoc("generic_death", self.origin, "death");

	// death music override possibility (preventing overlapping sounds)
	self.pers["deathmusic"] = true;

	// no death music when jukebox is playing
	if(level.ex_jukebox && isDefined(self.pers["jukebox"]) && self.pers["jukebox"].playing) self.pers["deathmusic"] = false;

	// do not report forced suicides
	if(isDefined(attacker) && isPlayer(attacker) && attacker != self)
	{
		if( (isDefined(self.ex_forcedsuicide) && self.ex_forcedsuicide) || (isDefined(self.switching_teams) && self.switching_teams) )
		{
			self thread playDeathMusic();
			return;
		}
	}

	// default values for obits
	self.ex_obmonamsg = false;
	self.ex_obmonpmsg = false;
	self.ex_obmonpsnd = false;

	// 0 = no obituary       - with stats (---)
	// 1 = stock obituary    - with stats (---)
	// 2 = stock obituary    - with stats and personal sounds (--S)
	// 3 = stock obituary    - with stats and personal messages (-M-)
	// 4 = stock obituary    - with stats, personal messages and personal sounds (-MS)
	// 5 = eXtreme+ obituary - with stats (X--)
	// 6 = eXtreme+ obituary - with stats and personal sounds (X-S)
	// 7 = eXtreme+ obituary - with stats and personal message (XM-)
	// 8 = eXtreme+ obituary - with stats, personal messages and personal sounds (XMS)
	if(level.ex_obituary >= 5) self.ex_obmonamsg = true;
	if(level.ex_obituary == 3 || level.ex_obituary == 4 || level.ex_obituary == 7 || level.ex_obituary == 8) self.ex_obmonpmsg = true;
	if(level.ex_obituary == 2 || level.ex_obituary == 4 || level.ex_obituary == 6 || level.ex_obituary == 8) self.ex_obmonpsnd = true;

	// no personal messages and sounds if bash-only mode
	if(level.ex_bash_only)
	{
		self.ex_obmonpmsg = false;
		self.ex_obmonpsnd = false;
	}

	// no messages and sounds if forced suicide or switching teams
	self.ex_obmonsuicide = 0;
	if(isDefined(attacker) && isPlayer(attacker) && attacker == self)
	{
		if(isDefined(self.switching_teams) && self.switching_teams) self.ex_obmonsuicide = 1;
		if(isDefined(self.ex_forcedsuicide) && self.ex_forcedsuicide) self.ex_obmonsuicide = 2;
		if(self.ex_obmonsuicide)
		{
			self.ex_obmonamsg = false;
			self.ex_obmonpmsg = false;
			self.ex_obmonpsnd = false;
		}
	}

	// stock obituary (conditional)
	if(level.ex_obituary && level.ex_obituary <= 4) obituary(self, attacker, sWeapon, sMeansOfDeath);

	// extreme obituary (unconditional so we always get the stats)
	thread extremeobituary(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);
}

extremeobituary(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc)
{
	self endon("disconnect");

	// MBOT weapon conversions
	if(level.ex_mbot && isDefined(attacker) && isPlayer(attacker) && isDefined(attacker.pers["isbot"]))
		sWeapon = botToNormalWeapon(attacker, sWeapon);

	// VIP pistol conversion
	if(level.ex_currentgt == "vip") sWeapon = vipToNormalPistol(sWeapon);

	// MOD conversions
	if(sMeansOfDeath == "MOD_CRUSH")
	{
		switch(sWeapon)
		{
			case "dummy1_mp": sWeapon = "beartrap_mp"; sMeansOfDeath = "MOD_BEARTRAP"; break; // breaktrap perk
			case "dummy2_mp": sWeapon = "quadrotor_mp"; sMeansOfDeath = "MOD_QUADROTOR"; break; // quadrotor perk
		}
	}
	else if(sMeansOfDeath == "MOD_EXPLOSIVE")
	{
		switch(sWeapon)
		{
			case "mortar_mp": sMeansOfDeath = "MOD_MORTAR"; break; // ambient mortars
			case "artillery_mp": sMeansOfDeath = "MOD_ARTILLERY"; break; // ambient artillery
			case "planebomb_mp": sMeansOfDeath = "MOD_AIRSTRIKE"; break; // ambient airstrike
			case "tripwire_mp": sMeansOfDeath = "MOD_TRIPWIRE"; break; // tripwire
			case "landmine_mp": sMeansOfDeath = "MOD_LANDMINE"; break; // landmine
			case "dummy1_mp": sWeapon = "gmlmissile_mp"; sMeansOfDeath = "MOD_GMLMISSILE"; break; // GML perk missile
			case "dummy2_mp": sWeapon = "helimissile_mp"; sMeansOfDeath = "MOD_HELIMISSILE"; break; // helicopter perk missile
			case "dummy3_mp": sWeapon = "flakprojectile_mp"; sMeansOfDeath = "MOD_FLAKPROJECTILE"; break; // flak perk shell
		}
	}
	else if(sMeansOfDeath == "MOD_GRENADE")
	{
		switch(sWeapon)
		{
			case "mortar_mp": sMeansOfDeath = "MOD_MORTAR"; break; // WMD mortars
			case "artillery_mp": sMeansOfDeath = "MOD_ARTILLERY"; break; // WMD artillery
			case "planebomb_mp": sMeansOfDeath = "MOD_AIRSTRIKE"; break; // WMD airstrike
			case "dummy1_mp": sWeapon = "monkey_mp"; sMeansOfDeath = "MOD_MONKEY"; break; // monkey perk
			case "dummy2_mp": sWeapon = "helitube_mp"; sMeansOfDeath = "MOD_HELITUBE"; break; // helicopter perk grenade
			case "dummy3_mp": sWeapon = "ugvrocket_mp"; sMeansOfDeath = "MOD_UGVROCKET"; break; // UGV perk missile
		}
	}
	else if(sMeansOfDeath == "MOD_GRENADE_SPLASH")
	{
		switch(sWeapon)
		{
			case "fire_mp": sMeansOfDeath = "MOD_FIRENADE"; break;
			case "smoke_grenade_american_fire_mp": sMeansOfDeath = "MOD_FIRENADE"; break;
			case "smoke_grenade_british_fire_mp": sMeansOfDeath = "MOD_FIRENADE"; break;
			case "smoke_grenade_german_fire_mp": sMeansOfDeath = "MOD_FIRENADE"; break;
			case "smoke_grenade_russian_fire_mp": sMeansOfDeath = "MOD_FIRENADE"; break;
			case "gas_mp": sMeansOfDeath = "MOD_GASNADE"; break;
			case "smoke_grenade_american_gas_mp": sMeansOfDeath = "MOD_GASNADE"; break;
			case "smoke_grenade_british_gas_mp": sMeansOfDeath = "MOD_GASNADE"; break;
			case "smoke_grenade_german_gas_mp": sMeansOfDeath = "MOD_GASNADE"; break;
			case "smoke_grenade_russian_gas_mp": sMeansOfDeath = "MOD_GASNADE"; break;
			case "satchel_mp": sMeansOfDeath = "MOD_SATCHELCHARGE"; break;
			case "smoke_grenade_american_satchel_mp": sMeansOfDeath = "MOD_SATCHELCHARGE"; break;
			case "smoke_grenade_british_satchel_mp": sMeansOfDeath = "MOD_SATCHELCHARGE"; break;
			case "smoke_grenade_german_satchel_mp": sMeansOfDeath = "MOD_SATCHELCHARGE"; break;
			case "smoke_grenade_russian_satchel_mp": sMeansOfDeath = "MOD_SATCHELCHARGE"; break;
		}
	}
	else if(sMeansOfDeath == "MOD_PROJECTILE" || sMeansOfDeath == "MOD_PROJECTILE_SPLASH")
	{
		switch(sWeapon)
		{
			case "planebomb_mp": sMeansOfDeath = "MOD_NAPALM"; break; // WMD napalm
			case "dummy1_mp": sWeapon = "sentrygun_mp"; sMeansOfDeath = "MOD_SENTRYGUN"; break; // sentrygun perk
			case "dummy2_mp": sWeapon = "heligun_mp"; sMeansOfDeath = "MOD_HELIGUN"; break; // helicopter perk gun
			case "dummy3_mp": sWeapon = "ugvgun_mp"; sMeansOfDeath = "MOD_UGVGUN"; break; // UGV perk gun
			case "gunship_25mm_mp": sMeansOfDeath = "MOD_GUNSHIP_25MM"; break; // gunship 25mm projectile
			case "gunship_40mm_mp": sMeansOfDeath = "MOD_GUNSHIP_40MM"; break; // gunship 40mm projectile
			case "gunship_105mm_mp": sMeansOfDeath = "MOD_GUNSHIP_105MM"; break; // gunship 105mm projectile
			case "gunship_nuke_mp": sMeansOfDeath = "MOD_GUNSHIP_NUKE"; break; // gunship nuke projectile
			default:
				if(isWeaponType(sWeapon, "ft")) sMeansOfDeath = "MOD_FLAMETHROWER"; // [verified]
					else if(isWeaponType(sWeapon, "rl")) sMeansOfDeath = "MOD_RPG";
						else if(isWeaponType(sWeapon, "gl")) sMeansOfDeath = "MOD_GL"; // [verified]
				break;
		}
	}
	else if(sMeansOfDeath == "MOD_HEAD_SHOT" || sMeansOfDeath == "MOD_PISTOL_BULLET")
	{
		if(isWeaponType(sWeapon, "knife")) sMeansOfDeath = "MOD_KNIFE";
	}
	else if(sMeansOfDeath == "MOD_SUICIDE")
	{
		if(sWeapon == "dummy1_mp") sMeansOfDeath = "MOD_DROWNING";
	}

	// obituary handling
	if(sMeansOfDeath == "MOD_TRIGGER_HURT")
	{
		obitnad("", "unknown", false);
	}
	else if(sMeansOfDeath == "MOD_FALLING")
	{
		obitnad("fallingdeath", "falling", true);
	}
	// ambient fx deaths
	else if(isDefined(attacker) && !isPlayer(attacker))
	{
		switch(sMeansOfDeath)
		{
			case "MOD_MORTAR": obitnad("mortardeath", "ambient", false); break;
			case "MOD_ARTILLERY": obitnad("artillerydeath", "ambient", false); break;
			case "MOD_AIRSTRIKE": obitnad("airstrikedeath", "ambient", false); break;
			case "MOD_EXPLOSIVE": obitnad("", "ambient", false); break;
		}
	}
	// real player kills and deaths
	else if(isDefined(attacker) && isPlayer(attacker))
	{
		// killed themself
		if(attacker == self)
		{
			switch(sMeansOfDeath)
			{
				case "MOD_EXPLOSIVE": obitnad("minefielddeath", "minefield", true); break;
				case "MOD_DROWNING": obitnad("", "drowning", true); break;
				case "MOD_GRENADE_SPLASH": if(isWeaponType(sWeapon, "frag") || isWeaponType(sWeapon, "super")) obitnad("grenadedeath", "selfnade", false); break;
				case "MOD_FIRENADE": obitnad("firenadedeath", "selffirenade", false); break;
				case "MOD_GASNADE": obitnad("gasnadedeath", "selfgasnade", false); break;
				case "MOD_SATCHELCHARGE": obitnad("satchelchargedeath", "selfsatchelcharge", false); break;
				case "MOD_MORTAR": obitnad("mortardeath", "selfmortar", false); break;
				case "MOD_ARTILLERY": obitnad("artillerydeath", "selfartillery", false); break;
				case "MOD_AIRSTRIKE": obitnad("airstrikedeath", "selfairstrike", false); break;
				case "MOD_NAPALM": obitnad("napalmdeath", "selfnapalm", false); break;
				case "MOD_RPG": obitnad("panzerdeath", "selfrpg", false); break;
				case "MOD_TRIPWIRE": obitnad("tripwiredeath", "selftripwire", false); break;
				case "MOD_LANDMINE": obitnad("landminedeath", "selflandmine", false); break;
				case "MOD_FLAMETHROWER": obitnad("flamethrowerdeath", "selfflamethrower", false); break;
				case "MOD_KNIFE": obitnad("knifedeath", "selfknife", false); break;
				case "MOD_SUICIDE":
					if(!self.ex_obmonsuicide)
					{
						if(level.ex_kamikaze && isWeaponType(self.ex_lastoffhand, "kamikaze")) obitnad("grenadedeath", "selfkamikaze", true);
							else obitnad("grenadedeath", "selfnades", true); break;
					}
					else obitnad("suicide", "", false);
					break;
			}
		}
		// did not kill themself
		else if(!level.ex_teamplay || attacker.pers["team"] != self.pers["team"])
		{
			if(isSpecialMeansOfDeath(sMeansOfDeath)) // special MOD
			{
				switch(sMeansOfDeath)
				{
					case "MOD_MELEE":
					{
						if(isWeaponType(sWeapon, "knife")) // register knife bash as normal kill
							obitad(attacker, "knifekill", "knifedeath", "knifewhip", sMeansOfDeath, sWeapon);
						else
						{
							if(sHitLoc == "head") obitad(attacker, "bashkill", "bashdeath", "bashkill_head", sMeansOfDeath, sWeapon);
								else obitad(attacker, "bashkill", "bashdeath", "bashkill", sMeansOfDeath, sWeapon);

							if(!level.ex_bash_only)
							{
								if((level.ex_arcade_shaders & 16) == 16) self thread extreme\_ex_player_arcade::showArcadeShader("x2_humiliation", level.ex_arcade_shaders_extra);
									else if(self.ex_obmonpmsg) self iprintlnbold(&"OBITUARY_HUMILIATION");
								if(self.ex_obmonpsnd) self playLocalSound("humiliation");
							}
						}
						break;
					}

					case "MOD_HEAD_SHOT":
					{
						obitad(attacker, "headshotkill", "headshotdeath", "", sMeansOfDeath, sWeapon);
						if(isWeaponType(sWeapon, "sniper")) obitstat(attacker, "sniperkill", "sniperdeath");
						obitmain(attacker, sWeapon, sHitLoc, false);
						if((level.ex_arcade_shaders & 16) == 16) attacker thread extreme\_ex_player_arcade::showArcadeShader("x2_headshot", level.ex_arcade_shaders_extra);
							else if(self.ex_obmonpmsg) attacker iprintlnbold(&"OBITUARY_HEADSHOT");
						if(self.ex_obmonpsnd) attacker playLocalSound("headshot");
						break;
					}

					case "MOD_GRENADE_SPLASH":
					{
						if(isWeaponType(sWeapon, "frag") || isWeaponType(sWeapon, "super"))
							obitad(attacker, "grenadekill", "grenadedeath", "explosive", sMeansOfDeath, sWeapon);
						break;
					}

					case "MOD_KNIFE": obitad(attacker, "knifekill", "knifedeath", "knife", sMeansOfDeath, sWeapon); break;
					case "MOD_MORTAR": obitad(attacker, "mortarkill", "mortardeath", "explosive", sMeansOfDeath, sWeapon); break;
					case "MOD_ARTILLERY": obitad(attacker, "artillerykill", "artillerydeath", "explosive", sMeansOfDeath, sWeapon); break;
					case "MOD_AIRSTRIKE": obitad(attacker, "airstrikekill", "airstrikedeath", "explosive", sMeansOfDeath, sWeapon); break;
					case "MOD_NAPALM": obitad(attacker, "napalmkill", "napalmdeath", "napalm", sMeansOfDeath, sWeapon); break;
					case "MOD_FIRENADE": obitad(attacker, "firenadekill", "firenadedeath", "firenade", sMeansOfDeath, sWeapon); break;
					case "MOD_GASNADE": obitad(attacker, "gasnadekill", "gasnadedeath", "gasnade", sMeansOfDeath, sWeapon); break;
					case "MOD_SATCHELCHARGE": obitad(attacker, "satchelchargekill", "satchelchargedeath", "satchelcharge", sMeansOfDeath, sWeapon); break;
					case "MOD_TRIPWIRE": obitad(attacker, "tripwirekill", "tripwiredeath", "explosive", sMeansOfDeath, sWeapon); break;
					case "MOD_LANDMINE": obitad(attacker, "landminekill", "landminedeath", "explosive", sMeansOfDeath, sWeapon); break;
					case "MOD_GUNSHIP_25MM":
					case "MOD_GUNSHIP_40MM":
					case "MOD_GUNSHIP_105MM":
					case "MOD_GUNSHIP_NUKE": obitad(attacker, "gunshipkill", "gunshipdeath", "explosive", sMeansOfDeath, sWeapon); break;
					case "MOD_RPG": obitad(attacker, "panzerkill", "panzerdeath", "rpg", sMeansOfDeath, sWeapon); break;
					case "MOD_BEARTRAP": obitad(attacker, "", "", "beartrap", sMeansOfDeath, sWeapon); break;
					case "MOD_MONKEY": obitad(attacker, "", "", "monkey", sMeansOfDeath, sWeapon); break;
					case "MOD_FLAMETHROWER": obitad(attacker, "flamethrowerkill", "flamethrowerdeath", "flamethrower", sMeansOfDeath, sWeapon); break;
					case "MOD_FLAKPROJECTILE": obitad(attacker, "", "", "flakprojectile", sMeansOfDeath, sWeapon); break;
					case "MOD_GMLMISSILE": obitad(attacker, "", "", "gmlmissile", sMeansOfDeath, sWeapon); break;
					case "MOD_SENTRYGUN": obitad(attacker, "", "", "sentrygun", sMeansOfDeath, sWeapon); break;
					case "MOD_QUADROTOR": obitad(attacker, "", "", "quadrotor", sMeansOfDeath, sWeapon); break;
					case "MOD_HELIGUN": obitad(attacker, "", "", "heligun", sMeansOfDeath, sWeapon); break;
					case "MOD_HELIMISSILE": obitad(attacker, "", "", "helimissile", sMeansOfDeath, sWeapon); break;
					case "MOD_HELITUBE": obitad(attacker, "", "", "helitube", sMeansOfDeath, sWeapon); break;
					case "MOD_UGVGUN": obitad(attacker, "", "", "ugvgun", sMeansOfDeath, sWeapon); break;
					case "MOD_UGVROCKET": obitad(attacker, "", "", "ugvrocket", sMeansOfDeath, sWeapon); break;
				}
			}
			// not special MOD - death by sniper
			else if(isWeaponType(sWeapon, "sniper"))
			{
				obitad(attacker, "sniperkill", "sniperdeath", "", sMeansOfDeath, sWeapon);
				obitmain(attacker, sWeapon, sHitLoc, false);
				sMeansOfDeath = "MOD_IGNORE";
			}
			// not special MOD - standard death
			else obitmain(attacker, sWeapon, sHitLoc, true);
		}
		// team kills
		else if(level.ex_teamplay && attacker.pers["team"] == self.pers["team"])
		{
			// special MOD
			if(isSpecialMeansOfDeath(sMeansOfDeath))
			{
				switch(sMeansOfDeath)
				{
					case "MOD_MELEE":
					{
						if(isWeaponType(sWeapon, "knife")) obitteam(attacker, "knifewhiptk", sMeansOfDeath, sWeapon);
							else obitteam(attacker, "bashtk", sMeansOfDeath, sWeapon);
						break;
					}

					case "MOD_HEAD_SHOT": obitteam(attacker, "headshottk", sMeansOfDeath, sWeapon); break;
					case "MOD_KNIFE": obitteam(attacker, "knifetk", sMeansOfDeath, sWeapon); break;
					case "MOD_GRENADE_SPLASH":
					case "MOD_MORTAR":
					case "MOD_ARTILLERY":
					case "MOD_AIRSTRIKE":
					case "MOD_TRIPWIRE":
					case "MOD_LANDMINE":
					case "MOD_GUNSHIP_25MM":
					case "MOD_GUNSHIP_40MM":
					case "MOD_GUNSHIP_105MM":
					case "MOD_GUNSHIP_NUKE":
					case "MOD_HELITUBE":
					case "MOD_HELIMISSILE":
					case "MOD_GMLMISSILE":
					case "MOD_FLAKPROJECTILE": obitteam(attacker, "explosivetk", sMeansOfDeath, sWeapon); break;
					case "MOD_NAPALM": obitteam(attacker, "napalmtk", sMeansOfDeath, sWeapon); break;
					case "MOD_FIRENADE": obitteam(attacker, "firenadetk", sMeansOfDeath, sWeapon); break;
					case "MOD_GASNADE": obitteam(attacker, "gasnadetk", sMeansOfDeath, sWeapon); break;
					case "MOD_SATCHELCHARGE": obitteam(attacker, "satchelchargetk", sMeansOfDeath, sWeapon); break;
					case "MOD_RPG": obitteam(attacker, "rpgtk", sMeansOfDeath, sWeapon); break;
					case "MOD_FLAMETHROWER": obitteam(attacker, "flamethrowertk", sMeansOfDeath, sWeapon); break;
				}
			}
			// not special MOD - death by sniping teammate
			else if(isWeaponType(sWeapon, "sniper"))
			{
				obitteam(attacker, "snipertk", sMeansOfDeath, sWeapon);
				sMeansOfDeath = "MOD_IGNORE";
			}
			// not special MOD - death by teammate
			else obitteam(attacker, "teamkill", sMeansOfDeath, sWeapon);
		}

		if(!self.ex_obmonsuicide)
		{
			// first blood
			if(level.ex_firstblood && !level.ex_firstblood_done)
			{
				if(attacker != self)
				{
					if((level.ex_arcade_shaders & 16) == 16) attacker thread extreme\_ex_player_arcade::showArcadeShader("x2_firstblood", level.ex_arcade_shaders_extra);
					if(level.ex_reward_firstblood && (!level.ex_teamplay || attacker.pers["team"] != self.pers["team"])) attacker thread [[level.ex_scorePlayer]](level.ex_reward_firstblood, "bonus");
				}

				players = level.players;
				for(i = 0; i < players.size; i++)
				{
					if(players[i] != self)
					{
						players[i] playLocalSound("firstblood");
						players[i] iprintlnbold(&"OBITUARY_FIRSTBLOOD_ALL", [[level.ex_pname]](attacker));
						if(!level.ex_teamplay || attacker.pers["team"] != self.pers["team"]) players[i] iprintlnbold(&"OBITUARY_FIRSTBLOOD_VICTIM", [[level.ex_pname]](self));
							else if(level.ex_teamplay && attacker != self && attacker.pers["team"] == self.pers["team"]) players[i] iprintlnbold(&"OBITUARY_FIRSTBLOOD_VICTIM_TEAM", [[level.ex_pname]](self));
								else if(attacker == self) players[i] iprintlnbold(&"OBITUARY_FIRSTBLOOD_VICTIM_SELF");
					}
				}

				self iprintlnbold(&"OBITUARY_FIRSTBLOOD_SELF");
				self playlocalsound("whyami");
				self.pers["deathmusic"] = false;
				level.ex_firstblood_done = true;
			}

			if(attacker != self)
			{
				// gunship weapon unlock
				if( (level.ex_gunship || level.ex_gunship_special) && getsubstr(sMeansOfDeath, 0, 11) == "MOD_GUNSHIP")
					level thread extreme\_ex_main_gunship::gunshipWeaponUnlock(attacker);
			}

			// check killing spree, streaks and quick kill ladder
			self thread extreme\_ex_stats_streaks::checkStreaks(attacker, sWeapon);
		}

		// stats HUD
		if(level.ex_statshud) attacker thread extreme\_ex_stats_hud::showStatsHUD();
	}

	self thread playDeathMusic();
}

playDeathMusic()
{
	if(level.ex_deathmusic && self.pers["deathmusic"] && !self.pers["specmusic"] && !level.ex_roundbased)
		self playLocalSound("death_music");
}

isSpecialMeansOfDeath(sMeansOfDeath)
{
	switch(sMeansOfDeath)
	{
		case "MOD_AIRSTRIKE":
		case "MOD_ARTILLERY":
		case "MOD_BEARTRAP":
		case "MOD_DROWNING":
		case "MOD_EXPLOSIVE":
		case "MOD_FALLING":
		case "MOD_FIRENADE":
		case "MOD_FLAKPROJECTILE":
		case "MOD_FLAMETHROWER":
		case "MOD_GASNADE":
		case "MOD_GMLMISSILE":
		case "MOD_GRENADE":
		case "MOD_GRENADE_SPLASH":
		case "MOD_GUNSHIP_105MM":
		case "MOD_GUNSHIP_25MM":
		case "MOD_GUNSHIP_40MM":
		case "MOD_GUNSHIP_NUKE":
		case "MOD_HEAD_SHOT":
		case "MOD_HELIGUN":
		case "MOD_HELIMISSILE":
		case "MOD_HELITUBE":
		case "MOD_IGNORE":
		case "MOD_KNIFE":
		case "MOD_LANDMINE":
		case "MOD_MELEE":
		case "MOD_MONKEY":
		case "MOD_MORTAR":
		case "MOD_NAPALM":
		case "MOD_PROJECTILE":
		case "MOD_QUADROTOR":
		case "MOD_RPG":
		case "MOD_SATCHELCHARGE":
		case "MOD_SENTRYGUN":
		case "MOD_SUICIDE":
		case "MOD_TRIPWIRE":
		case "MOD_UGVGUN":
		case "MOD_UGVROCKET": return(true);
	}

	return(false);
}

// special detection - no attacker defined
obitnad(vartype, amsg, issuicide)
{
	self endon("disconnect");

	if(vartype != "") self.pers[vartype]++;
	if(issuicide)
	{
		self.pers["kill"]--;
		self.pers["suicide"]++;
	}

	if(amsg != "")
	{
		if(self.ex_obmonpmsg) self showpmsg(amsg);
		if(self.ex_obmonamsg) self showamsg(amsg);
	}
}

// special detection - attacker defined
obitad(attacker, atvt, vivt, amsg, sMeansOfDeath, sWeapon)
{
	self endon("disconnect");

	if(!self.ex_confirmkill)
	{
		attacker.pers["kill"]++;
		if(atvt != "") attacker.pers[atvt]++;
		if(vivt != "") self.pers[vivt]++;
	}
	else
	{
		if(atvt != "") extreme\_ex_main_killconfirmed::kcStatsAttacker(self.ex_confirmkill, atvt);
		if(vivt != "") extreme\_ex_main_killconfirmed::kcStatsVictim(self.ex_confirmkill, vivt);
	}

	if(amsg != "")
	{
		attacker_weapon = getWeaponName(sWeapon);
		
		if(sMeansOfDeath == "MOD_MELEE")
		{
			if(isWeaponType(sWeapon, "pistol"))
			{
				if(self.ex_obmonpmsg) self showpmsg("pistolwhip");
				if(self.ex_obmonamsg)
				{
					self showamsg("pistolwhip");
					if(UseAn(sWeapon)) iprintln(&"OBITUARY_BY_USING_AN", [[level.ex_pname]](attacker), attacker_weapon);
						else iprintln(&"OBITUARY_BY_USING_A", [[level.ex_pname]](attacker), attacker_weapon);
				}
			}
			else if(isWeaponType(sWeapon, "knife"))
			{
				if(self.ex_obmonpmsg) self showpmsg("knifewhip");
				if(self.ex_obmonamsg)
				{
					self showamsg("knifewhip");
					if(UseAn(sWeapon)) iprintln(&"OBITUARY_BY_USING_AN", [[level.ex_pname]](attacker), attacker_weapon);
						else iprintln(&"OBITUARY_BY_USING_A", [[level.ex_pname]](attacker), attacker_weapon);
				}
			}
			else
			{
				if(self.ex_obmonpmsg) self showpmsg(amsg);
				if(self.ex_obmonamsg)
				{
					self showamsg(amsg);
					if(UseAn(sWeapon)) iprintln(&"OBITUARY_BY_USING_BUTT_AN", [[level.ex_pname]](attacker), attacker_weapon);
						else iprintln(&"OBITUARY_BY_USING_BUTT_A", [[level.ex_pname]](attacker), attacker_weapon);
				}
			}
		}
		else
		{
			if(self.ex_obmonpmsg) self showpmsg(amsg);
			if(self.ex_obmonamsg)
			{
				self showamsg(amsg);
				if(UseAn(sWeapon)) iprintln(&"OBITUARY_BY_USING_AN", [[level.ex_pname]](attacker), attacker_weapon);
					else iprintln(&"OBITUARY_BY_USING_A", [[level.ex_pname]](attacker), attacker_weapon);
			}
		}
	}
}

// killed by teammate
obitteam(attacker, amsg, sMeansOfDeath, sWeapon)
{
	self endon("disconnect");

	if(!level.ex_sinbin) attacker.pers["teamkill"]++;
	attacker.pers["kill"]--;

	if(amsg != "")
	{
		attacker_weapon = getWeaponName(sWeapon);
	
		if(sMeansOfDeath == "MOD_MELEE")
		{
			if(isWeaponType(sWeapon, "pistol"))
			{
				if(self.ex_obmonpmsg) self showpmsg("pistolwhiptk");
				if(self.ex_obmonamsg)
				{
					self showamsg("pistolwhiptk");
					if(UseAn(sWeapon)) iprintln(&"OBITUARY_BY_USING_AN", [[level.ex_pname]](attacker), attacker_weapon);
						else iprintln(&"OBITUARY_BY_USING_A", [[level.ex_pname]](attacker), attacker_weapon);
				}
			}
			else if(isWeaponType(sWeapon, "knife"))
			{
				if(self.ex_obmonpmsg) self showpmsg("knifewhiptk");
				if(self.ex_obmonamsg)
				{
					self showamsg("knifewhiptk");
					if(UseAn(sWeapon)) iprintln(&"OBITUARY_BY_USING_AN", [[level.ex_pname]](attacker), attacker_weapon);
						else iprintln(&"OBITUARY_BY_USING_A", [[level.ex_pname]](attacker), attacker_weapon);
				}
			}
			else
			{
				if(self.ex_obmonpmsg) self showpmsg(amsg);
				if(self.ex_obmonamsg)
				{
					self showamsg(amsg);
					if(UseAn(sWeapon)) iprintln(&"OBITUARY_BY_USING_BUTT_AN", [[level.ex_pname]](attacker), attacker_weapon);
						else iprintln(&"OBITUARY_BY_USING_BUTT_A", [[level.ex_pname]](attacker), attacker_weapon);
				}
			}
		}
		else
		{
			if(self.ex_obmonpmsg) self showpmsg(amsg);
			if(self.ex_obmonamsg)
			{
				self showamsg(amsg);
				if(UseAn(sWeapon)) iprintln(&"OBITUARY_BY_USING_AN", [[level.ex_pname]](attacker), attacker_weapon);
					else iprintln(&"OBITUARY_BY_USING_A", [[level.ex_pname]](attacker), attacker_weapon);
			}
		}
	}
}

// standard weapons
obitmain(attacker, sWeapon, sHitLoc, updstat)
{
	self endon("disconnect");

	if(updstat && !self.ex_confirmkill) attacker.pers["kill"]++;

	showdist = false;
	calcdist = 0;

	range = int(distance(attacker.origin, self.origin));
	if(isDefined(range))
	{
		if(level.ex_obituary_unit == 1)
		{
			calcdist = int(range * 0.02778); // Range in Yards
			if(calcdist > 9) showdist = true;
		}
		else
		{
			calcdist = int(range * 0.0254); // Range in Metres
			if(calcdist > 3) showdist = true;
		}

		attacker thread obitlongstat("longdist", calcdist);
		if(sHitloc == "head") attacker thread obitlongstat("longhead", calcdist);
	}

	if(!self.ex_obmonamsg) return;

	if(sHitLoc != "none")
	{
		hitloc = gethitlocstringname(sHitLoc);
		iprintln(&"OBITUARY_KILLED_HITLOC", [[level.ex_pname]](self), hitloc);
	}

	attacker_weapon = getWeaponName(sWeapon);

	if(showdist)
	{
		if(UseAn(sWeapon)) iprintln(&"OBITUARY_BY_USING_AN", [[level.ex_pname]](attacker), attacker_weapon);
			else iprintln(&"OBITUARY_BY_USING_A", [[level.ex_pname]](attacker), attacker_weapon);

		if(level.ex_obituary_range == 1 || (level.ex_obituary_range == 2 && isWeaponType(sWeapon, "sniper")) )
		{
			if(level.ex_obituary_unit == 1) iprintln(&"OBITUARY_YARDS", calcdist);
				else iprintln(&"OBITUARY_METRES", calcdist);
		}
	}
	else
	{
		if(UseAn(sWeapon)) iprintln(&"OBITUARY_BY_USING_CLOSE_AN", [[level.ex_pname]](attacker), attacker_weapon);
			else iprintln(&"OBITUARY_BY_USING_CLOSE_A", [[level.ex_pname]](attacker), attacker_weapon);
	}
}

// special stat update
obitstat(attacker, atvt, vivt)
{
	self endon("disconnect");

	if(!self.ex_confirmkill)
	{
		if(atvt != "") attacker.pers[atvt]++;
		if(vivt != "") self.pers[vivt]++;
	}
	else
	{
		if(atvt != "") extreme\_ex_main_killconfirmed::kcStatsAttacker(self.ex_confirmkill, atvt);
		if(vivt != "") extreme\_ex_main_killconfirmed::kcStatsVictim(self.ex_confirmkill, vivt);
	}
}

obitlongstat(stat, value)
{
	self endon("disconnect");

	if(value > self.pers[stat]) self.pers[stat] = value;
}

showamsg(message)
{
	self endon("disconnect");

	if(!isDefined(message)) return(undefined);

	msg = [];

	switch(message)
	{
		case "unknown":
			msg[0] = &"OBITUARY_UNKNOWN_MSG_0";
			msg[1] = &"OBITUARY_UNKNOWN_MSG_1";
			msg[2] = &"OBITUARY_UNKNOWN_MSG_2";
			break;

		case "falling":
			msg[0] = &"OBITUARY_FALLING_MSG_0";
			msg[1] = &"OBITUARY_FALLING_MSG_1";
			msg[2] = &"OBITUARY_FALLING_MSG_2";
			break;

		case "ambient":
			msg[0] = &"OBITUARY_AMBIENT_MSG_0";
			break;

		// pistol
		case "pistolwhip":
			msg[0] = &"OBITUARY_PISTOL_WHIP";
			break;

		case "pistolwhiptk":
			msg[0] = &"OBITUARY_PISTOL_WHIP_TK";
			break;

		// knife
		case "knife":
			msg[0] = &"OBITUARY_KNIFE_MSG_0";
			msg[1] = &"OBITUARY_KNIFE_MSG_1";
			break;

		case "knifetk":
			msg[0] = &"OBITUARY_KNIFETK_MSG_0";
			msg[1] = &"OBITUARY_KNIFETK_MSG_1";
			break;

		case "knifewhip":
			msg[0] = &"OBITUARY_KNIFE_WHIP";
			break;

		case "knifewhiptk":
			msg[0] = &"OBITUARY_KNIFE_WHIP_TK";
			break;

		case "selfknife":
			msg[0] = &"OBITUARY_KNIFESELF_MSG_0";
			break;

		// grenade
		case "selfnade":
			msg[0] = &"OBITUARY_SELFNADE_MSG_0";
			msg[1] = &"OBITUARY_SELFNADE_MSG_1";
			break;

		case "selfnades":
			msg[0] = &"OBITUARY_SELFNADES_MSG_0";
			msg[1] = &"OBITUARY_SELFNADES_MSG_1";
			break;

		case "selfkamikaze":
			msg[0] = &"OBITUARY_SELFKAMIKAZE_MSG_0";
			msg[1] = &"OBITUARY_SELFKAMIKAZE_MSG_1";
			break;

		// fire grenades
		case "firenade":
			msg[0] = &"OBITUARY_FIRENADE_MSG_0";
			msg[1] = &"OBITUARY_FIRENADE_MSG_1";
			break;

		case "firenadetk":
			msg[0] = &"OBITUARY_FIRENADETK_MSG_0";
			msg[1] = &"OBITUARY_FIRENADETK_MSG_1";
			break;

		case "selffirenade":
			msg[0] = &"OBITUARY_FIRENADESELF_MSG_0";
			break;

		// gas grenades
		case "gasnade":
			msg[0] = &"OBITUARY_GASNADE_MSG_0";
			msg[1] = &"OBITUARY_GASNADE_MSG_1";
			break;

		case "gasnadetk":
			msg[0] = &"OBITUARY_GASNADETK_MSG_0";
			msg[1] = &"OBITUARY_GASNADETK_MSG_1";
			break;

		case "selfgasnade":
			msg[0] = &"OBITUARY_GASNADESELF_MSG_0";
			break;

		// satchel charges
		case "satchelcharge":
			msg[0] = &"OBITUARY_SATCHEL_MSG_0";
			msg[1] = &"OBITUARY_SATCHEL_MSG_1";
			break;

		case "satchelchargetk":
			msg[0] = &"OBITUARY_SATCHELTK_MSG_0";
			msg[1] = &"OBITUARY_SATCHELTK_MSG_1";
			break;

		case "selfsatchelcharge":
			msg[0] = &"OBITUARY_SATCHELSELF_MSG_0";
			break;

		// mine
		case "minefield":
			msg[0] = &"OBITUARY_MINEFIELD_MSG_0";
			msg[1] = &"OBITUARY_MINEFIELD_MSG_1";
			msg[2] = &"OBITUARY_MINEFIELD_MSG_2";
			break;

		// tripwire
		case "selftripwire":
			msg[0] = &"OBITUARY_TRIPWIRESELF_MSG_0";
			break;

		// landmine
		case "selflandmine":
			msg[0] = &"OBITUARY_LANDMINESELF_MSG_0";
			break;

		// rpg
		case "rpg":
			msg[0] = &"OBITUARY_RPG_MSG_0";
			msg[1] = &"OBITUARY_RPG_MSG_1";
			break;

		case "rpgtk":
			msg[0] = &"OBITUARY_RPGTK_MSG_0";
			msg[1] = &"OBITUARY_RPGTK_MSG_1";
			break;

		case "selfrpg":
			msg[0] = &"OBITUARY_RPGSELF_MSG_0";
			break;

		// grenade launcher
		case "gl":
			msg[0] = &"OBITUARY_GL_MSG_0";
			break;

		case "gltk":
			msg[0] = &"OBITUARY_GLTK_MSG_0";
			break;

		case "selfgl":
			msg[0] = &"OBITUARY_GLSELF_MSG_0";
			break;

		// flamethrower
		case "flamethrower":
			msg[0] = &"OBITUARY_FLAMETHROWER_MSG_0";
			msg[1] = &"OBITUARY_FLAMETHROWER_MSG_1";
			break;

		case "flamethrowertk":
			msg[0] = &"OBITUARY_FLAMETHROWERTK_MSG_0";
			msg[1] = &"OBITUARY_FLAMETHROWERTK_MSG_1";
			break;

		case "selfflamethrower":
			msg[0] = &"OBITUARY_FLAMETHROWERSELF_MSG_0";
			break;

		// mortar
		case "mortar":
			msg[0] = &"OBITUARY_MORTAR_MSG_0";
			msg[1] = &"OBITUARY_MORTAR_MSG_1";
			break;

		case "selfmortar":
			msg[0] = &"OBITUARY_MORTARSELF_MSG_0";
			break;

		// artillery
		case "artillery":
			msg[0] = &"OBITUARY_ARTILLERY_MSG_0";
			msg[1] = &"OBITUARY_ARTILLERY_MSG_1";
			break;

		case "selfartillery":
			msg[0] = &"OBITUARY_ARTILLERYSELF_MSG_0";
			break;

		// airstrike
		case "airstrike":
			msg[0] = &"OBITUARY_AIRSTRIKE_MSG_0";
			msg[1] = &"OBITUARY_AIRSTRIKE_MSG_1";
			break;

		case "selfairstrike":
			msg[0] = &"OBITUARY_AIRSTRIKESELF_MSG_0";
			break;

		// napalm
		case "napalm":
			msg[0] = &"OBITUARY_NAPALM_MSG_0";
			msg[1] = &"OBITUARY_NAPALM_MSG_1";
			break;

		case "napalmtk":
			msg[0] = &"OBITUARY_NAPALMTK_MSG_0";
			msg[1] = &"OBITUARY_NAPALMTK_MSG_1";
			break;

		case "selfnapalm":
			msg[0] = &"OBITUARY_NAPALMSELF_MSG_0";
			break;

		// explosive
		case "explosive":
			msg[0] = &"OBITUARY_EXPLOSIVE_MSG_0";
			msg[1] = &"OBITUARY_EXPLOSIVE_MSG_1";
			break;

		case "explosivetk":
			msg[0] = &"OBITUARY_EXPLOSIVETK_MSG_0";
			msg[1] = &"OBITUARY_EXPLOSIVETK_MSG_1";
			break;

		// drowning
		case "drowning":
			msg[0] = &"OBITUARY_DROWNING_MSG_0";
			break;

		// misc
		case "headshottk":
			msg[0] = &"OBITUARY_HEADSHOT_TK_MSG_0";
			msg[1] = &"OBITUARY_HEADSHOT_TK_MSG_1";
			break;

		case "sniper":
			msg[0] = &"OBITUARY_SNIPER_MSG_0";
			msg[1] = &"OBITUARY_SNIPER_MSG_1";
			break;

		case "snipertk":
			msg[0] = &"OBITUARY_SNIPER_TK_MSG_0";
			msg[1] = &"OBITUARY_SNIPER_TK_MSG_1";
			break;

		// general bash
		case "bashkill_head":
			msg[0] = &"OBITUARY_BASHKILL_HEAD_MSG";
			break;

		case "bashkill":
			msg[0] = &"OBITUARY_BASHKILL_MSG_0";
			msg[1] = &"OBITUARY_BASHKILL_MSG_1";
			break;

		case "bashtk":
			msg[0] = &"OBITUARY_BASHTK_MSG_0";
			msg[1] = &"OBITUARY_BASHTK_MSG_1";
			break;

		// general teamkill
		case "teamkill":
			msg[0] = &"OBITUARY_TEAMKILL_MSG";
			break;

		default:
			msg[0] = &"OBITUARY_KILLED_BY";
			break;
	}

	if(msg.size)
	{
		amsg = randomInt(msg.size);
		iprintln(msg[amsg], [[level.ex_pname]](self));
	}
}

showpmsg(message)
{
	self endon("disconnect");

	if(!isDefined(message)) return(undefined);
	
	pmsg = undefined;

	switch(message)
	{
		case "unknown": pmsg = &"OBITUARY_UNKNOWN_PMSG"; break;
		case "falling": pmsg = &"OBITUARY_FALLING_PMSG"; break;
		case "ambient": pmsg = &"OBITUARY_AMBIENT_PMSG"; break;

		// pistol
		case "pistolwhip": pmsg = &"OBITUARY_PISTOL_WHIP_PMSG"; break;
		case "pistolwhiptk": pmsg = &"OBITUARY_PISTOL_WHIP_TK_PMSG"; break;

		// knife
		case "knife": pmsg = &"OBITUARY_KNIFE_PMSG"; break;
		case "knifetk": pmsg = &"OBITUARY_KNIFETK_PMSG"; break;
		case "knifewhip": pmsg = &"OBITUARY_KNIFE_WHIP_PMSG"; break;
		case "knifewhiptk": pmsg = &"OBITUARY_KNIFE_WHIP_TK_PMSG"; break;
		case "selfknife": pmsg = &"OBITUARY_KNIFESELF_PMSG"; break;

		// grenade
		case "selfnade": pmsg = &"OBITUARY_SELFNADE_PMSG"; break;
		case "selfnades": pmsg = &"OBITUARY_SELFNADES_PMSG"; break;
		case "selfkamikaze": pmsg = &"OBITUARY_SELFKAMIKAZE_PMSG"; break;

		// fire grenades
		case "firenade": pmsg = &"OBITUARY_FIRENADE_PMSG"; break;
		case "firenadetk": pmsg = &"OBITUARY_FIRENADETK_PMSG"; break;
		case "selffirenade": pmsg = &"OBITUARY_FIRENADESELF_PMSG"; break;

		// gas grenades
		case "gasnade": pmsg = &"OBITUARY_GASNADE_PMSG"; break;
		case "gasnadetk": pmsg = &"OBITUARY_GASNADETK_PMSG"; break;
		case "selfgasnade": pmsg = &"OBITUARY_GASNADESELF_PMSG"; break;

		// satchel charge
		case "satchelcharge": pmsg = &"OBITUARY_SATCHEL_PMSG"; break;
		case "satchelchargetk": pmsg = &"OBITUARY_SATCHELTK_PMSG"; break;
		case "selfsatchelcharge": pmsg = &"OBITUARY_SATCHELSELF_PMSG"; break;

		// mine
		case "minefield": pmsg = &"OBITUARY_MINEFIELD_PMSG"; break;

		// tripwire
		case "selftripwire": pmsg = &"OBITUARY_TRIPWIRESELF_PMSG"; break;

		// landmine
		case "selflandmine": pmsg = &"OBITUARY_LANDMINESELF_PMSG"; break;

		// rpg
		case "rpg": pmsg = &"OBITUARY_RPG_PMSG"; break;
		case "rpgtk": pmsg = &"OBITUARY_RPGTK_PMSG"; break;
		case "selfrpg": pmsg = &"OBITUARY_RPGSELF_PMSG"; break;

		// grenade launcher
		case "gl": pmsg = &"OBITUARY_GL_PMSG"; break;
		case "gltk": pmsg = &"OBITUARY_GLTK_PMSG"; break;
		case "selfgl": pmsg = &"OBITUARY_GLSELF_PMSG"; break;

		// flamethrower
		case "flamethrower": pmsg = &"OBITUARY_FLAMETHROWER_PMSG"; break;
		case "flamethrowertk": pmsg = &"OBITUARY_FLAMETHROWERTK_PMSG"; break;
		case "selfflamethrower": pmsg = &"OBITUARY_FLAMETHROWERSELF_PMSG"; break;

		// mortars
		case "mortar": pmsg = &"OBITUARY_MORTAR_PMSG"; break;
		case "mortartk": pmsg = &"OBITUARY_MORTARTK_PMSG"; break;
		case "selfmortar": pmsg = &"OBITUARY_MORTARSELF_PMSG"; break;

		// artillery
		case "artillery": pmsg = &"OBITUARY_ARTILLERY_PMSG"; break;
		case "artillerytk": pmsg = &"OBITUARY_ARTILLERYTK_PMSG"; break;
		case "selfartillery": pmsg = &"OBITUARY_ARTILLERYSELF_PMSG"; break;

		// airstrike
		case "airstrike": pmsg = &"OBITUARY_AIRSTRIKE_PMSG"; break;
		case "airstriketk": pmsg = &"OBITUARY_AIRSTRIKETK_PMSG"; break;
		case "selfairstrike": pmsg = &"OBITUARY_AIRSTRIKESELF_PMSG"; break;

		// napalm
		case "napalm": pmsg = &"OBITUARY_NAPALM_PMSG"; break;
		case "napalmtk": pmsg = &"OBITUARY_NAPALMTK_PMSG"; break;
		case "selfnapalm": pmsg = &"OBITUARY_NAPALMSELF_PMSG"; break;

		// explosive
		case "explosive": pmsg = &"OBITUARY_EXPLOSIVE_PMSG"; break;
		case "explosivetk": pmsg = &"OBITUARY_EXPLOSIVETK_PMSG"; break;

		// drowning
		case "drowning": pmsg = &"OBITUARY_DROWNING_PMSG"; break;

		// specials
		case "beartrap": pmsg = &"OBITUARY_BEARTRAP_PMSG"; break;
		case "monkey": pmsg = &"OBITUARY_MONKEY_PMSG"; break;
		case "sentrygun": pmsg = &"OBITUARY_SENTRYGUN_PMSG"; break;
		case "heligun": pmsg = &"OBITUARY_HELIGUN_PMSG"; break;
		case "ugvgun": pmsg = &"OBITUARY_UGVGUN_PMSG"; break;
		case "ugvrocket": pmsg = &"OBITUARY_UGVROCKET_PMSG"; break;
		case "helitube": pmsg = &"OBITUARY_HELITUBE_PMSG"; break;
		case "helimissile": pmsg = &"OBITUARY_HELIMISSILE_PMSG"; break;
		case "gmlmissile": pmsg = &"OBITUARY_GMLMISSILE_PMSG"; break;
		case "flakprojectile": pmsg = &"OBITUARY_FLAKPROJECTILE_PMSG"; break;
		case "quadrotor": pmsg = &"OBITUARY_QUADROTOR_PMSG"; break;

		// misc
		case "headshottk": pmsg = &"OBITUARY_HEADSHOT_TK_PMSG"; break;
		case "sniper": pmsg = &"OBITUARY_SNIPER_PMSG"; break;
		case "snipertk": pmsg = &"OBITUARY_SNIPER_TK_PMSG"; break;

		// general bashes
		case "bashkill": pmsg = &"OBITUARY_BASHKILL_PMSG"; break;
		case "bashkill_head": pmsg = &"OBITUARY_BASHKILL_HEAD_PMSG"; break;
		case "bashtk": pmsg = &"OBITUARY_BASHTK_PMSG"; break;

		// general teamkill
		case "teamkill": pmsg = &"OBITUARY_TEAMKILL_PMSG"; break;

		default: return;
	}

	self iprintlnbold(pmsg);
}

gethitlocstringname(location)
{
	if(location == "helmet") location = "head";

	switch(location)
	{
		case "right_hand":      return(&"HITLOC_RIGHT_HAND");
		case "left_hand":       return(&"HITLOC_LEFT_HAND");
		case "right_arm_upper": return(&"HITLOC_RIGHT_UPPER_ARM");
		case "right_arm_lower": return(&"HITLOC_RIGHT_FOREARM");
		case "left_arm_upper":  return(&"HITLOC_LEFT_UPPER_ARM");
		case "left_arm_lower":  return(&"HITLOC_LEFT_FOREARM");
		case "head":            return(&"HITLOC_HEAD");
		case "neck":            return(&"HITLOC_NECK");
		case "right_foot":      return(&"HITLOC_RIGHT_FOOT");
		case "left_foot":       return(&"HITLOC_LEFT_FOOT");
		case "right_leg_lower": return(&"HITLOC_RIGHT_LOWER_LEG");
		case "left_leg_lower":  return(&"HITLOC_LEFT_LOWER_LEG");
		case "right_leg_upper": return(&"HITLOC_RIGHT_UPPER_LEG");
		case "left_leg_upper":  return(&"HITLOC_LEFT_UPPER_LEG");
		case "torso_upper":     return(&"HITLOC_UPPER_TORSO");
		case "torso_lower":     return(&"HITLOC_LOWER_TORSO");
		case "none":
		default:                return(&"HITLOC_UNKNOWN");
	}
}

vipToNormalPistol(sWeapon)
{
	switch(sWeapon)
	{
		case "colt_vip_mp": return("colt_mp");
		case "luger_vip_mp": return("luger_mp");
		case "tt30_vip_mp": return("tt30_mp");
		case "webley_vip_mp": return("webley_mp");
		case "beretta_vip_mp": return("beretta_mp");
		case "deagle_vip_mp": return("deagle_mp");
		case "glock_vip_mp": return("glock_mp");
		case "hk45_vip_mp": return("hk45_mp");
	}
	return(sWeapon);
}

botToNormalWeapon(attacker, sWeapon)
{
	if(isWeaponType(sWeapon, "frag")) return(sWeapon);

	switch(sWeapon)
	{
		case "frag_grenade_american_bot": return("frag_grenade_american_mp");
		case "frag_grenade_british_bot": return("frag_grenade_british_mp");
		case "frag_grenade_russian_bot": return("frag_grenade_russian_mp");
		case "frag_grenade_german_bot": return("frag_grenade_german_mp");
	}
	return(attacker.oweapon);
}
