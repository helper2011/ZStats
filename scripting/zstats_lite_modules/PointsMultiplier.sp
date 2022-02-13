#include <zstats_lite>

#pragma newdecls required

float Multiplier;

public Plugin myinfo = 
{
	name		= "[ZStats] Points Multiplier",
	version		= "1.0",
	description	= "",
	author		= "hEl"
}

public void OnPluginStart()
{
	ConVar cvar = CreateConVar("sgstats_points_multiplier", "1.0", _, _, true, 0.2, true, 5.0);
	cvar.AddChangeHook(OnConVarChange);
	Multiplier = cvar.FloatValue;
}

public void OnConVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	Multiplier = cvar.FloatValue;
}

public void ZStats_OnClientGotPoints(int iClient, int& iPoints)
{
	iPoints = RoundToNearest(Multiplier * float(iPoints));
}
