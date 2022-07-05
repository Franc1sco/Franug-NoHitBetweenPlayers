#include <sourcemod>
#include <sdkhooks>
#include <dhooks>


#define VERSION "0.2"

Handle activeTimer[MAXPLAYERS + 1] = null;

public Plugin:myinfo =
{
    name = "SM No Hit Between players",
    author = "Franc1sco franug",
    description = "",
    version = VERSION,
    url = "https://steamcommunity.com/id/franug"
};


public OnPluginStart()
{
	CreateConVar("sm_nohit_players_version", VERSION, "", FCVAR_NOTIFY);
	
	GameData hData = new GameData("collisionhook");

	Handle hDetour = DHookCreateFromConf(hData, "PassEntityFilter");
	if( !hDetour ) 
		SetFailState("Failed to find \"PassEntityFilter\" offset.");
	delete hData;

	// Setup pre hook to grab parameters
	if( !DHookEnableDetour(hDetour, false, detour_pre) ) 
		SetFailState("Failed to detour \"PassEntityFilter\". pre");
		
	HookEvent("weapon_fire", EventWeaponFire, EventHookMode_Pre); 
				
}

public void OnClientDisconnect(int client)
{
	delete activeTimer[client];
}

// use only new syntax status yeah i know, soon, just lazy :D
public EventWeaponFire(Handle:event,const String:name[],bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	char szWeapon[32];
	GetEventString(event, "weapon", szWeapon, sizeof(szWeapon));
	if(!StrEqual(szWeapon, "weapon_knife") && !StrEqual(szWeapon, "weapon_bayonet"))
		return;
		
	// give totally ignore players collision during a 0.1 for ignore knife hit but keep the block between players
	delete activeTimer[client];
	activeTimer[client] = CreateTimer(0.1, Timer_Done, client);
} 

public Action Timer_Done(Handle timer, int client)
{
	activeTimer[client] = null;
}

public MRESReturn detour_pre(Handle hReturn, Handle hParams)
{
	if(DHookIsNullParam(hParams, 1) || DHookIsNullParam(hParams, 2))
		return MRES_Ignored;
		
    // Store prehook parameters into global variables
	int ent1    =    DHookGetParam(hParams, 1);
	int ent2    =    DHookGetParam(hParams, 2);
	
	//PrintToConsoleAll("entities %i y %i", ent1, ent2);
	
	if(!IsValidClient(ent1) || !IsValidClient(ent2) || ent1 == ent2)
		return MRES_Ignored;
	
	if(activeTimer[ent1] == null && activeTimer[ent2] == null)
		return MRES_Ignored;
		
	//
	//PrintToConsoleAll("done");
	DHookSetReturn(hReturn, 0);
	return MRES_Supercede;
} 

stock bool:IsValidClient( client ) 
{
    if ( 0 < client <= MaxClients && IsClientInGame(client) ) 
        return true; 
     
    return false; 
}
