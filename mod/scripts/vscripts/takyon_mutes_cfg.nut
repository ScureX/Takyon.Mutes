global function Mutes_CfgInit
global array<Mutes_PlayerData> mutes_cfg_players = []

void function Mutes_CfgInit(){
mutes_cfg_players.clear()
AddPlayer("Takyon_Scure", "1006792030176", false, true, 2)
AddPlayer("balls", "1005729651973", false, false, 0)
}

void function AddPlayer(string name, string uid, bool muted, bool gagged, int punishmentAmount){
Mutes_PlayerData tmp;
tmp.name = name;
tmp.uid = uid;
tmp.muted = muted;
tmp.gagged = gagged;
tmp.punishmentAmount = punishmentAmount;
mutes_cfg_players.append(tmp);
}