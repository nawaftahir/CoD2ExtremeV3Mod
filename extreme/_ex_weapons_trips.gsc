#include extreme\_ex_controller_hud;
#include extreme\_ex_controller_devices;
#include extreme\_ex_main_utils;
#include extreme\_ex_weapons;

init()
{
	tripDelete(-1);

	level.trip_identifier = 0;
	level.trip_spread = 50;
	level.trip_trigger_distance = 30;
	level.trip_defuse_distance = level.trip_trigger_distance + 20;
	level.trip_warn_distance = level.trip_trigger_distance + 120;

	// device registration (trip components are done in _ex_weapons_nades::initPost)
	[[level.ex_devRequest]]("trip", ::cpxTrip);
}

main()
{
	self.trip_protection = 0;
	self.trip_handling = false;
	self.trip_inrange = false;

	self thread tripPlantMonitor();
}

tripPlantMonitor()
{
	self endon("kill_thread");

	while(isPlayer(self) && self.sessionstate == "playing")
	{
		wait( [[level.ex_fpstime]](0.5) );

		frag = false;
		smoke = false;
		combo = false;
		trip = "none";

		// if not prone, continue monitoring
		if(self [[level.ex_getstance]](false) != 2 || !self meleeButtonPressed() || self playerads()) continue;

		// prevent planting while already handling a trip
		if(self.trip_inrange || self.trip_handling) continue;

		// prevent planting while using or with turret
		if(isDefined(self.onturret) || isWeaponType(self getCurrentWeapon(), "turret")) 
		{
			self thread cleanMessages();
			continue;
		}

		// check available nades
		frags = self getAmmoCount(self.pers["fragtype"]);
		smokes = self getAmmoCount(self.pers["smoketype"]);

		// teams share the same weapon file for special frags, so if one of them is enabled, skip enemy frags
		if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges) enemy_frags = 0;
			else enemy_frags = self getAmmoCount(self.pers["enemy_fragtype"]);
		enemy_smokes = self getAmmoCount(self.pers["enemy_smoketype"]);

		total_frags = frags + enemy_frags;
		total_smokes = smokes + enemy_smokes;

		// need at least 2. If not enough nades, continue monitoring
		if((total_frags + total_smokes < 2) || self.trip_handling) continue;

		// prevent planting if already handling a trip
		if(self.trip_inrange || self.trip_handling) continue;

		// check if too close to special entities
		if(isPlayer(self) && self tooClose(level.ex_mindist["tripwires"][0], level.ex_mindist["tripwires"][1], level.ex_mindist["tripwires"][2], level.ex_mindist["tripwires"][3]))
		{
			self cleanMessages();
			continue;
		}

		self showTripMessage(undefined, undefined, &"TRIPWIRE_HOLD_MELEE");

		// check for frags
		frag1type = self.pers["fragtype"];
		frag2type = self.pers["fragtype"];

		// not enough of their own teams, so check for enemy frags too
		if(frags <= 1)
		{
			if(frags == 1 && enemy_frags >= 1) // mix own frag and enemy frags
			{
				frag2type = self.pers["enemy_fragtype"];
				frag = true;
			}
			else if(frags == 0 && enemy_frags >= 2) // enemy frags only
			{
				frag1type = self.pers["enemy_fragtype"];
				frag2type = self.pers["enemy_fragtype"];
				frag = true;
			}
		}
		else frag = true; // got enough of their own frags

		// check for frag/smoke combination
		comb1type = self.pers["fragtype"];
		comb2type = self.pers["fragtype"];

		if(frags >= 1)
		{
			if(smokes >= 1) // mix own frag and own smoke
			{
				comb2type = self.pers["smoketype"];
				combo = true;
			}
			else if(enemy_smokes >= 1) // mix own frag and enemy smoke
			{
				comb2type = self.pers["enemy_smoketype"];
				combo = true;
			}
		}

		if(!combo && enemy_frags >= 1)
		{
			if(smokes >= 1) // mix enemy frag and own smoke
			{
				comb1type = self.pers["enemy_fragtype"];
				comb2type = self.pers["smoketype"];
				combo = true;
			}
			else if(enemy_smokes >= 1) // mix own frag and enemy smoke
			{
				comb1type = self.pers["enemy_fragtype"];
				comb2type = self.pers["enemy_smoketype"];
				combo = true;
			}
		}

		// check for smokes
		smoke1type = self.pers["smoketype"];
		smoke2type = self.pers["smoketype"];

		// not enough of their own teams, so check for enemy frags too
		if(smokes <= 1)
		{
			if(smokes == 1 && enemy_smokes >= 1) // mix own smoke and enemy smoke
			{
				smoke2type = self.pers["enemy_smoketype"];
				smoke = true;
			}
			else if(smokes == 0 && enemy_smokes >= 2) // enemy smokes only
			{
				smoke1type = self.pers["enemy_smoketype"];
				smoke2type = self.pers["enemy_smoketype"];
				smoke = true;
			}
		}
		else smoke = true; // got enough of their own smokes

		// ok, lets see what they want to plant
		count = 0;
		while(self meleeButtonPressed() && self isStanceOK(2))
		{
			wait( level.ex_fps_frame );
			count += level.ex_fps_frame;
			if(count >= 1) break;
		}

		// didn't hold down long enough, loop
		if(count < 1)
		{
			self cleanMessages();
			continue;
		}

		// if they have enough frags, display the frag tripwire message
		if(frag)
		{
			self playLocalSound("tripclick");
			trip = "frag";
			if(combo) self showTripMessage(frag1type, frag2type, &"TRIPWIRE_HOLD_COMBO");
				else if(smoke) self showTripMessage(frag1type, frag2type, &"TRIPWIRE_HOLD_SMOKE");
					else self showTripMessage(frag1type, frag2type, &"TRIPWIRE_RELEASE_PROCEED");

			// if they let go here, they want to use frag grenades
			count = 0;
			while(self meleeButtonPressed() && self isStanceOK(2))
			{
				wait( level.ex_fps_frame );
				count += level.ex_fps_frame;
				if(count >= 1) break;
			}
		}
		else count = 1; // no frags!

		// if they have a combination of frag and smoke, display the combo tripwire message
		if(combo)
		{
			if(count >= 1) // they kept holding so show the combo
			{
				self playLocalSound("tripclick");
				trip = "combo";
				if(smoke) self showTripMessage(comb1type, comb2type, &"TRIPWIRE_HOLD_SMOKE");
					else self showTripMessage(comb1type, comb2type, &"TRIPWIRE_RELEASE_PROCEED");
			}

			// if they let go here, they want to use combo trip
			count = 0;
			while(self meleeButtonPressed() && self isStanceOK(2))
			{
				wait( level.ex_fps_frame );
				count += level.ex_fps_frame;
				if(count >= 1) break;
			}
		}
		else count = 1; // no combo!

		// if they have enough smokes, display the smoke tripwire message
		if(smoke)
		{
			if(count >= 1) // they kept holding so show the smokes
			{
				self playLocalSound("tripclick");
				trip = "smoke";
				if(frag) self showTripMessage(smoke1type, smoke2type, &"TRIPWIRE_HOLD_FRAG");
					else self showTripMessage(smoke1type, smoke2type, &"TRIPWIRE_RELEASE_PROCEED");
			}
		}

		// if they let go here, it will use the smokes. continue to hold and it will loop
		count = 0;
		while(self meleeButtonPressed() && self isStanceOK(2))
		{
			wait( level.ex_fps_frame );
			count += level.ex_fps_frame;
			if(count >= 1) break;
		}

		// they held on, so they don't want to plant a tripwire, or missed the one they wanted...doh!
		if(count >= 1)
		{
			trip = "none";
			self cleanMessages();
		}

		// check to see if they got up during this process?
		if(!self isStanceOK(2)) continue;

		// ok, good to go...
		if(trip == "frag") self thread tripDrop(frag1type, frag2type);
			else if(trip == "combo") self thread tripDrop(comb1type, comb2type);
				else if(trip == "smoke") self thread tripDrop(smoke1type, smoke2type);
	}
}

tripDrop(grenadetype1, grenadetype2)
{
	self endon("kill_thread");

	self.trip_handling = true;

	// show the plant message
	self showTripMessage(grenadetype1, grenadetype2, &"TRIPWIRE_PLANT");

	// while they're NOT pressing the melee key, monitor to see if they leave the prone position
	while(isPlayer(self) && self.sessionstate == "playing" && !self meleeButtonPressed())
	{
		if(!self isStanceOK(2))
		{
			self cleanMessages();
			self.trip_handling = false;
			return;
		}

		wait( level.ex_fps_frame );
	}

	for(;;)
	{
		// check the amount of ammo, might have thrown a grenade
		if(grenadetype1 == grenadetype2) iAmmo = self getAmmoCount(grenadetype1);
			else iAmmo = self getAmmoCount(grenadetype1) + self getAmmoCount(grenadetype2);

		// not enough ammo?
		if(iAmmo < 2) break;

		// check if they're still prone
		if(!self isStanceOK(2)) break;

		// get a position in front of the player
		position = self.origin + [[level.ex_vectorscale]](anglesToForward(self.angles), 15);

		// check if there is room.
		trace = bulletTrace(self.origin + (0,0,10), position + (0,0,10), false, undefined);
		if(trace["fraction"] != 1)
		{
			self iprintlnbold(&"TRIPWIRE_REASON_NO_ROOM");
			break;
		}

		// find ground
		trace = bulletTrace(position + (0,0,10), position + (0,0,-10), false, undefined);
		if(trace["fraction"] == 1)
		{
			self iprintlnbold(&"TRIPWIRE_REASON_UNEVEN_GROUND");
			break;
		}

		if(isDefined(trace["entity"]) && isDefined(trace["entity"].classname) && trace["entity"].classname == "script_vehicle") break;

		position = trace["position"];
		tracestart = position + (0,0,10);

		// find position 1
		traceend = tracestart + [[level.ex_vectorscale]](anglesToForward(self.angles + (0,90,0)), level.trip_spread);
		trace = bulletTrace(tracestart, traceend, false, undefined);

		if(trace["fraction"] != 1)
		{
			distance = distance(tracestart, trace["position"]);
			if(distance > 5) distance = distance - 2;
			position1 = tracestart + [[level.ex_vectorscale]](vectorNormalize(trace["position"] - tracestart), distance);
		}
		else position1 = trace["position"];

		// find ground
		trace = bulletTrace(position1, position1 + (0,0,-20), false, undefined);
		if(trace["fraction"] == 1)
		{
			self iprintlnbold(&"TRIPWIRE_REASON_UNEVEN_GROUND");
			break;
		}

		vPos1 = trace["position"];

		// find position 2
		traceend = tracestart + [[level.ex_vectorscale]](anglesToForward(self.angles + (0,-90,0)), level.trip_spread);
		trace = bulletTrace(tracestart, traceend, false, undefined);

		if(trace["fraction"] != 1)
		{
			distance = distance(tracestart, trace["position"]);
			if(distance > 5) distance = distance - 2;
			position2 = tracestart + [[level.ex_vectorscale]](vectorNormalize(trace["position"] - tracestart), distance);
		}
		else position2 = trace["position"];

		// find ground
		trace = bulletTrace(position2, position2 + (0,0,-20), false, undefined);
		if(trace["fraction"] == 1)
		{
			self iprintlnbold(&"TRIPWIRE_REASON_UNEVEN_GROUND");
			break;
		}

		vPos2 = trace["position"];

		// check to see if they are pressing their melee key
		if(isPlayer(self) && self.sessionstate == "playing" && self meleeButtonPressed())
		{
			// check if free slot available
			if(!(self tripCount(false) < level.ex_tripwire_max) && !level.ex_tripwire_fifo)
			{
				self iprintlnbold(&"TRIPWIRE_MAXIMUM");
				break;
			}

			// lock the player to the spot while planting the tripwire
			self extreme\_ex_player_punish::punishment("disable", "freeze");

			// play plant sound
			self playSound("MP_bomb_plant");

			self cleanMessages();
			playerHudCreateBar(level.ex_tripwire_ptime, &"TRIPWIRE_PLANTING", false);

			// count how long they hold the melee button for
			count = 0;
			while(isAlive(self) && self meleeButtonPressed() && self isStanceOK(2))
			{
				wait( level.ex_fps_frame );
				count += level.ex_fps_frame;
				if(count >= level.ex_tripwire_ptime) break;
			}

			// remove the progress bar
			playerHudDestroyBar();

			// enable the players weapon and release them
			self thread extreme\_ex_player_punish::punishment("enable", "release");

			// they did not hold the key down long enough
			if(count >= level.ex_tripwire_ptime)
			{
				// decrease the players grenade ammo
				self takeFromNadeLoadout(grenadetype1, 1);
				self takeFromNadeLoadout(grenadetype2, 1);

				// calculate the tripwire centre
				x = (vPos1[0] + vPos2[0])/2;
				y = (vPos1[1] + vPos2[1])/2;
				z = (vPos1[2] + vPos2[2])/2;
				vPos = (x,y,z+3);

				// spawn the tripwire
				level.trip_identifier++;
				self.trip_protection = level.trip_identifier;

				tripwire = spawn("script_origin", vPos);
				tripwire.angles = self.angles;
				tripwire.blow = false;
				tripwire.identifier = level.trip_identifier;
				tripwire.owner = self;
				tripwire.team = self.pers["team"];
				//tripwire setModel( getDeviceModel("trip") );
				tripwire.targetname = "item_trip";
				tripwire.trigger = spawn("trigger_radius", tripwire.origin, 0, distance(vPos1, vPos2), 10);
				tripwire.handlers = [];

				// spawn nade one
				dev_id = getGrenadeDevice(grenadetype1);
				tripwire.tweapon1 = spawn("script_model", vPos1 + (0,0,getDeviceModelZ(dev_id)));
				tripwire.tweapon1 setModel( getDeviceModel(dev_id) );
				tripwire.tweapon1.angles = self.angles + getDeviceModelA(dev_id);
				tripwire.tweapon1.dev = grenadetype1;
				tripwire.tweapon1.dev_id = dev_id;
				tripwire.tweapon1.damaged = false;

				// spawn nade two
				dev_id = getGrenadeDevice(grenadetype2);
				tripwire.tweapon2 = spawn("script_model", vPos2 + (0,0,getDeviceModelZ(dev_id)));
				tripwire.tweapon2 setModel( getDeviceModel(dev_id) );
				tripwire.tweapon2.angles = self.angles + getDeviceModelA(dev_id);
				tripwire.tweapon2.dev = grenadetype2;
				tripwire.tweapon2.dev_id = dev_id;
				tripwire.tweapon2.damaged = false;

				// debugging: assign trip to bot
				//self assignToEnemyPlayer(tripwire);

				self playlocalsound("planted");
				self playlocalsound("MP_bomb_plant");

				// remove oldest if planted trips exceed maximum now
				self thread tripCheckMax();

				// do not arm until player releases the MELEE button
				while(isAlive(self) && self meleeButtonPressed()) wait( level.ex_fps_frame );

				// start monitor thread
				tripwire thread tripMonitor();

				// start trigger thread
				tripwire thread tripThink();
			}
		}
		break;
	}

	// remove messages
	self cleanMessages();

	self.trip_handling = false;
}

tripMonitor()
{
	level endon("ex_gameover");

	while(true)
	{
		wait( [[level.ex_fpstime]](0.5) );

		// return if trip is gone
		if(!isDefined(self)) return;

		// blow up
		if(self.blow) break;

		// delete mine if owner left or switched teams
		if(!isPlayer(self.owner) || (level.ex_teamplay && self.owner.pers["team"] != self.team))
		{
			self thread tripDeleteSelf();
			return;
		}
	}

	self thread tripBlow();
}

tripThink()
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
			player thread tripPlayer(self);
		}
	}
}

tripPlayer(device)
{
	self endon("kill_thread");

	// get component origins
	dev_pos1 = device.tweapon1.origin;
	dev_pos2 = device.tweapon2.origin;

	// get detection spots
	nadedist = distance(dev_pos1, dev_pos2);
	dev_pos3 = device.origin + [[level.ex_vectorscale]](anglesToForward(device.angles), nadedist/3.33);
	dev_pos4 = device.origin + [[level.ex_vectorscale]](anglesToForward(device.angles + (0,180,0)), nadedist/3.33);

	// set detection ranges
	dev_warnrange = distance(device.origin, dev_pos1) + level.trip_warn_distance;
	dev_sphere = distance(dev_pos3, dev_pos1);

	dev_blow = false;
	dev_origin = device.origin;
	dev_owner = device.owner;
	dev_team = device.team;
	dev_identifier = device.identifier;

	//level thread dropCircle(dev_pos3, dev_sphere, (1,0,0), 10);
	//level thread dropCircle(dev_pos4, dev_sphere, (1,1,0), 10);

	while(isDefined(device))
	{
		wait( level.ex_fps_frame );

		// would it trigger on player?
		dev_wouldblow = true;
		switch(level.ex_tripwire)
		{
			case 2: if(self == dev_owner) dev_wouldblow = false; break;
			case 3: if(self == dev_owner || (level.ex_teamplay && self.pers["team"] == dev_team)) dev_wouldblow = false; break;
		}

		// owner plant protection
		if(dev_identifier == self.trip_protection) dev_wouldblow = false;

		// check if player is in trigger range
		if(distance(dev_pos3, self.origin) < dev_sphere && distance(dev_pos4, self.origin) < dev_sphere)
		{
			// jumping over? (mbots do not always pass the isOnGround test, so skip this test for them)
			if(!isDefined(self.pers["isbot"]) && self isOnGround()) dev_blow = dev_wouldblow;
			if(dev_blow)
			{
				if(distance(dev_pos1, self.origin) < distance(dev_pos2, self.origin)) device.tweapon1.damaged = true;
					else device.tweapon2.damaged = true;
				break;
			}
		}

		// check if player is in warning range
		dev_dist = int(distance(dev_origin, self.origin));
		if(dev_dist < dev_warnrange)
		{
			// check if player is in defuse range
			dev_defuse = false;
			if(level.ex_tripwire_defuse && (distance(dev_pos1, self.origin) <= level.trip_defuse_distance || distance(dev_pos2, self.origin) <= level.trip_defuse_distance))
			{
				if(level.ex_teamplay)
				{
					switch(level.ex_tripwire_defuse)
					{
						case 1: if(self == dev_owner) dev_defuse = true; break;
						case 2:	if(self == dev_owner || self.pers["team"] == dev_team) dev_defuse = true; break;
						case 3:	if(self == dev_owner || self.pers["team"] != dev_team) dev_defuse = true; break;
						case 4: dev_defuse = true; break;
					}
				}
				else
				{
					switch(level.ex_tripwire_defuse)
					{
						case 1:
						case 2: if(self == dev_owner) dev_defuse = true; break;
						case 3:
						case 4: dev_defuse = true; break;
					}
				}

				// override if necessary
				if(level.ex_currentgt == "ft" && isDefined(self.frozenstate) && self.frozenstate == "frozen") dev_defuse = false;
				if(self.trip_handling || self.ex_moving || !self isStanceOK(2)) dev_defuse = false;
			}

			if(dev_defuse)
			{
				self.trip_inrange = true;
				hud_index = self playerHudIndex("dev_defuse");
				if(hud_index == -1) hud_index = self playerHudCreate("dev_defuse", 0, level.hudBarY, 1, (1,1,1), 1, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
				if(hud_index != -1) self playerHudAddText(hud_index, &"TRIPWIRE_DEFUSE");

				if(self meleeButtonPressed()) self thread tripDefuse(device);
			}
			else
			{
				self.trip_inrange = false;
				self playerHudRemoveText("dev_defuse", &"TRIPWIRE_DEFUSE");
			}

			// check if we should show the danger warning
			if(dev_wouldblow && level.ex_tripwire_warning)
			{
				dev_danger = false;
				if(level.ex_teamplay)
				{
					switch(level.ex_tripwire_warning)
					{
						case 1: if(self == dev_owner || self.pers["team"] == dev_team) dev_danger = true; break;
						case 2: dev_danger = true; break;
					}
				}
				else dev_danger = true;
				if(dev_danger) self thread tripWarning("tripwire_danger" + dev_identifier, dev_origin);
			}
		}
		else break;
	}

	// clean up
	self.trip_inrange = false;
	self playerHudRemoveText("dev_defuse", &"TRIPWIRE_DEFUSE");
	self notify("tripwire_danger" + dev_identifier);
	if(dev_identifier == self.trip_protection) self.trip_protection = 0;

	// clear handler and trigger blow if necessary
	if(isDefined(device))
	{
		if(isDefined(device.handlers)) device.handlers[self getEntityNumber()] = undefined;
		if(dev_blow) device.blow = true;
	}
}

tripBlow()
{
	level notify("tripwire_danger" + self.identifier);

	// device info to pass on
	device_info = [[level.ex_devInfo]](self.owner, self.team);
	device_info.dodamage = true;

	// handle trip component effects
	if(isDefined(self.tweapon1.damaged))
	{
		self.tweapon1 playSound("weap_fraggrenade_pin");
		wait( level.ex_fps_frame );
		self.tweapon1 thread [[level.ex_devTrip]](self.tweapon1.dev_id, device_info, "trip");

		wait( [[level.ex_fpstime]](0.15) );

		self.tweapon2 playSound("weap_fraggrenade_pin");
		wait( level.ex_fps_frame );
		self.tweapon2 thread [[level.ex_devTrip]](self.tweapon2.dev_id, device_info, "trip");
	}
	else
	{
		self.tweapon2 playSound("weap_fraggrenade_pin");
		wait( level.ex_fps_frame );
		self.tweapon2 thread [[level.ex_devTrip]](self.tweapon2.dev_id, device_info, "trip");

		wait( [[level.ex_fpstime]](0.15) );

		self.tweapon1 playSound("weap_fraggrenade_pin");
		wait( level.ex_fps_frame );
		self.tweapon1 thread [[level.ex_devTrip]](self.tweapon1.dev_id, device_info, "trip");
	}

	// handle trip damage
	self thread [[level.ex_devExplode]]("trip", device_info);

	wait(1);
	self thread tripDeleteSelf();
}

tripDefuse(device)
{
	self endon("kill_thread");

	self.trip_handling = true;

	// lock the player to the spot while defusing the tripwire
	self playsound("moody_plant");
	self extreme\_ex_player_punish::punishment("disable", "freeze");

	playerHudRemoveText("dev_defuse", &"TRIPWIRE_DEFUSE");
	playerHudCreateBar(level.ex_tripwire_dtime, &"TRIPWIRE_DEFUSING", true);

	count = 0;
	while(isDefined(device) && isAlive(self) && self meleeButtonPressed() && self isStanceOK(2))
	{
		wait( level.ex_fps_frame );
		count += level.ex_fps_frame;
		if(count >= level.ex_tripwire_dtime) break;
	}

	playerHudDestroyBar();

	if(count >= level.ex_tripwire_dtime)
	{
		// stop monitoring the tripwire
		if(isDefined(device)) device notify("kill_think");

		// bonus points for defusing
		if(isDefined(device) && level.ex_reward_tripwire)
		{
			if( (!level.ex_teamplay && device.owner != self) || (level.ex_teamplay && device.team != self.pers["team"]) )
				self thread [[level.ex_scorePlayer]](level.ex_reward_tripwire, "bonus");
		}

		// play a defuse sound and give player the new grenades
		if(isPlayer(self))
		{
			self playlocalsound("defused");
			self playsound("MP_bomb_defuse");

			// check if account system grants access
			if(!level.ex_accounts || (self.pers["account"]["status"] == 1 && (level.ex_accounts_lock & 8) == 0))
			{
				self addToNadeLoadout(device.tweapon1.dev, 1);
				self addToNadeLoadout(device.tweapon2.dev, 1);
			}
		}

		// remove the tripwire
		device tripDeleteSelf();
	}

	self thread extreme\_ex_player_punish::punishment("enable", "release");

	while(isAlive(self) && self meleeButtonPressed()) wait( level.ex_fps_frame );
	self.trip_handling = false;
	self.trip_inrange = false;
}

tripWarning(name, origin)
{
	self endon("kill_thread");

	// return if hud already exists
	hud_index = playerHudIndex(name);
	if(hud_index != -1) return;

	// the name of the HUD element must be the same as the notification to destroy it
	self thread tripWarningDestroyer(name);

	hud_index = playerHudCreate(name, origin[0], origin[1], 1, (1,0,0), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	playerHudSetShader(hud_index, "killiconsuicide", 7, 7);
	playerHudSetWaypoint(hud_index, origin[2] + 30, true);
}

tripWarningDestroyer(notification)
{
	self endon("kill_thread");

	ent = spawnstruct();
	self thread tripNotification(notification, true, ent);
	self thread tripNotification(notification, false, ent);
	ent waittill("returned");

	ent notify("die");
	playerHudDestroy(notification);
}

tripNotification(notification, islevel, ent)
{
	self endon("kill_thread");
	ent endon("die");

	if(isLevel) level waittill(notification);
		else self waittill(notification);

	ent notify("returned");
}

showTripMessage(grenadetype1, grenadetype2, msg)
{
	self endon("kill_thread");

	if(isPlayer(self))
	{
		self cleanMessages();

		if(isDefined(msg))
		{
			hud_index = playerHudCreate("tripwire_msg", 320, 408, 1, (1,1,1), 0.8, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
			if(hud_index == -1) return;
			playerHudSetText(hud_index, msg);
		}

		if(isDefined(grenadetype1))
		{
			hud_index = playerHudCreate("tripwire_nade1", 320, 415, 1, (1,1,1), 1, 0, "fullscreen", "fullscreen", "left", "top", false, false);
			if(hud_index == -1) return;
			playerHudSetShader(hud_index, getDeviceHud( getGrenadeDevice(grenadetype1) ), 40, 40);
		}

		if(isDefined(grenadetype2))
		{
			hud_index = playerHudCreate("tripwire_nade2", 320, 415, 1, (1,1,1), 1, 0, "fullscreen", "fullscreen", "right", "top", false, false);
			if(hud_index == -1) return;
			playerHudSetShader(hud_index, getDeviceHud( getGrenadeDevice(grenadetype2) ), 40, 40);
		}
	}
}

cleanMessages()
{
	self endon("kill_thread");

	playerHudDestroy("tripwire_msg");
	playerHudDestroy("tripwire_nade1");
	playerHudDestroy("tripwire_nade2");
}

// check max amount of trips for player (DM style game) or team (team based game)
tripCheckMax()
{
	oldestTrip = self tripCount(true);
	if(oldestTrip != 0) tripDelete(oldestTrip);
}

// return number of trips (parameter set to FALSE) or oldest trip (parameter set to TRUE)
// for player (DM style game) or team (team based game)
tripCount(return_oldest)
{
	ownTrips = 0;
	oldestTrip = 9999;
	trips = getentarray("item_trip", "targetname");
	for(i = 0; i < trips.size; i++)
	{
		if(isDefined(trips[i]) && isDefined(self))
		{
			if( (!level.ex_teamplay && trips[i].owner == self) || (level.ex_teamplay && trips[i].team == self.pers["team"]) )
			{
				ownTrips++;
				if(trips[i].identifier < oldestTrip) oldestTrip = trips[i].identifier;
			}
		}
	}

	if(return_oldest)
	{
		if(ownTrips > level.ex_tripwire_max) return(oldestTrip);
			else return(0);
	}
	else return(ownTrips);
}

// delete trip with specific identifier, or all trips if identifier is -1
tripDelete(identifier)
{
	trips = getentarray("item_trip", "targetname");
	for(i = 0; i < trips.size; i++)
	{
		if(isDefined(trips[i]) && (trips[i].identifier == identifier || identifier == -1))
		{
			if(trips[i].blow) continue;
			trips[i] tripDeleteSelf();
		}
	}
}

// delete trip
tripDeleteSelf()
{
	level notify("tripwire_danger" + self.identifier);
	self notify("kill_think");
	if(isDefined(self.trigger)) self.trigger delete();
	if(isDefined(self.tweapon1)) self.tweapon1 delete();
	if(isDefined(self.tweapon2)) self.tweapon2 delete();
	self.handlers = undefined;
	self delete();
}

addToNadeLoadout(grenadetype, newnades)
{
	if(isWeaponType(grenadetype, "frag") || isWeaponType(grenadetype, "fragspecial"))
	{
		if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges) currentfrags = self getammocount(self.pers["fragtype"]);
			else currentfrags = self getammocount(self.pers["fragtype"]) + self getammocount(self.pers["enemy_fragtype"]);
		if(!isDefined(currentfrags)) currentfrags = 0;

		totalfrags = currentfrags + newnades;
		if(totalfrags > level.ex_frag_cap) totalfrags = level.ex_frag_cap;
		self setWeaponClipAmmo(self.pers["fragtype"], totalfrags);
	}
	else if(isWeaponType(grenadetype, "smoke") || isWeaponType(grenadetype, "smokespecial"))
	{
		currentsmokes = self getammocount(self.pers["smoketype"]) + self getammocount(self.pers["enemy_smoketype"]);
		if(!isDefined(currentsmokes)) currentsmokes = 0;

		totalsmokes = currentsmokes + newnades;
		if(totalsmokes > level.ex_smoke_cap) totalsmokes = level.ex_smoke_cap;
		self setWeaponClipAmmo(self.pers["smoketype"], totalsmokes);
	}
}

takeFromNadeLoadout(grenadetype, count)
{
	self endon("disconnect");

	if(isPlayer(self))
	{
		totalnades = self getAmmoCount(grenadetype);
		if(totalnades == 0) return;
		if(totalnades < count) count = totalnades;
		self setWeaponClipAmmo(grenadetype, totalnades - count);
	}
}

cpxTrip(dev_index, cpx_flag, origin, owner, team, entity)
{
	if(!level.ex_tripwire_cpx) return;

	trips = getentarray("item_trip", "targetname");
	for(i = 0; i < trips.size; i ++)
	{
		tripwire = trips[i];
		if(!isDefined(tripwire) || tripwire.blow) continue;

		switch(cpx_flag)
		{
			case  1:
				if(level.ex_tripwire_cpx == 1 && isDefined(team) && level.ex_teamplay && tripwire.team == team) break;
				origin1 = tripwire.tweapon1.origin;
				origin2 = tripwire.tweapon2.origin;
				if(!isDefined(origin1) || !isDefined(origin2)) break;

				tripwire_damage = 0;
				dist1 = int( distance(origin, origin1) );
				dist2 = int( distance(origin, origin2) );
				if(dist1 <= level.ex_devices[dev_index].range) tripwire_damage += 1;
				if(dist2 <= level.ex_devices[dev_index].range) tripwire_damage += 2;

				if(tripwire_damage)
				{
					if(tripwire_damage == 3)
					{
						if(dist1 < dist2) tripwire.tweapon1.damaged = true;
							else tripwire.tweapon2.damaged = true;
					}
					else if(tripwire_damage == 2) tripwire.tweapon2.damaged = true;
						else tripwire.tweapon1.damaged = true;

					tripwire.blow = true;
				}
				break;
			case  2:
				break;
			case  4:
				break;
			case  8:
				tripwire.tweapon1.damaged = true;
				tripwire.blow = true;
				break;
			case 16:
				tripwire.tweapon1.damaged = true;
				tripwire.blow = true;
				break;
			case 32:
				tripwire.tweapon1.damaged = true;
				tripwire.blow = true;
				break;
		}
		wait( level.ex_fps_frame );
	}
}
