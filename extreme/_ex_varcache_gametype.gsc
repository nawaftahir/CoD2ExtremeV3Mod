init()
{
	switch(level.ex_currentgt)
	{
		case "chq": chq_init(); break;
		case "cnq": cnq_init(); break;
		case "ctf": ctf_init(); break;
		case "ctfb": ctfb_init(); break;
		case "dm": dm_init(); break;
		case "dom": dom_init(); break;
		case "esd": esd_init(); break;
		case "ft": ft_init(); break;
		case "hm": hm_init(); break;
		case "hq": hq_init(); break;
		case "htf": htf_init(); break;
		case "ihtf": ihtf_init(); break;
		case "lib": lib_init(); break;
		case "lms": lms_init(); break;
		case "lts": lts_init(); break;
		case "ons": ons_init(); break;
		case "rbcnq": rbcnq_init(); break;
		case "rbctf": rbctf_init(); break;
		case "sd": sd_init(); break;
		case "tdm": tdm_init(); break;
		case "tkoth": tkoth_init(); break;
		case "vip": vip_init(); break;
	}
}

initreg()
{
	switch(level.ex_currentgt)
	{
		case "chq": chq_initreg(); break;
		case "cnq": cnq_initreg(); break;
		case "ctf": ctf_initreg(); break;
		case "ctfb": ctfb_initreg(); break;
		case "dm": dm_initreg(); break;
		case "dom": dom_initreg(); break;
		case "esd": esd_initreg(); break;
		case "ft": ft_initreg(); break;
		case "hm": hm_initreg(); break;
		case "hq": hq_initreg(); break;
		case "htf": htf_initreg(); break;
		case "ihtf": ihtf_initreg(); break;
		case "lib": lib_initreg(); break;
		case "lms": lms_initreg(); break;
		case "lts": lts_initreg(); break;
		case "ons": ons_initreg(); break;
		case "rbcnq": rbcnq_initreg(); break;
		case "rbctf": rbctf_initreg(); break;
		case "sd": sd_initreg(); break;
		case "tdm": tdm_initreg(); break;
		case "tkoth": tkoth_initreg(); break;
		case "vip": vip_initreg(); break;
	}
}

chq_init()
{
	level.radioradius = [[level.ex_drm]]("ex_chq_radio_radius", 10, 1, 12, "int") * 12;
	level.zradioradius = [[level.ex_drm]]("ex_chq_radio_zradius", 6, 1, 12, "int") * 12;
	level.ex_custom_radios = [[level.ex_drm]]("ex_chq_custom_radios", 1, 0, 1, "int");
	level.ex_hq_radio_spawntime = [[level.ex_drm]]("ex_chq_radio_spawntime", 45, 0, 240, "int");
	level.ex_hq_radio_holdtime = [[level.ex_drm]]("ex_chq_radio_holdtime", 120, 60, 1440, "int");
	level.ex_hq_radio_compass = [[level.ex_drm]]("ex_chq_radio_compass", 0, 0, 1, "int");
	level.ex_hqpoints_teamcap = [[level.ex_drm]]("ex_chqpoints_teamcap", 0, 0, 999, "int");
	level.ex_hqpoints_teamneut = [[level.ex_drm]]("ex_chqpoints_teamneut", 10, 0, 999, "int");
	level.ex_hqpoints_playercap = [[level.ex_drm]]("ex_chqpoints_playercap", 2, 0, 999, "int");
	level.ex_hqpoints_playerneut = [[level.ex_drm]]("ex_chqpoints_playerneut", 2, 0, 999, "int");
	level.ex_hqpoints_defpps = [[level.ex_drm]]("ex_chqpoints_defpps", 1, 0, 999, "int");
	level.ex_hqpoints_radius = [[level.ex_drm]]("ex_chqpoints_radius", 40, 0, 200, "int") * 12;
}

chq_initreg()
{
	// No registrations necessary
}

cnq_init()
{
	level.cnq_initialobj = [[level.ex_drm]]("scr_cnq_initialobjective", 1, 1, 3, "int");
	if(level.cnq_initialobj != 1 && level.cnq_initialobj != 3) level.cnq_initialobj = 1;
	level.spawnmethod = [[level.ex_drm]]("scr_cnq_spawnmethod", "default", "", "", "string");
	if(level.spawnmethod != "default" && level.spawnmethod != "random") level.spawnmethod = "default";
	level.team_obj_points = [[level.ex_drm]]("scr_cnq_team_objective_points", 10, 0, 999, "int");
	level.team_bonus_points = [[level.ex_drm]]("scr_cnq_team_bonus_points", 15, 0, 999, "int");
	level.player_obj_points = [[level.ex_drm]]("scr_cnq_player_objective_points", 10, 0, 999, "int");
	level.player_bonus_points = [[level.ex_drm]]("scr_cnq_player_bonus_points", 15, 0, 999, "int");
	level.cnq_campaign_mode = [[level.ex_drm]]("scr_cnq_campaign", 1, 0, 1, "int");
	level.showobj_hud = [[level.ex_drm]]("scr_cnq_showobj_hud", 1, 0, 1, "int");
	level.cnq_debug = [[level.ex_drm]]("scr_cnq_debug", 0, 0, 1, "int");
}

cnq_initreg()
{
	// No registrations necessary
}

ctf_init()
{
	level.ex_ctfpoints_playercf = [[level.ex_drm]]("ex_ctfpoints_playercf", 10, 0, 999, "int");
	level.ex_ctfpoints_playerrf = [[level.ex_drm]]("ex_ctfpoints_playerrf", 2, 0, 999, "int");
	level.ex_ctfpoints_playersf = [[level.ex_drm]]("ex_ctfpoints_playersf", 2, 0, 999, "int");
	level.ex_ctfpoints_playertf = [[level.ex_drm]]("ex_ctfpoints_playertf", 1, 0, 999, "int");
	level.ex_ctfpoints_playerkf = [[level.ex_drm]]("ex_ctfpoints_playerkf", 1, 0, 999, "int");
	level.flagautoreturndelay = [[level.ex_drm]]("scr_ctf_flagautoreturndelay", 120, 0, 1440, "int");
}

ctf_initreg()
{
	// No registrations necessary
}

ctfb_init()
{
	level.ex_ctfbpoints_playercf = [[level.ex_drm]]("ex_ctfbpoints_playercf", 10, 0, 999, "int");
	level.ex_ctfbpoints_playerrf = [[level.ex_drm]]("ex_ctfbpoints_playerrf", 5, 0, 999, "int");
	level.ex_ctfbpoints_playersf = [[level.ex_drm]]("ex_ctfbpoints_playersf", 2, 0, 999, "int");
	level.ex_ctfbpoints_playerpf = [[level.ex_drm]]("ex_ctfbpoints_playerpf", 1, 0, 999, "int");
	level.ex_ctfbpoints_playertf = [[level.ex_drm]]("ex_ctfbpoints_playertf", 1, 0, 999, "int");
	level.ex_ctfbpoints_playerkfo = [[level.ex_drm]]("ex_ctfbpoints_playerkfo", 1, 0, 999, "int");
	level.ex_ctfbpoints_playerkfe = [[level.ex_drm]]("ex_ctfbpoints_playerkfe", 1, 0, 999, "int");
	level.ex_ctfbpoints_defend = [[level.ex_drm]]("ex_ctfbpoints_defend", 1, 0, 999, "int");
	level.ex_ctfbpoints_assist = [[level.ex_drm]]("ex_ctfbpoints_assist", 1, 0, 999, "int");
	level.flagprotectiondistance = [[level.ex_drm]]("scr_ctfb_flagprotectiondistance", 1000, 0, 5000, "int");
	level.show_enemy_own_flag_after_sec = [[level.ex_drm]]("scr_ctfb_show_enemy_own_flag_after_sec", 60, 10, 1440, "int");
	level.show_enemy_own_flag_time = [[level.ex_drm]]("scr_ctfb_show_enemy_own_flag_time", 60, 10, 1440, "int");
	level.flagautoreturndelay = [[level.ex_drm]]("scr_ctfb_flagautoreturndelay", 120, 0, 1440, "int");
	level.random_flag_position = [[level.ex_drm]]("scr_ctfb_random_flag_position", 0, 0, 1, "int");
	level.show_enemy_own_flag = [[level.ex_drm]]("scr_ctfb_show_enemy_own_flag", 0, 0, 1, "int");
}

ctfb_initreg()
{
	// No registrations necessary
}

dm_init()
{
	// No additional settings
}

dm_initreg()
{
	// No registrations necessary
}

dom_init()
{
	game["scorelimit"] = 0;
	level.flagsnumber = [[level.ex_drm]]("scr_dom_flagsnumber", 3, 1, 9, "int");
	level.spawndistance = [[level.ex_drm]]("scr_dom_spawndistance", 1000, 250, 5000, "int");
	level.flagcapturetime = [[level.ex_drm]]("scr_dom_flagcapturetime", 10, 1, 30, "int");
	level.pointscaptureflag = [[level.ex_drm]]("scr_dom_pointscaptureflag", 5, 1, 999, "int");
	level.cooldowntime = [[level.ex_drm]]("scr_dom_cooldowntime", 5, 1, 30, "int");
	level.flagtimeout = [[level.ex_drm]]("scr_dom_flagtimeout", 120, 0, 1440, "int");
	level.showflagwaypoints = [[level.ex_drm]]("scr_dom_showflagwaypoints", 0, 0, 1, "int");
	level.use_static_flags = [[level.ex_drm]]("scr_dom_static_flags", 0, 0, 1, "int");

	if(level.use_static_flags) extreme\_ex_varcache_gametype_dom::init();
}

dom_initreg()
{
	// No registrations necessary
}

esd_init()
{
	level.esd_mode = [[level.ex_drm]]("scr_esd_mode", 2, 0, 4, "int");
	level.esd_campaign_mode = [[level.ex_drm]]("scr_esd_campaign", 1, 0, 1, "int");
	level.esd_swap_roundwinner = [[level.ex_drm]]("scr_esd_swap_roundwinner", 1, 0, 1, "int");
	level.spawnlimit = [[level.ex_drm]]("scr_esd_spawntickets", 10, 0, 999, "int");
	level.plantscore = [[level.ex_drm]]("scr_esd_plantscore", 5, 0, 999, "int");
	level.defusescore = [[level.ex_drm]]("scr_esd_defusescore", 10, 0, 999, "int");
	level.roundwin_points = [[level.ex_drm]]("scr_esd_roundwin_points", 5, 0, 999, "int");

	level.bombtimer = [[level.ex_drm]]("scr_esd_bombtimer", 60, 30, 120, "int");
	level.planttime = [[level.ex_drm]]("scr_esd_planttime", 5, 1, 60, "int");
	level.defusetime = [[level.ex_drm]]("scr_esd_defusetime", 10, 1, 60, "int");
}

esd_initreg()
{
	[[level.ex_registerCvar]]("ui_esd_mode", level.esd_mode, 1);
	[[level.ex_registerCvar]]("ui_esd_spawntickets", level.spawnlimit, 1);
}

hm_init()
{
	level.showcommander = [[level.ex_drm]]("scr_hm_showcommander", 1, 0, 1, "int");
	level.tposuptime = [[level.ex_drm]]("scr_hm_tposuptime", 5, 0, 10, "int");
	level.ex_hmpoints_cmd_hitman = [[level.ex_drm]]("scr_hmpoints_cmd_hitman", 5, 0, 999, "int");
	level.ex_hmpoints_guard_hitman = [[level.ex_drm]]("scr_hmpoints_guard_hitman", 3, 0, 999, "int");
	level.ex_hmpoints_hitman_cmd = [[level.ex_drm]]("scr_hmpoints_hitman_cmd", 10, 0, 999, "int");
	level.ex_hmpoints_hitman_guard = [[level.ex_drm]]("scr_hmpoints_hitman_guard", 1, 0, 999, "int");
	level.ex_hmpoints_hitman_hitman = [[level.ex_drm]]("scr_hmpoints_hitman_hitman", 2, 0, 999, "int");
	level.penalty_time = [[level.ex_drm]]("scr_hm_penaltytime", 5, 0, 10, "int");
}

hm_initreg()
{
	// No registrations necessary
}

hq_init()
{
	level.radioradius = [[level.ex_drm]]("ex_hq_radio_radius", 10, 1, 12, "int") * 12;
	level.zradioradius = [[level.ex_drm]]("ex_hq_radio_zradius", 6, 1, 12, "int") * 12;
	level.ex_custom_radios = [[level.ex_drm]]("ex_hq_custom_radios", 1, 0, 1, "int");
	level.ex_hq_radio_spawntime = [[level.ex_drm]]("ex_hq_radio_spawntime", 45, 0, 240, "int");
	level.ex_hq_radio_holdtime = [[level.ex_drm]]("ex_hq_radio_holdtime", 120, 60, 1440, "int");
	level.ex_hq_radio_compass = [[level.ex_drm]]("ex_hq_radio_compass", 0, 0, 1, "int");
	level.ex_hqpoints_teamcap = [[level.ex_drm]]("ex_hqpoints_teamcap", 0, 0, 999, "int");
	level.ex_hqpoints_teamneut = [[level.ex_drm]]("ex_hqpoints_teamneut", 10, 0, 999, "int");
	level.ex_hqpoints_playercap = [[level.ex_drm]]("ex_hqpoints_playercap", 2, 0, 999, "int");
	level.ex_hqpoints_playerneut = [[level.ex_drm]]("ex_hqpoints_playerneut", 2, 0, 999, "int");
	level.ex_hqpoints_defpps = [[level.ex_drm]]("ex_hqpoints_defpps", 1, 0, 999, "int");
	level.ex_hqpoints_radius = [[level.ex_drm]]("ex_hqpoints_radius", 40, 0, 200, "int") * 12;
}

hq_initreg()
{
	// No registrations necessary
}

htf_init()
{
	level.mode = [[level.ex_drm]]("scr_htf_mode", 0, 0, 3, "int");
	level.htf_teamscore = [[level.ex_drm]]("scr_htf_teamscore", 0, 0, 1, "int");
	level.flagspawndelay = [[level.ex_drm]]("scr_htf_flagspawndelay", 15, 0, 120, "int");
	level.removeflagspawns = [[level.ex_drm]]("scr_htf_removeflagspawns", 1, 0, 1, "int");
	level.flagholdtime = [[level.ex_drm]]("scr_htf_flagholdtime", 90, 10, 300, "int");
	level.flagrecovertime = [[level.ex_drm]]("scr_htf_flagrecovertime", 60, 0, 1440, "int");
	level.PointsForKillingFlagCarrier = [[level.ex_drm]]("scr_htf_pointsforkillingflagcarrier", 1, 0, 999, "int");
	level.PointsForStealingFlag = [[level.ex_drm]]("scr_htf_pointsforstealingflag", 1, 0, 999, "int");

	extreme\_ex_varcache_gametype_htf::init();
}

htf_initreg()
{
	// No registrations necessary
}

ihtf_init()
{
	level.flagspawndelay = [[level.ex_drm]]("scr_ihtf_flagspawndelay", 15, 0, 120, "int");
	level.flagholdtime = [[level.ex_drm]]("scr_ihtf_flagholdtime", 10, 10, 1440, "int");
	level.flagmaxholdtime = [[level.ex_drm]]("scr_ihtf_flagmaxholdtime", 120, 10, 1440, "int");
	level.flagtimeout = [[level.ex_drm]]("scr_ihtf_flagtimeout", 60, 10, 300, "int");
	level.PointsForHoldingFlag = [[level.ex_drm]]("scr_ihtf_pointsforholdingflag", 2, 0, 999, "int");
	level.PointsForStealingFlag = [[level.ex_drm]]("scr_ihtf_pointsforstealingflag", 1, 0, 999, "int");
	level.PointsForKillingPlayers = [[level.ex_drm]]("scr_ihtf_pointsforkillingplayers", 0, 0, 999, "int");
	level.PointsForKillingFlagCarrier = [[level.ex_drm]]("scr_ihtf_pointsforkillingflagcarrier", 1, 0, 999, "int");
	level.randomflagspawns = [[level.ex_drm]]("scr_ihtf_randomflagspawns", 1, 0, 1, "int");
	level.spawndistance = [[level.ex_drm]]("scr_ithf_spawndistance", 1000, 0, 5000, "int");
	level.playerspawnpointsmode = [[level.ex_drm]]("scr_ihtf_playerspawnpointsmode", "dm tdm", "", "", "string");
	level.flagspawnpointsmode = [[level.ex_drm]]("scr_ihtf_flagspawnpointsmode", "dm ctff sdb hq", "", "", "string");
	level.flagrecovertime = [[level.ex_drm]]("scr_ihtf_flagrecovertime", 60, 0, 1440, "int");
}

ihtf_initreg()
{
	// No registrations necessary
}

lib_init()
{
	// No additional settings
}

lib_initreg()
{
	// No registrations necessary
}

lms_init()
{
	level.minplayers = [[level.ex_drm]]("scr_lms_minplayers", 3, 3, 64, "int");
	level.joinperiodtime = [[level.ex_drm]]("scr_lms_joinperiod", 30, 1, 120, "int");
	level.killometer = [[level.ex_drm]]("scr_lms_killometer", 120, 30, 1200, "int");
	level.duelperiodtime = [[level.ex_drm]]("scr_lms_duelperiod", 60, 30, 300, "int");
	level.killwinner = [[level.ex_drm]]("scr_lms_killwinner", 0, 0, 1, "int");
}

lms_initreg()
{
	[[level.ex_registerCvar]]("ui_lms_killometer", level.killometer, 1);
	[[level.ex_registerCvar]]("ui_lms_duelperiod", level.duelperiodtime, 1);
}

lts_init()
{
	// No additional settings
}

lts_initreg()
{
	// No registrations necessary
}

ons_init()
{
	game["scorelimit"] = 0;
	level.flagsnumber = [[level.ex_drm]]("scr_ons_flagsnumber", 5, 0, 9, "int");
	level.spawndistance = [[level.ex_drm]]("scr_ons_spawndistance", 1000, 250, 5000, "int");
	level.flagcapturetime = [[level.ex_drm]]("scr_ons_flagcapturetime", 10, 1, 30, "int");
	level.pointscaptureflag = [[level.ex_drm]]("scr_ons_pointscaptureflag", 5, 1, 999, "int");
	level.cooldowntime = [[level.ex_drm]]("scr_ons_cooldowntime", 5, 1, 30, "int");
	level.flagtimeout = [[level.ex_drm]]("scr_ons_flagtimeout", 120, 0, 1440, "int");
	level.showflagwaypoints = [[level.ex_drm]]("scr_ons_showflagwaypoints", 0, 0, 1, "int");
	level.use_static_flags = [[level.ex_drm]]("scr_ons_static_flags", 1, 0, 1, "int");

	if(level.use_static_flags) extreme\_ex_varcache_gametype_dom::init();
}

ons_initreg()
{
	// No registrations necessary
}

rbcnq_init()
{
	level.rbcnq_initialobj = [[level.ex_drm]]("scr_rbcnq_initialobjective", 1, 1, 3, "int");
	if(level.rbcnq_initialobj != 1 && level.rbcnq_initialobj != 3) level.rbcnq_initialobj = 1;
	level.spawnmethod = [[level.ex_drm]]("scr_rbcnq_spawnmethod", "default", "", "", "string");
	if(level.spawnmethod != "default" && level.spawnmethod != "random") level.spawnmethod = "default";
	level.team_obj_points = [[level.ex_drm]]("scr_rbcnq_team_objective_points", 10, 0, 999, "int");
	level.team_bonus_points = [[level.ex_drm]]("scr_rbcnq_team_bonus_points", 15, 0, 999, "int");
	level.player_obj_points = [[level.ex_drm]]("scr_rbcnq_player_objective_points", 10, 0, 999, "int");
	level.player_bonus_points = [[level.ex_drm]]("scr_rbcnq_player_bonus_points", 15, 0, 999, "int");
	level.roundwin_points = [[level.ex_drm]]("scr_rbcnq_roundwin_points", 15, 0, 999, "int");
	level.rbcnq_campaign_mode = [[level.ex_drm]]("scr_rbcnq_campaign", 1, 0, 1, "int");
	level.rbcnq_swap_roundwinner = [[level.ex_drm]]("scr_rbcnq_swap_roundwinner", 1, 0, 1, "int");
	level.showobj_hud = [[level.ex_drm]]("scr_rbcnq_showobj_hud", 1, 0, 1, "int");
	level.captime = [[level.ex_drm]]("scr_rbcnq_captime", 5, 0, 10, "int");
	level.spawnlimit = [[level.ex_drm]]("scr_rbcnq_spawntickets", 10, 0, 999, "int");
	level.reset_scores = [[level.ex_drm]]("scr_rbcnq_round_reset_scores", 0, 0, 1, "int");
	level.cnq_debug = [[level.ex_drm]]("scr_rbcnq_debug", 0, 0, 1, "int");
}

rbcnq_initreg()
{
	[[level.ex_registerCvar]]("ui_rbcnq_spawntickets", level.spawnlimit, 1);
}

rbctf_init()
{
	level.ex_rbctfpoints_roundwin = [[level.ex_drm]]("ex_rbctfpoints_roundwin", 5, 1, 999, "int");
	level.ex_rbctfpoints_playercf = [[level.ex_drm]]("ex_rbctfpoints_playercf", 10, 0, 999, "int");
	level.ex_rbctfpoints_playerrf = [[level.ex_drm]]("ex_rbctfpoints_playerrf", 5, 0, 999, "int");
	level.ex_rbctfpoints_playersf = [[level.ex_drm]]("ex_rbctfpoints_playersf", 2, 0, 999, "int");
	level.ex_rbctfpoints_playertf = [[level.ex_drm]]("ex_rbctfpoints_playertf", 1, 0, 999, "int");
	level.ex_rbctfpoints_playerkf = [[level.ex_drm]]("ex_rbctfpoints_playerkf", 1, 0, 999, "int");
	level.spawnlimit = [[level.ex_drm]]("scr_rbctf_spawntickets", 10, 0, 999, "int");
	level.showobj_hud = [[level.ex_drm]]("scr_rbctf_showobj_hud", 1, 0, 1, "int");
	level.flagautoreturndelay = [[level.ex_drm]]("scr_rbctf_returndelay", 60, 0, 1440, "int");
}

rbctf_initreg()
{
	[[level.ex_registerCvar]]("ui_rbctf_spawntickets", level.spawnlimit, 1);
}

sd_init()
{
	level.ex_sdpoints_plant = [[level.ex_drm]]("ex_sdpoints_plant", 5, 0, 999, "int");
	level.ex_sdpoints_defuse = [[level.ex_drm]]("ex_sdpoints_defuse", 10, 0, 999, "int");

	level.bombtimer = [[level.ex_drm]]("scr_sd_bombtimer", 60, 30, 120, "int");
	level.planttime = [[level.ex_drm]]("scr_sd_planttime", 5, 1, 60, "int");
	level.defusetime = [[level.ex_drm]]("scr_sd_defusetime", 10, 1, 60, "int");
}

sd_initreg()
{
	// No registrations necessary
}

tdm_init()
{
	// No additional settings
}

tdm_initreg()
{
	// No registrations necessary
}

tkoth_init()
{
	extreme\_ex_varcache_gametype_tkoth::init();

	level.zonetimelimit = [[level.ex_drm]]("scr_tkoth_zonetimelimit", 5, 1, 15, "int");
	level.zonepoints_capture = [[level.ex_drm]]("ex_tkothpoints_capture", 1, 1, 999, "int");
	level.zonepoints_takeover = [[level.ex_drm]]("ex_tkothpoints_takeover", 2, 1, 999, "int");
	level.zonepoints_holdmax = [[level.ex_drm]]("ex_tkothpoints_holdmax", 10, 1, 999, "int");
	level.debug = [[level.ex_drm]]("scr_tkoth_debug", 0, 0, 1, "int");
}

tkoth_initreg()
{
	[[level.ex_registerCvar]]("ui_tkoth_zonetimelimit", level.zonetimelimit, 1);
}

vip_init()
{
	level.vipdelay = [[level.ex_drm]]("scr_vip_vipdelay", 5, 0, 300, "int");
	level.vipvisiblebyteammates = [[level.ex_drm]]("scr_vip_vipvisiblebyteammates", 1, 0, 1, "int");
	level.vipvisiblebyenemies = [[level.ex_drm]]("scr_vip_vipvisiblebyenemies", 1, 0, 1, "int");
	level.pointsforkillingvip = [[level.ex_drm]]("scr_vip_pointsforkillingvip", 5, 0, 999, "int");
	level.pointsforprotectingvip = [[level.ex_drm]]("scr_vip_pointsforprotectingvip", 3, 0, 999, "int");
	level.vippoints = [[level.ex_drm]]("scr_vip_vippoints", 2, 0, 999, "int");
	level.vippointscycle = [[level.ex_drm]]("scr_vip_vippoints_cycle", 3, 0, 999, "int");
	level.vipprotectiondistance = [[level.ex_drm]]("scr_vip_vipprotectiondistance", 1000, 0, 5000, "int");
	level.vipprotectiontime = [[level.ex_drm]]("scr_vip_vipprotectiontime", 15, 0, 120, "int");
	level.vippistol = [[level.ex_drm]]("scr_vip_vippistol", 1, 0, 1, "int");
	level.vipmaxfragnades = 9;
	level.vipfragnades = [[level.ex_drm]]("scr_vip_vipfragnades", 0, 0, level.vipmaxfragnades, "int");
	level.vipmaxsmokenades = 9;
	level.vipsmokenades = [[level.ex_drm]]("scr_vip_vipsmokenades", 3, 0, level.vipmaxsmokenades, "int");
	level.vipsmokeradius = [[level.ex_drm]]("scr_vip_vipsmokeradius", 380, 0, 5000, "int");
	level.vipsmokeduration = [[level.ex_drm]]("scr_vip_vipsmokeduration", 70, 0, 600, "int");
	level.viphealth = [[level.ex_drm]]("scr_vip_viphealth", 150, 0, 1000, "int");
	level.vipbinoculars = [[level.ex_drm]]("scr_vip_binoculars", 1, 0, 1, "int");
}

vip_initreg()
{
	// No registrations necessary
}

ft_init()
{
	level.ft_roundend_delay = [[level.ex_drm]]("scr_ft_roundend_delay", 5, 5, 60, "int");
	level.ft_maxfreeze = [[level.ex_drm]]("scr_ft_maxfreeze", 999, 1, 999, "int");
	level.ft_unfreeze_mode = [[level.ex_drm]]("scr_ft_unfreeze_mode", 2, 0, 2, "int");
	level.ft_unfreeze_mode_window = [[level.ex_drm]]("scr_ft_unfreeze_mode_window", 60, 10, 300, "int");
	level.ft_unfreeze_prox = [[level.ex_drm]]("scr_ft_unfreeze_prox", 1, 0, 1, "int");
	level.ft_unfreeze_prox_time = [[level.ex_drm]]("scr_ft_unfreeze_prox_time", 3, 1, 10, "int");
	level.ft_unfreeze_prox_dist = [[level.ex_drm]]("scr_ft_unfreeze_prox_dist", 100, 100, 500, "int");
	level.ft_unfreeze_laser = [[level.ex_drm]]("scr_ft_unfreeze_laser", 1, 0, 1, "int");
	level.ft_unfreeze_laser_time = [[level.ex_drm]]("scr_ft_unfreeze_laser_time", 3, 1, 10, "int");
	level.ft_unfreeze_laser_dist = [[level.ex_drm]]("scr_ft_unfreeze_laser_dist", 5000, 100, 9999, "int");
	level.ft_unfreeze_respawn = [[level.ex_drm]]("scr_ft_unfreeze_respawn", 1, 0, 1, "int");
	level.ft_raygun = [[level.ex_drm]]("scr_ft_raygun", 3, 0, 3, "int");
	level.ft_teamchange = [[level.ex_drm]]("scr_ft_teamchange", 1, 0, 1, "int");
	level.ft_weaponchange = [[level.ex_drm]]("scr_ft_weaponchange", 0, 0, 1, "int");
	level.ft_nadesteal = [[level.ex_drm]]("scr_ft_nadesteal", 0, 0, 1, "int");
	level.ft_nadesteal_frag = [[level.ex_drm]]("scr_ft_nadesteal_frag", 1, 0, 9, "int");
	level.ft_nadesteal_smoke = [[level.ex_drm]]("scr_ft_nadesteal_smoke", 0, 0, 9, "int");
	level.ft_soundchance = [[level.ex_drm]]("scr_ft_soundchance", 50, 0, 100, "int");
	level.ft_history = [[level.ex_drm]]("scr_ft_history", 10, 0, 64, "int");
	level.ft_balance_frozen = [[level.ex_drm]]("scr_ft_balance_frozen", 0, 0, 1, "int");
	level.ft_points_freeze = [[level.ex_drm]]("scr_ft_points_freeze", 1, 1, 999, "int");
	level.ft_points_unfreeze = [[level.ex_drm]]("scr_ft_points_unfreeze", 5, 1, 999, "int");
}

ft_initreg()
{
	// No registrations necessary
}

