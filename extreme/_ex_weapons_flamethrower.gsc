#include extreme\_ex_weapons;
#include extreme\_ex_main_utils;

main()
{
	self endon("kill_thread");

	self.tankonback = undefined;

	while(true)
	{
		wait( [[level.ex_fpstime]](0.1) );

		// check if player is (still) carrying a flamethrower (any slot)
		weapon1 = self.pers["weapon"];
		if(level.ex_wepo_secondary) weapon2 = self.pers["weapon2"];
			else weapon2 = "none";

		if(isWeaponType(weapon1, "ft") || isWeaponType(weapon2, "ft"))
		{
			// flamethrower found: attach the gas tank to the back if not attached already
			if(!isDefined(self.tankonback))
			{
				// detach current weapon on back
				if(isDefined(self.weapononback))
				{
					if(checkAttached(self.weapononback)) self detach("xmodel/" + self.weapononback, "");
					self.weapononback = undefined;
				}
				self.tankonback = "ft_tank";
				if(!checkAttached(self.tankonback)) self attach("xmodel/" + self.tankonback, "j_spine4", true);
			}
		}
		else
		{
			// no flamethrower (anymore): detach the tank if attached
			if(isDefined(self.tankonback))
			{
				if(checkAttached(self.tankonback)) self detach("xmodel/" + self.tankonback, "j_spine4");
				self.tankonback = undefined;
			}
		}

		// separated the actual flamethrower monitor so only players with a flamethrower will
		// run that thread, saving a ton of script variables
		weapon = self getCurrentWeapon();
		if(self attackbuttonpressed() && isWeaponType(weapon, "ft")) monitorFlamethrower(weapon);
	}
}

monitorFlamethrower(flamethrower)
{
	self endon("kill_thread");

	flame_alloc = 10;
	flame_index = 0;
	flame_refused = 0;

	flames = [];
	for(i = 1; i <= flame_alloc; i++)
	{
		flames[i] = spawnstruct();
		flames[i].inuse = false;
		flames[i].flame = undefined;
	}

	while(1)
	{
		wait( [[level.ex_fpstime]](0.1) );

		weapon = self getCurrentWeapon();
		if(!isWeaponType(weapon, "ft")) break;

		if(self attackbuttonpressed())
		{
			// check if player is on turret
			if(isDefined(self.onturret)) continue;

			// check if weapon has ammo left
			if(weapon == self getWeaponSlotWeapon("primary")) ft_slot = "primary";
				else ft_slot = "primaryb";
			ft_ammo = self getWeaponSlotClipAmmo(ft_slot);
			if(!ft_ammo) continue;

			// check distance to object in front of player. Too close = no flame
			trace = self getEyeTrace(1000);
			trace_dist = distance(trace["position"], self.origin);
			if(trace_dist < 100)
			{
				flame_refused++;
				if(flame_refused == 1 || flame_refused%5 == 0) self playsound("ft_refuse");
				continue;
			}
			else flame_refused = 0;

			// next flame. Check if it has an allocated array element
			flame_index++;
			if(flame_index > flame_alloc)
			{
				// if first flame is still alive, expand array if within limits
				if(flames[1].inuse && flame_alloc <= 20)
				{
					flame_alloc++;
					flames[flame_alloc] = spawnstruct();
					flames[flame_alloc].inuse = false;
					flames[flame_alloc].flame = undefined;
				}
				else flame_index = 1;
			}

			// did we cycle a full array?
			if(flames[flame_index].inuse) continue;

			// play flamethrower sound on 1st and every 5th flame
			if(flame_index == 1 || flame_index%5 == 0) self playsound("ft_fire");

			// now get a target
			trace_entity = self;
			flame_start = self getEyeForward(65);
			flame_target = self getEyeForward(level.ex_ft_range);

			trace = bulletTrace(flame_start, flame_target, true, undefined);
			if(trace["fraction"] != 1 && isDefined(trace["entity"]))
			{
				trace_entity = trace["entity"];
				flame_target = trace_entity.origin;
			}
			else
			{
				trace = bulletTrace(flame_start, flame_target, false, undefined);
				if(trace["fraction"] != 1 && trace["surfacetype"] != "default")
					flame_target = trace["position"];
			}

			if(!isDefined(flame_target)) flame_target = self getEyeForward(level.ex_ft_range);

			// limit how many times a flame may duplicate itself while traveling
			trace_dist = distance(flame_start, flame_target);
			if(trace_dist == 0) trace_dist = 1;
			flame_loop = (level.ex_ft_range / trace_dist) * 0.1;

			// play effects
			flames[flame_index].inuse = true;
			flames[flame_index].flame = spawn("script_model", flame_start);
			flames[flame_index].flame setModel("xmodel/tag_origin"); // Substitution model (always precached)
			flames[flame_index].flame.angles = self.angles;
			flames[flame_index].flame hide();
			flames[flame_index].flame thread showFlame(flames[flame_index], flame_loop, flame_target);

			players = level.players;
			for(i = 0; i < players.size; i++)
			{
				player = players[i];

				// skip if player left or player is self
				if(!isPlayer(player) || player == self) continue;

				// skip dead players, spectators and spawn protected players
				if(!isAlive(player) || player.sessionteam == "spectator" || player.ex_invulnerable) continue;

				// respect friendly fire settings 0 (off) and 2 (reflect; it doesn't damage the attacker though)
				if(level.ex_teamplay && (level.friendlyfire == "0" || level.friendlyfire == "2"))
					if(player.pers["team"] == self.pers["team"]) continue;

				// if player is targeted and hit, set fixed damage and long burntime
				if(trace_entity == player)
				{
					damage = 20;
					burntime = 10;
				}
				else
				{
					// skip if player is not near flame target
					trace_dist = distance(flame_target, player.origin);
					if( !isAlive(player) || player.sessionstate != "playing" || trace_dist >= 100 ) continue;

					// check if free path between flame target and player
					trace = bullettrace(flame_target, player.origin, true, undefined);
					if(trace["fraction"] != 1 && isDefined(trace["entity"]) && trace["entity"] == player)
					{
						// calculate damage and burntime (depending on distance)
						damage = int(20 * (1 - (trace_dist / 100)));
						if(trace_dist <= (100 / 2)) burntime = 6;
							else burntime = 3;
					}
					else continue;
				}

				// if player is already on fire, damage depends on flame index
				if(isDefined(player.ex_isonfire)) damage = int(damage * (flame_index / 10));

				// burn and damage the player
				if(damage < player.health)
				{
					player.health = player.health - damage;
					player thread burnPlayer(self, weapon, burntime);
				}
				else player thread [[level.callbackPlayerDamage]](self, self, damage, 1, "MOD_PROJECTILE", weapon, undefined, (0,0,1), "none", 0);
			}
		}
	}
}

showFlame(flame_pointer, flame_loop, flame_target)
{
	self thread playFlameFX(flame_loop);

	self moveto(flame_target, 1);
	self waittill("movedone");

	self delete();
	if(isDefined(flame_pointer)) flame_pointer.inuse = false;
}

playFlameFX(loopTime)
{
	wait( level.ex_fps_frame );
	while(isDefined(self))
	{
		playfx(level.ex_effect["flamethrower"], self.origin);
		wait( [[level.ex_fpstime]](loopTime) );
	}
}

burnPlayer(attacker, weapon, burntime)
{
	self endon("kill_thread");

	if(isDefined(self.ex_isonfire)) return;
	self.ex_isonfire = 1;

	wait( [[level.ex_fpstime]](0.5) );
	if(randomint(100) > 10) self playsound("scream");

	// loop is quarter of a second, so x4 to convert to seconds
	tick = 0.25;
	burntime = burntime * (1 / tick);
	for(i = 0; i < burntime; i++)
	{
		if(isDefined(self))
		{
			// for every second on fire, player will lose some health
			if(i%4 == 0)
			{
				playFxOnTag(level.ex_effect["fire_torso"], self, "j_spine2");

				switch(randomint(13))
				{
					case 0: tag = "j_hip_le"; break;
					case 1: tag = "j_hip_ri"; break;
					case 2: tag = "j_knee_le"; break;
					case 3: tag = "j_knee_ri"; break;
					case 4: tag = "j_ankle_le"; break;
					case 5: tag = "j_ankle_ri"; break;
					case 6: tag = "j_wrist_ri"; break;
					case 7: tag = "j_wrist_le"; break;
					case 8: tag = "j_shoulder_le"; break;
					case 9: tag = "j_shoulder_ri"; break;
					case 10: tag = "j_elbow_le"; break;
					case 11: tag = "j_elbow_ri"; break;
					default: tag = "j_head"; break;
				}

				self thread playBurnFX(tag, level.ex_effect["fire_arm"], .1);

				damage = 5;
				if(damage < self.health) self.health = self.health - damage;
					else self thread [[level.callbackPlayerDamage]](attacker, attacker, damage, 1, "MOD_PROJECTILE", weapon, undefined, (0,0,1), "none", 0);
			}
		}

		wait( [[level.ex_fpstime]](tick) );
	}

	if(isAlive(self)) self.ex_isonfire = undefined;
}

playBurnFX(tag, fx, looptime)
{
	self endon("kill_thread");

	while(isDefined(self) && isDefined(self.ex_isonfire))
	{
		playFxOnTag(fx, self, tag);
		wait( [[level.ex_fpstime]](looptime) );
	}
}

checkAttached(model)
{
	self endon("kill_thread");

	model_attached = false;
	model_full = "xmodel/" + model;

	attachedSize = self getAttachSize();
	for(i = 0; i < attachedSize; i++)
	{
		attachedModel = self getAttachModelName(i);
		if(attachedModel == model_full)
		{
			model_attached = true;
			break;
		}
	}

	return(model_attached);
}
