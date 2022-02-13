int
	ClientData[MAXPLAYERS + 1][CLIENT_DATA_TOTAL],
	ClientModuleRewards[MAXPLAYERS + 1][MAX_MODULES],
	ClientModuleCD[MAXPLAYERS + 1][MAX_MODULES],
	ClientModuleValue[MAXPLAYERS + 1][MAX_MODULES];

ArrayList
	Queries[MAXPLAYERS + 1][2];

char
	ClanName[MAXPLAYERS + 1][64],
	CountryName[MAXPLAYERS + 1][64];

public void OnClientPostAdminCheck(int iClient)
{
	DebugMessage("OnClientPostAdminCheck: %N", iClient)
	if(IsLoaded[LOAD_DATABASE])
		LoadClientData(iClient);
}

public void OnClientDisconnect(int iClient)
{
	DebugMessage("OnClientDisconnect: %N", iClient)
	SaveClientData(iClient);
	DropClientArray(iClient);
	ResetClientData(iClient);
	delete Queries[iClient][0];
	delete Queries[iClient][1];
}

public void SQL_Callback_SelectClient(Database hDatabase, DBResultSet hResults, const char[] sError, any iUserID)
{
	DBG_SQL_Response("SQL_Callback_SelectClient")
	if(sError[0])
	{
		LogError("SQL_Callback_SelectClient: %s", sError);
		return;
	}
	
	int iClient = GetClientOfUserId(iUserID);
	if(iClient)
	{
		char szQuery[256], szName[MAX_NAME_LENGTH * 2 + 1];
		GetClientName(iClient, szQuery, MAX_NAME_LENGTH);
		g_hDatabase.Escape(szQuery, szName, sizeof(szName));
		int iTime = GetTime(), iId = GetSteamAccountID(iClient);
		if(hResults.FetchRow())
		{
			ClientData[iClient][CLIENT_POINTS] = hResults.FetchInt(4);
			int iColumn;
			for(int i; i < Modules; i++)
			{
				ClientModuleValue[iClient][i] = hResults.FieldNameToNum(Module[i], iColumn) ? hResults.FetchInt(iColumn):0;
			}
			
			OnClientPreLoaded(iClient);

			FormatEx(szQuery, sizeof(szQuery), "UPDATE `players` SET `lastvisit` = %i, `name` = '%s' WHERE `id` = %i;", iTime, szName, ClientData[iClient][CLIENT_ID]);
			DBG_SQL_Query(szQuery)
			g_hDatabase.Query(SQL_Callback_CheckError, szQuery);
		}
		else
		{
			g_hDatabase.Format(szQuery, sizeof(szQuery), "INSERT INTO `players` (`id`, `name`, `joined`, `lastvisit`) VALUES (%i, '%s', %i, %i);", iId, szName, iTime, iTime);
			DBG_SQL_Query(szQuery)
			g_hDatabase.Query(SQL_Callback_CreateClient, szQuery, GetClientUserId(iClient));
		}
		
		
	}
}

public void SQL_Callback_CreateClient(Database hDatabase, DBResultSet hResults, const char[] szError, any iUserID)
{
	DBG_SQL_Response("SQL_Callback_CreateClient")
	if(szError[0])
	{
		LogError("SQL_Callback_CreateClient: %s", szError);
		return;
	}
	
	int iClient = GetClientOfUserId(iUserID);
	if(iClient)
	{
		Clients++;
		OnClientPreLoaded(iClient);
	}
}



void OnClientPreLoaded(int iClient)
{
	DB_GetClientPlace(iClient, 0);
	DB_GetClientClan(iClient, 0);
	DB_GetClientCountry(iClient, 0);
}

void DB_GetClientPlace(int iClient, int iType = 1)
{
	char szBuffer[256];
	FormatEx(szBuffer, 256, "SELECT COUNT(`id`) FROM `players` WHERE `points` >= %i", ClientData[iClient][CLIENT_POINTS]);
	DBG_SQL_Query(szBuffer)
	g_hDatabase.Query(SQL_Callback_GetClientPlace, szBuffer, CreateAuthClientDataPack(iClient, iType));
}

public void SQL_Callback_GetClientPlace(Database hDatabase, DBResultSet hResults, const char[] sError, DataPack hPack) 
{
	DBG_SQL_Response("SQL_Callback_GetClientPlace")
	int iClient, iType;
	bool bValid = ReadAuthClientDataPack(hPack, iClient, iType);
	
	if(sError[0])
	{
		LogError("SQL_Callback_GetClientPlace: %s", sError);
		return;
	}
	if(!bValid || !hResults.FetchRow())
	{
		return;
	}
	
	ClientData[iClient][CLIENT_PLACE] = hResults.FetchInt(0);
	CheckClientLoading(iClient, iType);
}

void DB_GetClientClan(int iClient, int iType = 1)
{
	int ClanID = GetClientClanID(iClient);
	if(ClientData[iClient][CLIENT_CLAN_ID] > 1 && ClanID == ClientData[iClient][CLIENT_CLAN_ID])
	{
		return;
	}
	
	DropClientArray(iClient, ARRAY_CLANS);
	
	if(ClanID <= 1)
	{
		ClientData[iClient][CLIENT_CLAN_ID] = 0;
		CheckClientLoading(iClient, iType);
		return;
	}

	
	ClientData[iClient][CLIENT_CLAN_ID] = ClanID;
	
	char szQuery[256];
	FormatEx(szQuery, sizeof(szQuery), "SELECT `id`, `name` FROM `clans` WHERE `id` = %i;", ClanID);
	DBG_SQL_Query(szQuery)
	g_hDatabase.Query(SQL_Callback_SelectClan, szQuery, CreateAuthClientDataPack(iClient, iType));
}

public void SQL_Callback_SelectClan(Database hDatabase, DBResultSet hResults, const char[] sError, DataPack hPack) 
{
	DBG_SQL_Response("SQL_Callback_SelectClan")
	int iClient, iType;
	bool bValid = ReadAuthClientDataPack(hPack, iClient, iType);
	if(sError[0])
	{
		LogError("SQL_Callback_SelectClan: %s", sError);
		return;
	}

	if(!bValid)
	{
		return;
	}
	//PrintToServer("SQL_Callback_SelectClan 2");

	char szQuery[256], szClanTag[MAX_NAME_LENGTH * 2 + 1];
	CS_GetClientClanTag(iClient, ClanName[iClient], 64);
	g_hDatabase.Escape(ClanName[iClient], szClanTag, sizeof(szClanTag));
	
	if(ClientData[iClient][CLIENT_CLAN_ID] != GetClientClanID(iClient) || !szClanTag[0] || !strlen(szClanTag) || !GetClientArray(iClient, ARRAY_CLANS))
	{
		ClanName[iClient][0] = 0;
		ClientData[iClient][CLIENT_CLAN_ID] = 0;
		CheckClientLoading(iClient, iType);
		return;
	}
	//PrintToServer("SQL_Callback_SelectClan 3");
	
	if(hResults.FetchRow())
	{
		//PrintToServer("SQL_Callback_SelectClan 4");
		g_hDatabase.Format(szQuery, sizeof(szQuery), "UPDATE `clans` SET `name` = '%s', `lastvisit` = %i WHERE `id` = %i;", szClanTag, GetTime(), ClientData[iClient][CLIENT_CLAN_ID]);
		DBG_SQL_Query(szQuery)
		g_hDatabase.Query(SQL_Callback_CheckError, szQuery);
		CheckClientLoading(iClient, iType);
		
	}
	else if(GetArrayAttribute(ARRAY_CLANS, ARRAY_DATA_CLIENTS, ClientData[iClient][CLIENT_ARRAY_CLAN_ID]) == 1)
	{
		//PrintToServer("SQL_Callback_SelectClan 5");
		int iTime = GetTime();
		g_hDatabase.Format(szQuery, sizeof(szQuery), "INSERT INTO `clans` (`name`, `id`, `joined`, `lastvisit`) VALUES ('%s', %i, %i, %i);", szClanTag, ClientData[iClient][CLIENT_CLAN_ID], iTime, iTime);
		DBG_SQL_Query(szQuery)
		g_hDatabase.Query(SQL_Callback_CreateClan, szQuery, CreateAuthClientDataPack(iClient, iType));
	}
	else
	{
		//PrintToServer("SQL_Callback_SelectClan 6");
		CheckClientLoading(iClient, iType);
	}
}

public void SQL_Callback_CreateClan(Database hDatabase, DBResultSet hResults, const char[] szError, DataPack hPack)
{
	DBG_SQL_Response("SQL_Callback_CreateClan")
	int iClient, iType;
	bool bValid = ReadAuthClientDataPack(hPack, iClient, iType);
	if(szError[0])
	{
		LogError("SQL_Callback_CreateClan: %s", szError);
		return;
	}
	if(!bValid)
	{
		return;
	}

	
	if(ClientData[iClient][CLIENT_CLAN_ID] != GetClientClanID(iClient))
	{
		ClanName[iClient][0] = 0;
		ClientData[iClient][CLIENT_CLAN_ID] = 0;
		DropClientArray(iClient, ARRAY_CLANS);
	}
	else
	{
		GetArrayData(ARRAY_CLANS, ClientData[iClient][CLIENT_ARRAY_CLAN_ID]);
	}
	CheckClientLoading(iClient, iType);
}


void DB_GetClientCountry(int iClient, int iType = 1)
{
	char szIP[16];
	GetClientIP(iClient, szIP, 16);
	if(!GeoipCountry(szIP, CountryName[iClient], 64))
	{
		CountryName[iClient][0] = 0;
		ClientData[iClient][CLIENT_COUNTRY_ID] = 0;
		CheckClientLoading(iClient, iType);
		return;
	}
	
	char szQuery[256];
	FormatEx(szQuery, sizeof(szQuery), "SELECT `id` FROM `countries` WHERE `name` = '%s';", CountryName[iClient]);
	DBG_SQL_Query(szQuery)
	g_hDatabase.Query(SQL_Callback_SelectCountry, szQuery, CreateAuthClientDataPack(iClient, iType));
}

public void SQL_Callback_SelectCountry(Database hDatabase, DBResultSet hResults, const char[] sError, DataPack hPack) 
{
	DBG_SQL_Response("SQL_Callback_SelectCountry")
	int iClient, iType;
	bool bValid = ReadAuthClientDataPack(hPack, iClient, iType);
	if(sError[0])
	{
		LogError("SQL_Callback_SelectCountry: %s", sError);
		return;
	}

	if(!bValid)
	{
		return;
	}
	if(!CountryName[iClient][0])
	{
		ClientData[iClient][CLIENT_COUNTRY_ID] = 0;
		CheckClientLoading(iClient, iType);
		return;
	}
	if(hResults.FetchRow())
	{
		ClientData[iClient][CLIENT_COUNTRY_ID] = hResults.FetchInt(0);
		GetClientArray(iClient, ARRAY_COUNTRIES);
		CheckClientLoading(iClient, iType);
	}
	else
	{
		int iId = Array_GetArrayByName(ARRAY_COUNTRIES, ClanName[iClient]);
		
		if(iId == -1)
		{
			char szQuery[256]; int iTime = GetTime();
			FormatEx(szQuery, sizeof(szQuery), "INSERT INTO `countries` (`name`, `joined`, `lastvisit`) VALUES ('%s', %i, %i);", CountryName[iClient], iTime, iTime);
			DBG_SQL_Query(szQuery)
			g_hDatabase.Query(SQL_Callback_CreateCountry, szQuery, CreateAuthClientDataPack(iClient, iType));
		}
		else
		{
			ClientData[iClient][CLIENT_COUNTRY_ID] = GetArrayAttribute(ARRAY_COUNTRIES, ARRAY_DATA_ID, iId);
			GetClientArray(iClient, ARRAY_COUNTRIES);
			CheckClientLoading(iClient, iType);
		}

	}
}

public void SQL_Callback_CreateCountry(Database hDatabase, DBResultSet hResults, const char[] szError, DataPack hPack)
{
	DBG_SQL_Response("SQL_Callback_CreateCountry")
	int iClient, iType;
	bool bValid = ReadAuthClientDataPack(hPack, iClient, iType);
	if(szError[0])
	{
		LogError("SQL_Callback_CreateCountry: %s", szError);
		return;
	}

	if(!bValid)
	{
		return;
	}
	if(CountryName[iClient][0])
	{
		ClientData[iClient][CLIENT_COUNTRY_ID] = hResults.InsertId;
		GetClientArray(iClient, ARRAY_COUNTRIES);
	}
	CheckClientLoading(iClient, iType);
}


void OnClientLoaded(int iClient)
{
	DebugMessage("OnClientLoaded: %N", iClient)
	ClientData[iClient][CLIENT_LOADED] = 1;
	delete Queries[iClient][0];
	delete Queries[iClient][1];
	Queries[iClient][0] = new ArrayList(ByteCountToCells(16));
	Queries[iClient][1] = new ArrayList(ByteCountToCells(16));
	
	Forward_OnClientLoaded(iClient);
}

void SaveClientsData(bool bAll = true)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			SaveClientData(i, bAll);
		}
	}
}

void SaveClientData(int iClient, bool bAll = true)
{
	DebugMessage("SaveClientData: %N", iClient)
	
	if(!ClientData[iClient][CLIENT_LOADED])
		return;
	
	char szQuery[512];
	FormatEx(szQuery, sizeof(szQuery), "UPDATE `players` SET `points` = %i WHERE `id` = %i;", ClientData[iClient][CLIENT_POINTS], ClientData[iClient][CLIENT_ID]);
	DBG_SQL_Query(szQuery)
	g_hDatabase.Query(SQL_Callback_CheckError, szQuery);
	
	for(int i; i < Modules; i++)
	{
		Format(szQuery, 256, "UPDATE `players` SET `%s` = %i WHERE `id` = %i", Module[i], ClientModuleValue[iClient][i], ClientData[iClient][CLIENT_ID]);
		DBG_SQL_Query(szQuery)
		g_hDatabase.Query(SQL_Callback_CheckError, szQuery);
	}
	
	for(int j; j < 2; j++)
	{
		if(!bAll && j == 1)
			break;
		
		int iLength = Queries[iClient][j].Length;
		
		for(int i; i < iLength; i += QUERY_SIZE)
		{
			int	ClanID		= Queries[iClient][j].Get(QUERY_CLAN_ID), 
				iCountryID	= Queries[iClient][j].Get(i + QUERY_COUNTRY_ID), 
				iMapID		= Queries[iClient][j].Get(i + QUERY_MAP_ID), 
				iModuleID	= Queries[iClient][j].Get(i + QUERY_MODULE_ID), 
				iStage		= Queries[iClient][j].Get(i + QUERY_STAGE), 
				iPoints		= Queries[iClient][j].Get(i + QUERY_POINTS), 
				iValue		= Queries[iClient][j].Get(i + QUERY_VALUE),
				iZombies	= Queries[iClient][j].Get(i + QUERY_ZOMBIES),
				iTime		= Queries[iClient][j].Get(i + QUERY_TIME);
			
			
			FormatEx(szQuery, 512, "INSERT INTO `client_account` (`player_id`, `clan_id`, `country_id`, `map_id`, `module_id`, `stage`, `points`, `value`, `zombies`, `time`) VALUES (%i, %i, %i, %i, %i, %i, %i, %i, %i, %i);", ClientData[iClient][CLIENT_ID], ClanID, iCountryID, iMapID, iModuleID, iStage, iPoints, iValue, iZombies, iTime);
			DBG_SQL_Query(szQuery)
			g_hDatabase.Query(SQL_Callback_CheckError, szQuery);
		}
		
		Queries[iClient][j].Clear();
	}
}

void LoadClientData(int iClient)
{
	DebugMessage("LoadClientData: %N", iClient)
	if(IsFakeClient(iClient))
		return;
	
	ResetClientData(iClient);
	ClientData[iClient][CLIENT_ID] = GetSteamAccountID(iClient)
	
	if(!ClientData[iClient][CLIENT_ID])
		return;
	
	char szQuery[256];
	FormatEx(szQuery, sizeof(szQuery), "SELECT * FROM `players` WHERE `id` = %i;", ClientData[iClient][CLIENT_ID]);
	DBG_SQL_Query(szQuery)
	g_hDatabase.Query(SQL_Callback_SelectClient, szQuery, GetClientUserId(iClient));
}

void ResetClientData(int iClient)
{
	DebugMessage("ResetClientData: %N", iClient)
	ClanName[iClient][0] = 
	CountryName[iClient][0] = 0;
	
	ClientData[iClient][CLIENT_ID] =
	ClientData[iClient][CLIENT_TEAM] =
	ClientData[iClient][CLIENT_FSPAWN] =
	ClientData[iClient][CLIENT_POINTS] =
	ClientData[iClient][CLIENT_LOADED] = 
	ClientData[iClient][CLIENT_TEAM_TIME] = 0;
	
	ClientData[iClient][CLIENT_PLACE] = 
	ClientData[iClient][CLIENT_CLAN_ID] =
	ClientData[iClient][CLIENT_COUNTRY_ID] =
	ClientData[iClient][CLIENT_ARRAY_CLAN_ID] =
	ClientData[iClient][CLIENT_ARRAY_COUNTRY_ID] = -1;
	
	
	for(int i; i < Modules; i++)
	{
		ClientModuleValue[iClient][i] = 0;
	}
}

bool IsClientLoaded(int iClient)
{
	return 		(ClientData[iClient][CLIENT_ID] && 
				ClientData[iClient][CLIENT_PLACE] != -1 && 
				ClientData[iClient][CLIENT_CLAN_ID] != -1 && 
				ClientData[iClient][CLIENT_COUNTRY_ID] != -1);
}

bool CheckClientLoading(int iClient, int iType)
{
	if(!ClientData[iClient][CLIENT_LOADED] && iType == 0 && IsClientLoaded(iClient))
		OnClientLoaded(iClient);
}

int GetClientClanID(int iClient)
{
	char sClanID[32];
	GetClientInfo(iClient, "cl_clanid", sClanID, sizeof(sClanID));
	
	return StringToInt(sClanID);
}

DataPack CreateAuthClientDataPack(int iClient, int iType)
{
	DataPack hPack = new DataPack();
	hPack.WriteCell(GetClientUserId(iClient));
	hPack.WriteCell(iType);
	
	return hPack;
	
}

bool ReadAuthClientDataPack(DataPack hPack, int& iClient, int& iType)
{
	hPack.Reset();
	iClient = GetClientOfUserId(hPack.ReadCell()), 
	iType = hPack.ReadCell();
	delete hPack;
	
	return (iClient && IsClientInGame(iClient));
}