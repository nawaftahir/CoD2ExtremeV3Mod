#include extreme\_ex_controller_hud;
#include extreme\_ex_main_utils;

specialsInit()
{
	// initialize catalog
	if(!isDefined(game["perkcatalog"]))
	{
		level.perkcatalog_init = true;
		game["perkcategories"] = [];
		game["perkcatalog"] = [];

		// register category 0
		registerCategory(0, 40);

		// register category 1
		if(!level.ex_store_maxweapons) registerCategory(1, 20);
			else registerCategory(1, level.ex_store_maxweapons);

		// register category 2
		if(!level.ex_store_maxperks) registerCategory(2, 20);
			else registerCategory(2, level.ex_store_maxperks);

		// Make a catch-all slot so perk catalog aligns with perk menu numbers
		registerPerk(0, "-", "ex_store_na", "-", "-");
	}
	else
	{
		level.perkcatalog_init = false;
		logprint("SPC: Perks catalog already exists\n");
	}

	// register specials: weapons (category 1)
	// always rerun because function pointers are lost on map_restart
	registerWeapons(1);

	// register specials: perks (category 2)
	// always rerun because function pointers are lost on map_restart
	registerPerks(2);
}

init()
{
	// we need these for the regular gunship also
	if(level.ex_gunship || level.ex_store) [[level.ex_registerCallback]]("onJoinedTeam", ::onJoinedTeam);
	if(level.ex_gunship || (level.ex_store & 2) == 2)
	{
		[[level.ex_registerCallback]]("onJoinedSpectators", ::onJoinedSpectators);
		[[level.ex_registerCallback]]("onPlayerKilled", ::onPlayerKilled);
		if(level.ex_roundbased) [[level.ex_registerCallback]]("onRoundOver", ::onGameOver);
		[[level.ex_registerCallback]]("onGameOver", ::onGameOver);
	}

	// this is for the store
	if(level.ex_store)
	{
		for(i = 1; i < game["perkcatalog"].size; i++)
			if(isDefined(game["perkcatalog"][i]["initproc"])) thread [[game["perkcatalog"][i]["initproc"]]](i);

		[[level.ex_registerCallback]]("onPlayerConnected", ::onPlayerConnected);
		[[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerSpawned);

		// check if it makes sense to start monitor for delays
		if(!isDefined(game["perkcatalog"]) || game["perkcatalog"].size == 1) return;

		team_delay = 0;
		for(i = 1; i < game["perkcatalog"].size; i++)
			if(isDefined(game["perkcatalog"][i]["team_delay"])) team_delay += game["perkcatalog"][i]["team_delay"];

		player_delay = 0;
		for(i = 1; i < game["perkcatalog"].size; i++)
			if(isDefined(game["perkcatalog"][i]["player_delay"])) team_delay += game["perkcatalog"][i]["player_delay"];

		if(team_delay || player_delay) [[level.ex_registerLevelEvent]]("onSecond", ::onSecond);
	}
}

initPost()
{
	// this is for the store
	if(level.ex_store)
	{
		for(i = 1; i < game["perkcatalog"].size; i++)
			if(isDefined(game["perkcatalog"][i]["initpostproc"])) thread [[game["perkcatalog"][i]["initpostproc"]]](i);
	}
}

onSecond(eventID)
{
	for(i = 1; i < game["perkcatalog"].size; i++)
	{
		if(game["perkcatalog"][i]["name"] == "-") continue;
		if(game["perkcatalog"][i]["axis_delay"] > 0) game["perkcatalog"][i]["axis_delay"]--;
		if(game["perkcatalog"][i]["allies_delay"] > 0) game["perkcatalog"][i]["allies_delay"]--;
	}

	for(i = 0; i < level.ex_maxclients; i++)
	{
		for(j = 1; j < game["perkcatalog"].size; j++)
		{
			if(game["perkcatalog"][j]["name"] == "-") continue;
			if(game["perks"][i][game["perkcatalog"][j]["name"]]["player_delay"] > 0) game["perks"][i][game["perkcatalog"][j]["name"]]["player_delay"]--;
		}
	}
}

onGameOver()
{
	if(level.ex_gunship && isPlayer(level.gunship.owner))
		level.gunship.owner thread extreme\_ex_main_gunship::gunshipDetachPlayer(false);
	if((level.ex_store & 2) == 2 && level.ex_gunship_special && isPlayer(level.gunship_special.owner))
		level.gunship_special.owner thread extreme\_ex_specials_gunship::gunshipSpecialDetachPlayer(false);

	// clean up perks in the field
	if((level.ex_store & 2) == 2) thread removeAllPerks();
}

onPlayerConnected()
{
	if(!isDefined(self.pers["cash"])) self.pers["cash"] = 0;
	if(!isDefined(self.pers["cash_spent"])) self.pers["cash_spent"] = 0;
	self playerResetPerks();

	if(!level.ex_accounts && level.ex_store_savecash && level.ex_store_payment == 2)
	{
		memory = self extreme\_ex_controller_memory::getMemory("memory", "account", "cash");
		if(!memory.error) self.pers["cash"] = memory.value;
	}
}

onPlayerSpawned()
{
	playerUnlockPerks();

	for(i = 1; i < game["perkcatalog"].size; i++)
		if(isDefined(game["perkcatalog"][i]["assigndelayproc"])) thread [[game["perkcatalog"][i]["assigndelayproc"]]](i, level.ex_store_testdelay);

	self thread playerGiveBackPerks();

	if(level.ex_store_payment || level.ex_teamplay)
	{
		hud_index = playerHudCreate("cash", -150, -10, 1, (1, 0.843, 0), 2.0, 1, "right", "bottom", "right", "bottom", false, true);
		if(hud_index != -1)
		{
			switch(level.ex_store_currency)
			{
				case 1:
					playerHudSetLabel(hud_index, &"SPECIALS_CURRENCY_SIGN_LEFT");
					break;
				case 2:
					playerHudSetLabel(hud_index, &"SPECIALS_CURRENCY_SIGN_RIGHT");
					break;
			}

			switch(level.ex_store_payment)
			{
				case 0:
					playerHudSetValue(hud_index, self.pers["score"]);
					break;
				case 1:
					playerHudSetValue(hud_index, self.pers["bonus"]);
					break;
				case 2:
					playerHudSetValue(hud_index, self.pers["cash"]);
					break;
			}
		}
	}
}

onPlayerKilled()
{
	if(level.ex_gunship) level thread extreme\_ex_main_gunship::gunshipDetachPlayerLevel(self);
	if((level.ex_store & 2) == 2)
	{
		if(level.ex_specials_knife) self thread playerStopUsingPerk("knife", true);
		if(level.ex_wallfire) self thread playerStopUsingPerk("wallfire", true);
		if(level.ex_supernade) self thread playerStopUsingPerk("supernade", true);
		if(level.ex_vest) self thread playerStopUsingPerk("vest", true);
		if(level.ex_stealth)
		{
			self thread playerStopUsingPerk("stealth", true);
			if(isDefined(self.ex_stealth))
			{
				self.ex_stealth = undefined;
				if(isDefined(self.pers["savedmodel"])) self extreme\_ex_main_models::loadModel(self.pers["savedmodel"]);
			}
		}
		if(level.ex_gml && (level.ex_gml_remove & 2) == 2) level thread extreme\_ex_specials_gml::perkRemoveFrom(self);
		if(level.ex_flak && (level.ex_flak_remove & 2) == 2) level thread extreme\_ex_specials_flak::perkRemoveFrom(self);
		if(level.ex_sentrygun && (level.ex_sentrygun_remove & 2) == 2) level thread extreme\_ex_specials_sentrygun::perkRemoveFrom(self);
		if(level.ex_ugv && (level.ex_ugv_remove & 2) == 2) level thread extreme\_ex_specials_ugv::perkRemoveFrom(self);
		if(level.ex_gunship_special) level thread extreme\_ex_specials_gunship::gunshipSpecialDetachPlayerLevel(self);
	}
}

onPlayerDisconnected(entity)
{
	// called from _ex_main_clientcontrol::onPlayerDisconnected() to get entity parameter
	if(level.ex_vest) level thread extreme\_ex_specials::levelResetUsingPerk(entity, "vest");
	if(level.ex_gunship_special) level thread extreme\_ex_specials::levelResetUsingPerk(entity, "gunship");
}

onJoinedTeam()
{
	if(level.ex_gunship) level thread extreme\_ex_main_gunship::gunshipDetachPlayerLevel(self);
	if(level.ex_gunship_special) level thread extreme\_ex_specials_gunship::gunshipSpecialDetachPlayerLevel(self);

	// update specialty store cvars
	self thread extreme\_ex_specials::playerSpecialtyCvars();
}

onJoinedSpectators()
{
	if(level.ex_gunship) level thread extreme\_ex_main_gunship::gunshipDetachPlayerLevel(self);
	if(level.ex_gunship_special) level thread extreme\_ex_specials_gunship::gunshipSpecialDetachPlayerLevel(self);
}

registerCategory(cat, max)
{
	game["perkcategories"][cat]["start"] = 0;
	game["perkcategories"][cat]["max"] = max;
}

registerWeapons(cat)
{
	if((level.ex_store & 1) == 1)
	{
		if(!game["perkcategories"][cat]["start"]) game["perkcategories"][cat]["start"] = game["perkcatalog"].size;

		// make sure we have a lowercase, trimmed order string
		weapons_order = tolower(trim(level.ex_weapons_order));

		// build order string if config does not provide one
		if(weapons_order == "")
		{
			logprint("SPC: Weapons ordering string is empty. Rebuilding one\n");
			weapons_order = rebuildWeaponsOrder();
		}

		// do the perk registration based on the order defined in the order string
		perk_array = strtok(weapons_order, " ");
		if(isDefined(perk_array) && perk_array.size)
		{
			for(i = 0; i < perk_array.size; i++)
			{
				switch(perk_array[i])
				{
					case "-":
						registerPerk(cat, "-", "ex_weapons_na", "-", "-");
						break;
					case "weapon01":
						if(level.ex_weapon01)
						{
							if(registerPerk(cat, perk_array[i], "ex_weapon01", "spc_weapon_hudicon", "x2_weaponunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_weapon::perkInit, extreme\_ex_specials_weapon::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_weapon::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_weapon::perkAssign, extreme\_ex_specials_weapon::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_weapons_na");
						break;
					case "weapon02":
						if(level.ex_weapon02)
						{
							if(registerPerk(cat, perk_array[i], "ex_weapon02", "spc_weapon_hudicon", "x2_weaponunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_weapon::perkInit, extreme\_ex_specials_weapon::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_weapon::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_weapon::perkAssign, extreme\_ex_specials_weapon::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_weapons_na");
						break;
					case "weapon03":
						if(level.ex_weapon03)
						{
							if(registerPerk(cat, perk_array[i], "ex_weapon03", "spc_weapon_hudicon", "x2_weaponunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_weapon::perkInit, extreme\_ex_specials_weapon::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_weapon::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_weapon::perkAssign, extreme\_ex_specials_weapon::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_weapons_na");
						break;
					case "weapon04":
						if(level.ex_weapon04)
						{
							if(registerPerk(cat, perk_array[i], "ex_weapon04", "spc_weapon_hudicon", "x2_weaponunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_weapon::perkInit, extreme\_ex_specials_weapon::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_weapon::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_weapon::perkAssign, extreme\_ex_specials_weapon::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_weapons_na");
						break;
					case "weapon05":
						if(level.ex_weapon05)
						{
							if(registerPerk(cat, perk_array[i], "ex_weapon05", "spc_weapon_hudicon", "x2_weaponunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_weapon::perkInit, extreme\_ex_specials_weapon::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_weapon::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_weapon::perkAssign, extreme\_ex_specials_weapon::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_weapons_na");
						break;
					case "weapon06":
						if(level.ex_weapon06)
						{
							if(registerPerk(cat, perk_array[i], "ex_weapon06", "spc_weapon_hudicon", "x2_weaponunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_weapon::perkInit, extreme\_ex_specials_weapon::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_weapon::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_weapon::perkAssign, extreme\_ex_specials_weapon::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_weapons_na");
						break;
					case "weapon07":
						if(level.ex_weapon07)
						{
							if(registerPerk(cat, perk_array[i], "ex_weapon07", "spc_weapon_hudicon", "x2_weaponunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_weapon::perkInit, extreme\_ex_specials_weapon::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_weapon::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_weapon::perkAssign, extreme\_ex_specials_weapon::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_weapons_na");
						break;
					case "weapon08":
						if(level.ex_weapon08)
						{
							if(registerPerk(cat, perk_array[i], "ex_weapon08", "spc_weapon_hudicon", "x2_weaponunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_weapon::perkInit, extreme\_ex_specials_weapon::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_weapon::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_weapon::perkAssign, extreme\_ex_specials_weapon::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_weapons_na");
						break;
					case "weapon09":
						if(level.ex_weapon09)
						{
							if(registerPerk(cat, perk_array[i], "ex_weapon09", "spc_weapon_hudicon", "x2_weaponunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_weapon::perkInit, extreme\_ex_specials_weapon::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_weapon::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_weapon::perkAssign, extreme\_ex_specials_weapon::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_weapons_na");
						break;
					case "weapon10":
						if(level.ex_weapon10)
						{
							if(registerPerk(cat, perk_array[i], "ex_weapon10", "spc_weapon_hudicon", "x2_weaponunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_weapon::perkInit, extreme\_ex_specials_weapon::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_weapon::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_weapon::perkAssign, extreme\_ex_specials_weapon::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_weapons_na");
						break;
					case "weapon11":
						if(level.ex_weapon11)
						{
							if(registerPerk(cat, perk_array[i], "ex_weapon11", "spc_weapon_hudicon", "x2_weaponunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_weapon::perkInit, extreme\_ex_specials_weapon::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_weapon::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_weapon::perkAssign, extreme\_ex_specials_weapon::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_weapons_na");
						break;
					case "weapon12":
						if(level.ex_weapon12)
						{
							if(registerPerk(cat, perk_array[i], "ex_weapon12", "spc_weapon_hudicon", "x2_weaponunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_weapon::perkInit, extreme\_ex_specials_weapon::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_weapon::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_weapon::perkAssign, extreme\_ex_specials_weapon::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_weapons_na");
						break;
					case "weapon13":
						if(level.ex_weapon13)
						{
							if(registerPerk(cat, perk_array[i], "ex_weapon13", "spc_weapon_hudicon", "x2_weaponunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_weapon::perkInit, extreme\_ex_specials_weapon::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_weapon::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_weapon::perkAssign, extreme\_ex_specials_weapon::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_weapons_na");
						break;
					case "weapon14":
						if(level.ex_weapon14)
						{
							if(registerPerk(cat, perk_array[i], "ex_weapon14", "spc_weapon_hudicon", "x2_weaponunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_weapon::perkInit, extreme\_ex_specials_weapon::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_weapon::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_weapon::perkAssign, extreme\_ex_specials_weapon::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_weapons_na");
						break;
					case "weapon15":
						if(level.ex_weapon15)
						{
							if(registerPerk(cat, perk_array[i], "ex_weapon15", "spc_weapon_hudicon", "x2_weaponunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_weapon::perkInit, extreme\_ex_specials_weapon::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_weapon::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_weapon::perkAssign, extreme\_ex_specials_weapon::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_weapons_na");
						break;
					case "weapon16":
						if(level.ex_weapon16)
						{
							if(registerPerk(cat, perk_array[i], "ex_weapon16", "spc_weapon_hudicon", "x2_weaponunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_weapon::perkInit, extreme\_ex_specials_weapon::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_weapon::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_weapon::perkAssign, extreme\_ex_specials_weapon::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_weapons_na");
						break;
					case "weapon17":
						if(level.ex_weapon17)
						{
							if(registerPerk(cat, perk_array[i], "ex_weapon17", "spc_weapon_hudicon", "x2_weaponunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_weapon::perkInit, extreme\_ex_specials_weapon::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_weapon::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_weapon::perkAssign, extreme\_ex_specials_weapon::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_weapons_na");
						break;
					case "weapon18":
						if(level.ex_weapon18)
						{
							if(registerPerk(cat, perk_array[i], "ex_weapon18", "spc_weapon_hudicon", "x2_weaponunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_weapon::perkInit, extreme\_ex_specials_weapon::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_weapon::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_weapon::perkAssign, extreme\_ex_specials_weapon::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_weapons_na");
						break;
					case "weapon19":
						if(level.ex_weapon19)
						{
							if(registerPerk(cat, perk_array[i], "ex_weapon19", "spc_weapon_hudicon", "x2_weaponunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_weapon::perkInit, extreme\_ex_specials_weapon::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_weapon::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_weapon::perkAssign, extreme\_ex_specials_weapon::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_weapons_na");
						break;
					case "weapon20":
						if(level.ex_weapon20)
						{
							if(registerPerk(cat, perk_array[i], "ex_weapon20", "spc_weapon_hudicon", "x2_weaponunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_weapon::perkInit, extreme\_ex_specials_weapon::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_weapon::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_weapon::perkAssign, extreme\_ex_specials_weapon::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_weapons_na");
						break;
					default:
						logprint("SPC: Invalid weapon identifier \"" + perk_array[i] + "\". Please check \"ex_weapons_order\"!\n");
				}
			}

			// check if we registered something
			if(!getPerkCategoryCount(cat, false))
			{
				level.ex_store = (level.ex_store & 2);
				logprint("SPC: No weapons registered. Weapons menu disabled\n");
			}
			else
			{
				// fill catalog for missing weapons if not set to auto-adjust
				if(level.ex_store_maxweapons)
				{
					for(i = game["perkcatalog"].size; i < game["perkcategories"][cat]["start"] + game["perkcategories"][cat]["max"]; i++)
						if(!isDefined(game["perkcatalog"][i])) registerPerk(cat, "-", "ex_weapons_na", "-", "-");
				}
				game["perkcategories"][cat]["max"] = getPerkCategoryCount(cat, true);
				logprint("SPC: " + game["perkcategories"][cat]["max"] + " slot(s) occupied in category " + cat + " (starting at slot " + game["perkcategories"][cat]["start"] + ")\n");
			}
		}
		else
		{
			level.ex_store = (level.ex_store & 2);
			logprint("SPC: Weapons ordering string empty or invalid. Weapons menu disabled\n");
		}
	}

	// Check which perk made it into the array. Turn feature off if not in array
	if(!getPerkIndex("weapon01")) level.ex_weapon01 = 0;
	if(!getPerkIndex("weapon02")) level.ex_weapon02 = 0;
	if(!getPerkIndex("weapon03")) level.ex_weapon03 = 0;
	if(!getPerkIndex("weapon04")) level.ex_weapon04 = 0;
	if(!getPerkIndex("weapon05")) level.ex_weapon05 = 0;
	if(!getPerkIndex("weapon06")) level.ex_weapon06 = 0;
	if(!getPerkIndex("weapon07")) level.ex_weapon07 = 0;
	if(!getPerkIndex("weapon08")) level.ex_weapon08 = 0;
	if(!getPerkIndex("weapon09")) level.ex_weapon09 = 0;
	if(!getPerkIndex("weapon10")) level.ex_weapon10 = 0;
	if(!getPerkIndex("weapon11")) level.ex_weapon11 = 0;
	if(!getPerkIndex("weapon12")) level.ex_weapon12 = 0;
	if(!getPerkIndex("weapon13")) level.ex_weapon13 = 0;
	if(!getPerkIndex("weapon14")) level.ex_weapon14 = 0;
	if(!getPerkIndex("weapon15")) level.ex_weapon15 = 0;
	if(!getPerkIndex("weapon16")) level.ex_weapon16 = 0;
	if(!getPerkIndex("weapon17")) level.ex_weapon17 = 0;
	if(!getPerkIndex("weapon18")) level.ex_weapon18 = 0;
	if(!getPerkIndex("weapon19")) level.ex_weapon19 = 0;
	if(!getPerkIndex("weapon20")) level.ex_weapon20 = 0;
}

rebuildWeaponsOrder()
{
	specials = [];
	if(level.ex_weapon01 && specials.size < level.ex_store_maxweapons) specials[specials.size] = "weapon01";
	if(level.ex_weapon02 && specials.size < level.ex_store_maxweapons) specials[specials.size] = "weapon02";
	if(level.ex_weapon03 && specials.size < level.ex_store_maxweapons) specials[specials.size] = "weapon03";
	if(level.ex_weapon04 && specials.size < level.ex_store_maxweapons) specials[specials.size] = "weapon04";
	if(level.ex_weapon05 && specials.size < level.ex_store_maxweapons) specials[specials.size] = "weapon05";
	if(level.ex_weapon06 && specials.size < level.ex_store_maxweapons) specials[specials.size] = "weapon06";
	if(level.ex_weapon07 && specials.size < level.ex_store_maxweapons) specials[specials.size] = "weapon07";
	if(level.ex_weapon08 && specials.size < level.ex_store_maxweapons) specials[specials.size] = "weapon08";
	if(level.ex_weapon09 && specials.size < level.ex_store_maxweapons) specials[specials.size] = "weapon09";
	if(level.ex_weapon10 && specials.size < level.ex_store_maxweapons) specials[specials.size] = "weapon10";
	if(level.ex_weapon11 && specials.size < level.ex_store_maxweapons) specials[specials.size] = "weapon11";
	if(level.ex_weapon12 && specials.size < level.ex_store_maxweapons) specials[specials.size] = "weapon12";
	if(level.ex_weapon13 && specials.size < level.ex_store_maxweapons) specials[specials.size] = "weapon13";
	if(level.ex_weapon14 && specials.size < level.ex_store_maxweapons) specials[specials.size] = "weapon14";
	if(level.ex_weapon15 && specials.size < level.ex_store_maxweapons) specials[specials.size] = "weapon15";
	if(level.ex_weapon16 && specials.size < level.ex_store_maxweapons) specials[specials.size] = "weapon16";
	if(level.ex_weapon17 && specials.size < level.ex_store_maxweapons) specials[specials.size] = "weapon17";
	if(level.ex_weapon18 && specials.size < level.ex_store_maxweapons) specials[specials.size] = "weapon18";
	if(level.ex_weapon19 && specials.size < level.ex_store_maxweapons) specials[specials.size] = "weapon19";
	if(level.ex_weapon20 && specials.size < level.ex_store_maxweapons) specials[specials.size] = "weapon20";

	specials_order = "";
	for(i = 0; i < specials.size; i++) specials_order = specials_order + specials[i] + " ";

	return( tolower(trim(specials_order)) );
}

registerPerks(cat)
{
	if((level.ex_store & 2) == 2)
	{
		if(!game["perkcategories"][cat]["start"]) game["perkcategories"][cat]["start"] = game["perkcatalog"].size;

		// make sure we have a lowercase, trimmed order string
		specials_order = tolower(trim(level.ex_specials_order));

		// build order string if config does not provide one
		if(specials_order == "")
		{
			logprint("SPC: Perk ordering string is empty. Rebuilding one\n");
			specials_order = rebuildPerksOrder();
		}

		// do the perk registration based on the order defined in the order string
		perk_array = strtok(specials_order, " ");
		if(isDefined(perk_array) && perk_array.size)
		{
			for(i = 0; i < perk_array.size; i++)
			{
				switch(perk_array[i])
				{
					case "-":
						registerPerk(cat, "-", "ex_specials_na", "-", "-");
						break;
					case "maxhealth":
						if(level.ex_specials_maxhealth)
						{
							if(registerPerk(cat, perk_array[i], "ex_specials_maxhealth", "spc_health_hudicon", "x2_perkunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_maxhealth::perkInit, extreme\_ex_specials_maxhealth::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_maxhealth::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_maxhealth::perkAssign, extreme\_ex_specials_maxhealth::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_specials_na");
						break;
					case "maxammo":
						if(level.ex_specials_maxammo)
						{
							if(registerPerk(cat, perk_array[i], "ex_specials_maxammo", "spc_ammo_hudicon", "x2_perkunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_maxammo::perkInit, extreme\_ex_specials_maxammo::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_maxammo::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_maxammo::perkAssign, extreme\_ex_specials_maxammo::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_specials_na");
						break;
					case "knife":
						if(level.ex_specials_knife)
						{
							if(registerPerk(cat, perk_array[i], "ex_specials_knife", "spc_knife_hudicon", "x2_perkunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_knife::perkInit, extreme\_ex_specials_knife::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_knife::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_knife::perkAssign, extreme\_ex_specials_knife::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_specials_na");
						break;
					case "supernade":
						if(level.ex_supernade)
						{
							if(registerPerk(cat, perk_array[i], "ex_supernade", "spc_supernade_hudicon", "x2_supernadeunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_supernade::perkInit, extreme\_ex_specials_supernade::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_supernade::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_supernade::perkAssign, extreme\_ex_specials_supernade::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_specials_na");
						break;
					case "vest":
						if(level.ex_vest)
						{
							if(registerPerk(cat, perk_array[i], "ex_vest", "spc_vest_hudicon", "x2_perkunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_vest::perkInit, extreme\_ex_specials_vest::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_vest::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_vest::perkAssign, extreme\_ex_specials_vest::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_specials_na");
						break;
					case "beartrap":
						if(level.ex_beartrap)
						{
							if(registerPerk(cat, perk_array[i], "ex_beartrap", "spc_beartrap_hudicon", "x2_beartrapunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_beartrap::perkInit, extreme\_ex_specials_beartrap::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_beartrap::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_beartrap::perkAssign, extreme\_ex_specials_beartrap::perkAssignDelayed);
								registerPerkRemoval(perk_array[i], extreme\_ex_specials_beartrap::perkRemoveAll);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_specials_na");
						break;
					case "monkey":
						if(level.ex_monkey)
						{
							if(registerPerk(cat, perk_array[i], "ex_monkey", "spc_monkey_hudicon", "x2_monkeyunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_monkey::perkInit, extreme\_ex_specials_monkey::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_monkey::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_monkey::perkAssign, extreme\_ex_specials_monkey::perkAssignDelayed);
								registerPerkRemoval(perk_array[i], extreme\_ex_specials_monkey::perkRemoveAll);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_specials_na");
						break;
					case "bubble_small":
						if(level.ex_bubble_small)
						{
							if(registerPerk(cat, perk_array[i], "ex_bubble_small", "spc_bubble_hudicon", "x2_bubbleunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_bubble_small::perkInit, extreme\_ex_specials_bubble_small::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_bubble_small::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_bubble_small::perkAssign, extreme\_ex_specials_bubble_small::perkAssignDelayed);
								registerPerkRemoval(perk_array[i], extreme\_ex_specials_bubble_small::perkRemoveAll);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_specials_na");
						break;
					case "bubble_big":
						if(level.ex_bubble_big)
						{
							if(registerPerk(cat, perk_array[i], "ex_bubble_big", "spc_bubble_hudicon", "x2_bubbleunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_bubble_big::perkInit, extreme\_ex_specials_bubble_big::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_bubble_big::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_bubble_big::perkAssign, extreme\_ex_specials_bubble_big::perkAssignDelayed);
								registerPerkRemoval(perk_array[i], extreme\_ex_specials_bubble_big::perkRemoveAll);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_specials_na");
						break;
					case "stealth":
						if(level.ex_stealth)
						{
							if(registerPerk(cat, perk_array[i], "ex_stealth", "spc_stealth_hudicon", "x2_stealthunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_stealth::perkInit, extreme\_ex_specials_stealth::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_stealth::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_stealth::perkAssign, extreme\_ex_specials_stealth::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_specials_na");
						break;
					case "insertion":
						if(level.ex_insertion)
						{
							if(registerPerk(cat, perk_array[i], "ex_insertion", "spc_insertion_hudicon", "x2_insertionunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_insertion::perkInit, extreme\_ex_specials_insertion::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_insertion::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_insertion::perkAssign, extreme\_ex_specials_insertion::perkAssignDelayed);
								registerPerkRemoval(perk_array[i], extreme\_ex_specials_insertion::perkRemoveAll);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_specials_na");
						break;
					case "wallfire":
						if(level.ex_wallfire)
						{
							if(registerPerk(cat, perk_array[i], "ex_wallfire", "spc_wallfire_hudicon", "x2_wallfireunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_wallfire::perkInit, extreme\_ex_specials_wallfire::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_wallfire::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_wallfire::perkAssign, extreme\_ex_specials_wallfire::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_specials_na");
						break;
					case "flak":
						if(level.ex_flak)
						{
							if(registerPerk(cat, perk_array[i], "ex_flak", "spc_flak_hudicon", "x2_flakunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_flak::perkInit, extreme\_ex_specials_flak::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_flak::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_flak::perkAssign, extreme\_ex_specials_flak::perkAssignDelayed);
								registerPerkRemoval(perk_array[i], extreme\_ex_specials_flak::perkRemoveAll);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_specials_na");
						break;
					case "gml":
						if(level.ex_gml)
						{
							if(registerPerk(cat, perk_array[i], "ex_gml", "spc_gml_hudicon", "x2_gmlunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_gml::perkInit, extreme\_ex_specials_gml::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_gml::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_gml::perkAssign, extreme\_ex_specials_gml::perkAssignDelayed);
								registerPerkRemoval(perk_array[i], extreme\_ex_specials_gml::perkRemoveAll);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_specials_na");
						break;
					case "cam":
						if(level.ex_cam)
						{
							if(registerPerk(cat, perk_array[i], "ex_cam", "spc_cam_hudicon", "x2_camunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_cam::perkInit, extreme\_ex_specials_cam::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_cam::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_cam::perkAssign, extreme\_ex_specials_cam::perkAssignDelayed);
								registerPerkRemoval(perk_array[i], extreme\_ex_specials_cam::perkRemoveAll);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_specials_na");
						break;
					case "uav":
						if(level.ex_uav)
						{
							if(registerPerk(cat, perk_array[i], "ex_uav", "spc_uav_hudicon", "x2_uavunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_uav::perkInit, extreme\_ex_specials_uav::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_uav::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_uav::perkAssign, extreme\_ex_specials_uav::perkAssignDelayed);
								registerPerkRemoval(perk_array[i], extreme\_ex_specials_uav::perkRemoveAll);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_specials_na");
						break;
					case "sentrygun":
						if(level.ex_sentrygun)
						{
							if(registerPerk(cat, perk_array[i], "ex_sentrygun", "spc_sentry_hudicon", "x2_sentryunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_sentrygun::perkInit, extreme\_ex_specials_sentrygun::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_sentrygun::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_sentrygun::perkAssign, extreme\_ex_specials_sentrygun::perkAssignDelayed);
								registerPerkRemoval(perk_array[i], extreme\_ex_specials_sentrygun::perkRemoveAll);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_specials_na");
						break;
					case "ugv":
						if(level.ex_ugv)
						{
							if(registerPerk(cat, perk_array[i], "ex_ugv", "spc_ugv_hudicon", "x2_ugvunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_ugv::perkInit, extreme\_ex_specials_ugv::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_ugv::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_ugv::perkAssign, extreme\_ex_specials_ugv::perkAssignDelayed);
								registerPerkRemoval(perk_array[i], extreme\_ex_specials_ugv::perkRemoveAll);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_specials_na");
						break;
					case "quad":
						if(level.ex_quad)
						{
							if(registerPerk(cat, perk_array[i], "ex_quad", "spc_quadrotor_hudicon", "x2_quadrotorunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_quadrotor::perkInit, extreme\_ex_specials_quadrotor::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_quadrotor::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_quadrotor::perkAssign, extreme\_ex_specials_quadrotor::perkAssignDelayed);
								registerPerkRemoval(perk_array[i], extreme\_ex_specials_quadrotor::perkRemoveAll);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_specials_na");
						break;
					case "gunship":
						if(level.ex_gunship_special)
						{
							if(registerPerk(cat, perk_array[i], "ex_gunship_special", "spc_gunship_hudicon", "x2_gunshipunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_gunship::perkInit, extreme\_ex_specials_gunship::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_gunship::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_gunship::perkAssign, extreme\_ex_specials_gunship::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_specials_na");
						break;
					case "heli":
						if(level.ex_heli)
						{
							if(registerPerk(cat, perk_array[i], "ex_heli", "spc_heli_hudicon", "x2_helicopterunlock"))
							{
								registerPerkPrecache(perk_array[i], extreme\_ex_specials_helicopter::perkInit, extreme\_ex_specials_helicopter::perkInitPost);
								registerPerkCheck(perk_array[i], extreme\_ex_specials_helicopter::perkCheck);
								registerPerkAssignment(perk_array[i], extreme\_ex_specials_helicopter::perkAssign, extreme\_ex_specials_helicopter::perkAssignDelayed);
							}
						}
						else registerPerkUnavailable(cat, perk_array[i], "ex_specials_na");
						break;
					default:
						logprint("SPC: Invalid perk identifier \"" + perk_array[i] + "\". Please check \"ex_specials_order\"!\n");
				}
			}

			// check if we registered something
			if(!getPerkCategoryCount(cat, false))
			{
				level.ex_store = (level.ex_store & 1);
				logprint("SPC: No perks registered. Perks menu disabled\n");
			}
			else
			{
				// fill catalog for missing perks if not set to auto-adjust
				if(level.ex_store_maxperks)
				{
					for(i = game["perkcatalog"].size; i < game["perkcategories"][cat]["start"] + game["perkcategories"][cat]["max"]; i++)
						if(!isDefined(game["perkcatalog"][i])) registerPerk(cat, "-", "ex_specials_na", "-", "-");
				}
				game["perkcategories"][cat]["max"] = getPerkCategoryCount(cat, true);
				logprint("SPC: " + game["perkcategories"][cat]["max"] + " slot(s) occupied in category " + cat + " (starting at slot " + game["perkcategories"][cat]["start"] + ")\n");
			}
		}
		else
		{
			level.ex_store = (level.ex_store & 1);
			logprint("SPC: Perk ordering string empty or invalid. Perks menu disabled\n");
		}
	}

	// Check which perk made it into the array. Turn feature off if not in array
	if(!getPerkIndex("maxhealth")) level.ex_specials_maxhealth = 0;
	if(!getPerkIndex("maxammo")) level.ex_specials_maxammo = 0;
	if(!getPerkIndex("knife")) level.ex_specials_knife = 0;
	if(!getPerkIndex("supernade")) level.ex_supernade = 0;
	if(!getPerkIndex("vest")) level.ex_vest = 0;
	if(!getPerkIndex("beartrap")) level.ex_beartrap = 0;
	if(!getPerkIndex("monkey")) level.ex_monkey = 0;
	if(!getPerkIndex("bubble_small")) level.ex_bubble_small = 0;
	if(!getPerkIndex("bubble_big")) level.ex_bubble_big = 0;
	if(!getPerkIndex("stealth")) level.ex_stealth = 0;
	if(!getPerkIndex("insertion")) level.ex_insertion = 0;
	if(!getPerkIndex("wallfire")) level.ex_wallfire = 0;
	if(!getPerkIndex("flak")) level.ex_flak = 0;
	if(!getPerkIndex("gml")) level.ex_gml = 0;
	if(!getPerkIndex("cam")) level.ex_cam = 0;
	if(!getPerkIndex("uav")) level.ex_uav = 0;
	if(!getPerkIndex("sentrygun")) level.ex_sentrygun = 0;
	if(!getPerkIndex("ugv")) level.ex_ugv = 0;
	if(!getPerkIndex("quad")) level.ex_quad = 0;
	if(!getPerkIndex("gunship")) level.ex_gunship_special = 0;
	if(!getPerkIndex("heli")) level.ex_heli = 0;
}

rebuildPerksOrder()
{
	specials = [];
	if(level.ex_specials_maxhealth && specials.size < level.ex_store_maxperks) specials[specials.size] = "maxhealth";
	if(level.ex_specials_maxammo && specials.size < level.ex_store_maxperks) specials[specials.size] = "maxammo";
	if(level.ex_specials_knife && specials.size < level.ex_store_maxperks) specials[specials.size] = "knife";
	if(level.ex_supernade && specials.size < level.ex_store_maxperks) specials[specials.size] = "supernade";
	if(level.ex_vest && specials.size < level.ex_store_maxperks) specials[specials.size] = "vest";
	if(level.ex_beartrap && specials.size < level.ex_store_maxperks) specials[specials.size] = "beartrap";
	if(level.ex_monkey && specials.size < level.ex_store_maxperks) specials[specials.size] = "monkey";
	if(level.ex_bubble_small && specials.size < level.ex_store_maxperks) specials[specials.size] = "bubble_small";
	if(level.ex_bubble_big && specials.size < level.ex_store_maxperks) specials[specials.size] = "bubble_big";
	if(level.ex_stealth && specials.size < level.ex_store_maxperks) specials[specials.size] = "stealth";
	if(level.ex_insertion && specials.size < level.ex_store_maxperks) specials[specials.size] = "insertion";
	if(level.ex_wallfire && specials.size < level.ex_store_maxperks) specials[specials.size] = "wallfire";
	if(level.ex_flak && specials.size < level.ex_store_maxperks) specials[specials.size] = "flak";
	if(level.ex_gml && specials.size < level.ex_store_maxperks) specials[specials.size] = "gml";
	if(level.ex_cam && specials.size < level.ex_store_maxperks) specials[specials.size] = "cam";
	if(level.ex_uav && specials.size < level.ex_store_maxperks) specials[specials.size] = "uav";
	if(level.ex_sentrygun && specials.size < level.ex_store_maxperks) specials[specials.size] = "sentrygun";
	if(level.ex_ugv && specials.size < level.ex_store_maxperks) specials[specials.size] = "ugv";
	if(level.ex_quad && specials.size < level.ex_store_maxperks) specials[specials.size] = "quad";
	if(level.ex_gunship_special && specials.size < level.ex_store_maxperks) specials[specials.size] = "gunship";
	if(level.ex_heli && specials.size < level.ex_store_maxperks) specials[specials.size] = "heli";

	specials_order = "";
	for(i = 0; i < specials.size; i++) specials_order = specials_order + specials[i] + " ";

	return( tolower(trim(specials_order)) );
}

registerPerkUnavailable(cat, perk, configid)
{
	registerPerk(cat, "-", configid, "-", "-");
	logprint("SPC: Perk \"" + perk + "\" skipped, because it is not enabled!\n");
}

registerPerk(cat, perk, configid, hudicon, arcadeshader)
{
	if(perk == "-" || !getPerkIndex(perk))
	{
		// try to register perk
		if(perk != "-")
		{
			if(getPerkCategoryCount(cat, true) < game["perkcategories"][cat]["max"])
			{
				index = game["perkcatalog"].size;
				game["perkcatalog"][index]["category"] = cat;
				game["perkcatalog"][index]["name"] = perk;
				game["perkcatalog"][index]["axis_delay"] = 0;
				game["perkcatalog"][index]["axis_used"] = 0;
				game["perkcatalog"][index]["allies_delay"] = 0;
				game["perkcatalog"][index]["allies_used"] = 0;

				// set default properties
				game["perkcatalog"][index]["stock"] = 999999;
				game["perkcatalog"][index]["price"] = 0;
				game["perkcatalog"][index]["group"] = 0;
				game["perkcatalog"][index]["keep"] = 1;
				game["perkcatalog"][index]["player_maxbuy"] = 0;
				game["perkcatalog"][index]["player_maxact"] = 0;
				game["perkcatalog"][index]["player_delay"] = 0;
				game["perkcatalog"][index]["team_maxbuy"] = 0;
				game["perkcatalog"][index]["team_maxact"] = 0;
				game["perkcatalog"][index]["team_delay"] = 0;
				game["perkcatalog"][index]["test"] = 0;

				// get menu text
				game["perkcatalog"][index]["menutext"] = [[level.ex_drm]](configid + "_text", "[No Text Defined]", "", "", "string");

				// precache the shaders associated with this perk
				game["perkcatalog"][index]["hudicon"] = hudicon;
				[[level.ex_PrecacheShader]](game["perkcatalog"][index]["hudicon"]);
				if((level.ex_arcade_shaders & 8) == 8)
				{
					if(!isDefined(arcadeshader) || !level.ex_arcade_shaders_perkall)
					{
						if(cat == 0 || cat == 1) game["perkcatalog"][index]["arcade"] = "x2_weaponunlock";
							else game["perkcatalog"][index]["arcade"] = "x2_perkunlock";
					}
					else game["perkcatalog"][index]["arcade"] = arcadeshader;
					if(game["perkcatalog"][index]["arcade"] != "none") [[level.ex_PrecacheShader]](game["perkcatalog"][index]["arcade"]);
				}

				// set perk properties
				auth = trim([[level.ex_drm]](configid + "_auth", "999999,0,0,1,0,0,0,0,0,0,0", "", "", "string"));
				if(auth == "") auth = "999999,0,0,1,0,0,0,0,0,0,0";
				auth_array = strtok(auth, ",");
				if(isDefined(auth_array) && auth_array.size == 11)
				{
					game["perkcatalog"][index]["stock"] = strToInt(auth_array[0], 999999);
					game["perkcatalog"][index]["price"] = strToInt(auth_array[1], 0);
					game["perkcatalog"][index]["group"] = strToInt(auth_array[2], 0);
					game["perkcatalog"][index]["keep"] = strToInt(auth_array[3], 1);
					game["perkcatalog"][index]["player_maxbuy"] = strToInt(auth_array[4], 0);
					game["perkcatalog"][index]["player_maxact"] = strToInt(auth_array[5], 0);
					game["perkcatalog"][index]["player_delay"] = strToInt(auth_array[6], 0);
					game["perkcatalog"][index]["team_maxbuy"] = strToInt(auth_array[7], 0);
					game["perkcatalog"][index]["team_maxact"] = strToInt(auth_array[8], 0);
					game["perkcatalog"][index]["team_delay"] = strToInt(auth_array[9], 0);
					game["perkcatalog"][index]["test"] = strToInt(auth_array[10], 0);

					/*
					logprint("SPC: setting properties for perk \"" + perk + "\"\n");
					logprint("        stock: " + game["perkcatalog"][index]["stock"] + "\n");
					logprint("        price: " + game["perkcatalog"][index]["price"] + "\n");
					logprint("        group: " + game["perkcatalog"][index]["group"] + "\n");
					logprint("         keep: " + game["perkcatalog"][index]["keep"] + "\n");
					logprint("player_maxbuy: " + game["perkcatalog"][index]["player_maxbuy"] + "\n");
					logprint("player_maxact: " + game["perkcatalog"][index]["player_maxact"] + "\n");
					logprint(" player_delay: " + game["perkcatalog"][index]["player_delay"] + "\n");
					logprint("  team_maxbuy: " + game["perkcatalog"][index]["team_maxbuy"] + "\n");
					logprint("  team_maxact: " + game["perkcatalog"][index]["team_maxact"] + "\n");
					logprint("   team_delay: " + game["perkcatalog"][index]["team_delay"] + "\n");
					logprint("         test: " + game["perkcatalog"][index]["test"] + "\n");
					*/
				}
				else logprint("SPC: no valid auth for perk \"" + perk + "\". Setting default properties\n");

				// make sure we have the perks tracking array
				if(!isDefined(game["perks"]))
				{
					game["perks"] = [];
					for(i = 0; i < level.ex_maxclients; i++) game["perks"][i] = [];
				}

				// populate tracking array for this perk
				for(i = 0; i < level.ex_maxclients; i++)
				{
					game["perks"][i][perk]["bought"] = 0;
					game["perks"][i][perk]["used"] = 0;
					game["perks"][i][perk]["active"] = 0;
					game["perks"][i][perk]["locked"] = false;
					game["perks"][i][perk]["player_delay"] = 0;
				}

				// perk registered
				logprint("SPC: Perk \"" + perk + "\" registered (slot " + index + ", category " + cat + ")\n");
				return(true);
			}
			else
			{
				logprint("SPC: Maximum number of perks registered! Perk \"" + perk + "\" discarded\n");
				return(false);
			}
		}
		// try to register empty slot
		else
		{
			if(level.perkcatalog_init)
			{
				if(getPerkCategoryCount(cat, true) < game["perkcategories"][cat]["max"])
				{
					index = game["perkcatalog"].size;
					game["perkcatalog"][index]["category"] = cat;
					game["perkcatalog"][index]["name"] = perk;
					game["perkcatalog"][index]["menutext"] = [[level.ex_drm]](configid + "_text", "[No Text Defined]", "", "", "string");
					if(index == 0) logprint("SPC: Catch-all slot registered (slot " + index + ", category " + cat + ")\n");
						else logprint("SPC: Empty slot registered (slot " + index + ", category " + cat + ")\n");
					return(true);
				}
				else
				{
					logprint("SPC: Maximum number of perks registered! Perk \"" + perk + "\" discarded\n");
					return(false);
				}
			}
			else return(true);
		}
	}
	else return(true);
}

unregisterPerk(perk_variant, reason)
{
	// accept either the perk name or the perk index number
	if(isstring(perk_variant))
	{
		index = getPerkIndex(perk_variant);
		if(!index) return(0);
		perk = perk_variant;
	}
	else
	{
		index = perk_variant;
		perk = getPerkName(index);
		if(perk == "-") return(0);
	}

	log = "SPC: Unregistered perk \"" + perk + "\" (slot " + index + ", category " + game["perkcatalog"][index]["category"] + ")";
	if(isDefined(reason)) log += ". Reason: " + reason;
	logprint(log + "\n");
	game["perkcatalog"][index]["name"] = "-";
	game["perkcatalog"][index]["menutext"] = level.ex_store_na_text;
}

registerPerkPrecache(perk, initproc, initpostproc)
{
	index = getPerkIndex(perk);
	if(index)
	{
		// store precaching procedure for later use by init()
		game["perkcatalog"][index]["initproc"] = initproc;

		// store post-map precaching procedure for later use by initPost()
		game["perkcatalog"][index]["initpostproc"] = initpostproc;
	}
}

registerPerkCheck(perk, checkproc)
{
	index = getPerkIndex(perk);
	if(index)
	{
		// store assignment procedure for later use
		game["perkcatalog"][index]["checkproc"] = checkproc;
	}
}

registerPerkAssignment(perk, assignproc, assigndelayproc)
{
	index = getPerkIndex(perk);
	if(index)
	{
		// store assignment procedure for later use
		game["perkcatalog"][index]["assignproc"] = assignproc;

		// store delayed assignment procedure for later use by onPlayerSpawned()
		if(game["perkcatalog"][index]["test"]) game["perkcatalog"][index]["assigndelayproc"] = assigndelayproc;
	}
}

registerPerkRemoval(perk, removeproc)
{
	index = getPerkIndex(perk);
	if(index)
	{
		// store removal procedure for later use
		game["perkcatalog"][index]["removeproc"] = removeproc;
	}
}

getPerkIndex(perk)
{
	for(i = 1; i < game["perkcatalog"].size; i++)
		if(game["perkcatalog"][i]["name"] == perk) return(i);
	return(0);
}

getPerkCategoryCount(cat, count_unavailable)
{
	if(!isDefined(count_unavailable)) count_unavailable = true;
	count = 0;
	for(i = 1; i < game["perkcatalog"].size; i++)
		if(game["perkcatalog"][i]["category"] == cat && (game["perkcatalog"][i]["name"] != "-" || count_unavailable)) count++;
	return(count);
}

getPerkName(index)
{
	if(index > 0 && index <= game["perkcatalog"].size) return(game["perkcatalog"][index]["name"]);
	return("-");
}

getPerkStock(perk_variant)
{
	// accept either the perk name or the perk index number
	if(isstring(perk_variant))
	{
		index = getPerkIndex(perk_variant);
		if(!index) return(0);
	}
	else
	{
		index = perk_variant;
		perk = getPerkName(index);
		if(perk == "-") return(0);
	}
	return(game["perkcatalog"][index]["stock"]);
}

getPerkHudIcon(index)
{
	if(index > 0 && index <= game["perkcatalog"].size && game["perkcatalog"][index]["name"] != "-") return(game["perkcatalog"][index]["hudicon"]);
	return("black");
}

getPerkArcade(index)
{
	if(index > 0 && index <= game["perkcatalog"].size && game["perkcatalog"][index]["name"] != "-") return(game["perkcatalog"][index]["arcade"]);
	return("none");
}

getPerkPriority(index)
{
	if(!index) return(false);
	entity = self getEntityNumber();

	// priority based on registration order (next to last)
	if(level.ex_store_priority == 0)
	{
		for(i = index + 1; i < game["perkcatalog"].size; i++)
		{
			perk = game["perkcatalog"][i]["name"];
			if(perk == "-") continue;
			if(game["perks"][entity][perk]["locked"] && (game["perks"][entity][perk]["used"] < game["perks"][entity][perk]["bought"])) return(false);
		}
	}
	// priority based on registration order (previous to first)
	else if(level.ex_store_priority == 1)
	{
		for(i = game["perkcatalog"].size - 1; i < index + 1; i--)
		{
			perk = game["perkcatalog"][i]["name"];
			if(perk == "-") continue;
			if(game["perks"][entity][perk]["locked"] && (game["perks"][entity][perk]["used"] < game["perks"][entity][perk]["bought"])) return(false);
		}
	}
	// priority based on price
	else if(level.ex_store_priority == 2)
	{
		price = game["perkcatalog"][index]["price"];
		for(i = 1; i < game["perkcatalog"].size; i++)
		{
			if(i == index) continue;
			perk = game["perkcatalog"][i]["name"];
			if(perk == "-") continue;
			if(game["perks"][entity][perk]["locked"] && game["perkcatalog"][i]["price"] > price) return(false);
		}
	}
	return(true);
}

playerResetPerks()
{
	entity = self getEntityNumber();
	for(i = 1; i < game["perkcatalog"].size; i++)
	{
		if(game["perkcatalog"][i]["name"] == "-") continue;
		game["perks"][entity][game["perkcatalog"][i]["name"]]["bought"] = 0;
		game["perks"][entity][game["perkcatalog"][i]["name"]]["used"] = 0;
		game["perks"][entity][game["perkcatalog"][i]["name"]]["active"] = 0;
		game["perks"][entity][game["perkcatalog"][i]["name"]]["locked"] = false;
		game["perks"][entity][game["perkcatalog"][i]["name"]]["player_delay"] = 0;
	}
}

playerUnlockPerks()
{
	entity = self getEntityNumber();
	for(i = 1; i < game["perkcatalog"].size; i++)
	{
		if(game["perkcatalog"][i]["name"] == "-") continue;
		game["perks"][entity][game["perkcatalog"][i]["name"]]["locked"] = false;
	}
}

playerUnlockPerk(perk_variant)
{
	// accept either the perk name or the perk index number
	if(isstring(perk_variant))
	{
		if(!getPerkIndex(perk_variant)) return;
		perk = perk_variant;
	}
	else
	{
		perk = getPerkName(perk_variant);
		if(perk == "-") return;
	}

	entity = self getEntityNumber();
	game["perks"][entity][perk]["locked"] = false;
}


playerPerkIsLocked(perk_variant, lock)
{
	// accept either the perk name or the perk index number
	if(isstring(perk_variant))
	{
		if(!getPerkIndex(perk_variant)) return(false);
		perk = perk_variant;
	}
	else
	{
		perk = getPerkName(perk_variant);
		if(perk == "-") return(false);
	}

	if(!isDefined(lock)) lock = false;
	entity = self getEntityNumber();
	locked = game["perks"][entity][perk]["locked"];
	if(!locked && lock) game["perks"][entity][perk]["locked"] = true;
	return(locked);
}

playerBoughtPerk(perk_variant)
{
	// accept either the perk name or the perk index number
	if(isstring(perk_variant))
	{
		if(!getPerkIndex(perk_variant)) return;
		perk = perk_variant;
	}
	else
	{
		perk = getPerkName(perk_variant);
		if(perk == "-") return;
	}

	entity = self getEntityNumber();
	game["perks"][entity][perk]["bought"]++;
	game["perks"][entity][perk]["locked"] = true;

	//logprint("SPC: [debug] Player " + self.name + " bought perk \"" + perk + "\" (total " + game["perks"][entity][perk]["bought"] + ")\n");
}

playerStartUsingPerk(perk_variant, unlock)
{
	// accept either the perk name or the perk index number
	if(isstring(perk_variant))
	{
		if(!getPerkIndex(perk_variant)) return;
		perk = perk_variant;
	}
	else
	{
		perk = getPerkName(perk_variant);
		if(perk == "-") return;
	}

	if(!isDefined(unlock)) unlock = false;
	entity = self getEntityNumber();
	game["perks"][entity][perk]["used"]++;
	game["perks"][entity][perk]["active"]++;
	if(unlock) game["perks"][entity][perk]["locked"] = false;

	// keep track of used perks for axis and allies, also in DM, so we can check total usage
	index = getPerkIndex(perk);
	if(self.pers["team"] == "axis") game["perkcatalog"][index]["axis_used"]++;
		else game["perkcatalog"][index]["allies_used"]++;

	if(level.ex_teamplay)
	{
		// set team delay
		if(self.pers["team"] == "axis") game["perkcatalog"][index]["axis_delay"] = game["perkcatalog"][index]["team_delay"];
			else game["perkcatalog"][index]["allies_delay"] = game["perkcatalog"][index]["team_delay"];
	}

	//logprint("SPC: [debug] Player " + self.name + " started using perk \"" + perk + "\" (total " + game["perks"][entity][perk]["active"] + ")\n");
}

playerStopUsingPerk(perk_variant, unlock)
{
	// accept either the perk name or the perk index number
	if(isstring(perk_variant))
	{
		if(!getPerkIndex(perk_variant)) return;
		perk = perk_variant;
	}
	else
	{
		perk = getPerkName(perk_variant);
		if(perk == "-") return;
	}

	if(!isDefined(unlock)) unlock = false;
	entity = self getEntityNumber();
	if(game["perks"][entity][perk]["active"])
	{
		game["perks"][entity][perk]["active"]--;
		if(unlock) game["perks"][entity][perk]["locked"] = false;

		// set player delay
		index = getPerkIndex(perk);
		game["perks"][entity][perk]["player_delay"] = game["perkcatalog"][index]["player_delay"];

		//logprint("SPC: [debug] Player " + self.name + " stopped using perk \"" + perk + "\" (total " + game["perks"][entity][perk]["active"] + ")\n");
	}
}

playerGiveBackPerks()
{
	entity = self getEntityNumber();
	for(i = 1; i < game["perkcatalog"].size; i++)
	{
		perk = game["perkcatalog"][i]["name"];
		if(perk == "-") continue;
		if(game["perkcatalog"][i]["keep"] && isDefined(game["perkcatalog"][i]["assignproc"]))
		{
			bought = game["perks"][entity][perk]["bought"];
			used = game["perks"][entity][perk]["used"];
			if(used < bought)
			{
				game["perks"][entity][perk]["locked"] = true;
				thread [[game["perkcatalog"][i]["assignproc"]]](i, 0);
			}
		}
	}
}

playerGiveBackPerk(perk_variant)
{
	// accept either the perk name or the perk index number
	if(isstring(perk_variant))
	{
		if(!getPerkIndex(perk_variant)) return;
		perk = perk_variant;
	}
	else
	{
		perk = getPerkName(perk_variant);
		if(perk == "-") return;
	}

	entity = self getEntityNumber();
	index = getPerkIndex(perk);
	game["perks"][entity][perk]["locked"] = true;
	thread [[game["perkcatalog"][index]["assignproc"]]](index, 0);
}

levelStopUsingPerk(entity, perk_variant, unlock)
{
	// accept either the perk name or the perk index number
	if(isstring(perk_variant))
	{
		if(!getPerkIndex(perk_variant)) return;
		perk = perk_variant;
	}
	else
	{
		perk = getPerkName(perk_variant);
		if(perk == "-") return;
	}

	if(!isDefined(unlock)) unlock = false;
	if(game["perks"][entity][perk]["active"])
	{
		game["perks"][entity][perk]["active"]--;
		if(unlock) game["perks"][entity][perk]["locked"] = false;

		// set player delay
		index = getPerkIndex(perk);
		game["perks"][entity][perk]["player_delay"] = game["perkcatalog"][index]["player_delay"];

		//logprint("SPC: [debug] Level stopped using perk \"" + perk + "\" for entity " + entity + " (total " + game["perks"][entity][perk]["active"] + ")\n");
	}
}

levelResetUsingPerk(entity, perk_variant)
{
	// accept either the perk name or the perk index number
	if(isstring(perk_variant))
	{
		if(!getPerkIndex(perk_variant)) return;
		perk = perk_variant;
	}
	else
	{
		perk = getPerkName(perk_variant);
		if(perk == "-") return;
	}

	game["perks"][entity][perk]["active"] = 0;
	//logprint("SPC: [debug] Level reset of perk \"" + perk + "\" for entity " + entity + " (total " + game["perks"][entity][perk]["active"] + ")\n");
}

removeAllPerks()
{
	for(i = 1; i < game["perkcatalog"].size; i++)
	{
		perk = game["perkcatalog"][i]["name"];
		if(perk == "-") continue;
		if(isDefined(game["perkcatalog"][i]["removeproc"])) thread [[game["perkcatalog"][i]["removeproc"]]]();
	}
}

menuResponse(response, cat)
{
	self endon("disconnect");

	if(!isDefined(response) || response == "") return;
	if(self.sessionteam == "spectator") return;

	// mod defense condition
	if(level.ex_entities_defcon == 2)
	{
		self iprintlnbold(&"SPECIALS_NO_STORE");
		return;
	}

	// specials: weapons (category 1)
	if(cat == 1 && (level.ex_store & 1) != 1)
	{
		self iprintlnbold(&"SPECIALS_NO_STORE");
		return;
	}

	// specials: perks (category 2)
	if(cat == 2 && (level.ex_store & 2) != 2)
	{
		self iprintlnbold(&"SPECIALS_NO_STORE");
		return;
	}

	// store might be locked for player
	if(isDefined(self.specials_locked))
	{
		specials_locked_sec = ( (gettime() / 1000) - self.specials_locked);
		if(specials_locked_sec < 300)
		{
			self iprintlnbold(&"SPECIALS_NO_STORE_LOCK");
			return;
		}
		else self.specials_locked = undefined;
	}

	// minimum points to buy
	if(level.ex_store_minpoints && self.pers["score"] < level.ex_store_minpoints)
	{
		self iprintlnbold(&"SPECIALS_NO_STORE_YET", level.ex_store_minpoints);
		return;
	}

	// check menu repsonse
	perk = checkResponse(response, cat);
	if(perk == "-")
	{
		self iprintlnbold(&"SPECIALS_NO_VALIDRESPONSE");
		return;
	}

	// check perk properties
	if(!checkPerk(perk)) return;

	self thread playerBoughtPerk(perk);
	index = getPerkIndex(perk);
	thread [[game["perkcatalog"][index]["assignproc"]]](index, 0);
}

checkResponse(response, cat)
{
	if(response != "-")
	{
		validchars = "-1234567890hijklmnopu";
		for(i = 0; i < validchars.size; i++)
		{
			if(response == validchars[i])
			{
				index = game["perkcategories"][cat]["start"] - 1 + i;
				//logprint("SPC: [debug] Detected category " + cat + ", response " + response + ", catalog index " + index + "\n");
				if(isDefined(game["perkcatalog"][index])) return(game["perkcatalog"][index]["name"]);
					else break;
			}
		}
	}
	return(game["perkcatalog"][0]["name"]);
}

checkPerk(perk)
{
	index = getPerkIndex(perk);

	// check if the perk has a valid assignment procedure
	if(index && !isDefined(game["perkcatalog"][index]["assignproc"]))
	{
		self iprintlnbold(&"SPECIALS_NO_FEATURE");
		return(false);
	}

	// check if account system grants access
	if(level.ex_accounts && self.pers["account"]["status"] == 1 && (level.ex_accounts_lock & 64) == 64)
	{
		self iprintlnbold(&"ACCOUNTS_FEATURE_LOCKED");
		return(false);
	}

	// check if perk is in stock
	if(!game["perkcatalog"][index]["stock"])
	{
		self iprintlnbold(&"SPECIALS_NO_STOCK");
		return(false);
	}

	// check if perk is already available to player
	entity = self getEntityNumber();
	available = !game["perks"][entity][perk]["locked"];
	if(level.ex_currentgt == "ft" && isDefined(self.frozenstate) && self.frozenstate == "frozen") available = false;
	if(!available)
	{
		self iprintlnbold(&"SPECIALS_NO_PERK");
		return(false);
	}

	// if registered, call procedure to check prerequisites
	if(isDefined(game["perkcatalog"][index]["checkproc"]))
	{
		if( ![[game["perkcatalog"][index]["checkproc"]]](index) )
		{
			self iprintlnbold(&"SPECIALS_NO_FEATURE");
			return(false);
		}
	}

	// check player delay
	player_delay = game["perks"][entity][perk]["player_delay"];
	if(player_delay)
	{
		self iprintlnbold(&"SPECIALS_NO_PLAYERDELAY", player_delay);
		return(false);
	}

	// check team delay
	if(level.ex_teamplay)
	{
		if(self.pers["team"] == "axis") team_delay = game["perkcatalog"][index]["axis_delay"];
			else team_delay = game["perkcatalog"][index]["allies_delay"];
		if(team_delay)
		{
			self iprintlnbold(&"SPECIALS_NO_TEAMDELAY", team_delay);
			return(false);
		}
	}

	// check player max buy
	limit = game["perkcatalog"][index]["player_maxbuy"];
	if(limit)
	{
		// alternatively have it check for limit on bought perks
		//if(game["perks"][entity][perk]["bought"] >= limit)
		if(game["perks"][entity][perk]["used"] >= limit)
		{
			self iprintlnbold(&"SPECIALS_NO_MAXBUY", limit);
			return(false);
		}
	}

	// check player max active
	limit = game["perkcatalog"][index]["player_maxact"];
	if(limit)
	{
		if(game["perks"][entity][perk]["active"] >= limit)
		{
			self iprintlnbold(&"SPECIALS_NO_MAXACT", limit);
			return(false);
		}
	}

	// check team max buy
	if(level.ex_teamplay)
	{
		limit = game["perkcatalog"][index]["team_maxbuy"];
		if(limit)
		{
			if(self.pers["team"] == "axis") bought = game["perkcatalog"][index]["axis_used"];
				else bought = game["perkcatalog"][index]["allies_used"];
			if(bought >= limit)
			{
				self iprintlnbold(&"SPECIALS_NO_MAXBUY_TEAM", limit);
				return(false);
			}
		}

		// check team max active
		limit = game["perkcatalog"][index]["team_maxact"];
		if(limit)
		{
			if(getTeamActive(perk) >= limit)
			{
				self iprintlnbold(&"SPECIALS_NO_MAXACT_TEAM", limit);
				return(false);
			}
		}

		// check group max active for team
		group = game["perkcatalog"][index]["group"];
		if(group)
		{
			if(getTeamGroupActive(perk, group) > 0)
			{
				self iprintlnbold(&"SPECIALS_NO_MAXGROUP", group);
				return(false);
			}
		}
	}
	else
	{
		// DM: check total max bought (use team max buy * 2)
		limit = game["perkcatalog"][index]["team_maxbuy"] * 2;
		if(limit)
		{
			bought = game["perkcatalog"][index]["axis_used"] + game["perkcatalog"][index]["allies_used"];
			if(bought >= limit)
			{
				self iprintlnbold(&"SPECIALS_NO_MAXBUY_TOTAL", limit);
				return(false);
			}
		}

		// DM: check total max active (use team max active * 2)
		limit = game["perkcatalog"][index]["team_maxact"] * 2;
		if(limit)
		{
			if(getTotalActive(perk) >= limit)
			{
				self iprintlnbold(&"SPECIALS_NO_MAXACT_TOTAL", limit);
				return(false);
			}
		}

		// check group max active for player
		group = game["perkcatalog"][index]["group"];
		if(group)
		{
			if(getPlayerGroupActive(perk, group) > 0)
			{
				self iprintlnbold(&"SPECIALS_NO_MAXGROUP", group);
				return(false);
			}
		}
	}

	// buying not allowed if score is sub-zero
	if(self.pers["score"] < 0)
	{
		self iprintlnbold(&"SPECIALS_NO_POINTS_SUBZERO");
		return(false);
	}

	// keep price check last, because it handles payment (score adjustment)
	price = game["perkcatalog"][index]["price"];
	if(price > 0)
	{
		// check points
		switch(level.ex_store_payment)
		{
			case 0:
				if(self.pers["score"] < price)
				{
					self iprintlnbold(&"SPECIALS_NO_POINTS", price);
					return(false);
				}
				break;
			case 1:
				if(self.pers["bonus"] < price)
				{
					self iprintlnbold(&"SPECIALS_NO_POINTS", price);
					return(false);
				}
				break;
			case 2:
				if(self.pers["cash"] < price)
				{
					self iprintlnbold(&"SPECIALS_NO_POINTS", price);
					return(false);
				}
				break;
		}

		// keep specials_cash above adjusting score, otherwise it will force a rank demotion
		self.pers["cash_spent"] += price;

		// handle payment
		switch(level.ex_store_payment)
		{
			case 0:
				self thread [[level.ex_scorePlayer]](0 - price);
				if(level.ex_store_payment || level.ex_teamplay) self thread playerHudSetValue("cash", self.pers["score"]);
				break;
			case 1:
				self.pers["bonus"] = self.pers["bonus"] - price;
				if(level.ex_store_payment || level.ex_teamplay) self thread playerHudSetValue("cash", self.pers["bonus"]);
				break;
			case 2:
				self.pers["cash"] = self.pers["cash"] - price;
				if(level.ex_store_payment || level.ex_teamplay) self thread playerHudSetValue("cash", self.pers["cash"]);
				break;
		}
	}

	// adjust stock
	game["perkcatalog"][index]["stock"]--;

	return(true);
}

getPlayerGroupActive(perk, group)
{
	total = 0;
	entity = self getEntityNumber();
	for(i = 1; i < game["perkcatalog"].size; i++)
	{
		if(game["perkcatalog"][i]["name"] != "-" && game["perkcatalog"][i]["group"] == group)
		{
			other_perk = game["perkcatalog"][i]["name"];
			if(perk != other_perk) total += game["perks"][entity][other_perk]["active"];
		}
	}
	return(total);
}

getTeamGroupActive(perk, group)
{
	total = 0;
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isDefined(player.pers["team"])) continue;
		if(player.pers["team"] == self.pers["team"]) total += player getPlayerGroupActive(perk, group);
	}
	return(total);
}

getTeamActive(perk)
{
	total = 0;
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isDefined(player.pers["team"])) continue;
		if(player.pers["team"] == self.pers["team"])
		{
			entity = player getEntityNumber();
			total += game["perks"][entity][perk]["active"];
		}
	}
	return(total);
}

getTotalActive(perk)
{
	total = 0;
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isDefined(player.pers["team"])) continue;
		entity = player getEntityNumber();
		total += game["perks"][entity][perk]["active"];
	}
	return(total);
}

playerSpecialtyCvars()
{
	index_weapons = 0;
	index_perks = 0;

	for(i = 1; i < game["perkcatalog"].size; i++)
	{
		if(isDefined(game["perkcatalog"][i]))
		{
			switch(game["perkcatalog"][i]["category"])
			{
				case 1: // weapons
					index_weapons++;
					self setClientCvar("ui_specials_weapon" + index_weapons, getSpecialtyKey(index_weapons) + game["perkcatalog"][i]["menutext"]);
					//logprint("SPC: [debug] Variable \"ui_specials_weapon" + index_weapons + "\" set to \"" + getSpecialtyKey(index_weapons) + game["perkcatalog"][i]["menutext"] + "\"\n");
					break;
				case 2: // perks
					index_perks++;
					self setClientCvar("ui_specials_perk" + index_perks, getSpecialtyKey(index_perks) + game["perkcatalog"][i]["menutext"]);
					//logprint("SPC: [debug] Variable \"ui_specials_perk" + index_perks + "\" set to \"" + getSpecialtyKey(index_perks) + game["perkcatalog"][i]["menutext"] + "\"\n");
					break;
			}
		}
	}
}

getSpecialtyKey(index)
{
	switch(index)
	{
		case  1: return("1. ");
		case  2: return("2. ");
		case  3: return("3. ");
		case  4: return("4. ");
		case  5: return("5. ");
		case  6: return("6. ");
		case  7: return("7. ");
		case  8: return("8. ");
		case  9: return("9. ");
		case 10: return("0. ");
		case 11: return("H. ");
		case 12: return("I. ");
		case 13: return("J. ");
		case 14: return("K. ");
		case 15: return("L. ");
		case 16: return("M. ");
		case 17: return("N. ");
		case 18: return("O. ");
		case 19: return("P. ");
		case 20: return("U. ");
	}
}

hudNotifySpecial(index, delay)
{
	self endon("kill_thread");

	shader = game["perkcatalog"][index]["hudicon"];

	basex = 120;
	if(level.ex_statstotal && level.ex_statstotal_monitor_player) basex += 30;

	// first check if this hud elem is already on screen
	hudelem = "spc_icon" + index;

	hud_index = playerHudIndex(hudelem);
	if(hud_index == -1)
	{
		// move other perk hud elems to the right
		for(i = 1; i < game["perkcatalog"].size; i++)
		{
			checkelem = "spc_icon" + i;
			check_index = playerHudIndex(checkelem);
			if(check_index != -1) playerHudMove(check_index, .25, 0, 30, undefined, true);
		}

		hud_index = playerHudCreate(hudelem, basex, 450, level.ex_iconalpha, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
		if(hud_index != -1)
		{
			playerHudSetShader(hud_index, shader, 32, 32);
			playerHudScale(hud_index, .5, 0, 24, 24);
		}
	}

	if(isDefined(delay)) thread hudNotifySpecialRemove(index, delay);
}

hudNotifySpecialRemove(index, delay)
{
	self endon("kill_thread");

	if(isDefined(delay))
	{
		if(delay < 1) delay = 1;
		wait( [[level.ex_fpstime]](delay) );
	}

	hudelem = "spc_icon" + index;
	hud_index = playerHudIndex(hudelem);
	if(hud_index != -1)
	{
		hudelem_x = playerHudGetXYZ(hud_index)[0];
		playerHudDestroy(hudelem);

		// move other perk hud elems to the left
		for(i = 1; i < game["perkcatalog"].size; i++)
		{
			hudelem = "spc_icon" + i;
			hud_index = playerHudIndex(hudelem);
			if(hud_index != -1 && playerHudGetXYZ(hud_index)[0] > hudelem_x)
				playerHudMove(hudelem, .25, 0, -30, undefined, true);
		}
	}
}

hudNotifyProtected()
{
	hud_index = playerHudIndex("spc_proticon");
	if(hud_index == -1)
	{
		hud_index = playerHudCreate("spc_proticon", 150, 420, level.ex_iconalpha, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
		if(hud_index != -1) playerHudSetShader(hud_index, game["mod_protect_hudicon"], 24, 24);
	}
}

hudNotifyProtectedRemove()
{
	playerHudDestroy("spc_proticon");
}
