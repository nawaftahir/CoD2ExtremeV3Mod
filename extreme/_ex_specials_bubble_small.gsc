#include extreme\_ex_specials;

perkInit(index)
{
	// create perk array
	level.bubbles = [];

	// perk related precaching
	[[level.ex_PrecacheModel]]("xmodel/huaf_bubble_small");

	game["mod_protect_hudicon"] = "mod_protect_hudicon";
	[[level.ex_PrecacheShader]](game["mod_protect_hudicon"]);

	//level.ex_effect["bubble_burst_small"] = [[level.ex_PrecacheEffect]]("fx/bubble/bubble_burst_small.efx");
}

perkInitPost(index)
{
	// perk related precaching after map load
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

	if((level.ex_arcade_shaders & 8) == 8) self thread extreme\_ex_player_arcade::showArcadeShader(getPerkArcade(index), level.ex_arcade_shaders_perk);
		else self iprintlnbold(&"SPECIALS_BUBBLE_READY");

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
					if(!extreme\_ex_main_utils::tooClose(level.ex_mindist["perks"][0], level.ex_mindist["perks"][1], level.ex_mindist["perks"][2], level.ex_mindist["perks"][3])) break;
				}
				while(self meleebuttonpressed()) wait( level.ex_fps_frame );
			}
		}
	}

	self thread playerStartUsingPerk(index, true);
	self thread hudNotifySpecialRemove(index);

	angles = (0, self.angles[1], 0);
	origin = self.origin;

	level thread perkCreate(self, origin, angles);
}

perkCreate(owner, origin, angles)
{
	index = perkAllocate();

	level.bubbles[index].origin = origin;
	level.bubbles[index].angles = angles;

	level.bubbles[index].type = 0;
	level.bubbles[index].timer = level.ex_bubble_small_timer * 20;
	level.bubbles[index].bubble = spawn("script_model", origin + (0, 0, 20));
	level.bubbles[index].bubble hide();
	level.bubbles[index].bubble setmodel("xmodel/huaf_bubble_small");
	level.bubbles[index].bubble.angles = angles;
	level.bubbles[index].bubble_trig = spawn("trigger_radius", origin, 0, 34, 34);

	// set owner last so other code knowns it's fully initialized
	level.bubbles[index].ownernum = owner getEntityNumber();
	level.bubbles[index].team = owner.pers["team"];
	level.bubbles[index].bubble playsound("bubble_create");
	level.bubbles[index].bubble show();
	level.bubbles[index].owner = owner;

	level thread perkThink(index);
}

perkAllocate()
{
	for(i = 0; i < level.bubbles.size; i++)
	{
		if(level.bubbles[i].inuse == 0)
		{
			level.bubbles[i].inuse = 1;
			return(i);
		}
	}

	level.bubbles[i] = spawnstruct();
	level.bubbles[i].notification = "bubble" + i;
	level.bubbles[i].inuse = 1;
	return(i);
}

perkRemoveAll()
{
	if(level.ex_bubble_small && isDefined(level.bubbles))
	{
		for(i = 0; i < level.bubbles.size; i++)
			if(level.bubbles[i].inuse && level.bubbles[i].type == 0) thread perkRemove(i);
	}
}

perkRemoveFrom(player)
{
	for(i = 0; i < level.bubbles.size; i++)
		if(level.bubbles[i].inuse && isDefined(level.bubbles[i].owner) && level.bubbles[i].owner == player) thread perkRemove(i);
}

perkRemove(index)
{
	level notify(level.bubbles[index].notification);
	level.bubbles[index].bubble stoploopsound();
	level.bubbles[index].bubble playsound("bubble_destroy");
	level.bubbles[index].bubble rotateyaw(-360, 3, 0, 2);
	wait( [[level.ex_fpstime]](3) );

	player = level.bubbles[index].owner;
	if(isPlayer(player) && isDefined(player.ex_bubble_protected) && player.ex_bubble_protected == index)
	{
		player.ex_bubble_protected = undefined;
		player thread hudNotifyProtectedRemove();
	}

	//playfx(level.ex_effect["bubble_burst_small"], level.bubbles[index].bubble.origin);
	perkFree(index);
}

perkFree(index)
{
	if(isDefined(level.bubbles) && isDefined(level.bubbles[index]))
	{
		thread levelStopUsingPerk(level.bubbles[index].ownernum, "bubble_small");
		level.bubbles[index].owner = undefined;
		if(isDefined(level.bubbles[index].bubble_trig)) level.bubbles[index].bubble_trig delete();
		if(isDefined(level.bubbles[index].bubble)) level.bubbles[index].bubble delete();
		level.bubbles[index].inuse = 0;
	}
}

perkThink(index)
{
	level endon(level.bubbles[index].notification);

	level.bubbles[index].bubble playloopsound("bubble_loop");
	level.bubbles[index].bubble thread bubbleRotate(index, 3);

	for(;;)
	{
		// remove bubble if it reached end of life
		if(level.bubbles[index].timer <= 0) break;

		// remove bubble if owner left
		if(!isPlayer(level.bubbles[index].owner)) break;

		// check owner
		player = level.bubbles[index].owner;
		if(isAlive(player) && player isTouching(level.bubbles[index].bubble_trig))
		{
			player.ex_bubble_protected = index;
			player thread hudNotifyProtected();
		}
		else if(isDefined(player.ex_bubble_protected) && player.ex_bubble_protected == index)
		{
			player.ex_bubble_protected = undefined;
			player thread hudNotifyProtectedRemove();
		}

		level.bubbles[index].timer--;
		wait( level.ex_fps_frame );
	}

	thread perkRemove(index);
}

bubbleRotate(index, time)
{
	level endon(level.bubbles[index].notification);

	while(1)
	{
		self rotateyaw(-360, time);
		wait( [[level.ex_fpstime]](time) );
	}
}
