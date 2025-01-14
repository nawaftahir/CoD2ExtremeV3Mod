#include extreme\_ex_weapons;
#include extreme\_ex_main_utils;

devInit()
{
	if(level.ex_log_devices) logprint("DEV: Initializing device controller\n");

	// create device arrays
	level.ex_devices = [];
	level.ex_devicerequests = [];
	level.ex_devicequeue = [];
	level.ex_devicequeueID = 0;

	// precaching
	level.ex_effect["missile_trail"] = [[level.ex_PrecacheEffect]]("fx/smoke/emitter_missile.efx");

	// misc device requests
	devRequest("none"); // fake device for ammo crate parachute drop
	devRequest("kaboom"); // arty punishment effects
	devRequest("doarty"); // arty punishment damage
	devRequest("dotorch"); // torch punishment damage
}

devInitPost()
{
	// process device requests
	devRequestProcess();

	// start queue monitor event
	if(level.ex_devices.size) [[level.ex_registerLevelEvent]]("onFrame", ::devQueueProcess, true);
}

//------------------------------------------------------------------------------
// Device request handling
//------------------------------------------------------------------------------
devRequest(dev_id, react_callback, act_callback, alt_weapon, alt_id)
{
	dev_id = tolower(dev_id);
	dev_index = devRequestIndex(dev_id);
	if(dev_index != -1) return(-1);

	req_index = level.ex_devicerequests.size;
	level.ex_devicerequests[req_index] = spawnstruct();
	level.ex_devicerequests[req_index].dev_id = dev_id;
	level.ex_devicerequests[req_index].react_callback = react_callback;
	level.ex_devicerequests[req_index].act_callback = act_callback;
	level.ex_devicerequests[req_index].alt_weapon = alt_weapon;
	if(isDefined(alt_id)) level.ex_devicerequests[req_index].alt_id = tolower(alt_id);
		else level.ex_devicerequests[req_index].alt_id = undefined;
}

devRequestIndex(dev_id)
{
	if(!isDefined(dev_id) || dev_id == "") return(-1);
	for(i = 0; i < level.ex_devicerequests.size; i++)
		if(level.ex_devicerequests[i].dev_id == dev_id) return(i);
	return(-1);
}

devRequestProcess()
{
	for(i = 0; i < level.ex_devicerequests.size; i++)
	{
		dev_id = level.ex_devicerequests[i].dev_id;
		react_callback = level.ex_devicerequests[i].react_callback;
		act_callback = level.ex_devicerequests[i].act_callback;
		alt_weapon = level.ex_devicerequests[i].alt_weapon;
		alt_id = level.ex_devicerequests[i].alt_id;

		switch(dev_id)
		{
			// dummy device
			case "none":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				break;

			// effects-only devices
			case "kaboom":
				dev_index = devRegister(dev_id, "xmodel/prop_stuka_bomb", "mortar_incoming", 14, 1, 0, alt_id);
				if(dev_index != -1) devRegisterEffect(dev_index, "artillery_explosion", 0, 0, "fx/props/barrelexp.efx", 5, false, alt_id);
				break;
			case "skyfx_flak":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1) devRegisterEffect(dev_index, "flak_explosion", 0, 0, "fx/explosions/flak_shellexplode.efx", 0, false, alt_id);
				break;
			case "skyfx_flare1":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1) devRegisterEffect(dev_index, "flare_fire", 0, 0, "fx/misc/flare_hill400.efx", 0, false, alt_id);
				break;
			case "skyfx_flare2":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1) devRegisterEffect(dev_index, "flare_fire", 0, 0, "fx/flares/flare_1.efx", 0, false, alt_id);
				break;
			case "skyfx_flare3":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1) devRegisterEffect(dev_index, "flare_fire", 0, 0, "fx/flares/flare_firework.efx", 0, false, alt_id);
				break;
			case "skyfx_tracer":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1) devRegisterEffect(dev_index, "tracer_fire", 0, 0, "fx/misc/antiair_tracers.efx", 0, false, alt_id);
				break;
			case "smoke_grey":
				dev_index = devRegister(dev_id, "xmodel/weapon_us_smoke_grenade", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "smokegrenade_explode_default", 0, 0, "fx/props/american_smoke_grenade.efx", 0, false, alt_id);
					devRegisterTrip(dev_index, "hud_us_smokegrenade_C", 3, (0,0,0), alt_id);
				}
				break;
			case "smoke_blue":
				dev_index = devRegister(dev_id, "xmodel/weapon_us_smoke_grenade", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "smokegrenade_explode_default", 0, 0, "fx/extreme_smoke/blue_main.efx", 0, false, alt_id);
					devRegisterTrip(dev_index, "hud_us_smokegrenade_C", 3, (0,0,0), alt_id);
				}
				break;
			case "smoke_green":
				dev_index = devRegister(dev_id, "xmodel/weapon_us_smoke_grenade", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "smokegrenade_explode_default", 0, 0, "fx/extreme_smoke/green_main.efx", 0, false, alt_id);
					devRegisterTrip(dev_index, "hud_us_smokegrenade_C", 3, (0,0,0), alt_id);
				}
				break;
			case "smoke_orange":
				dev_index = devRegister(dev_id, "xmodel/weapon_us_smoke_grenade", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "smokegrenade_explode_default", 0, 0, "fx/extreme_smoke/orange_main.efx", 0, false, alt_id);
					devRegisterTrip(dev_index, "hud_us_smokegrenade_C", 3, (0,0,0), alt_id);
				}
				break;
			case "smoke_pink":
				dev_index = devRegister(dev_id, "xmodel/weapon_us_smoke_grenade", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "smokegrenade_explode_default", 0, 0, "fx/extreme_smoke/pink_main.efx", 0, false, alt_id);
					devRegisterTrip(dev_index, "hud_us_smokegrenade_C", 3, (0,0,0), alt_id);
				}
				break;
			case "smoke_red":
				dev_index = devRegister(dev_id, "xmodel/weapon_us_smoke_grenade", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "smokegrenade_explode_default", 0, 0, "fx/extreme_smoke/red_main.efx", 0, false, alt_id);
					devRegisterTrip(dev_index, "hud_us_smokegrenade_C", 3, (0,0,0), alt_id);
				}
				break;
			case "smoke_yellow":
				dev_index = devRegister(dev_id, "xmodel/weapon_us_smoke_grenade", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "smokegrenade_explode_default", 0, 0, "fx/extreme_smoke/yellow_main.efx", 0, false, alt_id);
					devRegisterTrip(dev_index, "hud_us_smokegrenade_C", 3, (0,0,0), alt_id);
				}
				break;

			// player-damage devices
			case "minefield_reg":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "explo_mine", 0, 0, "fx/explosions/grenadeExp_dirt.efx", 0, false, alt_id);
					devRegisterAct(dev_index, 0, 300, level.ex_minefield_min, level.ex_minefield_max, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_EXPLOSIVE", "minefield_mp", alt_weapon, alt_id);
				}
				break;
			case "minefield_gas":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "smokegrenade_explode_default", 0, 0, "fx/smoke/orange_smoke_20sec.efx", 0, false, alt_id);
					devRegisterAct(dev_index, 0, 300, level.ex_gasmine_min, level.ex_gasmine_max, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_EXPLOSIVE", "minefield_mp", alt_weapon, alt_id);
				}
				break;
			case "minefield_fire":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "Nebelwerfer_fire", 0, 0, "fx/extreme_napalm/napalm.efx", 0, false, alt_id);
					devRegisterAct(dev_index, 0, 300, level.ex_napalmmine_min, level.ex_napalmmine_max, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_EXPLOSIVE", "minefield_mp", alt_weapon, alt_id);
				}
				break;
			case "doarty":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1) devRegisterWeapon(dev_index, "MOD_EXPLOSIVE", "planebomb_mp", alt_weapon, alt_id);
				break;
			case "dotorch":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1) devRegisterWeapon(dev_index, "MOD_PROJECTILE", "planebomb_mp", alt_weapon, alt_id);
				break;
			case "quad_gun":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1) devRegisterWeapon(dev_index, "MOD_CRUSH", "dummy2_mp", alt_weapon, alt_id);
				break;
			case "sentry_gun":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1) devRegisterWeapon(dev_index, "MOD_PROJECTILE", "dummy1_mp", alt_weapon, alt_id);
				break;
			case "heli_gun":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1) devRegisterWeapon(dev_index, "MOD_PROJECTILE", "dummy2_mp", alt_weapon, alt_id);
				break;
			case "ugv_gun":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1) devRegisterWeapon(dev_index, "MOD_PROJECTILE", "dummy3_mp", alt_weapon, alt_id);
				break;

			// acting devices
			case "gunship_25mm":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterAct(dev_index, 1, 32, 100, 100, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_PROJECTILE_SPLASH", "gunship_25mm_mp", alt_weapon, alt_id);
				}
				break;
			case "gunship_40mm":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterAct(dev_index, 1, 256, 100, 250, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_PROJECTILE_SPLASH", "gunship_40mm_mp", alt_weapon, alt_id);
				}
				break;
			case "gunship_105mm":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterAct(dev_index, 1, 512, 100, 500, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_PROJECTILE_SPLASH", "gunship_105mm_mp", alt_weapon, alt_id);
				}
				break;
			case "frag_american":
				dev_index = devRegister(dev_id, "xmodel/weapon_mk2fraggrenade", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "grenade_explode_default", 0, 0, "fx/explosions/grenadeExp_blacktop.efx", 2, false, alt_id);
					devRegisterAct(dev_index, 3, 256, 100, 200, act_callback, alt_id);
					devRegisterTrip(dev_index, "gfx/icons/hud@us_grenade_C.tga", 3, (0,0,0), alt_id);
					devRegisterWeapon(dev_index, "MOD_GRENADE_SPLASH", "frag_grenade_american_mp", alt_weapon, alt_id);
				}
				break;
			case "frag_british":
				dev_index = devRegister(dev_id, "xmodel/weapon_mk1grenade", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "grenade_explode_default", 0, 0, "fx/explosions/grenadeExp_blacktop.efx", 2, false, alt_id);
					devRegisterAct(dev_index, 3, 256, 100, 200, act_callback, alt_id);
					devRegisterTrip(dev_index, "gfx/icons/hud@british_grenade_C.tga", 3, (0,0,0), alt_id);
					devRegisterWeapon(dev_index, "MOD_GRENADE_SPLASH", "frag_grenade_british_mp", alt_weapon, alt_id);
				}
				break;
			case "frag_german":
				dev_index = devRegister(dev_id, "xmodel/weapon_nebelhandgrenate", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "grenade_explode_default", 0, 0, "fx/explosions/grenadeExp_blacktop.efx", 2, false, alt_id);
					devRegisterAct(dev_index, 3, 256, 100, 200, act_callback, alt_id);
					devRegisterTrip(dev_index, "gfx/icons/hud@steilhandgrenate_C.tga", 3, (0,0,0), alt_id);
					devRegisterWeapon(dev_index, "MOD_GRENADE_SPLASH", "frag_grenade_german_mp", alt_weapon, alt_id);
				}
				break;
			case "frag_russian":
				dev_index = devRegister(dev_id, "xmodel/weapon_russian_handgrenade", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "grenade_explode_default", 0, 0, "fx/explosions/grenadeExp_blacktop.efx", 2, false, alt_id);
					devRegisterAct(dev_index, 3, 256, 100, 200, act_callback, alt_id);
					devRegisterTrip(dev_index, "gfx/icons/hud@russian_grenade_C.tga", 3, (0,0,0), alt_id);
					devRegisterWeapon(dev_index, "MOD_GRENADE_SPLASH", "frag_grenade_russian_mp", alt_weapon, alt_id);
				}
				break;
			case "firenade":
				dev_index = devRegister(dev_id, "xmodel/weapon_incendiary_grenade", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "grenade_explode_default", 0, 0, "fx/impacts/molotov_blast.efx", 0, false, alt_id);
					devRegisterAct(dev_index, 2, 256, 100, 200, act_callback, alt_id);
					devRegisterTrip(dev_index, "gfx/icons/hud@incenhandgrenade_c.tga", 1, (0,0,0), alt_id);
					devRegisterWeapon(dev_index, "MOD_GRENADE_SPLASH", "fire_mp", alt_weapon, alt_id);
				}
				break;
			case "gasnade":
				dev_index = devRegister(dev_id, "xmodel/weapon_mustardgas_grenade", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "smokegrenade_explode_default", 0, 0, "fx/impacts/mustard_blast.efx", 0, false, alt_id);
					devRegisterAct(dev_index, 2, 256, 100, 200, act_callback, alt_id);
					devRegisterTrip(dev_index, "gas_grenade", 1, (0,0,0), alt_id);
					devRegisterWeapon(dev_index, "MOD_GRENADE_SPLASH", "gas_mp", alt_weapon, alt_id);
				}
				break;
			case "satchel":
				dev_index = devRegister(dev_id, "xmodel/projectile_satchel", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "grenade_explode_default", 0, 0, "fx/explosions/barn_explosion.efx", 3, false, alt_id);
					devRegisterAct(dev_index, 3, 448, 100, 250, act_callback, alt_id);
					devRegisterTrip(dev_index, "gfx/icons/hud@satchel_charge1.tga", 0, (0,0,90), alt_id);
					devRegisterWeapon(dev_index, "MOD_GRENADE_SPLASH", "satchel_mp", alt_weapon, alt_id);
				}
				break;
			case "supernade_american":
				dev_index = devRegister(dev_id, "xmodel/supernade_american", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "mortar_explosion", 18, 1, "fx/explosions/spitfire_bomb_dirt.efx", 5, false, alt_id);
					devRegisterAct(dev_index, 3, 650, 100, 200, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_GRENADE_SPLASH", "supernade_american_mp", alt_weapon, alt_id);
				}
				break;
			case "supernade_british":
				dev_index = devRegister(dev_id, "xmodel/supernade_british", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "mortar_explosion", 18, 1, "fx/explosions/spitfire_bomb_dirt.efx", 5, false, alt_id);
					devRegisterAct(dev_index, 3, 650, 100, 200, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_GRENADE_SPLASH", "supernade_british_mp", alt_weapon, alt_id);
				}
				break;
			case "supernade_german":
				dev_index = devRegister(dev_id, "xmodel/supernade_german", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "mortar_explosion", 18, 1, "fx/explosions/spitfire_bomb_dirt.efx", 5, false, alt_id);
					devRegisterAct(dev_index, 3, 650, 100, 200, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_GRENADE_SPLASH", "supernade_german_mp", alt_weapon, alt_id);
				}
				break;
			case "supernade_russian":
				dev_index = devRegister(dev_id, "xmodel/supernade_russian", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "mortar_explosion", 18, 1, "fx/explosions/spitfire_bomb_dirt.efx", 5, false, alt_id);
					devRegisterAct(dev_index, 3, 650, 100, 200, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_GRENADE_SPLASH", "supernade_russian_mp", alt_weapon, alt_id);
				}
				break;
			case "gl_grenade": // must override weapon "none" in devInfo
				dev_index = devRegister(dev_id, "xmodel/projectile_mk2fraggrenade", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "mortar_explosion", 18, 1, "fx/props/barrelexp.efx", 4, false, alt_id);
					devRegisterAct(dev_index, 3, 256, 100, 500, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_PROJECTILE", "none", alt_weapon, alt_id);
				}
				break;
			case "mortar_amb":
				dev_index = devRegister(dev_id, "xmodel/prop_stuka_bomb", "mortar_incoming", 14, 1, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "mortar_explosion", 18, 1, "fx/explosions/mortarExp_dirt.efx", 5, true, alt_id);
					devRegisterAct(dev_index, 1, 300, 100, 500, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_EXPLOSIVE", "mortar_mp", alt_weapon, alt_id);
				}
				break;
			case "mortar_wmd":
				dev_index = devRegister(dev_id, "xmodel/prop_stuka_bomb", "mortar_incoming", 14, 1, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "mortar_explosion", 18, 1, "fx/explosions/mortarExp_dirt.efx", 5, true, alt_id);
					devRegisterAct(dev_index, 1, 300, 100, 500, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_GRENADE", "mortar_mp", alt_weapon, alt_id);
				}
				break;
			case "artillery_amb":
				dev_index = devRegister(dev_id, "xmodel/prop_stuka_bomb", "mortar_incoming", 14, 1, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "artillery_explosion", 0, 0, "fx/props/barrelexp.efx", 5, false, alt_id);
					devRegisterAct(dev_index, 1, 400, 100, 500, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_EXPLOSIVE", "artillery_mp", alt_weapon, alt_id);
				}
				break;
			case "artillery_wmd":
				dev_index = devRegister(dev_id, "xmodel/prop_stuka_bomb", "mortar_incoming", 14, 1, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "artillery_explosion", 0, 0, "fx/props/barrelexp.efx", 5, false, alt_id);
					devRegisterAct(dev_index, 1, 400, 100, 500, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_GRENADE", "artillery_mp", alt_weapon, alt_id);
				}
				break;
			case "airstrike_amb":
				dev_index = devRegister(dev_id, "xmodel/prop_stuka_bomb", "mortar_incoming", 14, 1, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "mortar_explosion", 18, 1, "fx/explosions/spitfire_bomb_dirt.efx", 5, false, alt_id);
					devRegisterAct(dev_index, 1, 500, 100, 500, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_EXPLOSIVE", "planebomb_mp", alt_weapon, alt_id);
				}
				break;
			case "airstrike_wmd":
				dev_index = devRegister(dev_id, "xmodel/prop_stuka_bomb", "mortar_incoming", 14, 1, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "mortar_explosion", 18, 1, "fx/explosions/spitfire_bomb_dirt.efx", 5, false, alt_id);
					devRegisterAct(dev_index, 1, 500, 100, 500, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_GRENADE", "planebomb_mp", alt_weapon, alt_id);
				}
				break;
			case "napalm":
				dev_index = devRegister(dev_id, "xmodel/prop_stuka_bomb", "mortar_incoming", 14, 1, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "mortar_explosion", 18, 1, "fx/explosions/spitfire_bomb_dirt.efx", 5, false, alt_id);
					devRegisterEffectSpecial(dev_index, "fx/extreme_napalm/napalm.efx", 0.25, "fx/fire/ground_fire_med.efx", alt_id);
					devRegisterAct(dev_index, 1, 500, 100, 500, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_PROJECTILE", "planebomb_mp", alt_weapon, alt_id);
				}
				break;
			case "heli_tube":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "grenade_explode_default", 0, 0, "generic", 3, true, alt_id);
					devRegisterAct(dev_index, 1, 250, 100, 250, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_GRENADE", "dummy2_mp", alt_weapon, alt_id);
				}
				break;
			case "ugv_missile":
				dev_index = devRegister(dev_id, "xmodel/vehicle_ugv_rocket", "weap_panzerfaust_fire", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "mortar_explosion", 18, 1, "fx/props/barrelexp.efx", 5, false, alt_id);
					devRegisterAct(dev_index, 4, 300, 100, 250, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_GRENADE", "dummy3_mp", alt_weapon, alt_id);
				}
				break;
			case "rpg_missile": // must override weapon "none" in devInfo
				dev_index = devRegister(dev_id, "xmodel/weapon_flak_missile", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "rocket_explode_default", 0, 0, "fx/explosions/grenadeExp_blacktop.efx", 3, false, alt_id);
					devRegisterAct(dev_index, 4, 300, 100, 250, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_PROJECTILE", "none", alt_weapon, alt_id);
				}
				break;
			case "gml_missile":
				dev_index = devRegister(dev_id, "xmodel/slamraam_missile", "weap_panzerfaust_fire", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "mortar_explosion", 18, 1, "fx/props/barrelexp.efx", 5, false, alt_id);
					devRegisterAct(dev_index, 4, 500, 100, 250, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_EXPLOSIVE", "dummy1_mp", alt_weapon, alt_id);
				}
				break;
			case "heli_missile":
				dev_index = devRegister(dev_id, "xmodel/slamraam_missile", "weap_panzerfaust_fire", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "mortar_explosion", 18, 1, "fx/props/barrelexp.efx", 5, false, alt_id);
					devRegisterAct(dev_index, 4, 500, 100, 250, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_EXPLOSIVE", "dummy2_mp", alt_weapon, alt_id);
				}
				break;
			case "flak_shell":
				dev_index = devRegister(dev_id, "xmodel/weapon_flak_missile", "Flak88_fire", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "mortar_explosion", 18, 1, "fx/props/barrelexp.efx", 5, false, alt_id);
					devRegisterAct(dev_index, 4, 300, 100, 250, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_EXPLOSIVE", "dummy3_mp", alt_weapon, alt_id);
				}
				break;
			case "gunship_nuke1":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterAct(dev_index, 8, 1000, 100, 500, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_PROJECTILE_SPLASH", "gunship_nuke_mp", alt_weapon, alt_id);
				}
				break;
			case "gunship_nuke2":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterAct(dev_index, 8, 2000, 100, 1000, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_PROJECTILE_SPLASH", "gunship_nuke_mp", alt_weapon, alt_id);
				}
				break;
			case "gunship_nuke3":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterAct(dev_index, 8, 5000, 100, 2000, act_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_PROJECTILE_SPLASH", "gunship_nuke_mp", alt_weapon, alt_id);
				}
				break;

			// reacting devices
			case "beartrap":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterReact(dev_index, 1, react_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_CRUSH", "dummy1_mp", alt_weapon, alt_id);
				}
				break;
			case "flak":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1) devRegisterReact(dev_index, 14, react_callback, alt_id);
				break;
			case "gml":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1) devRegisterReact(dev_index, 14, react_callback, alt_id);
				break;
			case "sentry":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1) devRegisterReact(dev_index, 10, react_callback, alt_id);
				break;
			case "ugv":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1) devRegisterReact(dev_index, 10, react_callback, alt_id);
				break;
			case "heli":
				dev_index = devRegister(dev_id, "xmodel/vehicle_apache", "", 0, 0, 0, alt_id);
				if(dev_index != -1) devRegisterReact(dev_index, 4, react_callback, alt_id);
				break;
			case "airplane":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1) devRegisterReact(dev_index, 4, react_callback, alt_id);
				break;
			case "gunship":
				dev_index = devRegister(dev_id, "xmodel/vehicle_condor", "", 0, 0, 0, alt_id);
				if(dev_index != -1) devRegisterReact(dev_index, 4, react_callback, alt_id);
				break;
			case "perkship":
				dev_index = devRegister(dev_id, "xmodel/vehicle_condor", "", 0, 0, 0, alt_id);
				if(dev_index != -1) devRegisterReact(dev_index, 4, react_callback, alt_id);
				break;

			// acting and reacting devices
			case "mine":
				dev_index = devRegister(dev_id, "xmodel/weapon_bbetty", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "explo_mine", 0, 0, "fx/explosions/mortarExp_dirt.efx", 5, false, alt_id);
					devRegisterAct(dev_index, 1, 300, 100, 250, act_callback, alt_id);
					devRegisterReact(dev_index, 1, react_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_EXPLOSIVE", "landmine_mp", alt_weapon, alt_id);
				}
				break;
			case "trip":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterAct(dev_index, 1, 300, 100, 250, act_callback, alt_id);
					devRegisterReact(dev_index, 1, react_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_EXPLOSIVE", "tripwire_mp", alt_weapon, alt_id);
				}
				break;
			case "monkey":
				dev_index = devRegister(dev_id, "", "", 0, 0, 0, alt_id);
				if(dev_index != -1)
				{
					devRegisterEffect(dev_index, "grenade_explode_default", 0, 0, "fx/explosions/spitfire_bomb_dirt.efx", 5, false, alt_id);
					devRegisterAct(dev_index, 1, 300, 100, 250, act_callback, alt_id);
					devRegisterReact(dev_index, 1, react_callback, alt_id);
					devRegisterWeapon(dev_index, "MOD_GRENADE", "dummy1_mp", alt_weapon, alt_id);
				}
				break;

			// unknown device requested
			default:
				logprint("DEV: Requested device \"" + dev_id + "\" is unknown\n");
				break;
		}
	}
}

//------------------------------------------------------------------------------
// Device registration
//------------------------------------------------------------------------------
devRegister(dev_id, model, sndin, sndin_max, sndin_base, sndin_pause, alt_id)
{
	dev_id = tolower(dev_id);
	dev_index = devIndex(dev_id);
	if(dev_index != -1) return(-1);

	// set to automatic if not provided
	if(!isDefined(model)) model = "auto";
	if(!isDefined(sndin)) sndin = "auto";
	if(!isDefined(sndin_max)) sndin_max = -1;
	if(!isDefined(sndin_base)) sndin_base = -1;
	if(!isDefined(sndin_pause)) sndin_pause = -1;

	// auto-fill from configuration files
	if(isDefined(alt_id))
	{
		if(model == "auto") model = [[level.ex_drm]]("ex_dev_" + alt_id + "_model", "", "", "", "string");
		if(sndin == "auto") sndin = [[level.ex_drm]]("ex_dev_" + alt_id + "_sndin", "", "", "", "string");
		if(sndin_max == -1) sndin_max = [[level.ex_drm]]("ex_dev_" + alt_id + "_sndin_max", 0, 0, 50, "int");
		if(sndin_base == -1) sndin_base = [[level.ex_drm]]("ex_dev_" + alt_id + "_sndin_base", 0, 0, 50, "int");
		if(sndin_pause == -1) sndin_pause = [[level.ex_drm]]("ex_dev_" + alt_id + "_sndin_pause", 0, 0, 60, "float");
	}
	else
	{
		if(model == "auto") model = [[level.ex_drm]]("ex_dev_" + dev_id + "_model", "", "", "", "string");
		if(sndin == "auto") sndin = [[level.ex_drm]]("ex_dev_" + dev_id + "_sndin", "", "", "", "string");
		if(sndin_max == -1) sndin_max = [[level.ex_drm]]("ex_dev_" + dev_id + "_sndin_max", 0, 0, 50, "int");
		if(sndin_base == -1) sndin_base = [[level.ex_drm]]("ex_dev_" + dev_id + "_sndin_base", 0, 0, 50, "int");
		if(sndin_pause == -1) sndin_pause = [[level.ex_drm]]("ex_dev_" + dev_id + "_sndin_pause", 0, 0, 60, "float");
	}

	// check properties
	if(model == "") model = undefined;
	if(sndin == "") sndin = undefined;

	// precache model
	if(isDefined(model)) [[level.ex_PrecacheModel]](model);

	// store in device array
	dev_index = level.ex_devices.size;
	level.ex_devices[dev_index] = spawnstruct();
	level.ex_devices[dev_index].dev_id = dev_id;
	level.ex_devices[dev_index].model = model;
	level.ex_devices[dev_index].sndin = sndin;
	level.ex_devices[dev_index].sndin_max = sndin_max;
	level.ex_devices[dev_index].sndin_base = sndin_base;
	level.ex_devices[dev_index].sndin_pause = sndin_pause;

	// reset other properties
	level.ex_devices[dev_index].sndex = undefined;
	level.ex_devices[dev_index].sndex_max = 0;
	level.ex_devices[dev_index].sndex_base = 0;
	level.ex_devices[dev_index].fx_id1 = -1;
	level.ex_devices[dev_index].quake = 0;
	level.ex_devices[dev_index].getsurface = 0;

	level.ex_devices[dev_index].fx_id2 = -1;
	level.ex_devices[dev_index].pause = 0;
	level.ex_devices[dev_index].fx_id3 = -1;

	level.ex_devices[dev_index].act = 0;
	level.ex_devices[dev_index].range = 0;
	level.ex_devices[dev_index].mindamage = 0;
	level.ex_devices[dev_index].maxdamage = 0;
	level.ex_devices[dev_index].act_callback = undefined;

	level.ex_devices[dev_index].react = 0;
	level.ex_devices[dev_index].react_callback = undefined;

	level.ex_devices[dev_index].mod = "MOD_UNKNOWN";
	level.ex_devices[dev_index].weapon = "none";

	if(level.ex_log_devices) logprint("DEV: Device \"" + dev_id + "\" registered (" + (dev_index+1) + ")\n");
	return(dev_index);
}

devRegisterEffect(dev_variant, sndex, sndex_max, sndex_base, effect1, quake, getsurface, alt_id)
{
	dev_index = devIndex(dev_variant);
	if(dev_index == -1) return(false);
	dev_id = level.ex_devices[dev_index].dev_id;

	// set to automatic if not provided
	if(!isDefined(sndex)) sndex = "auto";
	if(!isDefined(sndex_max)) sndex_max = -1;
	if(!isDefined(sndex_base)) sndex_base = -1;
	if(!isDefined(effect1)) effect1 = "auto";
	if(!isDefined(quake)) quake = -1;
	if(!isDefined(getsurface)) getsurface = -1;

	// auto-fill from configuration files
	if(isDefined(alt_id))
	{
		if(sndex == "auto") sndex = [[level.ex_drm]]("ex_dev_" + alt_id + "_sndex", "", "", "", "string");
		if(sndex_max == -1) sndex_max = [[level.ex_drm]]("ex_dev_" + alt_id + "_sndex_max", 0, 0, 50, "int");
		if(sndex_base == -1) sndex_base = [[level.ex_drm]]("ex_dev_" + alt_id + "_sndex_base", 0, 0, 50, "int");
		if(effect1 == "auto") effect1 = [[level.ex_drm]]("ex_dev_" + alt_id + "_effect1", "", "", "", "string");
		if(quake == -1) quake = [[level.ex_drm]]("ex_dev_" + alt_id + "_quake", 0, 0, 10, "int");
		if(getsurface == -1) getsurface = [[level.ex_drm]]("ex_dev_" + alt_id + "_getsurface", 0, 0, 1, "int");
	}
	else
	{
		if(sndex == "auto") sndex = [[level.ex_drm]]("ex_dev_" + dev_id + "_sndex", "", "", "", "string");
		if(sndex_max == -1) sndex_max = [[level.ex_drm]]("ex_dev_" + dev_id + "_sndex_max", 0, 0, 50, "int");
		if(sndex_base == -1) sndex_base = [[level.ex_drm]]("ex_dev_" + dev_id + "_sndex_base", 0, 0, 50, "int");
		if(effect1 == "auto") effect1 = [[level.ex_drm]]("ex_dev_" + dev_id + "_effect1", "", "", "", "string");
		if(quake == -1) quake = [[level.ex_drm]]("ex_dev_" + dev_id + "_quake", 0, 0, 10, "int");
		if(getsurface == -1) getsurface = [[level.ex_drm]]("ex_dev_" + dev_id + "_getsurface", 0, 0, 1, "int");
	}

	// check properties
	if(sndex == "") sndex = undefined;
	if(effect1 == "") effect1 = undefined;

	// precache effect
	fx_id1 = -1;
	if(isDefined(effect1))
	{
		if(effect1 != "generic") fx_id1 = [[level.ex_PrecacheEffect]](effect1);
			else fx_id1 = 0;
	}

	// store in device array
	level.ex_devices[dev_index].sndex = sndex;
	level.ex_devices[dev_index].sndex_base = sndex_base;
	level.ex_devices[dev_index].sndex_max = sndex_max;
	level.ex_devices[dev_index].fx_id1 = fx_id1;
	level.ex_devices[dev_index].quake = quake;
	level.ex_devices[dev_index].getsurface = getsurface;
}

devRegisterEffectSpecial(dev_variant, effect2, pause, effect3, alt_id)
{
	dev_index = devIndex(dev_variant);
	if(dev_index == -1) return(false);
	dev_id = level.ex_devices[dev_index].dev_id;

	// set to automatic if not provided
	if(!isDefined(effect2)) effect2 = "auto";
	if(!isDefined(pause)) pause = -1;
	if(!isDefined(effect3)) effect3 = "auto";

	// auto-fill from configuration files
	if(isDefined(alt_id))
	{
		if(effect2 == "auto") effect2 = [[level.ex_drm]]("ex_dev_" + alt_id + "_effect2", "", "", "", "string");
		if(pause == -1) pause = [[level.ex_drm]]("ex_dev_" + alt_id + "_pause", 0, 0, 60, "float");
		if(effect3 == "auto") effect3 = [[level.ex_drm]]("ex_dev_" + alt_id + "_effect3", "", "", "", "string");
	}
	else
	{
		if(effect2 == "auto") effect2 = [[level.ex_drm]]("ex_dev_" + dev_id + "_effect2", "", "", "", "string");
		if(pause == -1) pause = [[level.ex_drm]]("ex_dev_" + dev_id + "_pause", 0, 0, 60, "float");
		if(effect3 == "auto") effect3 = [[level.ex_drm]]("ex_dev_" + dev_id + "_effect3", "", "", "", "string");
	}

	// check properties
	if(effect2 == "") effect2 = undefined;
	if(effect3 == "") effect3 = undefined;

	// precache effects (-1 = off, 0 = generic, >0 = precached fx)
	fx_id2 = -1;
	if(isDefined(effect2))
	{
		if(effect2 != "generic") fx_id2 = [[level.ex_PrecacheEffect]](effect2);
			else fx_id2 = 0;
	}
	fx_id3 = -1;
	if(isDefined(effect3))
	{
		if(effect3 != "generic") fx_id3 = [[level.ex_PrecacheEffect]](effect3);
			else fx_id3 = 0;
	}

	// store in device array
	level.ex_devices[dev_index].fx_id2 = fx_id2;
	level.ex_devices[dev_index].pause = pause;
	level.ex_devices[dev_index].fx_id3 = fx_id3;
}

devRegisterTrip(dev_variant, hud, modz, moda, trip_callback, alt_id)
{
	dev_index = devIndex(dev_variant);
	if(dev_index == -1) return(false);
	dev_id = level.ex_devices[dev_index].dev_id;

	// set to automatic if not provided
	if(!isDefined(hud)) hud = "auto";
	if(!isDefined(modz)) modz = 0;
	if(!isDefined(moda)) moda = (0,0,0);

	// auto-fill from configuration files
	if(isDefined(alt_id))
	{
		if(hud == "auto") hud = [[level.ex_drm]]("ex_dev_" + alt_id + "_hud", "", "", "", "string");
	}
	else if(hud == "auto") hud = [[level.ex_drm]]("ex_dev_" + dev_id + "_hud", "", "", "", "string");

	// check properties
	if(hud == "") hud = "black";

	// precache shader
	[[level.ex_PrecacheShader]](hud);

	// store in device array
	level.ex_devices[dev_index].hud = hud;
	level.ex_devices[dev_index].modz = modz;
	level.ex_devices[dev_index].moda = moda;
}

devRegisterAct(dev_variant, act, act_range, act_mindamage, act_maxdamage, act_callback, alt_id)
{
	dev_index = devIndex(dev_variant);
	if(dev_index == -1) return(false);
	dev_id = level.ex_devices[dev_index].dev_id;

	// set to automatic if not provided
	if(!isDefined(act)) act = -1;
	if(!isDefined(act_range)) act_range = -1;
	if(!isDefined(act_mindamage)) act_mindamage = -1;
	if(!isDefined(act_maxdamage)) act_maxdamage = -1;

	// auto-fill from configuration files
	if(isDefined(alt_id))
	{
		if(act == -1) act = [[level.ex_drm]]("ex_dev_" + alt_id + "_act", 0, 0, 63, "int");
		if(act_range == -1) act_range = [[level.ex_drm]]("ex_dev_" + alt_id + "_range", 50, 0, 10000, "int");
		if(act_mindamage == -1) act_mindamage = [[level.ex_drm]]("ex_dev_" + alt_id + "_mindamage", 10, 0, 10000, "int");
		if(act_maxdamage == -1) act_maxdamage = [[level.ex_drm]]("ex_dev_" + alt_id + "_maxdamage", 10, 0, 10000, "int");
	}
	else
	{
		if(act == -1) act = [[level.ex_drm]]("ex_dev_" + dev_id + "_act", 0, 0, 63, "int");
		if(act_range == -1) act_range = [[level.ex_drm]]("ex_dev_" + dev_id + "_range", 50, 0, 10000, "int");
		if(act_mindamage == -1) act_mindamage = [[level.ex_drm]]("ex_dev_" + dev_id + "_mindamage", 10, 0, 10000, "int");
		if(act_maxdamage == -1) act_maxdamage = [[level.ex_drm]]("ex_dev_" + dev_id + "_maxdamage", 10, 0, 10000, "int");
	}

	// allowing this because minefield devices have act set to 0 (but need other properties)
	//if(!act) return(-1);

	// check properties
	if(act_range && act_range < 50) act_range = 50;
	if(act_mindamage && act_mindamage < 10) act_mindamage = 10;
	if(act_maxdamage && act_maxdamage < act_mindamage) act_maxdamage = act_mindamage;

	// store in device array
	level.ex_devices[dev_index].act = act;
	level.ex_devices[dev_index].range = act_range;
	level.ex_devices[dev_index].mindamage = act_mindamage;
	level.ex_devices[dev_index].maxdamage = act_maxdamage;
	level.ex_devices[dev_index].act_callback = act_callback;
}

devRegisterReact(dev_variant, react, react_callback, alt_id)
{
	dev_index = devIndex(dev_variant);
	if(dev_index == -1) return(false);
	dev_id = level.ex_devices[dev_index].dev_id;

	// set to automatic if not provided
	if(!isDefined(react)) react = -1;

	// auto-fill from configuration files
	if(isDefined(alt_id))
	{
		if(react == -1) react = [[level.ex_drm]]("ex_dev_" + alt_id + "_react", 0, 0, 63, "int");
	}
	else if(react == -1) react = [[level.ex_drm]]("ex_dev_" + dev_id + "_react", 0, 0, 63, "int");

	// check properties
	if(!react) return(false);

	// store in device array
	level.ex_devices[dev_index].react = react;
	level.ex_devices[dev_index].react_callback = react_callback;
}

devRegisterWeapon(dev_variant, mod, weapon, alt_weapon, alt_id)
{
	dev_index = devIndex(dev_variant);
	if(dev_index == -1) return(false);
	dev_id = level.ex_devices[dev_index].dev_id;

	// set to automatic if not provided
	if(!isDefined(mod)) mod = "auto";
	if(!isDefined(weapon)) weapon = "auto";

	// auto-fill from configuration files
	if(isDefined(alt_id))
	{
		if(mod == "auto") mod = [[level.ex_drm]]("ex_dev_" + alt_id + "_mod", mod, "", "", "string");
		if(weapon == "auto") weapon = [[level.ex_drm]]("ex_dev_" + alt_id + "_weapon", weapon, "", "", "string");
	}
	else
	{
		if(mod == "auto") mod = [[level.ex_drm]]("ex_dev_" + dev_id + "_mod", mod, "", "", "string");
		if(weapon == "auto") weapon = [[level.ex_drm]]("ex_dev_" + dev_id + "_weapon", weapon, "", "", "string");
	}

	// override weapon if alternative is provided
	if(isDefined(alt_weapon)) weapon = alt_weapon;

	// check properties
	if(mod == "") return(false);
	if(weapon == "") return(false);

	// precache item
	if(weapon != "none") [[level.ex_PrecacheItem]](weapon);

	// store in device array
	level.ex_devices[dev_index].mod = mod;
	level.ex_devices[dev_index].weapon = weapon;
}

//------------------------------------------------------------------------------
// Device usage
//------------------------------------------------------------------------------
devMissile(dev_variant, device_info, target_info, target_callback)
{
	dev_index = devIndex(dev_variant);
	if(dev_index == -1) return;

	// gotta have these
	if(!isDefined(device_info) || !isDefined(target_info)) return;

	if(level.ex_log_devices) logprint("DEV: Device \"" + level.ex_devices[dev_index].dev_id + "\" incoming\n");

	// spawn device model
	if(isDefined(device_info.spawn) && isDefined(device_info.origin) && isDefined(device_info.angles))
	{
		device = spawn("script_model", device_info.origin);
		if(isDefined(level.ex_devices[dev_index].model)) device setModel(level.ex_devices[dev_index].model);
			else device setModel("xmodel/tag_origin");
		device.angles = device_info.angles;
	}
	else device = self;

	// play incoming sound if registered
	if(isDefined(level.ex_devices[dev_index].sndin))
	{
		if(level.ex_devices[dev_index].sndin_max)
		{
			snd_id = level.ex_devices[dev_index].sndin_base + randomInt(level.ex_devices[dev_index].sndin_max);
			device playSound(level.ex_devices[dev_index].sndin + snd_id);
		}
		else device playSound(level.ex_devices[dev_index].sndin);
		if(level.ex_devices[dev_index].sndin_pause) wait( [[level.ex_fpstime]](level.ex_devices[dev_index].sndin_pause) );
	}

	// make it fly
	device thread devMissileFire(level.ex_devices[dev_index].dev_id, device_info, target_info, target_callback);
}

devInbound(dev_variant, device_info)
{
	dev_index = devIndex(dev_variant);
	if(dev_index == -1) return;

	// gotta have this
	if(!isDefined(device_info)) return;
	if(!isDefined(device_info.speed)) device_info.speed = 50;

	// DEBUG: colored line from origin to impact
	//level thread dropLine(device_info.origin, device_info.impactpos, (0,0,1), 300);
	if(level.ex_log_devices) logprint("DEV: Device \"" + level.ex_devices[dev_index].dev_id + "\" incoming\n");

	// spawn device model
	device = spawn("script_model", device_info.origin);
	if(isDefined(level.ex_devices[dev_index].model)) device setModel(level.ex_devices[dev_index].model);
		else device setModel("xmodel/tag_origin");
	device.angles = vectorToAngles(vectorNormalize(device_info.impactpos - device_info.origin));

	// play incoming sound if registered
	if(isDefined(level.ex_devices[dev_index].sndin))
	{
		if(level.ex_devices[dev_index].sndin_max)
		{
			snd_id = level.ex_devices[dev_index].sndin_base + randomInt(level.ex_devices[dev_index].sndin_max);
			device playSound(level.ex_devices[dev_index].sndin + snd_id);
		}
		else device playSound(level.ex_devices[dev_index].sndin);
		if(level.ex_devices[dev_index].sndin_pause) wait( [[level.ex_fpstime]](level.ex_devices[dev_index].sndin_pause) );
	}

	// move it
	device moveto(device_info.impactpos, calcTime(device_info.origin, device_info.impactpos, device_info.speed));
	device waittill("movedone");
	device hide();

	// update device info
	device_info.origin = self.origin;

	// handle explosion
	device devExplode(dev_index, device_info);

	wait(1);
	device delete();
}

devTrip(dev_variant, device_info, parentdev_variant)
{
	dev_index = devIndex(dev_variant);
	if(dev_index == -1) return;

	// gotta have this
	if(!isDefined(device_info)) return;

	if(level.ex_log_devices) logprint("DEV: Device \"" + level.ex_devices[dev_index].dev_id + "\" triggered\n");

	// handle sound and visual effects
	self devEffects(dev_index);

	// inject origin if necessary
	if(!isDefined(device_info.origin)) device_info.origin = self.origin;

	// only handle callback for trip components (no devDamage or devQueue)
	if(isDefined(level.ex_devices[dev_index].act_callback))
	{
		parentdev_index = -1;
		if(isDefined(parentdev_variant)) parentdev_index = devIndex(parentdev_variant);
		if(parentdev_index == -1) level thread [[level.ex_devices[dev_index].act_callback]](dev_index, device_info);
			else level thread [[level.ex_devices[dev_index].act_callback]](dev_index, device_info, parentdev_index);
	}
}

devExplode(dev_variant, device_info)
{
	dev_index = devIndex(dev_variant);
	if(dev_index == -1) return;

	// gotta have this
	if(!isDefined(device_info)) return;

	if(level.ex_log_devices) logprint("DEV: Device \"" + level.ex_devices[dev_index].dev_id + "\" exploding\n");

	// handle sound and visual effects
	self devEffects(dev_index);

	// handle damage
	if(device_info.dodamage)
	{
		// if owner does not exist, or is "level" (ambient), make "self" (device) the owner
		if(!isDefined(device_info.owner) || device_info.owner == level) device_info.owner = self;

		// inject origin if necessary
		if(!isDefined(device_info.origin)) device_info.origin = self.origin;

		// use callback if defined, otherwise call devDamage
		if(isDefined(level.ex_devices[dev_index].act_callback))
			level thread [[level.ex_devices[dev_index].act_callback]](dev_index, device_info);
		else self thread devDamage(dev_index, device_info, "none");

		// queue for devices reacting to close proximity explosions
		if(level.ex_cpx && level.ex_devices[dev_index].act) level thread devQueue(dev_index, device_info);
	}
}

devEffects(dev_variant)
{
	dev_index = devIndex(dev_variant);
	if(dev_index == -1) return;
	//dev_id = level.ex_devices[dev_index].dev_id;

	// play explosion sound if registered
	if(isDefined(level.ex_devices[dev_index].sndex))
	{
		if(level.ex_devices[dev_index].sndex_max)
		{
			snd_id = level.ex_devices[dev_index].sndex_base + randomInt(level.ex_devices[dev_index].sndex_max);
			self playSound(level.ex_devices[dev_index].sndex + snd_id);
		}
		else self playSound(level.ex_devices[dev_index].sndex);
	}

	// play explosion effect if registered
	if(level.ex_devices[dev_index].fx_id1 != -1)
	{
		if(level.ex_devices[dev_index].getsurface) surface = getImpactSurface(self.origin);
			else surface = undefined;

		if(level.ex_wintermap) surfacefx = "snow";
			else surfacefx = "dirt";

		if(isDefined(surface))
		{
			switch(surface)
			{
				case "beach":
				case "sand": surfacefx = "beach"; break;
				case "asphalt":
				case "metal":
				case "rock":
				case "gravel":
				case "plaster":
				case "default": surfacefx = "concrete"; break;
				case "mud":
				case "dirt":
				case "grass": surfacefx = "dirt"; break;
				case "snow":
				case "ice": surfacefx = "snow"; break;
				case "wood":
				case "bark": surfacefx = "wood"; break;
				case "water": surfacefx = "water"; break;
			}
		}

		if(level.ex_devices[dev_index].fx_id1 == 0) playFx(level.ex_effect["explosion_" + surfacefx], self.origin);
			else playFx(level.ex_devices[dev_index].fx_id1, self.origin);
		//if(level.ex_wintermap ) thread delayedEffect("explosion_snow", 1.5, self.origin);
	}

	// play special explosion effects if registered
	if(level.ex_devices[dev_index].fx_id2 > 0)
	{
		playFx(level.ex_devices[dev_index].fx_id2, self.origin);
		if(level.ex_devices[dev_index].pause) wait( [[level.ex_fpstime]](level.ex_devices[dev_index].pause) );
		if(level.ex_devices[dev_index].fx_id3 > 0) playFx(level.ex_devices[dev_index].fx_id3, self.origin);
	}

	// play earthquake effect if registered (strength, duration, origin, range)
	if(level.ex_devices[dev_index].quake)
	{
		switch(level.ex_devices[dev_index].quake)
		{
			case  1: earthquake(0.1, 1, self.origin,  250); break;
			case  2: earthquake(0.2, 1, self.origin,  250); break;
			case  3: earthquake(0.3, 1, self.origin,  500); break;
			case  4: earthquake(0.4, 1, self.origin,  500); break;
			case  5: earthquake(0.5, 1, self.origin, 1000); break;
			case  6: earthquake(0.6, 1, self.origin, 1000); break;
			case  7: earthquake(0.7, 2, self.origin, 1500); break;
			case  8: earthquake(0.8, 2, self.origin, 1500); break;
			case  9: earthquake(0.9, 3, self.origin, 2500); break;
			case 10: earthquake(1.0, 3, self.origin, 5000); break;
			default: earthquake(0.2, 1, self.origin,  250); break;
		}
	}
}

devDamage(dev_variant, device_info, special)
{
	level endon("ex_gameover");

	dev_index = devIndex(dev_variant);
	if(dev_index == -1) return;
	//dev_id = level.ex_devices[dev_index].dev_id;

	// gotta have this
	if(!isDefined(device_info)) return;

	attacker = device_info.owner;
	range = level.ex_devices[dev_index].range;
	if(isDefined(device_info.damage)) mindamage = device_info.damage;
		else mindamage = level.ex_devices[dev_index].mindamage;
	maxdamage = level.ex_devices[dev_index].maxdamage;
	if(maxdamage < mindamage) maxdamage = mindamage;

	// return if no damage set
	if(!device_info.dodamage || !mindamage) return;

	if(!isDefined(special)) special = "none";

	// loop through players to see who is close
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player) || !isAlive(player) || player.sessionstate != "playing") continue;

		// bubble protection
		if(isDefined(player.ex_bubble_protected)) continue;

		// radius protection for player in gunship
		if((level.ex_gunship && isPlayer(level.gunship.owner) && level.gunship.owner == player) ||
			 (level.ex_gunship_special && isPlayer(level.gunship_special.owner) && level.gunship_special.owner == player)) continue;

		// damage fall-off based on range
		damage = maxdamage;
		if(range)
		{
			dist = distance(self.origin, player.origin);
			if(dist >= range) continue;
			if(dist <= (range / 2)) damage = maxdamage; // max damage if within half the range
				else if(dist <= (range - 50)) damage = int(maxdamage * ((range - dist) / range)); // damage fall-off
					else damage = mindamage; // min damage if in outer 50 units of radius
		}

		if(player != self)
		{
			offset = 0;
			switch(player.ex_stance)
			{
				case 0: offset = (0,0,55); break;
				case 1: offset = (0,0,35); break;
				case 2: offset = (0,0,5); break;
			}

			traceorigin = player.origin + offset;
			hitdir = vectorNormalize(traceorigin - self.origin);

			if(special != "nuke")
			{
				if(isPlayer(self)) trace = bullettrace(self.origin, traceorigin, true, self);
					else trace = bullettrace(self.origin, traceorigin, true, attacker);

				if(trace["fraction"] != 1 && isDefined(trace["entity"]))
				{
					if(isPlayer(trace["entity"]) && trace["entity"] != player && trace["entity"] != attacker)
						damage = int(damage * .5); // damage blocked by other player, remove 50%
				}
				else
				{
					trace = bulletTrace(self.origin, traceorigin, false, undefined);
					if(trace["fraction"] != 1 && trace["surfacetype"] != "default")
						damage = int(damage * .2); // damage blocked by other entities, remove 80%
				}
			}
		}

		if(isPlayer(attacker) && attacker != player && special == "kamikaze" && damage >= player.health)
		{
			if(!isDefined(attacker.kamikaze_victims)) attacker.kamikaze_victims = 0;
			attacker.kamikaze_victims++;
		}

		// make sure we have mod and weapon set
		if(isDefined(device_info.mod)) mod = device_info.mod;
			else mod = level.ex_devices[dev_index].mod;
		if(isDefined(device_info.weapon)) weapon = device_info.weapon;
			else weapon = level.ex_devices[dev_index].weapon;
		if(isDefined(device_info.hitpnt)) hitpnt = device_info.hitpnt;
			else hitpnt = undefined;
		if(isDefined(device_info.hitdir)) hitdir = device_info.hitdir;
			else hitdir = (0,0,1);
		if(isDefined(device_info.hitloc)) hitloc = device_info.hitloc;
			else hitloc = "none";

		player thread [[level.callbackPlayerDamage]](self, attacker, damage, 1, mod, weapon, hitpnt, hitdir, hitloc, 0);
	}
}

devPlayer(dev_variant, device_info)
{
	level endon("ex_gameover");

	dev_index = devIndex(dev_variant);
	if(dev_index == -1) return;

	// must be called on a player entity
	if(!isPlayer(self)) return;

	// gotta have this
	if(!isDefined(device_info)) return;

	// make sure we have damage set
	if(isDefined(device_info.damage)) damage = device_info.damage;
		else damage = level.ex_devices[dev_index].mindamage;
	if(!device_info.dodamage || !damage) return;

	if(level.ex_log_devices) logprint("DEV: Device \"" + level.ex_devices[dev_index].dev_id + "\" causing damage to " + self.name + "\n");

	// make sure we have all parameters set
	if(isDefined(device_info.owner)) attacker = device_info.owner;
		else attacker = self;
	if(isDefined(device_info.mod)) mod = device_info.mod;
		else mod = level.ex_devices[dev_index].mod;
	if(isDefined(device_info.weapon)) weapon = device_info.weapon;
		else weapon = level.ex_devices[dev_index].weapon;
	if(isDefined(device_info.hitpnt)) hitpnt = device_info.hitpnt;
		else hitpnt = undefined;
	if(isDefined(device_info.hitdir)) hitdir = device_info.hitdir;
		else hitdir = (0,0,1);
	if(isDefined(device_info.hitloc)) hitloc = device_info.hitloc;
		else hitloc = "none";

	self thread [[level.callbackPlayerDamage]](attacker, attacker, damage, 1, mod, weapon, hitpnt, hitdir, hitloc, 0);
}

devInfo(owner, team)
{
	device_info = spawnstruct();
	device_info.owner = owner;
	if(isDefined(team)) device_info.team = team;
		else device_info.team = "neutral";
	device_info.dodamage = false;

	return(device_info);
}

devEffectsOnTag(sound, effect, tag)
{
	// sound fx
	if(isDefined(sound)) self playSound(sound);

	// visual fx on tag
	if(isDefined(effect) && isDefined(tag)) playFxOnTag(level.ex_effect[effect], self, tag);
}

//------------------------------------------------------------------------------
// Missile handling
//------------------------------------------------------------------------------
devMissileFire(dev_id, device_info, target_info, target_callback)
{
	if(isDefined(device_info.speed)) speed = device_info.speed;
		else speed = 40;
	if(target_info.target_type == 2 || target_info.target_type == 4) speed = 50;
	self.finishedrotating = true;

	dest = self.origin + [[level.ex_vectorscale]](anglesToForward(self.angles), 100000);
	time = calcTime(self.origin, dest, speed);
	self moveto(dest, time, 0, 0);
	playfxontag(level.ex_effect["missile_trail"], self, "tag_flash");
	wait( [[level.ex_fpstime]](0.5) );

	olddest = (0,0,0);
	totaltime = 0;
	lifespan = 30 * level.ex_fps;
	trace = bulletTrace(self.origin, dest, true, self);
	ftime = calcTime(self.origin, trace["position"], speed);
	for(t = 0; t < ftime * level.ex_fps; t++)
	{
		wait( level.ex_fps_frame );

		newtrace = bulletTrace(self.origin, dest, true, self);
		if(distance(newtrace["position"], trace["position"]) > 1)
		{
			trace = newtrace;
			ftime = calcTime(self.origin, trace["position"], speed);
			t = 0;
		}

		// repeat trail fx
		if(totaltime % level.ex_fps == 0) playfxontag(level.ex_effect["missile_trail"], self, "tag_flash");

		// handle flying time
		totaltime++;
		if(lifespan && totaltime > lifespan) break;

		// check if owner still exists
		if(!isPlayer(device_info.owner))
		{
			dest = self.origin + [[level.ex_vectorscale]](anglestoforward(self.angles), 100000);
			time = calcTime(self.origin, dest, speed);
			if(time <= 0) break;
			self moveto(dest, time, 0, 0);
			continue;
		}

		// check if target still exists
		if(!isDefined(target_info.target) || (isPlayer(target_info.target) && target_info.target.sessionstate != "playing"))
		{
			if(isDefined(target_callback)) target_info = [[target_callback]](device_info.owner, device_info.team);
			if(!isDefined(target_info.target) || (isPlayer(target_info.target) && target_info.target.sessionstate != "playing"))
			{
				dest = self.origin + [[level.ex_vectorscale]](anglestoforward(self.angles), 100000);
				time = calcTime(self.origin, dest, speed);
				if(time <= 0) break;
				self moveto(dest, time, 0, 0);
				continue;
			}
		}

		// change target from gunship to decoy if one is deployed
		if(target_info.target_type == 0 || target_info.target_type == 16)
		{
			if(isDefined(level.gunship) && target_info.target == level.gunship && isDefined(level.ex_gunship_decoy))
			{
				target_info.target = level.gunship_decoy;
				target_info.target_type = 0;
			}
			else if(isDefined(level.gunship_special) && target_info.target == level.gunship_special && isDefined(level.gunship_special_decoy))
			{
				target_info.target = level.gunship_special_decoy;
				target_info.target_type = 0;
			}
			else target_info.target_type = 16;
		}

		// try to follow target
		newdest = target_info.target.origin;
		if(!isDefined(newdest) || newdest == olddest) continue;
		olddest = dest;
		dest = newdest;

		if(self.finishedrotating)
		{
			dir = vectorNormalize(dest - self.origin);
			forward = anglesToForward(self.angles);
			dot = vectorDot(dir, forward);
			if(dot < 0.85)
			{
				rotate = vectorToAngles(dest - self.origin);
				dot = dotNormalize(vectorDot(anglesToForward(self.angles), anglesToForward(rotate)));
				time = abs(acos(dot) * .0075);
				if(time <= 0) time = 0.1;

				self rotateto(rotate, time, 0, 0);
				self.finishedrotating = false;
				self thread devMissileRotate(time);
			}
		}

		if(self.finishedrotating) angle = vectorToAngles(dest - self.origin);
		else
		{
			dest = self.origin + [[level.ex_vectorscale]](anglesToForward(self.angles), 100000);
			angle = undefined;
		}
		if(isDefined(angle)) self.angles = angle;

		time = calcTime(self.origin, dest, speed);
		if(time <= 0) break;
		self moveto(dest, time, 0, 0);
	}

	self hide();

	// we don't want cpx on player entities
	if(trace["fraction"] != 1 && isDefined(trace["entity"]) && isPlayer(trace["entity"])) trace["entity"] = undefined;

	// handle explosion and damage
	if(isPlayer(device_info.owner) && device_info.owner.sessionstate != "spectator" && (!level.ex_teamplay || device_info.owner.pers["team"] == device_info.team))
	{
		// update device info
		device_info.origin = self.origin;
		device_info.entity = trace["entity"];

		// missile explosion
		self thread devExplode(dev_id, device_info);
	}
	else self devEffects(dev_id);

	wait(1);
	self delete();
}

devMissileRotate(time)
{
	self notify("stop_rotate_thread");
	self endon("stop_rotate_thread");

	wait( [[level.ex_fpstime]](time) );
	if(isDefined(self)) self.finishedrotating = true;
}

//------------------------------------------------------------------------------
// Queue handling
//------------------------------------------------------------------------------
devQueue(dev_variant, device_info)
{
	dev_index = devIndex(dev_variant);
	if(dev_index == -1) return;

	// not an acting device
	if(!level.ex_devices[dev_index].act) return;

	// gotta have this
	if(!isDefined(device_info)) return;

	level.ex_devicequeueID++;

	// queue it
	queue_index = devQueueAllocate();
	level.ex_devicequeue[queue_index].dev_index = dev_index;
	level.ex_devicequeue[queue_index].origin = device_info.origin;
	level.ex_devicequeue[queue_index].owner = device_info.owner;
	level.ex_devicequeue[queue_index].team = device_info.team;
	level.ex_devicequeue[queue_index].entity = device_info.entity;
	level.ex_devicequeue[queue_index].queue_id = level.ex_devicequeueID;
	level.ex_devicequeue[queue_index].stamp = getTime();
	if(level.ex_log_devices) logprint("DEV: Allocating queue[" + queue_index + "] for device \"" + level.ex_devices[dev_index].dev_id + "\" [QID " + level.ex_devicequeueID + "]\n");
}

devQueueProcess(eventID)
{
	// get the oldest in queue
	snap = getTime();
	queue_index = -1;
	for(i = 0; i < level.ex_devicequeue.size; i++)
	{
		if(level.ex_devicequeue[i].inuse && isDefined(level.ex_devicequeue[i].stamp) && level.ex_devicequeue[i].stamp < snap)
		{
			snap = level.ex_devicequeue[i].stamp;
			queue_index = i;
		}
	}

	// call callback of reacting devices
	if(queue_index != -1)
	{
		for(i = 0; i < level.ex_devices.size; i++)
		{
			// must be a reacting device
			if(level.ex_devices[i].react)
			{
				// must have at least one matching act and react flag
				act = level.ex_devices[ level.ex_devicequeue[queue_index].dev_index ].act;
				matching_flags = (act & level.ex_devices[i].react);
				if(matching_flags)
				{
					if(level.ex_log_devices) logprint("DEV: Calling procedure for reacting device \"" + level.ex_devices[i].dev_id + "\" [QID " + level.ex_devicequeue[queue_index].queue_id + "]\n");

					// conditional priority 1 (entity check)
					if((matching_flags & 4) == 4 && isDefined(level.ex_devicequeue[queue_index].entity))
						level thread [[level.ex_devices[i].react_callback]](level.ex_devicequeue[queue_index].dev_index, 4, level.ex_devicequeue[queue_index].origin, level.ex_devicequeue[queue_index].owner, level.ex_devicequeue[queue_index].team, level.ex_devicequeue[queue_index].entity);
					// conditional priority 2 (close proximity - explosion count)
					else if((matching_flags & 2) == 2)
						level thread [[level.ex_devices[i].react_callback]](level.ex_devicequeue[queue_index].dev_index, 2, level.ex_devicequeue[queue_index].origin, level.ex_devicequeue[queue_index].owner, level.ex_devicequeue[queue_index].team, undefined);
					// conditional priority 3 (close proximity - distance)
					else if((matching_flags & 1) == 1)
						level thread [[level.ex_devices[i].react_callback]](level.ex_devicequeue[queue_index].dev_index, 1, level.ex_devicequeue[queue_index].origin, level.ex_devicequeue[queue_index].owner, level.ex_devicequeue[queue_index].team, undefined);
					// unconditional priority 1 (32)
					else if((matching_flags & 32) == 32)
						level thread [[level.ex_devices[i].react_callback]](level.ex_devicequeue[queue_index].dev_index, 32, level.ex_devicequeue[queue_index].origin, level.ex_devicequeue[queue_index].owner, level.ex_devicequeue[queue_index].team, undefined);
					// unconditional priority 2 (16)
					else if((matching_flags & 16) == 16)
						level thread [[level.ex_devices[i].react_callback]](level.ex_devicequeue[queue_index].dev_index, 16, level.ex_devicequeue[queue_index].origin, level.ex_devicequeue[queue_index].owner, level.ex_devicequeue[queue_index].team, undefined);
					// unconditional priority 3 (8)
					else if((matching_flags & 8) == 8)
						level thread [[level.ex_devices[i].react_callback]](level.ex_devicequeue[queue_index].dev_index, 8, level.ex_devicequeue[queue_index].origin, level.ex_devicequeue[queue_index].owner, level.ex_devicequeue[queue_index].team, undefined);

					wait( level.ex_fps_frame );
				}
			}
		}

		//took = (getTime() - level.ex_devicequeue[queue_index].stamp) / 1000;
		//logprint("DEV: Processing queue[" + queue_index + "] for acting device \"" + level.ex_devices[level.ex_devicequeue[queue_index].dev_index].dev_id + "\" [QID " + level.ex_devicequeue[queue_index].queue_id + "] took " + took + " seconds\n");

		level.ex_devicequeue[queue_index].inuse = false;
	}

	[[level.ex_enableLevelEvent]]("onFrame", eventID);
}

devQueueAllocate()
{
	for(i = 0; i < level.ex_devicequeue.size; i++)
	{
		if(level.ex_devicequeue[i].inuse == false)
		{
			level.ex_devicequeue[i].inuse = true;
			return(i);
		}
	}

	level.ex_devicequeue[i] = spawnstruct();
	level.ex_devicequeue[i].inuse = true;
	return(i);
}

//------------------------------------------------------------------------------
// Properties handling
//------------------------------------------------------------------------------
devIndex(dev_variant)
{
	if(!isDefined(dev_variant)) return(-1);
	if(isString(dev_variant)) dev_index = _devNameToIndex(dev_variant);
		else dev_index = _devVerifyIndex(dev_variant);
	return(dev_index);
}

_devNameToIndex(dev_id)
{
	if(dev_id == "") return(-1);
	for(i = 0; i < level.ex_devices.size; i++)
		if(level.ex_devices[i].dev_id == dev_id) return(i);
	return(-1);
}

_devVerifyIndex(dev_index)
{
	if(dev_index < 0) return(-1);
	if(!isDefined(level.ex_devices[dev_index])) return(-1);
	return(dev_index);
}

getDeviceHud(dev_variant)
{
	dev_index = devIndex(dev_variant);
	if(dev_index != -1) return(level.ex_devices[dev_index].hud);
	return("");
}

getDeviceModel(dev_variant)
{
	dev_index = devIndex(dev_variant);
	if(dev_index != -1) return(level.ex_devices[dev_index].model);
	return("");
}

getDeviceModelZ(dev_variant)
{
	dev_index = devIndex(dev_variant);
	if(dev_index != -1) return(level.ex_devices[dev_index].modz);
	return("");
}

getDeviceModelA(dev_variant)
{
	dev_index = devIndex(dev_variant);
	if(dev_index != -1) return(level.ex_devices[dev_index].moda);
	return("");
}

getGrenadeDevice(weapon)
{
	switch(weapon)
	{
		// frag grenades
		case "frag_grenade_american_mp": return("frag_american");
		case "frag_grenade_british_mp": return("frag_british");
		case "frag_grenade_german_mp": return("frag_german");
		case "frag_grenade_russian_mp": return("frag_russian");

		// gas grenades
		case "gas_mp":
		case "smoke_grenade_american_gas_mp":
		case "smoke_grenade_british_gas_mp":
		case "smoke_grenade_german_gas_mp":
		case "smoke_grenade_russian_gas_mp": return("gasnade");

		// fire grenades
		case "fire_mp":
		case "smoke_grenade_american_fire_mp":
		case "smoke_grenade_british_fire_mp":
		case "smoke_grenade_german_fire_mp":
		case "smoke_grenade_russian_fire_mp": return("firenade");

		// satchel charges
		case "satchel_mp":
		case "smoke_grenade_american_satchel_mp":
		case "smoke_grenade_british_satchel_mp":
		case "smoke_grenade_german_satchel_mp":
		case "smoke_grenade_russian_satchel_mp": return("satchel");

		// supernades
		case "supernade_american_mp": return("supernade_american");
		case "supernade_british_mp": return("supernade_british");
		case "supernade_german_mp": return("supernade_german");
		case "supernade_russian_mp": return("supernade_russian");

		// grey smoke
		case "smoke_grenade_american_mp":
		case "smoke_grenade_british_mp":
		case "smoke_grenade_german_mp":
		case "smoke_grenade_russian_mp": return("smoke_grey");

		// blue smoke
		case "smoke_grenade_american_blue_mp":
		case "smoke_grenade_british_blue_mp":
		case "smoke_grenade_german_blue_mp":
		case "smoke_grenade_russian_blue_mp": return("smoke_blue");

		// green smoke
		case "smoke_grenade_american_green_mp":
		case "smoke_grenade_british_green_mp":
		case "smoke_grenade_german_green_mp":
		case "smoke_grenade_russian_green_mp": return("smoke_green");

		// orange smoke
		case "smoke_grenade_american_orange_mp":
		case "smoke_grenade_british_orange_mp":
		case "smoke_grenade_german_orange_mp":
		case "smoke_grenade_russian_orange_mp": return("smoke_orange");

		// pink smoke
		case "smoke_grenade_american_pink_mp":
		case "smoke_grenade_british_pink_mp":
		case "smoke_grenade_german_pink_mp":
		case "smoke_grenade_russian_pink_mp": return("smoke_pink");

		// red smoke
		case "smoke_grenade_american_red_mp":
		case "smoke_grenade_british_red_mp":
		case "smoke_grenade_german_red_mp":
		case "smoke_grenade_russian_red_mp": return("smoke_red");

		// yellow smoke
		case "smoke_grenade_american_yellow_mp":
		case "smoke_grenade_british_yellow_mp":
		case "smoke_grenade_german_yellow_mp":
		case "smoke_grenade_russian_yellow_mp": return("smoke_yellow");
	}
}
