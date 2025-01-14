minefields()
{
	if(!level.ex_minefields) return;

	minefields = getEntArray("minefield", "targetname");
	if(minefields.size > 0)
	{
		switch(level.ex_minefields)
		{
			case 1: [[level.ex_devRequest]]("minefield_reg"); break;
			case 2: [[level.ex_devRequest]]("minefield_gas"); break;
			case 3: [[level.ex_devRequest]]("minefield_fire"); break;
		}
	}
	
	for(i = 0; i < minefields.size; i++) minefields[i] thread minefieldThink();
}

minefieldThink()
{
	level endon("ex_gameover");

	while(1)
	{
		self waittill("trigger", other);

		if(isPlayer(other))
		{
			if(isDefined(other.ex_isparachuting) || isDefined(other.minefield)) continue;
			if( (level.ex_gunship && isPlayer(level.gunship.owner) && level.gunship.owner == other) ||
			    (level.ex_gunship_special && isPlayer(level.gunship_special.owner) && level.gunship_special.owner == other) ) continue;

			other thread minefieldKill(self);
		}
	}
}

minefieldKill(trigger)
{
	level endon("ex_gameover");

	self.ex_invulnerable = false;
	self.minefield = true;
	self playsound("minefield_click");

	if(!level.ex_minefields_instant) wait( [[level.ex_fpstime]](0.5 + randomFloat(0.5)) );

	if(isDefined(self) && self isTouching(trigger))
	{
		explosion = spawn("script_origin", self getOrigin());

		// device info to pass on
		device_info = [[level.ex_devInfo]](self, self.pers["team"]);
		device_info.dodamage = true;

		// device explosion
		switch(level.ex_minefields)
		{
			case 1: explosion thread [[level.ex_devExplode]]("minefield_reg", device_info); break;
			case 2: explosion thread [[level.ex_devExplode]]("minefield_gas", device_info); break;
			case 3: explosion thread [[level.ex_devExplode]]("minefield_fire", device_info); break;
		}

		wait(1);
		explosion delete();
	}
	
	self.minefield = undefined;
}
