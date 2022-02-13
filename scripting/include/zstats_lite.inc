#if defined _zstats_included
	#endinput
#endif
#define _zstats_included

#define MAIN_COLOR "\x07FFF673"
#define COLOR_FIRST "\x07FFA473"
#define COLOR_SECOND "\x075FD4B1"


enum /* LoadData */
{
	LOAD_MAP,
	LOAD_MODULES,
	LOAD_DATABASE,
	LOAD_DATA_TOTAL
}

enum /* QueryData */
{
	QUERY_CLAN_ID,
	QUERY_COUNTRY_ID,
	QUERY_MAP_ID,
	QUERY_MODULE_ID,
	QUERY_STAGE,
	QUERY_POINTS,
	QUERY_VALUE,
	QUERY_ZOMBIES,
	QUERY_TIME,
	
	QUERY_SIZE
}

enum /* MapQueryData */
{
	MAP_QUERY_MODULE_ID,
	MAP_QUERY_STAGE,
	MAP_QUERY_POINTS,
	MAP_QUERY_VALUE,
	MAP_QUERY_ZOMBIES,
	MAP_QUERY_TIME,
	MAP_QUERY_SIZE
}



enum /* ClientData */
{
	CLIENT_ID,
	CLIENT_TEAM,
	CLIENT_TEAM_TIME,
	CLIENT_PLACE,
	CLIENT_POINTS,
	CLIENT_FSPAWN,
	CLIENT_LOADED,
	CLIENT_CLAN_ID,
	CLIENT_COUNTRY_ID,
	CLIENT_ARRAY_CLAN_ID,
	CLIENT_ARRAY_COUNTRY_ID,
	CLIENT_DATA_TOTAL
}

enum /* ModuleData */
{
	MODULE_ID,
	MODULE_POINTS,
	MODULE_COOLDOWN,
	MODULE_TAKE_VALUE,
	MODULE_MAX_REWARDS,
	MODULE_MIN_PLAYERS,
	MODULE_ACCOUNT,
	MODULE_ACCOUNT_OPTIMIZE,
	MODULE_SHOWTOP,
	MODULE_SHOWSTATS,
	MODULE_DATA_TOTAL
}

enum /* Arrays */
{
	ARRAY_CLANS,
	ARRAY_COUNTRIES,
	ARRAY_TOTAL
}

enum /* Array data */
{
	ARRAY_DATA_ID,
	ARRAY_DATA_POINTS,
	ARRAY_DATA_CLIENTS,
	ARRAY_DATA_LOADED,
	ARRAY_DATA_TOTAL
}


native bool ZStats_IsDBLoaded();
native bool ZStats_IsMapLoaded();
native bool ZStats_IsModulesLoaded();
native Database ZStats_GetDatabase();
native int ZStats_GetModuleIdByName(const char[] module);
native int ZStats_GetModuleIndexByName(const char[] module);
native int ZStats_GetModuleIndex(int iModuleId);
native int ZStats_GetModuleData(int iModuleIndex, int iData);
native int ZStats_GetClientData(int iClient, int iData);
native int ZStats_GiveMapPoints(int iPoints = 0, int iModuleIndex, int iValue = 1);
native int ZStats_GiveClientPoints(int iClient, int iPoints = 0, const char[] message, int iModuleIndex, int iValue = 1);
native void ZStats_PrintToChat(int iClient, const char[] message, any ...);
native void ZStats_PrintToChatAll(const char[] message, any ...);


/*typedef OnClientDisplayMainPage = function void (int iClient, char[] szBuffer, int iSize);
native bool ZStats_RegisterCallbacks(const char[] sModule, OnClientDisplayMainPage callback = INVALID_FUNCTION);
native bool ZStats_UnRegisterCallbacks(const char[] sModule);*/

forward void ZStats_OnDBLoaded();
forward void ZStats_OnMapLoaded(int iMapID);
forward void ZStats_OnClientLoaded(int iClient);
forward void ZStats_OnModuleLoaded(int iIndex, const char[] module);
forward void ZStats_OnClientGotPoints(int iClient, int& iPoints);
forward void ZStats_OnClientModuleValuesLoaded(int iClient, const char[] module, int& iValue, int& iValue2);


public SharedPlugin __pl_ZStats =
{
	name = "ZStats",
	file = "ZStats.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_ZStats_SetNTVOptional()
{
	MarkNativeAsOptional("ZStats_IsDBLoaded");
	MarkNativeAsOptional("ZStats_IsMapLoaded");
	MarkNativeAsOptional("ZStats_IsModulesLoaded");
	MarkNativeAsOptional("ZStats_GetModuleIdByName");
	MarkNativeAsOptional("ZStats_GetModuleIndexByName");
	MarkNativeAsOptional("ZStats_GetModuleIndex");
	MarkNativeAsOptional("ZStats_GetModuleData");
	MarkNativeAsOptional("ZStats_GetClientData");
	MarkNativeAsOptional("ZStats_GetDatabase");
	MarkNativeAsOptional("ZStats_GiveClientPoints");
	MarkNativeAsOptional("ZStats_PrintToChat");
	MarkNativeAsOptional("ZStats_PrintToChatAll");
}
#endif