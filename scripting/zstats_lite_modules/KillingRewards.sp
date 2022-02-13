#include <sourcemod>
#include <zstats_lite>

#pragma newdecls required

int ID[2];
static const char g_sModules[][] = {"infections", "kills"};

public Plugin myinfo = 
{
	name		= "[ZStats] Killing Rewards",
	version		= "1.0",
	description	= "",
	author		= "hEl"
}

public void OnPluginStart()
{
	HookEvent("player_death", OnPlayerDeath);

	if(ZStats_IsModulesLoaded())
	{
		ID[0] = ZStats_GetModuleIndexByName(g_sModules[0]);
		ID[1] = ZStats_GetModuleIndexByName(g_sModules[1]);
	}
}


public void ZStats_OnModuleLoaded(int iId, const char[] module)
{
	if(!strcmp(module, g_sModules[0], false))
	{
		ID[0] = iId;
	}
	else if(!strcmp(module, g_sModules[1], false))
	{
		ID[1] = iId;
	}
}

public void OnPlayerDeath(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	
	if(0 < iAttacker <= MaxClients && iAttacker != GetClientOfUserId(hEvent.GetInt("userid")))
	{
		int iTeam = GetClientTeam(iAttacker) - 2;
		
		if(iTeam >= 0)
		{
			ZStats_GiveClientPoints(iAttacker, _, g_sModules[iTeam], ID[iTeam]);
		}
	}
}