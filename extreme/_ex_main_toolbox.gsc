#include extreme\_ex_controller_hud;
#include extreme\_ex_main_utils;

init()
{
	level.ex_toolbox_users = [];
	count = 0;
	for(;;)
	{
		name_check = [[level.ex_drm]]("ex_toolbox_name_" + count, "", "", "", "string");
		if(name_check == "") break;
		index = level.ex_toolbox_users.size;
		level.ex_toolbox_users[index] = spawnstruct();
		level.ex_toolbox_users[index].name = name_check;
		level.ex_toolbox_users[index].tools = [[level.ex_drm]]("ex_toolbox_tools_" + count, 0, 0, 64, "int");
		count++;
	}

	if(!level.ex_toolbox_users.size) return;
	count = 0;
	for(i = 0; i < level.ex_toolbox_users.size; i++) count += level.ex_toolbox_users[i].tools;
	if(!count) return;

	level.ex_toolbox_modelent = [];
	level.ex_toolbox_models = [];
	level.ex_toolbox_model = -1;

	count = 0;
	for(;;)
	{
		model_check = [[level.ex_drm]]("ex_toolbox_model_" + count, "", "", "", "string");
		if(model_check == "") break;
		index = level.ex_toolbox_models.size;
		level.ex_toolbox_models[index] = spawnstruct();
		level.ex_toolbox_models[index].modelname = "xmodel/" + model_check;
		[[level.ex_PrecacheModel]](level.ex_toolbox_models[index].modelname);
		count++;
	}

	level.ex_toolbox_effects = [];
	level.ex_toolbox_effect = -1;

	count = 0;
	for(;;)
	{
		effect_check = [[level.ex_drm]]("ex_toolbox_effect_" + count, "", "", "", "string");
		if(effect_check == "") break;
		index = level.ex_toolbox_effects.size;
		level.ex_toolbox_effects[index] = spawnstruct();
		level.ex_toolbox_effects[index].effectname = "fx/" + effect_check;
		level.ex_toolbox_effects[index].effectid = [[level.ex_PrecacheEffect]](level.ex_toolbox_effects[index].effectname);
		count++;
	}

	[[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerSpawned);
}

main()
{
	// NOP
}

onPlayerSpawned()
{
	level endon("ex_gameover");
	self endon("disconnect");

	tool_user = false;
	for(i = 0; i < level.ex_toolbox_users.size; i++)
	{
		if(level.ex_toolbox_users[i].name == self.name)
		{
			tool_user = true;
			break;
		}
	}
	if(!tool_user) return;

	if((level.ex_toolbox_users[i].tools & 1) == 1) self thread toolShowPos();
	if((level.ex_toolbox_users[i].tools & 2) == 2) self thread toolThirdPerson();
	if((level.ex_toolbox_users[i].tools & 4) == 4 && level.ex_toolbox_models.size) self thread toolModelTest();
	if((level.ex_toolbox_users[i].tools & 8) == 8 && level.ex_toolbox_effects.size) self thread toolEffectTest();
}

//------------------------------------------------------------------------------
// Show position
//------------------------------------------------------------------------------
toolShowPos()
{
	level endon("ex_gameover");
	self endon("disconnect");

	if(isDefined(self.pers["tool_showpos"])) return;
	self.pers["tool_showpos"] = true;
	logprint("TBX: Show position tool started for player: " + self.name + "\n");

	// position X
	hud_index = playerHudCreate("toolbox_posx", 250, 55, 1, (1,0,0), 1, 0, "fullscreen", "fullscreen", "center", "top", false, false);
	if(hud_index == -1) return;

	// position Y
	hud_index = playerHudCreate("toolbox_posy", 320, 55, 1, (1,0,0), 1, 0, "fullscreen", "fullscreen", "center", "top", false, false);
	if(hud_index == -1) return;

	// position Z
	hud_index = playerHudCreate("toolbox_posz", 390, 55, 1, (1,0,0), 1, 0, "fullscreen", "fullscreen", "center", "top", false, false);
	if(hud_index == -1) return;

	// angle X
	hud_index = playerHudCreate("toolbox_pitch", 250, 75, 1, (1,0,0), 1, 0, "fullscreen", "fullscreen", "center", "top", false, false);
	if(hud_index == -1) return;

	// angle Y
	hud_index = playerHudCreate("toolbox_yaw", 320, 75, 1, (1,0,0), 1, 0, "fullscreen", "fullscreen", "center", "top", false, false);
	if(hud_index == -1) return;

	// angle Z
	hud_index = playerHudCreate("toolbox_roll", 390, 75, 1, (1,0,0), 1, 0, "fullscreen", "fullscreen", "center", "top", false, false);
	if(hud_index == -1) return;

	meleecount = 0;
	savecount = 0;

	while(1)
	{
		wait( [[level.ex_fpstime]](0.2) );

		origin = self.origin;
		playerHudSetValue("toolbox_posx", origin[0]);
		playerHudSetValue("toolbox_posy", origin[1]);
		playerHudSetValue("toolbox_posz", origin[2]);

		angles = self getplayerangles();
		playerHudSetValue("toolbox_pitch", angles[0]);
		playerHudSetValue("toolbox_yaw", angles[1]);
		playerHudSetValue("toolbox_roll", angles[2]);

		// reset counter if ADS, planting or defusing
		if(self playerADS() || self.trip_handling || self.mine_handling || isDefined(self.bomb_handling))
		{
			meleecount = 0;
			continue;
		}

		// monitor MELEE key
		if(self meleeButtonPressed())
		{
			// should have held key for 1 second
			if(meleecount > 5)
			{
				savecount++;
				logprint("TBX: [" + savecount + "] " + "origin " + origin + ", " + "angles " + angles + "\n");
				meleecount = 0;
				while(self meleeButtonPressed()) wait( [[level.ex_fpstime]](0.5) );
			}
			else meleecount++;
		}
		else meleecount = 0;
	}
}

//------------------------------------------------------------------------------
// Third person
//------------------------------------------------------------------------------
toolThirdPerson()
{
	level endon("ex_gameover");
	self endon("disconnect");

	if(isDefined(self.pers["tool_thirdperson"])) return;
	self.pers["tool_thirdperson"] = true;
	logprint("TBX: Third person tool started for player: " + self.name + "\n");

	self.ex_thirdperson = false;
	thirdpersonangle = 0;
	thirdpersonrange = 100;

	meleecount = 0;
	usecount = 0;

	while(1)
	{
		wait( [[level.ex_fpstime]](0.2) );

		// reset counter if ADS, sprinting, rearming, healing, planting or defusing
		if(self playerADS() || self.ex_sprinting || isDefined(self.ex_amc_rearm) || isDefined(self.ex_ishealing) || self.trip_handling || self.mine_handling || isDefined(self.bomb_handling))
		{
			usecount = 0;
			continue;
		}

		// monitor USE key
		if(self useButtonPressed())
		{
			// should have held key for 1 second
			if(usecount > 5)
			{
				if(self.ex_thirdperson)
				{
					thirdpersonrange += 20;
					if(thirdpersonrange > 200)
					{
						thirdpersonrange = 100;
						self setClientCvar("cg_thirdperson", 0);
						self.ex_thirdperson = false;
						usecount = 0;
					}
					else self setClientCvar("cg_thirdpersonrange", thirdpersonrange);
				}
				else
				{
					self setClientCvar("cg_thirdpersonangle", thirdpersonangle);
					self setClientCvar("cg_thirdpersonrange", thirdpersonrange);
					self setClientCvar("cg_thirdperson", 1);
					self.ex_thirdperson = true;
					usecount = 0;
				}
			}
			else usecount++;
		}
		else usecount = 0;

		if(self.ex_thirdperson)
		{
			// reset counter if ADS, sprinting, planting or defusing
			if(self playerADS() || self.ex_sprinting || self.trip_handling || self.mine_handling || isDefined(self.bomb_handling))
			{
				meleecount = 0;
				continue;
			}

			// monitor MELEE key
			if(self meleeButtonPressed())
			{
				// should have held key for 1 second
				if(meleecount > 5)
				{
					thirdpersonangle += 10;
					if(thirdpersonangle == 360) thirdpersonangle = 0;
					self setClientCvar("cg_thirdpersonangle", thirdpersonangle);
				}
				else meleecount++;
			}
			else meleecount = 0;
		}
	}
}

//------------------------------------------------------------------------------
// Models
//------------------------------------------------------------------------------
toolModelTest()
{
	level endon("ex_gameover");
	self endon("disconnect");

	if(isDefined(self.pers["tool_modeltest"])) return;
	self.pers["tool_modeltest"] = true;
	logprint("TBX: Model testing tool started for player: " + self.name + "\n");

	meleecount = 0;

	while(1)
	{
		wait( [[level.ex_fpstime]](0.2) );

		if(!self isOnGround()) continue;

		// reset counter if ADS, sprinting, planting or defusing
		if(self playerADS() || self.ex_sprinting || self.trip_handling || self.mine_handling || isDefined(self.bomb_handling))
		{
			meleecount = 0;
			continue;
		}

		// monitor MELEE key
		if(self meleeButtonPressed())
		{
			// should have held key for 1 second
			if(meleecount > 5)
			{
				if(!extreme\_ex_main_utils::tooClose(150, 150, 150, 150)) self thread toolModelCreate();
				while(self meleeButtonPressed()) wait( [[level.ex_fpstime]](0.5) );
				meleecount = 0;
			}
			else meleecount++;
		}
		else meleecount = 0;
	}
}

toolModelCreate()
{
	level.ex_toolbox_model++;
	if(level.ex_toolbox_model >= level.ex_toolbox_models.size) level.ex_toolbox_model = 0;

	index = toolModelAllocate();
	level.ex_toolbox_modelent[index].model = spawn("script_model", self.origin);
	level.ex_toolbox_modelent[index].model setmodel(level.ex_toolbox_models[level.ex_toolbox_model].modelname);
	level.ex_toolbox_modelent[index].model.angles = (0, self.angles[1], 0);
	level.ex_toolbox_modelent[index].model.owner = self;
	level.ex_toolbox_modelent[index].model.team = self.pers["team"];

	level thread toolModelThink(index);
}

toolModelThink(index)
{
	//level thread toolModelRotate(index);
	//level thread toolModelFX(index);

	//level.ex_toolbox_modelent[index].model.owner linkTo(level.ex_toolbox_modelent[index].model, "tag_player1", (0,0,0), (0,0,0));

	ttl = 60;
	while(ttl > 0)
	{
		ttl--;
		wait( [[level.ex_fpstime]](1) );
	}

	//level.ex_toolbox_modelent[index].model.owner unlink();

	toolModelRemove(index);
}

toolModelAllocate()
{
	for(i = 0; i < level.ex_toolbox_modelent.size; i++)
	{
		if(level.ex_toolbox_modelent[i].inuse == 0)
		{
			level.ex_toolbox_modelent[i].inuse = 1;
			return(i);
		}
	}

	level.ex_toolbox_modelent[i] = spawnstruct();
	level.ex_toolbox_modelent[i].notification = "testmodel" + i;
	level.ex_toolbox_modelent[i].inuse = 1;
	return(i);
}

toolModelRemove(index)
{
	if(!level.ex_toolbox_modelent[index].inuse) return;
	level notify(level.ex_toolbox_modelent[index].notification);
	level.ex_toolbox_modelent[index].model delete();
	level.ex_toolbox_modelent[index].inuse = 0;
}

toolModelRotate(index)
{
	level endon(level.ex_toolbox_modelent[index].notification);

	seconds = 10;
	while(true)
	{
		level.ex_toolbox_modelent[index].model movez(500, seconds, 1, 1);
		//level.ex_toolbox_modelent[index].model rotateyaw(360, seconds, 0, 0);
		wait(10);
		level.ex_toolbox_modelent[index].model movez(-500, seconds, 1, 1);
		//level.ex_toolbox_modelent[index].model rotateyaw(360 , seconds, 0, 0);
		wait(20);
	}
}

toolModelFX(index)
{
	level endon(level.ex_toolbox_modelent[index].notification);

	while(true)
	{
		//playfxontag(effect_id, level.ex_toolbox_modelent[index].model, "tag_id");
		wait(1);
	}
}

//------------------------------------------------------------------------------
// Effects
//------------------------------------------------------------------------------
toolEffectTest()
{
	level endon("ex_gameover");
	self endon("disconnect");

	if(isDefined(self.pers["tool_fxtest"])) return;
	self.pers["tool_fxtest"] = true;
	logprint("TBX: Effect testing tool started for player: " + self.name + "\n");

	meleecount = 0;

	while(1)
	{
		wait( [[level.ex_fpstime]](0.2) );

		if(!self isOnGround()) continue;

		// reset counter if ADS, planting or defusing
		if(self playerADS() || self.trip_handling || self.mine_handling || isDefined(self.bomb_handling))
		{
			usecount = 0;
			continue;
		}

		// monitor MELEE key
		if(self meleeButtonPressed())
		{
			// should have held key for 1 second
			if(meleecount > 5)
			{
				if(!extreme\_ex_main_utils::tooClose(150, 150, 150, 150)) self thread toolEffectCreate();
				while(self meleeButtonPressed()) wait( [[level.ex_fpstime]](0.5) );
				meleecount = 0;
			}
			else meleecount++;
		}
		else meleecount = 0;
	}
}

toolEffectCreate()
{
	level.ex_toolbox_effect++;
	if(level.ex_toolbox_effect >= level.ex_toolbox_effects.size) level.ex_toolbox_effect = 0;

	playOrigin = self getEye() + [[level.ex_vectorscale]](anglesToForward(self getplayerangles()), 100) + (0,0,20);
	//playOrigin = (game["mapArea_CentreX"], game["mapArea_CentreY"], 1000);
	//playOrigin = self.origin;

	playfx(level.ex_toolbox_effects[level.ex_toolbox_effect].effectid, playOrigin);

	//fxAngle = vectorNormalize((playOrigin + (0,0,100)) - playOrigin);
	//fxlooper = playLoopedFx(level.ex_toolbox_effects[level.ex_toolbox_effect].effectid, 1.6, playOrigin, 0, fxAngle);
	//wait( [[level.ex_fpstime]](60) );
	//if(isDefined(fxlooper)) fxlooper delete();
}

//------------------------------------------------------------------------------
// Debugging
//------------------------------------------------------------------------------
debugVec(origin, type, text)
{
	if(isDefined(origin))
	{
		if(!isDefined(level.ex_debug_models)) level.ex_debug_models = [];
		if(!isDefined(type)) type = 0;

		switch(type)
		{
			case 1: model = "xmodel/health_medium"; break;
			case 2: model = "xmodel/health_large"; break;
			default : model = "xmodel/health_small"; break;
		}

		index = level.ex_debug_models.size;
		level.ex_debug_models[index] = spawn("script_model", origin);
		if(isDefined(level.ex_debug_models[index]))
		{
			level.ex_debug_models[index] setmodel(model);
			if(isDefined(text) && isDefined(level.ex_debug_models[index].origin)) level.ex_debug_models[index] thread debugVecMark(text);
		}
	}
	else
	{
		if(isDefined(level.ex_debug_models))
		{
			for(i = 0; i < level.ex_debug_models.size; i++) level.ex_debug_models[i] delete();
			level.ex_debug_models = undefined;
		}
	}
}

debugVecMark(text)
{
	while(1)
	{
		//print3d(<origin>, <text>, [<color>, <alpha>, <scale>])
		print3d(self.origin + (0, 0, 15), text, (.3, .8, 1), 1, 0.3);
		wait( level.ex_fps_frame );
	}
}
