
playerStatsInit()
{
	count = 1;
	for(;;)
	{
		stat = playerStats(count);
		if(stat == "") break;
		if(isPlayer(self) && !isDefined(self.pers[stat])) self.pers[stat] = 0;
		count++;
	}
}

playerStatsReset()
{
	count = 1;
	for(;;)
	{
		stat = playerStats(count);
		if(stat == "") break;
		if(isPlayer(self)) self.pers[stat] = 0;
		count++;
	}
}

playerStats(stat)
{
	switch(stat)
	{
		// kills
		case 1:  return("kill");
		case 2:  return("grenadekill");
		case 3:  return("tripwirekill");
		case 4:  return("headshotkill");
		case 5:  return("bashkill");
		case 6:  return("sniperkill");
		case 7:  return("knifekill");
		case 8:  return("mortarkill");
		case 9:  return("artillerykill");
		case 10: return("airstrikekill");
		case 11: return("napalmkill");
		case 12: return("panzerkill");
		case 13: return("spawnkill");
		case 14: return("spamkill");
		case 15: return("teamkill");
		case 16: return("flamethrowerkill");
		case 17: return("landminekill");
		case 18: return("firenadekill");
		case 19: return("gasnadekill");
		case 20: return("satchelchargekill");
		case 21: return("gunshipkill");

		// deaths
		case 22: return("death");
		case 23: return("grenadedeath");
		case 24: return("tripwiredeath");
		case 25: return("headshotdeath");
		case 26: return("bashdeath");
		case 27: return("sniperdeath");
		case 28: return("knifedeath");
		case 29: return("mortardeath");
		case 30: return("artillerydeath");
		case 31: return("airstrikedeath");
		case 32: return("napalmdeath");
		case 33: return("panzerdeath");
		case 34: return("spawndeath");
		case 35: return("planedeath");
		case 36: return("flamethrowerdeath");
		case 37: return("fallingdeath");
		case 38: return("minefielddeath");
		case 39: return("suicide");
		case 40: return("landminedeath");
		case 41: return("firenadedeath");
		case 42: return("gasnadedeath");
		case 43: return("satchelchargedeath");
		case 44: return("gunshipdeath");

		// other
		case 45: return("turretkill");
		case 46: return("noobstreak");
		case 47: return("conseckill");
		case 48: return("weaponstreak");
		case 49: return("roundshown");
		case 50: return("longdist");
		case 51: return("longhead");
		case 52: return("longspree");
		case 53: return("flagcap");
		case 54: return("flagret");
		case 55: return("bonus");

		// empty signals end
		default: return("");
	}
}
