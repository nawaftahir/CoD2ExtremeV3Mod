// THIS FILE IS AUTOGENERATED, DO NOT MODIFY
main()
{
	switch(randomint(level.ex_british_normandy))
	{
		case 0:
			if(level.ex_camouflage) character\mp_british_normandy_boon_camo::main();
				else character\mp_british_normandy_boon::main();
			break;
		case 1:
			character\mp_british_normandy_chance::main();
			break;
		case 2:
			character\mp_british_normandy_harry::main();
			break;
		case 3:
			character\mp_british_normandy_joel::main();
			break;
		case 4:
			character\mp_british_normandy_macgregor::main();
			break;
		case 5:
			character\mp_british_normandy_paul::main();
			break;
	}
}

precache()
{
	if(level.ex_british_normandy > 0)
	{
		if(level.ex_camouflage) character\mp_british_normandy_boon_camo::precache();
			else character\mp_british_normandy_boon::precache();
	}
	if(level.ex_british_normandy > 1) character\mp_british_normandy_chance::precache();
	if(level.ex_british_normandy > 2) character\mp_british_normandy_harry::precache();
	if(level.ex_british_normandy > 3) character\mp_british_normandy_joel::precache();
	if(level.ex_british_normandy > 4) character\mp_british_normandy_macgregor::precache();
	if(level.ex_british_normandy > 5) character\mp_british_normandy_paul::precache();

	if(level.ex_hatmodels) character\mp_hatmodels::mp_british_normandy_precache();
}
