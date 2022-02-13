#include <zstats_lite>

#undef REQUIRE_PLUGIN
#include <StageManager>
#define REQUIRE_PLUGIN

#pragma newdecls required

enum
{
	SET_SOLO,
	SET_DUO,
	SET_TRIO,
	ZMS,
	ZMS_MULT
}

static const char g_sModules[][] = 
{
	"solowins",
	"duowins",
	"triowins",
	"wins",
	"dirtywins",
	"beat"
}

enum
{
	SOLO,
	DUO,
	TRIO,
	WINS,
	DIRTYWINS,
	BEAT
}

const int Modules = sizeof(g_sModules);

ConVar	g_hCvarPoints, g_hCvarMinTime, g_hMult[5];
int		Points, MinTime, Time, ID[Modules], BeatStages[MAXPLAYERS + 1];

bool g_bLibrary;

float Mult[5];

public Plugin myinfo = 
{
	name		= "[ZStats] Wins Rewards",
	version		= "1.0",
	description	= "",
	author		= "hEl"
}

public void OnPluginStart()
{
	g_hMult[SET_SOLO] = CreateConVar("zstats_win_mult_solo", "2");
	g_hMult[SET_DUO] = CreateConVar("zstats_win_mult_duo", "1.5");
	g_hMult[SET_TRIO] = CreateConVar("zstats_win_mult_duo", "1.25");
	
	g_hMult[ZMS] = CreateConVar("zstats_win_mult_zms", "10");
	g_hMult[ZMS_MULT] = CreateConVar("zstats_win_mult_per_some_zms", "1.0");
	
	for(int i; i < 5; i++)
	{
		Mult[i] = g_hMult[i].FloatValue;
		g_hMult[i].AddChangeHook(OnConVarChange2);
	}

	g_hCvarPoints = CreateConVar("zstats_win_reward", "4");
	g_hCvarMinTime = CreateConVar("zstats_win_mintime", "0");
	Points = g_hCvarPoints.IntValue;
	MinTime = g_hCvarMinTime.IntValue;
	g_hCvarPoints.AddChangeHook(OnConVarChange); 
	g_hCvarMinTime.AddChangeHook(OnConVarChange);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", OnRoundEnd);
	
	g_bLibrary = LibraryExists("StageManager");
	
	if(ZStats_IsModulesLoaded())
	{
		for(int i; i < Modules; i++)
		{
			ID[i] = ZStats_GetModuleIndexByName(g_sModules[i]);
		}
	}
}

public void ZStats_OnModuleLoaded(int iId, const char[] module)
{
	for(int i; i < Modules; i++)
	{
		if(!strcmp(module, g_sModules[i], false))
		{
			ID[i] = iId;
			break;
		}
	}
}


public void OnConVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if(cvar == g_hCvarPoints)
	{
		Points = g_hCvarPoints.IntValue;
	}
	else if(cvar == g_hCvarMinTime)
	{
		MinTime = g_hCvarMinTime.IntValue;
	}
}

public void OnConVarChange2(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	for(int i; i < 5; i++)
	{
		if(g_hMult[i] == cvar)
		{
			Mult[i] = cvar.FloatValue;
		}
	}
}

public void OnLibraryAdded(const char[] name)
{
	if(strcmp(name, "StageManager", false) == 0)
	{
		g_bLibrary = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if(strcmp(name, "StageManager", false) == 0)
	{
		g_bLibrary = false;
	}
}



public void OnRoundStart(Event hEvent, const char[] sEvent, bool bDontBroadcast)
{
	if(Points > 0)
	{
		Time = GetTime();
	}
		
}

public void StageManager_OnMapBeaten()
{
	GiveWinPoints(Points * StageManager_GetStages(), g_sModules[BEAT], ID[BEAT]);
}

public void OnRoundEnd(Event hEvent, const char[] sEvent, bool bDontBroadcast)
{
	if(Points <= 0 || GetTime() - Time < MinTime || hEvent.GetInt("winner") < 3)
	{
		return;
	}

	CreateTimer(0.0, Timer_OnRoundEnd);	
}

public Action Timer_OnRoundEnd(Handle hTimer)
{
	if(!g_bLibrary || StageManager_IsLegitWin() != 1)
	{
		GiveWinPoints(Points, g_sModules[DIRTYWINS]);
		return;
	}

	float fMultiplier = 1.0, Stage = float(StageManager_GetCurrentStage());
	int iId = -1, iCountCT = GetAliveCT(), iCountOther = GetOtherPlayers();
	
	if(Stage > 1.0)
	{
		fMultiplier *= (1.0 + Stage / 10.0);
	}
	
	if(Mult[ZMS] > 0.0)
	{
		float fZMs = (float(iCountOther) / Mult[ZMS]) * Mult[ZMS_MULT];
		if(fZMs > 1.0)
			fMultiplier *= fZMs;
	}
	

	if(iCountCT == 1)
	{
		if(Mult[SET_SOLO] > 1.0)
			fMultiplier *= Mult[SET_SOLO];
		
		iId = SOLO;
	}
	else if(iCountCT == 2)
	{
		if(Mult[SET_DUO] > 1.0)
			fMultiplier *= Mult[SET_DUO];
		

		iId = DUO;
	}
	else if(iCountCT == 3)
	{
		if(Mult[SET_TRIO] > 1.0)
			fMultiplier *= Mult[SET_TRIO];

		iId = TRIO;
	}
	else
	{
		iId = WINS;
	}

	if(iId != -1)
	{
		int iPoints = RoundToNearest(float(Points) * fMultiplier);
	
		if(iPoints > 250)
			iPoints = 250;
		
		GiveWinPoints(iPoints, g_sModules[iId], ID[iId]);
	
	}
}

void GiveWinPoints(int iPoints, const char[] module, int iModuleID = 0)
{
	int iStages = StageManager_GetStages();
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && ++BeatStages[i] && (iModuleID != ID[BEAT] || BeatStages[i] >= iStages))
		{
			ZStats_GiveClientPoints(i, iPoints, module, iModuleID);
		}
	}
	
	ZStats_GiveMapPoints(iPoints, iModuleID);
}

int GetAliveCT()
{
	int iCount;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			iCount++;
		}
	}
	
	return iCount;
}


int GetOtherPlayers()
{
	int iCount;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && (!IsPlayerAlive(i) || GetClientTeam(i) < 2))
		{
			iCount++;
		}
	}
	
	return iCount;
}

public void OnClientDisconnect(int iClient)
{
	BeatStages[iClient] = 0;
}