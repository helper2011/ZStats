#include <toponline>
#include <zstats_lite>

#pragma newdecls required

static const char g_sModule[] = "playtime";

int Online[MAXPLAYERS + 1], ID;

ConVar cvarNeedOnline;

public Plugin myinfo = 
{
	name		= "[ZStats] Playtime Rewards",
	version		= "1.0",
	description	= "",
	author		= "hEl"
}

public void OnPluginStart()
{
	cvarNeedOnline = CreateConVar("zstats_playtime_need", "600");
	CreateTimer(60.0, Timer_PlayTimeReward, _, TIMER_REPEAT);
	ID = ZStats_GetModuleIndexByName(g_sModule);
}

public void ZStats_OnModuleLoaded(int iId, const char[] module)
{
	if(!strcmp(module, g_sModule, false))
	{
		ID = iId;
	}
}

public Action Timer_PlayTimeReward(Handle hTimer)
{
	int iNeedOnline = cvarNeedOnline.IntValue;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && Online[i] >= iNeedOnline && ZStats_GiveClientPoints(i, _, g_sModule, ID, iNeedOnline) > 0)
		{
			Online[i] -= iNeedOnline;
		}
	}

}

public void OnClientOnlineCounted(int iClient, int iIncOnline, int iFullOnline)
{
	Online[iClient] += iIncOnline;
}

public void OnClientDisconnect(int iClient)
{
	Online[iClient] = 0;
}