#include extreme\_ex_controller_hud;

main()
{
	level endon("round_ended");
	self endon("kill_thread");

	wait( [[level.ex_fpstime]](level.ex_anticamp_delay) );

	iscamping = false;
	checkpos = self.origin;
	checktime = 0;
	evactime = 0;

	while(isPlayer(self) && isAlive(self) && self.sessionstate == "playing")
	{
		wait( [[level.ex_fpstime]](1) );

		// skip camper check if meeting these conditions
		if(self.ex_iscamper || self.ex_isunknown || self.ex_sinbin || self.ex_inmenu) continue;

		// skip if flag carrier
		if(isDefined(self.flagAttached)) continue;

		// skip if healing or handling ammocrate, bomb, trip or mine
		if(isDefined(self.ex_amc_rearm) || isDefined(self.bomb_handling) || isDefined(self.ex_ishealing) || self.trip_handling || self.mine_handling) continue;

		// skip if in gunship
		if((level.ex_gunship && isPlayer(level.gunship.owner) && level.gunship.owner == self) ||
		   (level.ex_gunship_special && isPlayer(level.gunship_special.owner) && level.gunship_special.owner == self)) continue;

		// skip if mounted flak
		if(isDefined(self.flak_handling)) continue;

		// skip if player is in jail (LIB)
		if(level.ex_currentgt == "lib" && isDefined(self.in_jail) && self.in_jail) continue;

		// skip while being frozen (FT)
		if(level.ex_currentgt == "ft" && isDefined(self.frozenstate) && self.frozenstate == "frozen") continue;

		// skip if bomb planted (SD)
		//if(level.ex_currentgt == "sd" && level.bombplanted) continue;

		// snipers
		if((level.ex_anticamp & 2) == 2 && extreme\_ex_weapons::isWeaponType(self getcurrentweapon(), "sniper"))
		{
			if(iscamping)
			{
       	//level thread extreme\_ex_main_utils::dropCircle(checkpos, level.ex_anticamp_evacarea_sniper, (1,0,0), 1);
				if(distance(checkpos, self.origin) > level.ex_anticamp_evacarea_sniper)
				{
					iscamping = false;
					checktime = 0;
					checkpos = self.origin;
				}
				else evactime++;

				if(evactime >= level.ex_anticamp_evactime_sniper)
				{
					iscamping = false;
					checktime = 0;
					self thread punishCamper();
				}
			}
			else
			{
       	//level thread extreme\_ex_main_utils::dropCircle(checkpos, level.ex_anticamp_checkarea_sniper, (0,1,0), 1);
				if(distance(checkpos, self.origin) > level.ex_anticamp_checkarea_sniper)
				{
					checktime = 0;
					checkpos = self.origin;
				}
				else checktime++;

				if(checktime >= level.ex_anticamp_checktime_sniper)
				{
					iscamping = true;
					evactime = 0;
					if(level.ex_anticamp_warning_sniper) self iprintlnbold(&"CAMPING_WARNING_MESSAGE_SELF", [[level.ex_pname]](self));
				}
			}
		}
		// non-snipers
		else if((level.ex_anticamp & 1) == 1)
		{
			if(iscamping)
			{
       	//level thread extreme\_ex_main_utils::dropCircle(checkpos, level.ex_anticamp_evacarea, (1,0,0), 1);
				if(distance(checkpos, self.origin) > level.ex_anticamp_evacarea)
				{
					iscamping = false;
					checktime = 0;
					checkpos = self.origin;
				}
				else evactime++;

				if(evactime >= level.ex_anticamp_evactime)
				{
					iscamping = false;
					checktime = 0;
					self thread punishCamper();
				}
			}
			else
			{
       	//level thread extreme\_ex_main_utils::dropCircle(checkpos, level.ex_anticamp_checkarea, (0,1,0), 1);
				if(distance(checkpos, self.origin) > level.ex_anticamp_checkarea)
				{
					checktime = 0;
					checkpos = self.origin;
				}
				else checktime++;

				if(checktime >= level.ex_anticamp_checktime)
				{
					iscamping = true;
					evactime = 0;
					if(level.ex_anticamp_warning) self iprintlnbold(&"CAMPING_WARNING_MESSAGE_SELF", [[level.ex_pname]](self));
				}
			}
		}
	}
}

punishCamper()
{
	switch(level.ex_anticamp_punishment)
	{
		case 1:	self thread markCamper(); break;
		case 2:	self thread blowUpCamper(); break;
		case 3:	self thread shellshockCamper(false); break;
		case 4:	self thread shellshockCamper(true); break;
		default:
		{
			switch(randomInt(4) + 1)
			{
				case 1: self thread markCamper(); break;
				case 2:	self thread blowUpCamper(); break;
				case 3:	self thread shellshockCamper(false); break;
				case 4:	self thread shellshockCamper(true); break;
			}
		}
	}
}

markCamper()
{
	level endon("round_ended");
	self endon("kill_thread");
	self endon("stopcamper");

	if(self.ex_iscamper || (isDefined(level.roundended) && level.roundended) || self.sessionstate != "playing") return;
 
	self removeCamper();
	self.ex_objnum = levelHudGetObjective();

	if(self.ex_objnum)
	{
		self.ex_iscamper = true;

		// notify player and players
		self iprintlnbold(&"CAMPING_MARKED_MESSAGE_SELF", [[level.ex_pname]](self));
		self iprintlnbold(&"CAMPING_TIME_MESSAGE_SELF", level.ex_camptimer);
		iprintln(&"CAMPING_MARKED_MESSAGE_ALL", [[level.ex_pname]](self));
		iprintln(&"CAMPING_TIME_MESSAGE_ALL", level.ex_camptimer);

		compass_team = "none";
		if(self.pers["team"] == "allies") compass_icon = game["hudicon_allies"];
			else compass_icon = game["hudicon_axis"];

		objective_add(self.ex_objnum, "current", self.origin, compass_icon);
		objective_team(self.ex_objnum, compass_team);

		if(level.ex_camptimer >= 1) self thread countCamper();
	
		while(isPlayer(self) && isAlive(self) && self.pers["team"] != "spectator")
		{
			for(i = 0; (i < 60 && isPlayer(self) && isAlive(self)); i++)
			{
				if((i <= 29) && self.ex_iscamper) objective_icon(self.ex_objnum, "objpoint_radio");
					else if((i >= 30) && self.ex_iscamper) objective_icon(self.ex_objnum, compass_icon);

				if(self.ex_iscamper) objective_position(self.ex_objnum, self.origin);

				wait( level.ex_fps_frame );
			}
		}
	}
}

blowUpCamper()
{
	level endon("round_ended");
	self endon("kill_thread");

	if(self.ex_iscamper || (isDefined(level.roundended) && level.roundended) || self.sessionstate != "playing") return;

	self.ex_iscamper = true;
	
	self iprintlnbold(&"CAMPING_BLOWN_MESSAGE_SELF", [[level.ex_pname]](self));
	iprintln(&"CAMPING_BLOWN_MESSAGE_ALL", [[level.ex_pname]](self));
	wait( [[level.ex_fpstime]](1.5) );
	
	playfx(level.ex_effect["barrel"], self.origin);
	self playsound("mortar_explosion1");
	wait( level.ex_fps_frame );

	self.ex_forcedsuicide = true;
	self suicide();
}

shellshockCamper(diswep)
{
	level endon("round_ended");
	self endon("kill_thread");
	self endon("stopcamper");

	if(!isDefined(diswep)) diswep = false;

	if(self.ex_iscamper || (isDefined(level.roundended) && level.roundended) || self.sessionstate != "playing") return;
 
	self.ex_iscamper = true;
	time = undefined;

	// notify player and players
	self iprintlnbold(&"CAMPING_SHOCK_MESSAGE_SELF", [[level.ex_pname]](self));
	self iprintlnbold(&"CAMPING_TIME_MESSAGE_SELF", level.ex_camptimer);
	iprintln(&"CAMPING_SHOCK_MESSAGE_ALL", [[level.ex_pname]](self));
	iprintln(&"CAMPING_TIME_MESSAGE_ALL", level.ex_camptimer);
	self thread countCamper();

	while(isPlayer(self) && isAlive(self) && self.pers["team"] != "spectator" && self.ex_iscamper)
	{
		time = randomInt(5) + 5;
		if(isPlayer(self))
		{
			self shellshock("medical", time);
			if(diswep) self thread extreme\_ex_weapons::dropCurrentWeapon();
		}

		wait( [[level.ex_fpstime]](time + randomInt(5)) );
	}
}

countCamper()
{
	self endon("kill_thread");

	wait( [[level.ex_fpstime]](level.ex_camptimer - 1) );

	if(isPlayer(self))
	{
		self.ex_iscamper = false;
		if(isDefined(self.ex_objnum)) self removeCamper();
		self notify("stopcamper");
		self iprintlnbold(&"CAMPING_SURVIVED_MESSAGE_SELF", [[level.ex_pname]](self));
		iprintln(&"CAMPING_SURVIVED_MESSAGE_ALL", [[level.ex_pname]](self));
	}
}

removeCampers()
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isPlayer(players[i]) && isDefined(players[i].ex_objnum))
			players[i] removeCamper();
	}
}

removeCamper()
{
	self endon("disconnect");

	if(isDefined(self.ex_objnum))
	{
		levelHudFreeObjective(self.ex_objnum);
		self.ex_objnum = undefined;
	}
}
