#include extreme\_ex_main_utils;

init()
{
	[[level.ex_registerLevelEvent]]("onRandom", ::onRandom, true, level.ex_mortars_delay_min, level.ex_mortars_delay_max, randomInt(30)+30);

	// device registration
	[[level.ex_devRequest]]("mortar_amb");
}

onRandom(eventID)
{
	// if entities monitor in defcon 3 or lower, suspend
	if(level.ex_entities_defcon < 4)
	{
		[[level.ex_enableLevelEvent]]("onRandom", eventID);
		return;
	}

	// warning
	[[level.ex_psop]]("mortarlaunch_incoming");
	if(!randomInt(2)) thread playBattleChat("inform_incoming_mortar", "both");
		else if(!randomInt(2)) thread playBattleChat("order_cover_generic", "both");
	wait( [[level.ex_fpstime]](randomfloat(4) + 0.5) );

	// number of shells
	if(level.ex_mortars_max > level.ex_mortars_min) shell_count = level.ex_mortars_min + randomInt(level.ex_mortars_max - level.ex_mortars_min);
		else shell_count = level.ex_mortars_min;

	// map quadrant
	side = randomInt(4);

	// fire shells
	for(i = 0; i < shell_count; i++)
	{
		// start point (random)
		droppos = getRandomPosPlayArea(400);

		// start point alternative (quadrant)
		//droppos = getPosPlayArea(side, 400);

		// target point
		targetpos = getTargetPos(droppos);
		if(!isDefined(targetpos)) continue;

		// impact point
		impactpos = getImpactPos(targetpos, level.ex_wmd_mortar_accuracy);
		if(!isDefined(impactpos)) continue;

		// device info to pass on
		device_info = [[level.ex_devInfo]](undefined, "neutral");
		device_info.origin = droppos;
		device_info.impactpos = impactpos;
		device_info.dodamage = (level.ex_mortars != 1);

		// fire device
		thread [[level.ex_devInbound]]("mortar_amb", device_info);
		wait(randomFloatRange(0.5, 1.5));
	}

	[[level.ex_enableLevelEvent]]("onRandom", eventID);
}
