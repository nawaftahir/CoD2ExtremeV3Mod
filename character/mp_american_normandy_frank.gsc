// THIS FILE IS AUTOGENERATED, DO NOT MODIFY
main()
{
	self setModel("xmodel/playerbody_american_normandy03");
	self attach("xmodel/head_us_ranger_frank", "", true);
	if(level.ex_hatmodels)
	{
		hatmodel = character\mp_hatmodels::randomHatModel(character\mp_hatmodels::mp_american_normandy());
		if(hatmodel != "") self.hatModel = hatmodel;
	}
	else self.hatModel = "xmodel/helmet_us_ranger_generic";
	if(isDefined(self.hatModel)) self attach(self.hatModel, "", true);
	self setViewmodel("xmodel/viewmodel_hands_cloth");
}

precache()
{
	[[level.ex_PrecacheModel]]("xmodel/playerbody_american_normandy03");
	[[level.ex_PrecacheModel]]("xmodel/head_us_ranger_frank");
	if(!level.ex_hatmodels) [[level.ex_PrecacheModel]]("xmodel/helmet_us_ranger_generic");
	[[level.ex_PrecacheModel]]("xmodel/viewmodel_hands_cloth");
}
