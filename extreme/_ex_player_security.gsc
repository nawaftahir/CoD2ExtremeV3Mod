#include extreme\_ex_main_utils;

init()
{
	// Store Non Grata tags
	level.ex_nongrata_tags = [];
	count = 0;
	for(;;)
	{
		tag = [[level.ex_drm]]("ex_nongrata_tag_" + count, "", "", "", "string");
		if(tag == "") break;
		tag = monoString(tag);
		if(level.ex_nongrata == 1) tag = toLower(tag);
		level.ex_nongrata_tags[level.ex_nongrata_tags.size] = tag;
		count++;
	}

	// Store Non Grata names
	level.ex_nongrata_names = [];
	count = 0;
	for(;;)
	{
		name = [[level.ex_drm]]("ex_nongrata_name_" + count, "", "", "", "string");
		if(name == "") break;
		name = monoString(name);
		if(level.ex_nongrata == 1) name = toLower(name);
		level.ex_nongrata_names[level.ex_nongrata_names.size] = name;
		count++;
	}

	// Store Non Grata GUIDs
	level.ex_nongrata_guids = [];
	count = 0;
	for(;;)
	{
		guid = [[level.ex_drm]]("ex_nongrata_guid_" + count, 0, 0, 9999999, "int");
		if(!guid) break;
		level.ex_nongrata_guids[level.ex_nongrata_guids.size] = guid;
		count++;
	}

	// Check error message
	title = trim(level.ex_nongrata_title);
	if(title == "") level.ex_nongrata_title = "Persona Non Grata";
	msg = trim(level.ex_nongrata_msg);
	if(msg == "") level.ex_nongrata_msg = "You have been disconnected from the server because you are deemed Persona Non Grata!";
}

main()
{
	self endon("disconnect");

	// check persona non grata status
	if(level.ex_nongrata) self checkPersonaNonGrata();

	// check what clan they are in
	if(!isDefined(self.ex_clanID)) self extreme\_ex_player_security::checkClan();

	// check if this is an authorized member
	if(level.ex_checkmembers) self checkMembers();

	// check if guid number is authorised for extra privileges
	if(level.ex_security && !self checkGuid())
	{
		self.ex_clanNM = "";
		self.ex_clanID = 0;
	}

	// init vars for bad word filer
	self.pers["badword_status"] = 0;
}

checkPersonaNonGrata()
{
	non_grata = false;

	// prepare player info
	playername = monoString(self.name);
	if(level.ex_nongrata == 1) playername = toLower(playername);
	playerguid = self getGuid();

	// Check tags
	for(i = 0; i < level.ex_nongrata_tags.size; i++)
	{
		if(playername.size <= level.ex_nongrata_tags[i].size) continue;
		sizediff = playername.size - level.ex_nongrata_tags[i].size;

		cnfront = "";
		cnback = "";
		for(j = 0; j < level.ex_nongrata_tags[i].size; j++)
		{
			cnfront += playername[j];
			cnback  += playername[sizediff + j];
		}

		if(cnfront == level.ex_nongrata_tags[i] || cnback == level.ex_nongrata_tags[i])
		{
			non_grata = true;
			break;
		}
	}

	// Check names
	if(!non_grata)
	{
		for(i = 0; i < level.ex_nongrata_names.size; i++)
		{
			if(playername == level.ex_nongrata_names[i])
			{
				non_grata = true;
				break;
			}
		}
	}

	// Check GUIDs
	if(!non_grata && playerguid)
	{
		for(i = 0; i < level.ex_nongrata_guids.size; i++)
		{
			if(playerguid == level.ex_nongrata_guids[i])
			{
				non_grata = true;
				break;
			}
		}
	}

	// Disconnect player if non grata
	if(non_grata)
	{
		self setClientCvar("com_errorTitle", level.ex_nongrata_title);
		self setClientCvar("com_errorMessage", level.ex_nongrata_msg);
		wait( [[level.ex_fpstime]](1) );
		self thread execClientCommand("disconnect");
	}
}

checkGuid()
{
	self endon("disconnect");

	playerGuid = self getGuid();

	if(!playerGuid) return(false);

	count = 0;
		
	for(;;)
	{
		guid = [[level.ex_drm]]("ex_guid_" + count, 0, 0, 9999999, "int");

		if(!guid) break;
			else if(guid == playerGuid) return(true);
				else count ++;
	}

	return(false);
}

checkClan()
{
	self endon("disconnect");

	self.ex_clanID = 0;
	self.ex_clanNM = "";

	clan_num = false;
	for(i = 1; i <= 4; i++)
	{
		if(checkClanID(i))
		{
			clan_num = i;
			break;
		}
	}

	if(!clan_num) return;

	self.ex_clanID = clan_num;
	self.ex_clanNM = level.ex_clantags[clan_num];

	return;
}

checkClanID(check)
{
	// decolorize name and tag
	namestr = monoString(self.name);
	tagstr = monoString(level.ex_clantags[check]);

	if(namestr.size <= tagstr.size) return(false);
	sizediff = namestr.size - tagstr.size;

	// check clan tag in front or at end of player's name
	cnfront = "";
	cnback = "";
	for(i = 0; i < tagstr.size; i++)
	{
		cnfront += namestr[i];
		cnback  += namestr[sizediff + i];
	}

	if(cnfront == tagstr || cnback == tagstr) return(true);

	return(false);
}

checkMembers()
{
	if(self.ex_clanID && self.ex_clanID <= level.ex_checkmembers)
	{
		// decolorize name
		name_nocol = monoString(self.name);

		count = 0;
		for(;;)
		{
			member_nocol = [[level.ex_drm]]("ex_member_name_" + count, "", "", "", "string");
			if(member_nocol == "") break;
			if(member_nocol == name_nocol) break;
				else count++;
		}

		if(member_nocol == "")
		{
			self setClientCvar("com_errorTitle", "eXtreme+ Message");
			self setClientCvar("com_errorMessage", "You have been disconnected from the server\ndue to illegal clan tag usage!\nYou can reconnect to our server after removing our clan tag from your name.");
			wait( [[level.ex_fpstime]](1) );
			self thread execClientCommand("disconnect");
		}
	}
}

checkIgnoreInactivity()
{
	self endon("disconnect");

	self.pers["dontkick"] = false;

	count = 0;
	clan_check = "";

	if(self.ex_clanID)
	{
		// convert the clan name
		playerclan = convertMLJ(self.ex_clanNM);

		for(;;)
		{
			// get the preset clan name
			clan_check = [[level.ex_drm]]("ex_inactive_exclude_clan_" + count, "", "", "", "string");

			// check if there is a preset clan name, if not end here!
			if(clan_check == "") break;

			// convert clan name
			clan_check = convertMLJ(clan_check);

			// if the names match, break here and set kick status
			if(clan_check == playerclan) break;
				else count++;
		}
	}

	if(clan_check != "")
	{
		self.pers["dontkick"] = true;
		return;
	}

	// convert the players name
	playername = convertMLJ(self.name);

	count = 0;
		
	for(;;)
	{
		// get the preset player name
		name_check = [[level.ex_drm]]("ex_inactive_exclude_name_" + count, "", "", "", "string");

		// check if there is a preset player name, if not end here!
		if(name_check == "") break;

		// convert name_check
		name_check = convertMLJ(name_check);

		// if the names match, break here and set kick status
		if(name_check == playername) break;
			else count++;
	}

	if(name_check != "")
		self.pers["dontkick"] = true;
}
