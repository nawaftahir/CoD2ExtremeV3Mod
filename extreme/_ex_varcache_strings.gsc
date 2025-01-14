
init()
{
	// crybaby punishment from rcon
	if(level.ex_rcon && level.ex_crybaby) [[level.ex_PrecacheString]](&"MISC_CRYBABY");

	// welcome messages
	if(level.ex_pwelcome)
	{
		if(level.ex_pwelcome_all >= 1) [[level.ex_PrecacheString]](&"CUSTOM_ALL_MESSAGE_1");
		if(level.ex_pwelcome_all >= 2) [[level.ex_PrecacheString]](&"CUSTOM_ALL_MESSAGE_2");
		if(level.ex_pwelcome_all >= 3) [[level.ex_PrecacheString]](&"CUSTOM_ALL_MESSAGE_3");
		if(level.ex_pwelcome_all >= 4) [[level.ex_PrecacheString]](&"CUSTOM_ALL_MESSAGE_4");
		if(level.ex_pwelcome_all >= 5) [[level.ex_PrecacheString]](&"CUSTOM_ALL_MESSAGE_5");
		if(level.ex_pwelcome_all >= 6) [[level.ex_PrecacheString]](&"CUSTOM_ALL_MESSAGE_6");
		if(level.ex_pwelcome_all >= 7) [[level.ex_PrecacheString]](&"CUSTOM_ALL_MESSAGE_7");
		if(level.ex_pwelcome_all >= 8) [[level.ex_PrecacheString]](&"CUSTOM_ALL_MESSAGE_8");
		if(level.ex_pwelcome_all >= 9) [[level.ex_PrecacheString]](&"CUSTOM_ALL_MESSAGE_9");
		if(level.ex_pwelcome_all >= 10) [[level.ex_PrecacheString]](&"CUSTOM_ALL_MESSAGE_10");

		if(level.ex_pwelcome_msg >= 1) [[level.ex_PrecacheString]](&"CUSTOM_NONCLAN_MESSAGE_1");
		if(level.ex_pwelcome_msg >= 2) [[level.ex_PrecacheString]](&"CUSTOM_NONCLAN_MESSAGE_2");
		if(level.ex_pwelcome_msg >= 3) [[level.ex_PrecacheString]](&"CUSTOM_NONCLAN_MESSAGE_3");

		if(level.ex_clanwelcome)
		{
			if(level.ex_clantags[1] != "")
			{
				if(level.ex_clanmsgs[1] >= 1) [[level.ex_PrecacheString]](&"CUSTOM_CLAN1_MESSAGE_1");
				if(level.ex_clanmsgs[1] >= 2) [[level.ex_PrecacheString]](&"CUSTOM_CLAN1_MESSAGE_2");
				if(level.ex_clanmsgs[1] >= 3) [[level.ex_PrecacheString]](&"CUSTOM_CLAN1_MESSAGE_3");
			}

			if(level.ex_clantags[2] != "")
			{
				if(level.ex_clanmsgs[2] >= 1) [[level.ex_PrecacheString]](&"CUSTOM_CLAN2_MESSAGE_1");
				if(level.ex_clanmsgs[2] >= 2) [[level.ex_PrecacheString]](&"CUSTOM_CLAN2_MESSAGE_2");
				if(level.ex_clanmsgs[2] >= 3) [[level.ex_PrecacheString]](&"CUSTOM_CLAN2_MESSAGE_3");
			}

			if(level.ex_clantags[3] != "")
			{
				if(level.ex_clanmsgs[3] >= 1) [[level.ex_PrecacheString]](&"CUSTOM_CLAN3_MESSAGE_1");
				if(level.ex_clanmsgs[3] >= 2) [[level.ex_PrecacheString]](&"CUSTOM_CLAN3_MESSAGE_2");
				if(level.ex_clanmsgs[3] >= 3) [[level.ex_PrecacheString]](&"CUSTOM_CLAN3_MESSAGE_3");
			}

			if(level.ex_clantags[4] != "")
			{
				if(level.ex_clanmsgs[4] >= 1) [[level.ex_PrecacheString]](&"CUSTOM_CLAN4_MESSAGE_1");
				if(level.ex_clanmsgs[4] >= 2) [[level.ex_PrecacheString]](&"CUSTOM_CLAN4_MESSAGE_2");
				if(level.ex_clanmsgs[4] >= 3) [[level.ex_PrecacheString]](&"CUSTOM_CLAN4_MESSAGE_3");
			}
		}

		[[level.ex_PrecacheString]](&"CUSTOM_VOTE_ALLOWED");
		[[level.ex_PrecacheString]](&"CUSTOM_VOTE_NOT_ALLOWED");
	}

	// arcade style HUD announcement of points scored for kills
	if(level.ex_arcade_score)
	{
		[[level.ex_PrecacheString]](&"MP_PLUS");
		[[level.ex_PrecacheString]](&"MP_MINUS");
	}

	// server redirection
	if(level.ex_redirect)
	{
		[[level.ex_PrecacheString]](&"REDIRECT_TITLE");
		[[level.ex_PrecacheString]](&"REDIRECT_TIMELEFT");

		if(level.ex_redirect_reason == 0 || level.ex_redirect_reason == 1)
			[[level.ex_PrecacheString]](&"REDIRECT_REASON_ISFULL");

		if(level.ex_redirect_reason == 0 || level.ex_redirect_reason == 1 || level.ex_redirect_reason == 3)
		{
			[[level.ex_PrecacheString]](&"REDIRECT_TO_OTHERSERVER");
			if(level.ex_redirect_hint) [[level.ex_PrecacheString]](&"REDIRECT_HINT_VISITWEBSITE");
		}

		if(level.ex_redirect_reason == 1)
		{
			[[level.ex_PrecacheString]](&"REDIRECT_REASON_ISPRIVATE");
			[[level.ex_PrecacheString]](&"REDIRECT_TO_PUBLICSERVER");
		}

		if(level.ex_redirect_reason == 2)
		{
			[[level.ex_PrecacheString]](&"REDIRECT_REASON_ISOLD");
			[[level.ex_PrecacheString]](&"REDIRECT_TO_NEWSERVER");
			if(level.ex_redirect_hint) [[level.ex_PrecacheString]](&"REDIRECT_HINT_ADDTOFAV");
		}

		if(level.ex_redirect_reason == 3) [[level.ex_PrecacheString]](&"REDIRECT_REASON_ISSERVICED");

		if(level.ex_redirect_priority)
		{
			[[level.ex_PrecacheString]](&"REDIRECT_REASON_CLANPRIORITY");
			[[level.ex_PrecacheString]](&"REDIRECT_CLAN_FREEUPSLOT");
			[[level.ex_PrecacheString]](&"REDIRECT_CLAN_ABORTED");
			[[level.ex_PrecacheString]](&"REDIRECT_CLAN_PLEASEWAIT");
			[[level.ex_PrecacheString]](&"REDIRECT_CLAN_CONTINUE");

			if(level.ex_redirect_hint)
			{
				[[level.ex_PrecacheString]](&"REDIRECT_HINT_SORRY");
				[[level.ex_PrecacheString]](&"REDIRECT_HINT_PRIORITY");
				[[level.ex_PrecacheString]](&"REDIRECT_HINT_EXTREME");
			}
		}
	}

	// round based game type round number text
	if(level.ex_roundbased || level.ex_currentgt == "lib")
	{
		[[level.ex_PrecacheString]](&"MISC_ROUNDNUMBER");
		[[level.ex_PrecacheString]](&"MISC_LASTROUND");
	}

	// halftime
	if(level.ex_swapteams)
	{
		if(level.ex_roundbased) [[level.ex_PrecacheString]](&"MISC_SWAPTEAM");
		else
		{
			[[level.ex_PrecacheString]](&"MISC_CLOCK_1H");
			[[level.ex_PrecacheString]](&"MISC_CLOCK_2H");
			[[level.ex_PrecacheString]](&"MISC_HALFTIME");
		}
		[[level.ex_PrecacheString]](&"MISC_SWAPTEAM_SWITCH");
		[[level.ex_PrecacheString]](&"MISC_SWAPTEAM_CONTINUE");
	}

	// overtime
	if(level.ex_overtime)
	{
		[[level.ex_PrecacheString]](&"MISC_CLOCK_OT");
		[[level.ex_PrecacheString]](&"MISC_OVERTIME");
		[[level.ex_PrecacheString]](&"MISC_OVERTIME_MINUTES");
		if(level.ex_currentgt == "ctf" || level.ex_currentgt == "ctfb") [[level.ex_PrecacheString]](&"MISC_OVERTIME_FIRSTCAP");
		if(level.ex_overtime_lastman)
		{
			[[level.ex_PrecacheString]](&"MISC_OVERTIME_LASTTEAM");
			[[level.ex_PrecacheString]](&"MISC_OVERTIME_WAIT");
		}
	}

	// stats board
	if(level.ex_stbd)
	{
		// initializing
		[[level.ex_PrecacheString]](&"MISC_INITIALIZING");

		// title
		[[level.ex_PrecacheString]](&"STATSBOARD_TITLE");
		[[level.ex_PrecacheString]](&"STATSBOARD_HOWTO");
		[[level.ex_PrecacheString]](&"STATSBOARD_TIMELEFT");
		[[level.ex_PrecacheString]](&"STATSBOARD_PLAYERLEFT");

		// kills and deaths categories
		if(level.ex_stbd_kd)
		{
			[[level.ex_PrecacheString]](&"STATSBOARD_HEADER_KD");
			[[level.ex_PrecacheString]](&"STATSBOARD_KILLS_DEATHS");
			[[level.ex_PrecacheString]](&"STATSBOARD_GRENADES");
			if(level.ex_tripwire) [[level.ex_PrecacheString]](&"STATSBOARD_TRIPWIRES");
			[[level.ex_PrecacheString]](&"STATSBOARD_HEADSHOTS");
			[[level.ex_PrecacheString]](&"STATSBOARD_BASHES");
			[[level.ex_PrecacheString]](&"STATSBOARD_SNIPERS");
			[[level.ex_PrecacheString]](&"STATSBOARD_KNIVES");
			if(level.ex_wmd || level.ex_mortars == 2) [[level.ex_PrecacheString]](&"STATSBOARD_MORTARS");
			if(level.ex_wmd || level.ex_artillery == 2) [[level.ex_PrecacheString]](&"STATSBOARD_ARTILLERY");
			if(level.ex_wmd || level.ex_planes == 3) [[level.ex_PrecacheString]](&"STATSBOARD_AIRSTRIKES");
			if(level.ex_wmd) [[level.ex_PrecacheString]](&"STATSBOARD_NAPALM");
			[[level.ex_PrecacheString]](&"STATSBOARD_PANZERS");
			if(level.ex_landmines) [[level.ex_PrecacheString]](&"STATSBOARD_LANDMINES");
			[[level.ex_PrecacheString]](&"STATSBOARD_FIRENADES");
			[[level.ex_PrecacheString]](&"STATSBOARD_GASNADES");
			[[level.ex_PrecacheString]](&"STATSBOARD_FLAMETHROWERS");
			[[level.ex_PrecacheString]](&"STATSBOARD_SATCHELCHARGES");
			if(level.ex_gunship || level.ex_gunship_special) [[level.ex_PrecacheString]](&"STATSBOARD_GUNSHIP");
			[[level.ex_PrecacheString]](&"STATSBOARD_SPAM_KILLS");
			[[level.ex_PrecacheString]](&"STATSBOARD_TEAM_KILLS");
			[[level.ex_PrecacheString]](&"STATSBOARD_FALLING_DEATHS");
			[[level.ex_PrecacheString]](&"STATSBOARD_MINEFIELD_DEATHS");
			[[level.ex_PrecacheString]](&"STATSBOARD_SUICIDE_DEATHS");
			//[[level.ex_PrecacheString]](&"STATSBOARD_SPAWN");
		}

		// score, efficiency and bonus points
		if(level.ex_stbd_se)
		{
			if(level.ex_flagbased)
			{
				[[level.ex_PrecacheString]](&"STATSBOARD_HEADER_FL");
				[[level.ex_PrecacheString]](&"STATSBOARD_FLAGS");
			}
			[[level.ex_PrecacheString]](&"STATSBOARD_HEADER_SE");
			[[level.ex_PrecacheString]](&"STATSBOARD_SCORE_EFFICIENCY");
			[[level.ex_PrecacheString]](&"STATSBOARD_HEADER_BP");
			[[level.ex_PrecacheString]](&"STATSBOARD_BONUS");
		}
	}

	// sprint
	if(level.ex_sprint && level.ex_sprinthudhint)
	{
		[[level.ex_PrecacheString]](&"SPRINT_HINT");
	}

	// weapons of mass destruction
	if(level.ex_wmd)
	{
		[[level.ex_PrecacheString]](&"WMD_MORTAR_HINT");
		[[level.ex_PrecacheString]](&"WMD_ARTILLERY_HINT");
		[[level.ex_PrecacheString]](&"WMD_AIRSTRIKE_HINT");
		[[level.ex_PrecacheString]](&"WMD_NAPALM_HINT");
	}

	if(level.ex_wmd || level.ex_gunship)
	{
		[[level.ex_PrecacheString]](&"WMD_GUNSHIP_HINT");
		[[level.ex_PrecacheString]](&"WMD_ACTIVATE_HINT");
	}

	// medic system
	if(level.ex_medicsystem)
	{
		[[level.ex_PrecacheString]](&"FIRSTAID_MEDI");
		[[level.ex_PrecacheString]](&"FIRSTAID_DISABLED");
	}

	// tripwire messages
	if(level.ex_tripwire)
	{
		[[level.ex_PrecacheString]](&"TRIPWIRE_PLANT");
		[[level.ex_PrecacheString]](&"TRIPWIRE_PLANTING");
		[[level.ex_PrecacheString]](&"TRIPWIRE_DEFUSE");
		[[level.ex_PrecacheString]](&"TRIPWIRE_DEFUSING");
		[[level.ex_PrecacheString]](&"TRIPWIRE_HOLD_MELEE");
		[[level.ex_PrecacheString]](&"TRIPWIRE_HOLD_COMBO");
		[[level.ex_PrecacheString]](&"TRIPWIRE_HOLD_SMOKE");
		[[level.ex_PrecacheString]](&"TRIPWIRE_HOLD_FRAG");
		[[level.ex_PrecacheString]](&"TRIPWIRE_RELEASE_PROCEED");
	}

	// server messages: rotation
	if(level.ex_svrmsg && level.ex_svrmsg_info && !level.ex_mapvote)
	{
		// pre-cache strings for map announcement system
		if(level.ex_svrmsg_info == 1 || level.ex_svrmsg_info == 3) [[level.ex_PrecacheString]](&"MAPROTATION_NEXT_MAP");
		if(level.ex_svrmsg_info >= 2)
		{
			[[level.ex_PrecacheString]](&"MAPROTATION_CUSTOM_NEXT");
			[[level.ex_PrecacheString]](&"MAPROTATION_NEXT_GT");
		}
		if(level.ex_svrmsg_rotation) [[level.ex_PrecacheString]](&"MAPROTATION_TITLE");
	}

	// map voting
	if(level.ex_mapvote)
	{
		// initializing
		[[level.ex_PrecacheString]](&"MISC_INITIALIZING");

		// pre-cache strings for extended map voting system
		[[level.ex_PrecacheString]](&"MAPVOTE_TITLE");
		[[level.ex_PrecacheString]](&"MAPVOTE_HEADERS");
		[[level.ex_PrecacheString]](&"MAPVOTE_HOWTO");
		[[level.ex_PrecacheString]](&"MAPVOTE_TIMELEFT");
		[[level.ex_PrecacheString]](&"MAPVOTE_INPROGRESS");
		[[level.ex_PrecacheString]](&"MAPVOTE_NOTALLOWED");
		[[level.ex_PrecacheString]](&"MAPVOTE_PLEASEWAIT");
		[[level.ex_PrecacheString]](&"MAPVOTE_PAGE");
		[[level.ex_PrecacheString]](&"MAPVOTE_WINNER");
		if(level.ex_mapvotereplay) [[level.ex_PrecacheString]](&"MAPVOTE_REPLAY");
	}

	if((level.ex_mapvote && level.ex_mapvotemode < 4) || (level.ex_svrmsg && level.ex_svrmsg_info && level.ex_svrmsg_rotation))
	{
		// pre-cache game type abbreviations for extended map voting system
		[[level.ex_PrecacheString]](&"MPUI_CHQ");
		[[level.ex_PrecacheString]](&"MPUI_CNQ");
		[[level.ex_PrecacheString]](&"MPUI_CTF");
		[[level.ex_PrecacheString]](&"MPUI_CTFB");
		[[level.ex_PrecacheString]](&"MPUI_DM");
		[[level.ex_PrecacheString]](&"MPUI_DOM");
		[[level.ex_PrecacheString]](&"MPUI_ESD");
		[[level.ex_PrecacheString]](&"MPUI_FT");
		[[level.ex_PrecacheString]](&"MPUI_HM");
		[[level.ex_PrecacheString]](&"MPUI_HQ");
		[[level.ex_PrecacheString]](&"MPUI_HTF");
		[[level.ex_PrecacheString]](&"MPUI_IHTF");
		[[level.ex_PrecacheString]](&"MPUI_LIB");
		[[level.ex_PrecacheString]](&"MPUI_LMS");
		[[level.ex_PrecacheString]](&"MPUI_LTS");
		[[level.ex_PrecacheString]](&"MPUI_ONS");
		[[level.ex_PrecacheString]](&"MPUI_RBCNQ");
		[[level.ex_PrecacheString]](&"MPUI_RBCTF");
		[[level.ex_PrecacheString]](&"MPUI_SD");
		[[level.ex_PrecacheString]](&"MPUI_TDM");
		[[level.ex_PrecacheString]](&"MPUI_VIP");
		[[level.ex_PrecacheString]](&"MPUI_TKOTH");
		[[level.ex_PrecacheString]](&"MPUI_UNKNOWN_GT_SHORT");
	}

	if((level.ex_mapvote && level.ex_mapvotemode >= 4) || (level.ex_svrmsg && level.ex_svrmsg_info >= 2))
	{
		// pre-cache game types for extended map voting system
		[[level.ex_PrecacheString]](&"MPUI_CLASSIC_HEADQUARTERS");
		[[level.ex_PrecacheString]](&"MPUI_CONQUEST");
		[[level.ex_PrecacheString]](&"MPUI_CAPTURE_THE_FLAG");
		[[level.ex_PrecacheString]](&"MPUI_CAPTURE_THE_FLAG_BACK");
		[[level.ex_PrecacheString]](&"MPUI_DEATHMATCH");
		[[level.ex_PrecacheString]](&"MPUI_DOMINATION");
		[[level.ex_PrecacheString]](&"MPUI_ENHANCED_SD");
		[[level.ex_PrecacheString]](&"MPUI_FREEZETAG");
		[[level.ex_PrecacheString]](&"MPUI_HITMAN");
		[[level.ex_PrecacheString]](&"MPUI_HEADQUARTERS");
		[[level.ex_PrecacheString]](&"MPUI_HOLD_THE_FLAG");
		[[level.ex_PrecacheString]](&"MPUI_I_HOLD_THE_FLAG");
		[[level.ex_PrecacheString]](&"MPUI_LIBERATION");
		[[level.ex_PrecacheString]](&"MPUI_LAST_MAN_STANDING");
		[[level.ex_PrecacheString]](&"MPUI_LAST_TEAM_STANDING");
		[[level.ex_PrecacheString]](&"MPUI_ONSLAUGHT");
		[[level.ex_PrecacheString]](&"MPUI_ROUNDBASED_CNQ");
		[[level.ex_PrecacheString]](&"MPUI_ROUNDBASED_CTF");
		[[level.ex_PrecacheString]](&"MPUI_SEARCH_AND_DESTROY");
		[[level.ex_PrecacheString]](&"MPUI_TEAM_DEATHMATCH");
		[[level.ex_PrecacheString]](&"MPUI_VERY_IMPORTANT_PERSON");
		[[level.ex_PrecacheString]](&"MPUI_TEAM_KING_OF_THE_HILL");
		[[level.ex_PrecacheString]](&"MPUI_UNKNOWN_GT_LONG");
	}

	// spawn protection
	if(level.ex_spwn_time)
	{
		[[level.ex_PrecacheString]](&"SPAWNPROTECTION_TIME");
		[[level.ex_PrecacheString]](&"SPAWNPROTECTION_RANGE");
	}

	// sinbin: teamkill punishment
	if(level.ex_sinbin)
	{
		[[level.ex_PrecacheString]](&"SINBIN_FREEZE");
		[[level.ex_PrecacheString]](&"SINBIN_FREEFALL");
	}

	// spectator music control messages
	if(level.ex_specmusic)
	{
		[[level.ex_PrecacheString]](&"MISC_MELEE_CHANGE_MUSIC");
		[[level.ex_PrecacheString]](&"MISC_MUSIC_CHNG");
	}

	// range finder
	if(level.ex_rangefinder)
	{
		if(level.ex_rangefinder_units == 1) [[level.ex_PrecacheString]](&"MISC_RANGE");
			else [[level.ex_PrecacheString]](&"MISC_RANGE2");
	}

	// unfixed turrets
	if(level.ex_turrets > 1)
	{
		[[level.ex_PrecacheString]](&"TURRET_MELEE_TO_PICKUP");
		[[level.ex_PrecacheString]](&"TURRET_MELEE_TO_PLANT");
		[[level.ex_PrecacheString]](&"TURRET_DEPLANT");
		[[level.ex_PrecacheString]](&"TURRET_PLANTING");
		[[level.ex_PrecacheString]](&"TURRET_USE_SHOW_ICON");
		[[level.ex_PrecacheString]](&"TURRET_TOO_CLOSE");
		[[level.ex_PrecacheString]](&"TURRET_TOO_FAR");
	}

	// landmines
	if(level.ex_landmines)
	{
		[[level.ex_PrecacheString]](&"LANDMINES_PLANT");
		[[level.ex_PrecacheString]](&"LANDMINES_PLANTING");
		[[level.ex_PrecacheString]](&"LANDMINES_DEFUSE");
		[[level.ex_PrecacheString]](&"LANDMINES_DEFUSING");
	}

	// retreat monitor
	if(level.ex_flag_retreat)
	{
		if((level.ex_flag_retreat & 4) == 4) [[level.ex_PrecacheString]](&"MISC_FLAG_RETREAT");
		if((level.ex_flag_retreat & 16) == 16) [[level.ex_PrecacheString]](&"MISC_FLAG_BRINGIN");
	}

	// store
	if(level.ex_store && (level.ex_store_payment || level.ex_teamplay))
	{
		if(level.ex_store_currency == 1) [[level.ex_PrecacheString]](&"SPECIALS_CURRENCY_SIGN_LEFT");
			else if(level.ex_store_currency == 2) [[level.ex_PrecacheString]](&"SPECIALS_CURRENCY_SIGN_RIGHT");
	}

	// kill confirmed mode
	if(level.ex_kc)
	{
		if((level.ex_kc_confirm_msg & 2) == 2)
		{
			[[level.ex_PrecacheString]](&"MISC_KCA_HUD");
			if(level.ex_kc > 1)
			{
				[[level.ex_PrecacheString]](&"MISC_KCC_HUD");
				[[level.ex_PrecacheString]](&"MISC_KCA_PROXY_HUD");
			}
		}
		if((level.ex_kc_confirm_msg & 8) == 8) [[level.ex_PrecacheString]](&"MISC_KCV_HUD");

		if((level.ex_kc_denied_msg & 2) == 2)
		{
			[[level.ex_PrecacheString]](&"MISC_KDV_HUD");
			if(level.ex_kc_denied > 2)
			{
				[[level.ex_PrecacheString]](&"MISC_KDC_HUD");
				[[level.ex_PrecacheString]](&"MISC_KDV_PROXY_HUD");
			}
		}
		if((level.ex_kc_denied_msg & 8) == 8) [[level.ex_PrecacheString]](&"MISC_KDA_HUD");
	}

	// pre-cache weapon modes for extended map voting system
	if(level.ex_mapvote && level.ex_mapvoteweaponmode)
	{
		wm_array = strtok(tolower(level.ex_mapvoteweaponmode_allow), " ");
		if(isDefined(wm_array) && wm_array.size)
		{
			level.weaponmodes = [];
			level.weaponmodenames = [];

			// precache regular weapon mode string
			weaponmodes = [];
			for(i = 0; i < wm_array.size; i++)
			{
				if(!isDefined(level.weaponmodes[wm_array[i]]))
				{
					index = initWeaponMode(wm_array[i]);
					if(index != -1) weaponmodes[weaponmodes.size] = index;
				}
				else weaponmodes[weaponmodes.size] = level.weaponmodes[wm_array[i]].index;
			}

			if(weaponmodes.size)
			{
				level.wmodes = "";
				for(j = 0; j < weaponmodes.size; j++)
				{
					level.wmodes = level.wmodes + weaponmodes[j];
					if(j < (weaponmodes.size - 1)) level.wmodes = level.wmodes + " ";
				}
				//logprint("MAPVOTE: Weapon modes string converted into ID string: " + level.wmodes + "\n");

				// precache weapon mode strings defined in map voting list
				if(level.ex_mapvotemode >= 4 && isDefined(level.ex_maps))
				{
					for(i = 0; i < level.ex_maps.size; i++)
					{
						if(isDefined(level.ex_maps[i].weaponmode))
						{
							wm_array = strtok(tolower(level.ex_maps[i].weaponmode), " ");
							if(isDefined(wm_array) && wm_array.size)
							{
								weaponmodes = [];
								for(j = 0; j < wm_array.size; j++)
								{
									if(!isDefined(level.weaponmodes[wm_array[j]]))
									{
										index = initWeaponMode(wm_array[j]);
										if(index != -1) weaponmodes[weaponmodes.size] = index;
									}
									else weaponmodes[weaponmodes.size] = level.weaponmodes[wm_array[j]].index;
								}

								if(weaponmodes.size)
								{
									level.ex_maps[i].wmodes = "";
									for(j = 0; j < weaponmodes.size; j++)
									{
										level.ex_maps[i].wmodes = level.ex_maps[i].wmodes + weaponmodes[j];
										if(j < (weaponmodes.size - 1)) level.ex_maps[i].wmodes = level.ex_maps[i].wmodes + " ";
									}
									if(level.ex_log_mapvote) logprint("MPV: Weapon modes string for map " + level.ex_maps[i].mapname + " converted into ID string: " + level.ex_maps[i].wmodes + "\n");
								}
								else logprint("MPV: Map " + level.ex_maps[i].mapname + " has no valid weapon modes; using default instead\n");
							}
							else logprint("MPV: Map " + level.ex_maps[i].mapname + " has an empty weapon modes string; using default instead\n");
						}
					}
				}
			}
			else
			{
				level.ex_mapvoteweaponmode = 0;
				logprint("MPV: No valid weapon modes found; weapon mode voting disabled\n");
			}
		}
		else
		{
			level.ex_mapvoteweaponmode = 0;
			logprint("MPV: Weapon modes string empty; weapon mode voting disabled\n");
		}
	}

	// pre-cache map long names for extended map voting system and map rotation info
	if(level.ex_mapvote || (level.ex_svrmsg && (level.ex_svrmsg_info == 1 || level.ex_svrmsg_info == 3)) )
	{
		for(i = 0; i < level.ex_maps.size; i++) [[level.ex_PrecacheString]](level.ex_maps[i].loclname);
	}
}

initPost()
{
	if(level.ex_ranksystem && level.ex_rank_hudicons == 2)
	{
		switch(game["allies"])
		{
			case "american":
			{
				[[level.ex_PrecacheString]](&"RANK_AMERICAN_7"); // General
				[[level.ex_PrecacheString]](&"RANK_AMERICAN_6"); // Colonel
				[[level.ex_PrecacheString]](&"RANK_AMERICAN_5"); // Major
				[[level.ex_PrecacheString]](&"RANK_AMERICAN_4"); // Captain
				[[level.ex_PrecacheString]](&"RANK_AMERICAN_3"); // Lieutenant
				[[level.ex_PrecacheString]](&"RANK_AMERICAN_2"); // Sergeant
				[[level.ex_PrecacheString]](&"RANK_AMERICAN_1"); // Corporal
				[[level.ex_PrecacheString]](&"RANK_AMERICAN_0"); // Private
				break;
			}

			case "british":
			{
				[[level.ex_PrecacheString]](&"RANK_BRITISH_7"); // General
				[[level.ex_PrecacheString]](&"RANK_BRITISH_6"); // Colonel
				[[level.ex_PrecacheString]](&"RANK_BRITISH_5"); // Major
				[[level.ex_PrecacheString]](&"RANK_BRITISH_4"); // Captain
				[[level.ex_PrecacheString]](&"RANK_BRITISH_3"); // Lieutenant
				[[level.ex_PrecacheString]](&"RANK_BRITISH_2"); // Sergeant
				[[level.ex_PrecacheString]](&"RANK_BRITISH_1"); // Corporal
				[[level.ex_PrecacheString]](&"RANK_BRITISH_0"); // Private
				break;
			}

			default:
			{
				[[level.ex_PrecacheString]](&"RANK_RUSSIAN_7"); // General-Poruchik
				[[level.ex_PrecacheString]](&"RANK_RUSSIAN_6"); // Polkovnik
				[[level.ex_PrecacheString]](&"RANK_RUSSIAN_5"); // Mayor
				[[level.ex_PrecacheString]](&"RANK_RUSSIAN_4"); // Kapitan
				[[level.ex_PrecacheString]](&"RANK_RUSSIAN_3"); // Leytenant
				[[level.ex_PrecacheString]](&"RANK_RUSSIAN_2"); // Podpraporshchik
				[[level.ex_PrecacheString]](&"RANK_RUSSIAN_1"); // Kapral
				[[level.ex_PrecacheString]](&"RANK_RUSSIAN_0"); // Soldat
				break;
			}
		}

		[[level.ex_PrecacheString]](&"RANK_GERMAN_7"); // General
		[[level.ex_PrecacheString]](&"RANK_GERMAN_6"); // Oberst
		[[level.ex_PrecacheString]](&"RANK_GERMAN_5"); // Major
		[[level.ex_PrecacheString]](&"RANK_GERMAN_4"); // Hauptmann
		[[level.ex_PrecacheString]](&"RANK_GERMAN_3"); // Leutnant
		[[level.ex_PrecacheString]](&"RANK_GERMAN_2"); // Unterfeldwebel
		[[level.ex_PrecacheString]](&"RANK_GERMAN_1"); // Unteroffizier
		[[level.ex_PrecacheString]](&"RANK_GERMAN_0"); // Grenadier

		[[level.ex_PrecacheString]](&"RANK_RANK");
	}

	if(level.ex_amc)
	{
		[[level.ex_PrecacheString]](&"AMMOCRATE_REARMING_WEAPONS");
		[[level.ex_PrecacheString]](&"AMMOCRATE_REARMING_GRENADES");
		if(level.ex_medicsystem) [[level.ex_PrecacheString]](&"AMMOCRATE_REARMING_FIRSTAID");

		if(level.ex_amc_msg >= 2)
		{
			switch(game["allies"])
			{
				case "american": [[level.ex_PrecacheString]](&"AMMOCRATE_DENY_AMERICAN"); break;
				case "british": [[level.ex_PrecacheString]](&"AMMOCRATE_DENY_BRITISH"); break;
				default: [[level.ex_PrecacheString]](&"AMMOCRATE_DENY_RUSSIAN"); break;
			}

			[[level.ex_PrecacheString]](&"AMMOCRATE_DENY_GERMAN");
			[[level.ex_PrecacheString]](&"AMMOCRATE_ACTIVATE");
		}
	}
}

initWeaponMode(weaponmode)
{
	switch(weaponmode)
	{
		case "team":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 0;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_TEAM";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "class1":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 1;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_CLASS1";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "class2":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 2;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_CLASS2";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "class3":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 3;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_CLASS3";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "class4":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 4;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_CLASS4";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "class5":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 5;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_CLASS5";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "class6":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 6;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_CLASS6";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "class7":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 7;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_CLASS7";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "class8":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 8;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_CLASS8";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "class9":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 9;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_CLASS9";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "class10":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 10;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_CLASS10";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "all":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 11;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_ALL";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "modern":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 12;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_MODERN";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "mclass1":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 13;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_MODERN_CLASS1";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "mclass2":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 14;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_MODERN_CLASS2";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "mclass3":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 15;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_MODERN_CLASS3";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "mclass4":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 16;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_MODERN_CLASS4";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "mclass7":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 17;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_MODERN_CLASS7";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "mclass8":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 18;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_MODERN_CLASS8";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "mclass10":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 19;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_MODERN_CLASS10";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "bash":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 20;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_BASH";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "frag":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 21;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_FRAG";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "random":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 99;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_RANDOM";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "server":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 100;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_SERVER";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		default:
			logprint("MPV: Invalid weapon mode <" + weaponmode + "> defined. Please check your weapon mode settings!\n");
			return(-1);
	}
}
