#include extreme\_ex_main_utils;

init()
{
	// tracers
	if(level.ex_tracers)
	{
		[[level.ex_devRequest]]("skyfx_tracer");
		[[level.ex_registerLevelEvent]]("onRandom", ::onTracerEvent, false, level.ex_tracers_delay_min, level.ex_tracers_delay_max, 30 + randomInt(30));
	}

	// flak fx
	if(level.ex_flakfx)
	{
		[[level.ex_devRequest]]("skyfx_flak");
		[[level.ex_registerLevelEvent]]("onRandom", ::onFlakEvent, false, level.ex_flakfx_delay_min, level.ex_flakfx_delay_max, 30 + randomInt(30));
	}

	// flares
	if(level.ex_flares)
	{
		switch(level.ex_flares_type)
		{
			case 0: [[level.ex_devRequest]]("skyfx_flare1"); break;
			case 1: [[level.ex_devRequest]]("skyfx_flare2"); break;
			case 2: [[level.ex_devRequest]]("skyfx_flare3"); break;
		}

		[[level.ex_registerLevelEvent]]("onRandom", ::onFlareEvent, true, level.ex_flares_delay_min, level.ex_flares_delay_max, 30 + randomInt(30));
	}
}

//------------------------------------------------------------------------------
// Tracer handling
//------------------------------------------------------------------------------
onTracerEvent(eventID)
{
	for(i = 0; i < level.ex_tracers; i++)
	{
		// play tracer effects
		tracer = spawn("script_model", getPosPlayAreaExtended(randomInt(4), 0));
		tracer thread [[level.ex_devEffects]]("skyfx_tracer");

		wait( [[level.ex_fpstime]](2) );
		tracer delete();
	}
}

//------------------------------------------------------------------------------
// Flak handling
//------------------------------------------------------------------------------
onFlakEvent(eventID)
{
	thread fireFlaks(level.ex_flakfx);
}

fireFlaks(count)
{
	for(i = 0; i < count; i++)
	{
		// play flak effects
		flak = spawn("script_model", getRandomPosPlayArea(400));
		flak thread [[level.ex_devEffects]]("skyfx_flak");

		wait( [[level.ex_fpstime]](0.5) );
		flak delete();
	}
}

//------------------------------------------------------------------------------
// Flare handling
//------------------------------------------------------------------------------
onFlareEvent(eventID)
{
	// if entities monitor in defcon 3 or lower, suspend
	if(level.ex_entities_defcon < 4)
	{
		[[level.ex_enableLevelEvent]]("onRandom", eventID);
		return;
	}

	// number of flares
	if(level.ex_flares_max > level.ex_flares_min) flare_count = level.ex_flares_min + randomInt(level.ex_flares_max - level.ex_flares_min);
		else flare_count = level.ex_flares_min;

	// optional warning
	if(level.ex_flares_alert)
	{
		thread playBattleChat("order_cover_generic", "both");
		wait( [[level.ex_fpstime]](1) );
	}

	// fire flares
	for(i = 0; i < flare_count; i++)
	{
		thread fireFlare();
		wait( [[level.ex_fpstime]]( randomFloatRange(2, 5)) );
	}

	// wait for all flares to finish
	wait( [[level.ex_fpstime]](60) );

	[[level.ex_enableLevelEvent]]("onRandom", eventID);
}

fireFlare()
{
	// target point
	targetpos = getTargetPos(getRandomPosPlayArea(400));
	if(!isDefined(targetpos)) return;

	// play flare effects
	flare = spawn("script_origin", targetpos);
	switch(level.ex_flares_type)
	{
		case 0: flare thread [[level.ex_devEffects]]("skyfx_flare1"); break;
		case 1: flare thread [[level.ex_devEffects]]("skyfx_flare2"); break;
		case 2: flare thread [[level.ex_devEffects]]("skyfx_flare3"); break;
	}

	wait( [[level.ex_fpstime]](1) );
	flare playSound("flare_burn");

	if(!level.ex_flares_type) wait( [[level.ex_fpstime]](30) ); // delay for normal flares
		else wait( [[level.ex_fpstime]](40) ); // bright flares last longer

	flare delete();
}
