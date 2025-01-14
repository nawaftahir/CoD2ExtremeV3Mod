#include extreme\_ex_controller_hud;

playerScoreInit()
{
	if(!isDefined(self.pers["score"])) self.pers["score"] = 0;
	self.score = self.pers["score"];

	if(!isDefined(self.pers["death"])) self.pers["death"] = 0;
	self.deaths = self.pers["death"];

	if(!isDefined(self.pers["bonus"])) self.pers["bonus"] = 0;
	if(!isDefined(self.pers["special"])) self.pers["special"] = 0;

	if(level.ex_arcade_score) self.ex_arcade_oldscore = self.pers["score"];
}

playerScoreReset()
{
	self.pers["score"] = 0;
	self.score = self.pers["score"];

	self.pers["death"] = 0;
	self.deaths = self.pers["death"];
}

/*
Usage examples:
Only main score        : playerScore(1)
Only reward (not used) : playerScore(0, "bonus", 1)
Main score = reward    : playerScore(1, "bonus")
Main score + reward    : playerScore(1, "bonus", 1)
*/
playerScore(points, stat, stat_points, checklimit)
{
	if(!isPlayer(self) || !isDefined(points)) return;
	if(!isDefined(checklimit)) checklimit = true;

	// stat_points are already included in points!
	if(points)
	{
		self.pers["score"] += points;
		self.score = self.pers["score"];
		self notify("update_playerscore_hud");

		if(level.ex_store)
		{
			if(level.ex_store_payment == 0) self thread playerHudSetValue("cash", self.pers["score"]);
			else if(level.ex_store_payment == 2)
			{
				if(!level.ex_accounts || self extreme\_ex_main_accounts::canAccumulateCash())
				{
					self.pers["cash"] += points;
					if(self.pers["cash"] > level.ex_store_maxcash) self.pers["cash"] = level.ex_store_maxcash;
					self thread playerHudSetValue("cash", self.pers["cash"]);
				}
			}
		}
	}

	if(isDefined(stat))
	{
		stat_add = points;
		if(isDefined(stat_points)) stat_add = stat_points;
		if(stat_add)
		{
			if(!isDefined(self.pers[stat])) self.pers[stat] = 0;
			self.pers[stat] += stat_add;
			if(stat != "bonus") self.pers["bonus"] += stat_add;
			if(level.ex_store && level.ex_store_payment == 1) self thread playerHudSetValue("cash", self.pers["bonus"]);
		}
	}

	if(level.ex_arcade_score) self thread extreme\_ex_player_arcade::checkScoreUpdate();
	if(checklimit && !level.ex_teamplay) self [[level.checkscorelimit]]();
}

teamScoreInit()
{
	if(!isDefined(game["alliedscore"])) game["alliedscore"] = 0;
	setTeamScore("allies", game["alliedscore"]);

	if(!isDefined(game["axisscore"])) game["axisscore"] = 0;
	setTeamScore("axis", game["axisscore"]);
}

teamScoreReset()
{
	game["alliedscore"] = 0;
	setTeamScore("allies", game["alliedscore"]);

	game["axisscore"] = 0;
	setTeamScore("axis", game["axisscore"]);
}

teamScore(team, points, checklimit)
{
	if(!isDefined(team) || !isDefined(points)) return;
	if(!isDefined(checklimit)) checklimit = true;

	if(points)
	{
		switch(team)
		{
			case "allies":
				game["alliedscore"] = getTeamScore(team) + points;
				setTeamScore(team, game["alliedscore"]);
				level notify("update_teamscore_hud");
				if(checklimit) [[level.checkscorelimit]]();
				break;
			case "axis":
				game["axisscore"] = getTeamScore(team) + points;
				setTeamScore(team, game["axisscore"]);
				level notify("update_teamscore_hud");
				if(checklimit) [[level.checkscorelimit]]();
				break;
		}
	}
}

