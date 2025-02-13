
main()
{
	precacheFX();
	ambientFX();

	level.scr_sound["flak88_explode"] = "flak88_explode";
}

precacheFX()
{
	level._effect["flak_explosion"] = [[level.ex_PrecacheEffect]]("fx/explosions/flak88_explosion.efx");

	if(level.ex_ambfirefx)
	{
		level._effect["building_fire_large"] = [[level.ex_PrecacheEffect]]("fx/fire/building_fire_large.efx");
		level._effect["building_fire_small"] = [[level.ex_PrecacheEffect]]("fx/fire/building_fire_small.efx");
	}

	if(level.ex_ambsmokefx) level._effect["thin_black_smoke_M"] = [[level.ex_PrecacheEffect]]("fx/smoke/thin_black_smoke_M.efx");

	if(level.ex_ambsnowfx)
	{
		level._effect["snow_light"] = [[level.ex_PrecacheEffect]]("fx/misc/snow_light_mp_downtown.efx");
		level._effect["snow_wind_cityhall"] = [[level.ex_PrecacheEffect]]("fx/misc/snow_wind_cityhall.efx");
	}
}

ambientFX()
{
	if(level.ex_ambsnowfx) maps\mp\_fx::loopfx("snow_light", (-75,-208,232), 0.6, (-75,-208,332));

	if(level.ex_ambfirefx)
	{
		maps\mp\_fx::loopfx("building_fire_large", (-2236,1405,362), 1, (-2137,1396,369));
		maps\mp\_fx::loopfx("building_fire_large", (-1355,-1509,599), 2, (-1355,-1509,610));
		maps\mp\_fx::loopfx("building_fire_large", (1371,-738,506), 2, (1371,-738,517));
	}

	if(level.ex_ambsmokefx)
	{
		maps\mp\_fx::loopfx("thin_black_smoke_M", (1444,-893,517), 2, (1444,-893,532));
		maps\mp\_fx::loopfx("thin_black_smoke_M", (1680,1468,484), 1, (1680,1468,498));
		maps\mp\_fx::loopfx("thin_black_smoke_M", (-2211,1574,540), 2, (-2211,1574,550));
		maps\mp\_fx::loopfx("thin_black_smoke_M", (-1599,1828,585), 1, (-1599,1828,595));
		maps\mp\_fx::loopfx("thin_black_smoke_M", (-630,-958,71), 2, (-657,-955,168));
	}

	if(level.ex_ambsoundfx)
	{	
		maps\mp\_fx::soundfx("bigfire", (1384,-746,-575));
		maps\mp\_fx::soundfx("bigfire", (-1352,-1494,656));
		maps\mp\_fx::soundfx("bigfire", (-2236,1405,362));
	}
}
