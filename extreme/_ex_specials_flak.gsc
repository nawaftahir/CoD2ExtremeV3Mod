#include extreme\_ex_specials;
#include extreme\_ex_controller_hud;
#include extreme\_ex_main_utils;

perkInit(index)
{
	// create perk array
	level.flaks = [];

	// precache models
	[[level.ex_PrecacheModel]]("xmodel/weapon_flak_missile");
	[[level.ex_PrecacheModel]]("xmodel/vehicle_flakvierling_base");
	[[level.ex_PrecacheModel]]("xmodel/vehicle_flakvierling_body");
	[[level.ex_PrecacheModel]]("xmodel/vehicle_flakvierling_guns");

	// precache other shaders
	game["actionpanel_owner"] = "spc_actionpanel_owner";
	[[level.ex_PrecacheShader]](game["actionpanel_owner"]);
	game["actionpanel_enemy"] = "spc_actionpanel_enemy";
	[[level.ex_PrecacheShader]](game["actionpanel_enemy"]);
	game["actionpanel_denied"] = "spc_actionpanel_denied";
	[[level.ex_PrecacheShader]](game["actionpanel_denied"]);

	// precache general purpose waypoints
	if(level.ex_flak_waypoints)
	{
		game["waypoint_abandoned"] = "spc_waypoint_abandoned";
		[[level.ex_PrecacheShader]](game["waypoint_abandoned"]);

		if(level.ex_flak_waypoints != 3)
		{
			game["waypoint_activated"] = "spc_waypoint_activated";
			[[level.ex_PrecacheShader]](game["waypoint_activated"]);
			game["waypoint_deactivated"] = "spc_waypoint_deactivated";
			[[level.ex_PrecacheShader]](game["waypoint_deactivated"]);
		}
	}

	// precache strings
	game["flak_reticle"] = &":    :";
	[[level.ex_PrecacheString]](game["flak_reticle"]);

	// precache effects
	level.ex_effect["flak_shot"] = [[level.ex_PrecacheEffect]]("fx/flakvierling/20mm_flash.efx");
	level.ex_effect["flak_sparks"] = [[level.ex_PrecacheEffect]]("fx/props/radio_sparks_smoke.efx");

	// device registration
	[[level.ex_devRequest]]("flak", ::cpxFlak);
	[[level.ex_devRequest]]("flak_shell");
}

perkInitPost(index)
{
	// perk related precaching after map load

	// precache team related waypoints
	if(level.ex_flak_waypoints == 3)
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

	if(!isDefined(self.flak_moving_timer))
	{
		if((level.ex_arcade_shaders & 8) == 8) self thread extreme\_ex_player_arcade::showArcadeShader(getPerkArcade(index), level.ex_arcade_shaders_perk);
			else self iprintlnbold(&"SPECIALS_FLAK_READY");
	}

	self thread hudNotifySpecial(index);
	approved_angles = [];

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
						if(perkEvenGround(self.origin, self.angles) && perkClearance(self.origin, 10, 4, 80))
						{
							approved_angles = perkGetApprovedAngles(self.origin + (0,0,50), 500, 20, 5);
							if(!isDefined(approved_angles) || !approved_angles.size) self iprintlnbold(&"SPECIALS_BAD_LOCATION");
								else if(self playerActionPanel(-1)) break;
						}
					}
				}
				while(self meleebuttonpressed()) wait( level.ex_fps_frame );
			}
		}
	}

	self thread playerStartUsingPerk(index, true);
	self thread hudNotifySpecialRemove(index);

	level thread perkCreate(self, approved_angles);

	if(level.ex_flak_messages)
	{
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(player == self || !isDefined(player.pers["team"])) continue;

			if(level.ex_teamplay && player.pers["team"] == self.pers["team"]) player iprintlnbold(&"SPECIALS_FLAK_DEPLOYED_TEAM", [[level.ex_pname]](self));
				else player iprintlnbold(&"SPECIALS_FLAK_DEPLOYED_ENEMY", [[level.ex_pname]](self));
		}
	}
}

//------------------------------------------------------------------------------
// Validation
//------------------------------------------------------------------------------
perkEvenGround(origin, angles)
{
	f0 = posForward(origin + (0,0,10), angles, 50);
	fl = posLeft(f0, angles, 35);
	pos = posDown(fl, angles, 0);
	if(distance(fl, pos) > 30)
	{
		self iprintlnbold(&"SPECIALS_BAD_LOCATION_CLEARANCE");
		return(false);
	}
	fr = posRight(f0, angles, 35);
	pos = posDown(fr, angles, 0);
	if(distance(fr, pos) > 30)
	{
		self iprintlnbold(&"SPECIALS_BAD_LOCATION_CLEARANCE");
		return(false);
	}

	b0 = posBack(origin + (0,0,10), angles, 50);
	bl = posLeft(b0, angles, 35);
	pos = posDown(bl, angles, 0);
	if(distance(bl, pos) > 30)
	{
		self iprintlnbold(&"SPECIALS_BAD_LOCATION_CLEARANCE");
		return(false);
	}
	br = posRight(b0, angles, 35);
	pos = posDown(br, angles, 0);
	if(distance(br, pos) > 30)
	{
		self iprintlnbold(&"SPECIALS_BAD_LOCATION_CLEARANCE");
		return(false);
	}

	return(true);
}

perkGetApprovedAngles(center, radius, yaw_step, pitch_step)
{
	approved_angles = [];

	for(y = 0; y < 360; y += yaw_step)
	{
		approved_angle = undefined;

		// try angle -45 first, because it looks nice
		//test_angle = perkTestTriplet(center, (rev(randomIntRange(10, 85)), y, 0), radius);
		test_angle = perkTestTriplet(center, (-45, y, 0), radius);
		if(isDefined(test_angle)) approved_angle = test_angle;
		else
		{
			// then scan angles -40 down to 0, otherwise the skylimit will always win
			for(p = 40; p >= 0; p -= pitch_step)
			{
				test_angle = perkTestTriplet(center, (rev(p), y, 0), radius);
				if(isDefined(test_angle))
				{
					approved_angle = test_angle;
					break;
				}
			}

			// lastly scan angles -50 up to -80
			if(!isDefined(approved_angle))
			{
				for(p = 50; p <= 80; p += pitch_step)
				{
					test_angle = perkTestTriplet(center, (rev(p), y, 0), radius);
					if(isDefined(test_angle))
					{
						approved_angle = test_angle;
						break;
					}
				}
			}
		}

		if(isDefined(approved_angle)) approved_angles[approved_angles.size] = approved_angle;
	}

	return(approved_angles);
}

perkTestTriplet(center, angles, radius)
{
	// this will validate an angle by testing a base angle and 2 adjacent angles
	approved_angle = undefined;
	test_angle = perkTestAngle(center, angles, radius, 0);
	if(isDefined(test_angle))
	{
		yaw = angles[1] - 5;
		if(yaw < 0) yaw = 360 - abs(yaw);
		test_angle = perkTestAngle(center, (angles[0], yaw, angles[2]), radius, 0);
		if(isDefined(test_angle))
		{
			yaw = angles[1] + 5;
			if(yaw > 360) yaw = yaw - 360;
			test_angle = perkTestAngle(center, (angles[0], yaw, angles[2]), radius, 0);
			if(isDefined(test_angle)) approved_angle = test_angle;
		}
	}

	return(approved_angle);
}

perkTestAngle(center, angles, radius, debug)
{
	// this will test a single angle
	test_angle = undefined;
	pos = getForwardLimit(center, angles, radius, true);
	temp_radius = int(distance(center, pos) + 1); // get rid of fractional differences
	if(temp_radius >= radius) test_angle = angles;

	return(test_angle);
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
	if(isDefined(level.flaks))
	{
		for(i = 0; i < level.flaks.size; i++)
			if(level.flaks[i].inuse && isDefined(level.flaks[i].owner) && (level.flaks[i].body == entity || level.flaks[i].guns == entity) ) return(i);
	}

	return(-1);
}

perkValidateAsTarget(index, team)
{
	if(!level.flaks[index].inuse || !level.flaks[index].activated || level.flaks[index].sabotaged || level.flaks[index].destroyed) return(false);
	if(level.flaks[index].health <= 0) return(false);
	if(isDefined(team) && level.ex_teamplay && level.flaks[index].team == team) return(false);
	if(!isDefined(level.flaks[index].owner) || !isPlayer(level.flaks[index].owner)) return(false);
	return(true);
}

//------------------------------------------------------------------------------
// Perk creation and removal
//------------------------------------------------------------------------------
perkCreate(owner, approved_angles)
{
	index = perkAllocate();
	angles = (0, owner.angles[1], 0);
	origin = owner.origin;

	level.flaks[index].health = level.ex_flak_maxhealth;
	level.flaks[index].timer = level.ex_flak_timer * 5;
	level.flaks[index].nades = 0;

	level.flaks[index].approved_angles = approved_angles;
	level.flaks[index].allowattach = true;
	level.flaks[index].mode = 1;

	level.flaks[index].ismoving = false;
	level.flaks[index].isfiring = false;
	level.flaks[index].istargeting = false;

	level.flaks[index].activated = false;
	level.flaks[index].destroyed = false;
	level.flaks[index].sabotaged = false;
	level.flaks[index].abandoned = false;

	level.flaks[index].org_origin = origin;
	level.flaks[index].org_angles = angles;
	level.flaks[index].org_owner = owner;
	level.flaks[index].org_ownernum = owner getEntityNumber();

	// create models
	level.flaks[index].base = spawn("script_model", origin);
	level.flaks[index].base hide();
	level.flaks[index].base setmodel("xmodel/vehicle_flakvierling_base");
	level.flaks[index].base.angles = angles;

	level.flaks[index].body = spawn("script_model", origin + (0,0,40) );
	level.flaks[index].body hide();
	level.flaks[index].body setmodel("xmodel/vehicle_flakvierling_body");
	level.flaks[index].body.angles = angles;

	level.flaks[index].guns = spawn("script_model", origin);
	level.flaks[index].guns hide();
	level.flaks[index].guns setmodel("xmodel/vehicle_flakvierling_guns");
	level.flaks[index].guns.angles = angles;
	level.flaks[index].guns linkTo(level.flaks[index].body, "tag_guns", (0,0,0), (0,0,0));

	level.flaks[index].block_trig = spawn("trigger_radius", origin + (0, 0, 20), 0, 30, 30);
	if(level.flaks[index].allowattach) level.flaks[index].mount_trig = spawn("trigger_radius", origin, 0, level.ex_flak_mount_radius, 50);

	// set owner after creating entities so proximity code can handle it
	level.flaks[index].gunner = level.flaks[index].guns;
	level.flaks[index].owner = owner;
	level.flaks[index].team = owner.pers["team"];

	// wait for player to clear perk location
	while(positionWouldTelefrag(origin)) wait( level.ex_fps_frame );
	wait( [[level.ex_fpstime]](1) ); // to let player get out of trigger zone

	// show models
	level.flaks[index].base show();
	level.flaks[index].body show();
	level.flaks[index].guns show();

	level.flaks[index].block_trig setcontents(1);
	if(level.flaks[index].allowattach) level.flaks[index].mount_trig thread perkTrigger(index);

	// restore timer and owner after moving perk
	if(isDefined(owner.flak_moving_timer))
	{
		level.flaks[index].timer = owner.flak_moving_timer;
		owner.flak_moving_timer = undefined;

		if(isDefined(owner.flak_moving_owner) && isPlayer(owner.flak_moving_owner) && owner.pers["team"] == owner.flak_moving_owner.pers["team"])
			level.flaks[index].owner = owner.flak_moving_owner;
		owner.flak_moving_owner = undefined;
	}

	perkActivate(index, false);
	level thread perkThink(index);
}

perkAllocate()
{
	for(i = 0; i < level.flaks.size; i++)
	{
		if(level.flaks[i].inuse == 0)
		{
			level.flaks[i].inuse = 1;
			return(i);
		}
	}

	level.flaks[i] = spawnstruct();
	level.flaks[i].notification = "flak" + i;
	level.flaks[i].inuse = 1;
	return(i);
}

perkRemoveAll()
{
	if(level.ex_flak && isDefined(level.flaks))
	{
		for(i = 0; i < level.flaks.size; i++)
			if(level.flaks[i].inuse && !level.flaks[i].destroyed) thread perkRemove(i);
	}
}

perkRemoveFrom(player)
{
	for(i = 0; i < level.flaks.size; i++)
		if(level.flaks[i].inuse && isDefined(level.flaks[i].owner) && level.flaks[i].owner == player) thread perkRemove(i);
}

perkRemove(index)
{
	if(!level.flaks[index].inuse) return;
	level notify(level.flaks[index].notification);
	level.flaks[index].destroyed = true; // kills perkThink(index)
	perkDeactivate(index, false);
	wait( [[level.ex_fpstime]](2) );
	perkDeleteWaypoint(index);
	perkFree(index);
}

perkFree(index)
{
	thread levelStopUsingPerk(level.flaks[index].org_ownernum, "flak");
	level.flaks[index].owner = undefined;

	level.flaks[index].block_trig delete();
	if(level.flaks[index].allowattach) level.flaks[index].mount_trig delete();
	level.flaks[index].guns delete();
	level.flaks[index].body delete();
	level.flaks[index].base delete();

	level.flaks[index].inuse = 0;
}

//------------------------------------------------------------------------------
// Perk main logic
//------------------------------------------------------------------------------
perkThink(index)
{
	target = level.flaks[index].guns;
	auto_interval = level.ex_flak_interval * 5;

	for(;;)
	{
		target_old = target;
		target = level.flaks[index].guns;

		// signaled to destroy by proximity checks, or when being moved
		if(level.flaks[index].destroyed) return;

		// remove perk if it reached end of life
		if(level.flaks[index].timer <= 0)
		{
			if(isPlayer(level.flaks[index].owner)) level.flaks[index].owner iprintlnbold(&"SPECIALS_FLAK_REMOVED");
			level thread perkRemove(index);
			return;
		}

/*
		// remove perk if health dropped to 0
		if(level.flaks[index].health <= 0)
		{
			if(level.ex_flak_messages && isPlayer(level.flaks[index].owner)) level.flaks[index].owner iprintlnbold(&"SPECIALS_FLAK_DESTROYED");
			level thread perkRemove(index);
			return;
		}
*/

		// temporarily disable if health drops to 0
		if(level.flaks[index].health <= 0)
		{
			level.flaks[index].health = level.ex_flak_maxhealth;
			level thread perkDeactivateTimer(index, level.ex_flak_cpx_timer);
		}

		// check if owner left the game or switched teams
		if(!level.flaks[index].abandoned)
		{
			// owner left
			if(!isPlayer(level.flaks[index].owner))
			{
				if((level.ex_flak_remove & 1) == 1)
				{
					level thread perkRemove(index);
					return;
				}
				level.flaks[index].abandoned = true;
				level.flaks[index].owner = level.flaks[index].guns;
				perkDeactivate(index, false);
				perkCreateWaypoint(index);
			}
			// owner switched teams
			else if((level.ex_flak_remove & 2) != 2 && level.flaks[index].owner.pers["team"] != level.flaks[index].team)
			{
				level.flaks[index].abandoned = true;
				perkDeleteWaypoint(index);
				level.flaks[index].owner = level.flaks[index].guns;
				perkDeactivate(index, false);
				perkCreateWaypoint(index);
			}
		}

		// check for actions
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];

			if(isAlive(player))
			{
				if(level.flaks[index].inuse && player meleebuttonpressed() && perkInRadius(index, player)) player thread playerActionPanel(index);
			}
		}

		level.flaks[index].timer--;
		wait( [[level.ex_fpstime]](0.2) );
	}
}

perkInRadius(index, player)
{
	if(distance(player.origin, level.flaks[index].guns.origin) < level.ex_flak_actionradius) return(true);
	return(false);
}

perkCanSee(index, player)
{
	cansee = (bullettrace(level.flaks[index].guns.origin + (0, 0, 10), player.origin + (0, 0, 10), false, level.flaks[index].block_trig)["fraction"] == 1);
	if(!cansee) cansee = (bullettrace(level.flaks[index].guns.origin + (0, 0, 10), player.origin + (0, 0, 40), false, level.flaks[index].block_trig)["fraction"] == 1);
	if(!cansee && isDefined(player.ex_eyemarker)) cansee = (bullettrace(level.flaks[index].guns.origin + (0, 0, 10), player.ex_eyemarker.origin, false, level.flaks[index].block_trig)["fraction"] == 1);
	return(cansee);
}

perkOwnership(index, player)
{
	if(!isPlayer(level.flaks[index].owner))
	{
		perkDeleteWaypoint(index);
		level.flaks[index].owner = player;
		level.flaks[index].abandoned = false;
		perkCreateWaypoint(index);

		if(!level.ex_teamplay || player.pers["team"] != level.flaks[index].team) level.flaks[index].team = player.pers["team"];
		level.flaks[index].owner iprintlnbold(&"SPECIALS_FLAK_OWNERSHIP_ABANDONED");
	}
}

//------------------------------------------------------------------------------
// Positioning
//------------------------------------------------------------------------------
perkPosition(index, approved_angle)
{
	level.flaks[index].ismoving = true;

	// rotate body (yaw) to approved angle
	if(approved_angle[1] != level.flaks[index].body.angles[1])
	{
		rotate_angle = (level.flaks[index].body.angles[0], approved_angle[1], level.flaks[index].body.angles[2]);

		fdot = dotNormalize(vectorDot(anglesToForward(level.flaks[index].body.angles), anglesToForward(rotate_angle)));
		fdiff = abs(acos(fdot)); // difference in degrees

		level.flaks[index].body playloopsound("tank_turret_spin");
		rotate_speed = 0.01 + fdiff * 0.025;
		level.flaks[index].body rotateto(rotate_angle, rotate_speed);
		wait( [[level.ex_fpstime]](rotate_speed) );
		level.flaks[index].body stoploopsound();
		level.flaks[index].body playsound("tank_turret_stop");

		wait( [[level.ex_fpstime]](0.5) );
	}

	// rotate guns (pitch) to approved angle
	if(approved_angle[0] != level.flaks[index].guns.angles[0])
	{
		level.flaks[index].guns unlink();
		// guns pitch needs to be normalized after being linked to body
		level.flaks[index].guns.angles = pitchNormalize(anglesNormalize(level.flaks[index].guns.angles));
		rotate_angle = (approved_angle[0], level.flaks[index].guns.angles[1], level.flaks[index].guns.angles[2]);

		fdiff = dif(level.flaks[index].guns.angles[0], rotate_angle[0]);

		level.flaks[index].guns playloopsound("tank_turret_spin");
		rotate_speed = 0.01 + fdiff * 0.025;
		level.flaks[index].guns rotateto(rotate_angle, rotate_speed);
		wait( [[level.ex_fpstime]](rotate_speed) );
		level.flaks[index].guns stoploopsound();
		level.flaks[index].guns linkTo(level.flaks[index].body, "tag_guns", (0,0,0), (approved_angle[0],0,0));

		wait( [[level.ex_fpstime]](0.1) );
	}

	level.flaks[index].ismoving = false;
}

perkPositionQuick(index, approved_angle)
{
	// rotate body (yaw) to approved angle
	if(approved_angle[1] != level.flaks[index].body.angles[1])
	{
		rotate_angle = (level.flaks[index].body.angles[0], approved_angle[1], level.flaks[index].body.angles[2]);
		level.flaks[index].body rotateto(rotate_angle, .1, 0, 0);
		wait( [[level.ex_fpstime]](0.1) );
	}

	// rotate guns (pitch) to approved angle
	if(approved_angle[0] != level.flaks[index].guns.angles[0])
	{
		level.flaks[index].guns unlink();
		level.flaks[index].guns.angles = pitchNormalize(anglesNormalize(level.flaks[index].guns.angles));
		rotate_angle = (approved_angle[0], level.flaks[index].guns.angles[1], level.flaks[index].guns.angles[2]);
		level.flaks[index].guns rotateto(rotate_angle, .1, 0, 0);
		wait( [[level.ex_fpstime]](0.1) );
		level.flaks[index].guns linkTo(level.flaks[index].body, "tag_guns", (0,0,0), (approved_angle[0],0,0));

		wait( [[level.ex_fpstime]](0.1) );
	}
}

perkPositionFlat(index)
{
	// rotate body (pitch) to base position
	if(level.flaks[index].body.angles[0] != 0)
	{
		level.flaks[index].body rotateto((0,level.flaks[index].body.angles[1], level.flaks[index].body.angles[2]), .1, 0, 0);
		wait( [[level.ex_fpstime]](0.1) );
	}

	// rotate guns (pitch) to base position
	level.flaks[index].guns unlink();
	level.flaks[index].guns.angles = pitchNormalize(anglesNormalize(level.flaks[index].guns.angles));
	level.flaks[index].guns rotateto((0, level.flaks[index].guns.angles[1], level.flaks[index].guns.angles[2]), .1, 0, 0);
	wait( [[level.ex_fpstime]](0.1) );
	level.flaks[index].guns linkTo(level.flaks[index].body, "tag_guns", (0,0,0), (0,0,0));

	// in case auto-fire loop sound is still playing
	level.flaks[index].guns stoploopsound();
}

//------------------------------------------------------------------------------
// Perk actions
//------------------------------------------------------------------------------
perkActivate(index, force)
{
	if(!level.flaks[index].inuse || (level.flaks[index].activated && !force)) return;
	perkPosition(index, (-45,level.flaks[index].body.angles[1],level.flaks[index].body.angles[2]));

	level.flaks[index].nades = 0;
	level.flaks[index].activated = true;
	perkCreateWaypoint(index);
}

perkDeactivate(index, forcebarrelup)
{
	if(!level.flaks[index].inuse || (!level.flaks[index].activated && !forcebarrelup)) return;
	level.flaks[index].activated = false;
	perkCreateWaypoint(index);

	if(level.flaks[index].allowattach && isPlayer(level.flaks[index].gunner)) perkDetachPlayer(index, level.flaks[index].gunner);
	while(level.flaks[index].istargeting) wait( level.ex_fps_frame );

	if(forcebarrelup) perkPosition(index, (-85,level.flaks[index].body.angles[1],level.flaks[index].body.angles[2]));
		else perkPosition(index, (20,level.flaks[index].body.angles[1],level.flaks[index].body.angles[2]));
}

perkDeactivateTimer(index, timer)
{
	if(!level.flaks[index].inuse || (!level.flaks[index].activated || level.flaks[index].destroyed)) return;

	if(timer && level.flaks[index].timer > timer)
	{
		perkDeactivate(index, false);
		wait( [[level.ex_fpstime]](timer) );
		if(!level.flaks[index].sabotaged && !level.flaks[index].destroyed && level.flaks[index].timer > 5)
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
	if(!level.flaks[index].inuse || level.flaks[index].sabotaged) return;
	level.flaks[index].sabotaged = true; // stops targeting and firing
	perkMalfunction(index);
	if(level.flaks[index].sabotaged) perkDeactivate(index, true);
}

perkRepair(index)
{
	if(!level.flaks[index].inuse || !level.flaks[index].sabotaged) return;
	level.flaks[index].sabotaged = false;
	perkActivate(index, level.flaks[index].activated);
	level.flaks[index].health = level.ex_flak_maxhealth;
}

perkDestroy(index)
{
	if(!level.flaks[index].inuse || level.flaks[index].destroyed) return;
	level.flaks[index].destroyed = true; // kills perkThink(index)
	perkMalfunction(index);
	perkRemove(index);
}

perkMove(index, player)
{
	if(!level.flaks[index].inuse || isDefined(player.flak_moving_timer)) return;
	level.flaks[index].destroyed = true; // kills perkThink(index)
	player.flak_moving_timer = level.flaks[index].timer;
	player.flak_moving_owner = level.flaks[index].owner;
	wait( [[level.ex_fpstime]](0.5) );
	perkRemove(index);
	player thread playerGiveBackPerk("flak");
}

perkSteal(index, player)
{
	perkDeleteWaypoint(index);
	level.flaks[index].owner = player;
	if(isAlive(player) && (!level.ex_teamplay || player.pers["team"] != level.flaks[index].team))
		level.flaks[index].team = player.pers["team"];
	level.flaks[index].owner iprintlnbold(&"SPECIALS_FLAK_OWNERSHIP");

	if(level.flaks[index].sabotaged) perkRepair(index);
		else if(!level.flaks[index].activated) perkActivate(index, false);
			else perkCreateWaypoint(index);
}

perkMalfunction(index)
{
	for(i = 0; i < 20; i++)
	{
		// quit malfunctioning if perk has been removed or repaired
		if(!level.flaks[index].inuse || (!level.flaks[index].sabotaged && !level.flaks[index].destroyed)) break;

		random_time = randomFloatRange(.1, 1);
		playfx(level.ex_effect["flak_sparks"], level.flaks[index].guns.origin);
		wait( [[level.ex_fpstime]](random_time) );
	}
}

//------------------------------------------------------------------------------
// Action panel
//------------------------------------------------------------------------------
playerActionPanel(index)
{
	self endon("kill_thread");

	if(isDefined(self.flak_action) || !isAlive(self) || !self isOnGround()) return(false);

	// if this is a deployment call (index -1), first check basic requirements before setting flak_action flag
	candeploy = false;
	if(index == -1)
	{
		if(self.ex_moving || self [[level.ex_getstance]](false) == 2) return(false);
		candeploy = true;
	}

	self.flak_action = true;

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
		if(self == level.flaks[index].owner && (!level.ex_teamplay || self.pers["team"] == level.flaks[index].team))
		{
			canactivate = ((level.ex_flak_owneraction & 1) == 1 && !level.flaks[index].activated && !level.flaks[index].sabotaged && !level.flaks[index].destroyed);
			canadjust = (mayadjust && (level.ex_flak_owneraction & 2) == 2 && level.flaks[index].activated && !level.flaks[index].sabotaged && !level.flaks[index].destroyed);
			canrepair = ((level.ex_flak_owneraction & 4) == 4 && level.flaks[index].sabotaged && !level.flaks[index].destroyed);
			canmove = ((level.ex_flak_owneraction & 8) == 8 && !level.flaks[index].sabotaged && !level.flaks[index].destroyed && !playerPerkIsLocked("flak", false));
			if(!canactivate && !canadjust && !canrepair && !canmove)
			{
				self.flak_action = undefined;
				return(false);
			}
		}
		// check teammates actions
		else if(level.ex_teamplay && self.pers["team"] == level.flaks[index].team)
		{
			canactivate = ((level.ex_flak_teamaction & 1) == 1 && !level.flaks[index].activated && !level.flaks[index].sabotaged && !level.flaks[index].destroyed);
			canadjust = (mayadjust && (level.ex_flak_teamaction & 2) == 2 && level.flaks[index].activated && !level.flaks[index].sabotaged && !level.flaks[index].destroyed);
			canrepair = ((level.ex_flak_teamaction & 4) == 4 && level.flaks[index].sabotaged && !level.flaks[index].destroyed);
			canmove = ((level.ex_flak_teamaction & 8) == 8 && !level.flaks[index].sabotaged && !level.flaks[index].destroyed && !playerPerkIsLocked("flak", false));
			if(!canactivate && !canadjust && !canrepair && !canmove)
			{
				self.flak_action = undefined;
				return(false);
			}
		}
		// check enemy actions
		else if(!level.ex_teamplay || self.pers["team"] != level.flaks[index].team)
		{
			panel = game["actionpanel_enemy"];
			candeactivate = ((level.ex_flak_enemyaction & 1) == 1 && level.flaks[index].activated && !level.flaks[index].sabotaged && !level.flaks[index].destroyed);
			cansabotage = ((level.ex_flak_enemyaction & 2) == 2 && !level.flaks[index].sabotaged && !level.flaks[index].destroyed);
			candestroy = ((level.ex_flak_enemyaction & 4) == 4 && !level.flaks[index].destroyed);
			cansteal = ((level.ex_flak_enemyaction & 8) == 8 && !level.flaks[index].destroyed);
			if(!candeactivate && !cansabotage && !candestroy && !cansteal)
			{
				self.flak_action = undefined;
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
		playerHudScale(hud_index, level.ex_flak_actiontime * 4, 0, 200, 11);
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
		if(!candeploy && !level.flaks[index].inuse) break;
		if(!candeploy && !perkInRadius(index, self) && !perkCanSee(index, self)) break;

		wait( level.ex_fps_frame );
		progresstime += level.ex_fps_frame;
		if(progresstime >= level.ex_flak_actiontime * actiontimer_autostop) break;
	}

	playerHudDestroy("perk_action_a1");
	playerHudDestroy("perk_action_a2");
	playerHudDestroy("perk_action_a3");
	playerHudDestroy("perk_action_a4");
	playerHudDestroy("perk_action_pb");
	playerHudDestroy("perk_action_bg");

	if(candeploy && progresstime >= level.ex_flak_actiontime) granted = true;
	if(!candeploy && level.flaks[index].inuse)
	{
		// 4th action (8 second boundary by default)
		if(!granted && progresstime >= level.ex_flak_actiontime * 4)
		{
			if(canmove)
			{
				granted = true;
				if(level.ex_flak_messages == 2 && isPlayer(level.flaks[index].owner) && self != level.flaks[index].owner)
					level.flaks[index].owner iprintlnbold(&"SPECIALS_FLAK_MOVED_BY", [[level.ex_pname]](self));
				level thread perkMove(index, self);
			}
			else if(cansteal)
			{
				granted = true;
				if(level.ex_flak_messages && isPlayer(level.flaks[index].owner) && self != level.flaks[index].owner)
					level.flaks[index].owner iprintlnbold(&"SPECIALS_FLAK_STOLEN_BY", [[level.ex_pname]](self));
				level thread perkSteal(index, self);
			}
		}

		// 3rd action (6 second boundary by default)
		if(!granted && progresstime >= level.ex_flak_actiontime * 3)
		{
			if(canrepair)
			{
				granted = true;
				if(level.ex_flak_messages == 2 && isPlayer(level.flaks[index].owner) && self != level.flaks[index].owner)
					level.flaks[index].owner iprintlnbold(&"SPECIALS_FLAK_REPAIRED_BY", [[level.ex_pname]](self));
				level thread perkRepair(index);
			}
			else if(candestroy)
			{
				granted = true;
				if(level.ex_flak_messages && isPlayer(level.flaks[index].owner) && self != level.flaks[index].owner)
					level.flaks[index].owner iprintlnbold(&"SPECIALS_FLAK_DESTROYED_BY", [[level.ex_pname]](self));
				level thread perkDestroy(index);
			}
		}

		// 2nd action (4 second boundary by default)
		if(!granted && progresstime >= level.ex_flak_actiontime * 2)
		{
			if(canadjust)
			{
				granted = true;
				if(level.ex_flak_messages == 2 && isPlayer(level.flaks[index].owner) && self != level.flaks[index].owner)
					level.flaks[index].owner iprintlnbold(&"SPECIALS_FLAK_ADJUSTED_BY", [[level.ex_pname]](self));
				level thread perkAdjust(index, self);
			}
			else if(cansabotage)
			{
				granted = true;
				if(level.ex_flak_messages && isPlayer(level.flaks[index].owner) && self != level.flaks[index].owner)
					level.flaks[index].owner iprintlnbold(&"SPECIALS_FLAK_SABOTAGED_BY", [[level.ex_pname]](self));
				level thread perkSabotage(index);
			}
		}

		// 1st action (2 second boundary by default)
		if(!granted && progresstime >= level.ex_flak_actiontime)
		{
			if(canactivate)
			{
				granted = true;
				if(level.ex_flak_messages == 2 && isPlayer(level.flaks[index].owner) && self != level.flaks[index].owner)
					level.flaks[index].owner iprintlnbold(&"SPECIALS_FLAK_ACTIVATED_BY", [[level.ex_pname]](self));
				level thread perkActivate(index, false);
			}
			else if(candeactivate)
			{
				granted = true;
				if(level.ex_flak_messages && isPlayer(level.flaks[index].owner) && self != level.flaks[index].owner)
					level.flaks[index].owner iprintlnbold(&"SPECIALS_FLAK_DEACTIVATED_BY", [[level.ex_pname]](self));
				level thread perkDeactivate(index, false);
			}
		}
	}

	wait( [[level.ex_fpstime]](0.2) );
	self.flak_action = undefined;
	if(!granted) return(false);
		else if(!candeploy) while(self meleebuttonpressed()) wait( level.ex_fps_frame );
	return(true);
}

//------------------------------------------------------------------------------
// Mounting
//------------------------------------------------------------------------------
perkTrigger(index)
{
	level endon("ex_gameover");
	level endon(level.flaks[index].notification);

	while(1)
	{
		self waittill("trigger", player);

		if(isDefined(player.flak_handling) || isPlayer(level.flaks[index].gunner))
		{
			while(isDefined(player.flak_handling) || isPlayer(level.flaks[index].gunner)) wait( [[level.ex_fpstime]](1) );
			continue;
		}
		prevent_entry = false;
		switch(level.ex_flak_mount)
		{
			case 0: if(player != level.flaks[index].owner) prevent_entry = true; break;
			case 1: if(player.pers["team"] != level.flaks[index].team) prevent_entry = true; break;
		}
		if(!prevent_entry && player useButtonPressed()) level thread perkAttachPlayer(index, player);
	}
}

perkAttachPlayer(index, player)
{
	level endon(level.flaks[index].notification);
	player endon("kill_thread");
	player endon("flak_detach");

	while(player useButtonPressed()) wait( level.ex_fps_frame );

	if(!isPlayer(level.flaks[index].gunner) && isDefined(player))
	{
		level.flaks[index].gunner = player;
		player.flak_handling = index;
		player [[level.ex_dWeapon]]();

		perkDeleteWaypoint(index);
		level thread perkMonitorPlayerKill(index, player);
		level thread perkMonitorPlayerKeys(index, player);

		flak = level.flaks[index].body;

		if(level.flaks[index].ismoving || level.flaks[index].isfiring)
		{
			player linkTo(flak, "tag_player", (0,0,0), (0,0,0));
			player setPlayerAngles(flak.angles);
			while(level.flaks[index].ismoving || level.flaks[index].isfiring) wait( level.ex_fps_frame );
			perkPositionFlat(index);
		}
		else
		{
			perkPositionFlat(index);
			player linkTo(flak, "tag_player", (0,0,0), (0,0,0));
		}

		iNewPitch = flak.angles[0];
		iNewYaw = flak.angles[1];
		iOldPitch = iNewPitch;
		iOldYaw = iNewYaw;

		while(isPlayer(player) && isAlive(player))
		{
			angles = flak.angles;

			temp = flak.origin + [[level.ex_vectorscale]](anglesToForward(player getPlayerAngles()), 10000);
			lookDirection = anglesNormalize(vectorToAngles(temp - flak.origin));

			temp = flak.origin + [[level.ex_vectorscale]](anglesToForward(angles), -10000);
			backDirection = anglesNormalize(vectorToAngles(temp - flak.origin));

			hdirection = angleDir(lookDirection[1], backDirection[1]);
			if(hdirection != 0)
			{
				hdiff = angleDiff(lookDirection[1], angles[1]);
				iTempYaw = hdirection;
				iYaw = hdiff;
				if(iYaw > 80) iYaw = 80;
				iTempYaw *= hdiff * (15 / (15 + iYaw));
				iNewYaw = angles[1] + iTempYaw;
			}

			vdirection = angleDir(angles[0], lookDirection[0]);
			temp = lookDirection[0];
			if( temp > 90 || temp < -90) temp -= 360;
			vdirection = angleDir(angles[0], angleNormalize(temp));
			if(vdirection != 0)
			{
				vdiff = angleDiff(lookDirection[0], angles[0]);
				iTempPitch = vdirection * (vdiff * (10 / 30));
				iNewPitch = angles[0] + iTempPitch;
			}

			if(iNewPitch > 0)
			{
				iNewPitch = 0;
				perkPlayerHUD(player, (1,0,0), false);
			}
			else if(iNewPitch < -70)
			{
				iNewPitch = -70;
				perkPlayerHUD(player, (1,0,0), false);
			}
			else perkPlayerHUD(player, (0,1,0), false);

			if(iNewPitch != iOldPitch || iNewYaw != iOldYaw)
			{
				flak rotateTo((iNewPitch, iNewYaw, 0), .1, 0, 0);
				iOldPitch = iNewPitch;
				iOldYaw = iNewYaw;
			}

			wait( [[level.ex_fpstime]](0.1) );
		}
	}
}

perkMonitorPlayerKeys(index, player)
{
	level endon(level.flaks[index].notification);
	player endon("kill_thread");

	mode1_gun = -1;
	mode2_gun = 0;

	while(isDefined(player) && isAlive(player))
	{
		wait( [[level.ex_fpstime]](0.1) );
		if(player useButtonPressed())
		{
			while(isDefined(player) && player useButtonPressed()) wait( [[level.ex_fpstime]](0.1) );
			break;
		}
		else if(player meleeButtonPressed())
		{
			oldmode = level.flaks[index].mode;
			if(level.flaks[index].mode == 1 && level.ex_flak_firemode) level.flaks[index].mode = 2;
				else if(level.flaks[index].mode == 2 && level.ex_flak_firemode > 1) level.flaks[index].mode = 4;
					else level.flaks[index].mode = 1;

			while(isDefined(player) && player meleeButtonPressed()) wait( [[level.ex_fpstime]](0.1) );
		}
		else if(player attackButtonPressed())
		{
			// do not allow manual fire if still finishing auto movement or fire
			if(level.flaks[index].ismoving || level.flaks[index].isfiring) continue;

			// only play sound once, even when firing multiple guns simultaneously
			level.flaks[index].guns playsound("Flak88_fire");

			if(level.flaks[index].mode == 1)
			{
				mode1_gun++;
				if(mode1_gun > 3) mode1_gun = 0;
				thread perkFireShell(index, mode1_gun);
			}
			else if(level.flaks[index].mode == 2)
			{
				mode2_gun = !mode2_gun;
				if(mode2_gun == 0)
				{
					thread perkFireShell(index, 0);
					thread perkFireShell(index, 3);
				}
				else
				{
					thread perkFireShell(index, 1);
					thread perkFireShell(index, 2);
				}
			}
			else
			{
				thread perkFireShell(index, 0);
				thread perkFireShell(index, 1);
				thread perkFireShell(index, 2);
				thread perkFireShell(index, 3);
			}

			wait( [[level.ex_fpstime]](0.25) );
		}
	}

	thread perkDetachPlayer(index, player);
}

perkMonitorPlayerKill(index, player)
{
	level endon(level.flaks[index].notification);

	player waittill("kill_thread");

	// only reposition flak if not moving or firing (in case player mounts and unmounts flak
	// while still moving or firing in auto mode)
	if(!level.flaks[index].ismoving && !level.flaks[index].isfiring) perkPositionFlat(index);

	thread perkDetachPlayer(index, player);
}

perkDetachPlayer(index, player)
{
	perkCreateWaypoint(index);
	level.flaks[index].gunner = level.flaks[index].guns;
	if(isDefined(player))
	{
		player notify("flak_detach");
		player.flak_handling = undefined;
		perkPlayerHUD(player, (1,0,0), true);
		if(isAlive(player))
		{
			player unlink();
			player [[level.ex_eWeapon]]();
			player freezecontrols(false);
		}
	}

	// only reposition flak if not moving or firing (in case player mounts and unmounts flak
	// while still moving or firing in auto mode)
	if(!level.flaks[index].ismoving && !level.flaks[index].isfiring) perkPositionFlat(index);
}

perkPlayerHUD(player, color, remove)
{
	if(!isDefined(remove)) remove = true;
	if(!remove)
	{
		hud_index = player playerHudCreate("special_flakreticle", 0, 2, 0.7, color, 1, 0, "center_safearea", "center_safearea", "center", "middle", false, false);
		if(hud_index == -1) return;
		player playerHudSetText(hud_index, game["flak_reticle"]);
	}
	else player playerHudDestroy("special_flakreticle");
}

angleDir(angleNew, angleOld)
{
	if(angleNew <= 180)
	{
		temp = angleNew + 180;
		if(angleOld >= angleNew && angleOld <= temp) iResult = 1;
			else iResult = -1;
	}
	else
	{
		temp = angleNew - 180;
		if(angleOld >= temp && angleOld <= angleNew) iResult = -1;
			else iResult = 1;
	}

	return(iResult);
}

angleDiff(angleNew, angleOld)
{
	val1 = angleMod(angleNew, true);
	val2 = angleMod(angleOld, true);

	if(val1 > val2)
	{
		temp = val1;
		val1 = val2;
		val2 = temp;
	}

	if((val2 - val1) < 180) return(val2 - val1);
		else return((360 - val2) + val1);
}

angleMod(angle, positive)
{
	if(angle < 0)
	{
		if(angle < -1000)
		{
			temp = int(angle / -360) - 1;
			angle -= (-360 * temp);
		}
		while(angle <= -360) angle += 360;
		if(positive) angle = (360 + angle);
	}
	else if(angle > 0)
	{
		if(angle > 1000)
		{
			temp = int(angle / 360) - 1;
			angle -= (360 * temp);
		}
		while(angle >= 360) angle -= 360;
	}

	return(angle);
}

//------------------------------------------------------------------------------
// Shell handling
//------------------------------------------------------------------------------
perkFireShell(index, gun)
{
	shell = spawn("script_model", (0,0,0));
	shell hide();
	shell setmodel("xmodel/weapon_flak_missile");

	// align shell with gun barrel
	playfxontag(level.ex_effect["flak_shot"], level.flaks[index].guns, "tag_flash" + gun);
	shell linkto(level.flaks[index].guns, "tag_flash" + gun, (0,0,0), (0,0,0));

	// must have a small delay to update shell origin and angles
	wait( level.ex_fps_frame );
	shell unlink();

	// make sure the shell is not touching the barrel, or the bullettrace will fail
	shell.origin = shell.origin + [[level.ex_vectorscale]](anglesToForward(shell.angles), 20);
	shell show();
	shell thread perkTrackShell(index);
}

perkTrackShell(index)
{
	endpos = self.origin + [[level.ex_vectorscale]](anglesToForward(self.angles), 100000);
	trace = bulletTrace(self.origin, endpos, true, self);

	// if bullettrace hit a moving target, extend the end position to allow the shell to hit it
	if(isDefined(trace["entity"])) trace["position"] = trace["position"] + [[level.ex_vectorscale]](anglesToForward(self.angles), 2000);

	shell_ttl = calcTime(self.origin, trace["position"], 100);
	if(shell_ttl > 0) self moveto(trace["position"], shell_ttl, 0, 0);

	lookahead = [[level.ex_vectorscale]](anglesToForward(self.angles), 200);
	while(shell_ttl > 0)
	{
		wait( level.ex_fps_frame );
		shell_ttl -= level.ex_fps_frame;

		endpos = self.origin + lookahead;
		trace = bulletTrace(self.origin, endpos, true, self);
		if(trace["fraction"] != 1) break;
	}

	self hide();

	// handle explosion and damage
	if(isDefined(trace["entity"]))
	{
		if(isPlayer(level.flaks[index].gunner) && level.flaks[index].gunner.sessionstate != "spectator")
		{
			if(perkVerifyEntity(trace["entity"], level.flaks[index].gunner.pers["team"]))
			{
				// device info to pass on
				device_info = [[level.ex_devInfo]](level.flaks[index].gunner, level.flaks[index].gunner.pers["team"]);
				device_info.entity = trace["entity"];
				device_info.dodamage = true;

				self thread [[level.ex_devExplode]]("flak_shell", device_info);
			}
		}
	}

	wait(1);
	self delete();
}

perkVerifyEntity(entity, team)
{
	if((level.ex_flak_target & 64) == 64 && extreme\_ex_specials_gml::perkCheckEntity(entity) != -1) return(true);
	if((level.ex_flak_target & 32) == 32 && extreme\_ex_specials_flak::perkCheckEntity(entity) != -1) return(true);
	if((level.ex_flak_target & 16) == 16 && extreme\_ex_main_gunship::gunshipCheckEntity(entity) != -1) return(true);
	if((level.ex_flak_target & 16) == 16 && extreme\_ex_specials_gunship::perkCheckEntity(entity) != -1) return(true);
	if((level.ex_flak_target &  8) ==  8 && extreme\_ex_specials_helicopter::perkCheckEntity(entity) != -1) return(true);
	if((level.ex_flak_target &  4) ==  4 && extreme\_ex_controller_airtraffic::planeCheckEntity(entity, level.PLANE_PURP_WMD, team) != -1) return(true);
	if((level.ex_flak_target &  2) ==  2 && extreme\_ex_controller_airtraffic::planeCheckEntity(entity, level.PLANE_PURP_AMBIENT, team) != -1) return(true);
	if((level.ex_flak_target &  1) ==  1 && isPlayer(entity) && entity.sessionstate == "playing" && (!level.ex_teamplay || entity.pers["team"] != team)) return(true);
	return(false);
}

//------------------------------------------------------------------------------
// Waypoint management
//------------------------------------------------------------------------------
perkCreateWaypoint(index)
{
	if(level.ex_flak_waypoints)
	{
		if(level.ex_flak_waypoints != 1 || !isPlayer(level.flaks[index].owner)) levelCreateWaypoint(index);
			else level.flaks[index].owner playerCreateWaypoint(index);
	}
}

perkDeleteWaypoint(index)
{
	if(level.ex_flak_waypoints)
	{
		if(level.ex_flak_waypoints != 1 || !isPlayer(level.flaks[index].owner)) levelDeleteWaypoint(index);
			else level.flaks[index].owner playerDeleteWaypoint(index);
	}
}

levelCreateWaypoint(index)
{
	if(!isDefined(level.flaks) || !isDefined(level.flaks[index])) return;

	level levelDeleteWaypoint(index);

	if(level.ex_flak_waypoints == 3 || !isPlayer(level.flaks[index].owner))
	{
		if(level.flaks[index].abandoned) shader = game["waypoint_abandoned"];
		else if(level.flaks[index].activated)
		{
			if(level.flaks[index].team == "axis") shader = game["waypoint_activated_axis"];
				else shader = game["waypoint_activated_allies"];
		}
		else
		{
			if(level.flaks[index].team == "axis") shader = game["waypoint_deactivated_axis"];
				else shader = game["waypoint_deactivated_allies"];
		}

		hud_index = levelHudCreate("waypoint_flak" + index, undefined, level.flaks[index].org_origin[0], level.flaks[index].org_origin[1], .6, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
		if(hud_index == -1) return;
	}
	else
	{
		if(level.flaks[index].abandoned) shader = game["waypoint_abandoned"];
			else if(level.flaks[index].activated) shader = game["waypoint_activated"];
				else shader = game["waypoint_deactivated"];

		hud_index = levelHudCreate("waypoint_flak" + index, level.flaks[index].team, level.flaks[index].org_origin[0], level.flaks[index].org_origin[1], .6, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
		if(hud_index == -1) return;
	}

	levelHudSetShader(hud_index, shader, 7, 7);
	levelHudSetWaypoint(hud_index, level.flaks[index].org_origin[2] + 100, true);
	level.flaks[index].waypoint = hud_index;
}

levelDeleteWaypoint(index)
{
	if(!isDefined(level.flaks) || !isDefined(level.flaks[index])) return;
	if(!isDefined(level.flaks[index].waypoint)) return;

	levelHudDestroy(level.flaks[index].waypoint);
	level.flaks[index].waypoint = undefined;
}

playerCreateWaypoint(index)
{
	if(!isDefined(self.flak_waypoints)) self.flak_waypoints = [];

	self playerDeleteWaypoint(index);

	if(level.flaks[index].abandoned) shader = game["waypoint_abandoned"];
		if(level.flaks[index].activated) shader = game["waypoint_activated"];
			else shader = game["waypoint_deactivated"];

	hud_index = playerHudCreate("waypoint_flak" + index, level.flaks[index].org_origin[0], level.flaks[index].org_origin[1], 0.6, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index == -1) return;
	playerHudSetShader(hud_index, shader, 7, 7);
	playerHudSetWaypoint(hud_index, level.flaks[index].org_origin[2] + 100, true);

	wp_index = playerAllocateWaypoint();
	self.flak_waypoints[wp_index].id = hud_index;
}

playerAllocateWaypoint()
{
	for(i = 0; i < self.flak_waypoints.size; i++)
	{
		if(self.flak_waypoints[i].inuse == 0)
		{
			self.flak_waypoints[i].inuse = 1;
			return(i);
		}
	}

	self.flak_waypoints[i] = spawnstruct();
	self.flak_waypoints[i].inuse = 1;
	return(i);
}

playerDeleteWaypoint(index)
{
	if(!isDefined(self.flak_waypoints)) return;

	hud_index = playerHudIndex("waypoint_flak" + index);
	if(hud_index == -1) return;

	remove_element = undefined;
	for(i = 0; i < self.flak_waypoints.size; i++)
	{
		if(!self.flak_waypoints[i].inuse) continue;
		if(self.flak_waypoints[i].id != hud_index) continue;
		remove_element = i;
		break;
	}

	if(isDefined(remove_element))
	{
		playerHudDestroy(self.flak_waypoints[remove_element].id);
		self.flak_waypoints[remove_element].inuse = 0;
	}
}

//------------------------------------------------------------------------------
// Close proximity explosion callback
//------------------------------------------------------------------------------
cpxFlak(dev_index, cpx_flag, origin, owner, team, entity)
{
	for(index = 0; index < level.flaks.size; index++)
	{
		if(perkValidateAsTarget(index, undefined))
		{
			switch(cpx_flag)
			{
				case 1:
					dist = int( distance(origin, level.flaks[index].org_origin) );
					if(dist <= level.ex_devices[dev_index].range)
					{
						damage = int(level.ex_devices[dev_index].maxdamage * ((level.ex_devices[dev_index].range - dist) / level.ex_devices[dev_index].range));
						level.flaks[index].health -= damage;
					}
					break;
				case 2:
					if(level.ex_flak_cpx)
					{
						dist = int( distance(origin, level.flaks[index].org_origin) );
						if(dist <= level.ex_devices[dev_index].range)
						{
							level.flaks[index].nades++;
							if(level.flaks[index].nades >= level.ex_flak_cpx_nades)
							{
								if(level.ex_teamplay && team == level.flaks[index].team)
								{
									if((level.ex_flak_cpx & 4) == 4) level thread perkDestroy(index);
									else if((level.ex_flak_cpx & 2) == 2) level thread perkSabotage(index);
									else if((level.ex_flak_cpx & 1) == 1) level thread perkDeactivateTimer(index, level.ex_flak_cpx_timer);
								}
								else
								{
									if((level.ex_flak_cpx & 32) == 32) level thread perkDestroy(index);
									else if((level.ex_flak_cpx & 16) == 16) level thread perkSabotage(index);
									else if((level.ex_flak_cpx & 8) == 8) level thread perkDeactivateTimer(index, level.ex_flak_cpx_timer);
								}
							}
						}
					}
					break;
				case 4:
					if(level.flaks[index].body == entity || level.flaks[index].guns == entity)
					{
						level.flaks[index].health -= level.ex_devices[dev_index].maxdamage;
						return;
					}
					break;
				case 8:
					level thread perkDeactivate(index, false);
					break;
				case 16:
					level.flaks[index].health -= level.ex_devices[dev_index].maxdamage;
					break;
				case 32:
					level.flaks[index].health -= level.ex_devices[dev_index].maxdamage;
					break;
			}
			wait( level.ex_fps_frame );
		}
	}
}
