
getModel()
{
	self detachAll();

	if(self.pers["team"] == "allies") [[game["allies_model"] ]]();
		else if(self.pers["team"] == "axis") [[game["axis_model"] ]]();

	self.pers["savedmodel"] = saveModel();
}

saveModel()
{
	info["model"] = self.model;
	info["viewmodel"] = self getViewModel();
	if(isDefined(self.hatModel)) info["ex_hatmodel"] = self.hatModel;

	attachSize = self getAttachSize();
	info["attach"] = [];

	for(i = 0; i < attachSize; i++)
	{
		info["attach"][i]["model"] = self getAttachModelName(i);
		info["attach"][i]["tag"] = self getAttachTagName(i);
		info["attach"][i]["ignoreCollision"] = self getAttachIgnoreCollision(i);
	}

	return(info);
}

loadModel(info)
{
	self detachAll();
	self setModel(info["model"]);
	self setViewModel(info["viewmodel"]);
	if(isDefined(info["ex_hatmodel"])) self.hatModel = info["ex_hatmodel"];

	attachInfo = info["attach"];
	attachSize = attachInfo.size;

	for(i = 0; i < attachSize; i++)
		self attach(attachInfo[i]["model"], attachInfo[i]["tag"], attachInfo[i]["ignoreCollision"]);
}

dumpModelInfo()
{
	totalparts = 0;
	logprint("PARTS BODY " + self.name + ": " + self.model + "\n");
	parts = getNumParts(self.model);
	totalparts += parts;
	for(j = 0; j < parts; j++)
	{
		partname = getPartName(self.model, j);
		logprint("     >> " + partname + "\n");
	}

	attachments = self getAttachSize();
	for(i = 0; i < attachments; i++)
	{
		model = self getAttachModelName(i);
		logprint("PARTS ATTACHMENT(" + i + ") " + self.name + ": " + model + "\n");
		parts = getNumParts(model);
		totalparts += parts;
		for(j = 0; j < parts; j++)
		{
			partname = getPartName(model, j);
			logprint("     >> " + partname + "\n");
		}
	}

	if(level.ex_wepo_secondary)
	{
		if(isDefined(level.weapons[self.pers["weapon1"]]))
		{
			model = getWeaponModel(self.pers["weapon1"]);
			logprint("PARTS WEAPON(1) " + self.name + ": " + model + "\n");
			parts = getNumParts(model);
			totalparts += parts;
			for(j = 0; j < parts; j++)
			{
				partname = getPartName(model, j);
				logprint("     >> " + partname + "\n");
			}
		}
		if(isDefined(level.weapons[self.pers["weapon2"]]))
		{
			model = getWeaponModel(self.pers["weapon2"]);
			logprint("PARTS WEAPON(2) " + self.name + ": " + model + "\n");
			parts = getNumParts(model);
			totalparts += parts;
			for(j = 0; j < parts; j++)
			{
				partname = getPartName(model, j);
				logprint("     >> " + partname + "\n");
			}
		}
	}
	else
	{
		if(isDefined(level.weapons[self.pers["weapon"]]))
		{
			model = getWeaponModel(self.pers["weapon"]);
			logprint("PARTS WEAPON(1) " + self.name + ": " + model + "\n");
			parts = getNumParts(model);
			totalparts += parts;
			for(j = 0; j < parts; j++)
			{
				partname = getPartName(model, j);
				logprint("     >> " + partname + "\n");
			}
		}
	}
	logprint("Player " + self.name + " has a total of " + totalparts + " bones\n");
}
