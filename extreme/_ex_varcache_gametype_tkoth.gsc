
init()
{
	switch(level.ex_currentmap)
	{
		// stock maps
		case "mp_breakout": breakout(); break;
		case "mp_brecourt": brecourt(); break;
		case "mp_burgundy": burgundy(); break;
		case "mp_carentan": carentan(); break;
		case "mp_dawnville": dawnville(); break;
		case "mp_decoy": decoy(); break;
		case "mp_downtown": downtown(); break;
		case "mp_farmhouse": farmhouse(); break;
		case "mp_harbor": harbor(); break;
		case "mp_leningrad": leningrad(); break;
		case "mp_matmata": matmata(); break;
		case "mp_railyard": railyard(); break;
		case "mp_rhine": rhine(); break;
		case "mp_toujane": toujane(); break;
		case "mp_trainstation": trainstation(); break;

		// custom maps
		case "mp_mapname": mp_mapname(); break;
	}
}

//------------------------------------------------------------------------------
// Stock maps
//------------------------------------------------------------------------------
breakout()
{
	level.x = 5459;
	level.y = 3931;
	level.z = 28;
	level.radius = 500;
	level.spawn = "sd";
}

brecourt()
{
	level.x = 782;
	level.y = -231;
	level.z = -14;
	level.radius = 500;
	level.spawn = "sd";
}

burgundy()
{
	level.x = 1528;
	level.y = 2096;
	level.z = -0;
	level.radius = 500;
	level.spawn = "sd";
}

carentan()
{
	level.x = 700;
	level.y = 1520;
	level.z = -37;
	level.radius = 500;
	level.spawn = "sd";
}

dawnville()
{
	level.x = 199;
	level.y = -15853;
	level.z = 27;
	level.radius = 400;
	level.spawn = "sd";
}

decoy()
{
	level.x = 7769;
	level.y = -13986;
	level.z = -535;
	level.radius = 100;
	level.spawn = "sd";
}

downtown()
{
	level.x = 570;
	level.y = -821;
	level.z = -12;
	level.radius = 500;
	level.spawn = "sd";
}

farmhouse()
{
	level.x = -798;
	level.y = -573;
	level.z = 59;
	level.radius = 500;
	level.spawn = "sd";
}

harbor()
{
	level.x = -9233;
	level.y = -8835;
	level.z = -2;
	level.radius = 600;
	level.spawn = "sd";
}

leningrad()
{
	level.x = -180;
	level.y = 110;
	level.z = -500;
	level.radius = 400;
	level.spawn = "sd";
}

matmata()
{
	level.x = 3073;
	level.y = 7346;
	level.z = 14;
	level.radius = 500;
	level.spawn = "sd";
}

railyard()
{
	level.x = -2554;
	level.y = 263;
	level.z = 8;
	level.radius = 500;
	level.spawn = "sd";
}

rhine()
{
	level.x = 5300;
	level.y = 16400;
	level.z = 475;
	level.radius = 500;
	level.spawn = "sd";
}

toujane()
{
	level.x = 1998;
	level.y = 939;
	level.z = 65;
	level.radius = 500;
	level.spawn = "sd";
}

trainstation()
{
	level.x = 6092;
	level.y = -2521;
	level.z = -19;
	level.radius = 500;
	level.spawn = "sd";
}

//------------------------------------------------------------------------------
// Custom maps
//------------------------------------------------------------------------------
mp_mapname()
{
	//level.x = 0;
	//level.y = 0;
	//level.z = 0;
	//level.radius = 500;
	//level.spawn = "sd";
}
