#include <zstats_lite>
#include <BossHP>
#pragma newdecls required

static const char g_sModule[] = "bossdamage";

ConVar g_hCvarMustDamage;

int ID, DamageNeed, Damage[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name		= "[ZStats] Damaging Bosses",
	version		= "1.0",
	author		= "hEl"
}

public void OnPluginStart()
{
	g_hCvarMustDamage = CreateConVar("zstats_bossdamage_need", "75");
	DamageNeed = g_hCvarMustDamage.IntValue;
	g_hCvarMustDamage.AddChangeHook(OnConVarChange);
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

public void OnBossDamaged(CBoss Boss, CConfig Config, int client, float damage)
{
	if(0 < client <= MaxClients)
	{
		if(DamageNeed > 0 && ++Damage[client] >= DamageNeed && ZStats_GiveClientPoints(client, _, g_sModule, ID, Damage[client]) != -1)
		{
			Damage[client] = 0;
		}
	}

}