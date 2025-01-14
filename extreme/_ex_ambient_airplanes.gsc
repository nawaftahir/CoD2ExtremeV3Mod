#include extreme\_ex_controller_airtraffic;
#include extreme\_ex_main_utils;

init()
{
	// team setting ("neutral", "axis" or "allies")
	if(level.ex_planes != 3) level.ex_planes_team = "neutral";
		else if(randomInt(2)) level.ex_planes_team = "axis";
			else level.ex_planes_team = "allies";

	// register ambient planes event
	[[level.ex_registerLevelEvent]]("onRandom", ::onRandom, true, level.ex_planes_delay_min, level.ex_planes_delay_max, randomInt(30)+30);

	// device registration
	[[level.ex_devRequest]]("airstrike_amb");
	if(level.ex_planes_flak) [[level.ex_devRequest]]("skyfx_flak");
}

onRandom(eventID)
{
	// suspend if entities monitor in defcon 3 or lower, or other planes are present
	if(level.ex_entities_defcon < 4 || planesInSky())
	{
		[[level.ex_enableLevelEvent]]("onRandom", eventID);
		return;
	}

	// number of planes
	if(level.ex_planes_max > level.ex_planes_min) plane_count = level.ex_planes_min + randomInt(level.ex_planes_max - level.ex_planes_min);
		else plane_count = level.ex_planes_min;

	// optional warnings
	if(level.ex_planes_alert) playSoundLoc("air_raid");
	if(level.ex_planes_flak) level thread extreme\_ex_ambient_skyeffects::fireFlaks(10);

	// create support entity
	airsupport = spawn("script_origin", (0,0,0));

	// preferred angle
	plane_angle = randomInt(360);

	// launch planes
	plane_xcount = 0;
	for(i = 0; i < plane_count; i++)
	{
		wait( level.ex_fps_frame );

		// number of shells
		shell_count = 4 + randomInt(3);

		// drop point
		droppos = getDropPosPlayArea(randomInt(4), 500);
		if(!isDefined(droppos)) continue;

		// adjust plane alignment
		if(i > 0)
		{
			if(i % 2 == 0) droppos = posLeft(droppos, (0,plane_angle,0), 1500);
				else droppos = posRight(droppos, (0,plane_angle,0), 1500);
		}

		// target point
		targetpos = getTargetPos(droppos);
		if(!isDefined(targetpos)) continue;

		// approve distance
		dist = distance(droppos, targetpos);
		if(dist > game["mapArea_Max"][2] + 1000) continue;

		// keep track of airplane requests that make it through
		plane_xcount++;

		// request a slot
		plane_slot = planeSlot(level.PLANE_PURP_AMBIENT);

		// create the airplane
		plane_index = airsupport planeCreate(plane_slot, level.PLANE_TYPE_ANY, level, level.ex_planes_team, droppos, plane_angle);

		// add payload to airplane
		if(level.ex_planes == 2) planeAddPayload(plane_index, "airstrike_amb", targetpos, shell_count, false);
			else if(level.ex_planes == 3) planeAddPayload(plane_index, "airstrike_amb", targetpos, shell_count, true);

		// fly baby
		thread planeGo(plane_index, "plane_finished");
	}

	// wait for all planes to finish
	for(i = 0; i < plane_xcount; i++) airsupport waittill("plane_finished");

	// delete support entity
	airsupport delete();

	// switch teams for next event (only if deadly)
	if(level.ex_planes == 3)
	{
		if(level.ex_planes_team == "axis") level.ex_planes_team = "allies";
			else level.ex_planes_team = "axis";
	}

	[[level.ex_enableLevelEvent]]("onRandom", eventID);
}
