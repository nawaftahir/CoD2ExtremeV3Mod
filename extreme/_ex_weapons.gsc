#include extreme\_ex_player_sprint;
#include extreme\_ex_controller_hud;
#include maps\mp\gametypes\_weapons;

loadout()
{
	// create weapon array
	self setWeaponArray();

	// weapon checks, if weapon is "ignore" or the weapon is undefined, set to "none"
	if(!isDefined(self.pers["weapon"]) || self.pers["weapon"] == "ignore") self.pers["weapon"] = "none";
	if(level.ex_wepo_secondary)
	{
		if(!isDefined(self.pers["weapon1"]) || self.pers["weapon1"] == "ignore") self.pers["weapon1"] = "none";
		if(!isDefined(self.pers["weapon2"]) || self.pers["weapon2"] == "ignore") self.pers["weapon2"] = "none";

		self setWeaponSlotWeapon("primary", self.pers["weapon1"]);
		self setWeaponSlotWeapon("primaryb", self.pers["weapon2"]);
		self setSpawnWeapon(self.pers["weapon1"]);

		// the sidearm is handled in setSpawnWeapons later on
	}
	else
	{
		self setWeaponSlotWeapon("primary", self.pers["weapon"]);
		self setWeaponSlotWeapon("primaryb", "none");
		self setSpawnWeapon(self.pers["weapon"]);

		// if allowed, give them a sidearm
		if(level.ex_wepo_sidearm && !isDefined(self.pers["isbot"])) self giveSidearm();
	}


	// set the ammo for the weapons
	self setAmmo("primary", false, true);
	self setAmmo("primaryb", false, true);

	// give landmines if allowed
	if(level.ex_landmines) self extreme\_ex_weapons_mines::giveLandmines();

	// give first aid kits if allowed
	if(level.ex_medicsystem) self giveFirstAid();

	// give grenades if allowed
	self giveGrenades(false);

	// give binoculars
	if(!isDefined(self.pers["isbot"])) self giveWeapon("binoculars_mp");

	// mbot loadout
	if(level.ex_mbot && isDefined(self.pers["isbot"])) self extreme\_ex_main_bots::botLoadout();

	// set up the spawning weapons
	self setSpawnWeapons();

	// for bash mode they can't have any weapons
	if(level.ex_bash_only)
	{
		self setWeaponSlotAmmo("primary", 0);
		self setWeaponSlotClipAmmo("primary", 0);
		self setWeaponSlotAmmo("primaryb", 0);
		self setWeaponSlotClipAmmo("primaryb", 0);
	}

	// bots stop here
	if(isDefined(self.pers["isbot"])) return;

	// start weapon monitor
	self thread weaponChangeMonitor();
}

setAmmo(slot, gts, spawning)
{
	self endon("disconnect");

	// if not spawning, default false
	if(!isDefined(spawning)) spawning = false;

	// if not gametype start delay, default false
	if(!isDefined(gts)) gts = false;

	weapon = self getWeaponSlotWeapon(slot);
	if(!isWeaponType(weapon, "valid")) return;

	clip = self getWeaponSlotClipAmmoDefault(weapon);
	if(!isDefined(clip) || !clip) clip = self getWeaponSlotClipAmmo(slot);

	reserve = self getWeaponSlotAmmoDefault(weapon);
	if(!isDefined(reserve) || reserve < 0) reserve = self getWeaponSlotAmmo(slot);

	// rank system reserve ammo override
	if(level.ex_wepo_loadout == 1)
	{
		if(isWeaponType(weapon, "pistol")) rank_suffix = game["rank_ammo_pistolclips_" + self.pers["rank"]];
			else rank_suffix = game["rank_ammo_gunclips_" + self.pers["rank"]];

		reserve = clip * rank_suffix;
	}

	if(spawning)
	{
		// do nothing
	}
	else if(!gts)
	{
		// compare the ammo the weapon already has, if its greater, just fill the clip!
		reserve_check = self getWeaponSlotAmmo(slot);
		if(reserve_check > reserve) reserve = reserve_check;
	}

	self setWeaponSlotAmmo(slot, reserve);
	self setWeaponSlotClipAmmo(slot, clip);
}

setWeaponArray()
{
	// create the arrays
	if(!isDefined(self.weapon)) self.weapon = [];
	if(!isDefined(self.weaponin)) self.weaponin = [];

	// clear weapon primary
	if(!isDefined(self.weapon["primary"])) self.weapon["primary"] = spawnstruct();
	self.weapon["primary"].name = "none";
	self.weapon["primary"].clip = 0;
	self.weapon["primary"].reserve = 0;
	self.weapon["primary"].maxammo = 0;

	// clear weapon primaryb
	if(!isDefined(self.weapon["primaryb"])) self.weapon["primaryb"] = spawnstruct();
	self.weapon["primaryb"].name = "none";
	self.weapon["primaryb"].clip = 0;
	self.weapon["primaryb"].reserve = 0;
	self.weapon["primaryb"].maxammo = 0;

	// clear weapon virtual
	if(!isDefined(self.weapon["virtual"])) self.weapon["virtual"] = spawnstruct();
	self.weapon["virtual"].name = "none";
	self.weapon["virtual"].clip = 0;
	self.weapon["virtual"].reserve = 0;
	self.weapon["virtual"].maxammo = 0;

	// clear current weapon and weaponin slots
	self.weapon["current"] = "none";
	self.weaponin["primary"] = "primary";
	self.weaponin["primaryb"] = "primaryb";

	// clear saved weapon primary
	if(!isDefined(self.weapon["primary_saved"])) self.weapon["primary_saved"] = spawnstruct();
	self.weapon["primary_saved"].name = "none";
	self.weapon["primary_saved"].clip = 0;
	self.weapon["primary_saved"].reserve = 0;

	// clear saved weapon primaryb
	if(!isDefined(self.weapon["primaryb_saved"])) self.weapon["primaryb_saved"] = spawnstruct();
	self.weapon["primaryb_saved"].name = "none";
	self.weapon["primaryb_saved"].clip = 0;
	self.weapon["primaryb_saved"].reserve = 0;

	// slots to save current weapon
	if(!isDefined(self.weapon["current_saved"])) self.weapon["current_saved"] = spawnstruct();
	self.weapon["current_saved"].name = "none";
	self.weapon["current_saved"].slot = "none";

	// slots to save nade count
	self.weapon["frags_saved"] = 0;
	self.weapon["smoke_saved"] = 0;
}

setSpawnWeapons()
{
	self endon("kill_thread");

	// save primary
	primary = self getWeaponSlotWeapon("primary");

	if(isDefined(primary) && primary != "none")
	{
		self.weapon["primary"].name = primary;
		self.weapon["primary"].clip = self getWeaponSlotClipAmmo("primary");
		self.weapon["primary"].reserve = self getWeaponSlotAmmo("primary");
		self.weapon["primary"].maxammo = self.weapon["primary"].clip + self.weapon["primary"].reserve;
	}
	else
	{
		self.weapon["primary"].name = "none";
		self.weapon["primary"].clip = 0;
		self.weapon["primary"].reserve= 0;
		self.weapon["primary"].maxammo = 0;
	}		

	// save secondary
	primaryb = self getWeaponSlotWeapon("primaryb");

	if(isDefined(primaryb) && primaryb != "none")
	{
		self.weapon["primaryb"].name = primaryb;
		self.weapon["primaryb"].clip = self getWeaponSlotClipAmmo("primaryb");
		self.weapon["primaryb"].reserve = self getWeaponSlotAmmo("primaryb");
		self.weapon["primaryb"].maxammo = self.weapon["primaryb"].clip + self.weapon["primaryb"].reserve;
	}
	else
	{
		self.weapon["primaryb"].name = "none";
		self.weapon["primaryb"].clip = 0;
		self.weapon["primaryb"].reserve= 0;
		self.weapon["primaryb"].maxammo = 0;
	}

	// save current
	self.weapon["current"] = self.weapon["primary"].name;

	// if using secondary weapons with pistols, give them a pistol
	if(level.ex_wepo_secondary && level.ex_wepo_sidearm && !isDefined(self.pers["isbot"]))
	{
		self setWeaponSlotWeapon("primaryb", "none");
		self giveSidearm();

		// save pistol
		self.weapon["virtual"].name = self getWeaponSlotWeapon("primaryb");
		self.weapon["virtual"].clip = self getWeaponSlotClipAmmo("primaryb");
		self.weapon["virtual"].reserve = self getWeaponSlotAmmo("primaryb");
		self.weapon["virtual"].maxammo = self.weapon["virtual"].clip + self.weapon["virtual"].reserve;

		// put the original secondary to the primaryb slot
		if(self.weapon["primaryb"].name != "none")
		{
			self setWeaponSlotWeapon("primaryb", self.weapon["primaryb"].name);
			self setWeaponSlotAmmo("primaryb", self.weapon["primaryb"].reserve);
			self setWeaponSlotClipAmmo("primaryb", self.weapon["primaryb"].clip);
		}
	}
	else
	{
		self.weapon["virtual"].name = "none";
		self.weapon["virtual"].clip = 0;
		self.weapon["virtual"].reserve = 0;
		self.weapon["virtual"].maxammo = 0;
	}

	// set virtual slot pointers
	self.weaponin["primary"] = "primary";
	self.weaponin["primaryb"] = "primaryb";

	// set sidearm if giveSidearm was skipped (bots)
	if(!isDefined(self.pers["sidearm"])) self.pers["sidearm"] = "none";

	// save primary backup
	self.weapon["primary_saved"].name = self.weapon["primary"].name;
	self.weapon["primary_saved"].clip = self.weapon["primary"].clip;
	self.weapon["primary_saved"].reserve = self.weapon["primary"].reserve;

	// save secondary backup
	self.weapon["primaryb_saved"].name = self.weapon["primaryb"].name;
	self.weapon["primaryb_saved"].clip = self.weapon["primaryb"].clip;
	self.weapon["primaryb_saved"].reserve = self.weapon["primaryb"].reserve;

	// save current backup
	self.weapon["current_saved"].name = self.weapon["primary"].name;
	self.weapon["current_saved"].slot = "primary";

	if(level.ex_log_weapons) weaponsLog(true, "setSpawnWeapons() completed");
}

stopWeaponChangeMonitor()
{
	self endon("kill_thread");

	if(self.ex_wepmon_paused) return;
	self.ex_wepmon_pause = true;
	while(isPlayer(self) && !self.ex_wepmon_paused) wait( level.ex_fps_frame );
	saveWeapons(true);
}

startWeaponChangeMonitor(nades, refill)
{
	self endon("kill_thread");

	if(self.ex_wepmon_paused) restoreWeapons(nades, refill);
	self.ex_wepmon_pause = false;
	while(isPlayer(self) && self.ex_wepmon_paused) wait( level.ex_fps_frame );
}

weaponChangeMonitor()
{
	self endon("kill_thread");

	while(isAlive(self))
	{
		while(isPlayer(self) && self.ex_wepmon_pause) wait( level.ex_fps_frame );
		if(level.ex_log_weapons) weaponsLog(true, "weaponChangeMonitor() started");
		self.ex_wepmon_paused = false;

		while(isPlayer(self) && !self.ex_wepmon_pause)
		{
			wait( level.ex_fps_frame );

			// get current
			current = self getCurrentWeapon();
			if(current == game["sprint"] || current == self.weapon["current"]) continue;

			// process primary
			primary = self getWeaponSlotWeapon("primary");
			if(isWeaponType(primary, "weapon"))
			{
				// is primary weapon in the virtual slot we expect it to be?
				if(primary != self.weapon[self.weaponin["primary"]].name)
				{
					vslot = self.weaponin["primary"];
					if(primary == self.weapon["primary"].name) vslot = "primary";
						else if(primary == self.weapon["primaryb"].name) vslot = "primaryb";
							else if(primary == self.weapon["virtual"].name) vslot = "virtual";

					self slotWeaponCheck("primary", vslot);
				}
				else
				{
					self.weapon[self.weaponin["primary"]].clip = self getWeaponSlotClipAmmo("primary");
					self.weapon[self.weaponin["primary"]].reserve = self getWeaponSlotAmmo("primary");
				}
			}

			// process primaryb
			primaryb = self getWeaponSlotWeapon("primaryb");
			if(isWeaponType(primaryb, "weapon"))
			{
				// is secondary weapon in the virtual slot we expect it to be?
				if(primaryb != self.weapon[self.weaponin["primaryb"]].name)
				{
					vslot = self.weaponin["primaryb"];
					if(primaryb == self.weapon["primary"].name) vslot = "primary";
						else if(primaryb == self.weapon["primaryb"].name) vslot = "primaryb";
							else if(primaryb == self.weapon["virtual"].name) vslot = "virtual";

					self slotWeaponCheck("primaryb", vslot);
				}
				else
				{
					self.weapon[self.weaponin["primaryb"]].clip = self getWeaponSlotClipAmmo("primaryb");
					self.weapon[self.weaponin["primaryb"]].reserve = self getWeaponSlotAmmo("primaryb");
				}
			}

			// if secondary weapons with sidearm, check if we need to switch the weapons around in
			// non-current slot (this creates the illusion of having more than 2 slots)
			if(isWeaponType(current, "weapon"))
			{
				if(level.ex_wepo_secondary && level.ex_wepo_sidearm && self.weapon["current"] != "none" && current != "none")
				{
					if(self.weapon["primary"].name == self.weapon["current"])
					{
						if(self.weapon["primaryb"].name == current)
						{
							if(self.weapon["primary"].name == primary && self.weapon["primaryb"].name == primaryb) self changeWeaponInSlot("primary", "virtual");
								else if(self.weapon["primary"].name == primaryb && self.weapon["primaryb"].name == primary) self changeWeaponInSlot("primaryb", "virtual");
						}
					}
					else if(self.weapon["primaryb"].name == self.weapon["current"])
					{
						if(self.weapon["virtual"].name == current)
						{
							if(self.weapon["primaryb"].name == primaryb && self.weapon["virtual"].name == primary) self changeWeaponInSlot("primaryb", "primary");
								else if(self.weapon["primaryb"].name == primary && self.weapon["virtual"].name == primaryb) self changeWeaponInSlot("primary", "primary");
						}
					}
					else if(self.weapon["virtual"].name == self.weapon["current"])
					{
						if(self.weapon["primary"].name == current)
						{
							if(self.weapon["virtual"].name == primary && self.weapon["primary"].name == primaryb) self changeWeaponInSlot("primary", "primaryb");
								else if(self.weapon["virtual"].name == primaryb && self.weapon["primary"].name == primary) self changeWeaponInSlot("primaryb", "primaryb");
						}
					}
				}

				self.weapon["current"] = self getCurrentWeapon();
			}
		}

		if(level.ex_log_weapons) weaponsLog(false, "weaponChangeMonitor() suspended");
		self.ex_wepmon_paused = true;
	}

	if(level.ex_log_weapons) weaponsLog(false, "weaponChangeMonitor() terminated");
}

changeWeaponInSlot(slot, vslot)
{
	// "none" weapon cannot be switched so return
	if(self.weapon[vslot].name == "none") return;

	if(level.ex_log_weapons) weaponsLog(false, "switchWeapons > changeWeaponInSlot() swapping " + self getWeaponSlotWeapon(slot) + " with " + self.weapon[vslot].name);

	// update virtual slot pointer
	self.weaponin[slot] = vslot;

	self setWeaponSlotWeapon(slot, self.weapon[vslot].name);
	self setWeaponSlotClipAmmo(slot, self.weapon[vslot].clip);
	self setWeaponSlotAmmo(slot, self.weapon[vslot].reserve);

	if(level.ex_log_weapons) weaponsLog(false, "switchWeapons > changeWeaponInSlot(" + slot + ", self.weapon[" + vslot + "].name) completed");
}

slotWeaponCheck(slot, vslot)
{
	self endon("kill_thread");

	if(level.ex_log_weapons) weaponsLog(false, "slotWeaponCheck(" + slot + ", " + vslot + ") called");

	weapon = self getWeaponSlotWeapon(slot);
	if(!isWeaponType(weapon, "weapon")) return;

	// update virtual slot pointer
	self.weaponin[slot] = vslot;

	// did player drop weapon?
	if(weapon == "none")
	{
		if(level.ex_log_weapons) weaponsLog(false, "slotWeaponCheck() detected weapon drop");
		self saveNewSlot(slot, vslot);
		return;
	}
	// check if no secondary weapon or sidearm allowed in primaryb
	else if(!level.ex_wepo_secondary && !level.ex_wepo_sidearm && slot == "primaryb")
	{
		// the knife perk will add the knife as primaryb, so allow that to happen
		if((level.ex_store & 2) != 2 || !level.ex_specials_knife || !extreme\_ex_specials::playerPerkIsLocked("knife", false))
		{
			if(level.ex_log_weapons) weaponsLog(true, "slotWeaponCheck() detected illegal secondary weapon");

			// move illegal primaryb to primary
			self dropItem(self getWeaponSlotWeapon("primary"));
			clip = self getWeaponSlotClipAmmo("primaryb");
			reserve = self getWeaponSlotAmmo("primaryb");
			primaryb = self getWeaponSlotWeapon("primaryb");
			self takeWeapon(primaryb);
			self setWeaponSlotWeapon("primary", primaryb);
			self setWeaponSlotClipAmmo("primary", clip);
			self setWeaponSlotAmmo("primary", reserve);
			self setWeaponSlotWeapon("primaryb", "none");
			return;
		}
	}

	// did player just drop a detached turret?
	if(level.ex_turrets > 1 && isDefined(self.turretid))
	{
		if(isWeaponType(self.weapon[slot].name, "mobilemg"))
		{
			if(level.ex_log_weapons) weaponsLog(true, "slotWeaponCheck() detected drop of unfixed turret");
			self thread extreme\_ex_weapons_turrets::turretRestore();
		}
	}

	if(level.ex_log_weapons) weaponsLog(false, "slotWeaponCheck() detected weapon pick-up (" + weapon + ")");

	// check if this weapon is a pistol, and is allowed to be exchanged
	enemyweapon_skip = false;
	if(level.ex_wepo_sidearm == 1 && weapon != self.pers["sidearm"])
	{
		if( (!level.ex_wepo_secondary && self.weaponin[slot] == "primaryb") || (level.ex_wepo_secondary && self.weaponin[slot] == "virtual") )
		{
			// the knife perk will change pistol to knife, so allow that to happen
			if((level.ex_store & 2) != 2 || !level.ex_specials_knife || !extreme\_ex_specials::playerPerkIsLocked("knife", false))
			{
				if(level.ex_log_weapons) weaponsLog(false, "slotWeaponCheck() detected illegal sidearm swap");

				// remove the original dropped weapon from the map first, so they can't get ammo from it
				entities = getentarray("weapon_" + self.pers["sidearm"], "classname");
				for(i = 0; i < entities.size; i++) if(distance(entities[i].origin, self.origin) < 200) entities[i] delete();

				self iprintlnbold(&"WEAPON_PISTOL_SWAP_NO_MSG1");
				self dropItem(self getWeaponSlotWeapon(slot));
				self setWeaponSlotWeapon(slot, self.pers["sidearm"]);
				self setWeaponSlotClipAmmo(slot, self.weapon[self.weaponin[slot]].clip);
				self setWeaponSlotAmmo(slot, self.weapon[self.weaponin[slot]].reserve);
			}
			enemyweapon_skip = true;
		}
	}

	if(!enemyweapon_skip && (level.ex_wepo_enemy == 0 || level.ex_wepo_enemy == 2))
	{
		// is this an enemy weapon?
		enemyweapon = false;
		if(!isWeaponType(weapon, self.pers["team"])) enemyweapon = true;

		// it is an enemy weapon, are we allowed to have it?
		if(enemyweapon)
		{
			enemyweapon_allowed = true;

			// enemy weapons are allowed only if you are low on ammo
			if(level.ex_wepo_enemy == 2)
			{
				// this is an enemy weapon and is only allowed if last weapon was low on ammo
				oldammo = self.weapon[self.weaponin[slot]].clip + self.weapon[self.weaponin[slot]].reserve;
				lowammo = int( (self.weapon[self.weaponin[slot]].maxammo / 100) * level.ex_wepo_enemy_pct);
				if(oldammo > lowammo)
				{
					enemyweapon_allowed = false;
					if(level.ex_log_weapons) weaponsLog(false, "slotWeaponCheck() rejected enemy weapon (" + weapon + " ; " + oldammo + " [" + self.weapon[self.weaponin[slot]].clip + "+" + self.weapon[self.weaponin[slot]].reserve + "] > " + lowammo + ")");
				}
				else if(level.ex_log_weapons) weaponsLog(false, "slotWeaponCheck() accepted enemy weapon (" + weapon + " ; " + oldammo + " [" + self.weapon[self.weaponin[slot]].clip + "+" + self.weapon[self.weaponin[slot]].reserve + "] <= " + lowammo + ")");
			}
			else if(!level.ex_wepo_enemy)
			{
				enemyweapon_allowed = false;
				if(level.ex_log_weapons) weaponsLog(false, "slotWeaponCheck() enemy weapon rejected (" + weapon + ")");
			}

			if(!enemyweapon_allowed)
			{
				// remove the original dropped weapon from the map first, so they can't get ammo from it
				entities = getentarray("weapon_" + self.weapon[self.weaponin[slot]].name, "classname");
				for(i = 0; i < entities.size; i++)
				{
					entity = entities[i];
					if(distance(entity.origin, self.origin) < 200) entities[i] delete();
				}

				if(level.ex_wepo_enemy == 2) self iprintlnbold(&"EWEAPON_AMMO_MSG0");
					else self iprintlnbold(&"EWEAPON_DISABLED");
				self dropItem(self getWeaponSlotWeapon(slot));
				self setWeaponSlotWeapon(slot, self.weapon[self.weaponin[slot]].name);
				self setWeaponSlotClipAmmo(slot, self.weapon[self.weaponin[slot]].clip);
				self setWeaponSlotAmmo(slot, self.weapon[self.weaponin[slot]].reserve);
			}
		}
	}

	self saveNewSlot(slot, self.weaponin[slot]);
}

saveNewSlot(slot, vslot)
{
	self endon("kill_thread");

	weapon = self getWeaponSlotWeapon(slot);
	is_dummy = isWeaponType(weapon, "dummy");

	if(is_dummy || weapon == "none")
	{
		// if the slot already contains a dummy weapon, then reuse it!
		if(!is_dummy) weapon = getDummy();

		// save the dummy to the weapon array
		self.weapon[vslot].name = weapon;
		self.weapon[vslot].clip = 0;
		self.weapon[vslot].reserve = 0;
		self.weapon[vslot].maxammo = 0;

		// set the empty slot to a dummy weapon if secondary weapons enabled with pistol
		self setWeaponSlotWeapon(slot, weapon);
		self setWeaponSlotClipAmmo(slot, 0);
		self setWeaponSlotAmmo(slot, 0);
	}
	else
	{
		// add new weapon to the weapon array
		self.weapon[vslot].name = weapon;
		self.weapon[vslot].clip = self getWeaponSlotClipAmmo(slot);
		self.weapon[vslot].reserve = self getWeaponSlotAmmo(slot);

		clip = self getWeaponSlotClipAmmoDefault(weapon);
		reserve = self getWeaponSlotAmmoDefault(weapon);
		if(isDefined(clip) && isDefined(reserve)) self.weapon[vslot].maxammo = clip + reserve;
			else self.weapon[vslot].maxammo = self.weapon[vslot].clip + self.weapon[vslot].reserve;
	}

	// switch to the new weapon and save as current
	self switchToWeapon(weapon);
	self.weapon["current"] = weapon;

	if(level.ex_log_weapons) weaponsLog(true, "saveNewSlot(" + slot + ", " + vslot + ") completed");
}

saveWeapons(nades)
{
	self endon("kill_thread");

	//if(level.ex_log_weapons) weaponsLog(false, "saveWeapons() called");

	// save current
	current = self getCurrentWeapon();
	self.weapon["current_saved"].name = current;

	// save primary
	primary = self getWeaponSlotWeapon("primary");
	if(isWeaponType(primary, "valid"))
	{
		self.weapon["primary_saved"].name = primary;
		self.weapon["primary_saved"].clip = self getWeaponSlotClipAmmo("primary");
		self.weapon["primary_saved"].reserve = self getWeaponSlotAmmo("primary");
		if(primary == current) self.weapon["current_saved"].slot = "primary";
	}
	else self.weapon["primary_saved"].name = "none";

	// save secondary
	primaryb = self getWeaponSlotWeapon("primaryb");
	if(isWeaponType(primaryb, "valid"))
	{
		self.weapon["primaryb_saved"].name = primaryb;
		self.weapon["primaryb_saved"].clip = self getWeaponSlotClipAmmo("primaryb");
		self.weapon["primaryb_saved"].reserve = self getWeaponSlotAmmo("primaryb");
		if(primaryb == current) self.weapon["current_saved"].slot = "primaryb";
	}
	else self.weapon["primaryb_saved"].name = "none";

	// save nades
	if(!isDefined(nades) || nades)
	{
		if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges) currentfrags = self getammocount(self.pers["fragtype"]);
			else currentfrags = self getammocount(self.pers["fragtype"]) + self getammocount(self.pers["enemy_fragtype"]);
		self.weapon["frags_saved"] = currentfrags;
		self.weapon["smoke_saved"] = self getammocount(self.pers["smoketype"]) + self getammocount(self.pers["enemy_smoketype"]);
	}

	if(level.ex_log_weapons) weaponsLog(true, "saveWeapons() completed");
}

restoreWeapons(nades, refill)
{
	self endon("kill_thread");

	//if(level.ex_log_weapons) weaponsLog(false, "restoreWeapons() called");

	// get saved current
	current = self.weapon["current_saved"].name;

	// restore primary
	self takeWeapon(self getWeaponSlotWeapon("primary"));
	if(isWeaponType(self.weapon["primary_saved"].name, "valid"))
	{
		self setWeaponSlotWeapon("primary", self.weapon["primary_saved"].name);
		if(refill) self setAmmo("primary", false);
		else
		{
			self setWeaponSlotClipAmmo("primary", self.weapon["primary_saved"].clip);
			self setWeaponSlotAmmo("primary", self.weapon["primary_saved"].reserve);
		}
		if(self.weapon["current_saved"].slot == "primary") current = self.weapon["primary_saved"].name;
	}
	else self setWeaponSlotWeapon("primary", "none");

	// restore secondary
	self takeWeapon(self getWeaponSlotWeapon("primaryb"));
	if(isWeaponType(self.weapon["primaryb_saved"].name, "valid"))
	{
		self setWeaponSlotWeapon("primaryb", self.weapon["primaryb_saved"].name);
		if(refill) self setAmmo("primaryb", false);
		else
		{
			self setWeaponSlotClipAmmo("primaryb", self.weapon["primaryb_saved"].clip);
			self setWeaponSlotAmmo("primaryb", self.weapon["primaryb_saved"].reserve);
		}
		if(self.weapon["current_saved"].slot == "primaryb") current = self.weapon["primaryb_saved"].name;
	}
	else self setWeaponSlotWeapon("primaryb", "none");

	if(refill) self refillWeapon("virtual", false);

	// restore current
	if(isWeaponType(current, "valid")) self switchToWeapon(current);

	// restore nades
	if(!isDefined(nades) || nades)
	{
		if(self.weapon["frags_saved"])
		{
			self giveWeapon(self.pers["fragtype"]);
			self setWeaponClipAmmo(self.pers["fragtype"], self.weapon["frags_saved"]);
		}
		if(self.weapon["smoke_saved"])
		{
			self giveWeapon(self.pers["smoketype"]);
			self setWeaponClipAmmo(self.pers["smoketype"], self.weapon["smoke_saved"]);
		}
	}

	if(level.ex_log_weapons) weaponsLog(true, "restoreWeapons() completed");
}

getDummy()
{
	self endon("disconnect");

	if(self.weapon["primary"].name != "dummy1_mp" && self.weapon["primaryb"].name != "dummy1_mp" && self.weapon["virtual"].name != "dummy1_mp") return("dummy1_mp");
		else if(self.weapon["primary"].name != "dummy2_mp" && self.weapon["primaryb"].name != "dummy2_mp" && self.weapon["virtual"].name != "dummy2_mp") return("dummy2_mp");
	return("dummy3_mp");
}

getWeaponSlot(weapon)
{
	if(weapon == self getweaponslotweapon("primary")) return("primary");
		else return("primaryb");
}

getCurrentSlot()
{
	primary = self getWeaponSlotWeapon("primary");
	if(self getCurrentWeapon() == primary || isWeaponType(primary, "mobilemg")) return("primary");
		else return("primaryb");
}

dropCurrentWeapon(mode)
{
	self endon("kill_thread");

	// do not drop weapons if bots enabled
	if(level.ex_weapondrop_override) return;

	if(isPlayer(self))
	{
		current = self getCurrentWeapon();
		if(!isWeaponType(current, "valid")) return;

		// mode 0: drop if allowed
		// mode 1: unconditional drop
		// mode 2: take weapon instead
		if(!isDefined(mode)) mode = 0;

		switch(mode)
		{
			case 0: self thread dropItemIfAllowed(current); break;
			case 1: self dropItem(current); break;
			default: self takeWeapon(current); break;
		}
	}
}

giveFirstAid()
{
	// set the default first aid kit value
	firstaidcount = level.ex_firstaid_kits;

	// check if random is on
	if(level.ex_firstaid_kits_random) firstaidcount = randomInt(level.ex_firstaid_kits);

	// check if ranksystem is on
	if(level.ex_ranksystem) firstaidcount = game["rank_firstaid_kits_" + self.pers["rank"]];

	// if all fails, give them at least one first aid kit
	if(!isDefined(firstaidcount)) firstaidcount = 1;

	// check if the player has more than whats on offer, if not set number of first aid kits for player
	if(!isDefined(self.ex_firstaidkits) || firstaidcount > self.ex_firstaidkits) self.ex_firstaidkits = firstaidcount;
	if(self.ex_firstaidkits) self.ex_canheal = true;
}

giveSidearm()
{
	weapon = self getWeaponSlotWeapon("primaryb");
	if(weapon != "none") return;

	sidearmtype = getSidearmType();
	self.pers["sidearm"] = sidearmtype;
	if(sidearmtype == "none") return;
	self setWeaponSlotWeapon("primaryb", sidearmtype);

	if(level.ex_wepo_loadout == 1)
	{
		// set primaryb
		clip = self getWeaponSlotClipAmmo("primaryb");
		ammo = clip * game["rank_ammo_pistolclips_" + self.pers["rank"]];
		self setWeaponSlotAmmo("primaryb", ammo);
	}
	else self setWeaponSlotAmmo("primaryb", self getWeaponSlotAmmoDefault(sidearmtype));
}

getSidearmType()
{
	self endon("disconnect");

	if(level.ex_currentgt == "ft" && level.ft_raygun) return("raygun_mp");

	if(level.ex_wepo_sidearm_type == 0)
	{
		sidearmtype = undefined;

		if(level.ex_modern_weapons)
		{
			if(self.pers["team"] == "allies")
			{
				switch(game["allies"])
				{
					case "american": sidearmtype = "deagle_mp"; break;
					case "british": sidearmtype = "beretta_mp"; break;
					default: sidearmtype = "glock_mp"; break;
				}
			}
			else sidearmtype = "hk45_mp";
		}
		else
		{
			if(self.pers["team"] == "allies")
			{
				switch(game["allies"])
				{
					case "american": sidearmtype = "colt_mp"; break;
					case "british": sidearmtype = "webley_mp"; break;
					default: sidearmtype = "tt30_mp"; break;
				}
			}
			else sidearmtype = "luger_mp";
		}
	}
	else
	{
		if(level.ex_modern_weapons) sidearmtype = "modern_knife_mp";
			else sidearmtype = "knife_mp";
	}

	// weapon limiter check
	if(level.ex_wepo_limiter)
	{
		if(isDefined(level.weapons[sidearmtype]))
		{
			if(level.ex_teamplay && level.ex_wepo_limiter_perteam)
			{
				if(self.pers["team"] == "allies")
				{
					if(isDefined(level.weapons[sidearmtype].allow_allies))
					{
						if(level.weapons[sidearmtype].allow_allies == 0) return("none");
							else return(sidearmtype);
					}
					else return("none");
				}
				else
				{
					if(isDefined(level.weapons[sidearmtype].allow_axis))
					{
						if(level.weapons[sidearmtype].allow_axis == 0) return("none");
							else return(sidearmtype);
					}
					else return("none");
				}
			}
			else
			{
				if(isDefined(level.weapons[sidearmtype].allow))
				{
					if(level.weapons[sidearmtype].allow == 0) return("none");
						else return(sidearmtype);
				}
				else return("none");
			}
		}
		else return("none");
	}
	else return(sidearmtype);
}

giveGrenades(rank_update, frags, smokes)
{
	self endon("disconnect");

	grenadetype_allies = getFragTypeAllies();
	grenadetype_axis = getFragTypeAxis();
	smokegrenadetype_allies = getSmokeTypeAllies();
	smokegrenadetype_axis = getSmokeTypeAxis();

	self takeWeapon(grenadetype_allies);
	self takeWeapon(grenadetype_axis);
	self takeWeapon(smokegrenadetype_allies);
	self takeWeapon(smokegrenadetype_axis);

	// set the grenade types
	if(self.pers["team"] == "allies")
	{
		self.pers["fragtype"] = grenadetype_allies;
		self.pers["smoketype"] = smokegrenadetype_allies;
		self.pers["enemy_fragtype"] = grenadetype_axis;
		self.pers["enemy_smoketype"] = smokegrenadetype_axis;
		if(level.ex_mbot && isDefined(self.pers["isbot"]))
		{
			self.botgrenade = "frag_grenade_" + game["allies"] + "_bot";
			self.botgrenadecount = 0;
			self.botsmoke = "smoke_grenade_" + game["allies"] + "_bot";
			self.botsmokecount = 0;
		}
	}
	else
	{
		self.pers["fragtype"] = grenadetype_axis;
		self.pers["smoketype"] = smokegrenadetype_axis;
		self.pers["enemy_fragtype"] = grenadetype_allies;
		self.pers["enemy_smoketype"] = smokegrenadetype_allies;
		if(level.ex_mbot && isDefined(self.pers["isbot"]))
		{
			self.botgrenade = "frag_grenade_german_bot";
			self.botgrenadecount = 0;
			self.botsmoke = "smoke_grenade_german_bot";
			self.botsmokecount = 0;
		}
	}

	// if entities monitor in defcon 2, do not give grenades
	if(level.ex_entities_defcon == 2) return;

	// check if account system grants access
	if(level.ex_accounts && self.pers["account"]["status"] == 1 && (level.ex_accounts_lock & 4) == 4) return;

	if(maps\mp\gametypes\_weapons::getWeaponStatus("fraggrenade"))
	{
		fraggrenadecount = 0;

		if(!rank_update)
		{
			switch(level.ex_frag_loadout)
			{
				case 1:	// eXtreme rank system settings
				fraggrenadecount = game["rank_ammo_grenades_" + self.pers["rank"]];
				break;

				case 2:	// eXtreme fixed settings
				fraggrenadecount = level.ex_wepo_frag;
				break;

				case 3: // eXtreme random settings
				fraggrenadecount = randomInt(level.ex_wepo_frag_random + 1);
				break;

				default: // eXtreme weapon class settings
				fraggrenadecount = getWeaponBasedGrenadeCount(self.pers["weapon"]);
				if(!fraggrenadecount && isDefined(self.pers["weapon2"]))
					fraggrenadecount = getWeaponBasedGrenadeCount(self.pers["weapon2"]);
				break;
			}
		}
		else fraggrenadecount = game["rank_ammo_grenades_" + self.pers["rank"]];

		// if all fails, give them 1 grenade
		if(!isDefined(fraggrenadecount)) fraggrenadecount = 1;

		// check how many nades they have already, if the new count is less, don't bother
		if(isDefined(frags) && frags > fraggrenadecount) fraggrenadecount = frags;

		if(fraggrenadecount)
		{
			if(level.ex_mbot && isDefined(self.pers["isbot"])) self.botgrenadecount = fraggrenadecount;
			self giveWeapon(self.pers["fragtype"]);
			self setWeaponClipAmmo(self.pers["fragtype"], fraggrenadecount);
		}
	}

	if(maps\mp\gametypes\_weapons::getWeaponStatus("smokegrenade"))
	{
		smokegrenadecount = 0;

		if(!rank_update)
		{
			switch(level.ex_smoke_loadout)
			{
				case 1:	// eXtreme rank system settings
				smokegrenadecount = game["rank_ammo_smoke_grenades_" + self.pers["rank"]];
				break;

				case 2: // eXtreme fixed settings
				smokegrenadecount = level.ex_wepo_smoke;
				break;

				case 3:	// eXtreme random settings
				smokegrenadecount = randomInt(level.ex_wepo_smoke_random + 1);
				break;

				default: // eXtreme weapon class settings
				smokegrenadecount = getWeaponBasedSmokeGrenadeCount(self.pers["weapon"]);
				if(!smokegrenadecount && isDefined(self.pers["weapon2"]))
					smokegrenadecount = getWeaponBasedSmokeGrenadeCount(self.pers["weapon2"]);
				break;
			}
		}
		else smokegrenadecount = game["rank_ammo_smoke_grenades_" + self.pers["rank"]];

		// if all fails, give them 1 grenade
		if(!isDefined(smokegrenadecount)) smokegrenadecount = 1;

		// check how many nades they have already, if the new count is less, don't bother
		if(isDefined(smokes) && smokes > smokegrenadecount) smokegrenadecount = smokes;

		if(smokegrenadecount)
		{
			if(level.ex_mbot && isDefined(self.pers["isbot"])) self.botsmokecount = smokegrenadecount;
			self giveWeapon(self.pers["smoketype"]);
			self setWeaponClipAmmo(self.pers["smoketype"], smokegrenadecount);
		}
	}
}

getFragTypeAllies()
{
	if(level.ex_firenades) fragtype = "fire_mp";
		else if(level.ex_gasnades) fragtype = "gas_mp";
			else if(level.ex_satchelcharges) fragtype = "satchel_mp";
				else fragtype = "frag_grenade_" + game["allies"] + "_mp";

	return(fragtype);
}

getFragTypeAxis()
{
	if(level.ex_firenades) fragtype = "fire_mp";
		else if(level.ex_gasnades) fragtype = "gas_mp";
			else if(level.ex_satchelcharges) fragtype = "satchel_mp";
				else fragtype = "frag_grenade_" + game["axis"] + "_mp";

	return(fragtype);
}

getSmokeTypeAllies()
{
	smoketype = "smoke_grenade_" + game["allies"] + getSmokeColour(level.ex_smoke[game["allies"]]) + "mp";
	return(smoketype);
}

getSmokeTypeAxis()
{
	smoketype = "smoke_grenade_" + game["axis"] + getSmokeColour(level.ex_smoke[game["axis"]]) + "mp";
	return(smoketype);
}

getSmokeColour(num)
{
	switch(num)
	{
		case 1: return("_blue_");
		case 2: return("_green_");
		case 3: return("_orange_");
		case 4: return("_pink_");
		case 5: return("_red_");
		case 6: return("_yellow_");
		case 7: return("_fire_");
		case 8: return("_gas_");
		case 9: return("_satchel_");
		case 0:
		default: return("_");
	}
}

getWeaponSlotAmmoDefault(weapon)
{
	if(level.ex_mbot && isDefined(self.pers["isbot"])) return(999);

	if(isDefined(weapon))
	{
		if(weapon == "none" || weapon == game["sprint"])
		{
			logPrint("WPN: getWeaponSlotAmmoDefault() for player " + self.name + ": invalid weapon >>> " + weapon + " <<<\n");
		}
		else
		{
			if(isDefined(level.weapons[weapon]))
			{
				if(isDefined(level.weapons[weapon].ammo_limit)) return(level.weapons[weapon].ammo_limit);
					else logPrint("WPN: getWeaponSlotAmmoDefault() for player " + self.name + ": ammo_limit not found >>> " + weapon + " <<<\n");
			}
			else logPrint("WPN: getWeaponSlotAmmoDefault() for player " + self.name + ": weapon not found >>> " + weapon + " <<<\n");
		}
	}

	return(0);
}

getWeaponSlotClipAmmoDefault(weapon)
{
	if(level.ex_mbot && isDefined(self.pers["isbot"])) return(999);

	if(isDefined(weapon))
	{
		if(weapon == "none" || weapon == game["sprint"])
		{
			logPrint("WPN: getWeaponSlotClipAmmoDefault() for player " + self.name + ": invalid weapon >>> " + weapon + " <<<\n");
		}
		else
		{
			if(isDefined(level.weapons[weapon]))
			{
				if(isDefined(level.weapons[weapon].clip_limit)) return(level.weapons[weapon].clip_limit);
					else logPrint("WPN: getWeaponSlotClipAmmoDefault() for player " + self.name + ": clip_limit not found >>> " + weapon + " <<<\n");
			}
			else logPrint("WPN: getWeaponSlotClipAmmoDefault() for player " + self.name + ": weapon not found >>> " + weapon + " <<<\n");
		}
	}

	return(0);
}

getWeaponBasedGrenadeCount(weapon)
{
	if(!isDefined(weapon) || !isWeaponType(weapon, "valid")) return(0);

	if(isWeaponType(weapon, "sniper")) return(level.ex_wepo_frag_stock_sniper);
	if(isWeaponType(weapon, "rifle")) return(level.ex_wepo_frag_stock_rifle);
	if(isWeaponType(weapon, "mg")) return(level.ex_wepo_frag_stock_mg);
	if(isWeaponType(weapon, "smg")) return(level.ex_wepo_frag_stock_smg);
	if(isWeaponType(weapon, "shotgun")) return(level.ex_wepo_frag_stock_shot);
	if(isWeaponType(weapon, "rl")) return(level.ex_wepo_frag_stock_rl);
	if(isWeaponType(weapon, "ft")) return(level.ex_wepo_frag_stock_ft);
	return(0);
}

getWeaponBasedSmokeGrenadeCount(weapon)
{
	if(!isDefined(weapon) || !isWeaponType(weapon, "valid")) return(0);

	if(isWeaponType(weapon, "sniper")) return(level.ex_wepo_smoke_stock_sniper);
	if(isWeaponType(weapon, "rifle")) return(level.ex_wepo_smoke_stock_rifle);
	if(isWeaponType(weapon, "mg")) return(level.ex_wepo_smoke_stock_mg);
	if(isWeaponType(weapon, "smg")) return(level.ex_wepo_smoke_stock_smg);
	if(isWeaponType(weapon, "shotgun")) return(level.ex_wepo_smoke_stock_shot);
	if(isWeaponType(weapon, "rl")) return(level.ex_wepo_smoke_stock_rl);
	if(isWeaponType(weapon, "ft")) return(level.ex_wepo_smoke_stock_ft);
	return(0);
}

hasWeaponType(type)
{
	weapon = self getWeaponSlotWeapon("primary");
	if(isWeaponType(weapon, type)) return(true);

	if(level.ex_wepo_secondary || level.ex_wepo_sidearm)
	{
		weapon = self getWeaponSlotWeapon("primaryb");
		if(isWeaponType(weapon, type)) return(true);

		if(level.ex_wepo_secondary && level.ex_wepo_sidearm)
		{
			vslot = "virtual";
			if(self.weaponin["primary"] == "primary")
			{
				if(self.weaponin["primaryb"] == "primaryb") vslot = "virtual";
					else if(self.weaponin["primaryb"] == "virtual") vslot = "primaryb";
			}
			else if(self.weaponin["primary"] == "primaryb")
			{
				if(self.weaponin["primaryb"] == "primary") vslot = "virtual";
					else if(self.weaponin["primaryb"] == "virtual") vslot = "primaryb";
			}
			else if(self.weaponin["primary"] == "virtual")
			{
				if(self.weaponin["primaryb"] == "primary") vslot = "primaryb";
					else if(self.weaponin["primaryb"] == "primaryb") vslot = "primary";
			}
			weapon = self.weapon[vslot].name;
			if(isWeaponType(weapon, type)) return(true);
		}
	}

	return(false);
}

isWeaponType(weapon, type)
{
	if(!isDefined(weapon)) return(false);

	// look-ups that don't require weapons array records
	switch(type)
	{
		// check if weapon is valid
		case "valid":
			if(weapon != "none" && !isWeaponType(weapon, "dummy") && weapon != game["sprint"]) return(true);
			return(false);

		// check if weapon is valid
		case "weapon":
			if(!isWeaponType(weapon, "dummy") && weapon != game["sprint"]) return(true);
			return(false);

		// check if weapon is dummy
		case "dummy":
			switch(weapon)
			{
				case "dummy1_mp":
				case "dummy2_mp":
				case "dummy3_mp": return(true);
				default: return(false);
			}

		// check if weapon is a 30cal stationary MG
		case "30cal":
			switch(weapon)
			{
				case "30cal_duck_mp":
				case "30cal_prone_mp":
				case "30cal_stand_mp": return(true);
				default: return(false);
			}

		// check if weapon is a mg42 stationary MG
		case "mg42":
			switch(weapon)
			{
				case "mg42_bipod_duck_mp":
				case "mg42_bipod_prone_mp":
				case "mg42_bipod_stand_mp": return(true);
				default: return(false);
			}

		// check if weapon is a mobile MG
		case "mobilemg":
			switch(weapon)
			{
				case "mobile_30cal":
				case "mobile_mg42": return(true);
				default: return(false);
			}

		// check if weapon is a turret (stationary or mobile MG)
		case "turret":
			if(isWeaponType(weapon, "30cal") || isWeaponType(weapon, "mg42") || isWeaponType(weapon, "mobilemg")) return(true);
			return(false);

		// check if weapon is a frag grenade (or replacement)
		case "fragspecial":
			if(weapon == "fire_mp" || weapon == "gas_mp" || weapon == "satchel_mp") return(true);
			return(false);

		// check if weapon is smoke grenade
		case "smoke":
			if(level.ex_smoke[game["allies"]] < 7 && weapon == getSmokeTypeAllies() ||
			   level.ex_smoke[game["axis"]] < 7 && weapon == getSmokeTypeAxis()) return(true);
			return(false);

		// check if weapon is smoke replacement
		case "smokespecial":
			if(level.ex_smoke[game["allies"]] >= 7 && weapon == getSmokeTypeAllies() ||
			   level.ex_smoke[game["axis"]] >= 7 && weapon == getSmokeTypeAxis()) return(true);
			return(false);

		// check if weapon is VIP smoke grenade
		case "smokevip":
			vip_allies = "smoke_grenade_" + game["allies"] + "_vip_mp";
			if(weapon == vip_allies) return(true);
			vip_axis = "smoke_grenade_" + game["axis"] + "_vip_mp";
			if(weapon == vip_axis) return(true);
			return(false);
	}

	// look-ups that do require weapons array records
	if(!isDefined(level.weapons[weapon])) return(false);

	// classes that only require a classname and type match
	if(level.weapons[weapon].classname == type) return(true);

	// classes that require classname combinations or more complicated look-ups
	switch(type)
	{
		// check if weapon is a proper suicide bomb
		case "kamikaze":
			if(level.weapons[weapon].classname == "frag" ||
			   level.weapons[weapon].classname == "satchel" ||
			   level.weapons[weapon].classname == "super") return(true);
			return(false);

		// check if weapon is a bolt action rifle
		case "boltrifle":
			if(level.weapons[weapon].classname == "rifle" &&
			   isDefined(level.weapons[weapon].subclass) &&
			   level.weapons[weapon].subclass == "bolt") return(true);
			return(false);

		// check if weapon is a semi automatic rifle
		case "semirifle":
			if(level.weapons[weapon].classname == "rifle" &&
			   isDefined(level.weapons[weapon].subclass) &&
			   level.weapons[weapon].subclass == "semi") return(true);
			return(false);

		// check if weapon is sniper rifle
		case "sniper":
			if(level.weapons[weapon].classname == "sniper" ||
			   level.weapons[weapon].classname == "sniperlr") return(true);
			return(false);

		// check if weapon is SR sniper rifle
		case "snipersr":
			if(level.weapons[weapon].classname == "sniper") return(true);
			return(false);

		// check if weapons is bolt rifle or sniper rifle
		case "boltsniper":
			if(isWeaponType(weapon, "boltrifle") ||
			   level.weapons[weapon].classname == "sniper" ||
			   level.weapons[weapon].classname == "sniperlr") return(true);
			return(false);

		// check if weapon is sidearm
		case "sidearm":
			if(level.weapons[weapon].classname == "pistol" ||
			   level.weapons[weapon].classname == "knife" ||
			   level.weapons[weapon].classname == "vip" ||
			   level.weapons[weapon].classname == "raygun") return(true);
			return(false);

		// check if weapon is perk weapon
		case "perkweapon":
			if(isDefined(level.weapons[weapon].perkindex)) return(true);
			return(false);

		// check if weapon is perk weapon
		case "perkonhand":
			if(isDefined(level.weapons[weapon].perkindex) &&
			   game["perkcatalog"][level.weapons[weapon].perkindex]["weapontype"] == 0) return(true);
			return(false);

		// check if weapon is perk weapon
		case "perkfrag":
			if(isDefined(level.weapons[weapon].perkindex) &&
			   game["perkcatalog"][level.weapons[weapon].perkindex]["weapontype"] == 1) return(true);
			return(false);

		// check if weapon is perk weapon
		case "perksmoke":
			if(isDefined(level.weapons[weapon].perkindex) &&
			   game["perkcatalog"][level.weapons[weapon].perkindex]["weapontype"] == 2) return(true);
			return(false);

		// check if weapon is american
		case "american":
			if((level.weapons[weapon].nat & 1) == 1) return(true);
			return(false);

		// check if weapon is british
		case "british":
			if((level.weapons[weapon].nat & 2) == 2) return(true);
			return(false);

		// check if weapon is allies
		case "allies":
			if((level.weapons[weapon].nat & 4) != 4) return(true);
			return(false);

		// check if weapon is german
		case "axis":
		case "german":
			if((level.weapons[weapon].nat & 4) == 4) return(true);
			return(false);

		// check if weapon is russian
		case "russian":
			if((level.weapons[weapon].nat & 8) == 8) return(true);
			return(false);
	}

	return(false);
}

setWeaponClientStatus(status)
{
	self endon("disconnect");

	if(!isDefined(status)) status = false;

	if(isWeaponType(self.pers["weapon"], "valid"))
	{
		if(!status) self updateDisabledSingleClient(self.pers["weapon"]);
			else self updateAllowedSingleClient(self.pers["weapon"]);
	}

	if(isWeaponType(self.pers["weapon2"], "valid"))
	{
		if(!status) self updateDisabledSingleClient(self.pers["weapon2"]);
			else self updateAllowedSingleClient(self.pers["weapon2"]);
	}
}

replenishWeapons(gts)
{
	self endon("kill_thread");

	if(!isDefined(gts)) gts = false;

	if(isPlayer(self))
	{
		if(!gts)
		{
			self [[level.ex_dWeapon]]();

			// stop the weapon monitor
			//self waittill( stopWeaponChangeMonitor() );

			// play reload sound for effect
			self playlocalsound("weap_bar_reload");
			wait( [[level.ex_fpstime]](0.25) );
		}

		if(level.ex_wepo_class)
		{
			self setAmmo("primary", gts);
			self setAmmo("primaryb", gts);
		}
		else
		{
			self refillWeapon("primary", gts);
			self refillWeapon("primaryb", gts);
			self refillWeapon("virtual", gts);
		}

		if(!gts)
		{
			// start the weapon monitor
			//self waittill( startWeaponChangeMonitor(false, false) );

			wait( [[level.ex_fpstime]](3) );
			if(isPlayer(self)) self [[level.ex_eWeapon]]();
		}
	}
}

replenishGrenades(gts)
{
	self endon("kill_thread");

	if(!isDefined(gts)) gts = false;

	if(!gts)
	{
		// play reload sound for effect
		self playlocalsound("grenade_pickup");
		wait( [[level.ex_fpstime]](0.25) );

		// replenish grenades
		// teams share the same weapon file for special nades, so if one of them is enabled, only count own type
		if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges) frags = self getammocount(self.pers["fragtype"]);
			else frags = self getammocount(self.pers["fragtype"]) + self getammocount(self.pers["enemy_fragtype"]);

		smokes = self getammocount(self.pers["smoketype"]) + self getammocount(self.pers["enemy_smoketype"]);
	}
	else
	{
		frags = 0;
		smokes = 0;
	}

	if(isPlayer(self)) self giveGrenades(false, frags, smokes);
}

replenishFirstaid(gts)
{
	self endon("kill_thread");

	if(!isDefined(gts)) gts = false;

	if(!gts)
	{
		// play reload sound for effect
		self playlocalsound("health_pickup_large");
		wait( [[level.ex_fpstime]](0.25) );
	}
	else self.ex_firstaidkits = 0;

	// replenish firstaid
	if(isPlayer(self)) self giveFirstAid();

	// refresh the number of firstaid kits on screen
	hud_index = playerHudIndex("firstaid_kits");
	if(hud_index != -1)
	{
		playerHudSetValue(hud_index, self.ex_firstaidkits);
		if(self.ex_firstaidkits == 0) kits_color = (1, 0, 0);
			else kits_color = (1, 1, 1);
		playerHudSetColor(hud_index, kits_color);
	}
}

refillWeapon(slot, gts)
{
	if(!isDefined(self.weapon) || !isDefined(self.weapon[slot].name)) return;

	if(!isDefined(gts)) gts = false;

	// refill all eXtreme+ slots
	weapon = self.weapon[slot].name;
	if(!isWeaponType(weapon, "valid")) return;

	clip = self getWeaponSlotClipAmmoDefault(weapon);
	if(!isDefined(clip) || !clip) clip = self getWeaponSlotClipAmmo(slot);

	reserve = self getWeaponSlotAmmoDefault(weapon);
	if(!isDefined(reserve) || reserve < 0) reserve = self getWeaponSlotAmmo(slot);

	// rank system reserve ammo override
	if(level.ex_wepo_loadout == 1)
	{
		if(isWeaponType(weapon, "pistol")) rank_suffix = game["rank_ammo_pistolclips_" + self.pers["rank"]];
		else rank_suffix = game["rank_ammo_gunclips_" + self.pers["rank"]];

		reserve = clip * rank_suffix;
	}

	if(!gts)
	{
		// compare the ammo the weapon already has, if its greater, just fill the clip!
		reserve_check = self.weapon[slot].reserve;
		if(reserve_check > reserve) reserve = reserve_check;
	}

	self.weapon[slot].clip = clip;
	self.weapon[slot].reserve = reserve;
	self.weapon[slot].maxammo = clip + reserve;

	// now do the real slots if this weapon is in them!
	if(weapon == self getWeaponSlotWeapon("primary")) self setAmmo("primary", gts);
	else if(weapon == self getWeaponSlotWeapon("primaryb")) self setAmmo("primaryb", gts);
}

updateLoadout(promotion)
{
	if(!isDefined(promotion)) return;

	// update the ammo, first aid and binocs
	if(promotion)
	{
		self refillWeapon("primary", false);
		self refillWeapon("primaryb", false);
		self refillWeapon("virtual", false);

		if(level.ex_medicsystem) self giveFirstAid();
	}

	// process landmine
	if(level.ex_landmines)
	{
		// rank system update
		if(level.ex_landmines_loadout)
		{
			currentlandmines = 0;
			newlandmines = 0;

			if(isDefined(self.mine_ammo)) currentlandmines = self.mine_ammo;
				else currentlandmines = 0;
			if(!isDefined(currentlandmines)) currentlandmines = 0;
			newlandmines = game["rank_ammo_landmines_" + self.pers["rank"]];

			if(promotion)
			{
				if(level.ex_rank_promote_nades)
				{
					totallandmines = currentlandmines + newlandmines;
					if(totallandmines > level.ex_landmines_cap) totallandmines = level.ex_landmines_cap;
					self thread extreme\_ex_weapons_mines::updateLandmines(totallandmines);
				}
			}
			else if(level.ex_rank_demote_nades && currentlandmines > newlandmines)
			{
				totallandmines = newlandmines;
				if(totallandmines > level.ex_landmines_cap) totallandmines = level.ex_landmines_cap;
				self thread extreme\_ex_weapons_mines::updateLandmines(totallandmines);
			}
		}
		// maxammo perk
		else
		{
			self thread extreme\_ex_weapons_mines::updateLandmines(self.mine_ammo_max);
		}
	}

	// get current nade count
	// teams share the same weapon file for special nades, so if one of them is enabled, only count own type
	if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges) currentfrags = self getammocount(self.pers["fragtype"]);
		else currentfrags = self getammocount(self.pers["fragtype"]) + self getammocount(self.pers["enemy_fragtype"]);
	if(!isDefined(currentfrags)) currentfrags = 0;
	currentsmokes = self getammocount(self.pers["smoketype"]) + self getammocount(self.pers["enemy_smoketype"]);
	if(!isDefined(currentsmokes)) currentsmokes = 0;

	// give nades based on new rank. promotion if 1 (true), demotion if 0 (false), max ammo specialty if 2
	self giveGrenades((promotion != 2));

	// get new nade count
	// teams share the same weapon file for special nades, so if one of them is enabled, only count own type
	if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges) newfrags = self getammocount(self.pers["fragtype"]);
		else newfrags = self getammocount(self.pers["fragtype"]) + self getammocount(self.pers["enemy_fragtype"]);
	if(!isDefined(newfrags)) newfrags = 0;
	newsmokes = self getammocount(self.pers["smoketype"]) + self getammocount(self.pers["enemy_smoketype"]);
	if(!isDefined(newsmokes)) newsmokes = 0;

	if(promotion)
	{
		if(!level.ex_ranksystem || level.ex_rank_promote_nades) // promotion; promote nades
		{
			totalfrags = currentfrags + newfrags;
			if(totalfrags > level.ex_frag_cap) totalfrags = level.ex_frag_cap;
			if(totalfrags)
			{
				if(!newfrags) self giveWeapon(self.pers["fragtype"]);
				self setWeaponClipAmmo(self.pers["fragtype"], totalfrags);
			}

			totalsmokes = currentsmokes + newsmokes;
			if(totalsmokes > level.ex_smoke_cap) totalsmokes = level.ex_smoke_cap;
			if(totalsmokes)
			{
				if(!newsmokes) self giveWeapon(self.pers["smoketype"]);
				self setWeaponClipAmmo(self.pers["smoketype"], totalsmokes);
			}
		}
		else // promotion; keep current
		{
			if(currentfrags && !newfrags)
			{
				self giveWeapon(self.pers["fragtype"]);
				self setWeaponClipAmmo(self.pers["fragtype"], currentfrags);
			}

			if(currentsmokes && !newsmokes)
			{
				self giveWeapon(self.pers["smoketype"]);
				self setWeaponClipAmmo(self.pers["smoketype"], currentsmokes);
			}
		}
	}
	else if(level.ex_ranksystem && level.ex_rank_demote_nades) // demotion; demote nades
	{
		if(currentfrags > newfrags)
		{
			totalfrags = newfrags;
			if(totalfrags > level.ex_frag_cap) totalfrags = level.ex_frag_cap;
			if(!newfrags) self giveWeapon(self.pers["fragtype"]);
			self setWeaponClipAmmo(self.pers["fragtype"], totalfrags);
		}

		if(currentsmokes > newsmokes)
		{
			totalsmokes = newsmokes;
			if(totalsmokes > level.ex_smoke_cap) totalsmokes = level.ex_smoke_cap;
			if(!newsmokes) self giveWeapon(self.pers["smoketype"]);
			self setWeaponClipAmmo(self.pers["smoketype"], totalsmokes);
		}
	}
	else // demotion; keep current
	{
		if(currentfrags && !newfrags)
		{
			self giveWeapon(self.pers["fragtype"]);
			self setWeaponClipAmmo(self.pers["fragtype"], currentfrags);
		}

		if(currentsmokes && !newsmokes)
		{
			self giveWeapon(self.pers["smoketype"]);
			self setWeaponClipAmmo(self.pers["smoketype"], currentsmokes);
		}
	}
}

weaponsLog(logweap, procname)
{
	//if(!isDefined(self.ex_clanNM)) return;
	//if(self.name != "bot1") return;
	if(isDefined(self.pers["isbot"])) return;

	wait(level.ex_fps_frame);

	logprint("\n********** " + self.name + " **********\n");
	if(isDefined(procname)) logprint("WPN: procedure " + procname + "\n");
	if(logweap)
	{
		primary = self getWeaponSlotWeapon("primary");
		secondary = self getWeaponSlotWeapon("primaryb");
		current = self getCurrentWeapon();

		if(level.ex_wepo_secondary)
		{
			logprint("WPN:      self.pers[\"weapon1\"] " + self.pers["weapon1"] + " -- actual primary " + primary + "\n");
			logprint("WPN:      self.pers[\"weapon2\"] " + self.pers["weapon2"] + " -- actual secondary " + secondary + "\n");
		}
		else
			logprint("WPN:       self.pers[\"weapon\"] " + self.pers["weapon"] + " -- actual primary " + primary + " (secondary: " + secondary + ")\n");

		logprint("WPN:  self.weaponin[\"primary\"] " + self.weaponin["primary"] + "\n");
		logprint("WPN: self.weaponin[\"primaryb\"] " + self.weaponin["primaryb"] + "\n");

		logprint("WPN:    self.weapon[\"primary\"] " + self.weapon["primary"].name + " (self.weapon[\"primary_saved\"] " + self.weapon["primary_saved"].name + ")\n");
		logprint("WPN:   self.weapon[\"primaryb\"] " + self.weapon["primaryb"].name + " (self.weapon[\"primaryb_saved\"] " + self.weapon["primaryb_saved"].name + ")\n");
		logprint("WPN:    self.weapon[\"virtual\"] " + self.weapon["virtual"].name + "\n");
		logprint("WPN:    self.weapon[\"current\"] " + self.weapon["current"] + " -- actual current " + current + "\n");
	}
}
