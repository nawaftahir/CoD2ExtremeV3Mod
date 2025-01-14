#include extreme\_ex_weapons;
#include extreme\_ex_controller_hud;

main()
{
	self endon("kill_thread");

	// bots do not sprint
	if(isDefined(self.pers["isbot"])) return;

	// check if account system grants access
	if(level.ex_accounts && self.pers["account"]["status"] == 1 && (level.ex_accounts_lock & 1) == 1) return;

	// set the variables
	self.ex_sprintmsg = undefined;
	self.ex_sprinttime = level.ex_sprinttime;
	self.ex_playsprint = false;

	// draw the hud elements
	if(level.ex_sprinthud) self thread sprintBar();

	// start the sprint function monitor
	self thread sprintMonitor();

	// start the sprint hud monitor
	if(level.ex_sprinthudhint)
	{
		if(!isDefined(self.pers["sprinthintcount"])) self.pers["sprinthintcount"] = 0;
		if(self.pers["sprinthintcount"] < 5) self thread sprintHintMonitor();
	}
}

sprintMonitor()
{
	self endon("kill_thread");

	// set sprint control vars
	sprintstancetimer = 0;
	sprintstop = false;

	// reset the recover time
	recovertime = 0;

	// set the default ammo
	sprintammo = 100;

	while(1)
	{
		wait( level.ex_fps_frame );

		sprint = (level.ex_sprinttime - self.ex_sprinttime) / level.ex_sprinttime;

		primary = self getWeaponSlotWeapon("primary");
		if(self.ex_sprinttime < level.ex_sprinttime && primary != game["sprint"])
		{
			// don't increase sprinttime unless recovertime has passed
			if(recovertime > 0) recovertime--;
				else self.ex_sprinttime++;
		}

		// keep the sprint bar updated
		if(level.ex_sprinthud) self thread sprintBarUpdate(sprint);

		// gotta be moving
		if(!self.ex_moving) continue;

		// refuse sprint until they completely recovered from stealth mode
		if(isDefined(self.ex_stealth)) continue;

		// no sprint check if player in gunship
		if( (level.ex_gunship && isPlayer(level.gunship.owner) && level.gunship.owner == self) ||
		    (level.ex_gunship_special && isPlayer(level.gunship_special.owner) && level.gunship_special.owner == self) ) continue;

		// wait here until they press the use key, unless they are sprinting!
		if(!self.ex_sprinting && !self useButtonPressed()) continue;

		// hold USE for 0.25 sec (could be a normal weapons change)
		if(!self.ex_sprinting && self useButtonPressed())
		{
			count = 0;
			while(self useButtonPressed() && count < 5)
			{
				wait( level.ex_fps_frame );
				count++;
			}
			if(count < 5) continue;
		}

		// if sprinting and anti-run punishment in effect - stop sprinting
		if(self.ex_sprinting && level.ex_antirun && self.antirun_puninprog) sprintstop = true;

		// ok, they pressed it for long enough, maybe they want to sprint?
		if(isPlayer(self) && self useButtonPressed() && self.ex_sprinttime > 0 && !sprintstop)
		{
			// cannot sprint if they are by an ammocrate possibly going to rearm
			if(isDefined(self.ex_amc_msg_displayed)) continue;

			// cannot sprint if planting or defusing bomb in SD or ESD
			if(isDefined(self.bomb_handling)) continue;
			
			// cannot sprint while healing
			if(isDefined(self.ex_ishealing)) continue;

			// cannot sprint while using binoculars
			if(self.ex_binocuse) continue;

			// cannot sprint if not moving
			if(!self.ex_pace) continue;
			
			// cannot sprint if stance does not match
			if(self.ex_stance > (level.ex_sprint - 1))
			{
				// if already sprinting, allow stance changes for half a sec (bumps and hills)
				if(self.ex_sprinting)
				{
					if(sprintstancetimer < 10) sprintstancetimer += 1;
						else sprintstop = true;
				}
				else continue;
			}
			else sprintstancetimer = 0;

			// cannot sprint if carrying a flag (heavy flag)
			if(level.ex_sprintheavyflag && isDefined(self.flagAttached))
			{
				if(!level.ex_ranksystem || self.pers["rank"] <= level.ex_sprintheavyflag_rank)
				{
					if(self.ex_sprinting) sprintstop = true;
					self thread sprintMessage(&"SPRINT_FLAG_NO_SPRINT", 3);
					continue;
				}
			}

			// get current weapon
			current = self getCurrentWeapon();

			// cannot sprint if current weapon is a mobile mg (heavy mg)
			if(level.ex_sprintheavymg && isWeaponType(current, "mobilemg"))
			{
				if(!level.ex_ranksystem || self.pers["rank"] <= level.ex_sprintheavymg_rank)
				{
					if(self.ex_sprinting) sprintstop = true;
					self thread sprintMessage(&"SPRINT_WEAPON_NO_SPRINT", 3);
					continue;
				}
			}

			// cannot sprint if current weapon is a rocket launcher (heavy panzer)
			if(level.ex_sprintheavypanzer && isWeaponType(current, "rl"))
			{
				if(!level.ex_ranksystem || self.pers["rank"] <= level.ex_sprintheavypanzer_rank)
				{
					if(self.ex_sprinting) sprintstop = true;
					self thread sprintMessage(&"SPRINT_WEAPON_NO_SPRINT", 3);
					continue;
				}
			}

			// ready to sprint...
			primary = self getWeaponSlotWeapon("primary");
			if(!self.ex_sprinting && primary != game["sprint"])
			{
				extreme\_ex_weapons::stopWeaponChangeMonitor();

				// get the sprint weapon in the primary slot
				self setWeaponSlotWeapon("primary", game["sprint"]);
				self setWeaponSlotAmmo("primary", 0);
				self switchToWeapon(game["sprint"]);

				self.ex_sprinting = true;
				self.ex_playsprint = true;
				self thread sprintSound();
			}
			else
			{
				// decrease the available sprint time depending on stance
				rate = 3; // prone
				if(self.ex_stance == 0) rate = 1; // standing
					else if(self.ex_stance == 1) rate = 2; // crouching

				self.ex_sprinttime -= rate;
				self.ex_sprinting = true;

				// update the sprint ammo counter
				sprintammo = int(100 * (1.0 - sprint));
				self setWeaponSlotAmmo("primary", sprintammo);
			}
		}
		else
		{
			// stopped sprinting
			self.ex_playsprint = false;
			self.ex_sprinting = false;
			sprintstancetimer = 0;
			sprintstop = false;

			if(self getWeaponSlotWeapon("primary") == game["sprint"])
			{
				// reset the recover time variable
				recovertime = level.ex_sprintrecovertime;

				// calculate the recover time if full sprint time has not been used
				if(self.ex_sprinttime > 0) recovertime = int(recovertime * sprint + 0.5);

				// start the weapons monitor again
				extreme\_ex_weapons::startWeaponChangeMonitor(false, false);
			}
		}
	}
}

sprintMessage(msg, time)
{
	self endon("kill_thread");

	if(!isDefined(self.ex_sprintmsg))
	{
		self.ex_sprintmsg = true;
		self iprintlnbold(msg);
		wait( [[level.ex_fpstime]](time) );
		extreme\_ex_main_utils::iprintlnboldCLEAR("self", 5);
		self.ex_sprintmsg = undefined;
	}
}

sprintBar()
{
	self endon("kill_thread");

	hud_index = playerHudCreate("sprinthud_back", 585, 400, 1, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index != -1) playerHudSetShader(hud_index, "gfx/hud/hud@health_back.tga", 12, 34);

	hud_index = playerHudCreate("sprinthud_bar", 585, 400, 0, (0,0,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index != -1) playerHudSetShader(hud_index, "gfx/hud/hud@health_bar.tga", 10, 32);
}

sprintBarUpdate(sprint)
{
	self endon("kill_thread");

	hud_index = playerHudIndex("sprinthud_bar");
	if(hud_index == -1) return;

	if(self.ex_sprinttime == level.ex_sprinttime) playerHudSetAlpha(hud_index, 0);
		else playerHudSetAlpha(hud_index, 1);

	if(!self.ex_sprinttime) playerHudSetColor(hud_index, (1,0,0));
		else playerHudSetColor(hud_index, (sprint, 0, 1.0 - sprint));

	hudheight = 32 - int(32 * (1.0 - sprint));
	if(hudheight < 1) hudheight = 1;
	playerHudSetShader(hud_index, "gfx/hud/hud@health_back.tga", 10, hudheight);
}

sprintHintMonitor()
{
	self endon("kill_thread");

	sprinthintdelay = 0;

	while(isAlive(self) && self.sessionstate == "playing")
	{
		wait( [[level.ex_fpstime]](1) );

		if(isDefined(self.ex_isparachuting)) continue;

		// player figured it out; quit the monitor
		if(self.ex_sprinting)
		{
			self.pers["sprinthintcount"] = 5;
			return;
		}

		if(sprinthintdelay)
		{
			sprinthintdelay--;
			continue;
		}

		if(isPlayer(self))
		{
			if(self.ex_sprinttime && self.ex_pace && (level.ex_sprint - 1) >= self.ex_stance)
			{
				playerHudAnnounce(&"SPRINT_HINT");
				sprinthintdelay = 20;
				self.pers["sprinthintcount"]++;
				if(self.pers["sprinthintcount"] == 5) return;
			}
		}
	}
}

sprintSound()
{
	self endon("kill_thread");

	self notify("kill_sprintsound");
	self endon("kill_sprintsound");

	wait( [[level.ex_fpstime]](2) );
	self.ex_headmarker playloopsound("sprint");

	while(isPlayer(self) && self.ex_playsprint) wait( level.ex_fps_frame );

	if(isPlayer(self))
	{
		stage = int(level.ex_sprinttime / 3);
		if(self.ex_sprinttime >= stage * 2) duration = 2;
			else if(self.ex_sprinttime > stage && self.ex_sprinttime < stage * 2) duration = 4;
				else duration = 8;
		self.ex_sprintreco = true;

		wait( [[level.ex_fpstime]](duration) );

		if(isPlayer(self))
		{
			self.ex_sprintreco = false;
			self.ex_headmarker stoploopsound();
			self.ex_headmarker playsound("sprintover");
		}
	}
}
