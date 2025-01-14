#include extreme\_ex_controller_hud;
#include extreme\_ex_player_wmd;

checkStreaks(attacker, weapon)
{
	self endon("disconnect");

	if(!isPlayer(attacker)) return;

	// killing spree and streaks
	if(level.ex_streak)
	{
		// killing spree
		if((level.ex_streak &  1) ==  1) self thread killSpree(attacker);

		// consecutive deaths
		if((level.ex_streak &  2) ==  2) self thread consecDeath(attacker);

		// noob and weapon streak
		if((level.ex_streak &  4) ==  4)
		{
			if(extreme\_ex_weapons::isWeaponType(weapon, "mg") || extreme\_ex_weapons::isWeaponType(weapon, "smg")) self thread noobStreak(attacker, weapon);
				else self thread weaponStreak(attacker, weapon);
		}
	}

	// check quick kill ladder
	if(level.ex_ladder && attacker != self)
		attacker thread killLadder();
}

killSpree(attacker)
{
	self endon("disconnect");

	if(!isPlayer(attacker)) return;
	if(level.ex_teamplay && attacker.pers["team"] == self.pers["team"])
	{
		attacker.pers["conseckill"]--;
		return;
	}

	if(attacker != self)
	{
		// check for end of a players killing spree
		if(self.pers["conseckill"] >= 5)
		{
			if(self.ex_obmonamsg)
			{
				amsg1 = undefined;
				amsg2 = undefined;

				if(self.pers["conseckill"] >= 30)
				{
					amsg1 = &"KILLSPREE_HAS_SAVED_ALL_OUR_ASSES_FROM";
					amsg2 = &"KILLSPREE_ANAL_RAPE";
				}
				else if(self.pers["conseckill"] >= 25)
				{
					amsg1 = &"KILLSPREE_HAS_SAVED_US_ALL_FROM";
					amsg2 = &"KILLSPREE_UNHOLY";
				}
				else if(self.pers["conseckill"] >= 20)
				{
					amsg1 = &"KILLSPREE_HAS_STOPPED_THE_UNSTOPPABLE";
					amsg2 = &"KILLSPREE_CRUSADE";
				}
				else if(self.pers["conseckill"] >= 15)
				{
					amsg1 = &"KILLSPREE_HAS_STOPPED_THE_UNSTOPPABLE";
					amsg2 = &"KILLSPREE_UNREAL";
				}
				else if(self.pers["conseckill"] >= 10)
				{
					amsg1 = &"KILLSPREE_HAS_STOPPED";
					amsg2 = &"KILLSPREE_FLUKISH";
				}
				else if(self.pers["conseckill"] >= 5)
				{
					amsg1 = &"KILLSPREE_HAS_STOPPED";
					amsg2 = &"KILLSPREE_PLURAL";
				}

				if(isDefined(amsg1)) iprintln(amsg1, [[level.ex_pname]](attacker));
				if(isDefined(amsg2)) iprintln(amsg2, [[level.ex_pname]](self));
			}

			self.pers["conseckill"] = 0;

			if(self.ex_obmonpsnd)
			{
				attacker playLocalSound("nailedhim");

				players = level.players;
				for(i = 0; i < players.size; i++) if(players[i] != self) players[i] playlocalsound("hallelujah");
				//self playlocalsound("hallelujah");
				//self.ex_deathmusic = false;
			}
		}

		// check for a player's killing spree
		if(attacker.pers["conseckill"] < 0) attacker.pers["conseckill"] = 0;

		attacker.pers["conseckill"]++;
		attacker thread extreme\_ex_player_obituary::obitlongstat("longspree", attacker.pers["conseckill"]);

		reward_points = 0;
		pmsg = undefined;
		amsg = undefined;
		psnd = undefined;
		pshd = undefined;

		if(attacker.pers["conseckill"] >= 5)
		{
			if(attacker.pers["conseckill"] == 5)
			{
				reward_points = int(extreme\_ex_main_utils::pow(1 * level.ex_reward_killspree, level.ex_reward_killspree_power));
				amsg = &"KILLSPREE_MSG_5";
				pmsg = &"KILLSPREE_KILLSPREE_PMSG";
				psnd = "killingspree";
				pshd = "x2_killingspree";
			}
			else if(attacker.pers["conseckill"] == 10)
			{
				reward_points = int(extreme\_ex_main_utils::pow(2 * level.ex_reward_killspree, level.ex_reward_killspree_power));
				amsg = &"KILLSPREE_MSG_10";
				pmsg = &"KILLSPREE_DOMINATING_PMSG";
				psnd = "dominating";
				pshd = "x2_dominating";
			}
			else if(attacker.pers["conseckill"] == 15)
			{
				reward_points = int(extreme\_ex_main_utils::pow(3 * level.ex_reward_killspree, level.ex_reward_killspree_power));
				amsg = &"KILLSPREE_MSG_15";
				pmsg = &"KILLSPREE_RAMPAGE_PMSG";
				psnd = "rampage";
				pshd = "x2_rampage";
			}
			else if(attacker.pers["conseckill"] == 20)
			{
				reward_points = int(extreme\_ex_main_utils::pow(4 * level.ex_reward_killspree, level.ex_reward_killspree_power));
				amsg = &"KILLSPREE_MSG_20";
				pmsg = &"KILLSPREE_UNSTOPPABLE_PMSG";
				psnd = "unstoppable";
				pshd = "x2_unstoppable";
			}
			else if(attacker.pers["conseckill"] == 25)
			{
				reward_points = int(extreme\_ex_main_utils::pow(5 * level.ex_reward_killspree, level.ex_reward_killspree_power));
				amsg = &"KILLSPREE_MSG_25";
				pmsg = &"KILLSPREE_WICKED_SICK_PMSG";
				psnd = "wickedsick";
				pshd = "x2_wickedsick";
			}
			else if(attacker.pers["conseckill"] >= 30)
			{
				if(attacker.pers["conseckill"] == 30)
					reward_points = int(extreme\_ex_main_utils::pow(6 * level.ex_reward_killspree, level.ex_reward_killspree_power));

				if(attacker.pers["conseckill"]%5 == 0)
				{
					amsg = &"KILLSPREE_MSG_30";
					ps = randomInt(100);
					if(ps <= 33)
					{
						psnd = "godlike";
						pmsg = &"KILLSPREE_GODLIKE_PMSG";
						pshd = "x2_godlike";
					}
					else if(ps <= 66)
					{
						psnd = "holyshit";
						pmsg = &"KILLSPREE_HOLY_SHIT_PMSG";
						pshd = "x2_holyshit";
					}
					else
					{
						psnd = "slaughter";
						pmsg = &"KILLSPREE_SLAUGHTER_PMSG";
						pshd = "x2_slaughter";
					}
				}
			}

			if( (reward_points > 0) && (level.ex_currentgt != "lms") && (level.ex_currentgt != "ihtf") )
				attacker thread [[level.ex_scorePlayer]](reward_points, "bonus");

			if(self.ex_obmonamsg && isDefined(amsg)) iprintln(amsg, [[level.ex_pname]](attacker));
			if((level.ex_arcade_shaders & 1) == 1 && isDefined(pshd)) attacker thread extreme\_ex_player_arcade::showArcadeShader(pshd, level.ex_arcade_shaders_spree);
				else if(self.ex_obmonpmsg && isDefined(pmsg)) attacker iprintlnbold(pmsg);
			if(self.ex_obmonpsnd && isDefined(psnd)) attacker playLocalSound(psnd);

			// check for WMD
			if(level.ex_wmd == 1)
			{
				if(attacker.pers["conseckill"]%5 == 0) attacker thread checkWmd(attacker.pers["conseckill"]);
			}
			// check for stand-alone gunship perk
			else if(level.ex_gunship == 1 && (attacker.pers["conseckill"] % level.ex_gunship_killspree == 0))
			{
				grant = true;
				// check if attacker already got the gunship once
				if(level.ex_gunship_killspree_once && isDefined(attacker.pers["gunship"])) grant = false;
				// if attacker is making kills from within the gunship now, deny another gunship
				if( (isPlayer(level.gunship.owner) && level.gunship.owner == attacker) ||
				  (level.ex_gunship_special && isPlayer(level.gunship_special.owner) && level.gunship_special.owner == attacker) ) grant = false;

				if(grant) attacker thread extreme\_ex_main_gunship::gunshipPerk(1);
			}
		}
	}
}

consecDeath(attacker)
{
	self endon("disconnect");

	if(!isPlayer(attacker)) return;
	if(attacker.pers["team"] == self.pers["team"] && level.ex_teamplay) return;

	if(self.pers["conseckill"] > 0) self.pers["conseckill"] = 0;
	self.pers["conseckill"]--;

	if(self.pers["conseckill"] <= -5 && self.ex_obmonamsg)
	{
		amsg = undefined;

		if(self.pers["conseckill"] == -5) amsg = &"CONSECDEATHS_MSG_5";
		else if(self.pers["conseckill"] == -8) amsg = &"CONSECDEATHS_MSG_8";
		else if(self.pers["conseckill"] == -10) amsg = &"CONSECDEATHS_MSG_10";
		else if(self.pers["conseckill"] == -13) amsg = &"CONSECDEATHS_MSG_13";
		else if(self.pers["conseckill"] <= -16) amsg = &"CONSECDEATHS_MSG_16";

		if(isDefined(amsg)) iprintln(amsg, [[level.ex_pname]](self));
	}
}

noobStreak(attacker, sWeapon)
{
	self endon("disconnect");

	if(!isPlayer(attacker)) return;
	if(attacker.pers["team"] == self.pers["team"] && level.ex_teamplay) return;

	if(isDefined(attacker.pers["weaponname"]) && sWeapon == attacker.pers["weaponname"]) attacker.pers["noobstreak"]++;
	else
	{
		attacker.pers["noobstreak"] = 1;
		attacker.pers["weaponname"] = sWeapon;
	}

	if(attacker.pers["noobstreak"]%5==0) attacker.pers["spamkill"]++;

	if(attacker.pers["noobstreak"] >= 5 && self.ex_obmonamsg)
	{
		amsg1 = undefined;
		amsg2 = undefined;

		if(attacker.pers["noobstreak"] == 5) amsg1 = &"NOOBSTREAK_MSG_5";
		else if(attacker.pers["noobstreak"] == 10) amsg1 = &"NOOBSTREAK_MSG_10";
		else if(attacker.pers["noobstreak"] == 15) amsg1 = &"NOOBSTREAK_MSG_15";
		else if(attacker.pers["noobstreak"] == 20) amsg1 = &"NOOBSTREAK_MSG_20";
		else if(attacker.pers["noobstreak"] == 25) amsg1 = &"NOOBSTREAK_MSG_25";
		else if(attacker.pers["noobstreak"] == 30) amsg1 = &"NOOBSTREAK_MSG_30";
		else if(attacker.pers["noobstreak"] >= 35)
		{
			amsg1 = &"NOOBSTREAK_MSG_35A";
			amsg2 = &"NOOBSTREAK_MSG_35B";
		}

		if(isDefined(amsg1))
		{
			iprintln(amsg1, [[level.ex_pname]](attacker));
			if(level.ex_streak_info)
			{
				attacker_weapon = maps\mp\gametypes\_weapons::getWeaponName(sWeapon);

				if(maps\mp\gametypes\_weapons::useAn(sWeapon)) iprintln(&"NOOBSTREAK_USING_AN", attacker_weapon);
					else iprintln(&"NOOBSTREAK_USING_A", attacker_weapon);
			}

			if(isDefined(amsg2)) iprintln(amsg2, attacker.pers["noobstreak"]);
		}
	}
}

weaponStreak(attacker, sWeapon)
{
	self endon("disconnect");

	if(!isPlayer(attacker)) return;
	if(attacker.pers["team"] == self.pers["team"] && level.ex_teamplay) return;

	if(isDefined(attacker.pers["weaponname"]) && sWeapon == attacker.pers["weaponname"]) attacker.pers["weaponstreak"]++;
	else
	{
		attacker.pers["weaponstreak"] = 1;
		attacker.pers["weaponname"] = sWeapon;
	}

	if(attacker.pers["weaponstreak"] >= 5 && self.ex_obmonamsg)
	{
		amsg1 = undefined;
		amsg2 = undefined;

		if(attacker.pers["weaponstreak"] == 5) amsg1 = &"WEAPONSTREAK_MSG_5";
		else if(attacker.pers["weaponstreak"] == 10) amsg1 = &"WEAPONSTREAK_MSG_10";
		else if(attacker.pers["weaponstreak"] == 15) amsg1 = &"WEAPONSTREAK_MSG_15";
		else if(attacker.pers["weaponstreak"] == 20) amsg1 = &"WEAPONSTREAK_MSG_20";
		else if(attacker.pers["weaponstreak"] == 25) amsg1 = &"WEAPONSTREAK_MSG_25";
		else if(attacker.pers["weaponstreak"] == 30) amsg1 = &"WEAPONSTREAK_MSG_30";
		else if(attacker.pers["weaponstreak"] >= 35)
		{
			amsg1 = &"WEAPONSTREAK_MSG_35A";
			amsg2 = &"WEAPONSTREAK_MSG_35B";
		}

		if(isDefined(amsg1))
		{
			iprintln(amsg1, [[level.ex_pname]](attacker));
			if(level.ex_streak_info)
			{
				attacker_weapon = maps\mp\gametypes\_weapons::getWeaponName(sWeapon);

				if(maps\mp\gametypes\_weapons::useAn(sWeapon)) iprintln(&"WEAPONSTREAK_USING_AN", attacker_weapon);
					else iprintln(&"WEAPONSTREAK_USING_A", attacker_weapon);
			}

			if(isDefined(amsg2)) iprintln(amsg2, attacker.pers["weaponstreak"]);
		}
	}
}

killLadder()
{
	self endon("disconnect");

	self.pers["conskillnumb"]++;
	thiskilltime = getTime();
	prevkilltime = self.pers["conskillprev"];
	self.pers["conskillprev"] = thiskilltime;
	if(prevkilltime == 0) prevkilltime = thiskilltime;
	self.pers["conskilltime"] = self.pers["conskilltime"] + (thiskilltime - prevkilltime) / 1000;

	if(self.pers["conskillnumb"] < 2) return;

	if(self.pers["conskillnumb"] == 9 && self.pers["conskilltime"] <= level.ex_ladder_9)
	{
		ladder_max = 9;
		ladder_snd = "topgun";
		ladder_shd = "x2_topgun";
	}
	else if(self.pers["conskillnumb"] == 8 && self.pers["conskilltime"] <= level.ex_ladder_8)
	{
		ladder_max = 8;
		ladder_snd = "ludicrouskill";
		ladder_shd = "x2_ludicrouskill";
	}
	else if(self.pers["conskillnumb"] == 7 && self.pers["conskilltime"] <= level.ex_ladder_7)
	{
		ladder_max = 7;
		ladder_snd = "monsterkill";
		ladder_shd = "x2_monsterkill";
	}
	else if(self.pers["conskillnumb"] == 6 && self.pers["conskilltime"] <= level.ex_ladder_6)
	{
		ladder_max = 6;
		ladder_snd = "ultrakill";
		ladder_shd = "x2_ultrakill";
	}
	else if(self.pers["conskillnumb"] == 5 && self.pers["conskilltime"] <= level.ex_ladder_5)
	{
		ladder_max = 5;
		ladder_snd = "megakill";
		ladder_shd = "x2_megakill";
	}
	else if(self.pers["conskillnumb"] == 4 && self.pers["conskilltime"] <= level.ex_ladder_4)
	{
		ladder_max = 4;
		ladder_snd = "multikill";
		ladder_shd = "x2_multikill";
	}
	else if(self.pers["conskillnumb"] == 3 && self.pers["conskilltime"] <= level.ex_ladder_3)
	{
		ladder_max = 3;
		ladder_snd = "triplekill";
		ladder_shd = "x2_triplekill";
	}
	else if(self.pers["conskillnumb"] == 2 && self.pers["conskilltime"] <= level.ex_ladder_2)
	{
		ladder_max = 2;
		ladder_snd = "doublekill";
		ladder_shd = "x2_doublekill";
	}
	else
	{
		ladder_max = 1;
		ladder_snd = undefined;
		ladder_shd = undefined;
		self.pers["conskillnumb"] = 1;
		self.pers["conskilltime"] = 0;
	}

	if(ladder_max > 1)
	{
		self notify("killspree_update");
		waittillframeend;
		self endon("killspree_update");

		// wait a brief moment to let quick consecutive kills come through
		wait( [[level.ex_fpstime]](0.5) );

		if((level.ex_arcade_shaders & 2) == 2) self thread extreme\_ex_player_arcade::showArcadeShader(ladder_shd, level.ex_arcade_shaders_ladder);
		wait( level.ex_fps_frame );
		self playLocalSound(ladder_snd);

		// check for WMD
		if(level.ex_wmd == 3)
		{
			self thread checkWmd(ladder_max);
		}
		// check for stand-alone gunship perk
		else if(level.ex_gunship == 3 && ladder_max >= level.ex_gunship_ladder)
		{
			grant = true;
			// check if attacker already got the gunship once
			if(level.ex_gunship_ladder_once && isDefined(self.pers["gunship"])) grant = false;
			// if attacker is making kills from within the gunship now, deny another gunship
			if( (isPlayer(level.gunship.owner) && level.gunship.owner == self) ||
			  (level.ex_gunship_special && isPlayer(level.gunship_special.owner) && level.gunship_special.owner == self) ) grant = false;

			if(grant) self thread extreme\_ex_main_gunship::gunshipPerk(1);
		}
	}
}
