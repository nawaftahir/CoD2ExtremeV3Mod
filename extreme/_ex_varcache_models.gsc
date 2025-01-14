
init()
{
	// multi-purpose (devices, binoc aimer, gunship, flag drop, sinbin and flamethrower)
	[[level.ex_PrecacheModel]]("xmodel/tag_origin");

	// mbots
	if(level.ex_mbot && level.ex_mbot_dev)
	{
		[[level.ex_PrecacheModel]]("xmodel/marker_glow0");
		[[level.ex_PrecacheModel]]("xmodel/marker_glow1");
		[[level.ex_PrecacheModel]]("xmodel/marker_glow2");

		[[level.ex_PrecacheModel]]("xmodel/marker_camp0");
		[[level.ex_PrecacheModel]]("xmodel/marker_climb0");
		[[level.ex_PrecacheModel]]("xmodel/marker_fall0");
		[[level.ex_PrecacheModel]]("xmodel/marker_jump0");
		[[level.ex_PrecacheModel]]("xmodel/marker_junction0");
		[[level.ex_PrecacheModel]]("xmodel/marker_mantle_up0");
		[[level.ex_PrecacheModel]]("xmodel/marker_mantle_over0");
		[[level.ex_PrecacheModel]]("xmodel/marker_nade0");
		[[level.ex_PrecacheModel]]("xmodel/marker_waypoint0");
		[[level.ex_PrecacheModel]]("xmodel/marker_wpstart0");
	}

	if(level.ex_medicsystem && level.ex_firstaid_drop)
	{
		[[level.ex_PrecacheModel]]("xmodel/health_small");
		[[level.ex_PrecacheModel]]("xmodel/health_medium");
		[[level.ex_PrecacheModel]]("xmodel/health_large");
	}

	// parachutes
	if(level.ex_parachutes || ((level.ex_gunship || level.ex_gunship_special) && level.ex_gunship_eject))
	{
		if(level.ex_modern_weapons)
		{
			game["chute_player_axis"] = "xmodel/vehicle_parachute_glide_grey";
			game["chute_player_allies"] = "xmodel/vehicle_parachute_glide_brown";
		}
		else
		{
			game["chute_player_axis"] = "xmodel/vehicle_parachute_cone_grey";
			game["chute_player_allies"] = "xmodel/vehicle_parachute_cone_brown";
		}

		[[level.ex_PrecacheModel]](game["chute_player_axis"]);
		[[level.ex_PrecacheModel]](game["chute_player_allies"]);
	}

	if(level.ex_amc && level.ex_amc_chutein)
	{
		if(!level.ex_amc_chutein_neutral)
		{
			game["chute_cargo_axis"] = "xmodel/vehicle_parachute_drop_grey";
			game["chute_cargo_allies"] = "xmodel/vehicle_parachute_drop_brown";
			[[level.ex_PrecacheModel]](game["chute_cargo_axis"]);
			[[level.ex_PrecacheModel]](game["chute_cargo_allies"]);
		}
		else
		{
			game["chute_cargo_neutral"] = "xmodel/vehicle_parachute_drop_camo";
			[[level.ex_PrecacheModel]](game["chute_cargo_neutral"]);
		}
	}

	// model changer
	if(level.ex_cmdmonitor && level.ex_cmdmonitor_models)
	{
		[[level.ex_PrecacheModel]]("xmodel/furniture_bedmattress1");
		[[level.ex_PrecacheModel]]("xmodel/furniture_bathtub");
		[[level.ex_PrecacheModel]]("xmodel/furniture_toilet");
		[[level.ex_PrecacheModel]]("xmodel/prop_barrel_benzin");
		[[level.ex_PrecacheModel]]("xmodel/prop_tombstone1");
		[[level.ex_PrecacheModel]]("xmodel/tree_grey_oak_sm_a");
	}

	// knife
	if(level.ex_wepo_class == 10 || (level.ex_wepo_sidearm && level.ex_wepo_sidearm_type))
	{
		if(level.ex_modern_weapons) [[level.ex_PrecacheModel]]("xmodel/viewmodel_modern_knife");
			else [[level.ex_PrecacheModel]]("xmodel/viewmodel_knife");
	}

	// ammocrates
	if(level.ex_amc) [[level.ex_PrecacheModel]]("xmodel/ammocrate_rearming");

	// unfixed turrets
	if(level.ex_turrets > 1)
	{
		[[level.ex_PrecacheModel]]("xmodel/weapon_30cal");
		[[level.ex_PrecacheModel]]("xmodel/weapon_mg42");
	}

	// kill confirmed
	if(level.ex_kc)
	{
		if(level.ex_teamplay)
		{
			switch(level.ex_kc_color_axis)
			{
				case 0: game["dogtag_axis"] = "xmodel/dogtag_blue"; break;
				case 1: game["dogtag_axis"] = "xmodel/dogtag_brass"; break;
				case 2: game["dogtag_axis"] = "xmodel/dogtag_gold"; break;
				case 3: game["dogtag_axis"] = "xmodel/dogtag_green"; break;
				case 4: game["dogtag_axis"] = "xmodel/dogtag_red"; break;
				default: game["dogtag_axis"] = "xmodel/dogtag_silver";
			}
			[[level.ex_PrecacheModel]](game["dogtag_axis"]);
			switch(level.ex_kc_color_allies)
			{
				case 0: game["dogtag_allies"] = "xmodel/dogtag_blue"; break;
				case 1: game["dogtag_allies"] = "xmodel/dogtag_brass"; break;
				case 2: game["dogtag_allies"] = "xmodel/dogtag_gold"; break;
				case 3: game["dogtag_allies"] = "xmodel/dogtag_green"; break;
				case 4: game["dogtag_allies"] = "xmodel/dogtag_red"; break;
				default: game["dogtag_allies"] = "xmodel/dogtag_silver";
			}
			[[level.ex_PrecacheModel]](game["dogtag_allies"]);
		}
		else
		{
			switch(level.ex_kc_color_dm)
			{
				case 0: game["dogtag_axis"] = "xmodel/dogtag_blue"; break;
				case 1: game["dogtag_axis"] = "xmodel/dogtag_brass"; break;
				case 2: game["dogtag_axis"] = "xmodel/dogtag_gold"; break;
				case 3: game["dogtag_axis"] = "xmodel/dogtag_green"; break;
				case 4: game["dogtag_axis"] = "xmodel/dogtag_red"; break;
				default: game["dogtag_axis"] = "xmodel/dogtag_silver";
			}
			[[level.ex_PrecacheModel]](game["dogtag_axis"]);
			game["dogtag_allies"] = game["dogtag_axis"];
		}
	}
}

initPost()
{
	// flamethrower tank
	if(maps\mp\gametypes\_weapons::getWeaponAdvStatus("flamethrower_axis") || maps\mp\gametypes\_weapons::getWeaponAdvStatus("flamethrower_allies"))
		[[level.ex_PrecacheModel]]("xmodel/ft_tank");

	// make sure the level script has the soldier types defined correctly
	switch(game["allies"])
	{
		case "british":
			if(isDefined(game["british_soldiertype"]))
			{
				if(game["british_soldiertype"] != "africa" && game["british_soldiertype"] != "normandy")
					game["british_soldiertype"] = "normandy";
			}
			else game["british_soldiertype"] = "normandy";
			break;
		case "russian":
			if(isDefined(game["russian_soldiertype"]))
			{
				if(game["russian_soldiertype"] != "coats" && game["russian_soldiertype"] != "padded")
					game["russian_soldiertype"] = "coats";
			}
			else game["russian_soldiertype"] = "coats";
			break;
		case "american":
			game["american_soldiertype"] = "normandy";
			break;
	}

	if(isDefined(game["german_soldiertype"]))
	{
		if(game["german_soldiertype"] != "africa" && game["german_soldiertype"] != "normandy" &&
		   game["german_soldiertype"] != "winterdark" && game["german_soldiertype"] != "winterlight")
			game["german_soldiertype"] = "normandy";
	}
	else game["german_soldiertype"] = "normandy";

	// workaround for the 127 bones error with mobile turrets
	if(!isDefined(game["allow_mg30"]))
		game["allow_mg30"] = maps\mp\gametypes\_weapons::getWeaponStatus("mobile_30cal");

	if(!isDefined(game["allow_mg42"]))
		game["allow_mg42"] = maps\mp\gametypes\_weapons::getWeaponStatus("mobile_mg42");

	if(level.ex_turrets > 1 || game["allow_mg30"] || game["allow_mg42"])
	{
		if(isDefined(game["russian_soldiertype"]) && game["russian_soldiertype"] == "coats")
			game["russian_soldiertype"] = "padded";
		if(isDefined(game["german_soldiertype"]) && game["german_soldiertype"] == "winterdark")
			game["german_soldiertype"] = "winterlight";
	}

	// stock processing
	switch(game["allies"])
	{
		case "british":
			if(isDefined(game["british_soldiertype"]) && game["british_soldiertype"] == "africa")
			{
				mptype\british_africa::precache();
				game["allies_model"] = mptype\british_africa::main;
			}
			else
			{
				mptype\british_normandy::precache();
				game["allies_model"] = mptype\british_normandy::main;
			}
			break;

		case "russian":
			if(isDefined(game["russian_soldiertype"]) && game["russian_soldiertype"] == "padded")
			{
				mptype\russian_padded::precache();
				game["allies_model"] = mptype\russian_padded::main;
			}
			else
			{
				mptype\russian_coat::precache();
				game["allies_model"] = mptype\russian_coat::main;
			}
			break;

		case "american":
		default:
			mptype\american_normandy::precache();
			game["allies_model"] = mptype\american_normandy::main;
	}

	if(isDefined(game["german_soldiertype"]) && game["german_soldiertype"] == "winterdark")
	{
		mptype\german_winterdark::precache();
		game["axis_model"] = mptype\german_winterdark::main;
	}
	else if(isDefined(game["german_soldiertype"]) && game["german_soldiertype"] == "winterlight")
	{
		mptype\german_winterlight::precache();
		game["axis_model"] = mptype\german_winterlight::main;
	}
	else if(isDefined(game["german_soldiertype"]) && game["german_soldiertype"] == "africa")
	{
		mptype\german_africa::precache();
		game["axis_model"] = mptype\german_africa::main;
	}
	else
	{
		mptype\german_normandy::precache();
		game["axis_model"] = mptype\german_normandy::main;
	}
}
