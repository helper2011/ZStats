#include <zstats_lite>

#pragma newdecls required

static const char g_sModule[] = "damage";

ConVar g_hCvarMustDamage;

int ID, DamageNeed, Damage[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name		= "[ZStats] Damaging Zombies",
	version		= "1.0",
	author		= "hEl"
}

public void OnPluginStart()
{
	g_hCvarMustDamage = CreateConVar("zstats_damage_need", "4500");
	DamageNeed = g_hCvarMustDamage.IntValue;
	g_hCvarMustDamage.AddChangeHook(OnConVarChange);

	HookEvent("player_hurt", OnPlayerHurt);
	
	ID = ZStats_GetModuleIndexByName(g_sModule);
}

public void ZStats_OnModuleLoaded(int iIndex, const char[] module)
{
	if(!strcmp(module, g_sModule, false))
	{
		ID = iIndex;
	}
}

public void OnConVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	DamageNeed = g_hCvarMustDamage.IntValue;
}

public void OnPlayerHurt(Event hEvent, const char[] event, bool bDontBroadcast)
{
	if(DamageNeed <= 0)
		return;
	
	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker")), iDamage = hEvent.GetInt("dmg_health");
	
	if(0 < iAttacker <= MaxClients && 0 < iDamage <= 1000 && GetClientTeam(iAttacker) > 2 && (Damage[iAttacker] += hEvent.GetInt("dmg_health")) >= DamageNeed && ZStats_GiveClientPoints(iAttacker, _, g_sModule, ID, Damage[iAttacker]) != -1)
	{
		Damage[iAttacker] = 0;
	}
}