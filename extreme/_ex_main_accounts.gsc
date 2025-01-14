#include extreme\_ex_controller_memory;
#include extreme\_ex_controller_hud;
#include extreme\_ex_main_utils;

init()
{
	game["menu_account"] = "accountsystem";
	[[level.ex_PrecacheMenu]](game["menu_account"]);

	[[level.ex_registerCallback]]("onPlayerConnected", ::onPlayerConnected);
}

onPlayerConnected()
{
	level endon("ex_gameover");
	self endon("disconnect");

	if(!isDefined(self.pers["account"]))
	{
		self.pers["account"] = [];

		// login control (0 = not logged in, 1 = skipped, 2 = not required, 3 = logged in)
		// related cvar: ui_account (ingame.menu)
		self.pers["account"]["status"] = 0;

		// menu mode (0 = login, 1 = register, 2 = change)
		// related cvar: ui_account_menu (accountsystem.menu)
		self.pers["account"]["menu"] = 0;

		// field identifier (0 = name, 1 = password[1], 2 = password[2])
		// related cvar: ui_account_item (accountsystem.menu)
		self.pers["account"]["item"] = "name";

		// show virtual keyboard (0 = hide, 1 = show)
		self.pers["account"]["keyb_show"] = 1;

		// active keyboard layout (10, 20, 30, ...,90)
		// related cvar: ui_account_kbst (part 1; accountsystem.menu)
		self.pers["account"]["keyb"] = level.ex_accounts_keyb;

		// key modifier (0 = normal, 1 = shift, 2 = alt, 3 = ctrl, 4 = fn)
		// related cvar: ui_account_kbst (part 2; accountsystem.menu)
		self.pers["account"]["keym"] = 0;

		// virtual keyboard caps lock state (0 = off, 1 = on)
		// related cvar: ui_account_kbst (part 2; accountsystem.menu)
		self.pers["account"]["keyc"] = 0;

		// name locker (0 = unlocked, 1 = locked)
		self.pers["account"]["name_lock"] = 0;

		// login name entry
		// related cvar: ui_account_name (accountsystem.menu)
		self.pers["account"]["name_entry"] = self.pers["account"]["name"];

		// login name (confirmed)
		self.pers["account"]["name"] = "";

		// related cvars: ui_account_pass1 and ui_account_pass2 (accountsystem.menu)
		self.pers["account"]["pass_entry1"] = self.pers["account"]["pass"];
		self.pers["account"]["pass_entry2"] = self.pers["account"]["pass"];

		// login password (confirmed)
		self.pers["account"]["pass"] = "";
	}
}

//------------------------------------------------------------------------------
// Account handling
//------------------------------------------------------------------------------
accountMenu()
{
	self endon("disconnect");

	// skipping guests
	if((level.ex_accounts == 1 || level.ex_accounts == 2) && self.ex_clanID != 1)
	{
		self thread accountNotRequired();
		return;
	}

	// prepare name
	self.pers["account"]["item"] = "name";
	if(level.ex_accounts_getname) self.pers["account"]["name_entry"] = sanitizeName(self.name);

	// check name lock condition
	memory = self getMemory("memory", "account", "name");
	if(!memory.error && memory.value != memory.def)
	{
		self.pers["account"]["item"] = "pass1";
		self.pers["account"]["name_lock"] = 1;
		self.pers["account"]["name_entry"] = memory.value;
	}

	// prepare passwords
	self.pers["account"]["pass_entry1"] = "";
	self.pers["account"]["pass_entry2"] = "";

	// check auto-login condition
	auto_login = false;
	if(self.pers["account"]["status"] == 0)
	{
		memory = self getMemory("memory", "account", "password");
		if(!memory.error && memory.value != memory.def)
		{
			self.pers["account"]["pass_entry1"] = memory.value;
			auto_login = true;
		}
	}

	// prepare virtual keyboard visibility
	if(self.pers["account"]["status"] == 0 || self.pers["account"]["status"] == 1) self.pers["account"]["keyb_show"] = 1;
		else self.pers["account"]["keyb_show"] = 0;

	// set UI variables
	accountPrepUI();

	// attempt auto-login
	if(auto_login && accountLogin()) return;

	// present account menu
	self closeInGameMenu();
	self closeMenu();
	self openMenu(game["menu_account"]);
	self thread setResult(0);
}

accountPrepUI()
{
	self setClientCvar("ui_account_msg", "");
	self setClientCvar("ui_account", self.pers["account"]["status"]);
	self setClientCvar("ui_account_menu", self.pers["account"]["menu"]);
	self setClientCvar("ui_account_item", self.pers["account"]["item"]);
	self setClientCvar("ui_account_lock", self.pers["account"]["name_lock"]);
	self setClientCvar("ui_account_name", self.pers["account"]["name_entry"]);
	self setClientCvar("ui_account_pass1", self.pers["account"]["pass_entry1"]);
	self setClientCvar("ui_account_pass2", self.pers["account"]["pass_entry2"]);
	setKeyboard(self.pers["account"]["keyb"], self.pers["account"]["keym"], true);
}

accountLimits(showdetails)
{
	code = 0;
	if(self.pers["account"]["name_entry"] == "" || self.pers["account"]["pass_entry1"] == "") code = 1;
	else if(self.pers["account"]["name_entry"].size < 5) code = 3;
	else if(self.pers["account"]["name_entry"].size > 32) code = 4;
	else if(self.pers["account"]["pass_entry1"].size < 5) code = 5;
	else if(self.pers["account"]["pass_entry1"].size > 16) code = 6;
	else if(showdetails && (self.pers["account"]["pass_entry1"] != self.pers["account"]["pass_entry2"])) code = 14;

	if(code > 1 && !showdetails) code = 12;
	if(code) self thread setResult(code);
	return(code);
}

accountLogin()
{
	if(self accountLimits(false)) return(false);
	if(!self accountPass())
	{
		self thread setResult(12);
		return(false);
	}

	if(level.ex_log_accounts) logprint("ACC: " + self.name + " logged in successfully\n");
	self thread accountApproved();
	return(true);
}

accountPass()
{
	self loadMemorySet("accounting");
	memory = self getMemory("accounting", "account", "password");
	if(!memory.error && memory.value != memory.def)
	{
		if(memory.value == self.pers["account"]["pass_entry1"]) return(true);
			else return(false);
	}
	else return(false);
}

accountCreate()
{
	if(self accountLimits(true)) return;
	if(self memorySetExists("accounting"))
	{
		self thread setResult(7);
		return;
	}

	self loadMemorySet("accounting");
	self setMemory("accounting", "account", "password", self.pers["account"]["pass_entry1"]);
	self setMemory("accounting", "account", "player", sanitizeName(self.name), false);

	if(level.ex_log_accounts) logprint("ACC: " + self.name + " created account and logged in successfully\n");
	self thread accountApproved();
}

accountSkip()
{
	if(self.pers["account"]["status"] != 3)
	{
		if(level.ex_accounts == 5)
		{
			self thread setResult(10);
			return;
		}
		else if((level.ex_accounts == 2 || level.ex_accounts == 4) && self.ex_clanID == 1)
		{
			self thread setResult(11);
			return;
		}
		self.pers["account"]["status"] = 1;
		if(level.ex_log_accounts) logprint("ACC: " + self.name + " skipped account login\n");
		self thread accountFinalize();
	}
	else self closeMenu();
}

accountNotRequired()
{
	self.pers["account"]["status"] = 2;
	if(level.ex_log_accounts) logprint("ACC: " + self.name + " does not require account login\n");
	self thread accountFinalize();
}

accountApproved()
{
	self.pers["account"]["status"] = 3;
	self.pers["account"]["name"] = self.pers["account"]["name_entry"];
	self.pers["account"]["pass"] = self.pers["account"]["pass_entry1"];

	self.pers["account"]["menu"] = 2;
	self.pers["account"]["item"] = "pass1";
	self.pers["account"]["name_lock"] = 1;
	self.pers["account"]["pass_entry1"] = "";
	self.pers["account"]["pass_entry2"] = "";
	self thread accountPrepUI();
	self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);

	if(level.ex_store && level.ex_store_savecash && level.ex_store_payment == 2)
	{
		memory = self getMemory("accounting", "account", "cash");
		if(!memory.error)
		{
			if(canAccumulateCash()) self.pers["cash"] += memory.value;
				else self.pers["cash"] = memory.value;
		}
		self thread playerHudSetValue("cash", self.pers["cash"]);
	}

	self setMemory("memory", "account", "name", self.pers["account"]["name"]);
	self setMemory("memory", "account", "password", self.pers["account"]["pass"], false);
	self thread accountFinalize();
}

accountFinalize()
{
	self closeInGameMenu();
	self closeMenu();

	// enable account system button in ingame menu
	self setClientCvar("ui_account", self.pers["account"]["status"]);

	// next menu to open
	if(isDefined(self.pers["team"]) && self.pers["team"] != "spectator")
	{
		if(!isDefined(self.pers["weapon"]))
		{
			if(self.pers["team"] == "allies") self openMenu(game["menu_weapon_allies"]);
				else self openMenu(game["menu_weapon_axis"]);
		}
	}
	else
	{
		if(!isDefined(self.pers["skipserverinfo"]))
		{
			self openMenu(game["menu_serverinfo"]);
			self.pers["skipserverinfo"] = true;
		}
		else self openMenu(game["menu_team"]);
	}
}

accountLogout()
{
	// set status to 1 (skipped) if login is optional, otherwise set status to 0 (not logged in)
	if(level.ex_accounts == 1 || level.ex_accounts == 3 || (level.ex_accounts == 4 && self.ex_clanID != 1)) self.pers["account"]["status"] = 1;
		else self.pers["account"]["status"] = 0;

	self.pers["account"]["name"] = "";
	self.pers["account"]["pass"] = "";

	self.pers["account"]["menu"] = 0;
	if(self.pers["account"]["name_lock"]) self.pers["account"]["item"] = "pass1";
		else self.pers["account"]["item"] = "name";
	self.pers["account"]["pass_entry1"] = "";
	self.pers["account"]["pass_entry2"] = "";
	self thread accountPrepUI();

	if(level.ex_store && level.ex_store_payment == 2)
	{
		if(level.ex_store_savecash) self setMemory("accounting", "account", "cash", self.pers["cash"], false);
		self.pers["cash"] = 0;
		self thread playerHudSetValue("cash", self.pers["cash"]);
	}
	self setDefault("memory", "account", "password", false);
	if(level.ex_log_accounts) logprint("ACC: " + self.name + " logged out successfully\n");
	self thread setResult(18);
}

changePass()
{
	code = 0;
	if(self.pers["account"]["pass_entry1"].size < 5) code = 5;
	else if(self.pers["account"]["pass_entry1"].size > 16) code = 6;
	else if(self.pers["account"]["pass_entry1"] != self.pers["account"]["pass_entry2"]) code = 14;
	else if(self.pers["account"]["pass_entry1"] == self.pers["account"]["pass"]) code = 15;
	if(code)
	{
		self thread setResult(code);
		return;
	}

	self setMemory("accounting", "account", "password", self.pers["account"]["pass"], false);
	logprint("ACC: " + self.name + " changed password successfully\n");
	self thread accountApproved();
}

//------------------------------------------------------------------------------
// Queries
//------------------------------------------------------------------------------
isLoggedIn()
{
	return( (self.pers["account"]["status"] == 3) );
}

canAccumulateCash()
{
	switch(level.ex_accounts_cash)
	{
		case 0:
			if(self.pers["account"]["status"] != 0) return(true);
			break;
		case 1:
			if(self.pers["account"]["status"] == 1 || self.pers["account"]["status"] == 3) return(true);
			break;
		case 2:
			if(self.pers["account"]["status"] == 2 || self.pers["account"]["status"] == 3) return(true);
			break;
		case 3:
			if(self.pers["account"]["status"] == 3) return(true);
			break;
	}
	return(false);
}

//------------------------------------------------------------------------------
// Menu response handling
//------------------------------------------------------------------------------
menuResponse(menu, response)
{
	self endon("disconnect");

	//if(level.ex_log_accounts) logprint("ACC: " + self.name + ": menu \"" + menu + "\", response \"" + response + "\"\n");

	if(response == "KEY_ESC" || response == "KEY_10" || response == "skip") { self thread accountSkip(); return; }
	else if(response == "KEY_F1" || response == "KEY_11") { self setKeyboard(10, 0, true); return; }
	else if(response == "KEY_F2" || response == "KEY_12") { self setKeyboard(20, 0, true); return; }
	else if(response == "KEY_F3" || response == "KEY_13") { self setKeyboard(30, 0, true); return; }
	else if(response == "KEY_F4" || response == "KEY_14") { self setKeyboard(40, 0, true); return; }
	else if(response == "KEY_F5" || response == "KEY_15") { self setKeyboard(50, 0, true); return; }
	else if(response == "KEY_F6" || response == "KEY_16") { self setKeyboard(60, 0, true); return; }
	else if(response == "KEY_F7" || response == "KEY_17") { self setKeyboard(70, 0, true); return; }
	else if(response == "KEY_F8" || response == "KEY_18") { self setKeyboard(80, 0, true); return; }
	else if(response == "KEY_F9" || response == "KEY_19") { self setKeyboard(90, 0, true); return; }
	else if(response == "KEY_TAB" || response == "KEY_30")
	{
		// handle TAB field selection for different menu modes
		switch(self.pers["account"]["menu"])
		{
			case 0:
				if(self.pers["account"]["item"] == "name") self.pers["account"]["item"] = "pass1";
					else if(!self.pers["account"]["name_lock"]) self.pers["account"]["item"] = "name";
						else self.pers["account"]["item"] = "pass1";
				break;
			case 1:
				if(self.pers["account"]["item"] == "name") self.pers["account"]["item"] = "pass1";
					else if(self.pers["account"]["item"] == "pass1") self.pers["account"]["item"] = "pass2";
						else self.pers["account"]["item"] = "name";
				break;
			case 2:
				if(self.pers["account"]["item"] == "pass1") self.pers["account"]["item"] = "pass2";
					else self.pers["account"]["item"] = "pass1";
				break;
		}
		self setClientCvar("ui_account_item", self.pers["account"]["item"]);
		return;
	}
	else if(response == "KEY_BACK" || response == "KEY_2D")
	{
		switch(self.pers["account"]["item"])
		{
			case "name":
				if(self.pers["account"]["name_entry"].size > 0)
				{
					self.pers["account"]["name_entry"] = getSubStr(self.pers["account"]["name_entry"], 0, self.pers["account"]["name_entry"].size - 1);
					self setClientCvar("ui_account_name", self.pers["account"]["name_entry"]);
				}
				break;
			case "pass1":
				if(self.pers["account"]["pass_entry1"].size > 0)
				{
					self.pers["account"]["pass_entry1"] = getSubStr(self.pers["account"]["pass_entry1"], 0, self.pers["account"]["pass_entry1"].size - 1);
					self setClientCvar("ui_account_pass1", self.pers["account"]["pass_entry1"]);
				}
				break;
			case "pass2":
				if(self.pers["account"]["pass_entry2"].size > 0)
				{
					self.pers["account"]["pass_entry2"] = getSubStr(self.pers["account"]["pass_entry2"], 0, self.pers["account"]["pass_entry2"].size - 1);
					self setClientCvar("ui_account_pass2", self.pers["account"]["pass_entry2"]);
				}
				break;
		}
		return;
	}
	else if(response == "KEY_CAPS" || response == "KEY_40")
	{
		self.pers["account"]["keyc"] = !self.pers["account"]["keyc"];
		self setKeyboard(undefined, self.pers["account"]["keyc"], false);
		return;
	}
	else if(response == "KEY_SHIFT" || response == "KEY_50")
	{
		if(!self.pers["account"]["keyc"]) self setKeyboard(undefined, !self.pers["account"]["keym"], false);
		return;
	}
	else if(response == "KEY_ENTER")
	{
		if(self.pers["account"]["status"] != 3)
		{
			if(self.pers["account"]["menu"] == 0) self thread accountLogin();
				else if(level.ex_accounts_reg && self.pers["account"]["menu"] == 1) self thread accountCreate();
					else self thread setResult(2);
		}
		return;
	}
	else if(response == "cancel")
	{
		if(self.pers["account"]["status"] == 3) self closeMenu();
		return;
	}
	else if(response == "username")
	{
		if(self.pers["account"]["menu"] == 1 || (self.pers["account"]["menu"] == 0 && !self.pers["account"]["name_lock"]))
		{
			self.pers["account"]["item"] = "name";
			self setClientCvar("ui_account_item", self.pers["account"]["item"]);
		}
		else self thread setResult(17);
		return;
	}
	else if(response == "password")
	{
		self.pers["account"]["item"] = "pass1";
		self setClientCvar("ui_account_item", self.pers["account"]["item"]);
		return;
	}
	else if(response == "login")
	{
		if(self.pers["account"]["menu"] == 0 && self.pers["account"]["status"] != 3) self thread accountLogin();
			else self thread setResult(99);
		return;
	}
	else if(response == "create")
	{
		if(level.ex_accounts_reg)
		{
			if(self.pers["account"]["menu"] == 1 && self.pers["account"]["status"] != 3) self thread accountCreate();
				else self thread setResult(99);
		}
		else self thread setResult(2);
		return;
	}
	else if(response == "logout")
	{
		if(self.pers["account"]["menu"] == 2 && self.pers["account"]["status"] == 3) accountLogout();
			else self thread setResult(99);
		return;
	}
	else if(response == "clear")
	{
		self.pers["account"]["pass_entry1"] = "";
		self setClientCvar("ui_account_pass1", self.pers["account"]["pass_entry1"]);
		self.pers["account"]["pass_entry2"] = "";
		self setClientCvar("ui_account_pass2", self.pers["account"]["pass_entry2"]);
		if(!self.pers["account"]["name_lock"])
		{
			self.pers["account"]["name_entry"] = "";
			self setClientCvar("ui_account_name", self.pers["account"]["name_entry"]);
			self.pers["account"]["item"] = "name";
		}
		else self.pers["account"]["item"] = "pass1";
		self setClientCvar("ui_account_item", self.pers["account"]["item"]);
		return;
	}
	else if(response == "clearname")
	{
		if(!self.pers["account"]["name_lock"])
		{
			self.pers["account"]["name_entry"] = "";
			self setClientCvar("ui_account_name", self.pers["account"]["name_entry"]);
			self.pers["account"]["item"] = "name";
			self setClientCvar("ui_account_item", self.pers["account"]["item"]);
		}
		else self thread setResult(17);
		return;
	}
	else if(response == "clearpass")
	{
		self.pers["account"]["pass_entry1"] = "";
		self setClientCvar("ui_account_pass1", self.pers["account"]["pass_entry1"]);
		self.pers["account"]["pass_entry2"] = "";
		self setClientCvar("ui_account_pass2", self.pers["account"]["pass_entry2"]);
		self.pers["account"]["item"] = "pass1";
		self setClientCvar("ui_account_item", self.pers["account"]["item"]);
		return;
	}
	else if(response == "changepass")
	{
		if(self.pers["account"]["menu"] == 2 && self.pers["account"]["status"] == 3) changePass();
		return;
	}
	else if(response == "switchmenu")
	{
		switch(self.pers["account"]["menu"])
		{
			case 0:
				if(level.ex_accounts_reg)
				{
					if(!self.pers["account"]["name_lock"])
					{
						self.pers["account"]["menu"] = 1;
						self setClientCvar("ui_account_menu", self.pers["account"]["menu"]);
					}
					else self thread setResult(16);
				}
				else self thread setResult(2);
				break;
			case 1:
				self.pers["account"]["menu"] = 0;
				self setClientCvar("ui_account_menu", self.pers["account"]["menu"]);
				if(self.pers["account"]["item"] == "pass2")
				{
					self.pers["account"]["pass_entry2"] = "";
					self setClientCvar("ui_account_pass2", self.pers["account"]["pass_entry2"]);
					self.pers["account"]["item"] = "pass1";
					self setClientCvar("ui_account_item", self.pers["account"]["item"]);
				}
				break;
		}
		return;
	}
	else if(response == "togglekeyb")
	{
		self.pers["account"]["keyb_show"] = !self.pers["account"]["keyb_show"];
		setKeyboard(self.pers["account"]["keyb"], self.pers["account"]["keym"], self.pers["account"]["keyb_show"]);
		return;
	}
	else
	{
		chr = translateKey(response);
		if(chr != "KEY_INVALID")
		{
			if(chr != " ")
			{
				//logprint("ACC: Detected character \"" + chr + "\"\n");
				switch(self.pers["account"]["item"])
				{
					case "name":
						if(self.pers["account"]["name_entry"].size < 32)
						{
							self.pers["account"]["name_entry"] += chr;
							self setClientCvar("ui_account_name", self.pers["account"]["name_entry"]);
						}
						else self thread setResult(4);
						break;
					case "pass1":
						if(self.pers["account"]["pass_entry1"].size < 16)
						{
							self.pers["account"]["pass_entry1"] += chr;
							self setClientCvar("ui_account_pass1", self.pers["account"]["pass_entry1"]);
						}
						else self thread setResult(6);
						break;
					case "pass2":
						if(self.pers["account"]["pass_entry2"].size < 16)
						{
							self.pers["account"]["pass_entry2"] += chr;
							self setClientCvar("ui_account_pass2", self.pers["account"]["pass_entry2"]);
						}
						else self thread setResult(6);
						break;
				}
			}
		}
		else self thread setResult(9);
	}
}

//------------------------------------------------------------------------------
// Result codes
//------------------------------------------------------------------------------
setResult(code)
{
	self endon("disconnect");

	message = "";
	switch(code)
	{
		case 1: message = "Enter name and password"; break;
		case 2: message = "Pre-registration is required"; break;
		case 3: message = "Name too short"; break;
		case 4: message = "Name too long"; break;
		case 5: message = "Password too short"; break;
		case 6: message = "Password too long"; break;
		case 7: message = "Registration failed"; break;
		case 8: message = "Account already exists";break;
		case 9: message = "Invalid key"; break;
		case 10: message = "Login is mandatory"; break;
		case 11: message = "Login is mandatory for clan members"; break;
		case 12: message = "Login failed"; break;
		case 13: message = "Verification failed"; break;
		case 14: message = "Passwords do not match"; break;
		case 15: message = "New password same as old password"; break;
		case 16: message = "Please use the existing account"; break;
		case 17: message = "Account name has been locked"; break;
		case 18: message = "You are logged out"; break;
		case 99: message = "Unexpected command at this time"; break;
	}

	self setClientCvar("ui_account_msg", message);
	if(message != "")
	{
		wait( [[level.ex_fpstime]](1) );
		if(isDefined(self)) self setClientCvar("ui_account_msg", "");
	}
}

//------------------------------------------------------------------------------
// Keyboard switching
//------------------------------------------------------------------------------
setKeyboard(keyb, keym, force_set)
{
	if(!isDefined(force_set)) force_set = false;

	dirty = false;
	if(isDefined(keyb) && (keyb % 10 == 0) && (force_set || keyb != self.pers["account"]["keyb"]))
	{
		dirty = true;
		self.pers["account"]["keyb"] = keyb;
	}
	if(isDefined(keym) && (force_set || keym != self.pers["account"]["keym"]))
	{
		dirty = true;
		self.pers["account"]["keym"] = keym;
	}

	if(self.pers["account"]["keyb_show"])
	{
		if(dirty) self setClientCvar("ui_account_kbst", "keyb_" + (self.pers["account"]["keyb"] + self.pers["account"]["keym"]));
	}
	else self setClientCvar("ui_account_kbst", "keyb_00");
}

//------------------------------------------------------------------------------
// Key translation
//------------------------------------------------------------------------------
translateKey(key)
{
	//if(level.ex_log_accounts) logprint("ACC: " + self.name + ": translateKey(\"" + key + "\") for language code " + self.pers["account"]["keyb"] + "\n");

	if(self.pers["account"]["keyb"] == 10) return(translateKey_10(key));
	if(self.pers["account"]["keyb"] == 20) return(translateKey_20(key));
	if(self.pers["account"]["keyb"] == 30) return(translateKey_30(key));
	if(self.pers["account"]["keyb"] == 40) return(translateKey_40(key));
	if(self.pers["account"]["keyb"] == 50) return(translateKey_50(key));
	if(self.pers["account"]["keyb"] == 60) return(translateKey_60(key));
	if(self.pers["account"]["keyb"] == 70) return(translateKey_70(key));
	if(self.pers["account"]["keyb"] == 80) return(translateKey_80(key));
	if(self.pers["account"]["keyb"] == 90) return(translateKey_90(key));
}

translateKey_10(key)
{
	if(!isDefined(key) || key == "") return("");

	keym = self.pers["account"]["keym"];
	if(keym && !self.pers["account"]["keyc"]) self setKeyboard(undefined, 0, false);

	switch(key)
	{
		//                       Normal state     Shift state
		case "KEY_20": if(!keym) return("`"); else return("~");
		case "KEY_21": if(!keym) return("1"); else return("!");
		case "KEY_22": if(!keym) return("2"); else return("@");
		case "KEY_23": if(!keym) return("3"); else return("#");
		case "KEY_24": if(!keym) return("4"); else return("$");
		case "KEY_25": if(!keym) return("5"); else return("%");
		case "KEY_26": if(!keym) return("6"); else return("^");
		case "KEY_27": if(!keym) return("7"); else return("&");
		case "KEY_28": if(!keym) return("8"); else return("*");
		case "KEY_29": if(!keym) return("9"); else return("(");
		case "KEY_2A": if(!keym) return("0"); else return(")");
		case "KEY_2B": if(!keym) return("-"); else return("_");
		case "KEY_2C": if(!keym) return("="); else return("+");
		case "KEY_31": if(!keym) return("q"); else return("Q");
		case "KEY_32": if(!keym) return("w"); else return("W");
		case "KEY_33": if(!keym) return("e"); else return("E");
		case "KEY_34": if(!keym) return("r"); else return("R");
		case "KEY_35": if(!keym) return("t"); else return("T");
		case "KEY_36": if(!keym) return("y"); else return("Y");
		case "KEY_37": if(!keym) return("u"); else return("U");
		case "KEY_38": if(!keym) return("i"); else return("I");
		case "KEY_39": if(!keym) return("o"); else return("O");
		case "KEY_3A": if(!keym) return("p"); else return("P");
		case "KEY_3B": if(!keym) return("["); else return("{");
		case "KEY_3C": if(!keym) return("]"); else return("}");
		case "KEY_3D": if(!keym) return("*"); else return("|");
		case "KEY_41": if(!keym) return("a"); else return("A");
		case "KEY_42": if(!keym) return("s"); else return("S");
		case "KEY_43": if(!keym) return("d"); else return("D");
		case "KEY_44": if(!keym) return("f"); else return("F");
		case "KEY_45": if(!keym) return("g"); else return("G");
		case "KEY_46": if(!keym) return("h"); else return("H");
		case "KEY_47": if(!keym) return("j"); else return("J");
		case "KEY_48": if(!keym) return("k"); else return("K");
		case "KEY_49": if(!keym) return("l"); else return("L");
		case "KEY_4A": if(!keym) return(";"); else return(":");
		case "KEY_4B": if(!keym) return("'"); else return("\"");
		case "KEY_51": if(!keym) return("z"); else return("Z");
		case "KEY_52": if(!keym) return("x"); else return("X");
		case "KEY_53": if(!keym) return("c"); else return("C");
		case "KEY_54": if(!keym) return("v"); else return("V");
		case "KEY_55": if(!keym) return("b"); else return("B");
		case "KEY_56": if(!keym) return("n"); else return("N");
		case "KEY_57": if(!keym) return("m"); else return("M");
		case "KEY_58": if(!keym) return(","); else return("<");
		case "KEY_59": if(!keym) return("."); else return(">");
		case "KEY_5A": if(!keym) return("/"); else return("?");
		case "KEY_64": return(" ");
		default: return("KEY_INVALID");
	}
}

translateKey_20(key)
{
	if(!isDefined(key) || key == "") return("");

	keym = self.pers["account"]["keym"];
	if(keym && !self.pers["account"]["keyc"]) self setKeyboard(undefined, 0, false);

	switch(key)
	{
		//                       Normal state     Shift state
		case "KEY_20": if(!keym) return("`"); else return("~");
		case "KEY_21": if(!keym) return("1"); else return("!");
		case "KEY_22": if(!keym) return("2"); else return("@");
		case "KEY_23": if(!keym) return("3"); else return("#");
		case "KEY_24": if(!keym) return("4"); else return("$");
		case "KEY_25": if(!keym) return("5"); else return("%");
		case "KEY_26": if(!keym) return("6"); else return("^");
		case "KEY_27": if(!keym) return("7"); else return("&");
		case "KEY_28": if(!keym) return("8"); else return("*");
		case "KEY_29": if(!keym) return("9"); else return("(");
		case "KEY_2A": if(!keym) return("0"); else return(")");
		case "KEY_2B": if(!keym) return("-"); else return("_");
		case "KEY_2C": if(!keym) return("="); else return("+");
		case "KEY_31": if(!keym) return("q"); else return("Q");
		case "KEY_32": if(!keym) return("w"); else return("W");
		case "KEY_33": if(!keym) return("e"); else return("E");
		case "KEY_34": if(!keym) return("r"); else return("R");
		case "KEY_35": if(!keym) return("t"); else return("T");
		case "KEY_36": if(!keym) return("y"); else return("Y");
		case "KEY_37": if(!keym) return("u"); else return("U");
		case "KEY_38": if(!keym) return("i"); else return("I");
		case "KEY_39": if(!keym) return("o"); else return("O");
		case "KEY_3A": if(!keym) return("p"); else return("P");
		case "KEY_3B": if(!keym) return("["); else return("{");
		case "KEY_3C": if(!keym) return("]"); else return("}");
		case "KEY_3D": if(!keym) return("*"); else return("|");
		case "KEY_41": if(!keym) return("a"); else return("A");
		case "KEY_42": if(!keym) return("s"); else return("S");
		case "KEY_43": if(!keym) return("d"); else return("D");
		case "KEY_44": if(!keym) return("f"); else return("F");
		case "KEY_45": if(!keym) return("g"); else return("G");
		case "KEY_46": if(!keym) return("h"); else return("H");
		case "KEY_47": if(!keym) return("j"); else return("J");
		case "KEY_48": if(!keym) return("k"); else return("K");
		case "KEY_49": if(!keym) return("l"); else return("L");
		case "KEY_4A": if(!keym) return(";"); else return(":");
		case "KEY_4B": if(!keym) return("'"); else return("\"");
		case "KEY_51": if(!keym) return("z"); else return("Z");
		case "KEY_52": if(!keym) return("x"); else return("X");
		case "KEY_53": if(!keym) return("c"); else return("C");
		case "KEY_54": if(!keym) return("v"); else return("V");
		case "KEY_55": if(!keym) return("b"); else return("B");
		case "KEY_56": if(!keym) return("n"); else return("N");
		case "KEY_57": if(!keym) return("m"); else return("M");
		case "KEY_58": if(!keym) return(","); else return("<");
		case "KEY_59": if(!keym) return("."); else return(">");
		case "KEY_5A": if(!keym) return("/"); else return("?");
		case "KEY_64": return(" ");
		default: return("KEY_INVALID");
	}
}

translateKey_30(key)
{
	if(!isDefined(key) || key == "") return("");

	keym = self.pers["account"]["keym"];
	if(keym && !self.pers["account"]["keyc"]) self setKeyboard(undefined, 0, false);

	switch(key)
	{
		//                       Normal state     Shift state
		case "KEY_20": if(!keym) return("`"); else return("~");
		case "KEY_21": if(!keym) return("1"); else return("!");
		case "KEY_22": if(!keym) return("2"); else return("@");
		case "KEY_23": if(!keym) return("3"); else return("#");
		case "KEY_24": if(!keym) return("4"); else return("$");
		case "KEY_25": if(!keym) return("5"); else return("%");
		case "KEY_26": if(!keym) return("6"); else return("^");
		case "KEY_27": if(!keym) return("7"); else return("&");
		case "KEY_28": if(!keym) return("8"); else return("*");
		case "KEY_29": if(!keym) return("9"); else return("(");
		case "KEY_2A": if(!keym) return("0"); else return(")");
		case "KEY_2B": if(!keym) return("-"); else return("_");
		case "KEY_2C": if(!keym) return("="); else return("+");
		case "KEY_31": if(!keym) return("q"); else return("Q");
		case "KEY_32": if(!keym) return("w"); else return("W");
		case "KEY_33": if(!keym) return("e"); else return("E");
		case "KEY_34": if(!keym) return("r"); else return("R");
		case "KEY_35": if(!keym) return("t"); else return("T");
		case "KEY_36": if(!keym) return("y"); else return("Y");
		case "KEY_37": if(!keym) return("u"); else return("U");
		case "KEY_38": if(!keym) return("i"); else return("I");
		case "KEY_39": if(!keym) return("o"); else return("O");
		case "KEY_3A": if(!keym) return("p"); else return("P");
		case "KEY_3B": if(!keym) return("["); else return("{");
		case "KEY_3C": if(!keym) return("]"); else return("}");
		case "KEY_3D": if(!keym) return("*"); else return("|");
		case "KEY_41": if(!keym) return("a"); else return("A");
		case "KEY_42": if(!keym) return("s"); else return("S");
		case "KEY_43": if(!keym) return("d"); else return("D");
		case "KEY_44": if(!keym) return("f"); else return("F");
		case "KEY_45": if(!keym) return("g"); else return("G");
		case "KEY_46": if(!keym) return("h"); else return("H");
		case "KEY_47": if(!keym) return("j"); else return("J");
		case "KEY_48": if(!keym) return("k"); else return("K");
		case "KEY_49": if(!keym) return("l"); else return("L");
		case "KEY_4A": if(!keym) return(";"); else return(":");
		case "KEY_4B": if(!keym) return("'"); else return("\"");
		case "KEY_51": if(!keym) return("z"); else return("Z");
		case "KEY_52": if(!keym) return("x"); else return("X");
		case "KEY_53": if(!keym) return("c"); else return("C");
		case "KEY_54": if(!keym) return("v"); else return("V");
		case "KEY_55": if(!keym) return("b"); else return("B");
		case "KEY_56": if(!keym) return("n"); else return("N");
		case "KEY_57": if(!keym) return("m"); else return("M");
		case "KEY_58": if(!keym) return(","); else return("<");
		case "KEY_59": if(!keym) return("."); else return(">");
		case "KEY_5A": if(!keym) return("/"); else return("?");
		case "KEY_64": return(" ");
		default: return("KEY_INVALID");
	}
}

translateKey_40(key)
{
	if(!isDefined(key) || key == "") return("");

	keym = self.pers["account"]["keym"];
	if(keym && !self.pers["account"]["keyc"]) self setKeyboard(undefined, 0, false);

	switch(key)
	{
		//                       Normal state     Shift state
		case "KEY_20": if(!keym) return("`"); else return("~");
		case "KEY_21": if(!keym) return("1"); else return("!");
		case "KEY_22": if(!keym) return("2"); else return("@");
		case "KEY_23": if(!keym) return("3"); else return("#");
		case "KEY_24": if(!keym) return("4"); else return("$");
		case "KEY_25": if(!keym) return("5"); else return("%");
		case "KEY_26": if(!keym) return("6"); else return("^");
		case "KEY_27": if(!keym) return("7"); else return("&");
		case "KEY_28": if(!keym) return("8"); else return("*");
		case "KEY_29": if(!keym) return("9"); else return("(");
		case "KEY_2A": if(!keym) return("0"); else return(")");
		case "KEY_2B": if(!keym) return("-"); else return("_");
		case "KEY_2C": if(!keym) return("="); else return("+");
		case "KEY_31": if(!keym) return("q"); else return("Q");
		case "KEY_32": if(!keym) return("w"); else return("W");
		case "KEY_33": if(!keym) return("e"); else return("E");
		case "KEY_34": if(!keym) return("r"); else return("R");
		case "KEY_35": if(!keym) return("t"); else return("T");
		case "KEY_36": if(!keym) return("y"); else return("Y");
		case "KEY_37": if(!keym) return("u"); else return("U");
		case "KEY_38": if(!keym) return("i"); else return("I");
		case "KEY_39": if(!keym) return("o"); else return("O");
		case "KEY_3A": if(!keym) return("p"); else return("P");
		case "KEY_3B": if(!keym) return("["); else return("{");
		case "KEY_3C": if(!keym) return("]"); else return("}");
		case "KEY_3D": if(!keym) return("*"); else return("|");
		case "KEY_41": if(!keym) return("a"); else return("A");
		case "KEY_42": if(!keym) return("s"); else return("S");
		case "KEY_43": if(!keym) return("d"); else return("D");
		case "KEY_44": if(!keym) return("f"); else return("F");
		case "KEY_45": if(!keym) return("g"); else return("G");
		case "KEY_46": if(!keym) return("h"); else return("H");
		case "KEY_47": if(!keym) return("j"); else return("J");
		case "KEY_48": if(!keym) return("k"); else return("K");
		case "KEY_49": if(!keym) return("l"); else return("L");
		case "KEY_4A": if(!keym) return(";"); else return(":");
		case "KEY_4B": if(!keym) return("'"); else return("\"");
		case "KEY_51": if(!keym) return("z"); else return("Z");
		case "KEY_52": if(!keym) return("x"); else return("X");
		case "KEY_53": if(!keym) return("c"); else return("C");
		case "KEY_54": if(!keym) return("v"); else return("V");
		case "KEY_55": if(!keym) return("b"); else return("B");
		case "KEY_56": if(!keym) return("n"); else return("N");
		case "KEY_57": if(!keym) return("m"); else return("M");
		case "KEY_58": if(!keym) return(","); else return("<");
		case "KEY_59": if(!keym) return("."); else return(">");
		case "KEY_5A": if(!keym) return("/"); else return("?");
		case "KEY_64": return(" ");
		default: return("KEY_INVALID");
	}
}

translateKey_50(key)
{
	if(!isDefined(key) || key == "") return("");

	keym = self.pers["account"]["keym"];
	if(keym && !self.pers["account"]["keyc"]) self setKeyboard(undefined, 0, false);

	switch(key)
	{
		//                       Normal state     Shift state
		case "KEY_20": if(!keym) return("`"); else return("~");
		case "KEY_21": if(!keym) return("1"); else return("!");
		case "KEY_22": if(!keym) return("2"); else return("@");
		case "KEY_23": if(!keym) return("3"); else return("#");
		case "KEY_24": if(!keym) return("4"); else return("$");
		case "KEY_25": if(!keym) return("5"); else return("%");
		case "KEY_26": if(!keym) return("6"); else return("^");
		case "KEY_27": if(!keym) return("7"); else return("&");
		case "KEY_28": if(!keym) return("8"); else return("*");
		case "KEY_29": if(!keym) return("9"); else return("(");
		case "KEY_2A": if(!keym) return("0"); else return(")");
		case "KEY_2B": if(!keym) return("-"); else return("_");
		case "KEY_2C": if(!keym) return("="); else return("+");
		case "KEY_31": if(!keym) return("q"); else return("Q");
		case "KEY_32": if(!keym) return("w"); else return("W");
		case "KEY_33": if(!keym) return("e"); else return("E");
		case "KEY_34": if(!keym) return("r"); else return("R");
		case "KEY_35": if(!keym) return("t"); else return("T");
		case "KEY_36": if(!keym) return("y"); else return("Y");
		case "KEY_37": if(!keym) return("u"); else return("U");
		case "KEY_38": if(!keym) return("i"); else return("I");
		case "KEY_39": if(!keym) return("o"); else return("O");
		case "KEY_3A": if(!keym) return("p"); else return("P");
		case "KEY_3B": if(!keym) return("["); else return("{");
		case "KEY_3C": if(!keym) return("]"); else return("}");
		case "KEY_3D": if(!keym) return("*"); else return("|");
		case "KEY_41": if(!keym) return("a"); else return("A");
		case "KEY_42": if(!keym) return("s"); else return("S");
		case "KEY_43": if(!keym) return("d"); else return("D");
		case "KEY_44": if(!keym) return("f"); else return("F");
		case "KEY_45": if(!keym) return("g"); else return("G");
		case "KEY_46": if(!keym) return("h"); else return("H");
		case "KEY_47": if(!keym) return("j"); else return("J");
		case "KEY_48": if(!keym) return("k"); else return("K");
		case "KEY_49": if(!keym) return("l"); else return("L");
		case "KEY_4A": if(!keym) return(";"); else return(":");
		case "KEY_4B": if(!keym) return("'"); else return("\"");
		case "KEY_51": if(!keym) return("z"); else return("Z");
		case "KEY_52": if(!keym) return("x"); else return("X");
		case "KEY_53": if(!keym) return("c"); else return("C");
		case "KEY_54": if(!keym) return("v"); else return("V");
		case "KEY_55": if(!keym) return("b"); else return("B");
		case "KEY_56": if(!keym) return("n"); else return("N");
		case "KEY_57": if(!keym) return("m"); else return("M");
		case "KEY_58": if(!keym) return(","); else return("<");
		case "KEY_59": if(!keym) return("."); else return(">");
		case "KEY_5A": if(!keym) return("/"); else return("?");
		case "KEY_64": return(" ");
		default: return("KEY_INVALID");
	}
}

translateKey_60(key)
{
	if(!isDefined(key) || key == "") return("");

	keym = self.pers["account"]["keym"];
	if(keym && !self.pers["account"]["keyc"]) self setKeyboard(undefined, 0, false);

	switch(key)
	{
		//                       Normal state     Shift state
		case "KEY_20": if(!keym) return("`"); else return("~");
		case "KEY_21": if(!keym) return("1"); else return("!");
		case "KEY_22": if(!keym) return("2"); else return("@");
		case "KEY_23": if(!keym) return("3"); else return("#");
		case "KEY_24": if(!keym) return("4"); else return("$");
		case "KEY_25": if(!keym) return("5"); else return("%");
		case "KEY_26": if(!keym) return("6"); else return("^");
		case "KEY_27": if(!keym) return("7"); else return("&");
		case "KEY_28": if(!keym) return("8"); else return("*");
		case "KEY_29": if(!keym) return("9"); else return("(");
		case "KEY_2A": if(!keym) return("0"); else return(")");
		case "KEY_2B": if(!keym) return("-"); else return("_");
		case "KEY_2C": if(!keym) return("="); else return("+");
		case "KEY_31": if(!keym) return("q"); else return("Q");
		case "KEY_32": if(!keym) return("w"); else return("W");
		case "KEY_33": if(!keym) return("e"); else return("E");
		case "KEY_34": if(!keym) return("r"); else return("R");
		case "KEY_35": if(!keym) return("t"); else return("T");
		case "KEY_36": if(!keym) return("y"); else return("Y");
		case "KEY_37": if(!keym) return("u"); else return("U");
		case "KEY_38": if(!keym) return("i"); else return("I");
		case "KEY_39": if(!keym) return("o"); else return("O");
		case "KEY_3A": if(!keym) return("p"); else return("P");
		case "KEY_3B": if(!keym) return("["); else return("{");
		case "KEY_3C": if(!keym) return("]"); else return("}");
		case "KEY_3D": if(!keym) return("*"); else return("|");
		case "KEY_41": if(!keym) return("a"); else return("A");
		case "KEY_42": if(!keym) return("s"); else return("S");
		case "KEY_43": if(!keym) return("d"); else return("D");
		case "KEY_44": if(!keym) return("f"); else return("F");
		case "KEY_45": if(!keym) return("g"); else return("G");
		case "KEY_46": if(!keym) return("h"); else return("H");
		case "KEY_47": if(!keym) return("j"); else return("J");
		case "KEY_48": if(!keym) return("k"); else return("K");
		case "KEY_49": if(!keym) return("l"); else return("L");
		case "KEY_4A": if(!keym) return(";"); else return(":");
		case "KEY_4B": if(!keym) return("'"); else return("\"");
		case "KEY_51": if(!keym) return("z"); else return("Z");
		case "KEY_52": if(!keym) return("x"); else return("X");
		case "KEY_53": if(!keym) return("c"); else return("C");
		case "KEY_54": if(!keym) return("v"); else return("V");
		case "KEY_55": if(!keym) return("b"); else return("B");
		case "KEY_56": if(!keym) return("n"); else return("N");
		case "KEY_57": if(!keym) return("m"); else return("M");
		case "KEY_58": if(!keym) return(","); else return("<");
		case "KEY_59": if(!keym) return("."); else return(">");
		case "KEY_5A": if(!keym) return("/"); else return("?");
		case "KEY_64": return(" ");
		default: return("KEY_INVALID");
	}
}

translateKey_70(key)
{
	if(!isDefined(key) || key == "") return("");

	keym = self.pers["account"]["keym"];
	if(keym && !self.pers["account"]["keyc"]) self setKeyboard(undefined, 0, false);

	switch(key)
	{
		//                       Normal state     Shift state
		case "KEY_20": if(!keym) return("`"); else return("~");
		case "KEY_21": if(!keym) return("1"); else return("!");
		case "KEY_22": if(!keym) return("2"); else return("@");
		case "KEY_23": if(!keym) return("3"); else return("#");
		case "KEY_24": if(!keym) return("4"); else return("$");
		case "KEY_25": if(!keym) return("5"); else return("%");
		case "KEY_26": if(!keym) return("6"); else return("^");
		case "KEY_27": if(!keym) return("7"); else return("&");
		case "KEY_28": if(!keym) return("8"); else return("*");
		case "KEY_29": if(!keym) return("9"); else return("(");
		case "KEY_2A": if(!keym) return("0"); else return(")");
		case "KEY_2B": if(!keym) return("-"); else return("_");
		case "KEY_2C": if(!keym) return("="); else return("+");
		case "KEY_31": if(!keym) return("q"); else return("Q");
		case "KEY_32": if(!keym) return("w"); else return("W");
		case "KEY_33": if(!keym) return("e"); else return("E");
		case "KEY_34": if(!keym) return("r"); else return("R");
		case "KEY_35": if(!keym) return("t"); else return("T");
		case "KEY_36": if(!keym) return("y"); else return("Y");
		case "KEY_37": if(!keym) return("u"); else return("U");
		case "KEY_38": if(!keym) return("i"); else return("I");
		case "KEY_39": if(!keym) return("o"); else return("O");
		case "KEY_3A": if(!keym) return("p"); else return("P");
		case "KEY_3B": if(!keym) return("["); else return("{");
		case "KEY_3C": if(!keym) return("]"); else return("}");
		case "KEY_3D": if(!keym) return("*"); else return("|");
		case "KEY_41": if(!keym) return("a"); else return("A");
		case "KEY_42": if(!keym) return("s"); else return("S");
		case "KEY_43": if(!keym) return("d"); else return("D");
		case "KEY_44": if(!keym) return("f"); else return("F");
		case "KEY_45": if(!keym) return("g"); else return("G");
		case "KEY_46": if(!keym) return("h"); else return("H");
		case "KEY_47": if(!keym) return("j"); else return("J");
		case "KEY_48": if(!keym) return("k"); else return("K");
		case "KEY_49": if(!keym) return("l"); else return("L");
		case "KEY_4A": if(!keym) return(";"); else return(":");
		case "KEY_4B": if(!keym) return("'"); else return("\"");
		case "KEY_51": if(!keym) return("z"); else return("Z");
		case "KEY_52": if(!keym) return("x"); else return("X");
		case "KEY_53": if(!keym) return("c"); else return("C");
		case "KEY_54": if(!keym) return("v"); else return("V");
		case "KEY_55": if(!keym) return("b"); else return("B");
		case "KEY_56": if(!keym) return("n"); else return("N");
		case "KEY_57": if(!keym) return("m"); else return("M");
		case "KEY_58": if(!keym) return(","); else return("<");
		case "KEY_59": if(!keym) return("."); else return(">");
		case "KEY_5A": if(!keym) return("/"); else return("?");
		case "KEY_64": return(" ");
		default: return("KEY_INVALID");
	}
}

translateKey_80(key)
{
	if(!isDefined(key) || key == "") return("");

	keym = self.pers["account"]["keym"];
	if(keym && !self.pers["account"]["keyc"]) self setKeyboard(undefined, 0, false);

	switch(key)
	{
		//                       Normal state     Shift state
		case "KEY_20": if(!keym) return("`"); else return("~");
		case "KEY_21": if(!keym) return("1"); else return("!");
		case "KEY_22": if(!keym) return("2"); else return("@");
		case "KEY_23": if(!keym) return("3"); else return("#");
		case "KEY_24": if(!keym) return("4"); else return("$");
		case "KEY_25": if(!keym) return("5"); else return("%");
		case "KEY_26": if(!keym) return("6"); else return("^");
		case "KEY_27": if(!keym) return("7"); else return("&");
		case "KEY_28": if(!keym) return("8"); else return("*");
		case "KEY_29": if(!keym) return("9"); else return("(");
		case "KEY_2A": if(!keym) return("0"); else return(")");
		case "KEY_2B": if(!keym) return("-"); else return("_");
		case "KEY_2C": if(!keym) return("="); else return("+");
		case "KEY_31": if(!keym) return("q"); else return("Q");
		case "KEY_32": if(!keym) return("w"); else return("W");
		case "KEY_33": if(!keym) return("e"); else return("E");
		case "KEY_34": if(!keym) return("r"); else return("R");
		case "KEY_35": if(!keym) return("t"); else return("T");
		case "KEY_36": if(!keym) return("y"); else return("Y");
		case "KEY_37": if(!keym) return("u"); else return("U");
		case "KEY_38": if(!keym) return("i"); else return("I");
		case "KEY_39": if(!keym) return("o"); else return("O");
		case "KEY_3A": if(!keym) return("p"); else return("P");
		case "KEY_3B": if(!keym) return("["); else return("{");
		case "KEY_3C": if(!keym) return("]"); else return("}");
		case "KEY_3D": if(!keym) return("*"); else return("|");
		case "KEY_41": if(!keym) return("a"); else return("A");
		case "KEY_42": if(!keym) return("s"); else return("S");
		case "KEY_43": if(!keym) return("d"); else return("D");
		case "KEY_44": if(!keym) return("f"); else return("F");
		case "KEY_45": if(!keym) return("g"); else return("G");
		case "KEY_46": if(!keym) return("h"); else return("H");
		case "KEY_47": if(!keym) return("j"); else return("J");
		case "KEY_48": if(!keym) return("k"); else return("K");
		case "KEY_49": if(!keym) return("l"); else return("L");
		case "KEY_4A": if(!keym) return(";"); else return(":");
		case "KEY_4B": if(!keym) return("'"); else return("\"");
		case "KEY_51": if(!keym) return("z"); else return("Z");
		case "KEY_52": if(!keym) return("x"); else return("X");
		case "KEY_53": if(!keym) return("c"); else return("C");
		case "KEY_54": if(!keym) return("v"); else return("V");
		case "KEY_55": if(!keym) return("b"); else return("B");
		case "KEY_56": if(!keym) return("n"); else return("N");
		case "KEY_57": if(!keym) return("m"); else return("M");
		case "KEY_58": if(!keym) return(","); else return("<");
		case "KEY_59": if(!keym) return("."); else return(">");
		case "KEY_5A": if(!keym) return("/"); else return("?");
		case "KEY_64": return(" ");
		default: return("KEY_INVALID");
	}
}

translateKey_90(key)
{
	if(!isDefined(key) || key == "") return("");

	keym = self.pers["account"]["keym"];
	if(keym && !self.pers["account"]["keyc"]) self setKeyboard(undefined, 0, false);

	switch(key)
	{
		//                       Normal state     Shift state
		case "KEY_20": if(!keym) return("`"); else return("~");
		case "KEY_21": if(!keym) return("1"); else return("!");
		case "KEY_22": if(!keym) return("2"); else return("@");
		case "KEY_23": if(!keym) return("3"); else return("#");
		case "KEY_24": if(!keym) return("4"); else return("$");
		case "KEY_25": if(!keym) return("5"); else return("%");
		case "KEY_26": if(!keym) return("6"); else return("^");
		case "KEY_27": if(!keym) return("7"); else return("&");
		case "KEY_28": if(!keym) return("8"); else return("*");
		case "KEY_29": if(!keym) return("9"); else return("(");
		case "KEY_2A": if(!keym) return("0"); else return(")");
		case "KEY_2B": if(!keym) return("-"); else return("_");
		case "KEY_2C": if(!keym) return("="); else return("+");
		case "KEY_31": if(!keym) return("q"); else return("Q");
		case "KEY_32": if(!keym) return("w"); else return("W");
		case "KEY_33": if(!keym) return("e"); else return("E");
		case "KEY_34": if(!keym) return("r"); else return("R");
		case "KEY_35": if(!keym) return("t"); else return("T");
		case "KEY_36": if(!keym) return("y"); else return("Y");
		case "KEY_37": if(!keym) return("u"); else return("U");
		case "KEY_38": if(!keym) return("i"); else return("I");
		case "KEY_39": if(!keym) return("o"); else return("O");
		case "KEY_3A": if(!keym) return("p"); else return("P");
		case "KEY_3B": if(!keym) return("["); else return("{");
		case "KEY_3C": if(!keym) return("]"); else return("}");
		case "KEY_3D": if(!keym) return("*"); else return("|");
		case "KEY_41": if(!keym) return("a"); else return("A");
		case "KEY_42": if(!keym) return("s"); else return("S");
		case "KEY_43": if(!keym) return("d"); else return("D");
		case "KEY_44": if(!keym) return("f"); else return("F");
		case "KEY_45": if(!keym) return("g"); else return("G");
		case "KEY_46": if(!keym) return("h"); else return("H");
		case "KEY_47": if(!keym) return("j"); else return("J");
		case "KEY_48": if(!keym) return("k"); else return("K");
		case "KEY_49": if(!keym) return("l"); else return("L");
		case "KEY_4A": if(!keym) return(";"); else return(":");
		case "KEY_4B": if(!keym) return("'"); else return("\"");
		case "KEY_51": if(!keym) return("z"); else return("Z");
		case "KEY_52": if(!keym) return("x"); else return("X");
		case "KEY_53": if(!keym) return("c"); else return("C");
		case "KEY_54": if(!keym) return("v"); else return("V");
		case "KEY_55": if(!keym) return("b"); else return("B");
		case "KEY_56": if(!keym) return("n"); else return("N");
		case "KEY_57": if(!keym) return("m"); else return("M");
		case "KEY_58": if(!keym) return(","); else return("<");
		case "KEY_59": if(!keym) return("."); else return(">");
		case "KEY_5A": if(!keym) return("/"); else return("?");
		case "KEY_64": return(" ");
		default: return("KEY_INVALID");
	}
}
