#include extreme\_ex_controller_hud;

init()
{
	// device registration
	[[level.ex_devRequest]]("mortar_wmd");
	[[level.ex_devRequest]]("artillery_wmd");
	[[level.ex_devRequest]]("airstrike_wmd");
	[[level.ex_devRequest]]("napalm", undefined, ::callbackNapalmDamage);
	if(level.ex_planes_flak) [[level.ex_devRequest]]("skyfx_flak");
}

checkWmd(value)
{
	self endon("kill_thread");

	// return if already checking
	if(isDefined(self.ex_checkingwmd)) return;

	// if playing LIB and player is jailed, do not give WMD
	if(level.ex_currentgt == "lib" && isDefined(self.in_jail) && self.in_jail)
	{
		self wmdStop();
		return;
	}

	// if entities monitor in defcon 2, suspend all WMD
	if(level.ex_entities_defcon == 2) return;

	// check if account system grants access
	if(level.ex_accounts && self.pers["account"]["status"] == 1 && (level.ex_accounts_lock & 32) == 32) return;

	// no checking if in gunship
	if( (level.ex_gunship && isPlayer(level.gunship.owner) && level.gunship.owner == self) ||
	    (level.ex_gunship_special && isPlayer(level.gunship_special.owner) && level.gunship_special.owner == self) ) return;

	// no checking if frozen in FreezeTag
	if(level.ex_currentgt == "ft" && isDefined(self.frozenstate) && self.frozenstate == "frozen") return;

	self.ex_checkingwmd = true;

	switch(level.ex_wmd)
	{
		case 1:
			if(level.ex_streak_wmdtype == 1) self wmdStreakFixed(value);
				else if(level.ex_streak_wmdtype == 2) self wmdStreakRandom(value);
					else if(level.ex_streak_wmdtype == 3) self wmdStreakAllowedRandom(value);
			break;
		case 2:
			if(level.ex_rank_wmdtype == 1) self wmdRankFixed(value);
				else if(level.ex_rank_wmdtype == 2) self wmdRankRandom(value);
					else if(level.ex_rank_wmdtype == 3) self wmdRankAllowedRandom(value);
			break;
		case 3:
			if(level.ex_ladder_wmdtype == 1) self wmdLadderFixed(value);
				else if(level.ex_ladder_wmdtype == 2) self wmdLadderRandom(value);
					else if(level.ex_ladder_wmdtype == 3) self wmdLadderAllowedRandom(value);
			break;
	}

	wait( [[level.ex_fpstime]](5) );
	if(isPlayer(self)) self.ex_checkingwmd = undefined;
}

//------------------------------------------------------------------------------
// Streak based WMD
//------------------------------------------------------------------------------
wmdStreakFixed(value)
{
	self endon("kill_thread");

	wmd_assigned = (self.ex_mortars || self.ex_artillery || self.ex_airstrike || self.ex_gunship);
	if(wmd_assigned && !level.ex_streak_wmd_upgrade) return;
	if(level.ex_gunship != 4 && self.ex_gunship) return;

	if(value < 5)
	{
		if(wmd_assigned) self wmdStop();
		return;
	}

	mortar_allowed = false;
	if(value == 5) mortar_allowed = true;
	artillery_allowed = false;
	if(value == 10) artillery_allowed = true;
	airstrike_allowed = false;
	gunship_allowed = false;
	if(level.ex_gunship == 4)
	{
			if(value == 15) airstrike_allowed = true;
			else if(value == 20)
			{
				if(!level.ex_streak_gunship_next && isDefined(self.pers["gunship"])) airstrike_allowed = true;
					else gunship_allowed = true;
			}
	}
	else if(value == 15) airstrike_allowed = true;

	if(wmd_assigned)
	{
		if(mortar_allowed) return;
		if(artillery_allowed && (self.ex_artillery || self.ex_airstrike || self.ex_gunship)) return;
		if(airstrike_allowed && (self.ex_airstrike || self.ex_gunship)) return;
		if(gunship_allowed && self.ex_gunship) return;
	}

	if(isPlayer(self))
	{
		self wmdStop();
		if(mortar_allowed)
		{
			if(!wmd_assigned) delay = level.ex_streak_mortar_first;
				else delay = level.ex_streak_wmd_delay;
			self thread extreme\_ex_player_wmd_mortars::startWmd(delay, level.ex_streak_mortar_first, level.ex_streak_mortar_next);
		}
		else if(artillery_allowed)
		{
			if(!wmd_assigned) delay = level.ex_streak_artillery_first;
				else delay = level.ex_streak_wmd_delay;
			self thread extreme\_ex_player_wmd_artillery::startWmd(delay, level.ex_streak_artillery_first, level.ex_streak_artillery_next);
		}
		else if(airstrike_allowed)
		{
			napalm = (value == 20 && randomInt(100) < level.ex_wmd_napalm_chance);
			if(!wmd_assigned) delay = level.ex_streak_airstrike_first;
				else delay = level.ex_streak_wmd_delay;
			self thread extreme\_ex_player_wmd_airstrike::startWmd(delay, level.ex_streak_airstrike_first, level.ex_streak_airstrike_next, napalm);
		}
		else if(gunship_allowed)
		{
			if(!wmd_assigned) delay = level.ex_streak_gunship_first;
				else delay = level.ex_streak_wmd_delay;
			self thread extreme\_ex_main_gunship::startWmd(delay, level.ex_streak_gunship_first, level.ex_streak_gunship_next);
		}
	}
}

wmdStreakRandom(value)
{
	self endon("kill_thread");

	wmd_assigned = (self.ex_mortars || self.ex_artillery || self.ex_airstrike || self.ex_gunship);
	if(wmd_assigned && !level.ex_streak_wmd_upgrade) return;
	if(level.ex_gunship != 4 && self.ex_gunship) return;

	mortar_allowed = false;
	if(value >= level.ex_streak_mortar) mortar_allowed = true;
	artillery_allowed = false;
	if(value >= level.ex_streak_artillery) artillery_allowed = true;
	airstrike_allowed = false;
	if((value >= level.ex_streak_airstrike) || (level.ex_gunship == 4 && value >= level.ex_streak_special)) airstrike_allowed = true;
	gunship_allowed = false;
	if(level.ex_gunship == 4 && value >= level.ex_streak_special && (level.ex_streak_gunship_next || !isDefined(self.pers["gunship"]))) gunship_allowed = true;

	if(!mortar_allowed && !artillery_allowed && !airstrike_allowed && !gunship_allowed)
	{
		if(wmd_assigned) self wmdStop();
		return;
	}

	for(;;)
	{
		wmdtodo = randomInt(4) + 1;

		if(wmdtodo == 1 && mortar_allowed) break;
		if(wmdtodo == 2 && artillery_allowed) break;
		if(wmdtodo == 3 && airstrike_allowed) break;
		if(wmdtodo == 4 && gunship_allowed) break;

		wait( [[level.ex_fpstime]](0.1) );
	}

	if(wmd_assigned)
	{
		if(wmdtodo == 1) return;
		if(wmdtodo == 2 && (self.ex_artillery || self.ex_airstrike || self.ex_gunship)) return;
		if(wmdtodo == 3 && (self.ex_airstrike || self.ex_gunship)) return;
		if(wmdtodo == 4 && self.ex_gunship) return;
	}

	if(isPlayer(self))
	{
		self wmdStop();
		if(wmdtodo == 1)
		{
			if(!wmd_assigned) delay = level.ex_streak_mortar_first;
				else delay = level.ex_streak_wmd_delay;
			self thread extreme\_ex_player_wmd_mortars::startWmd(delay, level.ex_streak_mortar_first, level.ex_streak_mortar_next);
		}
		else if(wmdtodo == 2)
		{
			if(!wmd_assigned) delay = level.ex_streak_artillery_first;
				else delay = level.ex_streak_wmd_delay;
			self thread extreme\_ex_player_wmd_artillery::startWmd(delay, level.ex_streak_artillery_first, level.ex_streak_artillery_next);
		}
		else if(wmdtodo == 3)
		{
			napalm = (value >= level.ex_streak_special && randomInt(100) < level.ex_wmd_napalm_chance);
			if(!wmd_assigned) delay = level.ex_streak_airstrike_first;
				else delay = level.ex_streak_wmd_delay;
			self thread extreme\_ex_player_wmd_airstrike::startWmd(delay, level.ex_streak_airstrike_first, level.ex_streak_airstrike_next, napalm);
		}
		else
		{
			if(!wmd_assigned) delay = level.ex_streak_gunship_first;
				else delay = level.ex_streak_wmd_delay;
			self thread extreme\_ex_main_gunship::startWmd(delay, level.ex_streak_gunship_first, level.ex_streak_gunship_next);
		}
	}
}

wmdStreakAllowedRandom(value)
{
	self endon("kill_thread");

	if(!level.ex_streak_allow_mortar && !level.ex_streak_allow_artillery && !level.ex_streak_allow_airstrike && !level.ex_streak_allow_special) return;

	wmd_assigned = (self.ex_mortars || self.ex_artillery || self.ex_airstrike || self.ex_gunship);
	if(wmd_assigned && !level.ex_streak_wmd_upgrade) return;
	if(level.ex_gunship != 4 && self.ex_gunship) return;

	if(value < level.ex_streak_allow_on)
	{
		if(wmd_assigned) self wmdStop();
		return;
	}

	mortar_allowed = level.ex_streak_allow_mortar;
	artillery_allowed = level.ex_streak_allow_artillery;
	airstrike_allowed = level.ex_streak_allow_airstrike || (level.ex_gunship == 4 && level.ex_streak_allow_special);
	gunship_allowed = (level.ex_gunship == 4 && level.ex_streak_allow_special && (level.ex_streak_gunship_next || !isDefined(self.pers["gunship"])));

	for(;;)
	{
		wmdtodo = randomInt(4) + 1;

		if(wmdtodo == 1 && mortar_allowed) break;
		if(wmdtodo == 2 && artillery_allowed) break;
		if(wmdtodo == 3 && airstrike_allowed) break;
		if(wmdtodo == 4 && gunship_allowed) break;

		wait( [[level.ex_fpstime]](0.1) );
	}

	if(wmd_assigned)
	{
		if(wmdtodo == 1) return;
		if(wmdtodo == 2 && (self.ex_artillery || self.ex_airstrike || self.ex_gunship)) return;
		if(wmdtodo == 3 && (self.ex_airstrike || self.ex_gunship)) return;
		if(wmdtodo == 4 && self.ex_gunship) return;
	}

	if(isPlayer(self))
	{
		self wmdStop();
		if(wmdtodo == 1)
		{
			if(!wmd_assigned) delay = level.ex_streak_mortar_first;
				else delay = level.ex_streak_wmd_delay;
			self thread extreme\_ex_player_wmd_mortars::startWmd(delay, level.ex_streak_mortar_first, level.ex_streak_mortar_next);
		}
		else if(wmdtodo == 2)
		{
			if(!wmd_assigned) delay = level.ex_streak_artillery_first;
				else delay = level.ex_streak_wmd_delay;
			self thread extreme\_ex_player_wmd_artillery::startWmd(delay, level.ex_streak_artillery_first, level.ex_streak_artillery_next);
		}
		else if(wmdtodo == 3)
		{
			napalm = (level.ex_streak_allow_airstrike && level.ex_streak_allow_special && randomInt(100) < level.ex_wmd_napalm_chance);
			if(!wmd_assigned) delay = level.ex_streak_airstrike_first;
				else delay = level.ex_streak_wmd_delay;
			self thread extreme\_ex_player_wmd_airstrike::startWmd(delay, level.ex_streak_airstrike_first, level.ex_streak_airstrike_next, napalm);
		}
		else
		{
			if(!wmd_assigned) delay = level.ex_streak_gunship_first;
				else delay = level.ex_streak_wmd_delay;
			self thread extreme\_ex_main_gunship::startWmd(delay, level.ex_streak_gunship_first, level.ex_streak_gunship_next);
		}
	}
}

//------------------------------------------------------------------------------
// Rank based WMD
//------------------------------------------------------------------------------
wmdRankFixed(value)
{
	self endon("kill_thread");

	wmd_assigned = (self.ex_mortars || self.ex_artillery || self.ex_airstrike || self.ex_gunship);
	if(wmd_assigned && !level.ex_rank_wmd_upgrade) return;
	if(level.ex_gunship != 4 && self.ex_gunship) return;

	if(value < 3)
	{
		if(wmd_assigned) self wmdStop();
		return;
	}

	mortar_allowed = false;
	if(value == 3) mortar_allowed = true;
	artillery_allowed = false;
	if(value == 4) artillery_allowed = true;
	airstrike_allowed = false;
	gunship_allowed = false;
	if(level.ex_gunship == 4)
	{
		if(value == 5 || value == 6) airstrike_allowed = true;
		else if(value > 6)
		{
			if(!level.ex_rank_gunship_next && isDefined(self.pers["gunship"])) airstrike_allowed = true;
				else gunship_allowed = true;
		}
	}
	else if(value >= 5) airstrike_allowed = true;

	if(wmd_assigned)
	{
		if(mortar_allowed) return;
		if(artillery_allowed && (self.ex_artillery || self.ex_airstrike || self.ex_gunship)) return;
		if(airstrike_allowed && (self.ex_airstrike || self.ex_gunship)) return;
		if(gunship_allowed && self.ex_gunship) return;
	}

	if(isPlayer(self))
	{
		self wmdStop();
		if(mortar_allowed)
		{
			if(!wmd_assigned) delay = level.ex_rank_mortar_first;
				else delay = level.ex_rank_wmd_delay;
			self thread extreme\_ex_player_wmd_mortars::startWmd(delay, level.ex_rank_mortar_first, level.ex_rank_mortar_next);
		}
		else if(artillery_allowed)
		{
			if(!wmd_assigned) delay = level.ex_rank_artillery_first;
				else delay = level.ex_rank_wmd_delay;
			self thread extreme\_ex_player_wmd_artillery::startWmd(delay, level.ex_rank_artillery_first, level.ex_rank_artillery_next);
		}
		else if(airstrike_allowed)
		{
			napalm = (value == 7 && randomInt(100) < level.ex_wmd_napalm_chance);
			if(!wmd_assigned) delay = level.ex_rank_airstrike_first;
				else delay = level.ex_rank_wmd_delay;
			self thread extreme\_ex_player_wmd_airstrike::startWmd(delay, level.ex_rank_airstrike_first, level.ex_rank_airstrike_next, napalm);
		}
		else if(gunship_allowed)
		{
			if(!wmd_assigned) delay = level.ex_rank_gunship_first;
				else delay = level.ex_rank_wmd_delay;
			self thread extreme\_ex_main_gunship::startWmd(delay, level.ex_rank_gunship_first, level.ex_rank_gunship_next);
		}
	}
}

wmdRankRandom(value)
{
	self endon("kill_thread");

	wmd_assigned = (self.ex_mortars || self.ex_artillery || self.ex_airstrike || self.ex_gunship);
	if(wmd_assigned && !level.ex_rank_wmd_upgrade) return;
	if(level.ex_gunship != 4 && self.ex_gunship) return;

	mortar_allowed = false;
	if(value >= level.ex_rank_mortar) mortar_allowed = true;
	artillery_allowed = false;
	if(value >= level.ex_rank_artillery) artillery_allowed = true;
	airstrike_allowed = false;
	if((value >= level.ex_rank_airstrike) || (level.ex_gunship == 4 && value >= level.ex_rank_special)) airstrike_allowed = true;
	gunship_allowed = false;
	if(level.ex_gunship == 4 && value >= level.ex_rank_special && (level.ex_rank_gunship_next || !isDefined(self.pers["gunship"]))) gunship_allowed = true;

	if(!mortar_allowed && !artillery_allowed && !airstrike_allowed && !gunship_allowed)
	{
		if(wmd_assigned) self wmdStop();
		return;
	}

	for(;;)
	{
		wmdtodo = randomInt(4) + 1;

		if(wmdtodo == 1 && mortar_allowed) break;
		if(wmdtodo == 2 && artillery_allowed) break;
		if(wmdtodo == 3 && airstrike_allowed) break;
		if(wmdtodo == 4 && gunship_allowed) break;

		wait( [[level.ex_fpstime]](0.1) );
	}

	if(wmd_assigned)
	{
		if(wmdtodo == 1) return;
		if(wmdtodo == 2 && (self.ex_artillery || self.ex_airstrike || self.ex_gunship)) return;
		if(wmdtodo == 3 && (self.ex_airstrike || self.ex_gunship)) return;
		if(wmdtodo == 4 && self.ex_gunship) return;
	}

	if(isPlayer(self))
	{
		self wmdStop();
		if(wmdtodo == 1)
		{
			if(!wmd_assigned) delay = level.ex_rank_mortar_first;
				else delay = level.ex_rank_wmd_delay;
			self thread extreme\_ex_player_wmd_mortars::startWmd(delay, level.ex_rank_mortar_first, level.ex_rank_mortar_next);
		}
		else if(wmdtodo == 2)
		{
			if(!wmd_assigned) delay = level.ex_rank_artillery_first;
				else delay = level.ex_rank_wmd_delay;
			self thread extreme\_ex_player_wmd_artillery::startWmd(delay, level.ex_rank_artillery_first, level.ex_rank_artillery_next);
		}
		else if(wmdtodo == 3)
		{
			napalm = (value >= level.ex_rank_special && randomInt(100) < level.ex_wmd_napalm_chance);
			if(!wmd_assigned) delay = level.ex_rank_airstrike_first;
				else delay = level.ex_rank_wmd_delay;
			self thread extreme\_ex_player_wmd_airstrike::startWmd(delay, level.ex_rank_airstrike_first, level.ex_rank_airstrike_next, napalm);
		}
		else
		{
			if(!wmd_assigned) delay = level.ex_rank_gunship_first;
				else delay = level.ex_rank_wmd_delay;
			self thread extreme\_ex_main_gunship::startWmd(delay, level.ex_rank_gunship_first, level.ex_rank_gunship_next);
		}
	}
}

wmdRankAllowedRandom(value)
{
	self endon("kill_thread");

	if(!level.ex_rank_allow_mortar && !level.ex_rank_allow_artillery && !level.ex_rank_allow_airstrike && !level.ex_rank_allow_special) return;

	wmd_assigned = (self.ex_mortars || self.ex_artillery || self.ex_airstrike || self.ex_gunship);
	if(wmd_assigned && !level.ex_rank_wmd_upgrade) return;
	if(level.ex_gunship != 4 && self.ex_gunship) return;

	if(value < level.ex_rank_allow_on)
	{
		if(wmd_assigned) self wmdStop();
		return;
	}

	mortar_allowed = level.ex_rank_allow_mortar;
	artillery_allowed = level.ex_rank_allow_artillery;
	airstrike_allowed = level.ex_rank_allow_airstrike || (level.ex_gunship == 4 && level.ex_rank_allow_special);
	gunship_allowed = (level.ex_gunship == 4 && level.ex_rank_allow_special && (level.ex_rank_gunship_next || !isDefined(self.pers["gunship"])));

	for(;;)
	{
		wmdtodo = randomInt(4) + 1;

		if(wmdtodo == 1 && mortar_allowed) break;
		if(wmdtodo == 2 && artillery_allowed) break;
		if(wmdtodo == 3 && airstrike_allowed) break;
		if(wmdtodo == 4 && gunship_allowed) break;

		wait( [[level.ex_fpstime]](0.1) );
	}

	if(wmd_assigned)
	{
		if(wmdtodo == 1) return;
		if(wmdtodo == 2 && (self.ex_artillery || self.ex_airstrike || self.ex_gunship)) return;
		if(wmdtodo == 3 && (self.ex_airstrike || self.ex_gunship)) return;
		if(wmdtodo == 4 && self.ex_gunship) return;
	}

	if(isPlayer(self))
	{
		self wmdStop();
		if(wmdtodo == 1)
		{
			if(!wmd_assigned) delay = level.ex_rank_mortar_first;
				else delay = level.ex_rank_wmd_delay;
			self thread extreme\_ex_player_wmd_mortars::startWmd(delay, level.ex_rank_mortar_first, level.ex_rank_mortar_next);
		}
		else if(wmdtodo == 2)
		{
			if(!wmd_assigned) delay = level.ex_rank_artillery_first;
				else delay = level.ex_rank_wmd_delay;
			self thread extreme\_ex_player_wmd_artillery::startWmd(delay, level.ex_rank_artillery_first, level.ex_rank_artillery_next);
		}
		else if(wmdtodo == 3)
		{
			napalm = (level.ex_rank_allow_airstrike && level.ex_rank_allow_special && randomInt(100) < level.ex_wmd_napalm_chance);
			if(!wmd_assigned) delay = level.ex_rank_airstrike_first;
				else delay = level.ex_rank_wmd_delay;
			self thread extreme\_ex_player_wmd_airstrike::startWmd(delay, level.ex_rank_airstrike_first, level.ex_rank_airstrike_next, napalm);
		}
		else
		{
			if(!wmd_assigned) delay = level.ex_rank_gunship_first;
				else delay = level.ex_rank_wmd_delay;
			self thread extreme\_ex_main_gunship::startWmd(delay, level.ex_rank_gunship_first, level.ex_rank_gunship_next);
		}
	}
}

//------------------------------------------------------------------------------
// Ladder based WMD
//------------------------------------------------------------------------------
wmdLadderFixed(value)
{
	self endon("kill_thread");

	wmd_assigned = (self.ex_mortars || self.ex_artillery || self.ex_airstrike || self.ex_gunship);
	if(wmd_assigned && !level.ex_streak_wmd_upgrade) return;
	if(level.ex_gunship != 4 && self.ex_gunship) return;

	if(value < 5)
	{
		if(wmd_assigned) self wmdStop();
		return;
	}

	mortar_allowed = false;
	if(value == 5) mortar_allowed = true;
	artillery_allowed = false;
	if(value == 6) artillery_allowed = true;
	airstrike_allowed = false;
	gunship_allowed = false;
	if(level.ex_gunship == 4)
	{
			if(value == 7) airstrike_allowed = true;
			else if(value > 7)
			{
				if(!level.ex_ladder_gunship_next && isDefined(self.pers["gunship"])) airstrike_allowed = true;
					else gunship_allowed = true;
			}
	}
	else if(value >= 7) airstrike_allowed = true;

	if(wmd_assigned)
	{
		if(mortar_allowed) return;
		if(artillery_allowed && (self.ex_artillery || self.ex_airstrike || self.ex_gunship)) return;
		if(airstrike_allowed && (self.ex_airstrike || self.ex_gunship)) return;
		if(gunship_allowed && self.ex_gunship) return;
	}

	if(isPlayer(self))
	{
		self wmdStop();
		if(mortar_allowed)
		{
			if(!wmd_assigned) delay = level.ex_ladder_mortar_first;
				else delay = level.ex_ladder_wmd_delay;
			self thread extreme\_ex_player_wmd_mortars::startWmd(delay, level.ex_ladder_mortar_first, level.ex_ladder_mortar_next);
		}
		else if(artillery_allowed)
		{
			if(!wmd_assigned) delay = level.ex_ladder_artillery_first;
				else delay = level.ex_ladder_wmd_delay;
			self thread extreme\_ex_player_wmd_artillery::startWmd(delay, level.ex_ladder_artillery_first, level.ex_ladder_artillery_next);
		}
		else if(airstrike_allowed)
		{
			napalm = (value > 7 && randomInt(100) < level.ex_wmd_napalm_chance);
			if(!wmd_assigned) delay = level.ex_ladder_airstrike_first;
				else delay = level.ex_ladder_wmd_delay;
			self thread extreme\_ex_player_wmd_airstrike::startWmd(delay, level.ex_ladder_airstrike_first, level.ex_ladder_airstrike_next, napalm);
		}
		else if(gunship_allowed)
		{
			if(!wmd_assigned) delay = level.ex_ladder_gunship_first;
				else delay = level.ex_ladder_wmd_delay;
			self thread extreme\_ex_main_gunship::startWmd(delay, level.ex_ladder_gunship_first, level.ex_ladder_gunship_next);
		}
	}
}

wmdLadderRandom(value)
{
	self endon("kill_thread");

	wmd_assigned = (self.ex_mortars || self.ex_artillery || self.ex_airstrike || self.ex_gunship);
	if(wmd_assigned && !level.ex_ladder_wmd_upgrade) return;
	if(level.ex_gunship != 4 && self.ex_gunship) return;

	mortar_allowed = false;
	if(value >= level.ex_ladder_mortar) mortar_allowed = true;
	artillery_allowed = false;
	if(value >= level.ex_ladder_artillery) artillery_allowed = true;
	airstrike_allowed = false;
	if((value >= level.ex_ladder_airstrike) || (level.ex_gunship == 4 && value >= level.ex_ladder_special)) airstrike_allowed = true;
	gunship_allowed = false;
	if(level.ex_gunship == 4 && value >= level.ex_ladder_special && (level.ex_ladder_gunship_next || !isDefined(self.pers["gunship"]))) gunship_allowed = true;

	if(!mortar_allowed && !artillery_allowed && !airstrike_allowed && !gunship_allowed)
	{
		if(wmd_assigned) self wmdStop();
		return;
	}

	for(;;)
	{
		wmdtodo = randomInt(4) + 1;

		if(wmdtodo == 1 && mortar_allowed) break;
		if(wmdtodo == 2 && artillery_allowed) break;
		if(wmdtodo == 3 && airstrike_allowed) break;
		if(wmdtodo == 4 && gunship_allowed) break;

		wait( [[level.ex_fpstime]](0.1) );
	}

	if(wmd_assigned)
	{
		if(wmdtodo == 1) return;
		if(wmdtodo == 2 && (self.ex_artillery || self.ex_airstrike || self.ex_gunship)) return;
		if(wmdtodo == 3 && (self.ex_airstrike || self.ex_gunship)) return;
		if(wmdtodo == 4 && self.ex_gunship) return;
	}

	if(isPlayer(self))
	{
		self wmdStop();
		if(wmdtodo == 1)
		{
			if(!wmd_assigned) delay = level.ex_ladder_mortar_first;
				else delay = level.ex_ladder_wmd_delay;
			self thread extreme\_ex_player_wmd_mortars::startWmd(delay, level.ex_ladder_mortar_first, level.ex_ladder_mortar_next);
		}
		else if(wmdtodo == 2)
		{
			if(!wmd_assigned) delay = level.ex_ladder_artillery_first;
				else delay = level.ex_ladder_wmd_delay;
			self thread extreme\_ex_player_wmd_artillery::startWmd(delay, level.ex_ladder_artillery_first, level.ex_ladder_artillery_next);
		}
		else if(wmdtodo == 3)
		{
			napalm = (value >= level.ex_ladder_special && randomInt(100) < level.ex_wmd_napalm_chance);
			if(!wmd_assigned) delay = level.ex_ladder_airstrike_first;
				else delay = level.ex_ladder_wmd_delay;
			self thread extreme\_ex_player_wmd_airstrike::startWmd(delay, level.ex_ladder_airstrike_first, level.ex_ladder_airstrike_next, napalm);
		}
		else
		{
			if(!wmd_assigned) delay = level.ex_ladder_gunship_first;
				else delay = level.ex_ladder_wmd_delay;
			self thread extreme\_ex_main_gunship::startWmd(delay, level.ex_ladder_gunship_first, level.ex_ladder_gunship_next);
		}
	}
}

wmdLadderAllowedRandom(value)
{
	self endon("kill_thread");

	if(!level.ex_ladder_allow_mortar && !level.ex_ladder_allow_artillery && !level.ex_ladder_allow_airstrike && !level.ex_ladder_allow_special) return;

	wmd_assigned = (self.ex_mortars || self.ex_artillery || self.ex_airstrike || self.ex_gunship);
	if(wmd_assigned && !level.ex_ladder_wmd_upgrade) return;
	if(level.ex_gunship != 4 && self.ex_gunship) return;

	if(value < level.ex_ladder_allow_on)
	{
		if(wmd_assigned) self wmdStop();
		return;
	}

	mortar_allowed = level.ex_ladder_allow_mortar;
	artillery_allowed = level.ex_ladder_allow_artillery;
	airstrike_allowed = level.ex_ladder_allow_airstrike || (level.ex_gunship == 4 && level.ex_ladder_allow_special);
	gunship_allowed = (level.ex_gunship == 4 && level.ex_ladder_allow_special && (level.ex_ladder_gunship_next || !isDefined(self.pers["gunship"])));

	for(;;)
	{
		wmdtodo = randomInt(4) + 1;

		if(wmdtodo == 1 && mortar_allowed) break;
		if(wmdtodo == 2 && artillery_allowed) break;
		if(wmdtodo == 3 && airstrike_allowed) break;
		if(wmdtodo == 4 && gunship_allowed) break;

		wait( [[level.ex_fpstime]](0.1) );
	}

	if(wmd_assigned)
	{
		if(wmdtodo == 1) return;
		if(wmdtodo == 2 && (self.ex_artillery || self.ex_airstrike || self.ex_gunship)) return;
		if(wmdtodo == 3 && (self.ex_airstrike || self.ex_gunship)) return;
		if(wmdtodo == 4 && self.ex_gunship) return;
	}

	if(isPlayer(self))
	{
		self wmdStop();
		if(wmdtodo == 1)
		{
			if(!wmd_assigned) delay = level.ex_ladder_mortar_first;
				else delay = level.ex_ladder_wmd_delay;
			self thread extreme\_ex_player_wmd_mortars::startWmd(delay, level.ex_ladder_mortar_first, level.ex_ladder_mortar_next);
		}
		else if(wmdtodo == 2)
		{
			if(!wmd_assigned) delay = level.ex_ladder_artillery_first;
				else delay = level.ex_ladder_wmd_delay;
			self thread extreme\_ex_player_wmd_artillery::startWmd(delay, level.ex_ladder_artillery_first, level.ex_ladder_artillery_next);
		}
		else if(wmdtodo == 3)
		{
			napalm = (level.ex_ladder_allow_airstrike && level.ex_ladder_allow_special && randomInt(100) < level.ex_wmd_napalm_chance);
			if(!wmd_assigned) delay = level.ex_ladder_airstrike_first;
				else delay = level.ex_ladder_wmd_delay;
			self thread extreme\_ex_player_wmd_airstrike::startWmd(delay, level.ex_ladder_airstrike_first, level.ex_ladder_airstrike_next, napalm);
		}
		else
		{
			if(!wmd_assigned) delay = level.ex_ladder_gunship_first;
				else delay = level.ex_ladder_wmd_delay;
			self thread extreme\_ex_main_gunship::startWmd(delay, level.ex_ladder_gunship_first, level.ex_ladder_gunship_next);
		}
	}
}

//------------------------------------------------------------------------------
// Shared procedures
//------------------------------------------------------------------------------
wmdStop()
{
	// stop wmd binoc threads
	self notify("end_waitforuse");
	wait( [[level.ex_fpstime]](0.1) );

	// stop mortars
	self.ex_mortars = false;
	self notify("mortar_over");
	self notify("end_mortar");
	wait( [[level.ex_fpstime]](0.1) );

	// stop artillery
	self.ex_artillery = false;
	self notify("artillery_over");
	self notify("end_artillery");
	wait( [[level.ex_fpstime]](0.1) );

	// stop airstrike
	self.ex_airstrike = false;
	self notify("airstrike_over");
	self notify("end_airstike");
	wait( [[level.ex_fpstime]](0.1) );

	// stop gunship if it is linked to WMD
	if(level.ex_gunship == 4)
	{
		self.ex_gunship = false;
		self notify("gunship_over");
		self notify("end_gunship");
		wait( [[level.ex_fpstime]](0.1) );
	}

	// clear hud icon
	playerHudDestroy("wmd_icon");
}

friendlyInStrikeZone(targetpos)
{
	// return if friendly fire check has been disabled
	if(!level.ex_wmd_checkfriendly) return(false);

	// dont need to check friendly if gametype is not teamplay
	if(!level.ex_teamplay) return(false);

	if(!isDefined(targetpos)) return(undefined);

	if(distance(targetpos, self.origin) <= 1000) return(undefined);

	// check if players in the same team are in targetzone
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isPlayer(self) && isPlayer(players[i]))
		{
			if(players[i].sessionstate == "playing" && players[i].pers["team"] == self.pers["team"])
			{
				if(distance(targetpos, players[i].origin) <= 1000)
					return(true);
			}
		}
	}
	return(false);
}

//------------------------------------------------------------------------------
// Damage callback for Napalm
//------------------------------------------------------------------------------
callbackNapalmDamage(dev_index, device_info, parentdev_index)
{
	level endon("ex_gameover");

	burntime = 10;
	for(j = 0; j < burntime; j++)
	{
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			if(isDefined(players[i].pers["team"]) && players[i].pers["team"] == "spectator" || players[i].sessionteam == "spectator") continue;
			if(isDefined(players[i].ex_invulnerable) && players[i].ex_invulnerable) continue;

			if(level.ex_teamplay && (level.friendlyfire == "0" || level.friendlyfire == "2"))
				if(isPlayer(device_info.owner) && (players[i] != device_info.owner) && (players[i].pers["team"] == device_info.team)) continue;

			dst = distance(device_info.origin, players[i].origin);
			damarea = level.ex_devices[dev_index].range + (j * 50);
			if( dst > damarea || !isAlive(players[i]) ) continue;
			damage = int( 40 * (1 - (dst / damarea)) + 0.5 );

			if(damage < players[i].health)
			{
				players[i] thread burnPlayer(3);
				players[i].health = players[i].health - damage;
			}
			else
			{
				device_info.damage = damage;
				if(isDefined(parentdev_index)) players[i] thread [[level.ex_devPlayer]](parentdev_index, device_info);
					else players[i] thread [[level.ex_devPlayer]](dev_index, device_info);
			}
		}

		wait( [[level.ex_fpstime]](1) );
	}
}

burnPlayer(burntime)
{
	self endon("kill_thread");

	if(isDefined(self.ex_isonfire)) return;
	self.ex_isonfire = 1;

	if(randomint(100) > 30) extreme\_ex_main_utils::forceto("crouch");
	self playsound("scream");

	burntime = burntime * 4;
	for(i = 0; i < burntime; i++)
	{
		if(isDefined(self))
		{
			switch(randomint(12))
			{
				case  0: tag = "j_hip_le"; break;
				case  1: tag = "j_hip_ri"; break;
				case  2: tag = "j_knee_le"; break;
				case  3: tag = "j_ankle_ri"; break;
				case  4: tag = "j_knee_ri"; break;
				case  5: tag = "j_wrist_ri"; break;
				case  6: tag = "j_head"; break;
				case  7: tag = "j_shoulder_le"; break;
				case  8: tag = "j_shoulder_ri"; break;
				case  9: tag = "j_elbow_le"; break;
				case 10: tag = "j_elbow_ri"; break;
				default: tag = "j_wrist_le"; break;
			}

			playfxontag(level.ex_effect["fire_arm"], self, tag);
			playfxontag(level.ex_effect["fire_torso"], self, "j_spine2");

			wait( [[level.ex_fpstime]](0.25) );
		}
	}

	if(isAlive(self)) self.ex_isonfire = undefined;
}
