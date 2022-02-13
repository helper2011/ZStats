#include <sourcemod>
#include <entWatch_Sg>
#include <zstats_lite>

#pragma newdecls required

static const char g_sModule[] = "itemsuse";

int ID;

public Plugin myinfo = 
{
	name		= "[ZStats] Use of Items",
	version		= "1.0",
	description	= "",
	author		= "hEl"
}

public void OnPluginStart()
{
	ID = ZStats_GetModuleIndexByName(g_sModule);
}

public void ZStats_OnModuleLoaded(int iId, const char[] module)
{
	if(!strcmp(module, g_sModule, false))
	{
		ID = iId;
	}
}

public void entWatch_OnClientUseItem(int iClient, int iItem)
{
	ZStats_GiveClientPoints(iClient, _, g_sModule, ID);
}