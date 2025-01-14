#include extreme\_ex_main_utils;

init()
{
	[[level.ex_registerLevelEvent]]("onRandom", ::onRandom, true, level.ex_artillery_delay_min, level.ex_artillery_delay_max, randomInt(30)+30);

	// device registration
	[[level.ex_devRequest]]("artillery_amb");
}

onRandom(eventID)
{
	// if entities monitor in defcon 3 or lower, suspend
	if(level.ex_entities_defcon < 4)
	{
		[[level.ex_enableLevelEvent]]("onRandom", eventID);
		return;
	}

	// number of shells
	if(level.ex_artillery_max > level.ex_artillery_min) shell_count = level.ex_artillery_min + randomInt(level.ex_artillery_max - level.ex_artillery_min);
		else shell_count = level.ex_artillery_min;

	// play firing sound
	for(i = 0; i < shell_count; i++ )
	{
		[[level.ex_psop]]("artillery_fire");
		wait( [[level.ex_fpstime]](0.5) );
	}

	// optional warning
	if(level.ex_artillery_alert) thread playBattleChat("order_cover_generic", "both");

	// map quadrant
	side = randomInt(4);

	// fire shells
	for(i = 0; i < shell_count; i++)
	{
		// start point (quadrant)
		droppos = getPosPlayArea(side, 400);

		// start point alternative (random)
		//droppos = getRandomPosPlayArea(400);

		// target point
		targetpos = getTargetPos(droppos);
		if(!isDefined(targetpos)) continue;

		// impact point
		impactpos = getImpactPos(targetpos, level.ex_wmd_artillery_accuracy);
		if(!isDefined(impactpos)) continue;

		// device info to pass on
		device_info = [[level.ex_devInfo]](undefined, "neutral");
		device_info.origin = droppos;
		device_info.impactpos = impactpos;
		device_info.dodamage = (level.ex_artillery != 1);

		// fire device
		thread [[level.ex_devInbound]]("artillery_amb", device_info);
		wait(randomFloatRange(1.5, 2.5));
	}

	[[level.ex_enableLevelEvent]]("onRandom", eventID);
}
