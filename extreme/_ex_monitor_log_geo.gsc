#include extreme\_ex_main_utils;
#include extreme\_ex_monitor_log_geolocalize;

geoInit()
{
	level.geo_lookup_inprogress = false;
	level.geo_statelist = [];
	level.geo_index = -1;
}

geoFindIP(str, searchstr, lineno)
{
	// Example:
	// Client 0 connecting with 50 challenge ping from 192.168.1.10:28961
	// Connecting player #10 has a zero GUID
	// Going from CS_FREE to CS_CONNECTED for(num 10 guid 0)

	ip_string = "";

	if(isSubStr(str, searchstr))
	{
		tokens = strtok(str, " ");
		if(tokens.size == 9)
		{
			ip_test = "";
			for(i = 0; i < tokens[8].size; i++)
				if(tokens[8][i] != ":") ip_test += tokens[8][i];
					else break;

			if(geoVerifyIP(ip_test)) ip_string = ip_test;
		}
	}

	if(ip_string != "")
	{
		level.geo_index = geoAllocRec();
		level.geo_statelist[level.geo_index].ip = ip_string;

		// Uncomment for testing a specific IP address
		//level.geo_statelist[level.geo_index].ip = "8.8.8.8";

		level.geo_statelist[level.geo_index].status = 1;
		logprint("LOM: [geo] record: " + level.geo_index + ", IP: " + level.geo_statelist[level.geo_index].ip + " (status " + level.geo_statelist[level.geo_index].status + ") (line " + lineno + ")\n");
	}
}

geoFindID(str, searchstr, lineno)
{
	// Example:
	// Client 0 connecting with 50 challenge ping from 192.168.1.10:28961
	// Connecting player #10 has a zero GUID
	// Going from CS_FREE to CS_CONNECTED for(num 10 guid 0)
	if(level.geo_index == -1) return;

	id_string = "";

	if(isSubStr(str, searchstr))
	{
		tokens = strtok(str, " ");
		if(tokens.size == 10)
		{
			id_test = tokens[7];
			if(isIntStr(id_test)) id_string = id_test;
		}
	}

	if(id_string != "")
	{
		id_int = int(id_string);

		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(isPlayer(player))
			{
				id_player = player getEntityNumber();
				if(id_player == id_int)
				{
					level.geo_statelist[level.geo_index].id = id_int;
					level.geo_statelist[level.geo_index].name = player.name;
					level.geo_statelist[level.geo_index].status = 2;
					logprint("LOM: [geo] record: " + level.geo_index + ", IP: " + level.geo_statelist[level.geo_index].ip + ", ID: " + level.geo_statelist[level.geo_index].id + ", player: " + level.geo_statelist[level.geo_index].name + " (status " + level.geo_statelist[level.geo_index].status + ") (line " + lineno + ")\n");
					level.geo_index = -1;
					break;
				}
			}
		}
	}
}

geoAllocRec()
{
	// status 0: empty, waiting for IP address
	// status 1: incomplete, waiting for client slot
	// status 2: complete, but not handled yet
	// status 3: complete and handled (ready to be reused)

	// look for records that can be reused
	for(i = 0; i < level.geo_statelist.size; i++)
	{
		if(level.geo_statelist[i].status == 3)
		{
			level.geo_statelist[i].status = 0;
			return(i);
		}
	}

	// no free records found: create new one
	level.geo_statelist[i] = spawnstruct();
	level.geo_statelist[i].ip = "";
	level.geo_statelist[i].id = -1;
	level.geo_statelist[i].name = -1;
	level.geo_statelist[i].status = 0;
	return(i);
}

geoShow()
{
	for(i = 0; i < level.geo_statelist.size; i++)
	{
		if(level.geo_statelist[i].status == 2)
		{
			players = level.players;
			for(p = 0; p < players.size; p++)
			{
				player = players[p];
				if(isPlayer(player))
				{
					id_player = player getEntityNumber();
					if(id_player == level.geo_statelist[i].id)
					{
						memory_ip = "0.0.0.0";
						memory_country = "UNKNOWN";

						memory = player extreme\_ex_controller_memory::getMemory("memory", "geo", "ip");
						if(!memory.error) memory_ip = memory.value;
						if(memory_ip != "0.0.0.0")
						{
							memory = player extreme\_ex_controller_memory::getMemory("memory", "geo", "country");
							if(!memory.error) memory_country = memory.value;
						}

						if(memory_ip == level.geo_statelist[i].ip && memory_country != "UNKNOWN")
						{
							country_loc = geoLocalize(memory_country);

							wait( [[level.ex_fpstime]](0.1) );
							//iprintlnbold(&"GEOLOCATION_WELCOME_GENERAL", country_loc);
							iprintlnbold(&"GEOLOCATION_WELCOME_PLAYER", level.geo_statelist[i].name , country_loc);
							logprint("LOM: [geo] record: " + i + ", IP: " + level.geo_statelist[i].ip + ", ID: " + level.geo_statelist[i].id + ", player: " + level.geo_statelist[i].name + " (status " + level.geo_statelist[i].status + ") (from memory " + memory_country + ")\n");
						}
						else
						{
							memory_ip = level.geo_statelist[i].ip;
							memory_country = geoLocate(memory_ip);
							country_loc = geoLocalize(memory_country);

							wait( [[level.ex_fpstime]](0.1) );
							//iprintlnbold(&"GEOLOCATION_WELCOME_GENERAL", country_loc);
							iprintlnbold(&"GEOLOCATION_WELCOME_PLAYER", level.geo_statelist[i].name , country_loc);
							logprint("LOM: [geo] record: " + i + ", IP: " + level.geo_statelist[i].ip + ", ID: " + level.geo_statelist[i].id + ", player: " + level.geo_statelist[i].name + " (status " + level.geo_statelist[i].status + ") (lookup " + memory_country + ")\n");
							if(isPlayer(player))
							{
								player extreme\_ex_controller_memory::setMemory("memory", "geo", "ip", memory_ip);
								player extreme\_ex_controller_memory::setMemory("memory", "geo", "country", memory_country);
							}
						}

						// disable other records with same player IP where ID or name matches (reconnect or back from download)
						for(j = i + 1; j < level.geo_statelist.size; j++)
							if(memory_ip == level.geo_statelist[j].ip && (id_player == level.geo_statelist[j].id || player.name == level.geo_statelist[j].name) )
								level.geo_statelist[j].status = 3;

						break;
					}
				}
			}

			// make the record available for reuse
			level.geo_statelist[i].status = 3;
		}
	}
}

geoLocate(ip_string)
{
	level.geo_lookup_inprogress = true;
	country = geoSearchLocation(ip_string);
	level.geo_lookup_inprogress = false;
	return(country);
}

geoSearchLocation(ip_string)
{
	if(!isDefined(ip_string) || ip_string == "0.0.0.0") return("ZZ");

	ip_country = geoSearchDatabase(ip_string);
	return(ip_country);
}

geoSearchDatabase(ip_string)
{
	// Warning: do not include wait statements
	db_file = "geolocation/geolocation." + geoOctetToStr(ip_string, 1, 3);
	db_handle = openfile(db_file, "read");
	if(db_handle != -1)
	{
		ip_long = geoIPArray(ip_string);
		ip_start = geoIPArray("0.0.0.0");
		ip_end = geoIPArray("0.0.0.0");
		ip_country = "ZZ";
		ip_inrange = false;

		for(;;)
		{
			farg = freadln(db_handle);
			if(farg == -1 || farg == 0) break;

			memory = fgetarg(db_handle, 0);
			array = strtok(memory, " ");
			if(array.size == 3)
			{
				ip_start = geoIPArray(array[0]);
				ip_end = geoIPArray(array[1]);
				ip_country = array[2];

				ip_inrange = false;
				if(ip_long[0] >= ip_start[0])
				{
					if(ip_long[0] < ip_end[0])
					{
						ip_inrange = true;
						break;
					}
					else
					{
						if(ip_long[0] > ip_start[0]) ignore_start1 = true;
							else ignore_start1 = false;

						if(ip_long[0] == ip_end[0])
						{
							if(ignore_start1 || ip_long[1] >= ip_start[1])
							{
								if(ip_long[1] < ip_end[1])
								{
									ip_inrange = true;
									break;
								}
								else
								{
									if(ip_long[1] > ip_start[1]) ignore_start2 = true;
										else ignore_start2 = false;

									if(ip_long[1] == ip_end[1])
									{
										if(ignore_start2 || ip_long[2] >= ip_start[2])
										{
											if(ip_long[2] < ip_end[2])
											{
												ip_inrange = true;
												break;
											}
											else
											{
												if(ip_long[2] > ip_start[2]) ignore_start3 = true;
													else ignore_start3 = false;

												if(ip_long[2] == ip_end[2])
												{
													if(ignore_start3 || ip_long[3] >= ip_start[3])
													{
														if(ip_long[3] <= ip_end[3])
														{
															ip_inrange = true;
															break;
														}
													} else break;
												}
											}
										} else break;
									}
								}
							} else break;
						}
					}
				} else break;
			}
		}

		closefile(db_handle);
		if(ip_inrange) return(ip_country);
	}

	return("UNKNOWN");
}

geoVerifyIP(ip_string)
{
	ip_array = strtok(ip_string, ".");
	if(ip_array.size != 4 || !isIntStr(ip_array[0]) || !isIntStr(ip_array[1]) || !isIntStr(ip_array[2]) || !isIntStr(ip_array[3])) return(false);
	return(true);
}

geoIPArray(ip_string)
{
	ip_array = strtok(ip_string, ".");
	ip_result[0] = int(ip_array[0]);
	ip_result[1] = int(ip_array[1]);
	ip_result[2] = int(ip_array[2]);
	ip_result[3] = int(ip_array[3]);
	return(ip_result);
}

geoOctetToStr(ip_string, octet, length)
{
	ip_array = geoIPArray(ip_string);
	switch(octet)
	{
		case 4: string = "" + ip_array[3]; break;
		case 3: string = "" + ip_array[2]; break;
		case 2: string = "" + ip_array[1]; break;
		default: string = "" + ip_array[0]; break;
	}
	if(string.size > length) length = string.size;
	diff = length - string.size;
	if(diff) string = dupChar("0", diff) + string;
	return(string);
}

geoRandomIP()
{
	ip_intro = [];
	ip_intro[0] = randomInt(256);
	ip_intro[1] = randomInt(256);
	ip_intro[2] = randomInt(256);
	ip_intro[3] = randomInt(256);
	ip_string = ip_intro[0] + "." + ip_intro[1] + "." + ip_intro[2] + "." + ip_intro[3];
	return(ip_string);
}
