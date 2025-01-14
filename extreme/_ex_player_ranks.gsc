#include extreme\_ex_controller_hud;
#include extreme\_ex_player_wmd;

main()
{
	self endon("kill_thread");

	if(!isDefined(self.pers["rank"])) self.pers["rank"] = self getRank();

	self waittill("spawned_player");

	if(level.ex_rank_statusicons) playerHudSetStatusIcon(getStatusIcon());

	while(isPlayer(self) && !level.ex_gameover)
	{
		self.pers["newrank"] = self getRank();

		// if old rank isn't the same as the new rank check
		if(self.pers["rank"] != self.pers["newrank"])
		{
			if(self.pers["rank"] < self.pers["newrank"])
			{
				// PROMOTED: update here, so the weapon update is based on the new rank
				self.pers["rank"] = self.pers["newrank"];
				self thread rankUpdate(true);
			}
			else if(self.pers["rank"] > self.pers["newrank"])
			{
				// DEMOTED: update here, so the weapon update is based on the new rank
				self.pers["rank"] = self.pers["newrank"];
				self thread rankUpdate(false);
			}
		}

		// check WMD
		if(level.ex_wmd == 2 && !isDefined(self.pers["isbot"])) self thread checkWmd(self.pers["rank"]);

		// if player is in gunship, suspend rank updates until old weapons are restored
		while( (level.ex_gunship && isPlayer(level.gunship.owner) && level.gunship.owner == self) ||
		       (level.ex_gunship_special && isPlayer(level.gunship_special.owner) && level.gunship_special.owner == self) ) wait( level.ex_fps_frame );

		wait( [[level.ex_fpstime]](1) );
	}
}

rankUpdate(promotion)
{
	self endon("disconnect");
	
	// update status icon
	if(level.ex_rank_statusicons) playerHudSetStatusIcon(getStatusIcon());

	// update head icon
	if(level.ex_rank_headicons) playerHudSetHeadIcon(getHeadIcon());

	// update HUD icon
	if(level.ex_rank_hudicons) self thread rankHud();

	rankstring = self getRankstring();

	while(self.sessionstate != "playing") wait( [[level.ex_fpstime]](0.5) );

	if(promotion)
	{
		if(level.ex_rank_announce == 1)
		{
			self iprintlnbold(&"RANK_PROMOTION_MSG", [[level.ex_pname]](self));
			self iprintlnbold(&"RANK_PROMOTION_START", &"RANK_MIDDLE_MSG", rankstring);
			self playLocalSound("promotion");
		}

		// check for stand-alone gunship perk
		if(level.ex_gunship == 2 && self.pers["rank"] >= level.ex_gunship_rank)
		{
			grant = true;
			// check if player already got the gunship once
			if(level.ex_gunship_rank_once && isDefined(self.pers["gunship"])) grant = false;
			// if player is making kills from within the gunship now, deny another gunship
			if( (isPlayer(level.gunship.owner) && level.gunship.owner == self) ||
			  (level.ex_gunship_special && isPlayer(level.gunship_special.owner) && level.gunship_special.owner == self) ) grant = false;

			if(grant) self thread extreme\_ex_main_gunship::gunshipPerk(1);
		}

		if(level.ex_rank_update_loadout) self extreme\_ex_weapons::updateLoadout(true);
	}
	else
	{
		if(level.ex_rank_announce == 1)
		{
			self iprintlnbold(&"RANK_DEMOTION_MSG", [[level.ex_pname]](self));
			self iprintlnbold(&"RANK_DEMOTION_START", &"RANK_MIDDLE_MSG", rankstring);
			self playLocalSound("demotion");
		}

		if(level.ex_wmd == 2) self wmdStop();
		if(level.ex_rank_update_loadout) self extreme\_ex_weapons::updateLoadout(false);
	}
}

rankHud()
{
	level endon("ex_gameover");
	self endon("disconnect");

	if(level.ex_rank_hudicons == 2)
	{
		hud_index = playerHudCreate("rank_text", 10, 474, 1, (1,1,1), 0.8, 0, "fullscreen", "fullscreen", "left", "middle", false, false);
		if(hud_index == -1) return;
		playerHudSetLabel(hud_index, &"RANK_RANK");
		rankstring = self getRankstring();
		playerHudSetText(hud_index, rankstring);
	}

	hud_index = playerHudCreate("rank_icon", 120, 420, level.ex_iconalpha, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index == -1) return;
	chevron = self getHudIcon();
	playerHudSetShader(hud_index, chevron, 32, 32);
	playerHudScale(hud_index, .5, 0, 24, 24);
}

getRank()
{
	self endon("disconnect");

	// check if player has a preset rank
	if(!isDefined(self.pers["preset_rank"])) self.pers["preset_rank"] = self checkPresetRank();

	// determine rank using
	points = game["rank_" + self.pers["preset_rank"]];
	if(level.ex_rank_score == 0)
	{
		points = points + self.pers["score"];
		if(level.ex_store && level.ex_store_payment == 0) points = points + self.pers["cash_spent"];
	}
	else if(level.ex_rank_score == 1)
	{
		points = points + (self.pers["kill"] + self.pers["special"]) - (self.pers["teamkill"] + self.pers["death"]);
	}
	else
	{
		// self.pers["special"] is included in self.pers["bonus"]
		points = points + (self.pers["kill"] + self.pers["bonus"]) - (self.pers["teamkill"] + self.pers["death"]);
		if(level.ex_store && level.ex_store_payment == 1) points = points + self.pers["cash_spent"];
	}

	if(points >= game["rank_7"]) return(7);
	else if(points >= game["rank_6"] && points < game["rank_7"]) return(6);
	else if(points >= game["rank_5"] && points < game["rank_6"]) return(5);
	else if(points >= game["rank_4"] && points < game["rank_5"]) return(4);
	else if(points >= game["rank_3"] && points < game["rank_4"]) return(3);
	else if(points >= game["rank_2"] && points < game["rank_3"]) return(2);
	else if(points >= game["rank_1"] && points < game["rank_2"]) return(1);
	else return(0);
}

getRankstring()
{
	self endon("disconnect");

	rank = &"RANK_AMERICAN_0";

	if(self.pers["team"] == "allies")
	{				
		switch(game["allies"])
		{
			case "american":
			{
				switch(self.pers["rank"])
				{
					case 7: rank = &"RANK_AMERICAN_7"; break; // General
					case 6: rank = &"RANK_AMERICAN_6"; break; // Colonel
					case 5: rank = &"RANK_AMERICAN_5"; break; // Major
					case 4: rank = &"RANK_AMERICAN_4"; break; // Captain
					case 3: rank = &"RANK_AMERICAN_3"; break; // Lieutenant
					case 2: rank = &"RANK_AMERICAN_2"; break; // Sergeant
					case 1: rank = &"RANK_AMERICAN_1"; break; // Corporal
					case 0: rank = &"RANK_AMERICAN_0"; break; // Private
				}
				break;
			}	
			
			case "british":
			{
				switch(self.pers["rank"])
				{
					case 7: rank = &"RANK_BRITISH_7"; break; // General
					case 6: rank = &"RANK_BRITISH_6"; break; // Colonel
					case 5: rank = &"RANK_BRITISH_5"; break; // Major
					case 4: rank = &"RANK_BRITISH_4"; break; // Captain
					case 3: rank = &"RANK_BRITISH_3"; break; // Lieutenant
					case 2: rank = &"RANK_BRITISH_2"; break; // Sergeant
					case 1: rank = &"RANK_BRITISH_1"; break; // Corporal
					case 0: rank = &"RANK_BRITISH_0"; break; // Private
				}
				break;
			}
			
			case "russian":
			{
				switch(self.pers["rank"])
				{
					case 7: rank = &"RANK_RUSSIAN_7"; break; // General-Poruchik
					case 6: rank = &"RANK_RUSSIAN_6"; break; // Polkovnik
					case 5: rank = &"RANK_RUSSIAN_5"; break; // Mayor
					case 4: rank = &"RANK_RUSSIAN_4"; break; // Kapitan
					case 3: rank = &"RANK_RUSSIAN_3"; break; // Leytenant
					case 2: rank = &"RANK_RUSSIAN_2"; break; // Podpraporshchik
					case 1: rank = &"RANK_RUSSIAN_1"; break; // Kapral
					case 0: rank = &"RANK_RUSSIAN_0"; break; // Soldat
				}
				break;
			}
		}
	}
	else if(self.pers["team"] == "axis")
	{
		switch(game["axis"])
		{
			case "german":
			{
				switch(self.pers["rank"])
				{
					case 7: rank = &"RANK_GERMAN_7"; break; // General
					case 6: rank = &"RANK_GERMAN_6"; break; // Oberst
					case 5: rank = &"RANK_GERMAN_5"; break; // Major
					case 4: rank = &"RANK_GERMAN_4"; break; // Hauptmann
					case 3: rank = &"RANK_GERMAN_3"; break; // Leutnant
					case 2: rank = &"RANK_GERMAN_2"; break; // Unterfeldwebel
					case 1: rank = &"RANK_GERMAN_1"; break; // Unteroffizier
					case 0: rank = &"RANK_GERMAN_0"; break; // Grenadier
				}
				break;
			}
		}
	}

	return(rank);
}

getHudIcon()
{
	self endon("disconnect");

	if(!isDefined(self.pers) || !isDefined(self.pers["rank"]) || !isDefined(self.pers["team"]) || self.pers["team"] == "spectator") return("");
	return( game["hudicon_rank" + self.pers["rank"]] );
}

getStatusIcon()
{
	self endon("disconnect");

	if(!isDefined(self.pers) || !isDefined(self.pers["rank"]) || !isDefined(self.pers["team"]) || self.pers["team"] == "spectator") return("");
	return( game["statusicon_rank" + self.pers["rank"]] );
}

getHeadIcon()
{
	self endon("disconnect");

	if(!isDefined(self.pers) || !isDefined(self.pers["rank"]) || !isDefined(self.pers["team"]) || self.pers["team"] == "spectator") return("");
	return( game["headicon_rank" + self.pers["rank"]] );
}

checkPresetRank()
{
	self endon("disconnect");

	count = 0;
	clan_check = "";

	if(isDefined(self.ex_clanNM))
	{
		// convert the players clan name
		playerclan = extreme\_ex_main_utils::convertMLJ(self.ex_clanNM);

		for(;;)
		{
			// get the preset clan name
			clan_check = [[level.ex_drm]]("ex_psr_clan_" + count, "", "", "", "string");

			// check if there is a preset clan name, if not end here!
			if(clan_check == "") break;

			// convert clan name
			clan_check = extreme\_ex_main_utils::convertMLJ(clan_check);

			// if the names match, break here and set rank
			if(clan_check == playerclan) break;
				else count ++;
		}
	}

	if(clan_check != "") return( [[level.ex_drm]]("ex_psr_rank_" + count, 0, 0, 8, "int") );

	// convert the players name
	playername = extreme\_ex_main_utils::convertMLJ(self.name);

	count = 0;

	for(;;)
	{
		// get the preset player name
		name_check = [[level.ex_drm]]("ex_psr_name_" + count, "", "", "", "string");

		// check if there is a preset player name, if not end here!
		if(name_check == "") break;

		// convert name_check
		name_check = extreme\_ex_main_utils::convertMLJ(name_check);

		// if the names match, break here and set rank
		if(name_check == playername) break;
			else count ++;
	}

	if(name_check == "") return(0);
		else return( [[level.ex_drm]]("ex_psr_rank_" + count, 0, 0, 8, "int") );
}
