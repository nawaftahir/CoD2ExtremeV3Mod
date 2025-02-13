init()
{
	[[level.ex_precacheShader]]("mpflag_spectator");

	switch(game["allies"])
	{
		case "american":
			[[level.ex_PrecacheShader]]("mpflag_american");
			setcvar("g_TeamName_Allies", &"MPUI_AMERICAN");
			setcvar("g_TeamColor_Allies", ".25 .75 .25");
			setcvar("g_ScoresBanner_Allies", "mpflag_american");
			break;

		case "british":
			[[level.ex_PrecacheShader]]("mpflag_british");
			setcvar("g_TeamName_Allies", &"MPUI_BRITISH");
			setcvar("g_TeamColor_Allies", ".25 .25 .75");
			setcvar("g_ScoresBanner_Allies", "mpflag_british");
			break;

		default:
			assert(game["allies"] == "russian");
			[[level.ex_PrecacheShader]]("mpflag_russian");
			setcvar("g_TeamName_Allies", &"MPUI_RUSSIAN");
			setcvar("g_TeamColor_Allies", ".75 .25 .25");
			setcvar("g_ScoresBanner_Allies", "mpflag_russian");
			break;
	}

	assert(game["axis"] == "german");
	[[level.ex_PrecacheShader]]("mpflag_german");
	setcvar("g_TeamName_Axis", &"MPUI_GERMAN");
	setcvar("g_TeamColor_Axis", ".6 .6 .6");
	setcvar("g_ScoresBanner_Axis", "mpflag_german");
}
