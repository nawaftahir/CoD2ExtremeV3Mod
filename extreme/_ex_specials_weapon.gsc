#include extreme\_ex_specials;
#include extreme\_ex_main_utils;

perkInit(index)
{
	// perk related precaching
}

perkInitPost(index)
{
	// perk related precaching after map load

	// done here because the weapon array needs to exist first, which is done
	// AFTER perkInit but BEFORE perkInitPost
	weaponspec = trim( [[level.ex_drm]]("ex_" + game["perkcatalog"][index]["name"] + "_prop", "", "", "", "string") );
	if(weaponspec != "")
	{
		weaponspec_array = strtok(weaponspec, ",");
		if(isDefined(weaponspec_array) && weaponspec_array.size == 6)
		{
			weaponfile = trim(tolower(weaponspec_array[0]));
			game["perkcatalog"][index]["weaponfile"] = weaponfile;

			weapontype = strToInt(weaponspec_array[1], 0);
			if(weapontype < 0 || weapontype > 2) weapontype = 0;
			game["perkcatalog"][index]["weapontype"] = weapontype;

			weaponclass = trim(tolower(weaponspec_array[2]));
			maps\mp\gametypes\_weapons::registerWeapon(weaponfile, weaponclass, undefined, 0, "all", 15, getLocString(weaponfile), 0);
			level.weapons[weaponfile].allow = 1;
			level.weapons[weaponfile].limit = 0;
			level.weapons[weaponfile].clip_limit = strToInt(weaponspec_array[3], 999);
			level.weapons[weaponfile].ammo_limit = strToInt(weaponspec_array[4], 999);
			level.weapons[weaponfile].wdm = strToInt(weaponspec_array[5], 100);
			level.weapons[weaponfile].perkindex = index;

			// precache weapon file
			[[level.ex_PrecacheItem]](weaponfile);

			// request projectile device (close proximity explosions)
			if(weaponclass == "gl") [[level.ex_devRequest]]("gl_grenade");
				else if(weaponclass == "rl") [[level.ex_devRequest]]("rpg_missile");
		}
		else unregisterPerk(index, "Weapon properties invalid");
	}
	else unregisterPerk(index, "Weapon properties undefined");
}

perkCheck(index)
{
	// checks before being able to buy this perk
	if(self hasWeapon(game["perkcatalog"][index]["weaponfile"])) return(false);
	return(true);
}

perkAssignDelayed(index, delay)
{
	self endon("kill_thread");

	if(isDefined(self.pers["isbot"])) return;
	wait( [[level.ex_fpstime]](delay) );

	if(!playerPerkIsLocked(index, true)) self thread perkAssign(index, 0);
}

perkAssign(index, delay)
{
	self endon("kill_thread");

	if(isDefined(self.pers["isbot"])) return;
	wait( [[level.ex_fpstime]](delay) );

	if((level.ex_arcade_shaders & 8) == 8) self thread extreme\_ex_player_arcade::showArcadeShader(getPerkArcade(index), level.ex_arcade_shaders_perk);
		else self iprintlnbold(&"SPECIALS_WEAPON_READY");

	self thread hudNotifySpecial(index, 5);
	if(level.ex_store_keeptimer) thread perkKeepTimer(index);
		else self thread playerStartUsingPerk(index, false);

	switch(game["perkcatalog"][index]["weapontype"])
	{
		case 0: thread activateOnhandWeapon(index, game["perkcatalog"][index]["weaponfile"]); break;
		case 1: thread activateOffhandFragWeapon(index, game["perkcatalog"][index]["weaponfile"]); break;
		case 2: thread activateOffhandSmokeWeapon(index, game["perkcatalog"][index]["weaponfile"]); break;
	}
}

perkKeepTimer(index)
{
	self endon("kill_thread");
	self endon("kill_keep" + index);

	wait( [[level.ex_fpstime]](level.ex_store_keeptimer) );
	self thread playerStartUsingPerk(index, false);
}

//------------------------------------------------------------------------------
// On-hand weapons
//------------------------------------------------------------------------------
activateOnhandWeapon(index, weaponfile)
{
	self endon("kill_thread");

	weaponslot = "primaryb";
	if(!level.ex_wepo_class && level.ex_wepo_secondary && level.ex_wepo_sidearm)
	{
		if(isPerkWeaponInSlot("primary") || isSidearmInSlot("primary")) weaponslot = "primary";
			else if(isPerkWeaponInSlot("primaryb") || isSidearmInSlot("primaryb")) weaponslot = "primaryb";
				else weaponslot = "virtual";
	}

	// release other on-hand perk weapons
	releasePerkWeaponOfType(0);

	if(weaponslot != "virtual")
	{
		weaponinslot = self getWeaponSlotWeapon(weaponslot);
		self takeWeapon(weaponinslot);
		self setWeaponSlotWeapon(weaponslot, weaponfile);

		clip = self extreme\_ex_weapons::getWeaponSlotClipAmmoDefault(weaponfile);
		if(!isDefined(clip) || !clip) clip = self getWeaponSlotClipAmmo(weaponslot);
		self setWeaponSlotClipAmmo(weaponslot, clip);

		reserve = self extreme\_ex_weapons::getWeaponSlotAmmoDefault(weaponfile);
		if(!isDefined(reserve) || reserve < 0) reserve = self getWeaponSlotAmmo(weaponslot);
		self setWeaponSlotAmmo(weaponslot, reserve);

		if(!level.ex_wepo_secondary && !level.ex_wepo_sidearm)
		{
			self.weapon[weaponslot].name = weaponfile;
			self.weapon[weaponslot].clip = clip;
			self.weapon[weaponslot].reserve = reserve;
			self.weapon[weaponslot].maxammo = clip + reserve;
		}
	}
	else
	{
		clip = self extreme\_ex_weapons::getWeaponSlotClipAmmoDefault(weaponfile);
		if(!isDefined(clip) || !clip) clip = self getWeaponSlotClipAmmo(weaponslot);

		reserve = self extreme\_ex_weapons::getWeaponSlotAmmoDefault(weaponfile);
		if(!isDefined(reserve) || reserve < 0) reserve = self getWeaponSlotAmmo(weaponslot);

		self.weapon[weaponslot].name = weaponfile;
		self.weapon[weaponslot].clip = clip;
		self.weapon[weaponslot].reserve = reserve;
		self.weapon[weaponslot].maxammo = clip + reserve;
	}
}

//------------------------------------------------------------------------------
// Off-hand weapons: frag slot
//------------------------------------------------------------------------------
activateOffhandFragWeapon(index, weaponfile)
{
	self endon("kill_thread");

	// release other off-hand (frag slot) perk weapons
	releasePerkWeaponOfType(1);

	// save current frag nades
	if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges) currentnades = self getammocount(self.pers["fragtype"]);
		else currentnades = self getammocount(self.pers["fragtype"]) + self getammocount(self.pers["enemy_fragtype"]);
	if(!isDefined(currentnades)) currentnades = 0;

	// remove all regular frag nades
	self takeWeapon(self.pers["fragtype"]);
	self takeWeapon(self.pers["enemy_fragtype"]);

	// give off-hand weapon perk
	self giveWeapon(weaponfile);

	// set ammo
	clip = self extreme\_ex_weapons::getWeaponSlotClipAmmoDefault(weaponfile);
	if(!isDefined(clip) || !clip) clip = self giveStartAmmo(weaponfile);
	self setWeaponClipAmmo(weaponfile, clip);

	// switch to off-hand weapon
	self switchToOffhand(weaponfile);

	while(isAlive(self))
	{
		wait( [[level.ex_fpstime]](1) );

		// keep removing regular nades until perk is gone, unless we're in the
		// process of throwing back a nade
		if(!isDefined(self.ex_throwback))
		{
			self takeWeapon(self.pers["fragtype"]);
			self takeWeapon(self.pers["enemy_fragtype"]);
		}

		weaponcount = self getAmmoCount(weaponfile);
		if(!weaponcount) break;
	}

	// remove weapon perk
	self takeWeapon(weaponfile);

	// if enabled, give back frag grenades
	if(maps\mp\gametypes\_weapons::getWeaponStatus("fraggrenade"))
	{
		self giveWeapon(self.pers["fragtype"]);
		self setWeaponClipAmmo(self.pers["fragtype"], currentnades);
	}

	self notify("kill_keep" + index);
	playerStopUsingPerk(index, false);
	playerUnlockPerk(index);
}

//------------------------------------------------------------------------------
// Off-hand weapons: smoke slot
//------------------------------------------------------------------------------
activateOffhandSmokeWeapon(index, weaponfile)
{
	self endon("kill_thread");

	// release other off-hand (smoke slot) perk weapons
	releasePerkWeaponOfType(2);

	// save current smoke nades
	currentnades = self getammocount(self.pers["smoketype"]) + self getammocount(self.pers["enemy_smoketype"]);
	if(!isDefined(currentnades)) currentnades = 0;

	// remove all regular frag nades
	self takeWeapon(self.pers["smoketype"]);
	self takeWeapon(self.pers["enemy_smoketype"]);

	// give off-hand weapon perk
	self giveWeapon(weaponfile);

	// set ammo
	clip = self extreme\_ex_weapons::getWeaponSlotClipAmmoDefault(weaponfile);
	if(!isDefined(clip) || !clip) clip = self giveStartAmmo(weaponfile);
	self setWeaponClipAmmo(weaponfile, clip);

	// switch to off-hand weapon
	self switchToOffhand(weaponfile);

	while(isAlive(self))
	{
		wait( [[level.ex_fpstime]](1) );

		// keep removing regular nades until perk is gone, unless we're in the
		// process of throwing back a nade
		if(!isDefined(self.ex_throwback))
		{
			self takeWeapon(self.pers["smoketype"]);
			self takeWeapon(self.pers["enemy_smoketype"]);
		}

		weaponcount = self getAmmoCount(weaponfile);
		if(!weaponcount) break;
	}

	// remove weapon perk
	self takeWeapon(weaponfile);

	// if enabled, give back smoke grenades
	if(maps\mp\gametypes\_weapons::getWeaponStatus("smokegrenade"))
	{
		self giveWeapon(self.pers["smoketype"]);
		self setWeaponClipAmmo(self.pers["smoketype"], currentnades);
	}

	self notify("kill_keep" + index);
	playerStopUsingPerk(index, false);
	playerUnlockPerk(index);
}

//------------------------------------------------------------------------------
// Shared code
//------------------------------------------------------------------------------
isPerkWeaponInSlot(weaponslot)
{
	weaponfile = self getWeaponSlotWeapon(weaponslot);
	if(extreme\_ex_weapons::isWeaponType(weaponfile, "perkweapon")) return(true);
	return(false);
}

isSidearmInSlot(weaponslot)
{
	weaponfile = self getWeaponSlotWeapon(weaponslot);
	if(extreme\_ex_weapons::isWeaponType(weaponfile, "sidearm")) return(true);
	return(false);
}

releasePerkWeaponOfType(weapontype)
{
	for(i = 1; i < game["perkcatalog"].size; i++)
	{
		if(isDefined(game["perkcatalog"][i]["weapontype"]) && game["perkcatalog"][i]["weapontype"] == weapontype)
		{
			weaponfile = game["perkcatalog"][i]["weaponfile"];
			//logprint("SPC: [debug] Checking weapon " + weaponfile + "\n");
			if(self hasWeapon(weaponfile))
			{
				//logprint("SPC: [debug] Releasing weapon " + weaponfile + "\n");
				self notify("kill_keep" + i);
				playerStopUsingPerk(i, false);
				playerUnlockPerk(i);
				return;
			}
			//else logprint("SPC: [debug] Player does not have weapon " + weaponfile + "\n");
		}
	}
}

//------------------------------------------------------------------------------
// Localized strings
//------------------------------------------------------------------------------
getLocString(weaponfile)
{
	switch(weaponfile)
	{
		case "raygun_mp": return(&"WEAPON_RAYGUN");
		case "carcano_mp": return(&"WEAPON_CARCANO");
		case "chainsaw_mp": return(&"WEAPON_CHAINSAW");
		case "potato_mp": return(&"WEAPON_POTATO");
		case "rpg_mp": return(&"WEAPON_RPG");

		default: {
			logprint("SPC: Weapon \"" + weaponfile + "\" needs a localized string\n");
			logprint("SPC: Edit extreme/_ex_specials_weapon::getLocString function\n");
			return(&"WEAPON_UNKNOWNWEAPON");
		}
	}
}
