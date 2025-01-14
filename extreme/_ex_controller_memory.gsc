#include extreme\_ex_main_utils;

memInit()
{
	if(level.ex_log_memory) logprint("MEM: Initializing memory controller\n");

	// Create global memory array
	if(!isDefined(game["memory"])) game["memory"] = [];

	memRegisterSet("memory", "memory/%MEMNAME%-memory");
	memRegisterItem("memory", "version", "no", 1, 0, 999, "int");
	memRegisterItem("memory", "cinematic", "status", 0, 0, 1, "bool");
	memRegisterItem("memory", "lrbind", "key", "m", "1234567890abcdefghijklmnopqrstuvwxyz", "", "char");
	memRegisterItem("memory", "jukebox", "status", level.ex_jukebox_power, 0, 1, "bool");
	memRegisterItem("memory", "jukebox", "loop", 0 ,0 ,1, "bool");
	memRegisterItem("memory", "jukebox", "shuffle", 0, 0, 1, "bool");
	memRegisterItem("memory", "jukebox", "track", 1, 1, 99, "int");
	memRegisterItem("memory", "zoom", "sr", level.ex_zoom_default_sr, level.ex_zoom_min_sr, level.ex_zoom_max_sr, "int");
	memRegisterItem("memory", "zoom", "lr", level.ex_zoom_default_lr, level.ex_zoom_min_lr, level.ex_zoom_max_lr, "int");
	memRegisterItem("memory", "account", "name", "****", "", "", "string");
	memRegisterItem("memory", "account", "password", "****", "", "", "string");
	memRegisterItem("memory", "account", "cash", 0, 0, level.ex_store_maxcash, "int");
	memRegisterItem("memory", "rcon", "pin", "****", "", "", "string");
	memRegisterItem("memory", "geo", "ip", "0.0.0.0", "", "", "string");
	memRegisterItem("memory", "geo", "country", "UNKNOWN", "", "", "string");
	memRegisterItem("memory", "total", "points", 0, 0, level.MAX_SIGNED_INT, "int");
	memRegisterItem("memory", "total", "kills", 0, 0, level.MAX_SIGNED_INT, "int");
	memRegisterItem("memory", "total", "deaths", 0, 0, level.MAX_SIGNED_INT, "int");
	memRegisterItem("memory", "total", "bonus", 0, 0, level.MAX_SIGNED_INT, "int");
	memRegisterItem("memory", "total", "special", 0, 0, level.MAX_SIGNED_INT, "int");
	memRegisterItem("memory", "total", "time", 0, 0, level.MAX_SIGNED_INT, "int");

	if(level.ex_accounts)
	{
		memRegisterSet("accounting", "accounts/%ACCNAME%-account");
		memRegisterItem("accounting", "version", "no", 1, 0, 999, "int");
		memRegisterItem("accounting", "account", "password", "****", "", "", "string");
		memRegisterItem("accounting", "account", "creator", "****", "", "", "string");
		memRegisterItem("accounting", "account", "cash", 0, 0, level.ex_store_maxcash, "int");
	}

	if(level.ex_scorememory)
	{
		if(!isDefined(game["scorememory"])) game["scorememory"] = [];
		[[level.ex_registerLevelEvent]]("onSecond", ::onSecond);
	}
}

//------------------------------------------------------------------------------
// Set handling
//------------------------------------------------------------------------------
memSetIndex(setID)
{
	if(!isDefined(setID) || !isString(setID) || setID == "") return(-1);
	setID = tolower(setID);
	for(set_index = 0; set_index < game["memory"].size; set_index++)
		if(game["memory"][set_index].setID == setID) return(set_index);
	return(-1);
}

memRegisterSet(setID, file_template)
{
	if(!isDefined(setID) || !isString(setID) || setID == "") return(-1);
	if(!isDefined(file_template)) file_template = "";

	set_index = memSetIndex(setID);
	if(set_index == -1)
	{
		set_index = game["memory"].size;
		game["memory"][set_index] = spawnstruct();
		game["memory"][set_index].setID = tolower(setID);
		game["memory"][set_index].file_template = file_template;
		game["memory"][set_index].groups = [];
	}
	return(set_index);
}

//------------------------------------------------------------------------------
// Group handling
//------------------------------------------------------------------------------
_memGroupIndex(set_index, groupID)
{
	if(!isDefined(groupID) || !isString(groupID) || groupID == "") return(-1);
	groupID = tolower(groupID);
	for(grp_index = 0; grp_index < game["memory"][set_index].groups.size; grp_index++)
		if(game["memory"][set_index].groups[grp_index].groupID == groupID) return(grp_index);
	return(-1);
}

memGroupIndex(setID, groupID)
{
	set_index = memSetIndex(setID);
	if(set_index == -1) return(-1);

	grp_index = _memGroupIndex(set_index, groupID);
	return(grp_index);
}

memRegisterGroup(setID, groupID)
{
	set_index = memRegisterSet(setID);
	if(set_index == -1) return(-1);

	grp_index = _memGroupIndex(set_index, groupID);
	if(grp_index == -1)
	{
		grp_index = game["memory"][set_index].groups.size;
		game["memory"][set_index].groups[grp_index] = spawnstruct();
		game["memory"][set_index].groups[grp_index].groupID = tolower(groupID);
		game["memory"][set_index].groups[grp_index].items = [];
	}
	return(grp_index);
}

//------------------------------------------------------------------------------
// Item handling
//------------------------------------------------------------------------------
_memItemIndex(set_index, grp_index, itemID)
{
	if(!isDefined(itemID) || !isString(itemID) || itemID == "") return(-1);
	itemID = tolower(itemID);
	for(itm_index = 0; itm_index < game["memory"][set_index].groups[grp_index].items.size; itm_index++)
		if(game["memory"][set_index].groups[grp_index].items[itm_index].itemID == itemID) return(itm_index);
	return(-1);
}

memItemIndex(setID, groupID, itemID)
{
	set_index = memSetIndex(setID);
	if(set_index == -1) return(-1);

	grp_index = _memGroupIndex(set_index, groupID);
	if(grp_index == -1) return(-1);

	itm_index = _memItemIndex(set_index, grp_index, itemID);
	return(itm_index);
}

// memRegisterItem(setID, groupID, itemID, itemDef, itemMin, itemMax, itemType)
// itemType: "int", "bool", "char", "float", "string"
// itemMin on itemType "char" can be used as a string with valid characters
// string defaults should not be empty (messes up parser which delimits on spaces)
memRegisterItem(setID, groupID, itemID, itemDef, itemMin, itemMax, itemType)
{
	if(!isDefined(itemType)) return(-1);

	set_index = memRegisterSet(setID);
	if(set_index == -1) return(-1);

	grp_index = memRegisterGroup(setID, groupID);
	if(grp_index == -1) return(-1);

	itemType = tolower(itemType);
	if(itemType != "int" && itemType != "char" && itemType != "bool" && itemType != "float" && itemType != "string") return(-1);

	if(!isDefined(itemMin))
	{
		if(itemType == "int" || itemType == "bool" || itemType == "float") itemMin = 0;
		else if(itemType == "char" || itemType == "string") itemMin = "";
	}

	if(!isDefined(itemMax))
	{
		if(itemType == "int" || itemType == "float") itemMax = 999;
		else if(itemType == "bool") itemMax = 1;
		else if(itemType == "char" || itemType == "string") itemMax = "";
	}

	if(!isDefined(itemDef))
	{
		if(itemType == "int" || itemType == "bool" || itemType == "float") itemDef = 0;
		else if(itemType == "char" || itemType == "string") itemDef = "";
	}

	if(itemType == "int" || itemType == "bool" || itemType == "float")
	{
		if(itemDef < itemMin) itemDef = itemMin;
		else if(itemDef > itemMax) itemDef = itemMax;
	}

	itm_index = _memItemIndex(set_index, grp_index, itemID);
	if(itm_index == -1)
	{
		itm_index = game["memory"][set_index].groups[grp_index].items.size;
		game["memory"][set_index].groups[grp_index].items[itm_index] = spawnstruct();
		game["memory"][set_index].groups[grp_index].items[itm_index].itemID = tolower(itemID);
		game["memory"][set_index].groups[grp_index].items[itm_index].min = itemMin;
		game["memory"][set_index].groups[grp_index].items[itm_index].max = itemMax;
		game["memory"][set_index].groups[grp_index].items[itm_index].def = itemDef;
		game["memory"][set_index].groups[grp_index].items[itm_index].type = itemType;
	}
	return(itm_index);
}

//------------------------------------------------------------------------------
// Initialize player memory structure and load "memory" set
//------------------------------------------------------------------------------
playerInit()
{
	if(!isPlayer(self)) return;

	self.pers["memory"] = [];

	// create player memory structure and populate with default values
	for(set_index = 0; set_index < game["memory"].size; set_index++)
	{
		self.pers["memory"][set_index] = spawnstruct();
		self.pers["memory"][set_index].file_path = "";
		self.pers["memory"][set_index].file_loaded = false;
		self.pers["memory"][set_index].dirty = false;
		self.pers["memory"][set_index].groups = [];

		for(grp_index = 0; grp_index < game["memory"][set_index].groups.size; grp_index++)
		{
			self.pers["memory"][set_index].groups[grp_index] = spawnstruct();
			self.pers["memory"][set_index].groups[grp_index].items = [];

			for(itm_index = 0; itm_index < game["memory"][set_index].groups[grp_index].items.size; itm_index++)
			{
				self.pers["memory"][set_index].groups[grp_index].items[itm_index] = spawnstruct();
				self.pers["memory"][set_index].groups[grp_index].items[itm_index].infile = false;
				self.pers["memory"][set_index].groups[grp_index].items[itm_index].val = game["memory"][set_index].groups[grp_index].items[itm_index].def;
			}
		}
	}

	self loadMemorySet("memory");
}

//------------------------------------------------------------------------------
// Loading, getting, setting and saving
//------------------------------------------------------------------------------
getFileFromTemplate(set_index)
{
	// if file has been loaded already, return set file name
	if(self.pers["memory"][set_index].file_loaded) return(self.pers["memory"][set_index].file_path);

	// check for valid template
	file_template = game["memory"][set_index].file_template;
	if(!isDefined(file_template) || !isString(file_template) || file_template == "") return("");

	// split template into parts
	parts = [];
	parts_index = parts.size;
	parts[parts_index] = spawnstruct();
	parts[parts_index].str = "";
	parts[parts_index].exp = false;
	parts_invar = false;
	for(i = 0; i < file_template.size; i++)
	{
		chr = file_template[i];
		if(chr == "%")
		{
			if(parts_invar) parts[parts_index].exp = true;
				else parts_invar = true;

			parts_index = parts.size;
			parts[parts_index] = spawnstruct();
			parts[parts_index].str = "";
			parts[parts_index].exp = false;
		}
		else parts[parts_index].str += chr;
	}

	// prepare template variables
	player_name = sanitizeName(self.name);
	player_guid = self getGuid();

	memory_name = player_name;
	if(player_guid)
	{
		switch(level.ex_memory_filename)
		{
			case 1:
				memory_name = "" + player_guid;
				break;
			case 2:
				memory_name = "" + player_guid + "-" + player_name;
				break;
		}
	}

	account_name = player_name;
	if(level.ex_accounts && game["memory"][set_index].setID != "memory")
	{
		account_name = self.pers["account"]["name_entry"];
		memory = self extreme\_ex_controller_memory::getMemory("memory", "account", "name");
		if(!memory.error && memory.value != memory.def) account_name = memory.value;
	}

	// replace template variables
	for(i = 0; i < parts.size; i++)
	{
		if(parts[i].exp)
		{
			switch(tolower(parts[i].str))
			{
				case "memname":
					parts[i].str = memory_name;
					break;
				case "accname":
					parts[i].str = account_name;
					break;
				case "nameguid":
					if(player_guid) parts[i].str = player_name + "-" + player_guid;
					break;
				case "guidname":
					if(player_guid) parts[i].str = "" + player_guid + "-" + player_name;
					break;
				case "guid":
					if(player_guid) parts[i].str = "" + player_guid;
					break;
				case "name":
				default:
					parts[i].str = player_name;
			}
		}
	}

	// reconstruct file name out of parts
	file_path = "";
	for(i = 0; i < parts.size; i++) file_path += parts[i].str;

	return(file_path);
}

memorySetExists(setID)
{
	// checking for valid set
	set_index = memSetIndex(setID);
	if(set_index == -1) return(false);

	// handle file name from template (temp)
	if(self.pers["memory"][set_index].file_path != "") file_path = self.pers["memory"][set_index].file_path;
		else file_path = getFileFromTemplate(set_index);

	// process memory file
	file_handle = openfile(file_path, "read");
	if(file_handle == -1) return(false);
	closefile(file_handle);
	return(true);
}

loadMemorySet(setID, file_forceload)
{
	// checking for valid set
	set_index = memSetIndex(setID);
	if(set_index == -1) return;

	// prevent unnecessary file operations
	if(!isDefined(file_forceload)) file_forceload = false;
	if(self.pers["memory"][set_index].file_loaded && !file_forceload) return;

	// handle file name from template (permanent)
	if(self.pers["memory"][set_index].file_path == "")
	{
		file_path = getFileFromTemplate(set_index);
		self.pers["memory"][set_index].file_path = file_path;
	}
	else file_path = self.pers["memory"][set_index].file_path;

	// process memory file
	file_handle = openfile(file_path, "read");
	if(file_handle == -1) return;

	self.pers["memory"][set_index].file_loaded = true;

	// 0 = old version, 1 = new version (old will be converted to new)
	version_handling = 0;

	for(;;)
	{
		farg = freadln(file_handle);
		if(farg == -1) break;
		if(farg == 0) continue;

		mline = fgetarg(file_handle, 0);
		if(level.ex_log_memory) logprint("MEM: [READ] " + mline + "\n");
		token_array = strtok(mline, " ");

		grp_index = -1;
		itm_index = 0;
		token_expect = "VER";
		for(token_index = 0; token_index < token_array.size; token_index++)
		{
			token = token_array[token_index];
			//if(level.ex_log_memory) logprint("MEM: Found token \"" + token + "\" (" + token_index + ")\n");
			switch(token_expect)
			{
				case "VER":
					grp_index = _memGroupIndex(set_index, token);
					if(grp_index != -1)
					{
						if(game["memory"][set_index].groups[grp_index].groupID == "version")
						{
							if(level.ex_log_memory) logprint("MEM: Found version identifier \"" + token + "\" (" + token_index + ")\n");
							version_handling = 1;
							token_expect = "ITM";
						}
						else
						{
							if(level.ex_log_memory) logprint("MEM: Found group identifier \"" + token + "\" (" + token_index + ")\n");
							self.pers["memory"][set_index].dirty = true;
							token_expect = "VAL";
							itm_index = 0;
						}
					}
					else
					{
						if(level.ex_log_memory) logprint("MEM: Expected group identifier, but got \"" + token + "\" (" + token_index + ")\n");
						self.pers["memory"][set_index].dirty = true;
						token_expect = "GRP";
					}
					break;
				case "ITM":
					itm_index = _memItemIndex(set_index, grp_index, token);
					if(itm_index != -1)
					{
						if(level.ex_log_memory) logprint("MEM: Found item identifier \"" + token + "\" (" + token_index + ")\n");
						token_expect = "VAL";
						break;
					}
					else
					{
						if(level.ex_log_memory) logprint("MEM: Expected item identifier, but got \"" + token + "\" (" + token_index + ")\n");
						self.pers["memory"][set_index].dirty = true;
						token_expect = "GRP";
						// no break so it switches to GRP inspection right away
					}
				case "GRP":
					grp_index = _memGroupIndex(set_index, token);
					if(grp_index != -1)
					{
						if(level.ex_log_memory) logprint("MEM: Found group identifier \"" + token + "\" (" + token_index + ")\n");
						if(version_handling == 0)
						{
							token_expect = "VAL";
							itm_index = 0;
						}
						else token_expect = "ITM";
					}
					else
					{
						if(level.ex_log_memory) logprint("MEM: Expected group identifier, but got \"" + token + "\" (" + token_index + ")\n");
						self.pers["memory"][set_index].dirty = true;
					}
					break;
				case "VAL":
					// it should not check for min and max when loading vars into memory!
					if(grp_index != -1 && (version_handling != 0 || itm_index < game["memory"][set_index].groups[grp_index].items.size))
					{
						type_expect = game["memory"][set_index].groups[grp_index].items[itm_index].type;
						if(level.ex_log_memory) logprint("MEM: Expecting " + type_expect + " (" + (itm_index+1) + " out of " + game["memory"][set_index].groups[grp_index].items.size + " values)\n");
						switch(type_expect)
						{
							case "int":
								if(isIntStr(token))
								{
									if(level.ex_log_memory) logprint("MEM: Found integer \"" + token + "\" (" + token_index + ")\n");
									if(game["memory"][set_index].groups[grp_index].groupID == "version")
									{
										if(int(token) > version_handling) version_handling = int(token);
										self.pers["memory"][set_index].groups[grp_index].items[itm_index].val = version_handling;
										self.pers["memory"][set_index].groups[grp_index].items[itm_index].infile = true;
									}
									else
									{
										self.pers["memory"][set_index].groups[grp_index].items[itm_index].val = int(token);
										self.pers["memory"][set_index].groups[grp_index].items[itm_index].infile = true;
									}
								}
								else if(level.ex_log_memory) logprint("MEM: Expected integer, but got \"" + token + "\". Keeping default \"" + self.pers["memory"][set_index].groups[grp_index].items[itm_index].val + "\"\n");
								break;
							case "float":
								if(isFloatStr(token))
								{
									if(level.ex_log_memory) logprint("MEM: Found float \"" + token + "\" (" + token_index + ")\n");
									self.pers["memory"][set_index].groups[grp_index].items[itm_index].val = strToFloat(token);
									self.pers["memory"][set_index].groups[grp_index].items[itm_index].infile = true;
								}
								else if(level.ex_log_memory) logprint("MEM: Expected float, but got \"" + token + "\". Keeping default \"" + self.pers["memory"][set_index].groups[grp_index].items[itm_index].val + "\"\n");
								break;
							case "bool":
								if(isBoolStr(token))
								{
									if(level.ex_log_memory) logprint("MEM: Found bool \"" + token + "\" (" + token_index + ")\n");
									self.pers["memory"][set_index].groups[grp_index].items[itm_index].val = int(token);
									self.pers["memory"][set_index].groups[grp_index].items[itm_index].infile = true;
								}
								else if(level.ex_log_memory) logprint("MEM: Expected bool, but got \"" + token + "\". Keeping default \"" + self.pers["memory"][set_index].groups[grp_index].items[itm_index].val + "\"\n");
								break;
							case "char":
								if(isValidChar(token))
								{
									if(level.ex_log_memory) logprint("MEM: Found char \"" + token + "\" (" + token_index + ")\n");
									self.pers["memory"][set_index].groups[grp_index].items[itm_index].val = token;
									self.pers["memory"][set_index].groups[grp_index].items[itm_index].infile = true;
								}
								else if(level.ex_log_memory) logprint("MEM: Expected char, but got \"" + token + "\". Keeping default \"" + self.pers["memory"][set_index].groups[grp_index].items[itm_index].val + "\"\n");
								break;
							case "string":
								if(isValidStr(token))
								{
									if(level.ex_log_memory) logprint("MEM: Found string \"" + token + "\" (" + token_index + ")\n");
									self.pers["memory"][set_index].groups[grp_index].items[itm_index].val = token;
									self.pers["memory"][set_index].groups[grp_index].items[itm_index].infile = true;
								}
								else if(level.ex_log_memory) logprint("MEM: Expected string, but got \"" + token + "\". Keeping default \"" + self.pers["memory"][set_index].groups[grp_index].items[itm_index].val + "\"\n");
								break;
						}

						itm_index++;
						if(itm_index >= game["memory"][set_index].groups[grp_index].items.size) token_expect = "GRP";
							else if(version_handling > 0) token_expect = "ITM";
					}
					else token_expect = "GRP";
					break;
			}
		}
	}

	closefile(file_handle);
}

saveMemorySets()
{
	for(set_index = 0; set_index < game["memory"].size; set_index++)
		saveMemorySet(game["memory"][set_index].setID);
}

saveMemorySet(setID)
{
	// checking for valid set
	set_index = memSetIndex(setID);
	if(set_index == -1) return;

	if(self.pers["memory"][set_index].dirty)
	{
		file_handle = openfile(self.pers["memory"][set_index].file_path, "write");
		if(file_handle != -1)
		{
			mem_line = "";
			for(grp_index = 0; grp_index < game["memory"][set_index].groups.size; grp_index++)
			{
				groupID = game["memory"][set_index].groups[grp_index].groupID;
				values = "";
				for(itm_index = 0; itm_index < game["memory"][set_index].groups[grp_index].items.size; itm_index++)
				{
					itemID = game["memory"][set_index].groups[grp_index].items[itm_index].itemID;
					if(values != "") values += " ";
					values += itemID + " " + self.pers["memory"][set_index].groups[grp_index].items[itm_index].val;
				}
				if(mem_line != "") mem_line += " ";
				mem_line += groupID + " " + values;
			}

			if(level.ex_log_memory) logprint("MEM: [WRITE] " + mem_line + "\n");
			fprintln(file_handle, mem_line);
			closefile(file_handle);
			self.pers["memory"][set_index].dirty = false;
		}
	}
}

setDefault(setID, groupID, itemID, delay_write)
{
	if(!isDefined(setID) || !isDefined(groupID) || !isDefined(itemID)) return;
	if(setID == "" || groupID == "" || itemID == "") return;

	// delayed write is enabled if not specified
	if(!isDefined(delay_write)) delay_write = true;

	// check for valid set
	set_index = memSetIndex(setID);
	if(set_index == -1) return;
	setID = tolower(setID);

	grp_index = _memGroupIndex(set_index, groupID);
	if(grp_index == -1) return;
	groupID = tolower(groupID);

	itemID = tolower(itemID);
	itm_index = _memItemIndex(set_index, grp_index, itemID);
	if(itm_index == -1) return;

	// setMemory will check for min and max. It will keep current value if out of bounds
	type_expect = game["memory"][set_index].groups[grp_index].items[itm_index].type;
	token = game["memory"][set_index].groups[grp_index].items[itm_index].def;
	switch(type_expect)
	{
		case "int":
			if(isIntStr(token))
			{
				token_int = int(token);
				if(token_int != self.pers["memory"][set_index].groups[grp_index].items[itm_index].val)
				{
					if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " to \"" + token + "\"\n");
					self.pers["memory"][set_index].groups[grp_index].items[itm_index].val = token_int;
					self.pers["memory"][set_index].dirty = true;
				}
				else if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " ignored. Already set to \"" + token + "\"\n");
			}
			else if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " expected integer, but got \"" + token + "\". Keeping current \"" + self.pers["memory"][set_index].groups[grp_index].items[itm_index].val + "\"\n");
			break;
		case "float":
			if(isFloatStr(token))
			{
				token_float = strToFloat(token);
				if(token_float != self.pers["memory"][set_index].groups[grp_index].items[itm_index].val)
				{
					if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " to \"" + token + "\"\n");
					self.pers["memory"][set_index].groups[grp_index].items[itm_index].val = token_float;
					self.pers["memory"][set_index].dirty = true;
				}
				else if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " ignored. Already set to \"" + token + "\"\n");
			}
			else if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " expected float, but got \"" + token + "\". Keeping current \"" + self.pers["memory"][set_index].groups[grp_index].items[itm_index].val + "\"\n");
			break;
		case "bool":
			if(isBoolStr(token))
			{
				token_int = int(token);
				if(token_int != self.pers["memory"][set_index].groups[grp_index].items[itm_index].val)
				{
					if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " to \"" + token + "\"\n");
					self.pers["memory"][set_index].groups[grp_index].items[itm_index].val = token_int;
					self.pers["memory"][set_index].dirty = true;
				}
				else if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " ignored. Already set to \"" + token + "\"\n");
			}
			else if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " expected bool, but got \"" + token + "\". Keeping current \"" + self.pers["memory"][set_index].groups[grp_index].items[itm_index].val + "\"\n");
			break;
		case "char":
			if(isValidChar(token, game["memory"][set_index].groups[grp_index].items[itm_index].min))
			{
				if(token != self.pers["memory"][set_index].groups[grp_index].items[itm_index].val)
				{
					if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " to \"" + token + "\"\n");
					self.pers["memory"][set_index].groups[grp_index].items[itm_index].val = token;
					self.pers["memory"][set_index].dirty = true;
				}
				else if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " ignored. Already set to \"" + token + "\"\n");
			}
			else if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " expected char, but got \"" + token + "\". Keeping current \"" + self.pers["memory"][set_index].groups[grp_index].items[itm_index].val + "\"\n");
			break;
		case "string":
			if(isValidStr(token))
			{
				if(token != self.pers["memory"][set_index].groups[grp_index].items[itm_index].val)
				{
					if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " to \"" + token + "\"\n");
					self.pers["memory"][set_index].groups[grp_index].items[itm_index].val = token;
					self.pers["memory"][set_index].dirty = true;
				}
				else if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " ignored. Already set to \"" + token + "\"\n");
			}
			else if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " expected string, but got \"" + token + "\". Keeping current \"" + self.pers["memory"][set_index].groups[grp_index].items[itm_index].val + "\"\n");
			break;
	}

	if(self.pers["memory"][set_index].dirty && !delay_write) saveMemorySet(setID);
}

setMemory(setID, groupID, itemID, itemVal, delay_write)
{
	if(!isDefined(setID) || !isDefined(groupID) || !isDefined(itemID)) return;
	if(setID == "" || groupID == "" || itemID == "") return;

	// delayed write is enabled if not specified
	if(!isDefined(delay_write)) delay_write = true;

	// check for valid set
	set_index = memSetIndex(setID);
	if(set_index == -1) return;
	setID = tolower(setID);

	grp_index = _memGroupIndex(set_index, groupID);
	if(grp_index == -1) return;
	groupID = tolower(groupID);

	itemID = tolower(itemID);
	itm_index = _memItemIndex(set_index, grp_index, itemID);
	if(itm_index == -1) return;

	// setMemory will check for min and max. It will keep current value if out of bounds
	type_expect = game["memory"][set_index].groups[grp_index].items[itm_index].type;
	token = asString(itemVal);
	switch(type_expect)
	{
		case "int":
			if(isIntStr(token))
			{
				token_int = int(token);
				if(token_int >= game["memory"][set_index].groups[grp_index].items[itm_index].min && token_int <= game["memory"][set_index].groups[grp_index].items[itm_index].max)
				{
					if(token_int != self.pers["memory"][set_index].groups[grp_index].items[itm_index].val)
					{
						if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " to \"" + token + "\"\n");
						self.pers["memory"][set_index].groups[grp_index].items[itm_index].val = token_int;
						self.pers["memory"][set_index].dirty = true;
					}
					else if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " ignored. Already set to \"" + token + "\"\n");
				}
				else if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " ignored. Value \"" + token + "\" out of bounce. Keeping current \"" + self.pers["memory"][set_index].groups[grp_index].items[itm_index].val + "\"\n");
			}
			else if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " expected integer, but got \"" + token + "\". Keeping current \"" + self.pers["memory"][set_index].groups[grp_index].items[itm_index].val + "\"\n");
			break;
		case "float":
			if(isFloatStr(token))
			{
				token_float = strToFloat(token);
				if(token_float >= game["memory"][set_index].groups[grp_index].items[itm_index].min && token_float <= game["memory"][set_index].groups[grp_index].items[itm_index].max)
				{
					if(token_float != self.pers["memory"][set_index].groups[grp_index].items[itm_index].val)
					{
						if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " to \"" + token + "\"\n");
						self.pers["memory"][set_index].groups[grp_index].items[itm_index].val = token_float;
						self.pers["memory"][set_index].dirty = true;
					}
					else if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " ignored. Already set to \"" + token + "\"\n");
				}
				else if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " ignored. Value \"" + token + "\" out of bounce. Keeping current \"" + self.pers["memory"][set_index].groups[grp_index].items[itm_index].val + "\"\n");
			}
			else if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " expected float, but got \"" + token + "\". Keeping current \"" + self.pers["memory"][set_index].groups[grp_index].items[itm_index].val + "\"\n");
			break;
		case "bool":
			if(isBoolStr(token))
			{
				token_int = int(token);
				if(token_int != self.pers["memory"][set_index].groups[grp_index].items[itm_index].val)
				{
					if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " to \"" + token + "\"\n");
					self.pers["memory"][set_index].groups[grp_index].items[itm_index].val = token_int;
					self.pers["memory"][set_index].dirty = true;
				}
				else if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " ignored. Already set to \"" + token + "\"\n");
			}
			else if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " expected bool, but got \"" + token + "\". Keeping current \"" + self.pers["memory"][set_index].groups[grp_index].items[itm_index].val + "\"\n");
			break;
		case "char":
			if(isValidChar(token, game["memory"][set_index].groups[grp_index].items[itm_index].min))
			{
				if(token != self.pers["memory"][set_index].groups[grp_index].items[itm_index].val)
				{
					if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " to \"" + token + "\"\n");
					self.pers["memory"][set_index].groups[grp_index].items[itm_index].val = token;
					self.pers["memory"][set_index].dirty = true;
				}
				else if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " ignored. Already set to \"" + token + "\"\n");
			}
			else if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " expected char, but got \"" + token + "\". Keeping current \"" + self.pers["memory"][set_index].groups[grp_index].items[itm_index].val + "\"\n");
			break;
		case "string":
			if(isValidStr(token))
			{
				if(token != self.pers["memory"][set_index].groups[grp_index].items[itm_index].val)
				{
					if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " to \"" + token + "\"\n");
					self.pers["memory"][set_index].groups[grp_index].items[itm_index].val = token;
					self.pers["memory"][set_index].dirty = true;
				}
				else if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " ignored. Already set to \"" + token + "\"\n");
			}
			else if(level.ex_log_memory) logprint("MEM: Set " + setID + "\\" + groupID + "\\" + itemID + " expected string, but got \"" + token + "\". Keeping current \"" + self.pers["memory"][set_index].groups[grp_index].items[itm_index].val + "\"\n");
			break;
	}

	if(self.pers["memory"][set_index].dirty && !delay_write) saveMemorySet(setID);
}

getMemory(setID, groupID, itemID)
{
	memory = spawnstruct();
	memory.error = 1;
	memory.value = undefined;

	if(!isPlayer(self)) return(memory);

	setID = tolower(setID);
	set_index = memSetIndex(setID);
	if(set_index == -1) return(memory);

	grp_index = _memGroupIndex(set_index, groupID);
	if(grp_index == -1) return(memory);
	groupID = tolower(groupID);

	itm_index = _memItemIndex(set_index, grp_index, itemID);
	if(itm_index == -1) return(memory);
	itemID = tolower(itemID);

	// getMemory will check for min and max. It will serve min, max or default when out of bounds
	type_expect = game["memory"][set_index].groups[grp_index].items[itm_index].type;
	token = self.pers["memory"][set_index].groups[grp_index].items[itm_index].val;
	switch(type_expect)
	{
		case "int":
		case "float":
			if(token < game["memory"][set_index].groups[grp_index].items[itm_index].min)
			{
				if(level.ex_log_memory) logprint("MEM: Get " + setID + "\\" + groupID + "\\" + itemID + ". Value \"" + token + "\" violates mininum. Serving minimum \"" + game["memory"][set_index].groups[grp_index].items[itm_index].min + "\"\n");
				token = game["memory"][set_index].groups[grp_index].items[itm_index].min;
			}
			else if(token > game["memory"][set_index].groups[grp_index].items[itm_index].max)
			{
				if(level.ex_log_memory) logprint("MEM: Get " + setID + "\\" + groupID + "\\" + itemID + ". Value \"" + token + "\" violates maxinum. Serving maximum \"" + game["memory"][set_index].groups[grp_index].items[itm_index].max + "\"\n");
				token = game["memory"][set_index].groups[grp_index].items[itm_index].max;
			}
			break;
		case "char":
			if(!isValidChar(token, game["memory"][set_index].groups[grp_index].items[itm_index].min))
			{
				if(level.ex_log_memory) logprint("MEM: Get " + setID + "\\" + groupID + "\\" + itemID + ". Value \"" + token + "\" is invalid. Serving default \"" + game["memory"][set_index].groups[grp_index].items[itm_index].def + "\"\n");
				token = game["memory"][set_index].groups[grp_index].items[itm_index].def;
			}
			break;
	}

	if(level.ex_log_memory) logprint("MEM: Get " + setID + "\\" + groupID + "\\" + itemID + ": \"" + token + "\"\n");
	memory.error = 0;
	memory.value = token;
	memory.def = game["memory"][set_index].groups[grp_index].items[itm_index].def;
	return(memory);
}

//------------------------------------------------------------------------------
// Scorememory handling
//------------------------------------------------------------------------------
onSecond(eventID)
{
	for(i = 0; i < game["scorememory"].size; i++)
		if(game["scorememory"][i]["grace"] > 0) game["scorememory"][i]["grace"]--;
}

setScoreMemory(name, score, kills, deaths, bonus, special)
{
	index = -1;

	// check if name is already on list
	for(i = 0; i < game["scorememory"].size; i++)
	{
		if(game["scorememory"][i]["name"] == name)
		{
			index = i;
			break;
		}
	}

	// name is not on list, so check for expired records
	if(index == -1)
	{
		for(i = 0; i < game["scorememory"].size; i++)
		{
			if(game["scorememory"][i]["grace"] == 0)
			{
				index = i;
				break;
			}
		}

		// no expired records so add one
		if(index == -1) index = game["scorememory"].size;
		game["scorememory"][index]["name"] = name;
	}

	game["scorememory"][index]["grace"] = level.ex_scorememory;
	if(!isDefined(score)) score = 0;
	game["scorememory"][index]["score"] = score;
	if(!isDefined(kills)) kills = 0;
	game["scorememory"][index]["kills"] = kills;
	if(!isDefined(deaths)) deaths = 0;
	game["scorememory"][index]["deaths"] = deaths;
	if(!isDefined(bonus)) bonus = 0;
	game["scorememory"][index]["bonus"] = bonus;
	if(!isDefined(special)) special = 0;
	game["scorememory"][index]["special"] = special;
}

getScoreMemory(name)
{
	memory = spawnstruct();
	memory.error = 1;

	// check if name is in list
	for(i = 0; i < game["scorememory"].size; i++)
	{
		if(game["scorememory"][i]["name"] == name)
		{
			// check if still in grace period
			if(game["scorememory"][i]["grace"] > 0)
			{
				memory.error = 0;
				memory.score = game["scorememory"][i]["score"];
				memory.kills = game["scorememory"][i]["kills"];
				memory.deaths = game["scorememory"][i]["deaths"];
				memory.bonus = game["scorememory"][i]["bonus"];
				memory.special = game["scorememory"][i]["special"];
			}
			break;
		}
	}

	return(memory);
}

hasScoreMemory(name)
{
	index = -1;

	// check if name is in list
	for(i = 0; i < game["scorememory"].size; i++)
	{
		if(game["scorememory"][i]["name"] == name)
		{
			// check if still in grace period
			if(game["scorememory"][i]["grace"] > 0) return(true);
			break;
		}
	}

	return(false);
}
