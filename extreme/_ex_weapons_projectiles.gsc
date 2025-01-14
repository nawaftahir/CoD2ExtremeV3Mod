#include extreme\_ex_controller_devices;
#include extreme\_ex_main_utils;

init()
{
	// register projectile monitor event
	[[level.ex_registerLevelEvent]]("onFrame", ::onFrame, true);

	// register device
	[[level.ex_devRequest]]("gl_grenade");
	[[level.ex_devRequest]]("rpg_missile");
}

onFrame(eventID)
{
	rockets = getentarray("rocket", "classname");
	for(i = 0; i < rockets.size; i ++)
	{
		rocket = rockets[i];
		if(!isDefined(rocket.monitored))
		{
			rocket.monitored = true;
			rocket thread tagProjectile();
		}
	}

	[[level.ex_enableLevelEvent]]("onFrame", eventID);
}

tagProjectile()
{
	closest_player = undefined;
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isPlayer(player) && player.sessionstate == "playing")
		{
			if(!isPlayer(closest_player)) closest_player = player;
			if(closer(self.origin, player.origin, closest_player.origin)) closest_player = player;
		}
	}

	if(isPlayer(closest_player))
	{
		if(level.ex_gunship && isPlayer(level.gunship.owner) && closest_player == level.gunship.owner)
		{
			level thread extreme\_ex_main_gunship::gunshipMonitorProjectile(self, level.gunship);
			//logprint("WPN: [proj] Projectile was fired from normal gunship by " + closest_player.name + "\n");
		}
		else if(level.ex_gunship_special && isPlayer(level.gunship_special.owner) && closest_player == level.gunship_special.owner)
		{
			level thread extreme\_ex_main_gunship::gunshipMonitorProjectile(self, level.gunship_special);
			//logprint("WPN: [proj] Projectile was fired from perk gunship by " + closest_player.name + "\n");
		}
		else
		{
			weapon = closest_player getcurrentweapon();
			if(extreme\_ex_weapons::isWeaponType(weapon, "rl"))
			{
				if(closest_player usebuttonpressed())
				{
					if(isDefined(level.helicopter) && level.ex_heli_candamage && (!level.ex_teamplay || closest_player.pers["team"] != level.helicopter.team))
					{
						level thread replaceProjectile(self, level.helicopter, closest_player, closest_player.pers["team"], weapon);
						if(level.ex_heli_damagehud && isPlayer(closest_player)) closest_player thread extreme\_ex_specials_helicopter::hudDamageHeli(10);
						//logprint("WPN: [proj] Projectile was fired from rocket launcher to chopper by " + closest_player.name + " (heat seaker)\n");
					}
					else if(level.ex_gunship && isPlayer(level.gunship.owner) && (!level.ex_teamplay || closest_player.pers["team"] != level.gunship.team))
					{
						level thread replaceProjectile(self, level.gunship, closest_player, closest_player.pers["team"], weapon);
						//logprint("WPN: [proj] Projectile was fired from rocket launcher to gunship by " + closest_player.name + " (heat seaker)\n");
					}
					else if(level.ex_gunship_special && isPlayer(level.gunship_special.owner) && (!level.ex_teamplay || closest_player.pers["team"] != level.gunship_special.team))
					{
						level thread replaceProjectile(self, level.gunship_special, closest_player, closest_player.pers["team"], weapon);
						//logprint("WPN: [proj] Projectile was fired from rocket launcher to specialty gunship by " + closest_player.name + " (heat seaker)\n");
					}
					else if(level.ex_gunship || level.ex_store || level.ex_longrange)
					{
						level thread assistedProjectile(self);
						//logprint("WPN: [proj] Projectile was fired from rocket launcher by " + closest_player.name + " (assisted)\n");
					}
				}
				else if(level.ex_gunship || level.ex_store || level.ex_longrange)
				{
					level thread assistedProjectile(self);
					//logprint("WPN: [proj] Projectile was fired from rocket launcher by " + closest_player.name + " (assisted)\n");
				}
				//else logprint("WPN: [proj] Projectile was fired from rocket launcher by " + closest_player.name + " (normal)\n");
			}
			else if(extreme\_ex_weapons::isWeaponType(weapon, "knife"))
			{
				if(isDefined(self))
				{
					modern = false;
					if(level.ex_specials_knife)
					{
						if(level.ex_specials_knife_modern) modern = true;
					}
					else if(level.ex_modern_weapons) modern = true;
					closest_player thread extreme\_ex_weapons_projectiles_knife::main(weapon, self.origin, modern);
					self delete();
				}
				//logprint("WPN: [proj] Projectile was fired from knife by " + closest_player.name + "\n");
			}
			else if(extreme\_ex_weapons::isWeaponType(weapon, "gl"))
			{
				if(isDefined(self))
				{
					closest_player thread extreme\_ex_weapons_projectiles_gl::main(weapon, self.origin);
					self delete();
				}
				//logprint("WPN: [proj] Projectile was fired from perk weapon by " + closest_player.name + "\n");
			}
			else if(extreme\_ex_weapons::isWeaponType(weapon, "ft"))
			{
				if(isDefined(self)) self delete();
				//logprint("WPN: [proj] Projectile was fired from flamethrower by " + closest_player.name + "\n");
			}
			//else logprint("WPN: [proj] Projectile was fired from LR rifle by " + closest_player.name + "\n");
		}
	}
}

//------------------------------------------------------------------------------
// Replace projectile
//------------------------------------------------------------------------------
replaceProjectile(entity, target, owner, team, weapon)
{
	origin = entity.origin;
	angles = entity.angles;
	entity delete();

	// create replacement model
	missile = spawn("script_model", origin);
	missile.angles = angles;
	missile setmodel( getDeviceModel("rpg_missile") );

	// device info to pass on
	device_info = [[level.ex_devInfo]](owner, team);
	device_info.weapon = weapon;

	// target info to pass on
	target_info = spawnstruct();
	target_info.target = target;
	target_info.target_type = -1;

	missile thread [[level.ex_devMissile]]("rpg_missile", device_info, target_info, undefined);
}

//------------------------------------------------------------------------------
// Monitor projectile impact (for effects only)
//------------------------------------------------------------------------------
assistedProjectile(entity)
{
	lastorigin = entity.origin;
	while(isDefined(entity))
	{
		lastorigin = entity.origin;
		wait( level.ex_fps_frame );
	}

	// handle explosion
	impactloc = spawn("script_origin", lastorigin);
	impactloc thread [[level.ex_devEffects]]("kaboom");
	wait(1);
	impactloc delete();
}
