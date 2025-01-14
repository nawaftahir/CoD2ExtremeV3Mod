#include extreme\_ex_controller_devices;

main(weapon, origin)
{
	direction = anglesToForward(self getPlayerAngles());
	origin = origin + [[level.ex_vectorscale]](direction, 80);
	vVelocity = [[level.ex_vectorscale]](direction, 60);

	grenade = spawn("script_model", origin);
	grenade setModel( getDeviceModel("gl_grenade") );
	grenade.angles = self.angles;
	grenade_bouncing = false;

	iLoop = 0;
	iLoopMax = 200; // max 10 seconds

	for(;;)
	{
		wait( level.ex_fps_frame );

		iLoop++;
		if(!isPlayer(self) || iLoop == iLoopMax) break;

		vVelocity += (0,0,-2);
		neworigin = grenade.origin + vVelocity;
		if(grenade_bouncing) newangles = grenade.angles + (randomInt(20), randomInt(20), randomInt(20));
			else newangles = vectorToAngles(neworigin - grenade.origin) + (90,0,0);

		trace = bulletTrace(grenade.origin, neworigin, true, grenade);
		if(trace["fraction"] != 1)
		{
			ignore_entity = false;

			// hit player
			if(isDefined(trace["entity"]) && isPlayer(trace["entity"]))
			{
				// you can't hit yourself unless the grenade has traveled far enough to avoid collision
				if(trace["entity"] != self || iLoop > 5) break;
					else ignore_entity = true;
			}

			if(!ignore_entity)
			{
				grenade_action = grenadeAction(trace["surfacetype"]);

				// bounce
				if(grenade_action > 0)
				{
					grenade.origin = trace["position"];
					vOldDirection = vectorNormalize(neworigin - grenade.origin);
					vNewDirection = vOldDirection - [[level.ex_vectorscale]](trace["normal"], vectorDot(vOldDirection, trace["normal"]) * 2);
					vVelocity = [[level.ex_vectorscale]](vNewDirection, length(vVelocity) * grenade_action);
					if(length(vVelocity) < 5)
					{
						grenade.angles = (90, grenade.angles[1], grenade.angles[2]);
						wait( [[level.ex_fpstime]](1) );
						break;
					}
					grenade_bouncing = true;
					continue;
				}
				// stop bouncing
				else break;
			}
		}

		grenade rotateto(newangles, .05, 0, 0);
		grenade moveto(neworigin, .05, 0, 0);
	}

	grenade hide();

	if(isPlayer(self))
	{
		// device info to pass on
		device_info = [[level.ex_devInfo]](self, self.pers["team"]);
		device_info.weapon = weapon;
		device_info.dodamage = true;

		// device explosion
		grenade thread [[level.ex_devExplode]]("gl_grenade", device_info);
	}
	else grenade [[level.ex_devEffects]]("gl_grenade");

	wait(1);
	grenade delete();
}

grenadeAction(surface)
{
	switch(surface)
	{
		// soft bounce
		case "cloth":
		case "flesh":
		case "mud":
		case "paper":
		case "sand":
			return(0.1);

		// medium bounce
		case "dirt":
		case "grass":
		case "gravel":
		case "ice":
		case "snow":
		case "wood":
			return(0.3);

		// medium-hard bounce
		case "asphalt":
		case "brick":
		case "concrete":
		case "metal":
		case "plaster":
		case "rock":
			return(0.4);

		// hard bounce
		case "bark":
		case "carpet":
		case "glass":
			return(0.5);

		// stop bouncing
		//case "foliage":
		//case "water":
		default:
			return(0);
	}
}
