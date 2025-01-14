#include extreme\_ex_specials;

perkInit(index)
{
	// NOP
}

perkInitPost(index)
{
	// perk related precaching after map load
	level.ex_supernade_allies = "supernade_" + game["allies"] + "_mp";
	[[level.ex_PrecacheItem]](level.ex_supernade_allies);

	level.ex_supernade_axis = "supernade_german_mp";
	[[level.ex_PrecacheItem]](level.ex_supernade_axis);

	// device registration
	[[level.ex_devRequest]]("supernade_" + game["allies"]);
	[[level.ex_devRequest]]("supernade_" + game["axis"]);
}

perkCheck(index)
{
	// checks before being able to buy this perk
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
		else self iprintlnbold(&"SPECIALS_SUPERNADE_READY");

	self thread hudNotifySpecial(index, 5);
	if(level.ex_store_keeptimer) thread perkKeepMonitor(index);
		else self thread playerStartUsingPerk(index, false);

	self thread perkThink(index);
}

perkKeepMonitor(index)
{
	self endon("kill_monitor" + index);

	self thread perkKeepStopper(index);

	keep = spawnstruct();
	keep.timer = level.ex_store_keeptimer;
	self thread perkKeepTimer(index, keep);

	self waittill("kill_thread");

	if(keep.timer == 0)
	{
		waittillframeend;
		if(isDefined(self)) self thread playerStartUsingPerk(index, false);
	}
}

perkKeepStopper(index)
{
	self endon("kill_thread");
	self endon("kill_stopper" + index);

	self waittill("kill_keep" + index);

	self notify("kill_monitor" + index);
	self notify("kill_timer" + index);
	self thread playerStartUsingPerk(index, false);
}

perkKeepTimer(index, keep)
{
	self endon("kill_thread");
	self endon("kill_timer" + index);

	while(keep.timer > 0)
	{
		wait( [[level.ex_fpstime]](1) );
		keep.timer--;
	}

	self notify("kill_monitor" + index);
	self notify("kill_stopper" + index);
	self thread playerStartUsingPerk(index, false);
}

perkThink(index)
{
	self endon("kill_thread");

	// save current frag nades
	if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges) currentnades = self getammocount(self.pers["fragtype"]);
		else currentnades = self getammocount(self.pers["fragtype"]) + self getammocount(self.pers["enemy_fragtype"]);
	if(!isDefined(currentnades)) currentnades = 0;

	// remove all regular frag nades
	self takeWeapon(self.pers["fragtype"]);
	self takeWeapon(self.pers["enemy_fragtype"]);

	// give supernade(s)
	if(self.pers["team"] == "allies") weaponfile = level.ex_supernade_allies;
		else weaponfile = level.ex_supernade_axis;
	self giveWeapon(weaponfile);

	// set ammo
	self setWeaponClipAmmo(weaponfile, level.ex_supernade);

	// switch to off-hand weapon
	self switchToOffhand(weaponfile);

	while(isAlive(self))
	{
		wait( [[level.ex_fpstime]](1) );

		// keep removing regular nades until supernade is gone, unless we're in the
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
