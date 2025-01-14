#include extreme\_ex_controller_devices;
#include extreme\_ex_controller_hud;
#include extreme\_ex_main_utils;
#include extreme\_ex_specials;

perkInit(index)
{
	// perk related precaching
	level.ex_effect["heli_mainrotor"] = [[level.ex_PrecacheEffect]]("fx/rotor/rotor250_spin.efx");
	level.ex_effect["heli_tailrotor"] = [[level.ex_PrecacheEffect]]("fx/rotor/rotor045_spin.efx");
	if(level.ex_heli_dust) level.ex_effect["heli_dust"] = [[level.ex_PrecacheEffect]]("fx/misc/heli_dust_side.efx");

	if(level.ex_heli_gun) level.ex_effect["heli_gun"] = [[level.ex_PrecacheEffect]]("fx/muzzleflashes/mg42hv.efx");
	if(level.ex_heli_tube) level.ex_effect["heli_tube"] = [[level.ex_PrecacheEffect]]("fx/muzzleflashes/flak_flash.efx");

	// device registration
	[[level.ex_devRequest]]("heli", ::cpxHeli);
	[[level.ex_devRequest]]("heli_gun");
	if(level.ex_heli_tube) [[level.ex_devRequest]]("heli_tube");
	if(level.ex_heli_missile) [[level.ex_devRequest]]("heli_missile");
}

perkInitPost(index)
{
	// perk related precaching after map load
}

perkCheck(index)
{
	// checks before being able to buy this perk
	if(isDefined(level.helicopter_player)) return(false);
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
		else self iprintlnbold(&"SPECIALS_HELI_READY");

	self thread hudNotifySpecial(index);

	while(true)
	{
		wait( level.ex_fps_frame );
		if(self meleebuttonpressed())
		{
			count = 0;
			while(self meleeButtonPressed() && count < 10)
			{
				wait( level.ex_fps_frame );
				count++;
			}

			if(count >= 10 && getPerkPriority(index) && heliAvailable()) break;
			while(self meleebuttonpressed()) wait( level.ex_fps_frame );
		}
	}

	self thread playerStartUsingPerk(index, true);
	self thread hudNotifySpecialRemove(index);

	level thread heliCreate(self);
}

//------------------------------------------------------------------------------
// Validation
//------------------------------------------------------------------------------
perkCheckEntity(entity)
{
	if(level.ex_heli && isDefined(level.helicopter) && entity == level.helicopter) return(1);
	return(-1);
}

perkValidateAsTarget(team)
{
	if(!level.ex_heli || !isDefined(level.helicopter) || !isDefined(level.helicopter_player)) return(false);
	if(level.helicopter.health <= 0) return(false);
	if(isDefined(team) && level.ex_teamplay && level.helicopter_player.pers["team"] == team) return(false);
	return(true);
}

//------------------------------------------------------------------------------
// Creation
//------------------------------------------------------------------------------
heliAvailable()
{
	self endon("kill_thread");

	if(isDefined(level.helicopter_player))
	{
		self iprintlnbold(&"SPECIALS_HELI_INUSE");
		return(false);
	}

	self.usedweapons = true;
	return(true);
}

heliCreate(owner)
{
	level.helicopter_player = owner;

	// get start and initial destination
	info = heliStartPos();

	// main model
	level.helicopter = spawn("script_model", info["start"]);
	level.helicopter setmodel( getDeviceModel("heli") );
	level.helicopter.angles = vectorToAngles(info["dest"] - info["start"]);

	// set other attributes
	level.helicopter.dest = info["dest"];
	level.helicopter.prevdest = info["start"];
	level.helicopter.nextdest = level.helicopter.dest;
	level.helicopter.owner = owner;
	level.helicopter.ownernum = owner getEntityNumber();
	level.helicopter.team = owner.pers["team"];
	level.helicopter.maxspeed = 25;
	level.helicopter.maxaccel = 1;
	level.helicopter.tilt = 0;
	level.helicopter.health = level.ex_heli_maxhealth;
	level.helicopter.moving = false;
	level.helicopter.hovering = false;
	level.helicopter.deccelerating = false;
	level.helicopter.adjusting = false;
	level.helicopter.targeting = false;
	level.helicopter.exiting = false;
	level.helicopter.firing = false;
	level.helicopter.status = 0;

	// attach missiles
	if(level.ex_heli_missile)
	{
		level.helicopter.missiles = [];
		level.helicopter.missiles[0] = spawnstruct();
		level.helicopter.missiles[0].fired = false;
		level.helicopter.missiles[0].model = spawn("script_model", (0,0,0));
		level.helicopter.missiles[0].model setmodel( getDeviceModel("heli_missile") );
		level.helicopter.missiles[0].model linkto(level.helicopter, "tag_rocket_l1", (0,0,0), (0,0,0));
		if(level.ex_heli_missile > 1)
		{
			level.helicopter.missiles[1] = spawnstruct();
			level.helicopter.missiles[1].fired = false;
			level.helicopter.missiles[1].model = spawn("script_model", (0,0,0));
			level.helicopter.missiles[1].model setmodel( getDeviceModel("heli_missile") );
			level.helicopter.missiles[1].model linkto(level.helicopter, "tag_rocket_r1", (0,0,0), (0,0,0));
			if(level.ex_heli_missile > 2)
			{
				level.helicopter.missiles[2] = spawnstruct();
				level.helicopter.missiles[2].fired = false;
				level.helicopter.missiles[2].model = spawn("script_model", (0,0,0));
				level.helicopter.missiles[2].model setmodel( getDeviceModel("heli_missile") );
				level.helicopter.missiles[2].model linkto(level.helicopter, "tag_rocket_l2", (0,0,0), (0,0,0));
				if(level.ex_heli_missile > 3)
				{
					level.helicopter.missiles[3] = spawnstruct();
					level.helicopter.missiles[3].fired = false;
					level.helicopter.missiles[3].model = spawn("script_model", (0,0,0));
					level.helicopter.missiles[3].model setmodel( getDeviceModel("heli_missile") );
					level.helicopter.missiles[3].model linkto(level.helicopter, "tag_rocket_r2", (0,0,0), (0,0,0));
				}
			}
		}
	}

	// tubes
	if(level.ex_heli_tube)
	{
		level.helicopter.tubes = [];
		level.helicopter.tubes[0] = spawnstruct();
		level.helicopter.tubes[0].fired = 0;
		if(level.ex_heli_tube > 1)
		{
			level.helicopter.tubes[1] = spawnstruct();
			level.helicopter.tubes[1].fired = 0;
		}
	}

	// play looping sound
	level.helicopter playloopsound("heli_fly_loop");

	// helicopter main logic
	level.helicopter thread heliThink();
}

//------------------------------------------------------------------------------
// Deletion
//------------------------------------------------------------------------------
heliDelete()
{
	self notify("heli_deleting");

	level thread levelStopUsingPerk(self.ownernum, "heli");
	level.helicopter_player = undefined;

	if(level.ex_heli_missile)
	{
		for(i = 0; i < self.missiles.size; i++)
			if(!self.missiles[i].fired) self.missiles[i].model delete();
	}

	self.exiting = true;
	self waittill("heli_rotorstop");

	self stoploopsound();
	self delete();
}

//------------------------------------------------------------------------------
// Main logic
//------------------------------------------------------------------------------
heliThink()
{
	self endon("heli_crashing");
	self endon("heli_deleting");

	thread rotateMainRotor(1);
	thread rotateTailRotor(1);
	wait( level.ex_fps_frame );
	thread heliMoveMonitor();
	thread heliTargetMonitor();
	if(level.ex_heli_dust) thread heliDust();

	timer = level.ex_heli_timer;
	while(timer > 0)
	{
		wait( [[level.ex_fpstime]](1) );
		timer--;
		if(self.health <= 0) thread heliCrash();
	}

	self.status = 1;
}

rotateMainRotor(time)
{
	while(!self.exiting)
	{
		playfxontag(level.ex_effect["heli_mainrotor"], self, "tag_rotormain");
		wait( [[level.ex_fpstime]](time) );
	}

	wait( [[level.ex_fpstime]](0.1) );
	self notify("heli_rotorstop");
}

rotateTailRotor(time)
{
	while(!self.exiting)
	{
		playfxontag(level.ex_effect["heli_tailrotor"], self, "tag_rotorrear");
		wait( [[level.ex_fpstime]](time) );
	}

	wait( [[level.ex_fpstime]](0.1) );
	self notify("heli_rotorstop");
}

heliMoveMonitor()
{
	self endon("heli_crashing");

	spawnpoints = getentarray("mp_dm_spawn", "classname");
	if(!spawnpoints.size) spawnpoints = getentarray("mp_tdm_spawn", "classname");
	if(!spawnpoints.size) self.status = 1;

	if(level.ex_heli_crash) crashcheck = randomInt(3) + 5;
		else crashcheck = 0;

	mindist = int((game["playArea_Width"] + game["playArea_Length"]) / 4);

	while(1)
	{
		// check for owner: must be there (player or spectator) or must be playing
		if(!isPlayer(self.owner)) self.status = 1;
		//if(!isPlayer(self.owner) || self.owner.sessionstate != "playing") self.status = 1;

		// prepare for exit if needed
		if(self.status)
		{
			self.dest = heliExitPos();
			self.status = 2;
		}
		else
		{
			// get next destination while moving to current destination
			thread heliDestinationPos(spawnpoints, mindist, 400);

			// wait while hovering (target mode)
			while(self.adjusting) wait( [[level.ex_fpstime]](1) );
		}

		// prepare path to destination
		self.angles = anglesNormalize(self.angles);
		va = vectorToAngles(self.dest - self.origin);
		forwardvector = anglesToForward(va);

		fdot = dotNormalize(vectorDot(anglesToForward(self.angles), forwardvector));
		fddot = acos(fdot); // difference in degrees
		rdot = dotNormalize(vectorDot(anglesToRight(self.angles), forwardvector));
		rddot = acos(rdot);
		dist = distance(self.dest, self.origin);

		pitch = 0;
		roll = 0;
		if(fdot < 0) // more than 90 degrees turn
		{
			if(rdot < 0) // rotate hard right
			{
				if(dist > 2000)
				{
					pitch = -10;
					sidevector = anglestoup(va + (0,0,45));
					pos1 = self.origin + ([[level.ex_vectorscale]](sidevector, 200));
				}
				else
				{
					roll = -10;
					sidevector = anglestoup(va + (0,0,65));
					pos1 = self.origin + ([[level.ex_vectorscale]](sidevector, 300));
				}
			}
			else // rotate hard left
			{
				if(dist > 2000)
				{
					pitch = -10;
					sidevector = anglestoup(va + (0,0,-45));
					pos1 = self.origin + ([[level.ex_vectorscale]](sidevector, 200));
				}
				else
				{
					roll = 10;
					sidevector = anglestoup(va + (0,0,-65));
					pos1 = self.origin + ([[level.ex_vectorscale]](sidevector, 300));
				}
			}
		}
		else // less than 90 degrees turn
		{
			if(rdot < 0 && fddot > 45) // rotate soft right
			{
				pitch = 8;
				sidevector = anglestoright(va + (0,45,0));
				pos1 = self.origin + ([[level.ex_vectorscale]](sidevector, 100));
			}
			else if(rdot > 0 && fddot > 45) // rotate soft left
			{
				pitch = 8;
				sidevector = anglestoright(va + (0,-45,0));
				pos1 = self.origin + ([[level.ex_vectorscale]](sidevector, 100));
			}
			else
			{
				pitch = 4;
				pos1 = self.origin;
			}
		}
		pos2 = self.dest + ([[level.ex_vectorscale]](forwardvector, 0 - 200));

		// move towards destination
		thread cubicBezierCurve(self.origin, pos1, pos2, self.dest);

		// tilt, roll and rotate towards destination
		if(pitch < 0)
		{
			self rotatePitch(pitch, 0.5);
			wait( [[level.ex_fpstime]](0.5) );
			pitch = 8;
		}
		if(roll != 0)
		{
			self rotateRoll(roll, 0.5);
			wait( [[level.ex_fpstime]](0.5) );
		}
		self rotateTo(va + (pitch,0,0), 2);
		self waittill("rotatedone");
		while(!self.deccelerating) wait( level.ex_fps_frame );
		self rotateTo(va, 2, 1, 1);

		// random crash
		if(crashcheck)
		{
			crashcheck--;
			if(!crashcheck && (randomInt(100) <= level.ex_heli_crash)) thread heliCrash();
		}

		// wait while still moving
		while(self.moving) wait( [[level.ex_fpstime]](1) );

		self.prevdest = self.dest;
		self.dest = self.nextdest;
		if(self.status == 2 || !isDefined(self.dest)) break;

		// start hovering for a while
		self.hovering = true;
		self thread heliHover();
		wait( [[level.ex_fpstime]](randomInt(5) + 3) );
		self.hovering = false;
		self notify("heli_stophover");
	}

	thread heliDelete();
}

heliStartPos()
{
	startpos = undefined;
	bestdist = 0;
	bestlist = [];

	zcheck = game["playArea_Min"][2] + 800;
	if(game["mapArea_Max"][2] > 1000 && zcheck < game["mapArea_Max"][2]) zpos = zcheck;
		else zpos = game["mapArea_Max"][2] - 200;

	endpos = (game["playArea_CentreX"], game["playArea_CentreY"], zpos);

	for(i = 0; i < 360; i += 10)
	{
		forwardpos = endpos + [[level.ex_vectorscale]](anglestoforward((0, i, 0)), 30000);
		trace = bulletTrace(endpos, forwardpos, true, self);
		if(trace["fraction"] != 1) frontpos = trace["position"];
			else frontpos = forwardpos;

		if(!isDefined(startpos)) startpos = frontpos;
		dist = distance(endpos, frontpos);
		if(dist > bestdist)
		{
			bestdist = dist;
			startpos = frontpos;
		}
		if(trace["surfacetype"] == "default") bestlist[bestlist.size] = frontpos;
	}
	if(bestlist.size) startpos = bestlist[randomInt(bestlist.size)];

	info["start"] = startpos;
	info["dest"] = endpos;
	return(info);
}

heliExitPos()
{
	endpos = undefined;
	bestdist = 0;
	bestlist = [];

	for(i = 0; i < 360; i += 10)
	{
		forwardpos = self.origin + [[level.ex_vectorscale]](anglestoforward((0, i, 0)), 30000);
		trace = bulletTrace(self.origin, forwardpos, true, self);
		if(trace["fraction"] != 1) frontpos = trace["position"];
			else frontpos = forwardpos;

		if(!isDefined(endpos)) endpos = frontpos;
		dist = distance(self.origin, frontpos);
		if(dist > bestdist)
		{
			bestdist = dist;
			endpos = frontpos;
		}
		if(trace["surfacetype"] == "default") bestlist[bestlist.size] = frontpos;
	}

	if(bestlist.size) return(bestlist[randomInt(bestlist.size)]);
		else return(endpos);
}

heliDestinationPos(destarray, mindist, margin)
{
	self.nextdest = undefined;
	bestdist = 0;
	bestlist = [];

	for(i = 0; i < destarray.size; i++)
	{
		index = randomInt(destarray.size);
		dest = destarray[index].origin;
		dest = (dest[0], dest[1], self.origin[2]);
		dist = distance(self.dest, dest);

		vf = anglesToForward(vectorToAngles(dest - self.dest));
		frontpos = self.dest + [[level.ex_vectorscale]](vf, dist);
		frontpos = bulletTrace(self.dest, frontpos, false, self)["position"] + [[level.ex_vectorscale]](vf, 0 - margin);
		if(frontpos == self.prevdest || frontpos == self.dest) continue;

		dist = distance(self.dest, frontpos);
		if(dist > bestdist)
		{
			self.nextdest = frontpos;
			bestdist = dist;
		}
		if(dist >= mindist) bestlist[bestlist.size] = frontpos;
		if(bestlist.size >= 10) break;
		if(i % 5 == 0) waittillframeend;
	}

	if(bestlist.size) self.nextdest = bestlist[randomInt(bestlist.size)];
}

heliHover()
{
	self endon("heli_stophover");
	self endon("heli_crashing");
	self endon("heli_deleting");

	original_pos = self.origin;

	while(1)
	{
		for(i = 0; i < 5; i++)
		{
			x = 0;
			x -= randomInt(15);
			x += randomInt(15);
			y = 0;
			y -= randomInt(15);
			y += randomInt(15);
			z = 0;
			z -= randomInt(15);
			z += randomInt(15);
			dest = self.origin + (x,y,z);

			movetime = randomFloat(1) + 1;
			self moveto(dest, movetime, 0, .5);
			wait( [[level.ex_fpstime]](movetime) );
		}

		dist = distance(self.origin, original_pos);
		movetime = dist * 0.0254;
		if(movetime < 1) movetime = 1;
		self moveto(original_pos, movetime, 0, .5);
		wait( [[level.ex_fpstime]](movetime) );
	}
}

heliDust()
{
	self endon("heli_crashing");
	self endon("heli_deleting");

	while(1)
	{
		fxtime = 1;
		if(self.deccelerating || self.hovering)
		{
			forwardvector = anglesToUp( (180, self.angles[1], 0) );
			forwardpos = self.origin + ([[level.ex_vectorscale]](forwardvector, 20000));
			trace = bulletTrace(self.origin, forwardpos, false, self);
			if(trace["fraction"] != 1)
			{
				fxtime = heliDustSurface(trace["surfacetype"]);
				if(fxtime) playfx(level.ex_effect["heli_dust"], trace["position"]);
					else fxtime = 1;
			}
		}

		wait( [[level.ex_fpstime]](fxtime) );
	}
}

heliDustSurface(surface)
{
	switch(surface)
	{
		case "asphalt":
		case "concrete":
		case "rock": return(3);
		case "foliage":
		case "grass":
		case "mud": return(2);
		case "gravel":
		case "dirt":
		case "sand": return(1);
		default: return(0);
	}
}

//------------------------------------------------------------------------------
// Targeting
//------------------------------------------------------------------------------
heliTargetMonitor()
{
	self endon("heli_crashing");
	self endon("heli_deleting");

	interval = .2;
	gun_target = self;
	gun_delay = 0;
	missile_delay = 50; // 10 seconds, 10 * (5 * .2)
	tube_delay = 100; // 20 seconds, 20 * (5 * .2)

	while(!self.status)
	{
		old_target = gun_target;
		gun_target = self;
		missile_target = undefined;
		tube_target = self;

		wait( [[level.ex_fpstime]](interval) );

		// gun targeting
		if(level.ex_heli_gun && !self.moving)
		{
			if(gun_delay) gun_delay--;
			if(!gun_delay)
			{
				players = level.players;
				for(i = 0; i < players.size; i++)
				{
					player = players[i];
					if(isPlayer(player) && player.sessionstate == "playing" && player.pers["team"] != self.team)
					{
						if(isPlayer(old_target) && isAlive(old_target) && heliCanSee(old_target, level.ex_heli_gun_fov, level.ex_heli_gun_radius))
						{
							gun_target = old_target;
							break;
						}
						else if(heliCanSee(player, level.ex_heli_gun_fov, level.ex_heli_gun_radius))
						{
							if(!isPlayer(gun_target)) gun_target = player;
							if(closer(self.origin, player.origin, gun_target.origin)) gun_target = player;
						}
					}
				}

				if(isPlayer(gun_target))
				{
					self.adjusting = true;
					va = vectorToAngles(gun_target.origin + (0, 0, 40) - self.origin);
					dot = dotNormalize(vectorDot(anglesToForward(self.angles), anglesToForward(va)));
					time = abs(acos(dot) * .01998);
					if(time <= 0) time = 0.1;
					if(gun_target == old_target && !self.targeting) self rotateTo((0, va[1], 0), time);
						else thread heliTargeting(va, time);

					wait( level.ex_fps_frame );

					if(!self.targeting) thread fireGun(gun_target);
				}
				else self.adjusting = false;
			}
		}

		// missile targeting
		if(level.ex_heli_missile)
		{
			if(missile_delay) missile_delay--;
			if(!missile_delay)
			{
				target_info = heliGetTarget(self.owner, self.team);
				if(isDefined(target_info.target))
				{
					thread fireMissile(target_info);
					missile_delay = 50;
				}
			}
		}

		// grenade tubes targeting
		if(level.ex_heli_tube)
		{
			if(tube_delay) tube_delay--;
			if(!tube_delay)
			{
				players = level.players;
				for(i = 0; i < players.size; i++)
				{
					player = players[i];
					if(isPlayer(player) && player.sessionstate == "playing" && player.pers["team"] != self.team)
					{
						if(heliCanSee(player, level.ex_heli_tube_fov, level.ex_heli_tube_radius))
						{
							if(player == gun_target || (isDefined(missile_target) && player == missile_target)) continue;
							if(!isPlayer(tube_target)) tube_target = player;
							thread fireTube(player);
							wait( [[level.ex_fpstime]](0.2) );
						}
					}
				}

				if(isPlayer(tube_target)) tube_delay = 100; // 20 seconds, 20 * (5 * .2)
			}
		}
	}

	self.adjusting = false;
}

heliGetTarget(owner, team)
{
	self endon("heli_crashing");
	self endon("heli_deleting");

	target_info = spawnstruct();
	target_info.target = undefined;
	target_info.target_type = -1;

	// GMls
	if((level.ex_heli_missile_target & 64) == 64)
	{
		if(isDefined(level.gmls))
		{
			for(i = 0; i < level.gmls.size; i++)
			{
				if(extreme\_ex_specials_gml::perkValidateAsTarget(i, team))
				{
					target_info.target = level.gmls[i].tube;
					target_info.target_type = 64;
					break;
				}
			}
		}
	}

	// flaks
	if(!isDefined(target_info.target) && (level.ex_heli_missile_target & 32) == 32)
	{
		if(isDefined(level.flaks))
		{
			for(i = 0; i < level.flaks.size; i++)
			{
				if(extreme\_ex_specials_flak::perkValidateAsTarget(i, team))
				{
					target_info.target = level.flaks[i].guns;
					target_info.target_type = 32;
					break;
				}
			}
		}
	}

	// gunships
	if(!isDefined(target_info.target) && (level.ex_heli_missile_target & 16) == 16)
	{
		if(extreme\_ex_main_gunship::gunshipValidateAsTarget(team))
		{
			target_info.target = level.gunship;
			target_info.target_type = 16;
		}

		if(!isDefined(target_info.target) && extreme\_ex_specials_gunship::perkValidateAsTarget(team))
		{
			target_info.target = level.gunship_special;
			target_info.target_type = 16;
		}
	}

	// heli
	//if(!isDefined(target_info.target) && (level.ex_heli_missile_target & 8) == 8)

	// WMD airplanes
	if(!isDefined(target_info.target) && (level.ex_heli_missile_target & 4) == 4)
	{
		for(i = 0; i < level.planes.size; i++)
		{
			if(extreme\_ex_controller_airtraffic::planeValidateAsTarget(i, level.PLANE_PURP_WMD, team))
			{
				target_info.target = level.planes[i].model;
				target_info.target_type = 4;
				break;
			}
		}
	}

	// ambient airplanes
	if(!isDefined(target_info.target) && (level.ex_heli_missile_target & 2) == 2)
	{
		for(i = 0; i < level.planes.size; i++)
		{
			if(extreme\_ex_controller_airtraffic::planeValidateAsTarget(i, level.PLANE_PURP_AMBIENT, team))
			{
				target_info.target = level.planes[i].model;
				target_info.target_type = 2;
				break;
			}
		}
	}

	// players
	if(!isDefined(target_info.target) && (level.ex_heli_missile_target & 1) == 1)
	{
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(isPlayer(player) && player.sessionstate == "playing" && (!level.ex_teamplay || player.pers["team"] != team))
			{
				if(heliCanSee(player, level.ex_heli_missile_fov, level.ex_heli_missile_radius))
				{
					if(!isPlayer(target_info.target)) target_info.target = player;
					if(!closer(self.origin, player.origin, target_info.target.origin)) target_info.target = player;
				}
			}
		}

		target_info.target_type = 1;
	}

	return(target_info);
}

heliTargeting(vector, time)
{
	self endon("heli_deleting");

	if(self.targeting) return;
	self.targeting = true;

	self rotateTo((0, vector[1], 0), time);
	wait( [[level.ex_fpstime]](time) );
	self.targeting = false;
}

heliCanSee(player, fov, radius)
{
	self endon("heli_deleting");

	cansee = false;
	dir = vectorNormalize(player.origin + (0, 0, 40) - self.origin);
	dot = dotNormalize(vectorDot(anglesToForward(self.angles), dir));
	viewangle = acos(dot);
	if(viewangle <= fov)
	{
		if(distance(player.origin, self.origin) <= radius)
		{
			cansee = (bullettrace(self.origin + (0, 0, 10), player.origin + (0, 0, 10), false, self)["fraction"] == 1);
			if(!cansee) cansee = (bullettrace(self.origin + (0, 0, 10), player.origin + (0, 0, 40), false, self)["fraction"] == 1);
			if(!cansee && isDefined(player.ex_eyemarker)) cansee = (bullettrace(self.origin + (0, 0, 10), player.ex_eyemarker.origin, false, self)["fraction"] == 1);
		}
	}
	return(cansee);
}

//------------------------------------------------------------------------------
// Gun handling
//------------------------------------------------------------------------------
fireGun(target)
{
	if(isPlayer(self.owner) && self.owner.sessionstate != "spectator" && (!level.ex_teamplay || self.owner.pers["team"] == self.team))
	{
		thread fireGunFX();

		// device info to pass on
		device_info = [[level.ex_devInfo]](self.owner, self.team);
		device_info.dodamage = true;
		device_info.damage = 20;
		device_info.hitdir = anglesToForward(vectorToAngles(target.origin - self.origin));

		// do damage
		target thread [[level.ex_devPlayer]]("heli_gun", device_info);
	}
}

fireGunFX()
{
	if(self.firing) return;
	self.firing = true;
	numshots = 15;
	self playsound("heli_firegun");
	for(i = 0; i < numshots; i++)
	{
		playfxontag(level.ex_effect["heli_gun"], self, "tag_gun");
		wait( [[level.ex_fpstime]](0.075) );
	}
	self.firing = false;
}

//------------------------------------------------------------------------------
// Missile handling
//------------------------------------------------------------------------------
fireMissile(target_info)
{
	missile = 0;
	while(1)
	{
		if(!self.missiles[missile].fired) break;
		missile++;
		if(missile == 4) return;
	}

	self.missiles[missile].fired = true;
	self.missiles[missile].model unlink();

	// device info to pass on
	device_info = [[level.ex_devInfo]](self.owner, self.team);

	// fire missile
	self.missiles[missile].model thread [[level.ex_devMissile]]("heli_missile", device_info, target_info, ::heliGetTarget);
}

//------------------------------------------------------------------------------
// Grenade tube handling
//------------------------------------------------------------------------------
fireTube(target)
{
	tube = 0;
	while(1)
	{
		if(self.tubes[tube].fired <= 19) break;
		tube++;
		if(tube == 2) return;
	}

	self.tubes[tube].fired++;

	self playsound("heli_firetube");
	if(tube == 0) playfxontag(level.ex_effect["heli_tube"], self, "tag_tube_l");
		else playfxontag(level.ex_effect["heli_tube"], self, "tag_tube_r");

	delay = (distance(self.origin, target.origin) / 100) * 0.05;
	wait( [[level.ex_fpstime]](delay) );

	// handle explosion and damage
	impactloc = spawn("script_origin", target.origin);

	if(isPlayer(self.owner) && self.owner.sessionstate != "spectator" && (!level.ex_teamplay || self.owner.pers["team"] == self.team))
	{
		// device info to pass on
		device_info = [[level.ex_devInfo]](self.owner, self.team);
		device_info.dodamage = true;

		// device explosion
		impactloc thread [[level.ex_devExplode]]("heli_tube", device_info);
	}
	else impactloc [[level.ex_devEffects]]("heli_tube");

	wait(1);
	impactloc delete();
}

//------------------------------------------------------------------------------
// Crash handling
//------------------------------------------------------------------------------
heliCrash()
{
	wait(0);
	self notify("heli_crashing");

	playfx(level.ex_effect["plane_explosion"], self.origin);
	self playsound("plane_explosion_1");

	self stoploopsound();
	self playloopsound("heli_damaged_loop");

	shortest = 50000;
	endpos = undefined;
	for(i = 0; i < 360; i += 10)
	{
		forwardpos = self.origin + [[level.ex_vectorscale]](anglestoforward((0, i, 0)), 30000);
		trace = bulletTrace(self.origin, forwardpos, true, self);
		if(trace["fraction"] != 1) temppos = trace["position"];
			else temppos = forwardpos;

		if(!isDefined(endpos)) endpos = temppos;
		dist = distance(self.origin, temppos);
		if(dist < shortest)
		{
			shortest = dist;
			endpos = temppos;
		}
	}

	time = calctime(endpos, self.origin, 10);
	self moveto(endpos, time * 0.999, 0, 0);

	thread heliCrashFX();
	thread heliCrashRotate();

	wait( [[level.ex_fpstime]](time) );

	self notify("heli_stopfx");
	playfx(level.ex_effect["plane_explosion"], self.origin);
	heliDelete();
}

heliCrashRotate()
{
	self endon("heli_stopfx");

	while(1)
	{
		self rotateyaw(-360, 3);
		wait( [[level.ex_fpstime]](3) );
	}
}

heliCrashFX()
{
	self endon("heli_stopfx");

	while(1)
	{
		playfx(level.ex_effect["planecrash_smoke"], self.origin);
		playfxontag(level.ex_effect["planecrash_smoke"], self, "tag_rotorrear");
		if(randomInt(100) < 10) self playsound("plane_explosion_2");
		wait( [[level.ex_fpstime]](0.4) );
	}
}

//------------------------------------------------------------------------------
// Bezier curves
//------------------------------------------------------------------------------
linearBezierCurve(pos0, pos1)
{
	self endon("heli_crashing");

	self.moving = true;
	node = pointLinearBezierCurve(pos0, pos1, 1);
	length = distance(pos0, node);
	if(length > 3000) speed = self.maxspeed;
		else if(length > 1500) speed = 15;
			else speed = 5;
	movetime = calcTime(self.origin, node, speed);
	self moveto(node, movetime);
	wait( [[level.ex_fpstime]](movetime * .999) );
	self.moving = false;
}

quadraticBezierCurve(pos0, pos1, pos2)
{
	self endon("heli_crashing");

	self.moving = true;

	length = 0;
	nodes = 10;
	node_prev = pos0;
	for(i = 1; i <= nodes; i++)
	{
		node = pointQuadraticBezierCurve(pos0, pos1, pos2, i / nodes);
		x_diff = node[0] - node_prev[0];
		y_diff = node[1] - node_prev[1];
		length += sqrt( (x_diff * x_diff) + (y_diff * y_diff) );
		node_prev = node;
	}

	node_length = 100;
	nodes = int(length / node_length);
	if(!nodes) nodes = 2;

	if(length > 3000) speed = self.maxspeed;
		else if(length > 1500) speed = 15;
			else speed = 5;
	movetime = (node_length * 0.0254) / speed;
	if(movetime <= 0) movetime = 0.5;

	for(i = 1; i <= nodes; i++)
	{
		node = pointQuadraticBezierCurve(pos0, pos1, pos2, i / nodes);
		if(i * node_length >= length - 500)
		{
			self.deccelerating = true;
			movetime_dec = movetime + (i / nodes) + (i / nodes) * movetime;
			self moveto(node, movetime_dec);
			wait( [[level.ex_fpstime]](movetime_dec * .999) );
		}
		else
		{
			self moveto(node, movetime);
			wait( [[level.ex_fpstime]](movetime * .999) );
		}
	}

	self.deccelerating = false;
	self.moving = false;
}

cubicBezierCurve(pos0, pos1, pos2, pos3)
{
	self endon("heli_crashing");

	self.moving = true;

	length = 0;
	nodes = 10;
	node_prev = pos0;
	for(i = 1; i <= nodes; i++)
	{
		node = pointCubicBezierCurve(pos0, pos1, pos2, pos3, i / nodes);
		x_diff = node[0] - node_prev[0];
		y_diff = node[1] - node_prev[1];
		length += sqrt( (x_diff * x_diff) + (y_diff * y_diff) );
		node_prev = node;
	}

	node_length = 100;
	nodes = int(length / node_length);
	if(!nodes) nodes = 2;

	if(length > 3000) speed = self.maxspeed;
		else if(length > 1500) speed = 15;
			else speed = 5;
	movetime = (node_length * 0.0254) / speed;
	if(movetime <= 0) movetime = 0.5;

	for(i = 1; i <= nodes; i++)
	{
		node = pointCubicBezierCurve(pos0, pos1, pos2, pos3, i / nodes);
		if(i * node_length >= length - 500)
		{
			self.deccelerating = true;
			movetime_dec = movetime + (i / nodes) + (i / nodes) * movetime;
			self moveto(node, movetime_dec);
			wait( [[level.ex_fpstime]](movetime_dec * .999) );
		}
		else
		{
			self moveto(node, movetime);
			wait( [[level.ex_fpstime]](movetime * .999) );
		}
	}

	self.deccelerating = false;
	self.moving = false;
}

pointLinearBezierCurve(pos0, pos1, t)
{
	// B(t) = (1-t)*P0 + t*P1
	tvec = [[level.ex_vectorscale]](pos0, 1 - t) +
	       [[level.ex_vectorscale]](pos1, t);
	vec = (tvec[0], tvec[1], tvec[2]);
	return(vec);
}

pointQuadraticBezierCurve(pos0, pos1, pos2, t)
{
	// B(t) = (1-t)^2*P0 + 2(1-t)*t*P1 + t^2*P2
	tvec = [[level.ex_vectorscale]](pos0, pow(1 - t, 2)) +
	       [[level.ex_vectorscale]](pos1, t * (2 * (1 - t))) +
	       [[level.ex_vectorscale]](pos2, pow(t, 2));
	vec = (tvec[0], tvec[1], tvec[2]);
	return(vec);
}

pointCubicBezierCurve(pos0, pos1, pos2, pos3, t)
{
	// B(t) = (1-t)^3*P0 + 3(1-t)^2*t*P1 + 3(1-t)*t^2*P2 + t^3*P3
	tvec = [[level.ex_vectorscale]](pos0, pow(1 - t, 3)) +
	       [[level.ex_vectorscale]](pos1, t * (3 * pow(1 - t, 2))) +
	       [[level.ex_vectorscale]](pos2, pow(t, 2) * (3 * (1 - t))) +
	       [[level.ex_vectorscale]](pos3, pow(t, 3));
	vec = (tvec[0], tvec[1], tvec[2]);
	return(vec);
}

//------------------------------------------------------------------------------
// Damage
//------------------------------------------------------------------------------
onFrameInit()
{
	weapon = self getcurrentweapon();
	if(weapon == self getweaponslotweapon("primary")) weaponslot = "primary";
		else weaponslot = "primaryb";
	ammo = self getWeaponslotclipammo(weaponslot);

	self.heli_weapon = weapon;
	self.heli_ammo = ammo;

	[[level.ex_registerPlayerEvent]]("onFrame", ::onFrame, true);
}

onFrame(eventID)
{
	self endon("kill_thread");

	if(isDefined(level.helicopter_player) && level.helicopter.health > 0)
	{
		weapon = self getcurrentweapon();
		if(weapon == self getweaponslotweapon("primary")) weaponslot = "primary";
			else weaponslot = "primaryb";
		ammo = self getWeaponslotclipammo(weaponslot);

		if(self attackbuttonpressed())
		{
			if(ammo < self.heli_ammo && canDamageHeli(weapon))
			{
				endorigin = self.ex_eyemarker.origin + [[level.ex_vectorscale]](anglesToForward(self getplayerangles()), 10000);
				trace = bulletTrace(self.ex_eyemarker.origin, endorigin, true, self);
				if(trace["fraction"] != 1 && isDefined(trace["entity"]) && trace["entity"] == level.helicopter)
				{
					dist = distance(self.ex_eyemarker.origin, trace["position"]);
					level.helicopter.health -= maxDamageHeli(3, weapon, dist);
					if(level.ex_heli_damagehud) thread hudDamageHeli(2);
				}
			}
		}

		self.heli_weapon = weapon;
		self.heli_ammo = ammo;
	}

	[[level.ex_enablePlayerEvent]]("onFrame", eventID);
}

canDamageHeli(weapon)
{
	if(self.pers["team"] == level.helicopter.team) return(false);

	if(!extreme\_ex_weapons::isWeaponType(weapon, "valid")) return(false);
	if(extreme\_ex_weapons::isWeaponType(weapon, "knife")) return(false);
	if(extreme\_ex_weapons::isWeaponType(weapon, "rl")) return(false);
	if(extreme\_ex_weapons::isWeaponType(weapon, "ft")) return(false);
	if(weapon == "gunship_nuke_mp") return(false);
	return(true);
}

maxDamageHeli(modifier, weapon, dist)
{
	distmod = int(100 - (dist / 100));
	if(distmod <= 0) return(0);

	maxdamage = 0;
	if(weapon == "gunship_105mm_mp") maxdamage = 500;
	else if(weapon == "gunship_40mm_mp") maxdamage = 250;
	else if(weapon == "gunship_25mm_mp") maxdamage = 50;
	else if(extreme\_ex_weapons::isWeaponType(weapon, "sniperlr")) maxdamage = 100;
	else if(extreme\_ex_weapons::isWeaponType(weapon, "snipersr")) maxdamage = 50;
	else if(extreme\_ex_weapons::isWeaponType(weapon, "rifle")) maxdamage = 40;
	else if(extreme\_ex_weapons::isWeaponType(weapon, "mg")) maxdamage = 30;
	else if(extreme\_ex_weapons::isWeaponType(weapon, "smg")) maxdamage = 20;
	else if(extreme\_ex_weapons::isWeaponType(weapon, "shotgun")) maxdamage = 10;
	else if(extreme\_ex_weapons::isWeaponType(weapon, "pistol")) maxdamage = 5;

	damage = int((maxdamage / modifier) * (distmod / 100));
	if(damage > level.helicopter.health) damage = level.helicopter.health;
	return(damage);
}

hudDamageHeli(duration)
{
	self endon("kill_thread");

	hud_index = playerHudIndex("helidamage_bar");
	if(hud_index == -1)
	{
		if(isDefined(level.helicopter)) status = level.helicopter.health;
			else status = 0;
		if(status <= 0) return;
		status = int( (114 / level.ex_heli_maxhealth) * status);
		if(status <= 0) return;

		hud_index = playerHudCreate("helidamage_back", -53, -160, 1, (1,1,1), 1, 2, "right", "bottom", "right", "bottom", false, false);
		if(hud_index == -1) return;
		playerHudSetGroup(hud_index, "heli");
		playerHudSetShader(hud_index, "hud_temperature_gauge", 35, 150);

		hud_index = playerHudCreate("helidamage_bar", -65, -192, 1, hudDamageHeliColor(), 1, 1, "right", "bottom", "right", "bottom", false, false);
		if(hud_index == -1) return;
		playerHudSetGroup(hud_index, "heli");
		playerHudSetShader(hud_index, "white", 10, status);
		playerHudDestroyTimed(hud_index, duration);
		playerHudSetUpdateProc(hud_index, ::hudDamageHeliUpdate, 0.1);
	}
	else playerHudDestroyTimed(hud_index, duration);
}

hudDamageHeliColor()
{
	if(isDefined(level.helicopter)) status = level.helicopter.health;
		else status = 0;
	perc = int( (100 / level.ex_heli_maxhealth) * status);
	if(perc > 50) return( (0,1,0) );
	if(perc > 40) return( (1,1,0) );
	if(perc > 20) return( (1,0.5,0) );
	return( (1,0,0) );
}

hudDamageHeliUpdate(hud_index)
{
	self endon("kill_thread");

	if(isDefined(level.helicopter))
	{
		status = level.helicopter.health;
		if(status <= 0) return;
		status = int( (114 / level.ex_heli_maxhealth) * status);
		if(status <= 0) return;

		playerHudSetShader(hud_index, "white", 10, status);
		playerHudSetColor(hud_index, hudDamageHeliColor());
	}
}

//------------------------------------------------------------------------------
// Close proximity explosion callback
//------------------------------------------------------------------------------
cpxHeli(dev_index, cpx_flag, origin, owner, team, entity)
{
	if(perkValidateAsTarget(team))
	{
		switch(cpx_flag)
		{
			case 1:
				dist = int( distance(origin, level.helicopter.origin) );
				if(dist <= level.ex_devices[dev_index].range)
				{
					damage = int(level.ex_devices[dev_index].maxdamage * ((level.ex_devices[dev_index].range - dist) / level.ex_devices[dev_index].range));
					level.helicopter.health -= damage;
				}
				break;
			case 2:
				break;
			case 4:
				if(entity == level.helicopter)
				{
					level.helicopter.health -= level.ex_devices[dev_index].maxdamage;
					return;
				}
				break;
			case 8:
				level.helicopter.health -= level.ex_devices[dev_index].maxdamage;
				break;
			case 16:
				level.helicopter.health -= level.ex_devices[dev_index].maxdamage;
				break;
			case 32:
				level.helicopter.health -= level.ex_devices[dev_index].maxdamage;
				break;
		}
	}
}
