#include <sourcemod>
#include <zstats_lite>
#include <cstrike>
#include <geoip>

#undef REQUIRE_PLUGIN
#include <StageManager>
#include <hlstatsx_loghelper>
#define REQUIRE_PLUGIN

#pragma newdecls required

#define DEBUG_MODE 0

#define CHARSET "utf8"
#define COLLATION "utf8_unicode_ci"

#include "zstats_lite2/debug.sp"
#include "zstats_lite2/libraries.sp"
#include "zstats_lite2/db.sp"
#include "zstats_lite2/map.sp"
#include "zstats_lite2/auth.sp"
#include "zstats_lite2/arrays.sp"
#include "zstats_lite2/forwards.sp"
#include "zstats_lite2/functions.sp"
#include "zstats_lite2/api.sp"
#include "zstats_lite2/top.sp"
#include "zstats_lite2/menu.sp"
#include "zstats_lite2/commands.sp"



public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ZStats_IsDBLoaded",			Native_IsDBLoaded);
	CreateNative("ZStats_IsMapLoaded",			Native_IsMapLoaded);
	CreateNative("ZStats_IsModulesLoaded",		Native_IsModulesLoaded);
	CreateNative("ZStats_GetDatabase",			Native_GetDatabase);
	
	CreateNative("ZStats_GetModuleIndex",		Native_GetModuleIndex);
	CreateNative("ZStats_GetModuleIndexByName",	Native_GetModuleIndexByName);
	CreateNative("ZStats_GetModuleIdByName",	Native_GetModuleIdByName);
	CreateNative("ZStats_GetModuleData",		Native_GetModuleData);
	CreateNative("ZStats_GetClientData",		Native_GetClientData);

	CreateNative("ZStats_GiveMapPoints",		Native_GiveMapPoints);
	CreateNative("ZStats_GiveClientPoints",		Native_GiveClientPoints);
	CreateNative("ZStats_PrintToChat",			Native_PrintToChat);
	CreateNative("ZStats_PrintToChatAll",		Native_PrintToChatAll);
	RegPluginLibrary("ZStats");
	return APLRes_Success;
}

public Plugin myinfo = 
{
	name		= "ZStats",
	version		= "1.0",
	description	= "Statistics for Zombie Escape, originally made for SIBGamers",
	author		= "hEl"
}

public void OnPluginStart()
{
	LoadTranslations("zstats.phrases");
	HookEvent("round_end", OnRoundEnd);
	HookEvent("player_team", OnPlayerTeam);
	HookEvent("player_spawn", OnPlayerSpawn);

	CheckLibraries();
	ConnectToDatabase();
	initGlobalForwards();
	CreateConsoleCommands();

}

public void OnPluginEnd()
{
	SaveMapData();
	SaveClientsData();
	SaveArrayDataAll();
}

public void OnPlayerSpawn(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if(!ClientData[iClient][CLIENT_FSPAWN] && ClientData[iClient][CLIENT_LOADED])
	{
		CreateTimer(0.0, Timer_OnPlayerFirstSpawn, iClient);
	}
}

public Action Timer_OnPlayerFirstSpawn(Handle hTimer, int iClient)
{
	if(IsClientInGame(iClient) && IsPlayerAlive(iClient) && ClientData[iClient][CLIENT_LOADED])
	{
		ClientData[iClient][CLIENT_FSPAWN] = 1;
		DB_GetClientClan(iClient);
	}
}

public void OnPlayerTeam(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid")), iTeam = hEvent.GetInt("team");
	
	if(ClientData[iClient][CLIENT_TEAM] != iTeam)
	{
		ClientData[iClient][CLIENT_TEAM] = iTeam;
		ClientData[iClient][CLIENT_TEAM_TIME] = GetTime();
	}
}

public void OnRoundEnd(Event hEvent, const char[] event, bool bDontBroadcast)
{
	SaveClientsData(false);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && ClientData[i][CLIENT_LOADED])
		{
			DB_GetClientClan(i);
			
			for(int j; j < Modules; j++)
			{
				ClientModuleRewards[i][j] = 0;
			}

		}
	}
	BuildTopMenu();
	GetArrayCount();
	DB_GetClientsCount();
}