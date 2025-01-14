
cvardef(varname, vardefault, min, max, type)
{
	// get the variable's definition
	switch(type)
	{
		case "int":
			if(getcvar(varname) == "") definition = vardefault;
				else definition = getCvarInt(varname);
			break;
		case "float":
			if(getcvar(varname) == "") definition = vardefault;
				else definition = getCvarFloat(varname);
			break;
		case "string":
		default:
			if(getcvar(varname) == "") definition = vardefault;
				else definition = getcvar(varname);
			break;
	}

	// if it's a number, check if it violates the minimum
	if((type == "int" || type == "float") && definition < min)
	{
		logprint("VAR: Variable \"" + varname + "\" (" + definition + ") violates minimum (" + min + ")\n");
		definition = min;
	}

	// if it's a number, check if it violates the maximum
	if((type == "int" || type == "float") && definition > max)
	{
		logprint("VAR: Variable \"" + varname + "\" (" + definition + ") violates maximum (" + max + ")\n");
		definition = max;
	}

	return(definition);
}

storeServerInfoDvar(dvar)
{
	if(!isDefined (game["serverinfodvar"])) game["serverinfodvar"] = [];
	game["serverinfodvar"][game["serverinfodvar"].size] = dvar;
}

//------------------------------------------------------------------------------
// Sounds and effects
//------------------------------------------------------------------------------
delayedEffect(effect, delay, pos)
{
	wait( [[level.ex_fpstime]](delay) );
	playfx(level.ex_effect[effect], pos);
}

delayedSound(alias, delay)
{
	wait( [[level.ex_fpstime]](delay) );
	if(isDefined(self)) self playLocalSound(alias);
}

playSoundLoc(alias, position, special)
{
	if(!isDefined(position)) position = game["playArea_Centre"];
	
	soundloc = spawn("script_origin", position);
	wait( level.ex_fps_frame );

	if(!isDefined(special)) soundloc playSound(alias);
	else
	{
		if(isPlayer(self) && special == "death")
		{
			if(self.pers["team"] == "allies") soundloc playsound(alias + "_" + game["allies"] + "_" + (randomInt(level.ex_voices[game["allies"]])+1) );
				else soundloc playsound(alias + "_german_" + (randomInt(level.ex_voices["german"])+1) );
		}
	}

	wait(1);
	soundloc delete();
}

playTeamSoundOnPlayer(alias, delay)
{
	if(self.pers["team"] == "allies")
	{
		switch(game["allies"])
		{
			case "american": self playLocalSound("us_" + alias); break;
			case "british": self playLocalSound("uk_" + alias); break;
			default: self playLocalSound("ru_" + alias); break;
		}
	}
	else self playLocalSound("ge_" + alias);

	if(isDefined(delay)) wait(delay);
}

playSoundOnPlayer(alias, special)
{
	self endon("kill_thread");

	self notify("ex_soplayer");
	self endon("ex_soplayer");

	if(!isDefined(special)) self playsound(alias);
	else
	{
		if(isPlayer(self) && special == "pain")
		{
			if(self.pers["team"] == "allies") self playsound(alias + "_" + game["allies"] + "_" + (randomInt(level.ex_voices[game["allies"]])+1) );
				else self playsound(alias + "_german_" + (randomInt(level.ex_voices["german"])+1) );
		}
	}
}

playSoundOnPlayers(alias, team, spectators)
{
	if(!isDefined(spectators)) spectators = true;

	players = level.players;

	if(isDefined(team))
	{
		for(i = 0; i < players.size; i++)
		{
			if(i % 10 == 0) wait( level.ex_fps_frame );
			if(isPlayer(players[i]) && isDefined(players[i].pers) && isDefined(players[i].pers["team"]) && players[i].pers["team"] == team)
			{
				if(spectators) players[i] playLocalSound(alias);
					else if(players[i].sessionstate != "spectator") players[i] playLocalSound(alias);
			}
		}
	}
	else
	{
		for(i = 0; i < players.size; i++)
		{
			if(i % 10 == 0) wait( level.ex_fps_frame );
			if(isPlayer(players[i]) && spectators) players[i] playLocalSound(alias);
				else if(isPlayer(players[i]) && isDefined(players[i].sessionstate) && players[i].sessionstate != "spectator") players[i] playLocalSound(alias);
		}
	}

	wait( [[level.ex_fpstime]](1) );
	level notify("psopdone");
}

playBattleChat(alias, team)
{
	if(!isDefined(alias)) return;

	// get nationality prefix for allies
	switch(game["allies"])
	{
		case "american":
			allies_prefix = "US_";
			break;
		case "british":
			allies_prefix = "UK_";
			break;
		default:
			allies_prefix = "RU_";
			break;
	}

	num = randomInt(4);
	allies_alias = allies_prefix + num + "_" + alias;
	axis_alias = "GE_" + num + "_" + alias;

	switch(team)
	{
		case "allies":
			level thread [[level.ex_psop]](allies_alias, "allies", false);
			break;
		case "axis":
			level thread [[level.ex_psop]](axis_alias, "axis", false);
			break;
		default:
			level thread [[level.ex_psop]](allies_alias, "allies", false);
			level thread [[level.ex_psop]](axis_alias, "axis", false);
			break;
	}
}

//------------------------------------------------------------------------------
// Precaching
//------------------------------------------------------------------------------
ex_PrecacheEffect(effect)
{
	if(!isDefined(game["precached_effects"]))
	{
		game["precached_effects"] = [];
		default_effect = "fx/misc/missing_fx.efx";
		effect_id = loadfx(default_effect);
		index = game["precached_effects"].size;
		game["precached_effects"][index] = spawnstruct();
		game["precached_effects"][index].effect = default_effect;
		game["precached_effects"][index].effect_id = effect_id;
	}

	// return the FX ID from the array for FX already precached
	effect_id = isInEffectsArray(game["precached_effects"], effect);
	if(effect_id != -1) return(effect_id);

	// load FX if within limit
	if(game["precached_effects"].size >= level.ex_tune_cachelimit_effects) // max 55 (max 63 but 8 reserved for level script effects)
	{
		logprint("PRC: Too many precached effects! Effect \"" + effect + "\" replaced with \"missing_fx\"\n");
		return(game["precached_effects"][0].effect_id);
	}

	effect_id = loadfx(effect);
	index = game["precached_effects"].size;
	game["precached_effects"][index] = spawnstruct();
	game["precached_effects"][index].effect = effect;
	game["precached_effects"][index].effect_id = effect_id;
	return(effect_id);
}

ex_PrecacheShader(shader)
{
	if(isDefined(game["precachedone"])) return;
	if(!isDefined(game["precached_shaders"])) game["precached_shaders"] = [];
	if(isInArray(game["precached_shaders"], shader)) return;

	if(game["precached_shaders"].size >= level.ex_tune_cachelimit_shaders) // max 127
	{
		logprint("PRC: Too many precached shaders! Precache request for \"" + shader + "\" ignored\n");
		return;
	}

	game["precached_shaders"][game["precached_shaders"].size] = shader;
	precacheShader(shader);
}

ex_PrecacheHeadIcon(icon)
{
	if(isDefined(game["precachedone"])) return;
	if(!isDefined(game["precached_headicons"])) game["precached_headicons"] = [];
	if(isInArray(game["precached_headicons"], icon)) return;

	if(game["precached_headicons"].size >= level.ex_tune_cachelimit_headicons) // max 15
	{
		logprint("PRC: Too many precached head icons! Precache request for \"" + icon + "\" ignored\n");
		return;
	}

	game["precached_headicons"][game["precached_headicons"].size] = icon;
	precacheHeadIcon(icon);
}

ex_PrecacheStatusIcon(icon)
{
	if(isDefined(game["precachedone"])) return;
	if(!isDefined(game["precached_statusicons"])) game["precached_statusicons"] = [];
	if(isInArray(game["precached_statusicons"], icon)) return;

	if(game["precached_statusicons"].size >= level.ex_tune_cachelimit_statusicons) // max 8
	{
		logprint("PRC: Too many precached status icons! Precache request for \"" + icon + "\" ignored\n");
		return;
	}

	game["precached_statusicons"][game["precached_statusicons"].size] = icon;
	precacheStatusIcon(icon);
}

ex_PrecacheModel(model)
{
	if(isDefined(game["precachedone"])) return;
	if(!isDefined(game["precached_models"])) game["precached_models"] = [];
	if(isInArray(game["precached_models"], model)) return;

	if(game["precached_models"].size >= level.ex_tune_cachelimit_models) // max 127 (max 254 but 127 reserved for weapon file models)
	{
		logprint("PRC: Too many precached models! Precache request for \"" + model + "\" ignored\n");
		return;
	}

	game["precached_models"][game["precached_models"].size] = model;
	precacheModel(model);
}

ex_PrecacheItem(item)
{
	if(!isDefined(game["precached_items"])) game["precached_items"] = [];
	if(!isInArray(game["precached_items"], item))
	{
		if(isDefined(game["precachedone"])) return;

		if(game["precached_items"].size >= level.ex_tune_cachelimit_items) // max 127
		{
			logprint("PRC: Too many precached items! Precache request for \"" + item + "\" ignored\n");
			return;
		}

		game["precached_items"][game["precached_items"].size] = item;
		precacheItem(item);
	}

	if(isDefined(level.weapons) && isDefined(level.weapons[item])) level.weapons[item].precached = true;
}

ex_PrecacheString(string)
{
	if(isDefined(game["precachedone"])) return;
	if(!isDefined(game["precached_strings"])) game["precached_strings"] = [];
	if(isInArray(game["precached_strings"], string)) return;

	if(game["precached_strings"].size >= level.ex_tune_cachelimit_strings) // max 254
	{
		logprint("PRC: Too many precached strings! Precache request ignored\n");
		return;
	}

	game["precached_strings"][game["precached_strings"].size] = string;
	precacheString(string);
}

ex_PrecacheMenu(menu)
{
	if(isDefined(game["precachedone"])) return;
	if(!isDefined(game["precached_menus"])) game["precached_menus"] = [];
	if(isInArray(game["precached_menus"], menu)) return;

	if(game["precached_menus"].size >= level.ex_tune_cachelimit_menus) // max 32
	{
		logprint("PRC: Too many precached menus! Precache request for \"" + menu + "\" ignored\n");
		return;
	}

	game["precached_menus"][game["precached_menus"].size] = menu;
	precacheMenu(menu);
}

ex_PrecacheShellShock(shock)
{
	if(isDefined(game["precachedone"])) return;
	if(!isDefined(game["precached_shellshocks"])) game["precached_shellshocks"] = [];
	if(isInArray(game["precached_shellshocks"], shock)) return;

	if(game["precached_shellshocks"].size >= level.ex_tune_cachelimit_shellshocks) // max 15
	{
		logprint("PRC: Too many precached shellshocks! Precache request for \"" + shock + "\" ignored\n");
		return;
	}

	game["precached_shellshocks"][game["precached_shellshocks"].size] = shock;
	precacheShellShock(shock);
}

ex_PrecacheRumble(rumble)
{
	if(isDefined(game["precachedone"])) return;
	if(!isDefined(game["precached_rumbles"])) game["precached_rumbles"] = [];
	if(isInArray(game["precached_rumbles"], rumble)) return;

	if(game["precached_rumbles"].size >= level.ex_tune_cachelimit_rumbles) // max 15
	{
		logprint("PRC: Too many precached rumbles! Precache request for \"" + rumble + "\" ignored\n");
		return;
	}

	game["precached_rumbles"][game["precached_rumbles"].size] = rumble;
	precacheRumble(rumble);
}

reportPrecache()
{
	if(isDefined(game["reportprecached"])) return;
	game["reportprecached"] = true;

	verbose = (level.ex_log_precache == 2);
	logprint("PRC: Precache report:\n");

	// strings
	if(isDefined(game["precached_strings"])) logprint("PRC: " + numToStrPadded(game["precached_strings"].size, 5) + " precached strings (max 254)\n");
	else logprint("PRC: " + numToStrPadded(0, 5) + " precached strings (max 254)\n");

	// models
	if(isDefined(game["precached_models"]))
	{
		logprint("PRC: " + numToStrPadded(game["precached_models"].size, 5) + " precached models (max 254; 127 reserved)\n");
		if(verbose)
		{
			for(i = 0; i < game["precached_models"].size; i++)
				logprint("PRC:   precached model " + (i+1) + ": " + game["precached_models"][i] + "\n");
		}
	}
	else logprint("PRC: " + numToStrPadded(0, 5) + " precached models (max 254; 127 reserved)\n");

	// shaders
	if(isDefined(game["precached_shaders"]))
	{
		logprint("PRC: " + numToStrPadded(game["precached_shaders"].size, 5) + " precached shaders (max 127)\n");
		if(verbose)
		{
			for(i = 0; i < game["precached_shaders"].size; i++)
				logprint("PRC:   precached shader " + (i+1) + ": " + game["precached_shaders"][i] + "\n");
		}
	}
	else logprint("PRC: " + numToStrPadded(0, 5) + " precached shaders (max 127)\n");

	// weapons
	if(isDefined(game["precached_items"]))
	{
		logprint("PRC: " + numToStrPadded(game["precached_items"].size, 5) + " precached weapons (max 127; 1 reserved)\n");
		if(verbose)
		{
			for(i = 0; i < game["precached_items"].size; i++)
				logprint("PRC:   precached weapon " + (i+1) + ": " + game["precached_items"][i] + "\n");
		}
	}
	else logprint("PRC: " + numToStrPadded(0, 5) + " precached weapons (max 127; 1 reserved)\n");

	// effects
	if(isDefined(game["precached_effects"]))
	{
		logprint("PRC: " + numToStrPadded(game["precached_effects"].size, 5) + " precached effects (max 63; 8 reserved)\n");
		if(verbose)
		{
			for(i = 0; i < game["precached_effects"].size; i++)
				logprint("PRC:   precached effect " + (i+1) + ": " + game["precached_effects"][i].effect + " (ID: " + game["precached_effects"][i].effect_id +")\n");
		}
	}
	else logprint("PRC: " + numToStrPadded(0, 5) + " precached effects (max 63; 8 reserved)\n");

	// menus
	if(isDefined(game["precached_menus"]))
	{
		logprint("PRC: " + numToStrPadded(game["precached_menus"].size, 5) + " precached menus (max 32)\n");
		if(verbose)
		{
			for(i = 0; i < game["precached_menus"].size; i++)
				logprint("PRC:   precached menu " + (i+1) + ": " + game["precached_menus"][i] + "\n");
		}
	}
	else logprint("PRC: " + numToStrPadded(0, 5) + " precached menus (max 32)\n");

	// head icons
	if(isDefined(game["precached_headicons"]))
	{
		logprint("PRC: " + numToStrPadded(game["precached_headicons"].size, 5) + " precached head icons (max 15)\n");
		if(verbose)
		{
			for(i = 0; i < game["precached_headicons"].size; i++)
				logprint("PRC:   precached head icon " + (i+1) + ": " + game["precached_headicons"][i] + "\n");
		}
	}
	else logprint("PRC: " + numToStrPadded(0, 5) + " precached head icons (max 15)\n");

	// shellshocks
	if(isDefined(game["precached_shellshocks"]))
	{
		logprint("PRC: " + numToStrPadded(game["precached_shellshocks"].size, 5) + " precached shell shocks (max 15)\n");
		if(verbose)
		{
			for(i = 0; i < game["precached_shellshocks"].size; i++)
				logprint("PRC:   precached shellshock " + (i+1) + ": " + game["precached_shellshocks"][i] + "\n");
		}
	}
	else logprint("PRC: " + numToStrPadded(0, 5) + " precached shell shocks (max 15)\n");

	// rumbles
	if(isDefined(game["precached_rumbles"]))
	{
		logprint("PRC: " + numToStrPadded(game["precached_rumbles"].size, 5) + " precached rumbles (max 15)\n");
		if(verbose)
		{
			for(i = 0; i < game["precached_rumbles"].size; i++)
				logprint("PRC:   precached rumble " + (i+1) + ": " + game["precached_rumbles"][i] + "\n");
		}
	}
	else logprint("PRC: " + numToStrPadded(0, 5) + " precached rumbles (max 15)\n");

	// status icons
	if(isDefined(game["precached_statusicons"]))
	{
		logprint("PRC: " + numToStrPadded(game["precached_statusicons"].size, 5) + " precached status icons (max 8)\n");
		if(verbose)
		{
			for(i = 0; i < game["precached_statusicons"].size; i++)
				logprint("PRC:   precached status icon " + (i+1) + ": " + game["precached_statusicons"][i] + "\n");
		}
	}
	else logprint("PRC: " + numToStrPadded(0, 5) + " precached status icons (max 8)\n");
}

isInEffectsArray(array, effect)
{
	if(!isDefined(array) || !array.size) return(-1);

	i = 0;
	while(i < array.size)
	{
		if(array[i].effect == effect) return(array[i].effect_id);
		i++;
		if(i % 10 == 0) resettimeout();
	}
	return(-1);
}

isInArray(array, element)
{
	if(!isDefined(array) || !array.size) return(false);

	i = 0;
	while(i < array.size)
	{
		if(array[i] == element) return(true);
		i++;
		if(i % 10 == 0) resettimeout();
	}
	return(false);
}

//------------------------------------------------------------------------------
// Dimensions and positioning
//------------------------------------------------------------------------------
getMapDim(debug)
{
	if(!isDefined(debug)) debug = false;

	mark = getTime();

	xMin = 20000;
	xMax = -20000;
	yMin = 20000;
	yMax = -20000;
	zMin = 20000;
	zMax = -20000;
	zSky = -20000;

	entitytypes = [];
	entitytypes[entitytypes.size] = "mp_dm_spawn";
	entitytypes[entitytypes.size] = "mp_tdm_spawn";
	entitytypes[entitytypes.size] = "mp_ctf_spawn_allied";
	entitytypes[entitytypes.size] = "mp_ctf_spawn_axis";
	entitytypes[entitytypes.size] = "mp_sd_spawn_attacker";
	entitytypes[entitytypes.size] = "mp_sd_spawn_defender";

	// get X, Y and Z min and max values from all common spawnpoints
	for(e = 0; e < entitytypes.size; e++)
	{
		entities = getentarray(entitytypes[e], "classname");

		for(i = 0; i < entities.size; i++)
		{
			if(isDefined(entities[i].origin))
			{
				origin = entities[i].origin;

				if(origin[0] < xMin) xMin = origin[0];
				if(origin[0] > xMax) xMax = origin[0];
				if(origin[1] < yMin) yMin = origin[1];
				if(origin[1] > yMax) yMax = origin[1];
				if(origin[2] < zMin) zMin = origin[2];
				if(origin[2] > zMax) zMax = origin[2];
				if(zMax > zSky) zSky = zMax;

				trace = bulletTrace(origin, origin + (0,0,20000), false, undefined);
				if(trace["fraction"] != 1 && trace["position"][2] > zSky)
				{
					if(trace["position"][2] < 6000) zSky = trace["position"][2];
						else if(zSky != 6000) zSky = 6000;
				}
			}

			if(i % 100 == 0) wait( level.ex_fps_frame );
		}
	}

	// get Z min and max values from mp_global_intermission
	entities = getentarray("mp_global_intermission", "classname");
	for(i = 0; i < entities.size; i++)
	{
		if(isDefined(entities[i].origin))
		{
			origin = entities[i].origin;

			if(origin[2] < zMin) zMin = origin[2];
			if(origin[2] > zMax) zMax = origin[2];
			if(zMax > zSky) zSky = zMax;

			trace = bulletTrace(origin, origin + (0,0,20000), false, undefined);
			if(trace["fraction"] != 1 && trace["position"][2] > zSky)
			{
				if(trace["position"][2] < 6000) zSky = trace["position"][2];
					else if(zSky != 6000) zSky = 6000;
			}
		}
	}

	// set the play area variables
	game["playArea_CentreX"] = int( (xMax + xMin) / 2 );
	game["playArea_CentreY"] = int( (yMax + yMin) / 2 );
	game["playArea_CentreZ"] = int( (zMax + zMin) / 2 );
	game["playArea_Centre"] = (game["playArea_CentreX"], game["playArea_CentreY"], game["playArea_CentreZ"]);

	game["playArea_Min"] = (xMin, yMin, zMin);
	game["playArea_Max"] = (xMax, yMax, zMax);

	game["playArea_Width"] = int(distance((xMin, yMin, 800),(xMax, yMin, 800)));
	game["playArea_Length"] = int(distance((xMin, yMin, 800),(xMin, yMax, 800)));

	// get centre map origin, just below skylimit
	origin = (game["playArea_CentreX"], game["playArea_CentreY"], zSky - 200);

	// get X and Y min and max values for map area
	trace = bulletTrace(origin, origin - (20000,0,0), false, undefined);
	if(trace["fraction"] != 1 && trace["position"][0] < xMin) xMin = trace["position"][0];

	trace = bulletTrace(origin, origin + (20000,0,0), false, undefined);
	if(trace["fraction"] != 1 && trace["position"][0] > xMax) xMax = trace["position"][0];

	trace = bulletTrace(origin, origin - (0,20000,0), false, undefined);
	if(trace["fraction"] != 1 && trace["position"][1] < yMin) yMin = trace["position"][1];

	trace = bulletTrace(origin, origin + (0,20000,0), false, undefined);
	if(trace["fraction"] != 1 && trace["position"][1] > yMax) yMax = trace["position"][1];

	// set the map area variables
	game["mapArea_CentreX"] = int( (xMax + xMin) / 2 );
	game["mapArea_CentreY"] = int( (yMax + yMin) / 2 );
	game["mapArea_CentreZ"] = int( (zSky + zMin) / 2 );
	game["mapArea_Centre"] = (game["mapArea_CentreX"], game["mapArea_CentreY"], game["mapArea_CentreZ"]);

	game["mapArea_Max"] = (xMax, yMax, zSky);
	game["mapArea_Min"] = (xMin, yMin, zMin);

	game["mapArea_Width"] = int(distance((xMin, yMin, zSky),(xMax, yMin, zSky)));
	game["mapArea_Length"] = int(distance((xMin, yMin, zSky),(xMin, yMax, zSky)));

	if(debug)
	{
		took = (getTime() - mark) / 1000;
		logprint("DEB: getMapDim took " + took + " seconds\n");

		ne = (game["mapArea_Max"][0] - 200,game["mapArea_Min"][1] - 200,game["mapArea_Max"][2] - 200);
		se = (game["mapArea_Min"][0] - 200,game["mapArea_Min"][1] - 200,game["mapArea_Max"][2] - 200);
		sw = (game["mapArea_Min"][0] - 200,game["mapArea_Max"][1] - 200,game["mapArea_Max"][2] - 200);
		nw = (game["mapArea_Max"][0] - 200,game["mapArea_Max"][1] - 200,game["mapArea_Max"][2] - 200);
		logprint("DEB: ne=" + ne + ", se=" + se + ", sw=" + sw + ", nw=" + nw + ", mapheight=" + game["mapArea_Max"][2] + "\n");
		thread dropLine(ne, se, (1,0,0), 0);
		thread dropLine(se, sw, (1,0,0), 0);
		thread dropLine(sw, nw, (1,0,0), 0);
		thread dropLine(nw, ne, (1,0,0), 0);

		ne = (game["playArea_Max"][0],game["playArea_Min"][1],game["mapArea_Max"][2] - 200);
		se = (game["playArea_Min"][0],game["playArea_Min"][1],game["mapArea_Max"][2] - 200);
		sw = (game["playArea_Min"][0],game["playArea_Max"][1],game["mapArea_Max"][2] - 200);
		nw = (game["playArea_Max"][0],game["playArea_Max"][1],game["mapArea_Max"][2] - 200);
		logprint("DEB: ne=" + ne + ", se=" + se + ", sw=" + sw + ", nw=" + nw + ", playheight=" + game["playArea_Max"][2] + "\n");
		thread dropLine(ne, se, (1,0,0), 0);
		thread dropLine(se, sw, (1,0,0), 0);
		thread dropLine(sw, nw, (1,0,0), 0);
		thread dropLine(nw, ne, (1,0,0), 0);

		logprint("DEB: game[\"playArea_CentreX\"] = " + game["playArea_CentreX"] + "\n");
		logprint("DEB: game[\"playArea_CentreY\"] = " + game["playArea_CentreY"] + "\n");
		logprint("DEB: game[\"playArea_CentreZ\"] = " + game["playArea_CentreZ"] + "\n");
		logprint("DEB: game[\"playArea_Centre\"] = " + game["playArea_Centre"] + "\n");
		logprint("DEB: game[\"playArea_Max\"] = " + game["playArea_Max"] + "\n");
		logprint("DEB: game[\"playArea_Min\"] = " + game["playArea_Min"] + "\n");
		logprint("DEB: game[\"playArea_Width\"] = " + game["playArea_Width"] + "\n");
		logprint("DEB: game[\"playArea_Length\"] = " + game["playArea_Length"] + "\n");

		logprint("DEB: game[\"mapArea_CentreX\"] = " + game["mapArea_CentreX"] + "\n");
		logprint("DEB: game[\"mapArea_CentreY\"] = " + game["mapArea_CentreY"] + "\n");
		logprint("DEB: game[\"mapArea_CentreZ\"] = " + game["mapArea_CentreZ"] + "\n");
		logprint("DEB: game[\"mapArea_Centre\"] = " + game["mapArea_Centre"] + "\n");
		logprint("DEB: game[\"mapArea_Max\"] = " + game["mapArea_Max"] + "\n");
		logprint("DEB: game[\"mapArea_Min\"] = " + game["mapArea_Min"] + "\n");
		logprint("DEB: game[\"mapArea_Width\"] = " + game["mapArea_Width"] + "\n");
		logprint("DEB: game[\"mapArea_Length\"] = " + game["mapArea_Length"] + "\n");
	}

	entities = [];
	entities = undefined;
}

getNearestSpawnpoint(origin)
{
	level endon("ex_gameover");
	self endon("disconnect");

	spawnpoints = [];

	spawn_entities = getentarray("mp_dm_spawn", "classname");
	if(isDefined(spawn_entities)) for(i = 0; i < spawn_entities.size; i++) spawnpoints[spawnpoints.size] = spawn_entities[i];

	if(!spawnpoints.size || level.ex_teamplay)
	{
		spawn_entities = getentarray("mp_tdm_spawn", "classname");
		if(isDefined(spawn_entities)) for(i = 0; i < spawn_entities.size; i++) spawnpoints[spawnpoints.size] = spawn_entities[i];
	}
	if(!spawnpoints.size || level.ex_flagbased)
	{
		spawn_entities = getentarray("mp_ctf_spawn_allied", "classname");
		if(isDefined(spawn_entities)) for(i = 0; i < spawn_entities.size; i++) spawnpoints[spawnpoints.size] = spawn_entities[i];
		spawn_entities = getentarray("mp_ctf_spawn_axis", "classname");
		if(isDefined(spawn_entities)) for(i = 0; i < spawn_entities.size; i++) spawnpoints[spawnpoints.size] = spawn_entities[i];
	}
	if(!spawnpoints.size)
	{
		spawn_entities = getentarray("mp_sd_spawn_attacker", "classname");
		if(isDefined(spawn_entities)) for(i = 0; i < spawn_entities.size; i++) spawnpoints[spawnpoints.size] = spawn_entities[i];
		spawn_entities = getentarray("mp_sd_spawn_defender", "classname");
		if(isDefined(spawn_entities)) for(i = 0; i < spawn_entities.size; i++) spawnpoints[spawnpoints.size] = spawn_entities[i];
	}

	if(isDefined(level.ex_spawnpoints)) for(i = 0; i < level.ex_spawnpoints.size; i++) spawnpoints[spawnpoints.size] = level.ex_spawnpoints[i];

	nearest_spot = spawnpoints[0];
	nearest_dist = distance(origin, spawnpoints[0].origin);

	for(i = 1; i < spawnpoints.size; i++)
	{
		trace = bullettrace(spawnpoints[i].origin, spawnpoints[i].origin + (0,0,300), true, undefined);
		trace_dist = int(distance(spawnpoints[i].origin, trace["position"]));

		if(!isDefined(trace_dist) || trace_dist == 300)
		{
			dist = distance(origin, spawnpoints[i].origin);
			if(dist < nearest_dist)
			{
				nearest_spot = spawnpoints[i];
				nearest_dist = dist;
			}
		}
	}

	return(nearest_spot);
}

getRandomPosPlayArea(correction)
{
	if(!isDefined(correction)) correction = 0;

	x = game["playArea_Min"][0] + randomInt(game["playArea_Width"]);
	y = game["playArea_Min"][1] + randomInt(game["playArea_Length"]);
	z = game["mapArea_Max"][2] - correction;

	return( (x,y,z) );
}

getDropPosPlayArea(side, correction)
{
	pos = getPosPlayArea(side, correction);
	trace = bulletTrace(pos, pos + (0,0,-100000), false, undefined);
	if(trace["fraction"] == 1.0 || trace["surfacetype"] == "default") return(undefined);
	return(pos);
}

getDropPosFromTarget(pos, correction)
{
	z = game["mapArea_Max"][2] - correction;
	if(level.ex_planes_altitude && (level.ex_planes_altitude <= z)) z = level.ex_planes_altitude;
	return( (pos[0],pos[1],z) );
}

getTargetPosPlayArea(side)
{
	return(getTargetPos(getPosPlayArea(side, 0)));
}

getStartPosPlayArea(side, correction)
{
	if(!isDefined(side)) side = randomInt(4);
	if(!isDefined(correction)) correction = 0;

	z = game["mapArea_Max"][2] - correction;

	switch(side)
	{
		// North side of map area
		case 0: {
			x = game["playArea_Max"][0];
			y = randomInt(game["playArea_Length"]);
			break;
		}
		// East side of map area
		case 1: {
			x = randomInt(game["playArea_Width"]);
			y = game["playArea_Min"][1];
			break;
		}
		// South side of map area
		case 2: {
			x = randomInt(game["playArea_Width"]);
			y = game["playArea_Max"][1];
			break;
		}
		// West side of map area
		default: {
			x = game["playArea_Min"][0];
			y = randomInt(game["playArea_Length"]);
			break;
		}
	}

	return( (x,y,z) );
}

getStartPosMapArea(side, correction)
{
	if(!isDefined(side)) side = randomInt(4);
	if(!isDefined(correction)) correction = 0;

	z = game["mapArea_Max"][2] - correction;

	switch(side)
	{
		// North side of map area
		case 0: {
			x = game["mapArea_Max"][0];
			y = randomInt(game["mapArea_Length"]);
			break;
		}
		// East side of map area
		case 1: {
			x = randomInt(game["mapArea_Width"]);
			y = game["mapArea_Min"][1];
			break;
		}
		// South side of map area
		case 2: {
			x = randomInt(game["mapArea_Width"]);
			y = game["mapArea_Max"][1];
			break;
		}
		// West side of map area
		default: {
			x = game["mapArea_Min"][0];
			y = randomInt(game["mapArea_Length"]);
			break;
		}
	}

	return( (x,y,z) );
}

getPosPlayArea(side, correction)
{
	if(!isDefined(side)) side = randomInt(4);
	if(!isDefined(correction)) correction = 0;

	z = game["mapArea_Max"][2] - correction;
	if(level.ex_planes_altitude && (level.ex_planes_altitude <= z)) z = level.ex_planes_altitude;

	switch(side)
	{
		// North-East quadrant of map area
		case 0:
			x = game["playArea_Max"][0] - randomInt( int(game["playArea_Width"] / 2) );
			y = game["playArea_Min"][1] + randomInt( int(game["playArea_Length"] / 2) );
			break;
		// South-East quadrant of map area
		case 1:
			x = game["playArea_Min"][0] + randomInt( int(game["playArea_Width"] / 2) );
			y = game["playArea_Min"][1] + randomInt( int(game["playArea_Length"] / 2) );
			break;
		// South-West quadrant of map area
		case 2:
			x = game["playArea_Min"][0] + randomInt( int(game["playArea_Width"] / 2) );
			y = game["playArea_Max"][1] - randomInt( int(game["playArea_Length"] / 2) );
			break;
		// North-West quadrant of map area
		default:
			x = game["playArea_Max"][0] - randomInt( int(game["playArea_Width"] / 2) );
			y = game["playArea_Max"][1] - randomInt( int(game["playArea_Length"] / 2) );
			break;
	}

	return( (x,y,z) );
}

getPosPlayAreaExtended(side, correction)
{
	if(!isDefined(side)) side = randomInt(4);
	if(!isDefined(correction)) correction = 0;

	z = game["mapArea_Max"][2] - correction;

	switch(side)
	{
		// North side of map area
		case 0:
			x = game["playArea_Max"][0] + int( abs(game["mapArea_Max"][0] - game["playArea_Max"][0]) / 2 );
			y = game["playArea_Min"][1] + randomInt(game["playArea_Length"]);
			break;
		// East side of map area
		case 1:
			x = game["playArea_Min"][0] + randomInt(game["playArea_Width"]);
			y = game["playArea_Min"][1] - int( abs(game["mapArea_Min"][1] - game["playArea_Min"][1]) / 2 );
			break;
		// South side of map area
		case 2:
			x = game["playArea_Min"][0] + randomInt(game["playArea_Width"]);
			y = game["playArea_Max"][1] + int( abs(game["mapArea_Max"][1] - game["playArea_Max"][1]) / 2 );
			break;
		// West side of map area
		default:
			x = game["playArea_Min"][0] - int( abs(game["mapArea_Min"][0] - game["playArea_Min"][0]) / 2 );
			y = game["playArea_Min"][1] + randomInt(game["playArea_Length"]);
			break;
	}

	return( (x,y,z) );
}

getTargetPos(pos)
{
	trace = bulletTrace(pos, pos + (0,0,-100000), false, undefined);
	if(trace["fraction"] == 1.0 || trace["surfacetype"] == "default") return(undefined);
		else return(trace["position"]);
}

getTargetPosEye()
{
	start = self getEye() + (0,0,20);
	end = start + [[level.ex_vectorscale]](anglesToForward(self getplayerangles()), 100000);

	trace = bulletTrace(start, end, false, self);
	if(trace["fraction"] == 1.0 || trace["surfacetype"] == "default") return(undefined);
		else return(trace["position"]);
}

getImpactPos(targetpos, accuracy)
{
	impactpos = undefined;
	iterations = 0;

	while(!isDefined(impactpos) && iterations < 5)
	{
		angle = randomInt(180);
		radius = randomInt(accuracy);
		impactpos = targetpos + (cos(angle) * radius, sin(angle) * radius, 0);

		trace = bulletTrace(impactpos + (0,0,100), impactpos + (0,0,-100), false, undefined);
		if(trace["fraction"] != 1) impactpos = trace["position"];
			else impactpos = undefined;

		iterations++;
	}

	return(impactpos);
}

getImpactPosPlane(plane_index, targetpos, accuracy)
{
	impactpos = undefined;
	iterations = 0;

	while(!isDefined(impactpos) && iterations < 5)
	{
		angle = randomInt(180);
		radius = randomInt(accuracy);
		impactpos = targetpos + (cos(angle) * radius, sin(angle) * radius, 0);

		origin = level.planes[plane_index].model.origin;
		vangles = vectortoangles(vectornormalize(impactpos - origin));
		//vangles = (vangles[0], level.planes[plane_index].model.angles[1], vangles[2]);
		forwardpos = origin + [[level.ex_vectorscale]](anglesToForward(vangles), 100000);

		trace = bulletTrace(origin, forwardpos, false, level.planes[plane_index].model);
		if(trace["fraction"] != 1) impactpos = trace["position"];
			else impactpos = undefined;

		iterations++;
	}

	return(impactpos);
}

getImpactSurface(targetpos)
{
	trace = bulletTrace(targetpos + (0,0,100), targetpos + (0,0,-100), false, undefined);
	if(trace["fraction"] != 1) surface = trace["surfacetype"];
		else surface = "dirt";

	if(!isDefined(surface)) surface = "dirt";
	return(surface);
}

getPlaneRoute(pos, angle, minimum, correction)
{
	if(!isDefined(angle)) angle = randomInt(360);
	if(!isDefined(minimum)) minumum = 10000;
	if(!isDefined(correction)) correction = 1000;

	// first get route the old fashioned way
	route = getPlaneStartEnd(pos, angle, minimum, correction);

	// not meeting minimum; calculate best angle instead
	if(minimum && distance(pos, route.startpos) < minimum)
	{
		positions = [];
		for(i = 0; i < 360; i += 10)
		{
			forwardvector = anglesToForward( (0,i,0) );
			forwardpos = getForwardLimit(pos, (0,i,0), 100000, true) + [[level.ex_vectorscale]](forwardvector, 0 - correction);
			dist1 = distance(pos, forwardpos);
			dist1ok = (dist1 >= minimum);

			backwardpos = getForwardLimit(pos, (0,i,0), -100000, true) + [[level.ex_vectorscale]](forwardvector, correction);
			dist2 = distance(pos, backwardpos);
			dist2ok = (dist2 >= minimum);

			// not meeting minimum; check next angle
			if(!dist1ok && !dist2ok) continue;

			index = positions.size;
			positions[index] = spawnstruct();
			if(dist1ok)
			{
				if(dist2ok && (dist2 > dist1))
				{
					positions[index].angle = i;
					positions[index].startpos = backwardpos;
					positions[index].endpos = forwardpos;
				}
				else
				{
					positions[index].angle = angleReverse(i);
					positions[index].startpos = forwardpos;
					positions[index].endpos = backwardpos;
				}
			}
			else
			{
				positions[index].angle = i;
				positions[index].startpos = backwardpos;
				positions[index].endpos = forwardpos;
			}
		}

		// if available, select one of the approved routes
		if(positions.size)
		{
			routeno = randomInt(positions.size);
			route.angle = positions[routeno].angle;
			route.startpos = positions[routeno].startpos;
			route.endpos = positions[routeno].endpos;
		}
		// if not, calculate route based on random angle
		else route = getPlaneStartEnd(pos, randomInt(360), minimum, correction);
	}

	return(route);
}

getPlaneStartEnd(pos, angle, minimum, correction)
{
	if(!isDefined(angle)) angle = randomInt(360);
	if(!isDefined(minimum)) minumum = 0;
	if(!isDefined(correction)) correction = 1000;

	forwardvector = anglesToForward( (0,angle,0) );
	forwardpos = getForwardLimit(pos, (0,angle,0), 100000, true) + [[level.ex_vectorscale]](forwardvector, 0 - correction);
	backwardpos = getForwardLimit(pos, (0,angle,0), -100000, true) + [[level.ex_vectorscale]](forwardvector, correction);

	route = spawnstruct();
	route.angle = angle;
	route.startpos = backwardpos;
	route.endpos = forwardpos;

	if(minimum)
	{
		dist1 = distance(pos, forwardpos);
		if(dist1 < minimum)
		{
			dist2 = distance(pos, backwardpos);
			if(dist2 >= minimum)
			{
				route.angle = angleReverse(angle);
				route.startpos = forwardpos;
				route.endpos = backwardpos;
			}
		}
	}

	return(route);
}

getForwardLimit(pos, angles, radius, oneshot)
{
	forwardvector = anglesToForward( (0,angles[1],0) );
	while(true)
	{
		forwardpos = pos + [[level.ex_vectorscale]](forwardvector, radius);
		trace = bulletTrace(pos, forwardpos, false, undefined);
		if(trace["fraction"] != 1) return(trace["position"]);
		if(oneshot) return(forwardpos);
		pos = forwardpos;
	}
}

getRadius(center, correction)
{
	if(!isDefined(correction)) correction = 0;

	radius = (((game["playArea_Width"] + game["playArea_Length"]) / 2) / 2) + 500;
	deviations = 0;
	deviations_allowed = 3;

	for(i = 0; i < 360; i += 10)
	{
		forwardpos = getForwardLimit(center, (0,i,0), radius, true);
		dist = distance(center, forwardpos);
		if(dist < radius)
		{
			if( (dist < (radius / 2)) && (deviations < deviations_allowed) ) deviations++;
				else radius = dist;
		}
	}

	return(radius - correction);
}

isOutside(origin)
{
	if(!isDefined(origin)) return(false);

	trace = bulletTrace(origin, origin + (0,0,5000), false, undefined);
	if(distance(origin, trace["position"]) >= 2000) return(true);
		else return(false);
}

posForward(origin, angles, length, exclude_entity)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToForward(angles);
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, 50000));
		trace = bulletTrace(origin, forwardpos, true, exclude_entity);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posBack(origin, angles, length, exclude_entity)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToForward(angles);
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, 50000));
		trace = bulletTrace(origin, forwardpos, true, exclude_entity);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, 0 - length);
	return(origin);
}

posUp(origin, angles, length, exclude_entity)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToUp( (0, angles[1], 0) );
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, 50000));
		trace = bulletTrace(origin, forwardpos, false, exclude_entity);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posAngledUp(origin, angles, length, exclude_entity)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToUp(angles);
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, 50000));
		trace = bulletTrace(origin, forwardpos, false, exclude_entity);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posDown(origin, angles, length, exclude_entity)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToUp( (180, angles[1], 0) );
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, 50000));
		trace = bulletTrace(origin, forwardpos, false, exclude_entity);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posAngledDown(origin, angles, length, exclude_entity)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToUp(angles);
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, -50000));
		trace = bulletTrace(origin, forwardpos, false, exclude_entity);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posLeft(origin, angles, length, exclude_entity)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToForward( (0, angles[1] + 90, 0) );
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, 50000));
		trace = bulletTrace(origin, forwardpos, true, exclude_entity);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posAngledLeft(origin, angles, length, exclude_entity)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToRight(angles);
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, -50000));
		trace = bulletTrace(origin, forwardpos, true, exclude_entity);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posRight(origin, angles, length, exclude_entity)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToForward( (0, angles[1] - 90, 0) );
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, 50000));
		trace = bulletTrace(origin, forwardpos, true, exclude_entity);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posAngledRight(origin, angles, length, exclude_entity)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToRight(angles);
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, 50000));
		trace = bulletTrace(origin, forwardpos, true, exclude_entity);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

tooClose(checkspawn, checkobj, checkturret, checkperk, report)
{
	self endon("kill_thread");

	if(!isDefined(checkspawn)) checkspawn = 150;
	if(!isDefined(checkobj)) checkobj = 150;
	if(!isDefined(checkturret)) checkturret = 150;
	if(!isDefined(checkperk)) checkperk = 150;
	if(!isDefined(report)) report = true;

	// Check spawnpoints
	if(checkspawn)
	{
		// if it doesn't exist, create spawnpoints array first
		if(!isDefined(level.ex_current_spawnpoints)) extreme\_ex_spawnpoints::spawnpointArray();

		for(i = 0; i < level.ex_current_spawnpoints.size; i++)
		{
			if(distance(self.origin, level.ex_current_spawnpoints[i].origin) < checkspawn)
			{
				if(report)
				{
					if(report == 1) self iprintln(&"MISC_TOO_CLOSE_SPAWN");
						else self iprintlnbold(&"MISC_TOO_CLOSE_SPAWN");
				}
				return(true);
			}
		}
	}

	// Check turrets
	if(checkturret)
	{
		turrets = getentarray("misc_turret", "classname");
		for(i = 0; i < turrets.size; i++)
		{
			if(isDefined(turrets[i]) && distance(self.origin, turrets[i].origin) < checkturret)
			{
				if(report)
				{
					if(report == 1) self iprintln(&"MISC_TOO_CLOSE_TURRET");
						else self iprintlnbold(&"MISC_TOO_CLOSE_TURRET");
				}
				return(true);
			}
		}

		turrets = getentarray("misc_mg42", "classname");
		for(i = 0; i < turrets.size; i++)
		{
			if(isDefined(turrets[i]) && distance(self.origin, turrets[i].origin) < checkturret)
			{
				if(report)
				{
					if(report == 1) self iprintln(&"MISC_TOO_CLOSE_TURRET");
						else self iprintlnbold(&"MISC_TOO_CLOSE_TURRET");
				}
				return(true);
			}
		}
	}

	// Check perks
	if(checkperk)
	{
		// check bear traps
		if(isDefined(level.beartraps))
		{
			for(i = 0; i < level.beartraps.size; i++)
			{
				if(level.beartraps[i].inuse && distance(self.origin, level.beartraps[i].origin) < checkperk)
				{
					if(report)
					{
						if(report == 1) self iprintln(&"MISC_TOO_CLOSE_PERK");
							else self iprintlnbold(&"MISC_TOO_CLOSE_PERK");
					}
					return(true);
				}
			}
		}

		// check defense bubbles
		if(isDefined(level.bubbles))
		{
			for(i = 0; i < level.bubbles.size; i++)
			{
				if(level.bubbles[i].inuse && distance(self.origin, level.bubbles[i].origin) < checkperk)
				{
					if(report)
					{
						if(report == 1) self iprintln(&"MISC_TOO_CLOSE_PERK");
							else self iprintlnbold(&"MISC_TOO_CLOSE_PERK");
					}
					return(true);
				}
			}
		}

		// check insertions
		if(isDefined(level.insertions))
		{
			for(i = 0; i < level.insertions.size; i++)
			{
				if(level.insertions[i].inuse && distance(self.origin, level.insertions[i].origin) < checkperk)
				{
					if(report)
					{
						if(report == 1) self iprintln(&"MISC_TOO_CLOSE_PERK");
							else self iprintlnbold(&"MISC_TOO_CLOSE_PERK");
					}
					return(true);
				}
			}
		}

		// check sentry guns
		if(isDefined(level.sentryguns))
		{
			for(i = 0; i < level.sentryguns.size; i++)
			{
				if(level.sentryguns[i].inuse && distance(self.origin, level.sentryguns[i].org_origin) < checkperk)
				{
					if(report)
					{
						if(report == 1) self iprintln(&"MISC_TOO_CLOSE_PERK");
							else self iprintlnbold(&"MISC_TOO_CLOSE_PERK");
					}
					return(true);
				}
			}
		}

		// check missile launchers
		if(isDefined(level.gmls))
		{
			for(i = 0; i < level.gmls.size; i++)
			{
				if(level.gmls[i].inuse && distance(self.origin, level.gmls[i].org_origin) < checkperk)
				{
					if(report)
					{
						if(report == 1) self iprintln(&"MISC_TOO_CLOSE_PERK");
							else self iprintlnbold(&"MISC_TOO_CLOSE_PERK");
					}
					return(true);
				}
			}
		}

		// check flak vierling
		if(isDefined(level.flaks))
		{
			for(i = 0; i < level.flaks.size; i++)
			{
				if(level.flaks[i].inuse && distance(self.origin, level.flaks[i].org_origin) < checkperk)
				{
					if(report)
					{
						if(report == 1) self iprintln(&"MISC_TOO_CLOSE_PERK");
							else self iprintlnbold(&"MISC_TOO_CLOSE_PERK");
					}
					return(true);
				}
			}
		}
	}

	// Check objectives
	if(checkobj)
	{
		// check bomb zones
		if(level.ex_currentgt == "esd")
		{
			if(isDefined(level.bombmodel))
			{
				for(i = 0; i < level.bombmodel.size; i++)
				{
					if(isDefined(level.bombmodel[i]) && distance(self.origin, level.bombmodel[i].origin) < checkobj)
					{
						if(report)
						{
							if(report == 1) self iprintln(&"MISC_TOO_CLOSE_OBJ");
								else self iprintlnbold(&"MISC_TOO_CLOSE_OBJ");
						}
						return(true);
					}
				}
			}
			return(false);
		}

		if(level.ex_currentgt == "sd")
		{
			if(isDefined(level.bombmodel))
			{
				if(distance(self.origin, level.bombmodel.origin) < checkobj)
				{
					if(report)
					{
						if(report == 1) self iprintln(&"MISC_TOO_CLOSE_OBJ");
							else self iprintlnbold(&"MISC_TOO_CLOSE_OBJ");
					}
					return(true);
				}
			}
			return(false);
		}

		// check radio zone
		if(level.ex_currentgt == "chq" || level.ex_currentgt == "hq")
		{
			if(isDefined(level.radio))
			{
				for(i = 0; i < level.radio.size; i++)
				{
					if(!level.radio[i].hidden)
					{
						if(distance(self.origin, level.radio[i].origin) < checkobj)
						{
							if(report)
							{
								if(report == 1) self iprintln(&"MISC_TOO_CLOSE_OBJ");
									else self iprintlnbold(&"MISC_TOO_CLOSE_OBJ");
							}
							return(true);
						}
						return(false);
					}
				}
			}
			return(false);
		}

		// check flag zones
		if(level.ex_currentgt == "dom" || level.ex_currentgt == "ons")
		{
			if(isDefined(level.flags))
			{
				for(i = 0; i < level.flags.size; i ++)
				{
					if(distance(self.origin, level.flags[i].origin) < checkobj)
					{
						if(report)
						{
							if(report == 1) self iprintln(&"MISC_TOO_CLOSE_OBJ");
								else self iprintlnbold(&"MISC_TOO_CLOSE_OBJ");
						}
						return(true);
					}
				}
			}
			return(false);
		}

		if(level.ex_currentgt == "ctf" || level.ex_currentgt == "rbctf" || level.ex_currentgt == "ctfb")
		{
			_tooclose = false;
			flag = getent("allied_flag", "targetname");
			if(isDefined(flag) && isDefined(flag.home_origin) && distance(self.origin, flag.home_origin) < checkobj) _tooclose = true;

			if(!_tooclose)
			{
				flag = getent("axis_flag", "targetname");
				if(isDefined(flag) && isDefined(flag.home_origin) && distance(self.origin, flag.home_origin) < checkobj) _tooclose = true;
			}

			if(_tooclose)
			{
				if(report)
				{
					if(report == 1) self iprintln(&"MISC_TOO_CLOSE_OBJ");
						else self iprintlnbold(&"MISC_TOO_CLOSE_OBJ");
				}
				return(true);
			}
			return(false);
		}

		if(level.ex_currentgt == "htf" || level.ex_currentgt == "ihtf")
		{
			_tooclose = false;
			if(isDefined(level.flag) && isDefined(level.flag.home_origin) && distance(self.origin, level.flag.home_origin) < checkobj) _tooclose = true;

			if(_tooclose)
			{
				if(report)
				{
					if(report == 1) self iprintln(&"MISC_TOO_CLOSE_OBJ");
						else self iprintlnbold(&"MISC_TOO_CLOSE_OBJ");
				}
				return(true);
			}
			return(false);
		}
	}

	// If we get this far, there are no restrictions
	return(false);
}

//------------------------------------------------------------------------------
// Angles
//------------------------------------------------------------------------------
angleDebug(impact, from, to)
{
	if(!isDefined(impact)) return;
	if(isDefined(from))
	{
		from = impact + [[level.ex_vectorscale]](from, -30);
		thread dropLine(impact, from, (0,1,0), 30);
	}
	if(isDefined(to))
	{
		to = impact + [[level.ex_vectorscale]](to, 30);
		thread dropLine(impact, to, (1,0,0), 30);
	}
}

circleHor(origin, angles, length)
{
	for(i = 0; i < 360; i += 20)
	{
		origin = origin + [[level.ex_vectorscale]](anglestoforward((0, i, 0)), length);
		// do something creative here
	}
}

circleVert(origin, angles, length)
{
	for(i = 0; i < 360; i += 20)
	{
		origin = origin + [[level.ex_vectorscale]](anglestoup((i, angles[1], 0)), length);
		// do something creative here
	}
}

anglesAdd(a1, a2)
{
	pitch = a1[0] + a2[0];
	yaw = a1[1] + a2[1];
	roll = a1[2] + a2[2];
	return(anglesNormalize( (pitch,yaw,roll) ));
}

angleSubtract(a1, a2)
{
	a = a1 - a2;
	if(abs(a) > 180)
	{
		if(a < -180) a += 360;
			else if(a > 180) a -= 360;
	}
	return(a);
}

angleReverse(angle)
{
	angle = angleNormalize(angle);
	if(angle <= 180) return(angle + 180);
	return(angle - 180);
}

angleNormalize(angle)
{
	if(angle) while(angle >= 360) angle -= 360;
		else while(angle <= -360) angle += 360;
	return(angle);
}

anglesNormalize(angles)
{
	pitch = angleNormalize(angles[0]);
	yaw = angleNormalize(angles[1]);
	roll = angleNormalize(angles[2]);
	return( (pitch, yaw, roll) );
}

dotNormalize(dot)
{
	if(dot < -1) return(-1);
		else if(dot > 1) return(1);
	return(dot);
}

pitchNormalize(angles)
{
	pitch = 0.0 + angles[0];
	if(pitch > 180) pitch = pitch - 360;
	return( (pitch, angles[1], angles[2]) );
}

//------------------------------------------------------------------------------
// String and numbers conversion
//------------------------------------------------------------------------------
roundDecimal(F1, decimals)
{
	if(!isDefined(decimals)) decimals = 1;
	if(!F1) return(0);

	if(F1 < 0) negative = true;
		else negative = false;
	Fn = abs(F1);
	whole = int(Fn);
	x1 = Fn - whole;

	fraction = 0;
	if(x1)
	{
		switch(decimals)
		{
			case 5: // 5 decimals
				x1 += 0.000005;
				fraction = int(100000 * x1) / 100000; break;
			case 4: // 4 decimals
				x1 += 0.00005;
				fraction = int(10000 * x1) / 10000; break;
			case 3: // 3 decimals
				x1 += 0.0005;
				fraction = int(1000 * x1) / 1000; break;
			case 2: // 2 decimals
				x1 += 0.005;
				fraction = int(100 * x1) / 100; break;
			default: // 1 decimal
				x1 += 0.05;
				fraction = int(10 * x1) / 10;
		}
	}

	result = whole + fraction;
	if(negative) result = 0 - result;
	return(result);
}

abs(var)
{
	if(var < 0) var = var * (-1);
	return(var);
}

rev(var)
{
	if(var < 0) var = var * (-1);
		else var = 0 - var;
	return(var);
}

dif(var1, var2)
{
	if(var1 >= var2) diff = var1 - var2;
		else diff = var2 - var1;
	return(abs(diff));
}

pow(numb, power)
{
	result = 1.0;
	for(i = 0; i < power; i++)
		result = result * numb;
	return(result);
}

sqrt(X)
{
	if(X < 0) return(-1);
	e = 0.000000000001;
	while(e > X) e /= 10;
	b = (1.0 + X) / 2;
	c = (b - X / b) / 2;
	iterations = 0;
	while(c > e && iterations < 1000)
	{
		f = b;
		b -= c;
		if(f == b) return(b);
		c = (b - X / b) / 2;
		iterations++;
	}
	return(b);
}

monoString(str, maxchar)
{
	if(!isDefined(str) || (str == "")) return("");
	if(!isDefined(maxchar)) maxchar = 256;

	newstr = "";
	strlen = 0;
	colorcheck = false;
	for(i = 0; i < str.size; i++)
	{
		ch = str[i];
		if(colorcheck)
		{
			colorcheck = false;
			switch(ch)
			{
				case "0":	// black
				case "1":	// red
				case "2":	// green
				case "3":	// yellow
				case "4":	// blue
				case "5":	// cyan
				case "6":	// pink
				case "7":	// white
				case "8":	// Olive
				case "9":	// Grey
					newstr += ("^" + ch);
					break;
				default:
					newstr += "^";
					strlen++;
					if(strlen < maxchar)
					{
						newstr += ch;
						strlen++;
					}
					break;
			}
		}
		else
		{
			if(ch != "^")
			{
				newstr += ch;
				strlen++;
			}
			else colorcheck = true;
		}

		if(strlen >= maxchar) break;
	}

	return(newstr);
}

strToIntArray(str, defint)
{
	info[0] = defint;
	info[1] = defint;
	info[2] = defint;
	info[3] = defint;

	if(!isDefined(str) || !str.size) return(info);

	str_array = strtok(str, ",");
	if(isDefined(str_array) && str_array.size)
	{
		if(isDefined(str_array[0])) info[0] = strToInt(str_array[0], defint);
		if(isDefined(str_array[1])) info[1] = strToInt(str_array[1], defint);
		if(isDefined(str_array[2])) info[2] = strToInt(str_array[2], defint);
		if(isDefined(str_array[3])) info[3] = strToInt(str_array[3], defint);
	}

	return(info);
}

strToInt(str, defint)
{
	if(!isDefined(defint)) defint = 0;
	if(!isDefined(str)) return(defint);

	str = trim(str);
	if(str == "") return(defint);

	validchars = "-+0123456789";
	for(i = 0; i < str.size; i++)
		if(!issubstr(validchars, str[i])) return(defint);

	return(int(str));
}

strToIntMinMax(str, defint, min, max)
{
	if(!isDefined(defint)) defint = 0;
	if(!isDefined(str)) return(defint);

	str = trim(str);
	if(str == "") return(defint);

	validchars = "-+0123456789";
	for(i = 0; i < str.size; i++)
		if(!isSubStr(validchars, str[i])) return(defint);

	val = int(str);
	if(val < min) return(defint);
	if(val > max) return(defint);
	return(val);
}

strToFloat(str, defflt)
{
	if(!isDefined(defflt)) defflt = 0;
	if((!isDefined(str)) || (!str.size)) return(defflt);

	switch(str[0])
	{
		case "+" :
			sign = 1;
			offset = 1;
			break;
		case "-" :
			sign = -1;
			offset = 1;
			break;
		default :
			sign = 1;
			offset = 0;
			break;
	}

	str2 = getsubstr(str, offset);
	parts = strtok(str2, ".");

	intpart = strToInt(parts[0]);
	decpart = strToInt(parts[1]);

	if(decpart < 0) return(defflt);
	if(decpart) for(i = 0; i < parts[1].size; i ++) decpart = decpart / 10;

	return((intpart + decpart) * sign);
}

asString(value)
{
	string = "" + value;
	return(string);
}

isIntStr(str)
{
	if(!isDefined(str) || str == "") return(false);

	validchars = "-+0123456789";
	for(i = 0; i < str.size; i++)
		if(!issubstr(validchars, str[i])) return(false);

	return(true);
}

isBoolStr(str)
{
	if(!isDefined(str) || str == "") return(false);

	validchars = "01";
	for(i = 0; i < str.size; i++)
		if(!issubstr(validchars, str[i])) return(false);

	boolean = int(str);
	if(boolean != 0 && boolean != 1) return(false);

	return(true);
}

isFloatStr(str)
{
	if(!isDefined(str) || str == "") return(false);

	validchars = "-+0123456789.";
	for(i = 0; i < str.size; i++)
		if(!issubstr(validchars, str[i])) return(false);

	return(true);
}

isValidChar(str, validchars)
{
	if(!isDefined(str) || str == "" || str.size > 1) return(false);

	invalidchars = " ,";
	if(issubstr(invalidchars, str)) return(false);
	if(isDefined(validchars) && validchars != "" && !issubstr(validchars, str)) return(false);

	return(true);
}

isValidStr(str)
{
	if(!isDefined(str) || str == "") return(false);

	invalidchars = " ,";
	for(i = 0; i < str.size; i++)
		if(issubstr(invalidchars, str[i])) return(false);

	return(true);
}

justNumbers(str)
{
	if(!isDefined(str) || str == "") return("");

	validchars = "0123456789";
	string = "";

	for(i = 0; i < str.size; i++)
	{
		chr = str[i];
		for(j = 0; j < validchars.size; j++)
			if(chr == validchars[j]) string += validchars[j];
	}

	return(string);
}

justAlphabet(str)
{
	if(!isDefined(str) || str == "") return("");

	uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	lowercase = "abcdefghijklmnopqrstuvwxyz";

	string = "";
	
	for(i = 0; i < str.size; i++)
	{
		chr = str[i];

		for(j = 0; j < uppercase.size; j++)
		{
			if(chr == uppercase[j]) string += uppercase[j];
				else if(chr == lowercase[j]) string += lowercase[j];
		}
	}

	return(string);
}

trim(s)
{
	if(s == "") return("");

	s2 = "";
	s3 = "";

	i = 0;
	while( (i < s.size) && (s[i] == " ") ) i++;
	if(i == s.size) return("");
	for(; i < s.size; i++) s2 += s[i];
	i = s2.size - 1;
	while( (s2[i] == " ") && (i > 0) ) i--;
	for(j = 0; j <= i; j++) s3 += s2[j];

	return(s3);
}

numToStrPadded(number, length, chr)
{
	if(!isDefined(chr)) chr = " ";
	string = "" + number;
	if(string.size > length) length = string.size;
	diff = length - string.size;
	if(diff) string = dupChar(chr, diff) + string;
	return(string);
}

dupChar(chr, length)
{
	string = "";
	for(i = 0; i < length; i++) string = string + chr;
	return(string);
}

explode(str, delimiter)
{
	j = 0;
	temp_array[j] = "";

	for(i = 0; i < str.size; i++)
	{
		if(str[i] == delimiter)
		{
			j++;
			temp_array[j] = "";
		}
		else temp_array[j] += str[i];
	}

	return(temp_array);
}

convertMLJ(string)
{
	string = monoString(string);
	string = tolower(string);
	string = justalphabet(string);
	return(string);
}

getMax(a, b, c, d)
{
	if(a > b) ab = a;
		else ab = b;

	if(c > d) cd = c;
		else cd = d;

	if(ab > cd) m = ab;
		else m = cd;

	return(m);
}

//------------------------------------------------------------------------------
// Players
//------------------------------------------------------------------------------
getEyeTrace(num)
{
	self endon("kill_thread");

	startpos = self getEye() + self getEyeOffset();
	forward = anglesToForward(self getplayerangles());
	forward = [[level.ex_vectorscale]](forward, num);
	endpos = startpos + forward;
	trace = bulletTrace(startpos, endpos, false, undefined);

	return(trace);
}

getEyeForward(num)
{
	self endon("kill_thread");

	startpos = self getEye() + self getEyeOffset();
	forward = anglesToForward(self getplayerangles());
	forward = [[level.ex_vectorscale]](forward, num);
	endpos = startpos + forward;

	return(endpos);
}

getEyeOffset()
{
	self endon("kill_thread");

	switch(self.ex_stance)
	{
		case 0: return( (0,0,16) ); // Stand
		case 1: return( (0,0,2) ); // Crouch
		case 2: return( (0,0,-27) ); // Prone
	}
}

getEyePos()
{
	self endon("kill_thread");

	if(isDefined(self.ex_eyemarker))
	{
		if(distancesquared(self.ex_eyemarker.origin, self.origin) > 0) return(self.ex_eyemarker.origin);
			else return(self geteye());
	}
	else return(self geteye());
}

getPlayerByEntityNo(entityID)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		entID = players[i] getEntityNumber();
		if(entID == entityID) return(players[i]);
	}
	return(undefined);
}

getEntityByPlayerName(name)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
		if(players[i].name == name) return(players[i]);
	return(undefined);
}

getEntityNoByPlayerName(name)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
		if(players[i].name == name) return(players[i] getEntityNumber());
	return(undefined);
}

getTeamPlayers(team)
{
	team_players = [];

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(!isPlayer(players[i]) || players[i].sessionstate == "spectator") continue;
		if(isDefined(players[i].pers["team"]) && players[i].pers["team"] == team) team_players[team_players.size] = players[i];
	}

	return(team_players);
}

getEnemyPlayers(team)
{
	enemy_players = [];

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(!isPlayer(players[i]) || players[i].sessionstate == "spectator") continue;
		if(isDefined(players[i].pers["team"]) && players[i].pers["team"] != team) enemy_players[enemy_players.size] = players[i];
	}

	return(enemy_players);
}

getOtherPlayers(player)
{
	other_players = [];

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(!isPlayer(players[i]) || players[i].sessionstate == "spectator") continue;
		if(players[i] != player) other_players[other_players.size] = players[i];
	}

	return(other_players);
}

assignToEnemyPlayer(device)
{
	if(!isPlayer(self)) return;

	if(level.ex_teamplay) enemies = getEnemyPlayers(self.pers["team"]);
		else enemies = getOtherPlayers(self);

	if(isDefined(enemies) && enemies.size)
	{
		bot = getEntityByPlayerName( enemies[randomInt(enemies.size)].name );
		if(isDefined(bot))
		{
			device.owner = bot;
			device.team = bot.pers["team"];
		}
	}
}

// check if stance is allowed: 0 = stand, 1 = crouch, 2 = prone, 3 = stand or crouch, 4 = crouch or prone
isStanceOK(allowedstance)
{
	stance = self getStance(false);
	switch(allowedstance)
	{
		case 0: if(stance == 0) return(true); break;
		case 1: if(stance == 1) return(true); break;
		case 2: if(stance == 2) return(true); break;
		case 3: if(stance == 0 || stance == 1) return(true); break;
		case 4: if(stance == 1 || stance == 2) return(true); break;
	}

	return(false);
}

getStance(checkjump)
{
	if(checkjump && !self isOnGround()) return(3); // jumping

	if(!isDefined(self.ex_newmodel))
	{
		if(isDefined(self.ex_spinemarker))
		{
			dist = int(self.ex_spinemarker.origin[2] - self.origin[2]);
			if(dist < level.ex_tune_prone) return(2); // prone
				else if(dist < level.ex_tune_crouch) return(1); // crouch
		}
	}

	return(0); // standing
}

pname(player)
{
	if(level.ex_islinuxserver) return(player.name);
	return(player);
}

hotSpot(radius, sMeansOfDeath, sWeapon)
{
	self endon("endhotspot");

	for(;;)
	{
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			if(isPlayer(players[i])) player = players[i];
				else continue;

			if(distance(self.origin, player.origin) > radius) continue;
				else player thread [[level.callbackPlayerDamage]](self, self, 5, 1, sMeansOfDeath, sWeapon, undefined, (0,0,0), "none", 0);
		}

		wait( [[level.ex_fpstime]](0.5) );
	}
}

sanitizeName(str)
{
	if(!isDefined(str) || str == "") return("");

	validchars = "!()+,-.0123456789;=@AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz_{}~";

	tmpname = monoString(str);
	string = "";
	prevchr = "";
	for(i = 0; i < tmpname.size; i++)
	{
		chr = tmpname[i];
		if(chr == ".")
		{
			if(!string.size) continue; // avoid leading dots
			if(chr == prevchr) continue; // avoid double dots
		}
		else if(chr == "[") chr = "{";
		else if(chr == "]") chr = "}";

		for(j = 0; j < validchars.size; j++)
		{
			if(chr == validchars[j])
			{
				string += chr;
				prevchr = chr;
				break;
			}
		}
	}

	if(string == "") string = "noname";
	return(string);
}

playersInRange(range)
{
	if(!isDefined(range) || !range) return(false);

	info["inrange_friendly"] = false;
	info["inrange_enemies"] = false;
	info["closest_enemy"] = undefined;

	closest_enemy_dist = 100000;

	forward = [[level.ex_vectorscale]](anglesToForward(self getPlayerAngles()), range * 5);
	targetpos = self.origin + forward;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(!isPlayer(self)) break;

		player = players[i];
		if(!isPlayer(player) || player == self || player.sessionstate != "playing") continue;

		if(player.pers["team"] == self.pers["team"])
		{
			if( (distance(self.origin, player.origin) <= range) || (isDefined(targetpos) && distance(targetPos, player.origin) <= range * 2) )
				info["inrange_friendly"] = true;
		}
		else if(isDefined(targetpos))
		{
			dist = distance(targetPos, player.origin);
			if(dist <= range * 2)
			{
				info["inrange_enemies"] = true;
				if(!isDefined(info["closest_enemy"])) info["closest_enemy"] = player;
					else if(dist < closest_enemy_dist) info["closest_enemy"] = player;
			}
		}
	}

	return(info);
}

printOnPlayersInRange(owner, msg1, msg2, targetpos)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isAlive(player) && player != owner && player.pers["team"] == owner.pers["team"])
		{
			// only play the warning if they are close to the strike area
			dist = distance( player.origin, targetpos );
			if(dist < 1000)
			{
				player iprintlnbold(msg1, [[level.ex_pname]](owner));
				player iprintlnbold(msg2);
			}
		}
	}
}

weaponPause(time)
{
	self endon("kill_thread");

	self [[level.ex_dWeapon]]();
	wait( [[level.ex_fpstime]](time) );
	if(isPlayer(self)) self [[level.ex_eWeapon]]();
}

weaponWeaken(time)
{
	self endon("kill_thread");

	self.ex_weakenweapon = true;
	wait( [[level.ex_fpstime]](time) );
	if(isPlayer(self)) self.ex_weakenweapon = undefined;
}

execClientCommand(cmd)
{
	self setClientCvar("clientcmd", cmd);
	self openMenuNoMouse(game["menu_clientcmd"]);
	self closeMenu(game["menu_clientcmd"]);
}

forceto(stance)
{
	if(stance == "stand") self thread execClientCommand("+gostand;-gostand");
	else if(stance == "crouch" || stance == "duck") self thread execClientCommand("gocrouch");
	else if(stance == "prone") self thread execClientCommand("goprone");
}

_disableWeapon()
{
	if(!isDefined(self.ex_disabledWeapon)) self.ex_disabledWeapon = 0;
	self.ex_disabledWeapon++;

	// bots don't like disableWeapon(), so we have to hack our way around it
	if(isDefined(self.pers["isbot"]))
	{
		// save the secondary, give them a dummy secondary and switch to it
		if(self.ex_disabledWeapon == 1)
		{
			if(!isDefined(self.weapon)) self.weapon = [];
			if(!isDefined(self.weapon["bot_primaryb"])) self.weapon["bot_primaryb"] = spawnstruct();
			self.weapon["bot_primaryb"].name = self getweaponslotweapon("primaryb");
			self.weapon["bot_primaryb"].clip = self getWeaponSlotClipAmmo("primaryb");
			self.weapon["bot_primaryb"].reserve = self getWeaponSlotAmmo("primaryb");
			self takeweapon(self.weapon["bot_primaryb"].name);
			self setweaponslotweapon("primaryb", "dummy3_mp");
			self setweaponslotclipammo("primaryb", 999);
			self setweaponslotammo("primaryb", 999);
			self setspawnweapon("dummy3_mp");
			self switchtoweapon("dummy3_mp");
		}
	}
	else self disableWeapon();

	extreme\_ex_weapons::weaponsLog(false, "_disableWeapon() finished");
}

_enableWeapon()
{
	if(!isDefined(self.ex_disabledWeapon)) self.ex_disabledWeapon = 0;
	if(self.ex_disabledWeapon) self.ex_disabledWeapon--;

	if(!self.ex_disabledWeapon)
	{
		// restore secondary for bot and switch to primary
		if(isDefined(self.pers["isbot"]) && isDefined(self.weapon) && isDefined(self.weapon["bot_primaryb"]))
		{
			self takeweapon(self getweaponslotweapon("primaryb"));
			if(self.weapon["bot_primaryb"].name != "none")
			{
				self giveweapon(self.weapon["bot_primaryb"].name);
				self setweaponslotclipammo("primaryb", self.weapon["bot_primaryb"].clip);
				self setweaponslotammo("primaryb", self.weapon["bot_primaryb"].reserve);
				self setspawnweapon(self.weapon["primary"].name);
				self switchtoweapon(self.weapon["primary"].name);
			}
			else self setWeaponSlotWeapon("primaryb", "none");
		}
		else self enableWeapon();

		extreme\_ex_weapons::weaponsLog(true, "_enableWeapon() finished");
	}
	else extreme\_ex_weapons::weaponsLog(false, "_enableWeapon() ignored");
}

//------------------------------------------------------------------------------
// Time and timing
//------------------------------------------------------------------------------
calcTime(p1, p2, speed)
{
	time = (distance(p1, p2) * 0.0254) / speed;
	if(time <= 0) time = 0.1;
	return(time);
}

waittill_any(string1, string2)
{
	self endon("death");
	ent = spawnstruct();

	if(isDefined(string1)) self thread waittill_string(string1, ent);
	if(isDefined(string2)) self thread waittill_string(string2, ent);

	ent waittill("returned");
	ent notify("die");
}

waittill_string(msg, ent)
{
	self endon("death");
	ent endon("die");
	self waittill(msg);
	ent notify("returned");
}

waittill_multi(str_multi)
{
	array = strtok(str_multi, " ");
	for(i = 0; i < array.size; i ++)
		self thread waittill_multi_thread(str_multi, array[i]);

	self waittill(str_multi);
}

waittill_multi_thread(str_multi, str)
{
	self endon(str_multi);
	self waittill(str);
	self notify(str_multi);
}

getLocalizedSeconds(value)
{
	switch(value)
	{
		case 1: return(&"TIME_1_SECOND");
		case 2: return(&"TIME_2_SECONDS");
		case 3: return(&"TIME_3_SECONDS");
		case 4: return(&"TIME_4_SECONDS");
		case 5: return(&"TIME_5_SECONDS");
		case 6: return(&"TIME_6_SECONDS");
		case 7: return(&"TIME_7_SECONDS");
		case 8: return(&"TIME_8_SECONDS");
		case 9: return(&"TIME_9_SECONDS");
		case 10: return(&"TIME_10_SECONDS");

		case 11: return(&"TIME_11_SECONDS");
		case 12: return(&"TIME_12_SECONDS");
		case 13: return(&"TIME_13_SECONDS");
		case 14: return(&"TIME_14_SECONDS");
		case 15: return(&"TIME_15_SECONDS");
		case 16: return(&"TIME_16_SECONDS");
		case 17: return(&"TIME_17_SECONDS");
		case 18: return(&"TIME_18_SECONDS");
		case 19: return(&"TIME_19_SECONDS");
		case 20: return(&"TIME_20_SECONDS");

		case 21: return(&"TIME_21_SECONDS");
		case 22: return(&"TIME_22_SECONDS");
		case 23: return(&"TIME_23_SECONDS");
		case 24: return(&"TIME_24_SECONDS");
		case 25: return(&"TIME_25_SECONDS");
		case 26: return(&"TIME_26_SECONDS");
		case 27: return(&"TIME_27_SECONDS");
		case 28: return(&"TIME_28_SECONDS");
		case 29: return(&"TIME_29_SECONDS");
		case 30: return(&"TIME_30_SECONDS");

		case 31: return(&"TIME_31_SECONDS");
		case 32: return(&"TIME_32_SECONDS");
		case 33: return(&"TIME_33_SECONDS");
		case 34: return(&"TIME_34_SECONDS");
		case 35: return(&"TIME_35_SECONDS");
		case 36: return(&"TIME_36_SECONDS");
		case 37: return(&"TIME_37_SECONDS");
		case 38: return(&"TIME_38_SECONDS");
		case 39: return(&"TIME_39_SECONDS");
		case 40: return(&"TIME_40_SECONDS");

		case 41: return(&"TIME_41_SECONDS");
		case 42: return(&"TIME_42_SECONDS");
		case 43: return(&"TIME_43_SECONDS");
		case 44: return(&"TIME_44_SECONDS");
		case 45: return(&"TIME_45_SECONDS");
		case 46: return(&"TIME_46_SECONDS");
		case 47: return(&"TIME_47_SECONDS");
		case 48: return(&"TIME_48_SECONDS");
		case 49: return(&"TIME_49_SECONDS");
		case 50: return(&"TIME_50_SECONDS");

		case 51: return(&"TIME_51_SECONDS");
		case 52: return(&"TIME_52_SECONDS");
		case 53: return(&"TIME_53_SECONDS");
		case 54: return(&"TIME_54_SECONDS");
		case 55: return(&"TIME_55_SECONDS");
		case 56: return(&"TIME_56_SECONDS");
		case 57: return(&"TIME_57_SECONDS");
		case 58: return(&"TIME_58_SECONDS");
		case 59: return(&"TIME_59_SECONDS");
		case 60: return(&"TIME_60_SECONDS");
	}
}

//------------------------------------------------------------------------------
// Bezier curves
//------------------------------------------------------------------------------
linearBezier(maxnodes, pos0, pos1, speed)
{
	node_array = [];
	node_array[0] = spawnstruct();
	node_array[0].node = pos0;
	node_array[0].time = calcTime(self.origin, pos0, speed);
	node_array[0].angles = vectorToAngles(pos0 - self.origin);

	node_prev = pos0;

	for(i = 1; i <= maxnodes; i++)
	{
		index = node_array.size;
		node_array[index] = spawnstruct();

		node = pointLinearBezier(pos0, pos1, i / maxnodes);
		node_array[index].node = node;
		node_array[index].time = calcTime(node_prev, node, speed);
		node_array[index].angles = vectorToAngles(node - node_prev);

		node_prev = node;
		if(i % 10 == 0) wait( level.ex_fps_frame );
	}

	//thread debugBezier(node_array);
	return(node_array);
}

pointLinearBezier(pos0, pos1, t)
{
	// B(t) = (1-t)*P0 + t*P1
	tvec = [[level.ex_vectorscale]](pos0, 1 - t) + [[level.ex_vectorscale]](pos1, t);
	vec = (tvec[0], tvec[1], tvec[2]);
	return(vec);
}

quadraticBezier(maxnodes, pos0, pos1, pos2, speed, maxroll)
{
	node_array = [];
	node_array[0] = spawnstruct();
	node_array[0].node = pos0;
	node_array[0].time = calcTime(self.origin, pos0, speed);
	node_array[0].angles = anglesNormalize(self.angles);

	node_prev = pos0;
	angles_prev = node_array[0].angles;
	angles_roll = node_array[0].angles[2];
	adjust_roll = 0;
	maxroll_right = 0 - maxroll;

	for(i = 1; i <= maxnodes; i++)
	{
		index = node_array.size;
		node_array[index] = spawnstruct();

		node = pointQuadraticBezier(pos0, pos1, pos2, i / maxnodes);
		node_array[index].node = node;
		node_array[index].time = calcTime(node_prev, node, speed);
		if(speed < 45) speed = speed + 1;

		va = vectorToAngles(vectorNormalize(node - node_prev));
		fv = anglesToForward(va);
		rdot = vectorDot(anglesToRight(angles_prev), fv);
		if(rdot < 0 && adjust_roll > maxroll_right) adjust_roll--; // right
			else if(rdot > 0 && adjust_roll < maxroll) adjust_roll++; // left
		node_array[index].angles = (va[0], va[1], angles_roll + adjust_roll);

		node_prev = node;
		angles_prev = node_array[index].angles;
		if(i % 10 == 0) wait( level.ex_fps_frame );
	}

	//thread debugBezier(node_array);
	return(node_array);
}

pointQuadraticBezier(pos0, pos1, pos2, t)
{
	// B(t) = (1-t)^2*P0 + 2(1-t)*t*P1 + t^2*P2
	tvec = [[level.ex_vectorscale]](pos0, pow(1 - t, 2)) +
	       [[level.ex_vectorscale]](pos1, t * (2 * (1 - t))) +
	       [[level.ex_vectorscale]](pos2, pow(t, 2));
	vec = (tvec[0], tvec[1], tvec[2]);
	return(vec);
}

cubicBezier(maxnodes, pos0, pos1, pos2, pos3, speed, maxroll)
{
	node_array = [];
	node_array[0] = spawnstruct();
	node_array[0].node = pos0;
	node_array[0].time = calcTime(self.origin, pos0, speed);
	node_array[0].angles = anglesNormalize(self.angles);

	node_prev = pos0;
	angles_prev = node_array[0].angles;
	angles_roll = node_array[0].angles[2];
	adjust_roll = 0;
	maxroll_right = 0 - maxroll;

	for(i = 1; i <= maxnodes; i++)
	{
		index = node_array.size;
		node_array[index] = spawnstruct();

		node = pointCubicBezier(pos0, pos1, pos2, pos3, i / maxnodes);
		node_array[index].node = node;
		node_array[index].time = calcTime(node_prev, node, speed);
		if(speed < 45) speed = speed + 1;

		va = vectorToAngles(vectorNormalize(node - node_prev));
		fv = anglesToForward(va);
		rdot = vectorDot(anglesToRight(angles_prev), fv);
		if(rdot < 0 && adjust_roll > maxroll_right) adjust_roll--; // right
			else if(rdot > 0 && adjust_roll < maxroll) adjust_roll++; // left
		node_array[index].angles = (va[0], va[1], angles_roll + adjust_roll);

		node_prev = node;
		angles_prev = node_array[index].angles;
		if(i % 10 == 0) wait( level.ex_fps_frame );
	}

	return(node_array);
}

pointCubicBezier(pos0, pos1, pos2, pos3, t)
{
	// B(t) = (1-t)^3*P0 + 3(1-t)^2*t*P1 + 3(1-t)*t^2*P2 + t^3*P3
	tvec = [[level.ex_vectorscale]](pos0, pow(1 - t, 3)) +
	       [[level.ex_vectorscale]](pos1, t * (3 * pow(1 - t, 2))) +
	       [[level.ex_vectorscale]](pos2, pow(t, 2) * (3 * (1 - t))) +
	       [[level.ex_vectorscale]](pos3, pow(t, 3));
	vec = (tvec[0], tvec[1], tvec[2]);
	return(vec);
}

moveBezier(node_array, speed, end_notify)
{
	for(i = 0; i < node_array.size; i++)
	{
		nodetime = node_array[i].time;
		self rotateto(node_array[i].angles, nodetime);
		self moveto(node_array[i].node, nodetime);
		wait( [[level.ex_fpstime]](nodetime * .99) );
	}

	if(isDefined(end_notify)) self notify(end_notify);
}

//------------------------------------------------------------------------------
// Misc
//------------------------------------------------------------------------------
codRGB(red, green, blue)
{
	return( (red/256, green/256, blue/256) );
}

iprintlnboldCLEAR(state, lines)
{
	for(i = 0; i < lines; i++)
	{
		if(state == "all") iprintlnbold(&"MISC_BLANK_LINE_TXT");
			else if(state == "self") self iprintlnbold(&"MISC_BLANK_LINE_TXT");
	}
}

popObject()
{
	origin_org = self.origin;
	vVelocity = [[level.ex_vectorscale]](anglesToForward((-85,0,0)), 15);

	traced = false;
	for(;;)
	{
		vVelocity += (0,0,-2);
		origin_new = self.origin + vVelocity;
		if(origin_new[2] <= origin_org[2])
		{
			if(!traced)
			{
				traced = true;
				// no fancy tracking; just a one-shot trace straight down
				trace = bullettrace(self.origin + (0,0,5), self.origin - (0,0,10000), false, self);
				if(trace["fraction"] != 1)
				{
					if(isDefined(trace["entity"]))
					{
						// hitting a dead player's cloned body
						if(isDefined(trace["entity"].classname) && trace["entity"].classname == "noclass")
							trace = bullettrace(trace["position"], self.origin - (0,0,10000), false, trace["entity"]);
					}
					// only adjust if lower; it's not supposed to go up again
					if(trace["position"][2] < origin_org[2]) origin_org = trace["position"];
						else break;
				}
				else break;
			}
			else break;
		}
		self.origin = origin_new;
		wait( level.ex_fps_frame );
	}

	self.origin = (origin_new[0], origin_new[1], origin_org[2]);
}

placeObject()
{
	trace = bullettrace(self.origin + (0,0,5), self.origin - (0,0,10000), false, self);
	if(trace["fraction"] != 1)
	{
		if(isDefined(trace["entity"]))
		{
			// hitting a dead player's cloned body
			if(isDefined(trace["entity"].classname) && trace["entity"].classname == "noclass")
				trace = bullettrace(trace["position"], self.origin - (0,0,10000), false, trace["entity"]);
		}
		// only adjust if lower; it's not supposed to go up again
		if(trace["position"][2] < self.origin[2]) self.origin = trace["position"];
	}
}

bounceObject(direction, speed, rotation, bounceability, impactsound, objectradius)
{
	vVelocity = [[level.ex_vectorscale]](direction, speed);

	pitch = rotation[0] * 0.05;
	yaw = rotation[1] * 0.05;
	roll = rotation[2] * 0.05;

	iLoop = 0;
	iLoopMax = 5; // max 5 seconds
	iBounce = 0;
	iBounceMax = 5; // max 5 bounces

	for(;;)
	{
		wait(level.ex_fps_frame);

		iLoop += level.ex_fps_frame;
		if(iLoop > iLoopMax) break;

		vVelocity += (0,0,-2);
		neworigin = self.origin + vVelocity;
		newangles = self.angles + (pitch, yaw, roll);

		trace = bulletTrace(self.origin, neworigin, true, self);
		if(trace["fraction"] != 1)
		{
			ignore_entity = false;
			if(isDefined(trace["entity"]))
			{
				if(isPlayer(trace["entity"]) && iLoop < 1) ignore_entity = true;
					else if(isDefined(trace["entity"].classname) && trace["entity"].classname == "noclass") ignore_entity = true;
			}

			if(!ignore_entity)
			{
				iBounce++;
				if(iBounce > iBounceMax) break;

				vOldDirection = vectorNormalize(neworigin - self.origin);
				if(isDefined(objectradius)) self.origin = trace["position"] + [[level.ex_vectorscale]](vOldDirection, 0 - objectradius);
					else self.origin = trace["position"];
				vNewDirection = vOldDirection - [[level.ex_vectorscale]](trace["normal"], vectorDot(vOldDirection, trace["normal"]) * 2);

				vVelocity = [[level.ex_vectorscale]](vNewDirection, length(vVelocity) * bounceability);
				lVelocity = length(vVelocity);
				if(lVelocity < 5) break;
				if(isDefined(impactsound) && iBounce <= 3 && lVelocity > 10) self playSound(impactsound + trace["surfacetype"]);
				continue;
			}
		}

		self rotateto(newangles, .05, 0, 0);
		self moveto(neworigin, .05, 0, 0);
	}

	if(iLoop < iLoopMax)
	{
		self.angles = (0, self.angles[1], 0);
		trace = bullettrace(self.origin + (0,0,10), self.origin - (0,0,1000), false, self);
		if(isDefined(objectradius)) self.origin = trace["position"] + (0,0,(objectradius/2));
			else self.origin = trace["position"];
	}
}

dropLine(start, stop, linecolor, seconds)
{
	if(!isDefined(seconds)) seconds = 10;

	if(seconds) ticks = int(seconds * level.ex_fps);
		else ticks = level.MAX_SIGNED_INT;

	while(ticks > 0)
	{
		line(start, stop, linecolor);
		wait( level.ex_fps_frame );
		ticks--;
	}
}

dropCircle(origin, range, linecolor, seconds)
{
	if(!isDefined(seconds)) seconds = 10;

	if(seconds) ticks = int(seconds * level.ex_fps);
		else ticks = level.MAX_SIGNED_INT;

	while(ticks > 0)
	{
		start = origin + [[level.ex_vectorscale]](anglestoforward((0,0,0)), range);
		for(i = 10; i <= 360; i += 10)
		{
			point = origin + [[level.ex_vectorscale]](anglestoforward((0,i,0)), range);
			line(start, point, linecolor);
			start = point;
		}
		wait( level.ex_fps_frame );
		ticks--;
	}
}

dropText(origin, text, seconds, color, alpha, scale)
{
	if(!isDefined(seconds)) seconds = 10;
	if(!isDefined(color)) color = (0,1,0);
	if(!isDefined(alpha)) alpha = 1;
	if(!isDefined(scale)) scale = 0.3;

	if(seconds) ticks = int(seconds * level.ex_fps);
		else ticks = level.MAX_SIGNED_INT;

	while(ticks > 0)
	{
		print3d(origin, text, color, alpha, scale);
		wait( level.ex_fps_frame );
		ticks--;
	}
}

dropTheFlag(findnewspot)
{
	self endon("disconnect");

	if(level.ex_flagbased)
	{
		if(!isDefined(findnewspot)) findnewspot = false;

		if(isDefined(self.flag))
		{
			dropspot = undefined;
			if(findnewspot) dropspot = self getDropSpot(100);

			switch(level.ex_currentgt)
			{
				case "ctf":
				self thread extreme\_ex_gametype_ctf::dropFlag(dropspot);
				break;

				case "ctfb":
				self thread extreme\_ex_gametype_ctfb::dropFlag(dropspot);
				break;

				case "ihtf":
				self thread extreme\_ex_gametype_ihtf::dropFlag(dropspot);
				break;

				case "htf":
				self thread extreme\_ex_gametype_htf::dropFlag(dropspot);
				break;

				case "rbctf":
				self thread extreme\_ex_gametype_rbctf::dropFlag(dropspot);
				break;
			}
		}

		if(isDefined(self.ownflag))
		{
			dropspot = undefined;
			if(findnewspot) dropspot = self getDropSpot(100);

			switch(level.ex_currentgt)
			{
				case "ctfb":
				self thread extreme\_ex_gametype_ctfb::dropOwnFlag(dropspot);
				break;
			}
		}
	}
}

getDropSpot(radius)
{
	origin = self.origin + (0, 0, 20);
	dropspot = undefined;

	// scan 360 degrees in 20 degree increments for good spot to drop flag
	for(i = 0; i < 360; i += 20)
	{
		// locate candidate spot in circle
		spot0 = origin + [[level.ex_vectorscale]](anglesToForward((0, i, 0)), radius);
		trace = bulletTrace(origin, spot0, false, undefined);
		spot1 = trace["position"];
		dist1 = int(distance(origin, spot1) + 0.5);
		if(dist1 != radius) continue;

		// check if this spot is in minefield (unfortunately needs entity to check)
		badspot = false;
		model1 = spawn("script_model", spot1);
		model1 setmodel("xmodel/tag_origin");
		for(j = 0; j < level.ex_returners.size; j++)
		{
			if(model1 istouching(level.ex_returners[j]))
			{
				badspot = true;
				break;
			}
		}
		model1 delete();
		if(badspot) continue;

		// find ground level
		trace = bulletTrace(spot1, spot1 + (0, 0, -10000), false, undefined);
		spot2 = trace["position"];
		dist2 = int(distance(spot1, spot2) + 0.5);

		// make sure path is clear 50 units up
		trace = bulletTrace(spot2, spot2 + (0, 0, 50), false, undefined);
		spot3 = trace["position"];
		dist3 = int(distance(spot2, spot3) + 0.5);
		if(dist3 != 50) continue;

		dropspot = spot2;
		break;
	}

	return(dropspot);
}

//------------------------------------------------------------------------------
// Parachutes
//------------------------------------------------------------------------------
parachuteMe(chute_model, chute_start, chute_end, chute_speed, chute_angles, chute_hide)
{
	index = parachuteCreate(chute_model, chute_start, chute_end, chute_speed, chute_angles, chute_hide);
	if(index == -1) return(-1);

	if(isDefined(self))
	{
		level.chutes[index].payload = self;
		level.chutes[index].payload.origin = level.chutes[index].anchor.origin;
		level.chutes[index].payload.ex_isparachuting = true;
		level.chutes[index].payload linkTo(level.chutes[index].anchor);
		level thread parachuteGo(index);
		return(index);
	}
	else return(-1);
}

parachuteMeOn(index, notification)
{
	index = parachuteIndex(index);
	if(index == -1) return(-1);
	if(level.chutes[index].status != 2) return(-1);

	if(isDefined(self))
	{
		level.chutes[index].payload = self;
		level.chutes[index].payload.origin = level.chutes[index].anchor.origin;
		level.chutes[index].payload.ex_isparachuting = true;
		level.chutes[index].payload linkTo(level.chutes[index].anchor);
		if(isDefined(notification)) level.chutes[index].payload waittill(notification);
		level thread parachuteGo(index);
	}
}

parachuteCreate(chute_model, chute_start, chute_end, chute_speed, chute_angles, chute_hide)
{
	if(!isDefined(chute_model) || !isDefined(chute_start) || !isDefined(chute_end)) return(-1);

	index = parachuteAlloc();
	level.chutes[index].status = 2; // idle
	level.chutes[index].payload = undefined;
	level.chutes[index].autokill = 180;
	level.chutes[index].anchor = spawn("script_model", chute_start);
	level.chutes[index].speed = 3;
	if(isDefined(chute_speed)) level.chutes[index].speed = chute_speed;
	if(isDefined(chute_angles)) level.chutes[index].anchor.angles = chute_angles;
	level.chutes[index].endpos = chute_end;

	level.chutes[index].model = spawn("script_model", chute_start);
	if(isDefined(chute_hide) && chute_hide) level.chutes[index].model hide();
	level.chutes[index].model setModel(chute_model);
	level.chutes[index].model linkTo(level.chutes[index].anchor);

	thread parachuteMonitor(index);

	return(index);
}

parachuteMonitor(index)
{
	chute_time = 0;
	while(true)
	{
		wait( [[level.ex_fpstime]](0.5) );
		chute_time++;
		if(level.chutes[index].status == 0 || chute_time >= level.chutes[index].autokill)
		{
			parachuteFree(index);
			break;
		}
	}
}

parachuteGo(index)
{
	index = parachuteIndex(index);
	if(index == -1) return;

	falltime = calcTime(level.chutes[index].anchor.origin, level.chutes[index].endpos, level.chutes[index].speed);

	level.chutes[index].status = 1; // move
	level.chutes[index].autokill = (falltime * 2) + 10;
	level.chutes[index].anchor playSound("para_plane");
	level.chutes[index].anchor playLoopSound ("para_wind");
	level.chutes[index].anchor moveto(level.chutes[index].endpos, falltime);
	level.chutes[index].anchor waittill("movedone");
	level.chutes[index].anchor stopLoopSound();
	level.chutes[index].anchor playSound("para_land");
	earthquake(0.4, 1.2, level.chutes[index].anchor.origin, 70);

	if(isDefined(level.chutes[index].payload))
	{
		level.chutes[index].payload unlink();
		level.chutes[index].payload.ex_isparachuting = undefined;
		level.chutes[index].payload = undefined;
	}

	level.chutes[index].status = 0; // done
}

parachuteIsDone(index)
{
	index = parachuteIndex(index);
	if(index == -1) return(true);
	return( (level.chutes[index].status == 0) );
}

parachuteStatus(index)
{
	index = parachuteIndex(index);
	if(index == -1) return(-1);
	return(level.chutes[index].status);
}

parachuteHide(index)
{
	index = parachuteIndex(index);
	if(index == -1) return;
	level.chutes[index].model hide();
}

parachuteShow(index)
{
	index = parachuteIndex(index);
	if(index == -1) return;
	level.chutes[index].model show();
}

parachuteAlloc()
{
	if(!isDefined(level.chutes)) level.chutes = [];

	for(i = 0; i < level.chutes.size; i++)
	{
		if(level.chutes[i].inuse == 0)
		{
			level.chutes[i].inuse = 1;
			return(i);
		}
	}

	level.chutes[i] = spawnstruct();
	level.chutes[i].inuse = 1;
	return(i);
}

parachuteFree(index)
{
	index = parachuteIndex(index);
	if(index == -1) return;

	level.chutes[index].model unlink();
	level.chutes[index].model delete();
	level.chutes[index].anchor delete();
	level.chutes[index].inuse = 0;
}

parachuteIndex(index)
{
	if(!isDefined(index) || index < 0) return(-1);
	if(!isDefined(level.chutes[index]) || !level.chutes[index].inuse) return(-1);
	return(index);
}
