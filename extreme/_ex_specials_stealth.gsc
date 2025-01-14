#include extreme\_ex_specials;

perkInit(index)
{
	// perk related precaching
	if(level.ex_stealth_knife) [[level.ex_PrecacheItem]]("stealth_mp");

	[[level.ex_PrecacheModel]]("xmodel/playerbody_stealth");
	[[level.ex_PrecacheModel]]("xmodel/playerhead_stealth");
	[[level.ex_PrecacheModel]]("xmodel/viewmodel_hands_stealth");
}

perkInitPost(index)
{
	// perk related precaching after map load
}

perkCheck(index)
{
	// checks before being able to buy this perk
	if( (level.ex_gunship && isPlayer(level.gunship.owner) && level.gunship.owner == self) ||
	    (level.ex_gunship_special && isPlayer(level.gunship_special.owner) && level.gunship_special.owner == self) ) return(false);
	if(playerPerkIsLocked("vest", false)) return(false);
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
		else self iprintlnbold(&"SPECIALS_STEALTH_READY");

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

	if(level.ex_stealth_auto) extreme\_ex_main_utils::forceto("crouch");
	if(level.ex_stealth_hint) self iprintlnbold(&"SPECIALS_STEALTH_HINT");

	stance = -1;
	stance_old = stance;
	stance_new = stance;
	stance_trigger = 0;

	timer = 0;
	while(timer < level.ex_stealth_timer)
	{
		wait( [[level.ex_fpstime]](0.1) );
		stance = self.ex_stance;

		// detect weapon pick up
		weapon = self getWeaponSlotWeapon("primaryb");
		if(isDefined(self.ex_stealth) && weapon != "none")
		{
			self takeAllWeapons();
			self iprintlnbold(&"SPECIALS_STEALTH_NOWEAPON");

			if(level.ex_stealth_knife)
			{
				// remove the dropped stealth weapon from the map
				entities = getentarray("weapon_stealth_mp", "classname");
				for(i = 0; i < entities.size; i++) entities[i] delete();

				self setWeaponSlotWeapon("primary", "stealth_mp");
				self setWeaponSlotAmmo("primary", 0); // no ammo so bashing only
				self setWeaponSlotClipAmmo("primary", 0);
				self switchToWeapon("stealth_mp");
			}
		}

		if(stance_trigger)
		{
			if(stance_trigger < level.ex_stealth_switch)
			{
				if(stance == stance_new) stance_trigger++;
					else stance_trigger = 0;
			}
			else
			{
				if(stance_new == 0) // standing
				{
					if(isDefined(self.ex_stealth)) stealthStop();
				}
				else if(!isDefined(self.ex_stealth)) stealthStart();
				stance_old = stance_new;
				stance_trigger = 0;
			}
		}
		else if(stance != stance_old)
		{
			stance_new = stance;
			stance_trigger++;
		}

		if(!level.ex_stealth_pause || isDefined(self.ex_stealth)) timer += .1;
	}

	stealthStop();
	self notify("kill_keep" + index);
	playerStopUsingPerk(index, false);
	playerUnlockPerk(index);
}

stealthStart()
{
	self endon("kill_thread");

	// can't activate stealth while in gunship
	if( (level.ex_gunship && isPlayer(level.gunship.owner) && level.gunship.owner == self) ||
	    (level.ex_gunship_special && isPlayer(level.gunship_special.owner) && level.gunship_special.owner == self) ) return;

	if(level.ex_stealth_hint) self iprintln(&"SPECIALS_STEALTH_ACTIVATED");

	// do not allow player in stealth mode to carry flag
	if(level.ex_flagbased && isDefined(self.flag))
	{
		thread extreme\_ex_main_utils::dropTheFlag(true);
		self iprintlnbold(&"SPECIALS_STEALTH_NOFLAG");
	}

	self playsound("stealth_toggle");
	self detachAll();
	self setModel("xmodel/playerbody_stealth");
	self attach("xmodel/playerhead_stealth", "", true);
	self setViewmodel("xmodel/viewmodel_hands_stealth");

	if(level.ex_stealth_knife)
	{
		extreme\_ex_weapons::stopWeaponChangeMonitor();
		self takeAllWeapons();
		self setWeaponSlotWeapon("primary", "stealth_mp");
		self setWeaponSlotAmmo("primary", 0); // no ammo so bashing only
		self setWeaponSlotClipAmmo("primary", 0);
		self switchToWeapon("stealth_mp");
	}
	else self [[level.ex_dWeapon]]();

	self.ex_spinemarker playloopsound("stealth_loop");
	self.ex_stealth = true;
}

stealthStop()
{
	self endon("kill_thread");

	self.ex_spinemarker stoploopsound();
	self playsound("stealth_toggle");
	if(level.ex_stealth_hint) self iprintln(&"SPECIALS_STEALTH_DEACTIVATED");

	if(!isDefined(self.pers["savedmodel"])) self extreme\_ex_main_models::getModel();
		else self extreme\_ex_main_models::loadModel(self.pers["savedmodel"]);

	if(level.ex_stealth_knife) extreme\_ex_weapons::startWeaponChangeMonitor(true, false);
		else self [[level.ex_eWeapon]]();

	self.ex_stealth = undefined;
}
