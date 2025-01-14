#include extreme\_ex_controller_hud;
#include extreme\_ex_controller_devices;
#include extreme\_ex_weapons;

init()
{
	level.nadetracker = [];

	if(level.ex_nademon_throwback)
	{
		[[level.ex_PrecacheString]](&"WEAPON_THROWBACK");
		if(level.ex_nademon_throwback_indicator)
		{
			[[level.ex_PrecacheShader]]("waypoint_throwback_red");
			[[level.ex_PrecacheShader]]("waypoint_throwback_green");
		}
	}

	if(level.ex_teamplay)
	{
		game["satchel_allies"] = 0;
		game["satchel_axis"] = 0;
		game["frag_allies"] = 0;
		game["frag_axis"] = 0;
		game["smoke_allies"] = 0;
		game["smoke_axis"] = 0;
		game["fire_allies"] = 0;
		game["fire_axis"] = 0;
		game["gas_allies"] = 0;
		game["gas_axis"] = 0;
		game["super_allies"] = 0;
		game["super_axis"] = 0;
	}
	else
	{
		game["satchel_all"] = 0;
		game["frag_all"] = 0;
		game["smoke_all"] = 0;
		game["fire_all"] = 0;
		game["gas_all"] = 0;
		game["super_all"] = 0;
	}

	// register nade monitor event
	[[level.ex_registerLevelEvent]]("onFrame", ::onFrame, true);
}

initPost()
{
	// device registration
	frag_allies = getFragTypeAllies();
	dev_id = getGrenadeDevice(frag_allies);
	if(isWeaponType(frag_allies, "fire")) [[level.ex_devRequest]](dev_id, undefined, ::callbackFireDamage, frag_allies);
		else if(isWeaponType(frag_allies, "gas")) [[level.ex_devRequest]](dev_id, undefined, ::callbackGasDamage, frag_allies);
			else if(isWeaponType(frag_allies, "satchel")) [[level.ex_devRequest]](dev_id, undefined, undefined, frag_allies);
				else [[level.ex_devRequest]](dev_id);

	frag_axis = getFragTypeAxis();
	dev_id = getGrenadeDevice(frag_axis);
	if(isWeaponType(frag_axis, "fire")) [[level.ex_devRequest]](dev_id, undefined, ::callbackFireDamage, frag_axis);
		else if(isWeaponType(frag_axis, "gas")) [[level.ex_devRequest]](dev_id, undefined, ::callbackGasDamage, frag_axis);
			else if(isWeaponType(frag_axis, "satchel")) [[level.ex_devRequest]](dev_id, undefined, undefined, frag_axis);
				else [[level.ex_devRequest]](dev_id);

	smoke_allies = getSmokeTypeAllies();
	dev_id = getGrenadeDevice(smoke_allies);
	if(isWeaponType(smoke_allies, "fire")) [[level.ex_devRequest]](dev_id, undefined, ::callbackFireDamage, smoke_allies);
		else if(isWeaponType(smoke_allies, "gas")) [[level.ex_devRequest]](dev_id, undefined, ::callbackGasDamage, smoke_allies);
			else if(isWeaponType(smoke_allies, "satchel")) [[level.ex_devRequest]](dev_id, undefined, undefined, smoke_allies);
				else [[level.ex_devRequest]](dev_id);

	smoke_axis = getSmokeTypeAxis();
	dev_id = getGrenadeDevice(smoke_axis);
	if(isWeaponType(smoke_axis, "fire")) [[level.ex_devRequest]](dev_id, undefined, ::callbackFireDamage, smoke_axis);
		else if(isWeaponType(smoke_axis, "gas")) [[level.ex_devRequest]](dev_id, undefined, ::callbackGasDamage, smoke_axis);
			else if(isWeaponType(smoke_axis, "satchel")) [[level.ex_devRequest]](dev_id, undefined, undefined, smoke_axis);
				else [[level.ex_devRequest]](dev_id);
}

onFrame(eventID)
{
	nades = getentarray("grenade", "classname");
	for(i = 0; i < nades.size; i ++)
	{
		nade = nades[i];
		if(!isDefined(nade.monitored))
		{
			nade.monitored = true;
			nade thread nadeDispatcher();
		}
	}

	[[level.ex_enableLevelEvent]]("onFrame", eventID);
}

nadeDispatcher()
{
	index = nadeAllocate();
	level.nadetracker[index].explode_contact = false;

	players = level.players;
	for(i = 0; i < players.size; i ++)
	{
		player = players[i];
		if(self isTouching(player))
		{
			level.nadetracker[index].owner = player;
			if(!isDefined(player.pers["isbot"])) level.nadetracker[index].explode_contact = player useButtonPressed();
			break;
		}
	}

	if(!isDefined(level.nadetracker[index].owner))
	{
		nadeFree(index);
		return;
	}

	if(!isAlive(level.nadetracker[index].owner) && isDefined(level.nadetracker[index].owner.pers["isbot"]))
	{
		if(isDefined(self)) self delete();
		nadeFree(index);
		return;
	}

	level.nadetracker[index].entity = self;
	level.nadetracker[index].entity_no = self getEntityNumber();
	level.nadetracker[index].timer = int(3.5 / level.ex_fps_frame);
	level.nadetracker[index].exploding = false;
	level.nadetracker[index].pickedup = false;
	level.nadetracker[index].weapon = level.nadetracker[index].owner getCurrentOffhand();
	if(level.ex_teamplay) level.nadetracker[index].team = level.nadetracker[index].owner.pers["team"];
		else level.nadetracker[index].team = "all";

	if(isWeaponType(level.nadetracker[index].weapon, "frag") || isWeaponType(level.nadetracker[index].weapon, "perkfrag"))
	{
		level.nadetracker[index].classname = "frag";
		level.nadetracker[index].classgroup = "frag";

		if(level.ex_teamplay && (level.ex_nademon_warn & 1) == 1)
			level.nadetracker[index].owner thread maps\mp\gametypes\_quickmessages::quickwarning("frag", 480, true, true);

		level thread monitorFragNade(index);
	}
	else if(isWeaponType(level.nadetracker[index].weapon, "fire"))
	{
		level.nadetracker[index].classname = "fire";
		if(isWeaponType(level.nadetracker[index].weapon, "fragspecial")) level.nadetracker[index].classgroup = "fragspecial";
			else level.nadetracker[index].classgroup = "smokespecial";

		if(level.ex_teamplay && (level.ex_nademon_warn & 2) == 2)
			level.nadetracker[index].owner thread maps\mp\gametypes\_quickmessages::quickwarning("frag", 480, true, true);

		level thread monitorFireNade(index);
	}
	else if(isWeaponType(level.nadetracker[index].weapon, "gas"))
	{
		level.nadetracker[index].classname = "gas";
		if(isWeaponType(level.nadetracker[index].weapon, "fragspecial")) level.nadetracker[index].classgroup = "fragspecial";
			else level.nadetracker[index].classgroup = "smokespecial";

		if(level.ex_teamplay && (level.ex_nademon_warn & 4) == 4)
			level.nadetracker[index].owner thread maps\mp\gametypes\_quickmessages::quickwarning("frag", 480, true, true);

		level thread monitorGasNade(index);
	}
	else if(isWeaponType(level.nadetracker[index].weapon, "satchel"))
	{
		level.nadetracker[index].classname = "satchel";
		if(isWeaponType(level.nadetracker[index].weapon, "fragspecial")) level.nadetracker[index].classgroup = "fragspecial";
			else level.nadetracker[index].classgroup = "smokespecial";
		level.nadetracker[index].timer = int(5 / level.ex_fps_frame);

		if(level.ex_teamplay && (level.ex_nademon_warn & 8) == 8)
			level.nadetracker[index].owner thread maps\mp\gametypes\_quickmessages::quickwarning("frag", 480, true, true);

		level thread monitorSatchelCharge(index);
	}
	else if(isWeaponType(level.nadetracker[index].weapon, "smoke") || isWeaponType(level.nadetracker[index].weapon, "perksmoke"))
	{
		level.nadetracker[index].classname = "smoke";
		level.nadetracker[index].classgroup = "smoke";
		level.nadetracker[index].timer = int(5 / level.ex_fps_frame);

		if(level.ex_teamplay && (level.ex_nademon_warn & 16) == 16)
			level.nadetracker[index].owner thread maps\mp\gametypes\_quickmessages::quickwarning("smoke", 480, true, true);

		level thread monitorSmokeNade(index);
	}
	else if(isWeaponType(level.nadetracker[index].weapon, "super"))
	{
		level.nadetracker[index].classname = "super";
		level.nadetracker[index].classgroup = "super";

		if(level.ex_teamplay && (level.ex_nademon_warn & 1) == 1)
			level.nadetracker[index].owner thread maps\mp\gametypes\_quickmessages::quickwarning("frag", 480, true, true);

		level thread monitorSuperNade(index);
	}
}

nadeAllocate()
{
	for(i = 0; i < level.nadetracker.size; i++)
	{
		if(level.nadetracker[i].inuse == 0)
		{
			level.nadetracker[i].inuse = 1;
			return(i);
		}
	}

	level.nadetracker[i] = spawnstruct();
	level.nadetracker[i].notification = "nade" + i;
	level.nadetracker[i].inuse = 1;
	return(i);
}

nadeFree(index)
{
	level notify(level.nadetracker[index].notification);
	level.nadetracker[index].inuse = 0;
}

//------------------------------------------------------------------------------
// Frag nades
//------------------------------------------------------------------------------
monitorFragNade(index)
{
	level endon("ex_gameover");

	if(level.ex_nademon_frag && !isDefined(level.nadetracker[index].owner.ex_throwback))
	{
		active = game["frag_" + level.nadetracker[index].team];
		if(active >= level.ex_nademon_frag)
		{
			if(level.ex_nademon_frag_maxwarn) level.nadetracker[index].owner iprintlnbold(&"WEAPON_MAX_FRAG_GRENADE");
			count = level.nadetracker[index].owner getAmmoCount(level.nadetracker[index].weapon);
			level.nadetracker[index].owner setWeaponClipAmmo(level.nadetracker[index].weapon, count + 1);
			if(isDefined(level.nadetracker[index].entity)) level.nadetracker[index].entity delete();
			nadeFree(index);
			return;
		}

		game["frag_" + level.nadetracker[index].team] = game["frag_" + level.nadetracker[index].team] + 1;
		thread duramodFragNade(index);
	}

	origin = level.nadetracker[index].entity.origin;
	origin1 = (0, 0, 0);
	throwback = (level.ex_nademon_throwback & 1 == 1);
	surfacetype = "none";

	while(isDefined(level.nadetracker[index].entity))
	{
		origin = level.nadetracker[index].entity.origin;

		if(level.ex_nademon_frag_eoc && level.nadetracker[index].explode_contact && origin1 != (0, 0, 0))
		{
			x = 2 * origin[0] - origin1[0];
			y = 2 * origin[1] - origin1[1];
			z = 2 * origin[2] - origin1[2];
			virtorigin = (x, y, z);
			trace = bullettrace(origin, virtorigin, true, undefined);
			if(trace["fraction"] != 1)
			{
				level.nadetracker[index].exploding = true;
				surfacetype = trace["surfacetype"];
				break;
			}
		}

		if(throwback && origin == origin1)
		{
			throwback = false;
			if(level.nadetracker[index].timer >= 20) thread throwbackMain(index, origin);
		}
		origin1 = origin;

		wait( level.ex_fps_frame );
		level.nadetracker[index].timer--;
		if(!level.nadetracker[index].timer) break;
	}

	if(!level.nadetracker[index].pickedup)
	{
		dev_id = getGrenadeDevice(level.nadetracker[index].weapon);
		if(level.nadetracker[index].exploding)
		{
			if(isDefined(level.nadetracker[index].entity)) level.nadetracker[index].entity delete();
			impactloc = spawn("script_origin", origin);

			// device info to pass on
			device_info = [[level.ex_devInfo]](level.nadetracker[index].owner, level.nadetracker[index].team);
			device_info.dodamage = true;

			// device explosion
			impactloc thread [[level.ex_devExplode]](dev_id, device_info);
			wait(1);
			impactloc delete();
		}
		else
		{
			// device info to pass on
			device_info = [[level.ex_devInfo]](level.nadetracker[index].owner, level.nadetracker[index].team);
			device_info.origin = origin;

			// device queue
			level thread [[level.ex_devQueue]](dev_id, device_info);
		}
	}

	while(isDefined(level.nadetracker[index].entity)) wait(1);
	nadeFree(index);
}

duramodFragNade(index)
{
	level endon("nade_" + index);

	team = level.nadetracker[index].team;
	duration = 3.5 * (level.ex_nademon_frag_duramod / 100);
	wait( [[level.ex_fpstime]](duration) );
	game["frag_" + team] = game["frag_" + team] - 1;
}

//------------------------------------------------------------------------------
// Napalm (Fire) nades
//------------------------------------------------------------------------------
monitorFireNade(index)
{
	level endon("ex_gameover");

	if(level.ex_nademon_fire && !isDefined(level.nadetracker[index].owner.ex_throwback))
	{
		active = game["fire_" + level.nadetracker[index].team];
		if(active >= level.ex_nademon_fire)
		{
			if(level.ex_nademon_fire_maxwarn) level.nadetracker[index].owner iprintlnbold(&"WEAPON_MAX_FIRE_GRENADE");
			count = level.nadetracker[index].owner getAmmoCount(level.nadetracker[index].weapon);
			level.nadetracker[index].owner setWeaponClipAmmo(level.nadetracker[index].weapon, count + 1);
			if(isDefined(level.nadetracker[index].entity)) level.nadetracker[index].entity delete();
			nadeFree(index);
			return;
		}

		game["fire_" + level.nadetracker[index].team] = game["fire_" + level.nadetracker[index].team] + 1;
		thread duramodFireNade(index);
	}

	origin = level.nadetracker[index].entity.origin;
	origin1 = (0, 0, 0);
	throwback = (level.ex_nademon_throwback & 2 == 2);
	surfacetype = "none";

	while(isDefined(level.nadetracker[index].entity))
	{
		origin = level.nadetracker[index].entity.origin;

		if(throwback && origin == origin1)
		{
			throwback = false;
			if(level.nadetracker[index].timer >= 20) thread throwbackMain(index, origin);
		}
		origin1 = origin;

		wait( level.ex_fps_frame );
		level.nadetracker[index].timer--;
		if(!level.nadetracker[index].timer) break;
	}

	if(!level.nadetracker[index].pickedup && !level.nadetracker[index].exploding)
	{
		if(level.nadetracker[index].classgroup == "smokespecial")
		{
			if(isDefined(level.nadetracker[index].entity)) level.nadetracker[index].entity delete();
			dev_id = getGrenadeDevice(level.nadetracker[index].weapon);
			impactloc = spawn("script_origin", origin);

			// device info to pass on
			device_info = [[level.ex_devInfo]](level.nadetracker[index].owner, level.nadetracker[index].team);
			device_info.dodamage = true;

			// device explosion
			impactloc thread [[level.ex_devExplode]](dev_id, device_info);
			wait(1);
			impactloc delete();
		}
	}

	while(isDefined(level.nadetracker[index].entity)) wait(1);
	nadeFree(index);
}

duramodFireNade(index)
{
	level endon("nade_" + index);

	team = level.nadetracker[index].team;
	duration = 20 * (level.ex_nademon_fire_duramod / 100);
	wait( [[level.ex_fpstime]](duration) );
	game["fire_" + team] = game["fire_" + team] - 1;
}

//------------------------------------------------------------------------------
// Gas nades
//------------------------------------------------------------------------------
monitorGasNade(index)
{
	level endon("ex_gameover");

	if(level.ex_nademon_gas && !isDefined(level.nadetracker[index].owner.ex_throwback))
	{
		active = game["gas_" + level.nadetracker[index].team];
		if(active >= level.ex_nademon_gas)
		{
			if(level.ex_nademon_gas_maxwarn) level.nadetracker[index].owner iprintlnbold(&"WEAPON_MAX_GAS_GRENADE");
			count = level.nadetracker[index].owner getAmmoCount(level.nadetracker[index].weapon);
			level.nadetracker[index].owner setWeaponClipAmmo(level.nadetracker[index].weapon, count + 1);
			if(isDefined(level.nadetracker[index].entity)) level.nadetracker[index].entity delete();
			nadeFree(index);
			return;
		}

		game["gas_" + level.nadetracker[index].team] = game["gas_" + level.nadetracker[index].team] + 1;
		thread duramodGasNade(index);
	}

	origin = level.nadetracker[index].entity.origin;
	origin1 = (0, 0, 0);
	throwback = (level.ex_nademon_throwback & 4 == 4);
	surfacetype = "none";

	while(isDefined(level.nadetracker[index].entity))
	{
		origin = level.nadetracker[index].entity.origin;

		if(throwback && origin == origin1)
		{
			throwback = false;
			if(level.nadetracker[index].timer >= 20) thread throwbackMain(index, origin);
		}
		origin1 = origin;

		wait( level.ex_fps_frame );
		level.nadetracker[index].timer--;
		if(!level.nadetracker[index].timer) break;
	}

	if(!level.nadetracker[index].pickedup && !level.nadetracker[index].exploding)
	{
		if(level.nadetracker[index].classgroup == "smokespecial")
		{
			if(isDefined(level.nadetracker[index].entity)) level.nadetracker[index].entity delete();
			dev_id = getGrenadeDevice(level.nadetracker[index].weapon);
			impactloc = spawn("script_origin", origin);

			// device info to pass on
			device_info = [[level.ex_devInfo]](level.nadetracker[index].owner, level.nadetracker[index].team);
			device_info.dodamage = true;

			// device explosion
			impactloc thread [[level.ex_devExplode]](dev_id, device_info);
			wait(1);
			impactloc delete();
		}
	}

	while(isDefined(level.nadetracker[index].entity)) wait(1);
	nadeFree(index);
}

duramodGasNade(index)
{
	level endon("nade_" + index);

	team = level.nadetracker[index].team;
	duration = 20 * (level.ex_nademon_gas_duramod / 100);
	wait( [[level.ex_fpstime]](duration) );
	game["gas_" + team] = game["gas_" + team] - 1;
}

//------------------------------------------------------------------------------
// Satchel charges
//------------------------------------------------------------------------------
monitorSatchelCharge(index)
{
	level endon("ex_gameover");

	if(level.ex_nademon_satchel && !isDefined(level.nadetracker[index].owner.ex_throwback))
	{
		active = game["satchel_" + level.nadetracker[index].team];
		if(active >= level.ex_nademon_satchel)
		{
			if(level.ex_nademon_satchel_maxwarn) level.nadetracker[index].owner iprintlnbold(&"WEAPON_MAX_SATCHEL_CHARGE");
			count = level.nadetracker[index].owner getAmmoCount(level.nadetracker[index].weapon);
			level.nadetracker[index].owner setWeaponClipAmmo(level.nadetracker[index].weapon, count + 1);
			if(isDefined(level.nadetracker[index].entity)) level.nadetracker[index].entity delete();
			nadeFree(index);
			return;
		}

		game["satchel_" + level.nadetracker[index].team] = game["satchel_" + level.nadetracker[index].team] + 1;
		thread duramodSatchelCharge(index);
	}

	origin = level.nadetracker[index].entity.origin;
	origin1 = (0, 0, 0);
	throwback = (level.ex_nademon_throwback & 8 == 8);
	surfacetype = "none";

	while(isDefined(level.nadetracker[index].entity))
	{
		origin = level.nadetracker[index].entity.origin;

		if(level.ex_nademon_satchel_eoc && level.nadetracker[index].explode_contact && origin1 != (0, 0, 0))
		{
			x = 2 * origin[0] - origin1[0];
			y = 2 * origin[1] - origin1[1];
			z = 2 * origin[2] - origin1[2];
			virtorigin = (x, y, z);
			trace = bullettrace(origin, virtorigin, true, undefined);
			if(trace["fraction"] != 1)
			{
				level.nadetracker[index].exploding = true;
				surfacetype = trace["surfacetype"];
				break;
			}
		}

		if(throwback && origin == origin1)
		{
			throwback = false;
			if(level.nadetracker[index].timer >= 20) thread throwbackMain(index, origin);
		}
		origin1 = origin;

		wait( level.ex_fps_frame );
		level.nadetracker[index].timer--;
		if(!level.nadetracker[index].timer) break;
	}

	if(!level.nadetracker[index].pickedup)
	{
		dev_id = getGrenadeDevice(level.nadetracker[index].weapon);
		if(level.nadetracker[index].exploding || level.nadetracker[index].classgroup == "smokespecial")
		{
			if(isDefined(level.nadetracker[index].entity)) level.nadetracker[index].entity delete();
			impactloc = spawn("script_origin", origin);

			// device info to pass on
			device_info = [[level.ex_devInfo]](level.nadetracker[index].owner, level.nadetracker[index].team);
			device_info.dodamage = true;

			// device explosion
			impactloc [[level.ex_devExplode]](dev_id, device_info);
			wait(1);
			impactloc delete();
		}
		else
		{
			// device info to pass on
			device_info = [[level.ex_devInfo]](level.nadetracker[index].owner, level.nadetracker[index].team);
			device_info.origin = origin;

			// device queue
			level thread [[level.ex_devQueue]](dev_id, device_info);
		}
	}

	while(isDefined(level.nadetracker[index].entity)) wait(1);
	nadeFree(index);
}

duramodSatchelCharge(index)
{
	level endon("nade_" + index);

	team = level.nadetracker[index].team;
	duration = 5 * (level.ex_nademon_satchel_duramod / 100);
	wait( [[level.ex_fpstime]](duration) );
	game["satchel_" + team] = game["satchel_" + team] - 1;
}

//------------------------------------------------------------------------------
// Smoke nades
//------------------------------------------------------------------------------
monitorSmokeNade(index)
{
	level endon("ex_gameover");

	if(level.ex_nademon_smoke)
	{
		active = game["smoke_" + level.nadetracker[index].team];
		if(active >= level.ex_nademon_smoke)
		{
			if(level.ex_nademon_smoke_maxwarn) level.nadetracker[index].owner iprintlnbold(&"WEAPON_MAX_SMOKE_GRENADE");
			count = level.nadetracker[index].owner getAmmoCount(level.nadetracker[index].weapon);
			level.nadetracker[index].owner setWeaponClipAmmo(level.nadetracker[index].weapon, count + 1);
			if(isDefined(level.nadetracker[index].entity)) level.nadetracker[index].entity delete();
			nadeFree(index);
			return;
		}

		game["smoke_" + level.nadetracker[index].team] = game["smoke_" + level.nadetracker[index].team] + 1;
		thread duramodSmokeNade(index);
	}

	origin1 = (0, 0, 0);
	while(isDefined(level.nadetracker[index].entity))
	{
		origin = level.nadetracker[index].entity.origin;
		if(origin == origin1) break;
		origin1 = origin;
		wait( level.ex_fps_frame );
		level.nadetracker[index].timer--;
		if(!level.nadetracker[index].timer) break;
	}

	if(isDefined(level.nadetracker[index].entity)) level.nadetracker[index].entity delete();
	dev_id = getGrenadeDevice(level.nadetracker[index].weapon);
	impactloc = spawn("script_origin", origin1);
	impactloc thread [[level.ex_devEffects]](dev_id);
	wait(1);
	impactloc delete();
	nadeFree(index);
}

duramodSmokeNade(index)
{
	level endon("nade_" + index);

	team = level.nadetracker[index].team;
	if(isWeaponType(level.nadetracker[index].weapon, "smokevip")) duration = 85;
		else duration = 45;
	duration = duration * (level.ex_nademon_smoke_duramod / 100);
	wait( [[level.ex_fpstime]](duration) );
	game["smoke_" + team] = game["smoke_" + team] - 1;
}

//------------------------------------------------------------------------------
// Super nades
//------------------------------------------------------------------------------
monitorSuperNade(index)
{
	level endon("ex_gameover");

	origin = level.nadetracker[index].entity.origin;
	origin1 = (0, 0, 0);
	throwback = (level.ex_nademon_throwback & 16 == 16);
	surfacetype = "none";

	while(isDefined(level.nadetracker[index].entity))
	{
		origin = level.nadetracker[index].entity.origin;

		if(level.ex_supernade_eoc && level.nadetracker[index].explode_contact && origin1 != (0, 0, 0))
		{
			x = 2 * origin[0] - origin1[0];
			y = 2 * origin[1] - origin1[1];
			z = 2 * origin[2] - origin1[2];
			virtorigin = (x, y, z);
			trace = bullettrace(origin, virtorigin, true, undefined);
			if(trace["fraction"] != 1)
			{
				level.nadetracker[index].exploding = true;
				surfacetype = trace["surfacetype"];
				break;
			}
		}

		if(throwback && origin == origin1)
		{
			throwback = false;
			if(level.nadetracker[index].timer >= 20) thread throwbackMain(index, origin);
		}
		origin1 = origin;

		wait( level.ex_fps_frame );
		level.nadetracker[index].timer--;
		if(!level.nadetracker[index].timer) break;
	}

	if(!level.nadetracker[index].pickedup)
	{
		dev_id = getGrenadeDevice(level.nadetracker[index].weapon);
		if(level.nadetracker[index].exploding)
		{
			if(isDefined(level.nadetracker[index].entity)) level.nadetracker[index].entity delete();
			impactloc = spawn("script_origin", origin);

			// device info to pass on
			device_info = [[level.ex_devInfo]](level.nadetracker[index].owner, level.nadetracker[index].team);
			device_info.dodamage = true;

			// device explosion
			impactloc [[level.ex_devExplode]](dev_id, device_info);
			wait(1);
			impactloc delete();
		}
		else
		{
			// device info to pass on
			device_info = [[level.ex_devInfo]](level.nadetracker[index].owner, level.nadetracker[index].team);
			device_info.origin = origin;

			// device queue
			level thread [[level.ex_devQueue]](dev_id, device_info);
		}
	}

	while(isDefined(level.nadetracker[index].entity)) wait(1);
	nadeFree(index);
}

//------------------------------------------------------------------------------
// Throw Back Nades
//------------------------------------------------------------------------------
throwbackMain(index, origin)
{
	while(isDefined(level.nadetracker[index].entity))
	{
		wait( level.ex_fps_frame );

		if(!level.nadetracker[index].timer) break;

		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			if(!isDefined(level.nadetracker[index].entity)) break;
			if(!level.nadetracker[index].timer) break;

			player = players[i];
			if(isAlive(player) && player.sessionstate == "playing")
			{
				if(isDefined(player.ex_throwback)) continue;
				if(level.ex_teamplay && !level.ex_nademon_throwback_team && player.pers["team"] == level.nadetracker[index].team) continue;

				dist = distance(player.origin, origin);
				if(player useButtonPressed() && dist < level.ex_nademon_throwback_pickup)
				{
					offset = (0,0,16); // Stand
					if(player.ex_stance == 1) offset = (0,0,2); // Crouch
					if(player.ex_stance == 2) offset = (0,0,-27); // Prone

					dot = vectordot(anglesToForward(player getPlayerAngles()), anglesToForward(vectorToAngles(vectorNormalize((player getEye() + offset) - origin)))) * -1;
					if(dot >= 0.8)
					{
						player.ex_throwback = true;
						player thread throwbackMonitor(index);
						level.nadetracker[index].pickedup = true;
						if(isDefined(level.nadetracker[index].entity)) level.nadetracker[index].entity delete();
						break;
					}
				}

				if(level.ex_nademon_throwback_indicator)
				{
					if(dist < level.ex_nademon_throwback_indicator)
					{
						waypoint = "waypoint_throwback_red";
						if(dist < level.ex_nademon_throwback_pickup) waypoint = "waypoint_throwback_green";
						hud_index = player playerHudCreate("throwback_wp" + level.nadetracker[index].entity_no, origin[0], origin[1], 0.8, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
						if(hud_index != -1)
						{
							player playerHudSetShader(hud_index, waypoint, 9, 9);
							player playerHudSetWaypoint(hud_index, origin[2] + 10, true);
						}
					}
					else player playerHudDestroy("throwback_wp" + level.nadetracker[index].entity_no);
				}
			}
		}
	}

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isDefined(player)) continue;
		if(player.sessionstate == "playing") player playerHudDestroy("throwback_wp" + level.nadetracker[index].entity_no);
	}
}

throwbackMonitor(index)
{
	self endon("disconnect");

	// kill running duramod thread
	level notify("nade_" + index);

	// save some properties before the nadetracker record is freed
	owner = level.nadetracker[index].owner;
	team = level.nadetracker[index].team;
	weapon = level.nadetracker[index].weapon;
	classname = level.nadetracker[index].classname;
	classgroup = level.nadetracker[index].classgroup;

	// adjust limit
	game[classname + "_" + team]--;

	// save and remove existing nades
	save_nades = [];
	switch(classgroup)
	{
		// frag slot
		case "frag":
		case "fragspecial":
		case "super":
			if(self hasWeapon(self.pers["fragtype"]))
			{
				save_index = save_nades.size;
				save_nades[save_index] = spawnstruct();
				save_nades[save_index].weapon = self.pers["fragtype"];
				save_nades[save_index].ammo = self getAmmoCount(self.pers["fragtype"]);
				self takeWeapon(self.pers["fragtype"]);
			}
			if(self hasWeapon(self.pers["enemy_fragtype"]))
			{
				save_index = save_nades.size;
				save_nades[save_index] = spawnstruct();
				save_nades[save_index].weapon = self.pers["enemy_fragtype"];
				save_nades[save_index].ammo = self getAmmoCount(self.pers["enemy_fragtype"]);
				self takeWeapon(self.pers["enemy_fragtype"]);
			}
			break;
		// smoke slot
		case "smokespecial":
			if(self hasWeapon(self.pers["smoketype"]))
			{
				save_index = save_nades.size;
				save_nades[save_index] = spawnstruct();
				save_nades[save_index].weapon = self.pers["smoketype"];
				save_nades[save_index].ammo = self getAmmoCount(self.pers["smoketype"]);
				self takeWeapon(self.pers["smoketype"]);
			}
			if(self hasWeapon(self.pers["enemy_smoketype"]))
			{
				save_index = save_nades.size;
				save_nades[save_index] = spawnstruct();
				save_nades[save_index].weapon = self.pers["enemy_smoketype"];
				save_nades[save_index].ammo = self getAmmoCount(self.pers["enemy_smoketype"]);
				self takeWeapon(self.pers["enemy_smoketype"]);
			}
			break;
	}

	// give nade to throw back
	if(!self hasWeapon(weapon))
	{
		ammo = 1;
		self giveWeapon(weapon);
	}
	else ammo = self getAmmoCount(weapon) + 1;
	self setWeaponClipAmmo(weapon, ammo);
	self playsound("grenade_pickup");

	hud_index = playerHudCreate("throwback_timer", 0, 50, 1, (1,0,0), 2, 1, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index != -1) playerHudSetTenthsTimer(hud_index, level.ex_nademon_throwback_time);

	hud_index = playerHudCreate("throwback_timertext", 0, 75, 1, (1,1,1), 2, 1, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index != -1)
	{
		playerHudSetText(hud_index, &"WEAPON_THROWBACK");
		playerHudFontPulseInit(hud_index);
	}

	ticks = 0;
	ticks_total = level.ex_nademon_throwback_time * 10;
	origin = self.origin;

	kaboom = false;
	while(!kaboom && self.sessionstate == "playing")
	{
		wait(0.1);

		// keep throw-back nade queued up until we have thrown back the nade
		//self switchToOffhand(weapon);
		origin = self.origin;

		// keep removing other nades until we're done
		switch(classgroup)
		{
			// frag slot
			case "frag":
			case "super":
				if(self.pers["fragtype"] != weapon) self takeWeapon(self.pers["fragtype"]);
				if(self.pers["enemy_fragtype"] != weapon) self takeWeapon(self.pers["enemy_fragtype"]);
				break;
			case "fragspecial":
				if(self.pers["fragtype"] != weapon) self takeWeapon(self.pers["fragtype"]);
				break;
			// smoke slot
			case "smokespecial":
				if(self.pers["smoketype"] != weapon) self takeWeapon(self.pers["smoketype"]);
				if(self.pers["enemy_smoketype"] != weapon) self takeWeapon(self.pers["enemy_smoketype"]);
				break;
		}

		// monitor the throw-back nade type ammo
		if(self getAmmoCount(weapon) < ammo) break;

		ticks++;
		if(ticks > ticks_total) kaboom = true;
			else if(ticks % 8 == 0) thread playerHudFontPulse(hud_index, undefined, false, "kill_nadepulse");
	}

	impactloc = undefined;
	if(kaboom)
	{
		dev_id = getGrenadeDevice(weapon);
		impactloc = spawn("script_origin", origin);

		// device info to pass on
		device_info = [[level.ex_devInfo]](owner, team);
		device_info.dodamage = true;

		// device explosion
		impactloc thread [[level.ex_devExplode]](dev_id, device_info);
	}

	wait( level.ex_fps_frame );

	if(isAlive(self))
	{
		self notify("kill_nadepulse");

		if(isPlayer(self) && self.sessionstate == "playing")
		{
			self.ex_throwback = undefined;
			playerHudDestroy("throwback_timer");
			playerHudDestroy("throwback_timertext");

			// restore nades
			for(i = 0; i < save_nades.size; i++)
			{
				self giveWeapon(save_nades[i].weapon);
				self setWeaponClipAmmo(save_nades[i].weapon, save_nades[i].ammo);
			}
		}
	}

	if(kaboom)
	{
		// remove grenade that was still cooking, if any
		entities = getentarray("grenade", "classname");
		for(i = 0; i < entities.size; i++) if(distance(entities[i].origin, origin) < 100) entities[i] delete();

		// remove dropped grenade, if any
		entities = getentarray("weapon_" + weapon, "classname");
		for(i = 0; i < entities.size; i++) if(distance(entities[i].origin, origin) < 100) entities[i] delete();

		impactloc delete();
	}
}

//------------------------------------------------------------------------------
// Damage callback for Firenade
//------------------------------------------------------------------------------
callbackFireDamage(dev_index, device_info, parentdev_index)
{
	level endon("ex_gameover");

	burntime = 15;
	for(j = 0; j < burntime; j++)
	{
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			if(isDefined(players[i].pers["team"]) && players[i].pers["team"] == "spectator" || players[i].sessionteam == "spectator") continue;
			if(isDefined(players[i].ex_invulnerable) && players[i].ex_invulnerable) continue;

			//if(level.ex_teamplay && (level.friendlyfire == "0" || level.friendlyfire == "2"))
			//	if(isPlayer(device_info.owner) && (players[i] != device_info.owner) && (players[i].pers["team"] == device_info.team)) continue;

			dst = distance(device_info.origin, players[i].origin);
			damarea = level.ex_devices[dev_index].range + (j * 10);
			if( dst > damarea || !isAlive(players[i]) ) continue;
			damage = int( 40 * (1 - (dst / damarea)) + 0.5 );

			if(damage < players[i].health)
			{
				players[i] thread burnPlayer(3);
				players[i].health = players[i].health - damage;
			}
			else
			{
				device_info.damage = damage;
				if(isDefined(parentdev_index)) players[i] thread [[level.ex_devPlayer]](parentdev_index, device_info);
					else players[i] thread [[level.ex_devPlayer]](dev_index, device_info);
			}
		}

		wait( [[level.ex_fpstime]](1) );
	}
}

burnPlayer(burntime)
{
	self endon("kill_thread");

	if(isDefined(self.ex_isonfire)) return;
	self.ex_isonfire = 1;

	if(randomint(100) > 30) extreme\_ex_main_utils::forceto("crouch");
	self playsound("scream");

	burntime = burntime * 4;
	for(i = 0; i < burntime; i++)
	{
		if(isDefined(self))
		{
			switch(randomint(12))
			{
				case  0: tag = "j_hip_le"; break;
				case  1: tag = "j_hip_ri"; break;
				case  2: tag = "j_knee_le"; break;
				case  3: tag = "j_ankle_ri"; break;
				case  4: tag = "j_knee_ri"; break;
				case  5: tag = "j_wrist_ri"; break;
				case  6: tag = "j_head"; break;
				case  7: tag = "j_shoulder_le"; break;
				case  8: tag = "j_shoulder_ri"; break;
				case  9: tag = "j_elbow_le"; break;
				case 10: tag = "j_elbow_ri"; break;
				default: tag = "j_wrist_le"; break;
			}

			playfxontag(level.ex_effect["fire_arm"], self, tag);
			playfxontag(level.ex_effect["fire_torso"], self, "j_spine2");

			wait( [[level.ex_fpstime]](0.25) );
		}
	}

	if(isAlive(self)) self.ex_isonfire = undefined;
}

//------------------------------------------------------------------------------
// Damage callback for Gasnades
//------------------------------------------------------------------------------
callbackGasDamage(dev_index, device_info, parentdev_index)
{
	level endon("ex_gameover");

	gastime = 15;
	for(j = 0; j <= gastime; j++)
	{
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			if(isDefined(players[i].pers["team"]) && players[i].pers["team"] == "spectator" || players[i].sessionteam == "spectator") continue;
			if(isDefined(players[i].ex_invulnerable) && players[i].ex_invulnerable) continue;

			//if(level.ex_teamplay && (level.friendlyfire == "0" || level.friendlyfire == "2"))
			//	if(isPlayer(device_info.owner) && (players[i] != device_info.owner) && (players[i].pers["team"] == device_info.team)) continue;

			dst = distance(device_info.origin, players[i].origin);
			damarea = level.ex_devices[dev_index].range + (j * 10);
			if( dst > damarea || !isAlive(players[i]) ) continue;
			damage = int( 40 * (1 - (dst / damarea)) + 0.5 );

			if(damage < players[i].health)
			{
				players[i] thread gasPlayer(3);
				players[i].health = players[i].health - damage;
			}
			else
			{
				device_info.damage = damage;
				if(isDefined(parentdev_index)) players[i] thread [[level.ex_devPlayer]](parentdev_index, device_info);
					else players[i] thread [[level.ex_devPlayer]](dev_index, device_info);
			}
		}

		wait( [[level.ex_fpstime]](1) );
	}
}

gasPlayer(gastime)
{
	self endon("kill_thread");

	if(isDefined(self.ex_puked)) return;
	self.ex_puked = 1;

	if(randomint(100) > 30)
	{
		extreme\_ex_main_utils::forceto("crouch");
		self playsound("puke");
	}
	else self playsound("choke");

	wait( [[level.ex_fpstime]](gastime) );
	if(isAlive(self)) self.ex_puked = undefined;
}

