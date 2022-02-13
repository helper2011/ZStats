int
	MapID,
	MapPoints,
	MapModuleValue[MAX_MODULES];
char
	CurrentMap[256];
ArrayList
	MapQueries;
	
public void OnMapStart()
{
	DebugMessage("OnMapStart")
	SaveMapData();
	ResetMapData();
	IsLoaded[LOAD_MAP] = false
	GetCurrentMap(CurrentMap, 256);
	StringToLowercase(CurrentMap);
	DB_GetMap();
	DB_GetClientAveragePoints();
	BuildTopMenu();
	BuildTopMenu(_, false);
	
}

public void OnMapEnd()
{
	DebugMessage("OnMapEnd")
	AverageClientPoints = 0;
	//AverageAccountClientPoints = 0;
	ResetArrayDataAll();
	ResetClientArrayAll();
}

void DB_GetMap()
{
	if(!IsLoaded[LOAD_DATABASE] || MapID)
		return;
	
	char szQuery[256];
	FormatEx(szQuery, 256, "SELECT * FROM `maps` WHERE `name` = '%s';", CurrentMap);
	DBG_SQL_Query(szQuery)
	g_hDatabase.Query(SQL_Callback_SelectMap, szQuery);
}

public void SQL_Callback_SelectMap(Database hDatabase, DBResultSet hResults, const char[] sError, int iData) 
{
	DBG_SQL_Response("SQL_Callback_SelectMap")
	if(sError[0])
	{
		LogError("SQL_Callback_SelectMap: %s", sError);
		return;
	}
	char szBuffer[256];
	GetCurrentMap(szBuffer, 256);
	if(strcmp(szBuffer, CurrentMap, false))
	{
		return;
	}
	
	if(hResults.FetchRow())
	{
		MapID = hResults.FetchInt(0);
		char szQuery[256];
		FormatEx(szQuery, 256, "UPDATE `maps` SET `lastvisit` = %i WHERE `id` = %i;", GetTime(), MapID);
		DBG_SQL_Query(szQuery)
		g_hDatabase.Query(SQL_Callback_CheckError, szQuery);
		
		int iColumn;
		for(int i; i < Modules; i++)
		{
			MapModuleValue[i] = hResults.FieldNameToNum(Module[i], iColumn) ? hResults.FetchInt(iColumn):0;
		}
		OnMapLoaded();
	}
	else
	{
		char szQuery[256];int iTime = GetTime();
		FormatEx(szQuery, 256, "INSERT INTO `maps` (`name`, `joined`, `lastvisit`) VALUES ('%s', %i, %i);", CurrentMap, iTime, iTime);
		DBG_SQL_Query(szQuery)
		g_hDatabase.Query(SQL_Callback_CreateMap, szQuery);
	}
	
}

public void SQL_Callback_CreateMap(Database hDatabase, DBResultSet hResults, const char[] szError, int iData)
{
	DBG_SQL_Response("SQL_Callback_CreateMap")
	if(szError[0])
	{
		LogError("SQL_Callback_CreateMap: %s", szError);
		return;
	}
	char szBuffer[256];
	GetCurrentMap(szBuffer, 256);
	if(!strcmp(szBuffer, CurrentMap, false))
	{
		MapID = hResults.InsertId;
		OnMapLoaded();
	}
}

void OnMapLoaded()
{
	IsLoaded[LOAD_MAP] = true;
	Forward_OnMapLoaded();
}

void SaveMapData()
{
	DebugMessage("SaveMapData")
	if(!IsLoaded[LOAD_DATABASE] || !MapID)
		return;
	
	char szQuery[512];
	FormatEx(szQuery, sizeof(szQuery), "UPDATE `maps` SET `points` = %i WHERE `id` = %i;", MapPoints, MapID);
	DBG_SQL_Query(szQuery)
	g_hDatabase.Query(SQL_Callback_CheckError, szQuery);
	
	for(int i; i < Modules; i++)
	{
		FormatEx(szQuery, 256, "UPDATE `maps` SET `%s` = %i WHERE `id` = %i", Module[i], MapModuleValue[i], MapID);
		DBG_SQL_Query(szQuery)
		g_hDatabase.Query(SQL_Callback_CheckError, szQuery);
	}
	
	int iLength = MapQueries.Length;
	
	for(int i; i < iLength; i += MAP_QUERY_SIZE)
	{
		int	iModuleID	= MapQueries.Get(i + MAP_QUERY_MODULE_ID), 
			iStage		= MapQueries.Get(i + MAP_QUERY_STAGE), 
			iPoints		= MapQueries.Get(i + MAP_QUERY_POINTS), 
			iValue		= MapQueries.Get(i + MAP_QUERY_VALUE),
			iZombies	= MapQueries.Get(i + MAP_QUERY_ZOMBIES),
			iTime		= MapQueries.Get(i + MAP_QUERY_TIME);
		
		
		g_hDatabase.Format(szQuery, 512, "INSERT INTO `map_account` (`map_id`, `module_id`, `stage`, `points`, `value`, `zombies`, `time`) VALUES (%i, %i, %i, %i, %i, %i, %i);", MapID, iModuleID, iStage, iPoints, iValue, iZombies, iTime);
		DBG_SQL_Query(szQuery)
		g_hDatabase.Query(SQL_Callback_CheckError, szQuery);
	}
	
	MapQueries.Clear();
}

void ResetMapData()
{
	delete MapQueries;
	MapQueries = new ArrayList(ByteCountToCells(16));
	MapID = MapPoints = 0;
	
	for(int i; i < Modules; i++)
	{
		MapModuleValue[i] = 0;
	}
}