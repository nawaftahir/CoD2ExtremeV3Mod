// THIS FILE IS AUTOGENERATED, DO NOT MODIFY
main()
{
	self setModel("xmodel/playerbody_german_winterligc1");
	self attach("xmodel/head_german_winter_jon", "", true);
	if(level.ex_hatmodels)
	{
		hatmodel = character\mp_hatmodels::randomHatModel(character\mp_hatmodels::mp_german_winter());
		if(hatmodel != "") self.hatModel = hatmodel;
	}
	else self.hatModel = "xmodel/helmet_german_winter_jc1";
	if(isDefined(self.hatModel)) self attach(self.hatModel, "", true);
	self setViewmodel("xmodel/viewmodel_hands_german_wintc1");
}

precache()
{
	[[level.ex_PrecacheModel]]("xmodel/playerbody_german_winterligc1");
	[[level.ex_PrecacheModel]]("xmodel/head_german_winter_jon");
	if(!level.ex_hatmodels) [[level.ex_PrecacheModel]]("xmodel/helmet_german_winter_jc1");
	[[level.ex_PrecacheModel]]("xmodel/viewmodel_hands_german_wintc1");
}
