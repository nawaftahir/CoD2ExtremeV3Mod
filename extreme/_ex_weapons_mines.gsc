#include extreme\_ex_controller_hud;
#include extreme\_ex_main_utils;
#include extreme\_ex_weapons;

init()
{
	mineDelete(-1);

	level.mine_identifier = 0;
	level.mine_trigger_distance = 30;
	level.mine_defuse_distance = level.mine_trigger_distance + 20;
	level.mine_warn_distance = level.mine_trigger_distance + 120;

	// device registration
	[[level.ex_devRequest]]("mine", ::cpxMine);
}

giveLandmines()
{
	self endon("disconnect");

	if(level.ex_landmines_loadout) self.mine_ammo_max = game["rank_ammo_landmines_" + self.pers["rank"]];
		else self.mine_ammo_max = getWeaponBasedMineCount(self.pers["weapon"]);
	self.mine_ammo = self.mine_ammo_max;

	if(!isDefined(self.ex_moving)) self.ex_moving = false;

	self.mine_protection = 0;
	self.mine_handling = false;
	self.mine_inrange = false;

	// mbots do not get landmines
	if(level.ex_mbot && isDefined(self.pers["isbot"]))
	{
		self.mine_ammo = 0;
		return;
	}

	// check if account system grants access
	if(level.ex_accounts && self.pers["account"]["status"] == 1 && (level.ex_accounts_lock & 8) == 8)
	{
		self.mine_ammo = 0;
		return;
	}

	if(self.mine_ammo) self thread minePlantMonitor();
}

updateLandmines(landmines)
{
	if(level.ex_mbot && isDefined(self.pers["isbot"])) return;

	plantMonitorIsRunning = self.mine_ammo;
	self.mine_ammo_max = landmines;
	self.mine_ammo = self.mine_ammo_max;
	if(!plantMonitorIsRunning) self thread minePlantMonitor();
		else self thread mineShowHUD();
}

mineShowHUD()
{
	//  frag 20x20:
	//		icon(-42, -75), "right", "bottom", "left", "top"
	//		ammo(-20, -57), "right", "bottom", "left", "bottom"
	// smoke 20x20:
	//		icon(-42,-100), "right", "bottom", "left", "top"
	//		ammo(-20, -82), "right", "bottom", "left", "bottom"
	//  medi 20x20
	//		icon(-42,-125), "right", "bottom", "left", "top"
	//		ammo(-20,-107), "right", "bottom", "left", "bottom"
	//  mine 20x20
	//		icon(-42,-150), "right", "bottom", "left", "top"
	//		ammo(-20,-132), "right", "bottom", "left", "bottom"

	if(level.ex_medicsystem) iconY = -150;
		else iconY = -125;
	ammoY = iconY + 18;
	
	if(self.mine_ammo == 0) ammo_color = (1, 0, 0);
		else ammo_color = (1, 1, 1);

	// HUD landmine icon
	hud_index = playerHudIndex("landmine_icon");
	if(hud_index == -1) hud_index = playerHudCreate("landmine_icon", -42, iconY, 1, (1,1,1), 1, 0, "right", "bottom", "left", "top", false, true);
	if(hud_index != -1) playerHudSetShader(hud_index, "mtl_weapon_bbetty_hud", 20, 20);

	// HUD landmine ammo
	hud_index = playerHudIndex("landmine_ammo");
	if(hud_index == -1) hud_index = playerHudCreate("landmine_ammo", -20, ammoY, 1, ammo_color, 1, 0, "right", "bottom", "left", "bottom", false, true);
	if(hud_index != -1)
	{
		playerHudSetColor(hud_index, ammo_color);
		playerHudSetValue(hud_index, self.mine_ammo);
	}
}

minePlantMonitor()
{
	self endon("kill_thread");

	self thread mineShowHUD();

	while(self.mine_ammo)
	{
		timer = 0;
		while(self isStanceOK(2) && !self.ex_moving && self useButtonPressed())
		{
			// prevent mine plant hysteria
			if(timer < 0.5)
			{
				timer = timer + level.ex_fps_frame;
				wait( level.ex_fps_frame );
				continue;
			}

			// prevent planting while already handling a mine
			if(self.mine_inrange || self.mine_handling) break;

			// prevent planting while healing (crouched shellshock position is detected as prone).
			// wait till healing is over and player releases USE button
			if(isDefined(self.ex_ishealing))
			{
				while(isDefined(self.ex_ishealing)) wait( level.ex_fps_frame );
				while(self useButtonPressed()) wait( level.ex_fps_frame );
				break;
			}

			// prevent planting landmine while planting or defusing bomb in SD or ESD
			if(isDefined(self.bomb_handling)) break;

			// prevent planting too close to special entities
			if(self tooClose(level.ex_mindist["landmines"][0], level.ex_mindist["landmines"][1], level.ex_mindist["landmines"][2], level.ex_mindist["landmines"][3])) break;

			// prevent planting while being frozen in freezetag
			if(level.ex_currentgt == "ft" && isDefined(self.frozenstate) && self.frozenstate == "frozen") break;

			// double check stance
			if(!self isStanceOK(2)) break;

			// check if free slot available
			if(!(self mineCount(false) < level.ex_landmines_max) && !level.ex_landmines_fifo)
			{
				self iprintlnbold(&"LANDMINES_MAXIMUM");
				break;
			}

			// get origin and angles
			plant = self maps\mp\_utility::getPlant(32);

			// check for correct surface type
			if(level.ex_landmines_surfacecheck && !allowedSurface(plant.origin))
			{
				self iprintlnbold(&"LANDMINES_WRONG_SURFACE");
				break;
			}

			self.mine_handling = true;

			self playsound("moody_plant");
			self.mine_plant_sitstill = spawn("script_origin", self.origin);
			self linkTo(self.mine_plant_sitstill);
			self [[level.ex_dWeapon]]();

			playerHudCreateBar(level.ex_landmines_plant_time, &"LANDMINES_PLANTING", false);

			count = 0;
			while(isAlive(self) && self useButtonPressed() && self isStanceOK(2))
			{
				wait( level.ex_fps_frame );
				count += level.ex_fps_frame;
				if(count >= level.ex_landmines_plant_time) break;
			}

			playerHudDestroyBar();

			self unlink();
			self [[level.ex_eWeapon]]();
			if(isDefined(self.mine_plant_sitstill)) self.mine_plant_sitstill delete();

			if(count >= level.ex_landmines_plant_time)
			{
				self thread mineDrop(plant);
				self.mine_ammo--;
				self thread mineShowHUD();
			}

			while(isAlive(self) && self useButtonPressed()) wait( level.ex_fps_frame );

			self.mine_handling = false;

			if(!self.mine_ammo) break;

			timer = 0;
			wait( level.ex_fps_frame );
		}

		wait( [[level.ex_fpstime]](0.1) );
	}

	self thread mineShowHUD();
}

mineDrop(plant)
{
	if(!isDefined(self)) return;

	level.mine_identifier++;
	self.mine_protection = level.mine_identifier;

	// spawn mine
	mine = spawn("script_model", plant.origin - (0, 0, level.ex_landmines_depth));
	mine hide();
	mine.angles = plant.angles;
	mine.identifier = level.mine_identifier; // set custom vars before assigning targetname
	mine.blow = false;
	mine.owner = self;
	mine.team = self.pers["team"];
	mine setModel( extreme\_ex_controller_devices::getDeviceModel("mine") );
	mine.targetname = "item_mine";
	mine.trigger = spawn("trigger_radius", mine.origin, 0, level.mine_warn_distance, 10);
	mine.handlers = [];
	mine show();

	// debugging: assign mine to bot
	//self assignToEnemyPlayer(mine);

	self playsound("weap_fraggrenade_pin");
	wait( [[level.ex_fpstime]](0.15) );
	self playsound("weap_fraggrenade_pin");

	// remove oldest if planted mines exceed maximum now
	self thread mineCheckMax();

	// do not arm until player releases the USE button
	while(isAlive(self) && self useButtonPressed()) wait( level.ex_fps_frame );

	// start monitor thread
	mine thread mineMonitor();

	// start trigger thread
	mine thread mineThink();
}

mineMonitor()
{
	level endon("ex_gameover");

	while(true)
	{
		wait( [[level.ex_fpstime]](0.5) );

		// return if mine is gone
		if(!isDefined(self)) return;

		// blow up
		if(self.blow) break;

		// delete mine if owner left or switched teams
		if(!isPlayer(self.owner) || (level.ex_teamplay && self.owner.pers["team"] != self.team))
		{
			self thread mineDeleteSelf();
			return;
		}
	}

	self thread mineBlow();
}

mineThink()
{
	level endon("ex_gameover");
	self endon("kill_think");

	while(true)
	{
		self.trigger waittill("trigger", player);

		if(isPlayer(player) && player.sessionstate == "playing")
		{
			entityno = player getEntityNumber();
			if(isDefined(self.handlers[entityno])) continue;
			self.handlers[entityno] = true;
			player thread minePlayer(self);
		}
	}
}

minePlayer(device)
{
	self endon("kill_thread");

	dev_blow = false;
	dev_origin = device.origin;
	dev_owner = device.owner;
	dev_team = device.team;
	dev_identifier = device.identifier;

	while(isDefined(device))
	{
		wait( level.ex_fps_frame );

		// would it trigger on player?
		dev_wouldblow = true;
		switch(level.ex_landmines)
		{
			case 2: if(self == dev_owner) dev_wouldblow = false; break;
			case 3: if(self == dev_owner || (level.ex_teamplay && self.pers["team"] == dev_team)) dev_wouldblow = false; break;
		}

		// owner plant protection
		if(dev_identifier == self.mine_protection) dev_wouldblow = false;

		// check if player is in trigger range
		dev_dist = int(distance(dev_origin, self.origin));
		if(dev_dist < level.mine_trigger_distance)
		{
			// jumping over? (mbots do not always pass the isOnGround test, so skip this test for them)
			if(!isDefined(self.pers["isbot"]) && self isOnGround()) dev_blow = dev_wouldblow;
			if(dev_blow) break;
		}

		// check if player is in warning range
		if(dev_dist < level.mine_warn_distance)
		{
			// check if player is in defuse range
			dev_defuse = false;
			if(level.ex_landmines_defuse && dev_dist < level.mine_defuse_distance)
			{
				if(level.ex_teamplay)
				{
					switch(level.ex_landmines_defuse)
					{
						case 1: if(self == dev_owner) dev_defuse = true; break;
						case 2:	if(self == dev_owner || self.pers["team"] == dev_team) dev_defuse = true; break;
						case 3:	if(self == dev_owner || self.pers["team"] != dev_team) dev_defuse = true; break;
						case 4: dev_defuse = true; break;
					}
				}
				else
				{
					switch(level.ex_landmines_defuse)
					{
						case 1:
						case 2: if(self == dev_owner) dev_defuse = true; break;
						case 3:
						case 4: dev_defuse = true; break;
					}
				}

				// override if necessary
				if(level.ex_currentgt == "ft" && isDefined(self.frozenstate) && self.frozenstate == "frozen") dev_defuse = false;
				if(self.mine_handling || self.ex_moving || !self isStanceOK(4)) dev_defuse = false;
			}

			if(dev_defuse)
			{
				self.mine_inrange = true;
				hud_index = self playerHudIndex("dev_defuse");
				if(hud_index == -1) hud_index = self playerHudCreate("dev_defuse", 0, level.hudBarY, 1, (1,1,1), 1, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
				if(hud_index != -1) self playerHudAddText(hud_index, &"LANDMINES_DEFUSE");

				if(self useButtonPressed()) self thread mineDefuse(device);
			}
			else
			{
				self.mine_inrange = false;
				self playerHudRemoveText("dev_defuse", &"LANDMINES_DEFUSE");
			}

			// check if we should show the danger warning
			if(dev_wouldblow && level.ex_landmines_warning)
			{
				dev_danger = false;
				if(level.ex_teamplay)
				{
					switch(level.ex_landmines_warning)
					{
						case 1: if(self == dev_owner || self.pers["team"] == dev_team) dev_danger = true; break;
						case 2: dev_danger = true; break;
					}
				}
				else dev_danger = true;
				if(dev_danger) self thread mineWarning("landmine_danger" + dev_identifier, dev_origin);
			}
		}
		else break;
	}

	// clean up
	self.mine_inrange = false;
	self playerHudRemoveText("dev_defuse", &"LANDMINES_DEFUSE");
	self notify("landmine_danger" + dev_identifier);
	if(dev_identifier == self.mine_protection) self.mine_protection = 0;

	// clear handler and trigger blow if necessary
	if(isDefined(device))
	{
		if(isDefined(device.handlers)) device.handlers[self getEntityNumber()] = undefined;
		if(dev_blow) device.blow = true;
	}
}

mineBlow()
{
	self playsound ("minefield_click");
	if(level.ex_landmines_bb) self movez(60, 0.4, 0, 0.3);
	wait( [[level.ex_fpstime]](0.5) );
	self hide();

	// clean up and kill running threads
	level notify("landmine_danger" + self.identifier);
	self notify("kill_think");
	if(isDefined(self.trigger)) self.trigger delete();

	// release linked player if still alive
	if(isDefined(self.linkedplayer) && isPlayer(self.linkedplayer) && isAlive(self.linkedplayer))
	{
		self.linkedplayer playerHudDestroyBar();
		self.linkedplayer unlink();
		self.linkedplayer [[level.ex_eWeapon]]();
		self.linkedplayer.mine_handling = false;
	}

	// device info to pass on
	device_info = [[level.ex_devInfo]](self.owner, self.team);
	device_info.dodamage = true;

	// device explosion
	self thread [[level.ex_devExplode]]("mine", device_info);

	wait(1);
	self thread mineDeleteSelf();
}

mineDefuse(device)
{
	self endon("kill_thread");

	self.mine_handling = true;

	// remember player so we can unlink and clean up the HUD when the landmine blows without
	// killing the player
	device.linkedplayer = self;

	self playsound("moody_plant");
	self linkTo(device);
	self [[level.ex_dWeapon]]();

	playerHudRemoveText("dev_defuse", &"LANDMINES_DEFUSE");
	playerHudCreateBar(level.ex_landmines_defuse_time, &"LANDMINES_DEFUSING", true);

	count = 0;
	while(isDefined(device) && isAlive(self) && self useButtonPressed() && self isStanceOK(4))
	{
		wait( level.ex_fps_frame );
		count += level.ex_fps_frame;
		if(count >= level.ex_landmines_defuse_time) break;
	}

	playerHudDestroyBar();

	if(count >= level.ex_landmines_defuse_time)
	{
		// stop monitoring the mine
		if(isDefined(device)) device notify("kill_think");

		// bonus points for defusing
		if(isDefined(device) && level.ex_reward_landmine)
		{
			if( (!level.ex_teamplay && device.owner != self) || (level.ex_teamplay && device.team != self.pers["team"]) )
				self thread [[level.ex_scorePlayer]](level.ex_reward_landmine, "bonus");
		}

		// check if account system grants access
		if(!level.ex_accounts || (self.pers["account"]["status"] == 1 && (level.ex_accounts_lock & 8) == 0))
		{
			if(self.mine_ammo < self.mine_ammo_max)
			{
				self.mine_ammo++;
				if(self.mine_ammo == 1) self thread minePlantMonitor();
				self thread mineShowHUD();
			}
		}

		// remove the mine
		device mineDeleteSelf();
	}

	if(isDefined(device)) device.linkedplayer = undefined;
	self unlink();
	self [[level.ex_eWeapon]]();

	while(isAlive(self) && self useButtonPressed()) wait( level.ex_fps_frame );
	self.mine_handling = false;
	self.mine_inrange = false;
}

mineWarning(name, origin)
{
	self endon("kill_thread");

	// return if hud already exists
	hud_index = playerHudIndex(name);
	if(hud_index != -1) return;

	// the name of the HUD element must be the same as the notification to destroy it
	self thread mineWarningDestroyer(name);

	hud_index = playerHudCreate(name, origin[0], origin[1], 1, (1,0,0), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	playerHudSetShader(hud_index, "killiconsuicide", 7, 7);
	playerHudSetWaypoint(hud_index, origin[2] + 30, true);
}

mineWarningDestroyer(notification)
{
	self endon("kill_thread");

	ent = spawnstruct();
	self thread mineNotification(notification, true, ent);
	self thread mineNotification(notification, false, ent);
	ent waittill("returned");

	ent notify("die");
	self playerHudDestroy(notification);
}

mineNotification(notification, islevel, ent)
{
	self endon("kill_thread");
	ent endon("die");

	if(isLevel) level waittill(notification);
		else self waittill(notification);

	ent notify("returned");
}

// check max amount of mines for player (DM style game) or team (team based game)
mineCheckMax()
{
	oldestMine = self mineCount(true);
	if(oldestMine != 0) mineDelete(oldestMine);
}

// return number of mines (parameter set to FALSE) or oldest mine (parameter set to TRUE)
// for player (DM style game) or team (team based game)
mineCount(return_oldest)
{
	ownMines = 0;
	oldestMine = 9999;
	mines = getentarray("item_mine", "targetname");
	for(i = 0; i < mines.size; i++)
	{
		if(isDefined(mines[i]) && isDefined(self))
		{
			if( (!level.ex_teamplay && mines[i].owner == self) || (level.ex_teamplay && mines[i].team == self.pers["team"]) )
			{
				ownMines++;
				if(mines[i].identifier < oldestMine) oldestMine = mines[i].identifier;
			}
		}
	}

	if(return_oldest)
	{
		if(ownMines > level.ex_landmines_max) return(oldestMine);
			else return(0);
	}
	else return(ownMines);
}

// delete mine with specific identifier, or all mines if identifier is -1
mineDelete(identifier)
{
	mines = getentarray("item_mine", "targetname");
	for(i = 0; i < mines.size; i++)
	{
		if(isDefined(mines[i]) && (mines[i].identifier == identifier || identifier == -1))
		{
			if(mines[i].blow) continue;
			mines[i] mineDeleteSelf();
		}
	}
}

// delete mine
mineDeleteSelf()
{
	level notify("landmine_danger" + self.identifier);
	self notify("kill_think");
	if(isDefined(self.trigger)) self.trigger delete();
	self.handlers = undefined;
	self delete();
}

getWeaponBasedMineCount(weapon)
{
	if(isWeaponType(weapon, "boltrifle")) return(level.ex_landmines_allow_boltrifle);
	if(!isDefined(level.weapons[weapon])) return(0);

	switch(level.weapons[weapon].classname)
	{
		case "sniper": return(level.ex_landmines_allow_sniper);
		case "rifle": return(level.ex_landmines_allow_rifle);
		case "smg": return(level.ex_landmines_allow_smg);
		case "mg": return(level.ex_landmines_allow_mg);
		case "shotgun": return(level.ex_landmines_allow_shotgun);
		default: return(0);
	}
}

allowedSurface(origin)
{
	trace = bulletTrace(origin + (0,0,100), origin + (0,0,-100), true, undefined);
	if(trace["fraction"] < 1.0) surface = trace["surfacetype"];
		else surface = "dirt";

	switch(surface)
	{
		case "beach":
		case "dirt":
		case "grass":
		case "ice":
		case "mud":
		case "sand":
		case "snow": return(true);
	}

	return(false);
}

cpxMine(dev_index, cpx_flag, origin, owner, team, entity)
{
	if(!level.ex_landmines_cpx) return;

	mines = getentarray("item_mine", "targetname");
	for(i = 0; i < mines.size; i++)
	{
		mine = mines[i];
		if(!isDefined(mine) || mine.blow) continue;

		switch(cpx_flag)
		{
			case 1:
				if(level.ex_landmines_cpx == 1 && isDefined(team) && level.ex_teamplay && mine.team == team) break;
				dist = int( distance(origin, mine.origin) );
				if(dist <= level.ex_devices[dev_index].range) mine.blow = true;
				break;
			case 2:
				break;
			case 4:
				break;
			case 8:
				mine.blow = true;
				break;
			case 16:
				mine.blow = true;
				break;
			case 32:
				mine.blow = true;
				break;
		}
		wait( level.ex_fps_frame );
	}
}
