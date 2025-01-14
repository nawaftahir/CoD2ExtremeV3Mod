#include extreme\_ex_controller_devices;
#include extreme\_ex_controller_hud;
#include extreme\_ex_main_utils;
#include extreme\_ex_specials;

perkInit(index)
{
	// create perk array
	level.ugvs = [];

	// precache models
	[[level.ex_PrecacheModel]]("xmodel/vehicle_ugv_base");
	[[level.ex_PrecacheModel]]("xmodel/vehicle_ugv_tracks");
	[[level.ex_PrecacheModel]]("xmodel/vehicle_ugv_tracks_noscroll");
	[[level.ex_PrecacheModel]]("xmodel/vehicle_ugv_sentry");

	// precache other shaders
	game["actionpanel_owner"] = "spc_actionpanel_owner";
	[[level.ex_PrecacheShader]](game["actionpanel_owner"]);
	game["actionpanel_enemy"] = "spc_actionpanel_enemy";
	[[level.ex_PrecacheShader]](game["actionpanel_enemy"]);
	game["actionpanel_denied"] = "spc_actionpanel_denied";
	[[level.ex_PrecacheShader]](game["actionpanel_denied"]);

	// precache general purpose waypoints
	if(level.ex_ugv_waypoints)
	{
		game["waypoint_abandoned"] = "spc_waypoint_abandoned";
		[[level.ex_PrecacheShader]](game["waypoint_abandoned"]);

		if(level.ex_ugv_waypoints != 3)
		{
			game["waypoint_activated"] = "spc_waypoint_activated";
			[[level.ex_PrecacheShader]](game["waypoint_activated"]);
			game["waypoint_deactivated"] = "spc_waypoint_deactivated";
			[[level.ex_PrecacheShader]](game["waypoint_deactivated"]);
		}
	}

	// precache effects
	level.ex_effect["ugv_shot"] = [[level.ex_PrecacheEffect]]("fx/muzzleflashes/mg42hv.efx");
	level.ex_effect["ugv_eject"] = [[level.ex_PrecacheEffect]]("fx/shellejects/rifle.efx");
	level.ex_effect["ugv_sparks"] = [[level.ex_PrecacheEffect]]("fx/props/radio_sparks_smoke.efx");
	if(level.ex_ugv_rockets) level.ex_effect["ugvrocket"] = [[level.ex_PrecacheEffect]]("fx/misc/slamraam.efx");

	// device registration
	[[level.ex_devRequest]]("ugv", ::cpxUGV);
	[[level.ex_devRequest]]("ugv_gun");
	if(level.ex_ugv_rockets) [[level.ex_devRequest]]("ugv_missile");
}

perkInitPost(index)
{
	// perk related precaching after map load

	// precache team related waypoints
	if(level.ex_ugv_waypoints == 3)
	{
		switch(game["allies"])
		{
			case "american":
				game["waypoint_activated_allies"] = "spc_waypoint_activated_a";
				game["waypoint_deactivated_allies"] = "spc_waypoint_deactivated_a";
				break;
			case "british":
				game["waypoint_activated_allies"] = "spc_waypoint_activated_b";
				game["waypoint_deactivated_allies"] = "spc_waypoint_deactivated_b";
				break;
			default:
				game["waypoint_activated_allies"] = "spc_waypoint_activated_r";
				game["waypoint_deactivated_allies"] = "spc_waypoint_deactivated_r";
				break;
		}

		game["waypoint_activated_axis"] = "spc_waypoint_activated_g";
		game["waypoint_deactivated_axis"] = "spc_waypoint_deactivated_g";

		[[level.ex_PrecacheShader]](game["waypoint_activated_allies"]);
		[[level.ex_PrecacheShader]](game["waypoint_deactivated_allies"]);
		[[level.ex_PrecacheShader]](game["waypoint_activated_axis"]);
		[[level.ex_PrecacheShader]](game["waypoint_deactivated_axis"]);
	}
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

	if(!isDefined(self.ugv_moving_timer))
	{
		if((level.ex_arcade_shaders & 8) == 8) self thread extreme\_ex_player_arcade::showArcadeShader(getPerkArcade(index), level.ex_arcade_shaders_perk);
			else self iprintlnbold(&"SPECIALS_UGV_READY");
	}

	self thread hudNotifySpecial(index);

	while(true)
	{
		wait( level.ex_fps_frame );
		if(!self isOnGround()) continue;
		if(self meleebuttonpressed())
		{
			count = 0;
			while(self meleeButtonPressed() && count < 10)
			{
				wait( level.ex_fps_frame );
				count++;
			}
			if(count >= 10)
			{
				if(getPerkPriority(index))
				{
					if(!tooClose(level.ex_mindist["perks"][0], level.ex_mindist["perks"][1], level.ex_mindist["perks"][2], level.ex_mindist["perks"][3]))
					{
						if(perkEvenGround(self.origin, self.angles) && perkClearance(self.origin, 40, 2, 60) && self playerActionPanel(-1)) break;
					}
				}
				while(self meleebuttonpressed()) wait( level.ex_fps_frame );
			}
		}
	}

	self thread playerStartUsingPerk(index, true);
	self thread hudNotifySpecialRemove(index);

	level thread perkCreate(self);

	if(level.ex_ugv_messages)
	{
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(player == self || !isDefined(player.pers["team"])) continue;

			if(level.ex_teamplay && player.pers["team"] == self.pers["team"]) player iprintlnbold(&"SPECIALS_UGV_DEPLOYED_TEAM", [[level.ex_pname]](self));
				else player iprintlnbold(&"SPECIALS_UGV_DEPLOYED_ENEMY", [[level.ex_pname]](self));
		}
	}
}

//------------------------------------------------------------------------------
// Validation
//------------------------------------------------------------------------------
perkEvenGround(origin, angles)
{
	f0 = posForward(origin + (0,0,10), angles, 35);
	fl = posLeft(f0, angles, 15);
	pos = posDown(fl, angles, 0);
	if(distance(fl, pos) > 30)
	{
		self iprintlnbold(&"SPECIALS_BAD_LOCATION_CLEARANCE");
		return(false);
	}
	fr = posRight(f0, angles, 15);
	pos = posDown(fr, angles, 0);
	if(distance(fr, pos) > 30)
	{
		self iprintlnbold(&"SPECIALS_BAD_LOCATION_CLEARANCE");
		return(false);
	}

	b0 = posBack(origin + (0,0,10), angles, 35);
	bl = posLeft(b0, angles, 15);
	pos = posDown(bl, angles, 0);
	if(distance(bl, pos) > 30)
	{
		self iprintlnbold(&"SPECIALS_BAD_LOCATION_CLEARANCE");
		return(false);
	}
	br = posRight(b0, angles, 15);
	pos = posDown(br, angles, 0);
	if(distance(br, pos) > 30)
	{
		self iprintlnbold(&"SPECIALS_BAD_LOCATION_CLEARANCE");
		return(false);
	}

	return(true);
}

perkClearance(origin, z_up, z_rings, radius)
{
	for(x = 0; x < z_rings; x++)
	{
		check_origin = origin + (0,0,z_up);

		for(i = 0; i < 360; i += 10)
		{
			pos = getForwardLimit(check_origin, (0,i,0), radius + 10, true);
			if(distance(check_origin, pos) < radius)
			{
				self iprintlnbold(&"SPECIALS_BAD_LOCATION_CLEARANCE");
				return(false);
			}
		}

		z_up += 40;
	}

	return(true);
}

perkCheckEntity(entity)
{
	if(isDefined(level.ugvs))
	{
		for(i = 0; i < level.ugvs.size; i++)
			if(level.ugvs[i].inuse && isDefined(level.ugvs[i].owner) && (level.ugvs[i].body == entity || level.ugvs[i].tracks == entity) ) return(i);
	}

	return(-1);
}

perkValidateAsTarget(index, team)
{
	if(!level.ugvs[index].inuse || !level.ugvs[index].activated || level.ugvs[index].sabotaged || level.ugvs[index].destroyed) return(false);
	if(level.ugvs[index].health <= 0) return(false);
	if(isDefined(team) && level.ex_teamplay && level.ugvs[index].team == team) return(false);
	if(!isDefined(level.ugvs[index].owner) || !isPlayer(level.ugvs[index].owner)) return(false);
	return(true);
}

//------------------------------------------------------------------------------
// Creation and removal
//------------------------------------------------------------------------------
perkCreate(owner)
{
	index = perkAllocate();
	angles = (0, owner.angles[1], 0);
	origin = owner.origin;

	level.ugvs[index].health = level.ex_ugv_maxhealth;
	level.ugvs[index].timer = level.ex_ugv_timer * 5;
	level.ugvs[index].nades = 0;
	level.ugvs[index].speed = 3;

	level.ugvs[index].iscold = false;
	level.ugvs[index].isidle = false;
	level.ugvs[index].ishot = false;
	level.ugvs[index].inreturner = false;
	level.ugvs[index].ismoving = false;
	level.ugvs[index].isfiring = false;
	level.ugvs[index].istargeting = false;

	level.ugvs[index].activated = false;
	level.ugvs[index].destroyed = false;
	level.ugvs[index].sabotaged = false;
	level.ugvs[index].abandoned = false;

	level.ugvs[index].org_origin = origin;
	level.ugvs[index].org_angles = angles;
	level.ugvs[index].org_owner = owner;
	level.ugvs[index].org_ownernum = owner getEntityNumber();

	// create models
	level.ugvs[index].body = spawn("script_model", origin);
	level.ugvs[index].body hide();
	level.ugvs[index].body setmodel("xmodel/vehicle_ugv_base");
	level.ugvs[index].body.angles = angles;

	level.ugvs[index].tracks = spawn("script_model", origin);
	level.ugvs[index].tracks hide();
	level.ugvs[index].tracks setmodel("xmodel/vehicle_ugv_tracks");
	level.ugvs[index].tracks.angles = angles;
	level.ugvs[index].tracks linkTo(level.ugvs[index].body, "tag_tracks", (0,0,0), (0,0,0));

	level.ugvs[index].tracks_s = spawn("script_model", origin);
	level.ugvs[index].tracks_s hide();
	level.ugvs[index].tracks_s setmodel("xmodel/vehicle_ugv_tracks_noscroll");
	level.ugvs[index].tracks_s.angles = angles;
	level.ugvs[index].tracks_s linkTo(level.ugvs[index].body, "tag_tracks", (0,0,0), (0,0,0));

	level.ugvs[index].gun = spawn("script_model", origin);
	level.ugvs[index].gun hide();
	level.ugvs[index].gun setmodel("xmodel/vehicle_ugv_sentry");

	// attach rockets
	if(level.ex_ugv_rockets)
	{
		level.ugvs[index].rockets = [];
		level.ugvs[index].rockets[0] = spawnstruct();
		level.ugvs[index].rockets[0].fired = false;
		level.ugvs[index].rockets[0].model = spawn("script_model", (0,0,0));
		level.ugvs[index].rockets[0].model hide();
		level.ugvs[index].rockets[0].model setmodel( getDeviceModel("ugv_missile") );
		level.ugvs[index].rockets[0].model linkto(level.ugvs[index].gun, "tag_rocket_0", (0,0,0), (0,0,0));
		if(level.ex_ugv_rockets > 1)
		{
			level.ugvs[index].rockets[1] = spawnstruct();
			level.ugvs[index].rockets[1].fired = false;
			level.ugvs[index].rockets[1].model = spawn("script_model", (0,0,0));
			level.ugvs[index].rockets[1].model hide();
			level.ugvs[index].rockets[1].model setmodel( getDeviceModel("ugv_missile") );
			level.ugvs[index].rockets[1].model linkto(level.ugvs[index].gun, "tag_rocket_1", (0,0,0), (0,0,0));
			if(level.ex_ugv_rockets > 2)
			{
				level.ugvs[index].rockets[2] = spawnstruct();
				level.ugvs[index].rockets[2].fired = false;
				level.ugvs[index].rockets[2].model = spawn("script_model", (0,0,0));
				level.ugvs[index].rockets[2].model hide();
				level.ugvs[index].rockets[2].model setmodel( getDeviceModel("ugv_missile") );
				level.ugvs[index].rockets[2].model linkto(level.ugvs[index].gun, "tag_rocket_2", (0,0,0), (0,0,0));
				if(level.ex_ugv_rockets > 3)
				{
					level.ugvs[index].rockets[3] = spawnstruct();
					level.ugvs[index].rockets[3].fired = false;
					level.ugvs[index].rockets[3].model = spawn("script_model", (0,0,0));
					level.ugvs[index].rockets[3].model hide();
					level.ugvs[index].rockets[3].model setmodel( getDeviceModel("ugv_missile") );
					level.ugvs[index].rockets[3].model linkto(level.ugvs[index].gun, "tag_rocket_3", (0,0,0), (0,0,0));
				}
			}
		}
	}
	level.ugvs[index].gun linkTo(level.ugvs[index].body, "tag_primary", (0,0,0), (45,0,0));

	level.ugvs[index].block_trig = spawn("trigger_radius", origin + (0, 0, 20), 0, 40, 40);

	// set owner after creating entities so proximity code can handle it
	level.ugvs[index].owner = owner;
	level.ugvs[index].team = owner.pers["team"];

	// wait for player to clear perk location
	while(positionWouldTelefrag(level.ugvs[index].body.origin)) wait( level.ex_fps_frame );
	wait( [[level.ex_fpstime]](1) ); // to let player get out of trigger zone

	level.ugvs[index].block_trig setcontents(1);

	// create sensors
	level.ugvs[index].sensors = spawn("script_origin", (0,0,0));
	level.ugvs[index].sensors linkTo(level.ugvs[index].body, "tag_sensors", (0,0,0), (0,0,0));
	level.ugvs[index].sensor_fm = spawn("script_origin", (0,0,0));
	level.ugvs[index].sensor_fm linkTo(level.ugvs[index].body, "tag_sensor_fm", (0,0,0), (0,0,0));
	level.ugvs[index].sensor_fl = spawn("script_origin", (0,0,0));
	level.ugvs[index].sensor_fl linkTo(level.ugvs[index].body, "tag_sensor_fl", (0,0,0), (0,0,0));
	level.ugvs[index].sensor_fr = spawn("script_origin", (0,0,0));
	level.ugvs[index].sensor_fr linkTo(level.ugvs[index].body, "tag_sensor_fr", (0,0,0), (0,0,0));
	level.ugvs[index].sensor_bm = spawn("script_origin", (0,0,0));
	level.ugvs[index].sensor_bm linkTo(level.ugvs[index].body, "tag_sensor_bm", (0,0,0), (0,0,0));
	level.ugvs[index].sensor_bl = spawn("script_origin", (0,0,0));
	level.ugvs[index].sensor_bl linkTo(level.ugvs[index].body, "tag_sensor_bl", (0,0,0), (0,0,0));
	level.ugvs[index].sensor_br = spawn("script_origin", (0,0,0));
	level.ugvs[index].sensor_br linkTo(level.ugvs[index].body, "tag_sensor_br", (0,0,0), (0,0,0));

	// move to initial position (also make sure the origin of the linked models is updated)
	level.ugvs[index].body moveto(level.ugvs[index].body.origin + (0,0,50), .1);
	wait( [[level.ex_fpstime]](0.1) );
	perkInitialPosition(index);

	// restore timer and owner after moving perk
	if(isDefined(owner.ugv_moving_timer))
	{
		level.ugvs[index].timer = owner.ugv_moving_timer;
		owner.ugv_moving_timer = undefined;

		if(isDefined(owner.ugv_moving_owner) && isPlayer(owner.ugv_moving_owner) && owner.pers["team"] == owner.ugv_moving_owner.pers["team"])
			level.ugvs[index].owner = owner.ugv_moving_owner;
		owner.ugv_moving_owner = undefined;
	}

	level thread perkThink(index);
}

perkAllocate()
{
	for(i = 0; i < level.ugvs.size; i++)
	{
		if(level.ugvs[i].inuse == 0)
		{
			level.ugvs[i].inuse = 1;
			return(i);
		}
	}

	level.ugvs[i] = spawnstruct();
	level.ugvs[i].notification = "ugv" + i;
	level.ugvs[i].inuse = 1;
	return(i);
}

perkRemoveAll()
{
	if(level.ex_ugv && isDefined(level.ugvs))
	{
		for(i = 0; i < level.ugvs.size; i++)
			if(level.ugvs[i].inuse && !level.ugvs[i].destroyed) thread perkRemove(i);
	}
}

perkRemoveFrom(player)
{
	for(i = 0; i < level.ugvs.size; i++)
		if(level.ugvs[i].inuse && isDefined(level.ugvs[i].owner) && level.ugvs[i].owner == player) thread perkRemove(i);
}

perkRemove(index)
{
	if(!level.ugvs[index].inuse) return;
	level notify(level.ugvs[index].notification);
	level.ugvs[index].destroyed = true; // kills perkThink and perkPathFinder
	perkDeactivate(index, false);
	wait( [[level.ex_fpstime]](2) );
	perkDeleteWaypoint(index);
	perkFree(index);
}

perkFree(index)
{
	thread levelStopUsingPerk(level.ugvs[index].org_ownernum, "ugv");
	level.ugvs[index].owner = undefined;

	// block trigger
	if(isDefined(level.ugvs[index].block_trig)) level.ugvs[index].block_trig delete();

	// sensors
	if(isDefined(level.ugvs[index].sensor_fm)) level.ugvs[index].sensor_fm delete();
	if(isDefined(level.ugvs[index].sensor_fl)) level.ugvs[index].sensor_fl delete();
	if(isDefined(level.ugvs[index].sensor_fr)) level.ugvs[index].sensor_fr delete();
	if(isDefined(level.ugvs[index].sensor_bm)) level.ugvs[index].sensor_bm delete();
	if(isDefined(level.ugvs[index].sensor_bl)) level.ugvs[index].sensor_bl delete();
	if(isDefined(level.ugvs[index].sensor_br)) level.ugvs[index].sensor_br delete();
	if(isDefined(level.ugvs[index].sensors)) level.ugvs[index].sensors delete();

	// rockets
	if(level.ex_ugv_rockets)
	{
		for(i = 0; i < level.ugvs[index].rockets.size; i++)
			if(!level.ugvs[index].rockets[i].fired && isDefined(level.ugvs[index].rockets[i].model)) level.ugvs[index].rockets[i].model delete();
	}

	// models
	if(isDefined(level.ugvs[index].gun)) level.ugvs[index].gun delete();
	if(isDefined(level.ugvs[index].tracks_s)) level.ugvs[index].tracks_s delete();
	if(isDefined(level.ugvs[index].tracks)) level.ugvs[index].tracks delete();
	if(isDefined(level.ugvs[index].body)) level.ugvs[index].body delete();
	level.ugvs[index].inuse = 0;
}

//------------------------------------------------------------------------------
// Main logic
//------------------------------------------------------------------------------
perkInitialPosition(index)
{
	// calculate ground level
	fl_down = posDown(level.ugvs[index].sensor_fl.origin, (0,0,0), 0);
	fr_down = posDown(level.ugvs[index].sensor_fr.origin, (0,0,0), 0);
	bl_down = posDown(level.ugvs[index].sensor_bl.origin, (0,0,0), 0);
	br_down = posDown(level.ugvs[index].sensor_br.origin, (0,0,0), 0);
	h = highestFrom(fl_down, fr_down, bl_down, br_down);
	origin_new = (level.ugvs[index].body.origin[0], level.ugvs[index].body.origin[1], h[2]);

	// move to ground level
	level.ugvs[index].body moveto(origin_new, .1);
	wait( [[level.ex_fpstime]](0.25) );

	// calculate pitch and roll from terrain
	fl_down = posAngledDown(level.ugvs[index].sensor_fl.origin, level.ugvs[index].body.angles, 0);
	fl_dist = distance( (fl_down[0], fl_down[1], level.ugvs[index].sensors.origin[2]), fl_down);

	fr_down = posAngledDown(level.ugvs[index].sensor_fr.origin, level.ugvs[index].body.angles, 0);
	fr_dist = distance( (fr_down[0], fr_down[1], level.ugvs[index].sensors.origin[2]), fr_down);

	bl_down = posAngledDown(level.ugvs[index].sensor_bl.origin, level.ugvs[index].body.angles, 0);
	bl_dist = distance( (bl_down[0], bl_down[1], level.ugvs[index].sensors.origin[2]), bl_down);

	br_down = posAngledDown(level.ugvs[index].sensor_br.origin, level.ugvs[index].body.angles, 0);
	br_dist = distance( (br_down[0], br_down[1], level.ugvs[index].sensors.origin[2]), br_down);

	z_ref = fl_dist;
	pitch = perkGetAngle(fl_down, bl_down);
	roll = perkGetAngle(fr_down, fl_down);
	pitch_d = distance(fl_down, bl_down);
	roll_d = distance(fr_down, fl_down);
	if(bl_dist < z_ref)
	{
		z_ref = bl_dist;
		pitch = perkGetAngle(fl_down, bl_down);
		roll = perkGetAngle(br_down, bl_down);
		pitch_d = distance(fl_down, bl_down);
		roll_d = distance(br_down, bl_down);
	}
	if(fr_dist < z_ref)
	{
		z_ref = fr_dist;
		pitch = perkGetAngle(fr_down, br_down);
		roll = perkGetAngle(fr_down, fl_down);
		pitch_d = distance(fr_down, br_down);
		roll_d = distance(fr_down, fl_down);
	}
	if(br_dist < z_ref)
	{
		pitch = perkGetAngle(fr_down, br_down);
		roll = perkGetAngle(br_down, bl_down);
		pitch_d = distance(fr_down, br_down);
		roll_d = distance(br_down, bl_down);
	}

	if(abs(pitch) > abs(roll)) z_corr = (sin(abs(pitch)) * pitch_d) / 2;
		else z_corr = (sin(abs(roll)) * roll_d) / 2;
	angles_new = (pitch, level.ugvs[index].body.angles[1], roll);
	origin_new = level.ugvs[index].body.origin - (0,0,z_corr);

	// move to new position and angles
	level.ugvs[index].body moveto(origin_new, .1);
	level.ugvs[index].body rotateto(angles_new, .1);
	wait( [[level.ex_fpstime]](0.25) );

	// show models
	level.ugvs[index].body show();
	level.ugvs[index].tracks_s show();
	level.ugvs[index].gun show();
	if(level.ex_ugv_rockets)
	{
		for(i = 0; i < level.ugvs[index].rockets.size; i++)
			if(isDefined(level.ugvs[index].rockets[i].model)) level.ugvs[index].rockets[i].model show();
	}
}

perkThink(index)
{
	limit = sin(level.ex_ugv_reach) - 0.0001;
	target = level.ugvs[index].gun;
	stop_delay = 10;
	move_delay = 0;
	rocket_delay = 50;

	level.ugvs[index].gun unlink();
	perkActivate(index, false);
	thread perkPathFinder(index);

	// device info to pass on
	device_info = [[level.ex_devInfo]](level.ugvs[index].owner, level.ugvs[index].team);
	device_info.dodamage = true;
	device_info.damage = level.ex_ugv_damage;

	for(;;)
	{
		target_old = target;
		target = level.ugvs[index].gun;

		// signaled to destroy by proximity checks, or when being moved
		if(level.ugvs[index].destroyed) return;

		// remove perk if it reached end of life
		if(level.ugvs[index].timer <= 0)
		{
			if(isPlayer(level.ugvs[index].owner)) level.ugvs[index].owner iprintlnbold(&"SPECIALS_UGV_REMOVED");
			level thread perkRemove(index);
			return;
		}

/*
		// remove perk if health dropped to 0
		if(level.ugvs[index].health <= 0)
		{
			if(level.ex_ugv_messages && isPlayer(level.ugvs[index].owner)) level.ugvs[index].owner iprintlnbold(&"SPECIALS_UGV_DESTROYED");
			level thread perkRemove(index);
			return;
		}
*/

		// temporarily disable if health drops to 0
		if(level.ugvs[index].health <= 0)
		{
			level.ugvs[index].health = level.ex_ugv_maxhealth;
			level thread perkDeactivateTimer(index, level.ex_ugv_cpx_timer);
		}

		// check if owner left the game or switched teams
		if(!level.ugvs[index].abandoned)
		{
			// owner left
			if(!isPlayer(level.ugvs[index].owner))
			{
				if((level.ex_ugv_remove & 1) == 1)
				{
					level thread perkRemove(index);
					return;
				}
				level.ugvs[index].abandoned = true;
				level.ugvs[index].owner = level.ugvs[index].gun;
				perkDeactivate(index, false);
				perkCreateWaypoint(index);
			}
			// owner switched teams
			else if((level.ex_ugv_remove & 2) != 2 && level.ugvs[index].owner.pers["team"] != level.ugvs[index].team)
			{
				level.ugvs[index].abandoned = true;
				perkDeleteWaypoint(index);
				level.ugvs[index].owner = level.ugvs[index].gun;
				perkDeactivate(index, false);
				perkCreateWaypoint(index);
			}
		}

		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];

			if(isAlive(player))
			{
				// check for actions
				if(level.ugvs[index].inuse && player meleebuttonpressed() && perkInRadius(index, player)) player thread playerActionPanel(index);

				// check for targets if activated and not sabotaged
				if(level.ugvs[index].activated && !level.ugvs[index].sabotaged)
				{
					if( (!level.ex_teamplay && player != level.ugvs[index].owner) || (level.ex_teamplay && player.pers["team"] != level.ugvs[index].team) )
					{
						// check if old target is still alive and in range
						if(isPlayer(target_old) && isAlive(target_old) && perkInSight(index, target_old) && perkCanSee(index, target_old))
						{
							target = target_old;
							break;
						}
						// check other player
						else if(perkInSight(index, player) && perkCanSee(index, player))
						{
							if(!isPlayer(target)) target = player;
							if(closer(level.ugvs[index].gun.origin, player.origin, target.origin)) target = player;
						}
					}
				}
			}
		}

		// if still active and not sabotaged, show some action
		if(level.ugvs[index].activated && !level.ugvs[index].sabotaged)
		{
			if(isPlayer(target))
			{
				if(stop_delay) stop_delay--;
				if(!stop_delay)
				{
					level.ugvs[index].ishot = true;
					wait( [[level.ex_fpstime]](0.1) );
					move_delay = 15;
					perkTracksStop(index);

					va = vectorToAngles(target.origin + (0, 0, 40) - level.ugvs[index].gun.origin);

					if(target == target_old && !level.ugvs[index].istargeting) level.ugvs[index].gun rotateTo(va, .2);
						else thread perkTargeting(index, va, .5);

					wait( level.ex_fps_frame );

					if(!level.ugvs[index].istargeting)
					{
						if(level.ex_ugv_rockets && !rocket_delay)
						{
							thread perkRocket(index, target);
							rocket_delay = randomIntRange(50, 100);
						}

						thread perkFiring(index);

						// do damage
						if(isPlayer(level.ugvs[index].owner) && (!level.ex_teamplay || level.ugvs[index].owner.pers["team"] == level.ugvs[index].team))
						{
							device_info.hitdir = anglesToForward(va);
							target thread [[level.ex_devPlayer]]("ugv_gun", device_info);
						}
					}
				}
			}
			else if(level.ugvs[index].ishot)
			{
				if(move_delay) move_delay--;
				if(!move_delay)
				{
					stop_delay = 10;
					// reset to idle position
					level.ugvs[index].gun playsound("sentrygun_servo_medium");
					level.ugvs[index].gun rotateTo(level.ugvs[index].body.angles, 1);
					wait( [[level.ex_fpstime]](1) );
					level.ugvs[index].ishot = false;
				}
			}
		}

		if(rocket_delay) rocket_delay--;

		level.ugvs[index].timer--;
		wait( [[level.ex_fpstime]](0.2) );
	}
}

perkPathFinder(index)
{
	pitch = level.ugvs[index].body.angles[0];
	yaw = level.ugvs[index].body.angles[1];
	roll = level.ugvs[index].body.angles[2];

	pitch_old = pitch;
	roll_old = roll;
	yaw_corr_total = 0;

	while(!level.ugvs[index].destroyed)
	{
		if(level.ugvs[index].iscold || level.ugvs[index].isidle || level.ugvs[index].ishot)
		{
			wait( [[level.ex_fpstime]](0.1) );
			continue;
		}

		// move tracks if not already moving
		perkTracksMove(index);

		// apply remaining yaw correction if necessary
		forward_step = 3;
		if(yaw_corr_total < 0)
		{
			forward_step = 0;
			if(yaw_corr_total <= -3)
			{
				yaw_corr = -3;
				yaw_corr_total += 3;
			}
			else
			{
				yaw_corr = yaw_corr_total;
				yaw_corr_total = 0;
			}
		}
		else if(yaw_corr_total > 0)
		{
			forward_step = 0;
			if(yaw_corr_total >= 3)
			{
				yaw_corr = 3;
				yaw_corr_total -= 3;
			}
			else
			{
				yaw_corr = yaw_corr_total;
				yaw_corr_total = 0;
			}
		}
		else yaw_corr = 0;

		if(forward_step)
		{
			// yaw correction based on forward projection
			fm_forw = posForward(level.ugvs[index].sensor_fm.origin, level.ugvs[index].body.angles, 0);
			fm_dist = distance(level.ugvs[index].sensor_fm.origin, fm_forw);
			fl_forw = posForward(level.ugvs[index].sensor_fl.origin, level.ugvs[index].body.angles, 0);
			fl_dist = distance(level.ugvs[index].sensor_fl.origin, fl_forw);
			fr_forw = posForward(level.ugvs[index].sensor_fr.origin, level.ugvs[index].body.angles, 0);
			fr_dist = distance(level.ugvs[index].sensor_fr.origin, fr_forw);

			if((fl_dist < 25 && fr_dist < 25) || perkTouchingReturners(index))
			{
				// can't move forward; do 90 degree yaw correction based on side projection
				forward_step = 0;
				fl_side = posLeft(level.ugvs[index].sensor_fl.origin, level.ugvs[index].body.angles, 0);
				fl_dist = distance(level.ugvs[index].sensor_fl.origin, fl_side);
				fr_side = posRight(level.ugvs[index].sensor_fr.origin, level.ugvs[index].body.angles, 0);
				fr_dist = distance(level.ugvs[index].sensor_fr.origin, fr_side);
				if(fl_dist >= fr_dist)
				{
					yaw_corr_total = 85;
					yaw_corr = 5;
				}
				else
				{
					yaw_corr_total = -85;
					yaw_corr = -5;
				}
			}
			else level.ugvs[index].inreturner = false;

			if(forward_step)
			{
				if(fm_dist < 80 || fl_dist < 80 || fr_dist < 80)
				{
					check_left = 0;
					for(i = 1; i < 5; i++)
					{
						pos = getForwardLimit(level.ugvs[index].sensor_fl.origin, level.ugvs[index].body.angles + (0,i*15,0), 1000, true);
						check_left += (5-i) * distance(level.ugvs[index].sensor_fl.origin, pos);
					}

					check_right = 0;
					for(i = 1; i < 5; i++)
					{
						pos = getForwardLimit(level.ugvs[index].sensor_fr.origin, level.ugvs[index].body.angles - (0,i*15,0), 1000, true);
						check_right += (5-i) * distance(level.ugvs[index].sensor_fr.origin, pos);
					}

					if(check_left > check_right)
					{
						yaw_corr += 2;
						if(check_right < 500) yaw_corr += 1;
					}
					else
					{
						yaw_corr -= 2;
						if(check_left < 500) yaw_corr -= 1;
					}
				}

				// yaw correction based on side projection
				fl_side = posLeft(level.ugvs[index].sensor_fl.origin, level.ugvs[index].body.angles, 0);
				fl_dist = distance(level.ugvs[index].sensor_fl.origin, fl_side);
				if(fl_dist < 50) yaw_corr -= 1;
				fr_side = posRight(level.ugvs[index].sensor_fr.origin, level.ugvs[index].body.angles, 0);
				fr_dist = distance(level.ugvs[index].sensor_fr.origin, fr_side);
				if(fr_dist < 50) yaw_corr += 1;
			}
		}

		// calculate pitch and roll from terrain
		fl_down = posAngledDown(level.ugvs[index].sensor_fl.origin, level.ugvs[index].body.angles, 0);
		fl_dist = distance( (fl_down[0], fl_down[1], level.ugvs[index].sensors.origin[2]), fl_down);

		fr_down = posAngledDown(level.ugvs[index].sensor_fr.origin, level.ugvs[index].body.angles, 0);
		fr_dist = distance( (fr_down[0], fr_down[1], level.ugvs[index].sensors.origin[2]), fr_down);

		if(yaw_corr_total == 0 && (fl_dist > 45 || fr_dist > 45))
		{
			forward_step = -3;
			yaw_corr_total = 175;
			yaw_corr = 3;
		}
		else if(yaw_corr_total != 0 && abs(pitch_old) < 5)
		{
			pitch = pitch_old;
			roll = roll_old;
		}
		else
		{
			bl_down = posAngledDown(level.ugvs[index].sensor_bl.origin, level.ugvs[index].body.angles, 0);
			bl_dist = distance( (bl_down[0], bl_down[1], level.ugvs[index].sensors.origin[2]), bl_down);

			br_down = posAngledDown(level.ugvs[index].sensor_br.origin, level.ugvs[index].body.angles, 0);
			br_dist = distance( (br_down[0], br_down[1], level.ugvs[index].sensors.origin[2]), br_down);

			z_ref = fl_dist;
			pitch = perkGetAngle(fl_down, bl_down);
			roll = perkGetAngle(fr_down, fl_down);
			if(bl_dist < z_ref)
			{
				z_ref = bl_dist;
				pitch = perkGetAngle(fl_down, bl_down);
				roll = perkGetAngle(br_down, bl_down);
			}
			if(fr_dist < z_ref)
			{
				z_ref = fr_dist;
				pitch = perkGetAngle(fr_down, br_down);
				roll = perkGetAngle(fr_down, fl_down);
			}
			if(br_dist < z_ref)
			{
				pitch = perkGetAngle(fr_down, br_down);
				roll = perkGetAngle(br_down, bl_down);
			}

			// handle pitch and roll changes
			if(abs(pitch - pitch_old) > 20)
			{
				if(pitch < 0) pitch = pitch_old;
					else pitch = pitch / 2;
			}
			if(abs(roll - roll_old) > 10)
			{
				if(abs(roll) >= abs(roll_old)) roll = roll_old;
			}
			if(abs(pitch) > 75 || abs(roll) > 75)
			{
				perkDeactivate(index, false);
				continue;
			}
		}

		// apply yaw correction
		yaw = level.ugvs[index].body.angles[1];
		if(yaw_corr != 0) yaw += yaw_corr;

		// apply subtle height correction (based on xmodel with 19 units from sensor to ground level)
		z_corr = 0;
		bm_down = posAngledDown(level.ugvs[index].sensor_bm.origin, level.ugvs[index].body.angles, 0);
		bm_dist = distance(level.ugvs[index].sensor_bm.origin, bm_down);
		if(bm_dist < 19) z_corr = 0.1;
			else if(bm_dist > 19) z_corr = -0.1;

		// move to new position and rotate to new angles
		angles_new = (pitch, yaw, roll);
		if(forward_step)
		{
			origin_new = posForward(level.ugvs[index].body.origin + (0,0,z_corr), angles_new, forward_step);
			level.ugvs[index].body moveto(origin_new, .06, 0, 0);
		}
		level.ugvs[index].body rotateto(angles_new, .06, 0, 0);
		level thread perkUpdateTrigger(index);
		wait( [[level.ex_fpstime]](0.06) );

		pitch_old = pitch;
		roll_old = roll;
	}

	wait( [[level.ex_fpstime]](0.1) );
}

perkTouchingReturners(index)
{
	if(level.ugvs[index].inreturner) return(false);

	for(i = 0; i < level.ex_returners.size; i++)
	{
		if(level.ugvs[index].sensor_fl istouching(level.ex_returners[i]))
		{
			level.ugvs[index].inreturner = true;
			return(true);
		}
		if(level.ugvs[index].sensor_fr istouching(level.ex_returners[i]))
		{
			level.ugvs[index].inreturner = true;
			return(true);
		}
	}

	return(false);
}

perkUpdateTrigger(index)
{
	if(isDefined(level.ugvs[index].block_trig)) level.ugvs[index].block_trig delete();
	level.ugvs[index].block_trig = spawn("trigger_radius", level.ugvs[index].body.origin + (0, 0, 20), 0, 40, 40);
	level.ugvs[index].block_trig setcontents(1);
}

highestFrom(v1, v2, v3, v4)
{
	highest = v1;
	if(v2[2] > highest[2]) highest = v2;
	if(v3[2] > highest[2]) highest = v3;
	if(v4[2] > highest[2]) highest = v4;
	return(highest);
}

perkGetAngle(v1, v2)
{
	angle = vectorToAngles(v1 - v2)[0];
	if(angle > 180) return(0 - (360 - angle));
		else return(angle);
}

perkTracksMove(index)
{
	if(level.ugvs[index].ismoving) return;
	level.ugvs[index].ismoving = true;

	level.ugvs[index].gun linkTo(level.ugvs[index].body, "tag_primary", (0,0,0), (0,0,0));
	wait( [[level.ex_fpstime]](0.1) );
	level.ugvs[index].tracks_s hide();
	level.ugvs[index].tracks show();
	level.ugvs[index].body playloopsound("ugv_loop");

	thread perkWaypointUpdater(index);
}

perkTracksStop(index)
{
	if(!level.ugvs[index].ismoving) return;
	level.ugvs[index].ismoving = false;

	level.ugvs[index].tracks hide();
	level.ugvs[index].tracks_s show();
	level.ugvs[index].body stoploopsound();

	dest = posForward(level.ugvs[index].body.origin, level.ugvs[index].body.angles, .1);
	level.ugvs[index].body moveto(dest, .1);
	wait( [[level.ex_fpstime]](0.2) );

	level.ugvs[index].gun unlink();
}

perkWaypointUpdater(index)
{
	while(level.ugvs[index].ismoving)
	{
		perkUpdateWaypoint(index);
		wait( level.ex_fps_frame );
	}
}

perkInRadius(index, player)
{
	if(distance(player.origin, level.ugvs[index].gun.origin) < level.ex_ugv_actionradius) return(true);
	return(false);
}

perkInSight(index, player)
{
	dir = vectorNormalize(player.origin + (0, 0, 40) - level.ugvs[index].gun.origin);

	// check if player is within the limits of perk movement
	dot = dotNormalize(vectorDot(anglesToForward( (0, level.ugvs[index].body.angles[1], 0) ), dir));
	viewangle = acos(dot);
	if(viewangle > level.ex_ugv_reach) return(false);

	// check if player is in line of sight
	dot = dotNormalize(vectorDot(anglesToForward( (0, level.ugvs[index].gun.angles[1], 0) ), dir));
	viewangle = acos(dot);
	if(viewangle > level.ex_ugv_viewangle) return(false);
	return(true);
}

perkCanSee(index, player)
{
	cansee = false;
	if(distance(player.origin, level.ugvs[index].gun.origin) <= level.ex_ugv_fireradius)
	{
		cansee = (bullettrace(level.ugvs[index].gun.origin + (0, 0, 10), player.origin + (0, 0, 10), false, level.ugvs[index].block_trig)["fraction"] == 1);
		if(!cansee) cansee = (bullettrace(level.ugvs[index].gun.origin + (0, 0, 10), player.origin + (0, 0, 40), false, level.ugvs[index].block_trig)["fraction"] == 1);
		if(!cansee && isDefined(player.ex_eyemarker)) cansee = (bullettrace(level.ugvs[index].gun.origin + (0, 0, 10), player.ex_eyemarker.origin, false, level.ugvs[index].block_trig)["fraction"] == 1);
	}
	return(cansee);
}

perkTargeting(index, vector, duration)
{
	if(level.ugvs[index].istargeting) return;
	level.ugvs[index].istargeting = true;
	if(randomInt(2)) level.ugvs[index].gun playsound("sentrygun_servo_short");
		else level.ugvs[index].gun playsound("sentrygun_servo_medium");
	level.ugvs[index].gun rotateTo(vector, duration);
	wait( [[level.ex_fpstime]](duration) );
	level.ugvs[index].istargeting = false;
}

perkFiring(index)
{
	if(level.ugvs[index].isfiring) return;
	level.ugvs[index].isfiring = true;
	level.ugvs[index].gun playsound("sentrygun_fire");

	firingtime = 1.3;
	for(i = 0; i < firingtime; i += .1)
	{
		playfxontag(level.ex_effect["ugv_shot"], level.ugvs[index].gun, "tag_flash_left");
		playfxontag(level.ex_effect["ugv_eject"], level.ugvs[index].gun, "tag_eject_left");

		playfxontag(level.ex_effect["ugv_shot"], level.ugvs[index].gun, "tag_flash_right");
		playfxontag(level.ex_effect["ugv_eject"], level.ugvs[index].gun, "tag_eject_right");
		wait( [[level.ex_fpstime]](0.1) );
	}

	level.ugvs[index].isfiring = false;
}

perkOwnership(index, player)
{
	if(!isPlayer(level.ugvs[index].owner))
	{
		perkDeleteWaypoint(index);
		level.ugvs[index].owner = player;
		level.ugvs[index].abandoned = false;
		perkCreateWaypoint(index);

		if(!level.ex_teamplay || player.pers["team"] != level.ugvs[index].team) level.ugvs[index].team = player.pers["team"];
		level.ugvs[index].owner iprintlnbold(&"SPECIALS_UGV_OWNERSHIP_ABANDONED");
	}
}

//------------------------------------------------------------------------------
// Rocket handling
//------------------------------------------------------------------------------
perkRocket(index, target)
{
	rocket = 0;
	while(1)
	{
		if(!level.ugvs[index].rockets[rocket].fired) break;
		rocket++;
		if(rocket == 4) return;
	}

	level.ugvs[index].rockets[rocket].fired = true;
	level.ugvs[index].rockets[rocket].model unlink();

	// device info to pass on
	device_info = [[level.ex_devInfo]](level.ugvs[index].owner, level.ugvs[index].team);

	// target info to pass on
	target_info = spawnstruct();
	target_info.target = target;
	target_info.target_type = -1;

	// fire missile
	level.ugvs[index].rockets[rocket].model thread [[level.ex_devMissile]]("ugv_missile", device_info, target_info, undefined);
}

//------------------------------------------------------------------------------
// Actions
//------------------------------------------------------------------------------
perkActivate(index, force)
{
	if(!level.ugvs[index].inuse || (level.ugvs[index].activated && !force)) return;

	level.ugvs[index].nades = 0;
	level.ugvs[index].gun playsound("sentrygun_windup");
	level.ugvs[index].gun rotateTo(level.ugvs[index].body.angles, 2);
	wait( [[level.ex_fpstime]](2) );

	level.ugvs[index].ishot = false;
	level.ugvs[index].iscold = false;

	level.ugvs[index].activated = true;
	perkCreateWaypoint(index);
}

perkDeactivate(index, forcebarrelup)
{
	if(!level.ugvs[index].inuse || (!level.ugvs[index].activated && !forcebarrelup)) return;

	level.ugvs[index].activated = false;
	level.ugvs[index].iscold = true;
	wait( [[level.ex_fpstime]](0.1) ); // wait for PathFinder to finish loop
	perkTracksStop(index);
	perkCreateWaypoint(index);

	dummy = spawn("script_model", level.ugvs[index].body.origin);
	dummy setmodel("xmodel/tag_origin");
	dummy.angles = level.ugvs[index].body.angles;
	if(forcebarrelup) dummy linkTo(level.ugvs[index].body, "tag_primary", (0,0,0), (-75,0,0));
		else dummy linkTo(level.ugvs[index].body, "tag_primary", (0,0,0), (45,0,0));
	wait( [[level.ex_fpstime]](0.1) );
	dummy unlink();
	angles_new = dummy.angles;
	dummy delete();

	level.ugvs[index].gun playsound("sentrygun_winddown");
	level.ugvs[index].gun rotateTo(angles_new, 2);
	level.ugvs[index].gun playsound("sentrygun_servo_long");
	wait( [[level.ex_fpstime]](2) );
}

perkDeactivateTimer(index, timer)
{
	if(!level.ugvs[index].inuse || (!level.ugvs[index].activated || level.ugvs[index].destroyed)) return;

	if(timer && level.ugvs[index].timer > timer)
	{
		perkDeactivate(index, false);
		wait( [[level.ex_fpstime]](timer) );
		if(!level.ugvs[index].sabotaged && !level.ugvs[index].destroyed && level.ugvs[index].timer > 5)
			perkActivate(index, false);
	}
	else level thread perkDeactivate(index, false);
}

perkAdjust(index, player)
{
	// NOP
}

perkSabotage(index)
{
	if(!level.ugvs[index].inuse || level.ugvs[index].sabotaged) return;
	level.ugvs[index].sabotaged = true; // stops targeting and firing
	perkMalfunction(index);
	if(level.ugvs[index].sabotaged) perkDeactivate(index, true);
}

perkRepair(index)
{
	if(!level.ugvs[index].inuse || !level.ugvs[index].sabotaged) return;
	level.ugvs[index].sabotaged = false;
	perkActivate(index, level.ugvs[index].activated);
	level.ugvs[index].health = level.ex_ugv_maxhealth;
}

perkDestroy(index)
{
	if(!level.ugvs[index].inuse || level.ugvs[index].destroyed) return;
	level.ugvs[index].destroyed = true; // kills perkThink(index)
	perkMalfunction(index);
	perkRemove(index);
}

perkMove(index, player)
{
	perkTracksStop(index);
	if(!level.ugvs[index].inuse || isDefined(player.ugv_moving_timer)) return;
	level.ugvs[index].destroyed = true; // kills perkThink(index)
	player.ugv_moving_timer = level.ugvs[index].timer;
	player.ugv_moving_owner = level.ugvs[index].owner;
	wait( [[level.ex_fpstime]](0.5) );
	perkRemove(index);
	player thread playerGiveBackPerk("ugv");
}

perkSteal(index, player)
{
	perkDeleteWaypoint(index);
	level.ugvs[index].owner = player;
	if(isAlive(player) && (!level.ex_teamplay || player.pers["team"] != level.ugvs[index].team))
		level.ugvs[index].team = player.pers["team"];
	level.ugvs[index].owner iprintlnbold(&"SPECIALS_UGV_OWNERSHIP");

	if(level.ugvs[index].sabotaged) perkRepair(index);
		else if(!level.ugvs[index].activated) perkActivate(index, false);
			else perkCreateWaypoint(index);
}

perkMalfunction(index)
{
	perkTracksStop(index);
	for(i = 0; i < 20; i++)
	{
		// quit malfunctioning if perk has been removed or repaired
		if(!level.ugvs[index].inuse || (!level.ugvs[index].sabotaged && !level.ugvs[index].destroyed)) break;

		random_time = randomFloatRange(.5, 1);
		// do not want two malfunctions to run at once when perkSabotage(index) is called from cpxUGVs()
		if(level.ugvs[index].activated)
		{
			random_pitch = randomIntRange(-20, 20);
			random_yaw = randomIntRange(0 - level.ex_ugv_reach, level.ex_ugv_reach);
			random_time = randomFloatRange(.1, 1);
			level.ugvs[index].gun playsound("sentrygun_servo_short");
			level.ugvs[index].gun rotateTo(level.ugvs[index].body.angles + (random_pitch, random_yaw, 0), random_time);
		}
		playfx(level.ex_effect["ugv_sparks"], level.ugvs[index].gun.origin);
		wait( [[level.ex_fpstime]](random_time) );
	}
}

//------------------------------------------------------------------------------
// Action panel
//------------------------------------------------------------------------------
playerActionPanel(index)
{
	self endon("kill_thread");

	if(isDefined(self.ugv_action) || !isAlive(self) || !self isOnGround()) return(false);

	// if this is a deployment call (index -1), first check basic requirements before setting ugv_action flag
	candeploy = false;
	if(index == -1)
	{
		if(self.ex_moving || self [[level.ex_getstance]](false) == 2) return(false);
		candeploy = true;
	}

	self.ugv_action = true;

	// set mayadjust to false if this perk has no adjust capabilities
	mayadjust = false;

	canactivate = false;
	canadjust = false;
	canrepair = false;
	canmove = false;
	candeactivate = false;
	cansabotage = false;
	candestroy = false;
	cansteal = false;

	panel = game["actionpanel_owner"];
	if(!candeploy)
	{
		// check ownership if not deploying
		perkOwnership(index, self);

		// check owner actions
		if(self == level.ugvs[index].owner && (!level.ex_teamplay || self.pers["team"] == level.ugvs[index].team))
		{
			canactivate = ((level.ex_ugv_owneraction & 1) == 1 && !level.ugvs[index].activated && !level.ugvs[index].sabotaged && !level.ugvs[index].destroyed);
			canadjust = (mayadjust && (level.ex_ugv_owneraction & 2) == 2 && level.ugvs[index].activated && !level.ugvs[index].sabotaged && !level.ugvs[index].destroyed);
			canrepair = ((level.ex_ugv_owneraction & 4) == 4 && level.ugvs[index].sabotaged && !level.ugvs[index].destroyed);
			canmove = ((level.ex_ugv_owneraction & 8) == 8 && !level.ugvs[index].sabotaged && !level.ugvs[index].destroyed && !playerPerkIsLocked("ugv", false));
			if(!canactivate && !canadjust && !canrepair && !canmove)
			{
				self.ugv_action = undefined;
				return(false);
			}
		}
		// check teammates actions
		else if(level.ex_teamplay && self.pers["team"] == level.ugvs[index].team)
		{
			canactivate = ((level.ex_ugv_teamaction & 1) == 1 && !level.ugvs[index].activated && !level.ugvs[index].sabotaged && !level.ugvs[index].destroyed);
			canadjust = (mayadjust && (level.ex_ugv_teamaction & 2) == 2 && level.ugvs[index].activated && !level.ugvs[index].sabotaged && !level.ugvs[index].destroyed);
			canrepair = ((level.ex_ugv_teamaction & 4) == 4 && level.ugvs[index].sabotaged && !level.ugvs[index].destroyed);
			canmove = ((level.ex_ugv_teamaction & 8) == 8 && !level.ugvs[index].sabotaged && !level.ugvs[index].destroyed && !playerPerkIsLocked("ugv", false));
			if(!canactivate && !canadjust && !canrepair && !canmove)
			{
				self.ugv_action = undefined;
				return(false);
			}
		}
		// check enemy actions
		else if(!level.ex_teamplay || self.pers["team"] != level.ugvs[index].team)
		{
			panel = game["actionpanel_enemy"];
			candeactivate = ((level.ex_ugv_enemyaction & 1) == 1 && level.ugvs[index].activated && !level.ugvs[index].sabotaged && !level.ugvs[index].destroyed);
			cansabotage = ((level.ex_ugv_enemyaction & 2) == 2 && !level.ugvs[index].sabotaged && !level.ugvs[index].destroyed);
			candestroy = ((level.ex_ugv_enemyaction & 4) == 4 && !level.ugvs[index].destroyed);
			cansteal = ((level.ex_ugv_enemyaction & 8) == 8 && !level.ugvs[index].destroyed);
			if(!candeactivate && !cansabotage && !candestroy && !cansteal)
			{
				self.ugv_action = undefined;
				return(false);
			}
		}
	}

	// show the action panel
	hud_index = playerHudCreate("perk_action_bg", 0, 160, 1, undefined, 1, 0, "center_safearea", "center_safearea", "center", "middle", false, true);
	if(hud_index != -1) playerHudSetShader(hud_index, panel, 256, 256);

	// show progress bar
	hud_index = playerHudCreate("perk_action_pb", (200 / -2) + 2, 161, 1, (0,1,0), 1, 1, "center_safearea", "center_safearea", "left", "middle", false, true);
	if(hud_index != -1)
	{
		playerHudSetShader(hud_index, "white", 1, 11);
		playerHudScale(hud_index, level.ex_ugv_actiontime * 4, 0, 200, 11);
	}

	// show disabled indicator for action 1
	actiontimer_autostop = 0;
	if(!(candeploy || canactivate || candeactivate))
	{
		hud_index = playerHudCreate("perk_action_a1", -45, 112, 1, undefined, 1, 1, "center_safearea", "center_safearea", "center", "middle", false, true);
		if(hud_index != -1) playerHudSetShader(hud_index, game["actionpanel_denied"], 45, 45);
	}
	else actiontimer_autostop = 1;
	// show disabled indicator for action 2
	if(!(canadjust || cansabotage))
	{
		hud_index = playerHudCreate("perk_action_a2", 3, 112, 1, undefined, 1, 1, "center_safearea", "center_safearea", "center", "middle", false, true);
		if(hud_index != -1) playerHudSetShader(hud_index, game["actionpanel_denied"], 45, 45);
	}
	else actiontimer_autostop = 2;
	// show disabled indicator for action 3
	if(!(canrepair || candestroy))
	{
		hud_index = playerHudCreate("perk_action_a3", 51, 112, 1, undefined, 1, 1, "center_safearea", "center_safearea", "center", "middle", false, true);
		if(hud_index != -1) playerHudSetShader(hud_index, game["actionpanel_denied"], 45, 45);
	}
	else actiontimer_autostop = 3;
	// show disabled indicator for action 4
	if(!(canmove || cansteal))
	{
		hud_index = playerHudCreate("perk_action_a4", 99, 112, 1, undefined, 1, 1, "center_safearea", "center_safearea", "center", "middle", false, true);
		if(hud_index != -1) playerHudSetShader(hud_index, game["actionpanel_denied"], 45, 45);
	}
	else actiontimer_autostop = 4;

	// now see for how long the melee key is pressed
	granted = false;
	progresstime = 0;
	while(self meleebuttonpressed())
	{
		if(!self isOnGround() || self.ex_moving || self [[level.ex_getstance]](false) == 2) break;
		if(!candeploy && !level.ugvs[index].inuse) break;
		if(!candeploy && !perkCanSee(index, self) && !perkInRadius(index, self)) break;

		wait( level.ex_fps_frame );
		progresstime += level.ex_fps_frame;
		if(progresstime >= level.ex_ugv_actiontime * actiontimer_autostop) break;
	}

	playerHudDestroy("perk_action_a1");
	playerHudDestroy("perk_action_a2");
	playerHudDestroy("perk_action_a3");
	playerHudDestroy("perk_action_a4");
	playerHudDestroy("perk_action_pb");
	playerHudDestroy("perk_action_bg");

	if(candeploy && progresstime >= level.ex_ugv_actiontime) granted = true;
	if(!candeploy && level.ugvs[index].inuse)
	{
		// 4th action (8 second boundary by default)
		if(!granted && progresstime >= level.ex_ugv_actiontime * 4)
		{
			if(canmove)
			{
				granted = true;
				if(level.ex_ugv_messages == 2 && isPlayer(level.ugvs[index].owner) && self != level.ugvs[index].owner)
					level.ugvs[index].owner iprintlnbold(&"SPECIALS_UGV_MOVED_BY", [[level.ex_pname]](self));
				level thread perkMove(index, self);
			}
			else if(cansteal)
			{
				granted = true;
				if(level.ex_ugv_messages && isPlayer(level.ugvs[index].owner) && self != level.ugvs[index].owner)
					level.ugvs[index].owner iprintlnbold(&"SPECIALS_UGV_STOLEN_BY", [[level.ex_pname]](self));
				level thread perkSteal(index, self);
			}
		}

		// 3rd action (6 second boundary by default)
		if(!granted && progresstime >= level.ex_ugv_actiontime * 3)
		{
			if(canrepair)
			{
				granted = true;
				if(level.ex_ugv_messages == 2 && isPlayer(level.ugvs[index].owner) && self != level.ugvs[index].owner)
					level.ugvs[index].owner iprintlnbold(&"SPECIALS_UGV_REPAIRED_BY", [[level.ex_pname]](self));
				level thread perkRepair(index);
			}
			else if(candestroy)
			{
				granted = true;
				if(level.ex_ugv_messages && isPlayer(level.ugvs[index].owner) && self != level.ugvs[index].owner)
					level.ugvs[index].owner iprintlnbold(&"SPECIALS_UGV_DESTROYED_BY", [[level.ex_pname]](self));
				level thread perkDestroy(index);
			}
		}

		// 2nd action (4 second boundary by default)
		if(!granted && progresstime >= level.ex_ugv_actiontime * 2)
		{
			if(canadjust)
			{
				granted = true;
				if(level.ex_ugv_messages == 2 && isPlayer(level.ugvs[index].owner) && self != level.ugvs[index].owner)
					level.ugvs[index].owner iprintlnbold(&"SPECIALS_UGV_ADJUSTED_BY", [[level.ex_pname]](self));
				level thread perkAdjust(index, self);
			}
			else if(cansabotage)
			{
				granted = true;
				if(level.ex_ugv_messages && isPlayer(level.ugvs[index].owner) && self != level.ugvs[index].owner)
					level.ugvs[index].owner iprintlnbold(&"SPECIALS_UGV_SABOTAGED_BY", [[level.ex_pname]](self));
				level thread perkSabotage(index);
			}
		}

		// 1st action (2 second boundary by default)
		if(!granted && progresstime >= level.ex_ugv_actiontime)
		{
			if(canactivate)
			{
				granted = true;
				if(level.ex_ugv_messages == 2 && isPlayer(level.ugvs[index].owner) && self != level.ugvs[index].owner)
					level.ugvs[index].owner iprintlnbold(&"SPECIALS_UGV_ACTIVATED_BY", [[level.ex_pname]](self));
				level thread perkActivate(index, false);
			}
			else if(candeactivate)
			{
				granted = true;
				if(level.ex_ugv_messages && isPlayer(level.ugvs[index].owner) && self != level.ugvs[index].owner)
					level.ugvs[index].owner iprintlnbold(&"SPECIALS_UGV_DEACTIVATED_BY", [[level.ex_pname]](self));
				level thread perkDeactivate(index, false);
			}
		}
	}

	wait( [[level.ex_fpstime]](0.2) );
	self.ugv_action = undefined;
	if(!granted) return(false);
		else if(!candeploy) while(self meleebuttonpressed()) wait( level.ex_fps_frame );
	return(true);
}

//------------------------------------------------------------------------------
// Waypoint management
//------------------------------------------------------------------------------
perkCreateWaypoint(index)
{
	if(level.ex_ugv_waypoints)
	{
		if(level.ex_ugv_waypoints != 1 || !isPlayer(level.ugvs[index].owner)) levelCreateWaypoint(index);
			else level.ugvs[index].owner playerCreateWaypoint(index);
	}
}

perkUpdateWaypoint(index)
{
	if(level.ex_ugv_waypoints)
	{
		if(level.ex_ugv_waypoints != 1 || !isPlayer(level.ugvs[index].owner)) levelUpdateWaypoint(index);
			else level.ugvs[index].owner playerUpdateWaypoint(index);
	}
}

perkDeleteWaypoint(index)
{
	if(level.ex_ugv_waypoints)
	{
		if(level.ex_ugv_waypoints != 1 || !isPlayer(level.ugvs[index].owner)) levelDeleteWaypoint(index);
			else level.ugvs[index].owner playerDeleteWaypoint(index);
	}
}

levelCreateWaypoint(index)
{
	if(!isDefined(level.ugvs) || !isDefined(level.ugvs[index])) return;

	level levelDeleteWaypoint(index);

	if(level.ex_ugv_waypoints == 3 || !isPlayer(level.ugvs[index].owner))
	{
		if(level.ugvs[index].abandoned) shader = game["waypoint_abandoned"];
		else if(level.ugvs[index].activated)
		{
			if(level.ugvs[index].team == "axis") shader = game["waypoint_activated_axis"];
				else shader = game["waypoint_activated_allies"];
		}
		else
		{
			if(level.ugvs[index].team == "axis") shader = game["waypoint_deactivated_axis"];
				else shader = game["waypoint_deactivated_allies"];
		}

		hud_index = levelHudCreate("waypoint_ugv" + index, undefined, level.ugvs[index].body.origin[0], level.ugvs[index].body.origin[1], .6, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
		if(hud_index == -1) return;
	}
	else
	{
		if(level.ugvs[index].abandoned) shader = game["waypoint_abandoned"];
			else if(level.ugvs[index].activated) shader = game["waypoint_activated"];
				else shader = game["waypoint_deactivated"];

		hud_index = levelHudCreate("waypoint_ugv" + index, level.ugvs[index].team, level.ugvs[index].body.origin[0], level.ugvs[index].body.origin[1], .6, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
		if(hud_index == -1) return;
	}

	levelHudSetShader(hud_index, shader, 7, 7);
	levelHudSetWaypoint(hud_index, level.ugvs[index].body.origin[2] + 100, true);
	level.ugvs[index].waypoint = hud_index;
}

levelUpdateWaypoint(index)
{
	if(!isDefined(level.ugvs) || !isDefined(level.ugvs[index])) return;
	if(!isDefined(level.ugvs[index].waypoint)) return;

	levelHudSetXYZ(level.ugvs[index].waypoint, level.ugvs[index].body.origin[0], level.ugvs[index].body.origin[1], level.ugvs[index].body.origin[2] + 100);
}

levelDeleteWaypoint(index)
{
	if(!isDefined(level.ugvs) || !isDefined(level.ugvs[index])) return;
	if(!isDefined(level.ugvs[index].waypoint)) return;

	levelHudDestroy(level.ugvs[index].waypoint);
	level.ugvs[index].waypoint = undefined;
}

playerCreateWaypoint(index)
{
	if(!isDefined(self.ugv_waypoints)) self.ugv_waypoints = [];

	self playerDeleteWaypoint(index);

	if(level.ugvs[index].abandoned) shader = game["waypoint_abandoned"];
		if(level.ugvs[index].activated) shader = game["waypoint_activated"];
			else shader = game["waypoint_deactivated"];

	hud_index = playerHudCreate("waypoint_ugv" + index, level.ugvs[index].body.origin[0], level.ugvs[index].body.origin[1], 0.6, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index == -1) return;
	playerHudSetShader(hud_index, shader, 7, 7);
	playerHudSetWaypoint(hud_index, level.ugvs[index].body.origin[2] + 100, true);

	wp_index = playerAllocateWaypoint();
	self.ugv_waypoints[wp_index].id = hud_index;
}

playerAllocateWaypoint()
{
	for(i = 0; i < self.ugv_waypoints.size; i++)
	{
		if(self.ugv_waypoints[i].inuse == 0)
		{
			self.ugv_waypoints[i].inuse = 1;
			return(i);
		}
	}

	self.ugv_waypoints[i] = spawnstruct();
	self.ugv_waypoints[i].inuse = 1;
	return(i);
}

playerUpdateWaypoint(index)
{
	if(!isDefined(self.ugv_waypoints)) return;

	hud_index = playerHudIndex("waypoint_ugv" + index);
	if(hud_index == -1) return;

	update_element = undefined;
	for(i = 0; i < self.ugv_waypoints.size; i++)
	{
		if(!self.ugv_waypoints[i].inuse) continue;
		if(self.ugv_waypoints[i].id != hud_index) continue;
		update_element = i;
		break;
	}

	if(isDefined(update_element))
		playerHudSetXYZ(self.ugv_waypoints[update_element].id, level.ugvs[index].body.origin[0], level.ugvs[index].body.origin[1], level.ugvs[index].body.origin[2] + 100);
}

playerDeleteWaypoint(index)
{
	if(!isDefined(self.ugv_waypoints)) return;

	hud_index = playerHudIndex("waypoint_ugv" + index);
	if(hud_index == -1) return;

	remove_element = undefined;
	for(i = 0; i < self.ugv_waypoints.size; i++)
	{
		if(!self.ugv_waypoints[i].inuse) continue;
		if(self.ugv_waypoints[i].id != hud_index) continue;
		remove_element = i;
		break;
	}

	if(isDefined(remove_element))
	{
		playerHudDestroy(self.ugv_waypoints[remove_element].id);
		self.ugv_waypoints[remove_element].inuse = 0;
	}
}

//------------------------------------------------------------------------------
// Close proximity explosion callback
//------------------------------------------------------------------------------
cpxUGV(dev_index, cpx_flag, origin, owner, team, entity)
{
	for(index = 0; index < level.ugvs.size; index++)
	{
		if(perkValidateAsTarget(index, undefined))
		{
			switch(cpx_flag)
			{
				case 1:
					dist = int( distance(origin, level.ugvs[index].body.origin) );
					if(dist <= level.ex_devices[dev_index].range)
					{
						damage = int(level.ex_devices[dev_index].maxdamage * ((level.ex_devices[dev_index].range - dist) / level.ex_devices[dev_index].range));
						level.ugvs[index].health -= damage;
					}
					break;
				case 2:
					if(level.ex_ugv_cpx)
					{
						dist = int( distance(origin, level.ugvs[index].body.origin) );
						if(dist <= level.ex_devices[dev_index].range)
						{
							level.ugvs[index].nades++;
							if(level.ugvs[index].nades >= level.ex_ugv_cpx_nades)
							{
								if(level.ex_teamplay && team == level.ugvs[index].team)
								{
									if((level.ex_ugv_cpx & 4) == 4) level thread perkDestroy(index);
									else if((level.ex_ugv_cpx & 2) == 2) level thread perkSabotage(index);
									else if((level.ex_ugv_cpx & 1) == 1) level thread perkDeactivateTimer(index, level.ex_ugv_cpx_timer);
								}
								else
								{
									if((level.ex_ugv_cpx & 32) == 32) level thread perkDestroy(index);
									else if((level.ex_ugv_cpx & 16) == 16) level thread perkSabotage(index);
									else if((level.ex_ugv_cpx & 8) == 8) level thread perkDeactivateTimer(index, level.ex_ugv_cpx_timer);
								}
							}
						}
					}
					break;
				case 4:
					if(level.ugvs[index].body == entity || level.ugvs[index].tracks == entity || level.ugvs[index].tracks_s == entity || level.ugvs[index].gun == entity)
					{
						level.ugvs[index].health -= level.ex_devices[dev_index].maxdamage;
						return;
					}
					break;
				case 8:
					level thread perkDeactivate(index, false);
					break;
				case 16:
					level.ugvs[index].health -= level.ex_devices[dev_index].maxdamage;
					break;
				case 32:
					level.ugvs[index].health -= level.ex_devices[dev_index].maxdamage;
					break;
			}
			wait( level.ex_fps_frame );
		}
	}
}
