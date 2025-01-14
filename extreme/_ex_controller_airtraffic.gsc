#include extreme\_ex_main_utils;

atcInit()
{
	if(level.ex_log_atc) logprint("ATC: Initializing air traffic controller\n");

	// array for tracking slots and plane entities
	level.planes = [];
	level.planeslots = [];
	level.planetypes = [];

	level.PLANE_PURP_ANY = 0;
	level.PLANE_PURP_AMBIENT = 1;
	level.PLANE_PURP_AMMO = 2;
	level.PLANE_PURP_WMD = 3;

	level.PLANE_TYPE_ANY = 0;
	level.PLANE_TYPE_FIGHTER = 1;
	level.PLANE_TYPE_BOMBER = 2;

	level.PLANE_TEAM_ANY = 0;
	level.PLANE_TEAM_NEUTRAL = 1;
	level.PLANE_TEAM_AXIS = 2;
	level.PLANE_TEAM_ALLIES = 3;

	// no ATC needed if all related features are turned off
	if(!level.ex_planes && !level.ex_wmd && (!level.ex_amc || !level.ex_amc_chutein)) return;

	// fighters
	index = registerFighter("stuka", level.PLANE_TEAM_AXIS, "xmodel/vehicle_stuka_flying", "stuka_flyby_1", "stuka_flyby_2", "spitfire_flyby_1");
	index = registerFighter("spitfire", level.PLANE_TEAM_ALLIES, "xmodel/vehicle_spitfire_flying", "stuka_flyby_1", "stuka_flyby_2", "spitfire_flyby_1");
	index = registerFighter("mustang", level.PLANE_TEAM_ALLIES, "xmodel/vehicle_p51_mustang", "stuka_flyby_1", "stuka_flyby_2", "spitfire_flyby_1");

	// bombers
	index = registerBomber("condor", level.PLANE_TEAM_AXIS, "xmodel/vehicle_condor", "stuka_flyby_1", "stuka_flyby_2", "spitfire_flyby_1");
	index = registerBomber("mebelle", level.PLANE_TEAM_ALLIES, "xmodel/vehicle_mebelle", "stuka_flyby_1", "stuka_flyby_2", "spitfire_flyby_1");

	// var for tracking crashes
	if(!isDefined(game["ex_planescrashed"])) game["ex_planescrashed"] = 0;

	// register slot monitor event
	[[level.ex_registerLevelEvent]]("onSecond", ::onSecond, true);

	// device registration
	[[level.ex_devRequest]]("airplane", ::cpxAirplane);
}

//------------------------------------------------------------------------------
// Plane slot management
//------------------------------------------------------------------------------
onSecond(eventID)
{
	if(planesInSky() < level.ex_atc_maxplanes)
	{
		longest_time = -1;
		notify_slot = -1;
		notify_purp = 0;

		for(i = 0; i < level.planeslots.size; i++)
		{
			if(level.planeslots[i].inuse && level.planeslots[i].clearance)
			{
				time_past = getTime() - level.planeslots[i].time;
				if(level.planeslots[i].purp < notify_purp) continue;
				if(time_past > longest_time)
				{
					notify_slot = i;
					notify_purp = level.planeslots[i].purp;
					longest_time = time_past;
				}
			}
		}

		if(notify_slot != -1)
		{
			if(level.ex_log_atc) logprint("ATC: Plane in slot " + notify_slot + " got clearance\n");
			wait( [[level.ex_fpstime]](2 + randomInt(2)) );

			level notify("plane_clearance" + notify_slot);
			level.planeslots[notify_slot].inuse = 0;
			level.planeslots[notify_slot].pilot = undefined;
		}
	}

	[[level.ex_enableLevelEvent]]("onSecond", eventID);
}

planeSlot(purpose)
{
	index = -1;
	for(i = 0; i < level.planeslots.size; i++)
	{
		if(level.planeslots[i].inuse == 0)
		{
			index = i;
			break;
		}
	}

	if(index == -1)
	{
		index = level.planeslots.size;
		level.planeslots[index] = spawnstruct();
	}

	level.planeslots[index].inuse = 1;
	level.planeslots[index].purp = purpose;
	level.planeslots[index].time = getTime();
	level.planeslots[index].clearance = false;
	if(level.ex_log_atc) logprint("ATC: Allocating plane slot " + index + "\n");

	return(index);
}

planeClearance(index)
{
	level.planeslots[index].clearance = true;
	return("plane_clearance" + index);
}

//------------------------------------------------------------------------------
// Plane type registration
//------------------------------------------------------------------------------
registerFighter(name, team_id, xmodel, sound1, sound2, sound3)
{
	return( registerPlaneType(name, level.PLANE_TYPE_FIGHTER, team_id, xmodel, sound1, sound2, sound3) );
}

registerBomber(name, team_id, xmodel, sound1, sound2, sound3)
{
	return( registerPlaneType(name, level.PLANE_TYPE_BOMBER, team_id, xmodel, sound1, sound2, sound3) );
}

registerPlaneType(name, type, team_id, xmodel, sound1, sound2, sound3)
{
	if(!isDefined(name) || !isDefined(xmodel)) return;
	if(!isDefined(team_id)) team_id = level.PLANE_TEAM_ANY;

	index = level.planetypes.size;
	level.planetypes[index] = spawnstruct();
	level.planetypes[index].name = tolower(name);
	level.planetypes[index].type = type;
	level.planetypes[index].team_id = team_id;
	level.planetypes[index].xmodel = xmodel;

	level.planetypes[index].speed = randomIntRange(30, 35);
	if(type == level.PLANE_TYPE_FIGHTER) level.planetypes[index].speed = randomIntRange(35, 45);

	level.planetypes[index].sounds = [];
	if(isDefined(sound1)) registerPlaneSound(index, sound1);
	if(isDefined(sound2)) registerPlaneSound(index, sound2);
	if(isDefined(sound3)) registerPlaneSound(index, sound3);

	[[level.ex_PrecacheModel]](xmodel);

	return(index);
}

registerPlaneSound(index, sound)
{
	sound_index = level.planetypes[index].sounds.size;
	level.planetypes[index].sounds[sound_index] = sound;
}

//------------------------------------------------------------------------------
// Plane properties handling
//------------------------------------------------------------------------------
getTeamID(team)
{
	if(!isDefined(team)) return(level.PLANE_TEAM_NEUTRAL);
	if(team == "axis") return(level.PLANE_TEAM_AXIS);
	if(team == "allies") return(level.PLANE_TEAM_ALLIES);
	return(level.PLANE_TEAM_NEUTRAL);
}

getPlaneName(index)
{
	return(level.planetypes[index].name);
}

getPlaneType(index)
{
	return(level.planetypes[index].type);
}

getPlaneTeamID(index)
{
	return(level.planetypes[index].team_id);
}

getPlaneModel(index)
{
	return(level.planetypes[index].xmodel);
}

getPlaneSpeed(index)
{
	return(level.planetypes[index].speed);
}

getPlaneSound(index)
{
	array_size = level.planetypes[index].sounds.size;
	if(array_size) return( level.planetypes[index].sounds[ randomInt(array_size) ] );
		else return(undefined);
}

getPlaneByName(name, team_id)
{
	if(!isDefined(name)) return(undefined);
	return( getPlane(name, undefined, team_id) );
}

getPlaneByType(type, team_id)
{
	if(!isDefined(type)) type = level.PLANE_TYPE_ANY;
	return( getPlane(undefined, type, team_id) );
}

getPlaneByTeamID(team_id)
{
	if(!isDefined(team_id)) team_id = level.PLANE_TEAM_ANY;
	return( getPlane(undefined, undefined, team_id) );
}

getPlaneFighter(team_id)
{
	return( getPlane(undefined, level.PLANE_TYPE_FIGHTER, team_id) );
}

getPlaneBomber(team_id)
{
	return( getPlane(undefined, level.PLANE_TYPE_BOMBER, team_id) );
}

getPlane(name, type, team_id)
{
	if(isDefined(name)) name = tolower(name);

	planes = [];
	for(i = 0; i < level.planetypes.size; i++)
	{
		if(isDefined(name) && level.planetypes[i].name != name) continue;
		if(isDefined(type) && (type != level.PLANE_TYPE_ANY && level.planetypes[i].type != type)) continue;
		if(isDefined(team_id) && (team_id != level.PLANE_TEAM_ANY && level.planetypes[i].team_id != team_id)) continue;
		planes[planes.size] = i;
	}

	if(planes.size) return( planes[randomInt(planes.size)] );
		else return(undefined);
}

//------------------------------------------------------------------------------
// Plane management
//------------------------------------------------------------------------------
planeCreate(slot, type, owner, team, droppos, angle, speed)
{
	if(level.ex_log_atc) logprint("ATC: Creating plane in slot " + slot + "\n");
	if(!isDefined(type) || type == -1) type = level.PLANE_TYPE_ANY;

	purpose = level.planeslots[slot].purp;
	team_id = getTeamID(team);
	if(purpose == level.PLANE_PURP_AMBIENT && level.ex_planes != 3) team_id = level.PLANE_TEAM_NEUTRAL;

	if(team_id == level.PLANE_TEAM_NEUTRAL)
	{
		if(type == level.PLANE_TYPE_FIGHTER) type_index = getPlaneFighter(level.PLANE_TEAM_ANY);
			else if(type == level.PLANE_TYPE_BOMBER) type_index = getPlaneBomber(level.PLANE_TEAM_ANY);
				else type_index = getPlaneByTeamID(level.PLANE_TEAM_ANY);
	}
	else
	{
		if(type == level.PLANE_TYPE_FIGHTER) type_index = getPlaneFighter(team_id);
			else if(type == level.PLANE_TYPE_BOMBER) type_index = getPlaneBomber(team_id);
				else type_index = getPlaneByTeamID(team_id);
	}

	if(!isDefined(droppos)) droppos = getRandomPosPlayArea(400);
	if(!isDefined(angle)) angle = randomInt(360);

	// type identifier for targeting: 0 = ambient airstrike, 1 = ammocrate drop, 2 = WMD airstrike
	index = planeAllocate();
	level.planes[index].slot = slot;
	level.planes[index].purp = purpose;
	level.planes[index].pilot = self; // not the owner, but the entity allocating
	level.planes[index].owner = owner;
	level.planes[index].team = team;
	level.planes[index].team_id = team_id;
	level.planes[index].type = level.planetypes[type_index].type;;
	level.planes[index].xmodel = level.planetypes[type_index].xmodel;
	level.planes[index].speed = level.planetypes[type_index].speed;
	level.planes[index].sound = getPlaneSound(type_index);
	level.planes[index].route = getPlaneRoute(droppos, angle, 10000, 1000);
	level.planes[index].health = level.ex_planes_maxhealth;
	level.planes[index].insky = false;
	level.planes[index].crash = false;
	level.planes[index].crashed = false;
	level.planes[index].haspayload = false;
	level.planes[index].drop_notify = undefined;
	level.planes[index].crash_notify = undefined;
	level.planes[index].pilot_notify = undefined;
	level.planes[index].node_array = undefined;

	// payload reset
	if(!isDefined(level.planes[index].payload)) level.planes[index].payload = spawnstruct();
	level.planes[index].payload.droppos = droppos;
	level.planes[index].payload.targetpos = droppos;
	level.planes[index].payload.dev_index = -1;
	level.planes[index].payload.count = 1;
	level.planes[index].payload.dropping = false;
	level.planes[index].payload.dropped = false;
	level.planes[index].payload.dropdist = 1500;
	level.planes[index].payload.droprate = 0.2;
	level.planes[index].payload.dodamage = true;

	if(isDefined(speed)) level.planes[index].speed = speed;
	if(purpose == level.PLANE_PURP_WMD) level.planes[index].health = level.ex_wmd_planes_maxhealth;
	if(randomInt(100) < level.ex_atc_crashchance && game["ex_planescrashed"] < level.ex_atc_maxcrashes)
		level.planes[index].crash = true;

	return(index);
}

planeAddPayload(index, dev_id, targetpos, count, dodamage)
{
	if(level.planes[index].insky || level.planes[index].type != level.PLANE_TYPE_BOMBER) return;
	dev_index = [[level.ex_devIndex]](dev_id);
	if(dev_index == -1) return;

	if(level.ex_log_atc) logprint("ATC: Adding payload to plane in slot " + level.planes[index].slot + "\n");

	// minimum 1 payload
	if(!isDefined(count) || !count) count = 1;

	level.planes[index].haspayload = true;
	level.planes[index].payload.targetpos = targetpos;
	level.planes[index].payload.dev_index = dev_index;
	level.planes[index].payload.count = count;
	level.planes[index].payload.dropping = false;
	level.planes[index].payload.dropped = false;
	level.planes[index].payload.dodamage = dodamage;

	// drop distance
	if(level.planes[index].purp != level.PLANE_PURP_AMMO)
	{
		mapsquare = (game["mapArea_Width"] + game["mapArea_Length"]) / 2;
		mapheight = game["mapArea_Max"][2];
		if(mapsquare >= 8000 && mapheight >= 2000) dropdist = 2500;
			else if(mapsquare >= 7000 && mapheight >= 1500) dropdist = 2000;
				else dropdist = 1500;
		maxdist = distance(level.planes[index].route.startpos, level.planes[index].payload.droppos);
		if(maxdist < dropdist) dropdist = maxdist;
	}
	else dropdist = 500;

	// drop rate
	if(dropdist < 1000) droprate = 0.1;
		else droprate = 0.2;

	level.planes[index].payload.dropdist = dropdist;
	level.planes[index].payload.droprate = droprate;
}

planeAddNotify(index, drop_notify, crash_notify)
{
	if(isDefined(drop_notify)) level.planes[index].drop_notify = drop_notify;
	if(isDefined(crash_notify)) level.planes[index].crash_notify = crash_notify;
}

planeGo(index, pilot_notify)
{
	level endon("crash_plane" + index);

	if(level.ex_log_atc) logprint("ATC: Plane in slot " + level.planes[index].slot + " now waiting for clearance\n");

	// wait for slot clearance
	level waittill(planeClearance(level.planes[index].slot));

	level.planes[index].insky = true;
	level.planes[index].pilot_notify = pilot_notify;

	level.planes[index].model = spawn("script_model", level.planes[index].route.startpos);
	level.planes[index].model setModel(level.planes[index].xmodel);
	level.planes[index].model.angles = (0, level.planes[index].route.angle, 0);
	if(isDefined(level.planes[index].sound)) level.planes[index].model playloopsound(level.planes[index].sound);

	// handle payload
	if(level.planes[index].haspayload) level thread planeMonitorPayload(index);

	// handle crashes
	if(level.planes[index].crash || level.planes[index].health) level thread planeMonitorHealth(index);

	if(level.ex_log_atc) logprint("ATC: Plane in slot " + level.planes[index].slot + " on the move\n");

	// move airplane
	level.planes[index].model moveto(level.planes[index].route.endpos, calcTime(level.planes[index].route.startpos, level.planes[index].route.endpos, level.planes[index].speed));
	level.planes[index].model waittill("movedone");

	if(level.ex_log_atc) logprint("ATC: Plane in slot " + level.planes[index].slot + " is done\n");

	planeFree(index);
}

//------------------------------------------------------------------------------
// Plane payload handling
//------------------------------------------------------------------------------
planeMonitorPayload(index)
{
	level endon("ex_gameover");
	level endon("kill_plane" + index);
	level endon("crash_plane" + index);

	owner = level.planes[index].owner;
	startpos = level.planes[index].route.startpos;
	endpos = level.planes[index].route.endpos;
	droppos = level.planes[index].payload.droppos;
	targetpos = level.planes[index].payload.targetpos;

	while(!level.planes[index].payload.dropped)
	{
		wait( [[level.ex_fpstime]](0.1) );
		if(distance(droppos, level.planes[index].model.origin) < level.planes[index].payload.dropdist)
		{
			level.planes[index].payload.dropping = true;

			payload_drop = true;
			if(!isDefined(owner) || (level.ex_teamplay && isPlayer(owner) && owner.pers["team"] != level.planes[index].team) ) payload_drop = false;

			if(payload_drop)
			{
				if(!isDefined(level.planes[index].drop_notify))
				{
					if(level.planes[index].purp == level.PLANE_PURP_WMD && isPlayer(level.planes[index].owner)) level.planes[index].owner playTeamSoundOnPlayer("fire_away", 1);

					if(level.ex_log_atc) logprint("ATC: Plane in slot " + level.planes[index].slot + " dropping payload\n");

					bombcount = level.planes[index].payload.count;
					for(i = 0; i < bombcount; i++)
					{
						// make sure the plane is still there
						if(!isDefined(level.planes[index].model)) break;

						// drop point
						droppos = level.planes[index].model.origin;

						// impact point
						impactpos = getImpactPosPlane(index, targetpos, level.ex_wmd_airstrike_accuracy);
						if(!isDefined(impactpos)) continue;

						// device info to pass on
						device_info = [[level.ex_devInfo]](level.planes[index].owner, level.planes[index].team);
						device_info.origin = droppos;
						device_info.impactpos = impactpos;
						device_info.dodamage = level.planes[index].payload.dodamage;

						// fire device
						thread [[level.ex_devInbound]](level.planes[index].payload.dev_index, device_info);

						wait( [[level.ex_fpstime]](level.planes[index].payload.droprate) );
					}
				}
				else level.planes[index].pilot notify(level.planes[index].drop_notify, level.planes[index].model.origin);
			}

			level.planes[index].payload.dropping = false;
			level.planes[index].payload.dropped = true;
		}
	}
}

//------------------------------------------------------------------------------
// Plane crash handling
//------------------------------------------------------------------------------
planeMonitorHealth(index)
{
	level endon("ex_gameover");
	level endon("kill_plane" + index);

	crash = false;
	while(true)
	{
		wait( [[level.ex_fpstime]](0.1) );
		if(level.planes[index].haspayload && level.planes[index].payload.dropping) continue;

		if(level.planes[index].health <= 0) crash = true;
			else if(level.planes[index].crash && (distance(game["playArea_Centre"], level.planes[index].model.origin) < 5000)) crash = true;

		if(crash)
		{
			level.planes[index].health = 0;
			if(isDefined(level.planes[index].crash_notify)) level.planes[index].pilot notify(level.planes[index].crash_notify, level.planes[index].model.origin);
			level thread planeCrash(index, level.planes[index].speed);
			break;
		}
	}
}

planeCrashAll()
{
	for(i = 0; i < level.planes.size; i++)
		if(level.planes[i].inuse && level.planes[i].insky) level.planes[i].health = 0;
}

planeCrash(index, plane_speed)
{
	level notify("crash_plane" + index);

	if(level.ex_log_atc) logprint("ATC: Plane in slot " + level.planes[index].slot + " crashing\n");

	level.planes[index].crashed = true;
	game["ex_planescrashed"]++;

	plane = level.planes[index].model;
	plane.angles = anglesNormalize(plane.angles);
	plane thread planeCrashFX();

	// crash point (must be far enough to calculate bezier curve before reaching it)
	crashpos = posForward(plane.origin, plane.angles, 2000);

	// calculate bezier crash curve
	if(randomInt(100) < 75)
	{
		f1 = posForward(crashpos, plane.angles, 3000 + randomInt(2000));

		if(randomInt(2)) f2 = posLeft(f1, plane.angles, 1000 + randomInt(2000));
			else f2 = posRight(f1, plane.angles, 1000 + randomInt(2000));

		dest = posDown(f2, plane.angles, 0);
		if(dest[2] < game["mapArea_Min"][2]) dest = (dest[0], dest[1], game["mapArea_Min"][2] - 100);

		level.planes[index].node_array = plane quadraticBezier(20, crashpos, f1, dest, plane_speed, 30);
	}
	else
	{
		f1 = posForward(crashpos, plane.angles, 3000 + randomInt(2000));
		b1 = posBack(crashpos, plane.angles, 2000 + randomInt(3000));

		if(randomInt(2))
		{
			f2 = posLeft(f1, plane.angles, 4000 + randomInt(3000));
			if(randomInt(100) < 95) b2 = posLeft(b1, plane.angles, 2000 + randomInt(2000));
				else b2 = posRight(b1, plane.angles, 2000 + randomInt(2000));
		}
		else
		{
			f2 = posRight(f1, plane.angles, 4000 + randomInt(3000));
			if(randomInt(100) < 95) b2 = posRight(b1, plane.angles, 2000 + randomInt(2000));
				else b2 = posLeft(b1, plane.angles, 2000 + randomInt(2000));
		}

		dest = posDown(b2, plane.angles, 0);
		if(dest[2] < game["mapArea_Min"][2]) dest = (dest[0], dest[1], game["mapArea_Min"][2] - 100);

		level.planes[index].node_array = plane cubicBezier(40, crashpos, f1, f2, dest, plane_speed, 30);
	}

	// commence crashing
	plane thread moveBezier(level.planes[index].node_array, plane_speed, "crash_done");
	plane stoploopsound();
	plane playloopsound("plane_dive");

	// wait for crash to finish
	plane waittill("crash_done");
	plane notify("crashfx_done");

	plane stoploopsound();
	playfx(level.ex_effect["planecrash_explosion"], plane.origin);
	plane playsound("plane_explosion_" + (1 + randomInt(3)));
	wait( [[level.ex_fpstime]](0.5) );
	playfx(level.ex_effect["planecrash_ball"], plane.origin);
	wait( [[level.ex_fpstime]](5) );

	planeFree(index);
}

planeCrashFX()
{
	self endon("crashfx_done");

	playfx(level.ex_effect["plane_explosion"], self.origin);
	self playsound("plane_explosion_" + (1 + randomInt(3)));
	wait( [[level.ex_fpstime]](0.5) );

	playfx(level.ex_effect["plane_explosion"], self.origin);
	self playsound("plane_explosion_" + (1 + randomInt(3)));
	wait( [[level.ex_fpstime]](0.5) );

	while(1)
	{
		playfx(level.ex_effect["planecrash_smoke"], self.origin);
		if(randomInt(100) < 5)
		{
			playfx(level.ex_effect["plane_explosion"], self.origin);
			self playsound("plane_explosion_" + (1 + randomInt(3)));
		}
		wait( [[level.ex_fpstime]](0.25) );
	}
}

//------------------------------------------------------------------------------
// Supporting code
//------------------------------------------------------------------------------
planeAllocate()
{
	for(i = 0; i < level.planes.size; i++)
	{
		if(level.planes[i].inuse == 0)
		{
			level.planes[i].inuse = 1;
			return(i);
		}
	}

	level.planes[i] = spawnstruct();
	level.planes[i].inuse = 1;
	return(i);
}

planeFree(index)
{
	if(isDefined(level.planes[index].pilot_notify)) level.planes[index].pilot notify(level.planes[index].pilot_notify);
	level notify("kill_plane" + index);

	level.planes[index].model stoploopsound();
	level.planes[index].model delete();
	level.planes[index].inuse = 0;
}

planesInSky()
{
	insky = 0;
	for(i = 0; i < level.planes.size; i++)
		if(level.planes[i].inuse && level.planes[i].insky) insky++;
	return(insky);
}

planesInSkyNeutral()
{
	insky = 0;
	for(i = 0; i < level.planes.size; i++)
		if(level.planes[i].inuse && level.planes[i].insky && level.planes[i].team_id == level.PLANE_TEAM_NEUTRAL) insky++;
	return(insky);
}

planesInSkyAllies()
{
	insky = 0;
	for(i = 0; i < level.planes.size; i++)
		if(level.planes[i].inuse && level.planes[i].insky && level.planes[i].team_id == level.PLANE_TEAM_ALLIES) insky++;
	return(insky);
}

planesInSkyAxis()
{
	insky = 0;
	for(i = 0; i < level.planes.size; i++)
		if(level.planes[i].inuse && level.planes[i].insky && level.planes[i].team_id == level.PLANE_TEAM_AXIS) insky++;
	return(insky);
}

planeCheckEntity(entity, purpose, team)
{
	for(i = 0; i < level.planes.size; i++)
	{
		if(isDefined(purpose) && purpose != level.PLANE_PURP_ANY && level.planes[i].purp != purpose) continue;
		if(isDefined(team) && level.ex_teamplay && level.planes[i].team == team) continue;
		if(level.planes[i].inuse && level.planes[i].insky && level.planes[i].model == entity) return(i);
	}
	return(-1);
}

planeValidateAsTarget(index, purpose, team)
{
	if(!level.planes[index].inuse || !level.planes[index].insky) return(false);
	if(level.planes[index].health <= 0) return(false);
	if(isDefined(purpose) && purpose != level.PLANE_PURP_ANY && level.planes[index].purp != purpose) return(false);
	if(isDefined(team) && level.ex_teamplay && level.planes[index].team == team) return(false);
	return(true);
}

//------------------------------------------------------------------------------
// Close proximity explosion callback
//------------------------------------------------------------------------------
cpxAirplane(dev_index, cpx_flag, origin, owner, team, entity)
{
	for(i = 0; i < level.planes.size; i++)
	{
		if(planeValidateAsTarget(i, undefined, team))
		{
			switch(cpx_flag)
			{
				case 1:
					dist = int( distance(origin, level.planes[i].model.origin) );
					if(dist <= level.ex_devices[dev_index].range)
					{
						damage = int(level.ex_devices[dev_index].maxdamage * ((level.ex_devices[dev_index].range - dist) / level.ex_devices[dev_index].range));
						level.planes[i].health -= damage;
					}
					break;
				case 2:
					break;
				case 4:
					if(level.planes[i].model == entity)
					{
						level.planes[i].health -= level.ex_devices[dev_index].maxdamage;
						return;
					}
					break;
				case 8:
					level.planes[i].health -= level.ex_devices[dev_index].maxdamage;
					break;
				case 16:
					level.planes[i].health -= level.ex_devices[dev_index].maxdamage;
					break;
				case 32:
					level.planes[i].health -= level.ex_devices[dev_index].maxdamage;
					break;
			}
			wait( level.ex_fps_frame );
		}
	}
}
