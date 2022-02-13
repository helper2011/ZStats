#include <sdktools>
#include <zstats_lite>

#pragma newdecls required

static const char g_sModule[] = "triggers";
int		ID;
bool	g_bDisabled[2048];

public Plugin myinfo = 
{
	name		= "[ZStats] Trigger Rewards",
	version		= "1.0",
	description	= "",
	author		= "hEl"
}

public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEntityOutput("trigger_once", "OnStartTouch", OnStartTouch);
	HookEntityOutput("func_button", "OnPressed", OnPressed);	
	
	ID = ZStats_GetModuleIndexByName(g_sModule);
}

public void ZStats_OnModuleLoaded(int iId, const char[] module)
{
	if(!strcmp(module, g_sModule, false))
	{
		ID = iId;
	}
}


public void OnRoundStart(Event hEvent, const char[] sEvent, bool bDontBroadcast)
{
	for(int i = MaxClients + 1; i < 2048; i++)
	{
		g_bDisabled[i] = false;
	}
		
}

public void OnStartTouch(const char[] sOutput, int iCaller, int iActivator, float fDelay)
{
	if (IsValidClientAndEntity(iActivator, iCaller))
	{
		StartCoolDown(iActivator, iCaller);
	}
}

public void OnPressed(const char[] sOutput, int iCaller, int iActivator, float fDelay)
{
	if (IsValidClientAndEntity(iActivator, iCaller))
	{
		int iParent = INVALID_ENT_REFERENCE;
		if ((iParent = GetEntPropEnt(iCaller, Prop_Data, "m_hMoveParent")) != INVALID_ENT_REFERENCE)
		{
			char sClassname[64];
			GetEdictClassname(iParent, sClassname, sizeof(sClassname));
	
			if (strncmp(sClassname, "weapon_", 7, false))
			{
				StartCoolDown(iActivator, iCaller);
			}
		}
	}
}

void StartCoolDown(int iActivator, int iEntity)
{
	if(ZStats_GiveClientPoints(iActivator, _, g_sModule, ID) > 0)
	{
		g_bDisabled[iEntity] = true;
	}
}

public bool IsValidClientAndEntity(int iClient, int iEntity)
{
	return (!g_bDisabled[iEntity] && 0 < iClient <= MaxClients && IsClientInGame(iClient) && IsPlayerAlive(iClient) && GetClientTeam(iClient) == 3);
}
