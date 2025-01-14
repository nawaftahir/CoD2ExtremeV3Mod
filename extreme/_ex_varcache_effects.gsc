
init()
{
	// explode player punishment
	if(level.ex_rcon || level.ex_cmdmonitor || (level.ex_turrets && level.ex_turretabuse) ||
	  (level.ex_anticamp && (!level.ex_anticamp_punishment || level.ex_anticamp_punishment == 2)) ||
	  (level.ex_anticamp && (!level.ex_anticamp_punishment_sniper || level.ex_anticamp_punishment_sniper == 2)))
		level.ex_effect["barrel"] = [[level.ex_PrecacheEffect]]("fx/props/barrelexp.efx");

	// turret overheating
	if(level.ex_turrets && level.ex_turretoverheat)
		level.ex_effect["armored_car_overheat"] = [[level.ex_PrecacheEffect]]("fx/distortion/armored_car_overheat.efx");

	// plane and heli crash effects
	if(level.ex_planes || level.ex_gunship || level.ex_gunship_special || level.ex_heli || level.ex_ranksystem || (level.ex_amc && level.ex_amc_chutein))
	{
		level.ex_effect["plane_explosion"] = [[level.ex_PrecacheEffect]]("fx/explosions/spitfire_bomb_dirt.efx");
		level.ex_effect["planecrash_smoke"] = [[level.ex_PrecacheEffect]]("fx/smoke/thin_black_smoke_M.efx");
		level.ex_effect["planecrash_explosion"] = [[level.ex_PrecacheEffect]]("fx/explosions/panzer_explosion.efx");
		level.ex_effect["planecrash_ball"] = [[level.ex_PrecacheEffect]]("fx/smoke/battlefield_smokebank_S.efx");
	}

	// WMD
	if(level.ex_wmd && level.ex_wmd_flare) level.ex_effect["flare_indicator"] = [[level.ex_PrecacheEffect]]("fx/misc/flare_artillery_runner.efx");

	// gunship
	if(level.ex_gunship)
	{
		level.ex_effect["gunship_flares"] = [[level.ex_PrecacheEffect]]("fx/flares/ac130_flare_emitter.efx");
		if(level.ex_gunship_nuke && level.ex_gunship_nuke_fx) level.ex_effect["gunship_nuke"] = [[level.ex_PrecacheEffect]]("fx/impacts/gunship_nuke_expand.efx");
	}

	// bleeding
	if(level.ex_bleeding) level.ex_effect["bleeding"] = [[level.ex_PrecacheEffect]]("fx/impacts/bleeding_hit.efx");

	// fire effects for napalm, command monitor fire, flamethrower, fire nades
	level.ex_effect["fire_ground"] = [[level.ex_PrecacheEffect]]("fx/fire/ground_fire_med.efx");
	level.ex_effect["fire_arm"] = [[level.ex_PrecacheEffect]]("fx/fire/character_arm_fire.efx");
	level.ex_effect["fire_torso"] = [[level.ex_PrecacheEffect]]("fx/fire/character_torso_fire.efx");

	// generic explosion effects
	level.ex_effect["explosion_beach"] = [[level.ex_PrecacheEffect]]("fx/explosions/mortarExp_beach.efx");
	level.ex_effect["explosion_concrete"] = [[level.ex_PrecacheEffect]]("fx/explosions/mortarExp_concrete.efx");
	level.ex_effect["explosion_dirt"] = [[level.ex_PrecacheEffect]]("fx/explosions/mortarExp_dirt.efx");
	level.ex_effect["explosion_snow"] = [[level.ex_PrecacheEffect]]("fx/explosions/grenadeExp_snow.efx");
	level.ex_effect["explosion_water"] = [[level.ex_PrecacheEffect]]("fx/explosions/mortarExp_water.efx");
	level.ex_effect["explosion_wood"] = [[level.ex_PrecacheEffect]]("fx/explosions/grenadeExp_wood.efx");

	// binoculars animated crosshair
	if(level.ex_aimrig)
	{
		switch(level.ex_aimrig)
		{
			case 1: game["aimrig_selector"] = [[level.ex_PrecacheEffect]]("fx/selector/ui_selector_black.efx"); break;
			case 2: game["aimrig_selector"] = [[level.ex_PrecacheEffect]]("fx/selector/ui_selector_blue.efx"); break;
			case 3: game["aimrig_selector"] = [[level.ex_PrecacheEffect]]("fx/selector/ui_selector_gold.efx"); break;
			case 4: game["aimrig_selector"] = [[level.ex_PrecacheEffect]]("fx/selector/ui_selector_green.efx"); break;
			case 5: game["aimrig_selector"] = [[level.ex_PrecacheEffect]]("fx/selector/ui_selector_red.efx"); break;
			case 6: game["aimrig_selector"] = [[level.ex_PrecacheEffect]]("fx/selector/ui_selector_silver.efx"); break;
			case 7: game["aimrig_selector"] = [[level.ex_PrecacheEffect]]("fx/selector/ui_selector_yellow.efx"); break;
		}
	}

	if(level.ex_flagbased || level.ex_currentgt == "dom" || level.ex_currentgt == "ons")
	{
		if(level.ex_currentgt == "ctf" || level.ex_currentgt == "ctfb" || level.ex_currentgt == "rbctf" || level.ex_currentgt == "dom" || level.ex_currentgt == "ons")
		{
			if(level.ex_flagbase_anim_allies)
			{
				switch(level.ex_flagbase_anim_allies)
				{
					case 1: game["flagbase_anim_allies"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_black.efx"); break;
					case 2: game["flagbase_anim_allies"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_blue.efx"); break;
					case 3: game["flagbase_anim_allies"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_gold.efx"); break;
					case 4: game["flagbase_anim_allies"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_green.efx"); break;
					case 5: game["flagbase_anim_allies"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_red.efx"); break;
					case 6: game["flagbase_anim_allies"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_silver.efx"); break;
					case 7: game["flagbase_anim_allies"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_yellow.efx"); break;
				}
			}

			if(level.ex_flagbase_anim_axis)
			{
				switch(level.ex_flagbase_anim_axis)
				{
					case 1: game["flagbase_anim_axis"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_black.efx"); break;
					case 2: game["flagbase_anim_axis"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_blue.efx"); break;
					case 3: game["flagbase_anim_axis"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_gold.efx"); break;
					case 4: game["flagbase_anim_axis"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_green.efx"); break;
					case 5: game["flagbase_anim_axis"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_red.efx"); break;
					case 6: game["flagbase_anim_axis"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_silver.efx"); break;
					case 7: game["flagbase_anim_axis"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_yellow.efx"); break;
				}
			}
		}

		if(level.ex_currentgt == "htf" || level.ex_currentgt == "ihtf" || level.ex_currentgt == "dom" || level.ex_currentgt == "ons")
		{
			if(level.ex_flagbase_anim_neutral)
			{
				switch(level.ex_flagbase_anim_neutral)
				{
					case 1: game["flagbase_anim_neutral"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_black.efx"); break;
					case 2: game["flagbase_anim_neutral"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_blue.efx"); break;
					case 3: game["flagbase_anim_neutral"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_gold.efx"); break;
					case 4: game["flagbase_anim_neutral"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_green.efx"); break;
					case 5: game["flagbase_anim_neutral"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_red.efx"); break;
					case 6: game["flagbase_anim_neutral"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_silver.efx"); break;
					case 7: game["flagbase_anim_neutral"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_yellow.efx"); break;
				}
			}
		}
	}
}

initPost()
{
	// flamethrower
	if(maps\mp\gametypes\_weapons::getWeaponAdvStatus("flamethrower_axis") || maps\mp\gametypes\_weapons::getWeaponAdvStatus("flamethrower_allies"))
		level.ex_effect["flamethrower"] = [[level.ex_PrecacheEffect]]("fx/fire/flamethrower.efx");

	// cold breath
	if(level.ex_currentgt == "ft" || (level.ex_wintermap && level.ex_coldbreathfx))
		level.ex_effect["coldbreathfx"] = [[level.ex_PrecacheEffect]]("fx/misc/cold_breath.efx");

	// weather
	if(level.ex_weather) thread extreme\_ex_ambient_weather::init();
}
