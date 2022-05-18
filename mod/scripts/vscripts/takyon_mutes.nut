global function MutesInit

global struct Mutes_PlayerData{
	string name 
	string uid
	bool muted
	bool gagged
	int punishmentAmount
}

array<string> mutes_adminUIDs = []
const string path = "../R2Northstar/mods/Takyon.Mutes/mod/scripts/vscripts/takyon_mutes_cfg.nut" // where the config is stored
array<Mutes_PlayerData> mutes_playerData = [] // data from current match

void function MutesInit(){
	Mutes_CfgInit()
	mutes_playerData.extend(mutes_cfg_players)
	AddCallback_OnReceivedSayTextMessage(Mutes_ChatCallback)
	UpdateAdminList()
}

void function Mutes_Gag(entity caller, string targetSubName){
	if(!Mutes_IsAdmin(caller.GetUID())){
		Chat_ServerPrivateMessage(caller, "\x1b[34m[Mutes]\x1b[0m You're not an admin!",false)
		return
	}

	if(!Muted_CanFindPlayerFromSubstring(targetSubName)){
		Chat_ServerPrivateMessage(caller, "\x1b[34m[Mutes]\x1b[0m Cant find one player for substr",false)
		return
	}

	// player might dc?
	entity target = Muted_GetPlayerFromSubstring(targetSubName)
	string tUid = target.GetUID()
	string tName = target.GetPlayerName()

	foreach(Mutes_PlayerData pd in mutes_playerData){ // loop through each player in current match
		if(pd.uid == tUid){ // player in live match is in cfg // REM 
			pd.gagged = true
			pd.punishmentAmount++
			Chat_ServerPrivateMessage(caller, "\x1b[34m[Mutes]\x1b[0m Player has been gagged.",false)
			Mutes_SaveConfig()
			return
		}
	}

	// not yet in cfg
	Mutes_PlayerData tmp;
	tmp.name = tName;
	tmp.uid = tUid;
	tmp.muted = false;
	tmp.gagged = true;
	tmp.punishmentAmount = 1;
	mutes_playerData.append(tmp);
}

void function Mutes_Ungag(entity caller, string targetSubName){
	if(!Mutes_IsAdmin(caller.GetUID())){
		Chat_ServerPrivateMessage(caller, "\x1b[34m[Mutes]\x1b[0m You're not an admin!",false)
		return
	}

	if(!Muted_CanFindPlayerFromSubstring(targetSubName)){
		Chat_ServerPrivateMessage(caller, "\x1b[34m[Mutes]\x1b[0m Cant find one player for substr",false)
		return
	}

	// player might dc?
	entity target = Muted_GetPlayerFromSubstring(targetSubName)
	string tUid = target.GetUID()

	foreach(Mutes_PlayerData pd in mutes_playerData){ // loop through each player in current match
		if(pd.uid == tUid){ // player in live match is in cfg // REM 
			pd.gagged = false
			Chat_ServerPrivateMessage(caller, "\x1b[34m[Mutes]\x1b[0m Player has been ungagged.",false)
			Mutes_SaveConfig()
		}
	}
}

void function Mutes_Status(entity caller, string targetSubName){
	if(!Mutes_IsAdmin(caller.GetUID())){
		Chat_ServerPrivateMessage(caller, "\x1b[34m[Mutes]\x1b[0m You're not an admin!",false)
		return
	}

	if(!Muted_CanFindPlayerFromSubstring(targetSubName)){
		Chat_ServerPrivateMessage(caller, "\x1b[34m[Mutes]\x1b[0m Cant find one player for substr",false)
		return
	}

	// player might dc?
	entity target = Muted_GetPlayerFromSubstring(targetSubName)
	string tUid = target.GetUID()

	Mutes_CfgInit() // just 2 be safe lol

	foreach(Mutes_PlayerData pd in mutes_playerData){ // loop through each player in current match
		if(pd.uid == tUid){ // player in live match is in cfg 
			Chat_ServerPrivateMessage(caller, "\x1b[34m[Mutes]\x1b[0m Player " + (pd.gagged ? "is" : "isn't") + " gagged. Offenses: " + pd.punishmentAmount,false)
			return
		}
	}

	Chat_ServerPrivateMessage(caller, "\x1b[34m[Mutes]\x1b[0m Player has no history",false)
}

void function Mutes_Help(entity player){
	if(!Mutes_IsAdmin(player.GetUID())){
		Chat_ServerPrivateMessage(player, "\x1b[34m[Mutes]\x1b[0m You're not an admin!",false)
		return
	}
	
	Chat_ServerPrivateMessage(player, "\x1b[34m[Mutes]\n\x1b[0m!gag name\n!ungag name\n!status name",false)
}

/*
 *	CHAT COMMANDS
 */

ClServer_MessageStruct function Mutes_ChatCallback(ClServer_MessageStruct message) {
    string msg = message.message.tolower()
    // find first char -> gotta be ! to recognize command
    if (format("%c", msg[0]) == "!") {
        // command
        msg = msg.slice(1) // remove !
        array<string> msgArr = split(msg, " ") // split at space, [0] = command
        string cmd
        
        try{
            cmd = msgArr[0] // save command
        }
        catch(e){
            return message
        }

        // command logic
		if(cmd == "gag"){ // chat
			if(msgArr.len() < 2){
				Chat_ServerPrivateMessage(message.player, "\x1b[34m[Mutes]\x1b[0m No name specified",false)
				message.shouldBlock = true
				return message
			}

			Mutes_Gag(message.player, msgArr[1])
			message.shouldBlock = true
			return message
		} 
		else if(cmd == "ungag"){
			if(msgArr.len() < 2){
				Chat_ServerPrivateMessage(message.player, "\x1b[34m[Mutes]\x1b[0m No name specified",false)
				message.shouldBlock = true
				return message
			}

			Mutes_Ungag(message.player, msgArr[1])
			message.shouldBlock = true
			return message
		}
		else if(cmd == "status"){
			if(msgArr.len() < 2){
				Chat_ServerPrivateMessage(message.player, "\x1b[34m[Mutes]\x1b[0m No name specified",false)
				message.shouldBlock = true
				return message
			}

			Mutes_Status(message.player, msgArr[1])
			message.shouldBlock = true
			return message
		}
		else if(cmd == "mutehelp"){
			Mutes_Help(message.player)
			message.shouldBlock = true
			return message
		}
    }

	// check if person is muted, block msg and send info 
	foreach(Mutes_PlayerData pd in mutes_playerData){
		if(pd.uid == message.player.GetUID()){
			if(pd.gagged){
				message.shouldBlock = true
				Chat_ServerPrivateMessage(message.player, "\x1b[34m[Mutes]\x1b[0m Your message has not been sent because you have been muted. If you believe this was unfair, apply for an unban at karma-gaming.net",false)
				return message
			}
		}
	}

	// player isnt muted return msg
    return message
}

/*
 *	CONFIG
 */

const string MUTES_HEADER = "global function Mutes_CfgInit\n" +
						 "global array<Mutes_PlayerData> mutes_cfg_players = []\n\n" +
						 "void function Mutes_CfgInit(){\n" +
						 "mutes_cfg_players.clear()\n"

const string MUTES_FOOTER = "}\n\n" +
						 "void function AddPlayer(string name, string uid, bool muted, bool gagged, int punishmentAmount){\n" +
						 "Mutes_PlayerData tmp;\ntmp.name = name;\ntmp.uid = uid;\ntmp.muted = muted;\ntmp.gagged = gagged;\ntmp.punishmentAmount = punishmentAmount;\nmutes_cfg_players.append(tmp);\n" +
						 "}"

void function Mutes_SaveConfig(){
	Mutes_CfgInit()

	array<Mutes_PlayerData> offlinePlayersToSave = []

	foreach(Mutes_PlayerData pdcfg in mutes_cfg_players){ // loop through each player in cfg
		bool found = false
		foreach(Mutes_PlayerData pd in mutes_playerData){ // loop through each player in current match
			if(pdcfg.uid == pd.uid){ // player in live match is in cfg // REM 
				found = true
			}
		}

		if(!found){
			offlinePlayersToSave.append(pdcfg)
		}
	}
	
	// merge live and offline players
	array<Mutes_PlayerData> allPlayersToSave = []
	allPlayersToSave.extend(mutes_playerData)
	allPlayersToSave.extend(offlinePlayersToSave)

	// write to buffer
	DevTextBufferClear()
	DevTextBufferWrite(MUTES_HEADER)

	foreach(Mutes_PlayerData pd in allPlayersToSave){
		DevTextBufferWrite(format("AddPlayer(\"%s\", \"%s\", %s, %s, %i)\n", pd.name, pd.uid, pd.muted.tostring(), pd.gagged.tostring(), pd.punishmentAmount))	
	}
	
    DevTextBufferWrite(MUTES_FOOTER)

    DevP4Checkout(path)
	DevTextBufferDumpToFile(path)
	DevP4Add(path)
	print("[Mutes] Saving config at " + path)
}

/*
 *  HELPER FUNCTIONS
 */

void function UpdateAdminList()
{
    string cvar = GetConVarString( "mutes_admin_uids" )

    array<string> dirtyUIDs = split( cvar, "," )
    foreach ( string uid in dirtyUIDs )
        mutes_adminUIDs.append(strip(uid))
}

bool function Mutes_IsAdmin(string uid){
	foreach(string _uid in mutes_adminUIDs){
		if(_uid == uid){
			return true
		}
	}
	return false
}

entity function Muted_GetPlayerFromSubstring(string substring){
	return Muted_GetPlayerFromName(Muted_GetFullPlayerNameFromSubstring(substring))
}

string function Muted_GetFullPlayerNameFromSubstring(string substring){
    foreach(entity player in GetPlayerArray()){ // shitty solution but cant do .find cause its not an entity
        if(player.GetPlayerName().tolower().find(substring.tolower()) != null)
            return player.GetPlayerName()
    }
    return "ERROR :(" // bad fix but this shouldnt even be possible to reach
}

entity function Muted_GetPlayerFromName(string name){
    entity target
    for(int i = 0; i < GetPlayerArray().len(); i++){
        if(name == GetPlayerArray()[i].GetPlayerName()){
            return GetPlayerArray()[i]
        }
    }
    return null
}

bool function Muted_CanFindPlayerFromSubstring(string substring){
    int found = 0
    foreach(entity player in GetPlayerArray()){ // shitty solution but cant do .find cause its not an entity
        if(player.GetPlayerName().tolower().find(substring.tolower()) != null && player.GetPlayerName().tolower().find(substring.tolower()) != -1)
            found++
    }

    if(found == 1){
        return true
    }
    return false
}