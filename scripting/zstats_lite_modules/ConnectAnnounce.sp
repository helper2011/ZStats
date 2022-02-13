#include <zstats_lite>
#include <geoip>

#pragma newdecls required

public Plugin myinfo = 
{
	name		= "[ZStats] Connect Announce",
	version		= "1.0",
	description	= "Player Connection Alert",
	author		= "hEl"
}

public void OnPluginStart()
{
	LoadTranslations("connect_announce.phrases");
}


public void ZStats_OnClientLoaded(int iClient)
{
	char szIP[16], szCountry[64];
	GetClientIP(iClient, szIP, 16);
	
	if(GeoipCountry(szIP, szCountry, 64))
	{
		ZStats_PrintToChatAll("%t", "Client connected", iClient, ZStats_GetClientData(iClient, CLIENT_POINTS), ZStats_GetClientData(iClient, CLIENT_PLACE), szCountry);
	}
	else
	{
		ZStats_PrintToChatAll("%t", "Client connected 2", iClient, ZStats_GetClientData(iClient, CLIENT_POINTS), ZStats_GetClientData(iClient, CLIENT_PLACE));
	}
}

