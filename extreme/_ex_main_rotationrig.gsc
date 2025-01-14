#include extreme\_ex_main_utils;

main()
{
	x = game["playArea_CentreX"];
	y = game["playArea_CentreY"];
	z = game["mapArea_Max"][2] - 200;
	if(level.ex_planes_altitude && (level.ex_planes_altitude <= z)) z = level.ex_planes_altitude;

	level.rotation_rig = spawn("script_model", (x,y,z));
	level.rotation_rig setmodel("xmodel/tag_origin");
	level.rotation_rig.angles = (0,0,0);

	if(isDefined(level.ex_gunship_rotationspeed)) maxspeed = level.ex_gunship_rotationspeed;
		else maxspeed = 40;

	if(isDefined(level.ex_gunship_radius_tweak)) radiustweak = level.ex_gunship_radius_tweak;
		else radiustweak = 150;

	level.rotation_rig.maxradius = getRadius(level.rotation_rig.origin, radiustweak);

	rotationspeed = int((maxspeed / 2000) * level.rotation_rig.maxradius);
	if(rotationspeed < maxspeed) rotationspeed = maxspeed;
	level.rotation_rig.rotationspeed = rotationspeed;

	// not added to event controller because it causes tiny stutter after each 360 rotation
	level thread rigRotate();
}

rigRotate()
{
	while(!level.ex_gameover)
	{
		level.rotation_rig rotateyaw(360, level.rotation_rig.rotationspeed);
		wait( [[level.ex_fpstime]](level.rotation_rig.rotationspeed * 0.999) );
		level.rotation_rig notify("rotated360");
	}
}
