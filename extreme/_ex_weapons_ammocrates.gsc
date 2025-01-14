#include extreme\_ex_controller_airtraffic;
#include extreme\_ex_controller_hud;
#include extreme\_ex_main_utils;
#include extreme\_ex_weapons;

main()
{
	level endon("ex_gameover");

	spawnpoints = getentarray("mp_tdm_spawn", "classname");
	if(!spawnpoints.size) spawnpoints = getentarray("mp_dm_spawn", "classname");
	if(spawnpoints.size < 2) return;

	// initialize
	ammocratesInit(spawnpoints);

	if(level.ex_amc_chutein)
	{
		// chuting crate logic
		drop_wait = level.ex_amc_chutein;
		drop_switcher = 0;
		
		while(level.ex_amc_perteam)
		{
			wait( [[level.ex_fpstime]](drop_wait) );
			drop_wait = level.ex_amc_chutein_pause_all;

			// if entities monitor in defcon 3 or lower, suspend
			if(level.ex_entities_defcon < 4) continue;

			drop_count = 0;
			if(level.ex_amc_chutein_neutral)
			{
				ammocrate_team = "neutral";
				drop_count = (level.ex_amc_perteam * 2) - getAmmocratesAllocated();
				if(drop_count < 0) drop_count = 0; // merely to let debug messages look nice
				if(drop_count > 0 && level.ex_amc_chutein_slice)
				{
					if(level.ex_amc_chutein_slice < drop_count)
						drop_count = level.ex_amc_chutein_slice;
					drop_wait = level.ex_amc_chutein_pause_slice;
				}
			}
			else
			{
				if(drop_switcher%2 == 0) ammocrate_team = "allies";
					else ammocrate_team = "axis";

				drop_count = level.ex_amc_perteam - getAmmocratesForTeam(ammocrate_team);
				if(drop_count < 0) drop_count = 0; // merely to let debug messages look nice
				if(drop_count > 0)
				{
					if(level.ex_amc_chutein_slice && level.ex_amc_chutein_slice < drop_count)
						drop_count = level.ex_amc_chutein_slice;
					drop_switcher++;
					if(drop_switcher%2 == 0) drop_wait = level.ex_amc_chutein_pause_slice;
						else drop_wait = 0.5;
				}
			}

			if(level.ex_log_ammocrate && drop_count) logprint("AMC: dropping " + drop_count + " crates for " + ammocrate_team + "\n");

			// create support entity
			airsupport = spawn("script_origin", (0,0,0));

			// preferred angle
			plane_angle = randomInt(360);

			plane_xcount = 0;
			for(i = 0; i < drop_count; i++)
			{
				crate_index = getAmmocrateIndex();
				if(crate_index != 999)
				{
					ammocrate_compass = level.ex_amc_compass;
					// if not a neutral drop, don't let a team allocate all or too many compass slots at once
					if(!level.ex_amc_chutein_neutral && !level.ex_amc_chutein_slice && (i > level.ex_amc_maxobjteam - 1)) ammocrate_compass = false;
					if(level.ex_log_ammocrate) logprint("AMC: crate " + crate_index + " has compass request flag: " + ammocrate_compass + "\n");
					ammoCrateAlloc(crate_index, ammocrate_team, ammocrate_compass);
					if(level.ex_log_ammocrate) logprint("AMC: crate " + crate_index + " acquired objective index: " + level.ammocrates[crate_index].objective + "\n");

					//level thread ammoCratePlane(crate_index, plane_angle);
					setAmmocrateStatus(crate_index, "inplane");

					// target point
					targetpos = level.ammocrates[crate_index].spawnpoint;
					x = targetpos[0] - 50 + randomInt(50);
					y = targetpos[1] - 50 + randomInt(50);
					targetpos = (x,y,targetpos[2]);

					// drop point
					droppos = getDropPosFromTarget(targetpos, 500);

					// keep track of airplane requests that make it through
					plane_xcount++;

					// request a slot
					plane_slot = planeSlot(level.PLANE_PURP_AMMO);

					// create the airplane
					plane_index = airsupport planeCreate(plane_slot, level.PLANE_TYPE_BOMBER, level, ammocrate_team, droppos, plane_angle);

					// add payload to airplane
					planeAddPayload(plane_index, "none", targetpos, 1, false);

					// we handle the payload via events
					planeAddNotify(plane_index, "drop_crate"+crate_index, "crash_crate"+crate_index);

					// start the event monitors for health and payload
					level thread ammoCrateCrashMonitor(plane_index, crate_index);
					level thread ammoCrateDropMonitor(plane_index, crate_index);

					// fly baby
					thread planeGo(plane_index, "plane_finished");
				}
				else level.ex_amc_perteam--;
			}

			// wait for all planes to finish
			for(i = 0; i < plane_xcount; i++) airsupport waittill("plane_finished");

			// delete support entity
			airsupport delete();

			if(drop_count == 0)
			{
				if(!level.ex_amc_chutein_lifespan) break;
				level thread ammocratesOnGroundMonitor();
				level waittill("ammocrate_countdown");
				drop_wait += level.ex_amc_chutein_lifespan;
				if(level.ex_log_ammocrate) logprint("AMC: all crates touched ground. Waiting " + drop_wait + " seconds for next drop\n");
			}
		}
	}
	else
	{
		// fixed crate logic
		drop_count = level.ex_amc_perteam;
		ammocrate_team = "allies";
		for(i = 0; i < 2; i++)
		{
			if(level.ex_log_ammocrate && drop_count) logprint("AMC: dropping " + drop_count + " crates for " + ammocrate_team + "\n");

			for(j = 0; j < drop_count; j++)
			{
				crate_index = getAmmocrateIndex();
				if(crate_index != 999)
				{
					ammocrate_compass = level.ex_amc_compass;
					// don't let a team allocate all or too many compass slots at once
					if(j > level.ex_amc_maxobjteam - 1) ammocrate_compass = false;
					if(level.ex_log_ammocrate) logprint("AMC: crate " + crate_index + " has compass request flag: " + ammocrate_compass + "\n");
					ammoCrateAlloc(crate_index, ammocrate_team, ammocrate_compass);
					if(level.ex_log_ammocrate) logprint("AMC: crate " + crate_index + " acquired objective index: " + level.ammocrates[crate_index].objective + "\n");
					level thread ammoCrateFixed(crate_index);
				}
			}

			ammocrate_team = "axis";
		}
	}
}

ammocratesOnGroundMonitor()
{
	level endon("ex_gameover");

	// wait in case all crates already touched ground (the monitor would fire its notify before the waittill started).
	wait( [[level.ex_fpstime]](0.1) );
	if(level.ex_log_ammocrate) logprint("AMC: waiting for " + getAmmocratesAllocated() + " crates to touch ground\n");
	while(getAmmocratesAllocated() != getAmmocratesWithStatus("onground")) wait( [[level.ex_fpstime]](1) );
	level notify("ammocrate_countdown");
}

ammocratesInit(spawnpoints)
{
	level.ammocrates = [];
	level.ex_amc_maxobjteam = 4;

	for(i = 0; i < spawnpoints.size; i++)
	{
		level.ammocrates[i] = spawnstruct();
		level.ammocrates[i].spawnpoint = spawnpoints[i].origin;
		level.ammocrates[i].inuse = false;
		level.ammocrates[i].objective = 0;
		level.ammocrates[i].team = "none";
		level.ammocrates[i].status = "none";
	}

	if(level.ex_teamplay)
	{
		if((level.ex_amc_perteam * 2) > level.ammocrates.size)
			level.ex_amc_perteam = int(level.ammocrates.size / 2);
	}
	else
	{
		level.ex_amc_perteam = int(level.ex_amc_perteam / 2);
		if(level.ex_amc_perteam > level.ammocrates.size)
			level.ex_amc_perteam = level.ammocrates.size;
	}
}

ammoCrateAlloc(crate_index, ammocrate_team, oncompass)
{
	crate_objnum = 0;
	if(oncompass)
	{
		if(ammocrate_team == "neutral")
		{
			if(getAmmocratesOnCompass() < (level.ex_amc_maxobjteam * 2)) crate_objnum = levelHudGetObjective();
		}
		else if(getAmmocratesOnCompassForTeam(ammocrate_team) < level.ex_amc_maxobjteam) crate_objnum = levelHudGetObjective();
	}

	level.ammocrates[crate_index].inuse = true;
	level.ammocrates[crate_index].objective = crate_objnum;
	level.ammocrates[crate_index].team = ammocrate_team;
	level.ammocrates[crate_index].status = "alloc";
	return(true);
}

ammoCrateFree(crate_index)
{
	level notify("kill_crate" + crate_index);

	if(level.ammocrates[crate_index].objective)
		levelHudFreeObjective(level.ammocrates[crate_index].objective);

	level.ammocrates[crate_index].inuse = false;
	level.ammocrates[crate_index].objective = 0;
	level.ammocrates[crate_index].team = "none";
	level.ammocrates[crate_index].status = "none";
}

IsAmmocrateAllocated(crate_index)
{
	if(crate_index > level.ammocrates.size-1) return(true);
	return(level.ammocrates[crate_index].inuse);
}

getAmmocrateIndex()
{
	crate_index = 999;
	rejected = true;
	mindist = 750;
	iterations = 0;

	while(rejected && iterations < level.ammocrates.size * 2)
	{
		wait( level.ex_fps_frame );
		iterations++;

		crate_index = randomInt(level.ammocrates.size);
		if(IsAmmocrateAllocated(crate_index)) continue;

		rejected = false;
		for(i = crate_index; i < level.ammocrates.size; i++)
			if(level.ammocrates[i].inuse && distance(level.ammocrates[i].spawnpoint, level.ammocrates[crate_index].spawnpoint) < mindist)
				rejected = true;

		if(!rejected)
		{
			for(i = 0; i < crate_index; i++)
				if(level.ammocrates[i].inuse && distance(level.ammocrates[i].spawnpoint, level.ammocrates[crate_index].spawnpoint) < mindist)
					rejected = true;
		}

		if(level.ex_log_ammocrate && rejected) logprint("AMC: crate index " + crate_index + " rejected\n");
	}

	if(IsAmmocrateAllocated(crate_index))
	{
		// still no valid spawnpos? Get the first free one in the list
		for(i = 0; i < level.ammocrates.size; i++)
		{
			crate_index = i;
			if(!level.ammocrates[i].inuse) break;
		}
	}

	if(IsAmmocrateAllocated(crate_index)) return(999);
		else return(crate_index);
}

getAmmocratesAllocated()
{
	ammocrates = 0;
	for(i = 0; i < level.ammocrates.size; i++)
		if(level.ammocrates[i].inuse) ammocrates++;
	return(ammocrates);
}

setAmmocrateTeam(crate_index, ammocrate_team)
{
	// Valid are: "neutral", "allies", "axis"
	level.ammocrates[crate_index].team = ammocrate_team;
	if(level.ex_teamplay && level.ex_amc_compass && level.ammocrates[crate_index].objective)
		objective_team(level.ammocrates[crate_index].objective, ammocrate_team);
}

getAmmocratesWithStatus(ammocrate_status)
{
	ammocrates = 0;
	for(i = 0; i < level.ammocrates.size; i++)
		if(level.ammocrates[i].status == ammocrate_status) ammocrates++;
	return(ammocrates);
}

setAmmocrateStatus(crate_index, ammocrate_status)
{
	// valid are: "none", "alloc", "inplane", "inair", "onground"
	if(level.ex_log_ammocrate) logprint("AMC: crate " + crate_index + " acquired status " + ammocrate_status + "\n");
	level.ammocrates[crate_index].status = ammocrate_status;
}

getAmmocratesForTeam(ammocrate_team)
{
	ammocrates = 0;
	for(i = 0; i < level.ammocrates.size; i++)
		if(level.ammocrates[i].team == ammocrate_team) ammocrates++;
	return(ammocrates);
}

getAmmocratesOnCompassForTeam(ammocrate_team)
{
	ammocrates = 0;
	for(i = 0; i < level.ammocrates.size; i++)
		if(level.ammocrates[i].team == ammocrate_team && level.ammocrates[i].objective != 0) ammocrates++;
	return(ammocrates);
}

getAmmocratesOnCompass()
{
	ammocrates = 0;
	for(i = 0; i < level.ammocrates.size; i++)
		if(level.ammocrates[i].objective != 0) ammocrates++;
	return(ammocrates);
}

getAmmocratesDropped()
{
	ammocrates = getentarray("ammocrate_chute", "targetname");
	return(ammocrates.size);
}

getAmmocratesFixed()
{
	ammocrates = getentarray("ammocrate_fixed", "targetname");
	return(ammocrates.size);
}

ammoCrateCrashMonitor(plane_index, crate_index)
{
	level endon("ex_gameover");
	level endon("kill_crate" + crate_index);

	level.planes[plane_index].pilot waittill("crash_crate" + crate_index);
	if(!level.planes[plane_index].payload.dropped) ammoCrateFree(crate_index);
}

ammoCrateDropMonitor(plane_index, crate_index)
{
	level endon("ex_gameover");
	level endon("kill_crate" + crate_index);

	level.planes[plane_index].pilot waittill("drop_crate" + crate_index, droppos);
	level thread ammoCrateDrop(crate_index, droppos);
}

ammoCrateDrop(crate_index, droppos)
{
	level endon("ex_gameover");

	setAmmocrateStatus(crate_index, "inair");

	crate = spawn("script_model", droppos);
	crate setmodel("xmodel/ammocrate_rearming");
	crate.targetname = "ammocrate_chute";
	crate.index = crate_index;
	crate.timeout = false;

	// let it freefall for a brief moment
	endpos = crate.origin + (0,0,-400);
	falltime = calcTime(crate.origin, endpos, 10);
	crate moveto(endpos, falltime);
	crate waittill("movedone");

	// define final position
	targetpos = level.ammocrates[crate_index].spawnpoint;
	endpos = targetpos - (15,15,0) + (randomInt(30),randomInt(30),0);
	trace = bulletTrace(endpos + (0,0,100), endpos + (0,0,-1000), false, undefined);
	if(trace["fraction"] < 1.0)
	{
		chute_end = trace["position"];
		if(chute_end[2] > targetpos[2] && (chute_end[2] - targetpos[2] > 50)) chute_end = targetpos;
	}
	else chute_end = targetpos;

	// parachute model
	switch(level.ammocrates[crate_index].team)
	{
		case "axis": chute_model = game["chute_cargo_axis"]; break;
		case "allies": chute_model = game["chute_cargo_allies"]; break;
		default: chute_model = game["chute_cargo_neutral"]; break;
	}

	// parachute into the map
	chute_index = crate parachuteMe(chute_model, crate.origin, chute_end, 3, crate.angles, false);
	if(chute_index != -1) while(!parachuteIsDone(chute_index)) wait( [[level.ex_fpstime]](0.2) );
		else crate.origin = chute_end;

	// if crate has limited lifespan, wait for signal to start countdown
	crate thread ammoCrateTimer(level.ex_amc_chutein_lifespan);

	// now let the crate do the thinking
	crate thread ammoCrateThink();
}

ammoCrateFixed(crate_index)
{
	// define fixed position
	targetpos = level.ammocrates[crate_index].spawnpoint;
	crate_endpos = targetpos - (15, 15, 0) + (randomInt(31), randomInt(31), 0);
	trace = bulletTrace(crate_endpos + (0, 0, 100), crate_endpos + (0, 0, -1000), false, undefined);
	ground = trace["position"];
	if(ground[2] > targetpos[2] && (ground[2] - targetpos[2] > 50)) ground = targetpos;

	crate = spawn("script_model", ground);
	crate setmodel("xmodel/ammocrate_rearming");
	crate.targetname = "ammocrate_fixed";
	crate.index = crate_index;
	crate.timeout = false;

	// now let the crate do the thinking
	crate thread ammoCrateThink();
}

ammoCrateTimer(timeout)
{
	level endon("ex_gameover");
	level endon("round_ended");

	if(!timeout) return;

	level waittill("ammocrate_countdown");

	for(i = 0; i < timeout; i++) wait( [[level.ex_fpstime]](1) );

	self.timeout = true;
}

ammoCrateThink()
{
	level endon("ex_gameover");
	level endon("round_ended");

	setAmmocrateStatus(self.index, "onground");

	self thread ammoCrateShowObjective();
	
	while(!self.timeout)
	{
		wait( [[level.ex_fpstime]](0.1) );

		ammocrate_team = level.ammocrates[self.index].team;
		
		// look for any players near enough to the crate to rearm
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			if(!isPlayer(players[i]) || players[i].sessionstate != "playing") continue;

			// if crate reached end-of-life, stop all services
			if(self.timeout) continue;

			// if moving or not the right stance, don't try to rearm the player
			if(players[i].ex_moving || players[i] [[level.ex_getstance]](false) == 2) continue;

			// if player is ADS, do not rearm
			if(players[i] playerADS()) continue;

			// do not rearm bots
			if(isDefined(players[i].pers["isbot"])) continue;

			// prevent rearming while being frozen in freezetag
			if(level.ex_currentgt == "ft" && isDefined(players[i].frozenstate) && players[i].frozenstate == "frozen") continue;

			// check if account system grants access
			if(level.ex_accounts && players[i].pers["account"].status == 1 && (level.ex_accounts_lock & 2) == 2) return;

			if(players[i] isOnGround() && !isDefined(players[i].ex_amc_rearm))
			{
				dist = distance(players[i].origin, self.origin);
				if((dist < 36) && (!level.ex_teamplay || (level.ex_teamplay && (ammocrate_team == players[i].pers["team"] || ammocrate_team == "neutral" )))) players[i] thread ammoCratePlayerRearm(self);
			}
		}
	}

	// signal ammoCrateShowObjective() to end
	self notify("ammocrate_deleted");

	// wait for all threads to die
	wait( [[level.ex_fpstime]](0.1) );

	ammoCrateFree(self.index);
	self delete();
}

ammoCratePlayerRearm(crate)
{
	self endon("disconnect");

	if(isDefined(self.ex_amc_rearm)) return;
	self.ex_amc_rearm = true;

	monitor = true;
	linked = false;

	// set how long it takes to replenish
	prog_limit = 5;
	if(level.ex_medicsystem) prog_limit = 8;

	while(monitor && isDefined(crate) && !crate.timeout && isPlayer(self) && self.sessionstate == "playing" && distance(self.origin, crate.origin) < 36 && self [[level.ex_getstance]](true) != 2)
	{
		// display the message
		if(!isDefined(self.ex_amc_msg_displayed))
		{
			self.ex_amc_msg_displayed = true;
			self ammoCrateMessage(&"AMMOCRATE_ACTIVATE");
		}

		wait( level.ex_fps_frame );

		// wait until they press the USE key
		if(!self useButtonPressed()) continue;

		// optionally give points if player conquered a neutral crate
		if(level.ammocrates[crate.index].team == "neutral")
		{
			setAmmocrateTeam(crate.index, self.pers["team"]);

			if(level.ex_amc_chutein_score == 1 || level.ex_amc_chutein_score == 3)
				self thread [[level.ex_scorePlayer]](1, "bonus");
		}

		// make sure they want to rearm, and have not just stopped sprinting over one
		count = 0;
		while(self useButtonPressed() && count < 20)
		{
			wait( level.ex_fps_frame );
			count++;
		}
		if(count < 20) continue;

		// if you got into the gunship by hitting USE, stop rearming attempt
		if( (level.ex_gunship && isPlayer(level.gunship.owner) && level.gunship.owner == self) ||
		    (level.ex_gunship_special && isPlayer(level.gunship_special.owner) && level.gunship_special.owner == self) ) continue;

		// OK, they're still holding so lets rearm them
		if(self useButtonPressed())
		{
			if(isDefined(crate))
			{
				self linkTo(crate);
				linked = true;
			}
			
			weaponsdone = undefined;
			grenadesdone = undefined;
			firstaiddone = undefined;

			playerHudCreateBar(prog_limit, &"AMMOCRATE_REARMING_WEAPONS", false);

			progresstime = 0;
			while(isPlayer(self) && isDefined(crate) && self useButtonPressed() && progresstime <= prog_limit && !crate.timeout)
			{
				wait( level.ex_fps_frame );
				progresstime += level.ex_fps_frame;

				if(progresstime >= 2 && !isDefined(weaponsdone))
				{
					self thread replenishWeapons();
					playerHudBarSetText(&"AMMOCRATE_REARMING_GRENADES");
					weaponsdone = true;
				}
				else if(progresstime >= 5 && !isDefined(grenadesdone))
				{
					self thread replenishGrenades();
					if(level.ex_medicsystem) playerHudBarSetText(&"AMMOCRATE_REARMING_FIRSTAID");
					grenadesdone = true;
				}
				else if(progresstime >= 8 && !isDefined(firstaiddone))
				{
					if(level.ex_medicsystem) self thread replenishFirstaid();
					firstaiddone = true;
				}
			}

			monitor = false;
		}
	}

	// clear the bar graphic and reset the variables
	if(linked) self unlink();
	self [[level.ex_eWeapon]]();
	playerHudDestroyBar();
	self.ex_amc_msg_displayed = undefined;
	self.ex_amc_rearm = undefined;
}

ammoCrateMessage(msg)
{
	self endon("kill_thread");

	if(!isDefined(msg)) return;

	switch(level.ex_amc_msg)
	{
		case 0: self iprintln(msg); break;
		case 1: self iprintlnbold(msg); break;
		case 2: self thread playerHudAnnounce(msg); break;
	}
}

ammoCrateShowObjective()
{
	level endon("ex_gameover");
	self endon("ammocrate_deleted");

	crate_objnum = level.ammocrates[self.index].objective;
	if(!crate_objnum) return;
	
	// show to all
	crate_objteam = "none";
	if(level.ammocrates[self.index].team == "allies" || level.ammocrates[self.index].team == "axis")
		crate_objteam = level.ammocrates[self.index].team;

	objective_add(crate_objnum, "current", self.origin, "compassping_ammocrate");
	objective_team(crate_objnum, crate_objteam);

	if(level.ex_amc_compass < 2) return;
	if(!level.ex_teamplay && !level.ex_amc_chutein_score) return;

	while(level.ammocrates[self.index].team == "neutral")
	{
		wait( [[level.ex_fpstime]](0.5) );
		objective_state(crate_objnum, "invisible");
		wait( [[level.ex_fpstime]](0.5) );
		objective_state(crate_objnum, "current");
	}
}
