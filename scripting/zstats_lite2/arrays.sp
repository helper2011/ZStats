

int 	
	ArrayData[ARRAY_TOTAL][ARRAY_DATA_TOTAL][MAXPLAYERS],
	ArrayCount[ARRAY_TOTAL],
	ArrayModule[ARRAY_TOTAL][MAX_MODULES][MAXPLAYERS];

char
	ArrayName[ARRAY_TOTAL][MAXPLAYERS][64];
	
static const char ArrayTitle[ARRAY_TOTAL][32] = {"clans", "countries"};
static const int ArrayRequiredValue[ARRAY_TOTAL] = {1, 0};
	

bool GetClientArray(int iClient, int iArray = -1)
{
	DebugMessage("GetClientArray: %N", iClient)
	//PrintToServer("GetClientArray");
	int iCData = Array_GetClientData(iArray), iValue = Array_GetClientValue(iArray);
	if(ClientData[iClient][iValue] <= ArrayRequiredValue[iArray])
	{
		return false;
	}
	//PrintToServer("GetClientArray 2");
	
	if(ClientData[iClient][iCData] != -1)
	{
		if(ClientData[iClient][iValue] == ArrayData[iArray][ARRAY_DATA_ID][ClientData[iClient][iCData]])
		{
			return false;
		}
		DropClientArray(iClient, iArray);
	}
	//PrintToServer("GetClientArray 3 (%i)", ClientData[iClient][iValue]);
	ClientData[iClient][iCData] = PushValueEx(ArrayData[iArray][ARRAY_DATA_ID], ClientData[iClient][iValue]);
	ArrayData[iArray][ARRAY_DATA_CLIENTS][ClientData[iClient][iCData]]++;
	strcopy(ArrayName[iArray][ClientData[iClient][iCData]], 64, iArray == ARRAY_CLANS ? ClanName[iClient]:CountryName[iClient]);
	GetArrayData(iArray, ClientData[iClient][iCData]);
	return true;
}


bool DropClientArray(int iClient, int iArray = -1)
{
	DebugMessage("DropClientArray: %N", iClient)
	if(iArray == -1)
	{
		for(int i; i < ARRAY_TOTAL; i++)
		{
			DropClientArray(iClient, i);
		}
		return false;
	}
	int iCData = Array_GetClientData(iArray);
	
	if(ClientData[iClient][iCData] == -1)
	{
		return false;
	}
	int iId = ClientData[iClient][iCData];
	ClientData[iClient][iCData] = -1;
	
	if(--ArrayData[iArray][ARRAY_DATA_CLIENTS][iId] <= 0)
	{
		SaveArrayData(iArray, iId);
		ResetArrayData(iArray, iId);
	}
	ClientData[iClient][iCData] = -1;
	return true;
}

void GetArrayCount(int iArray = -1)
{
	if(iArray == -1)
	{
		for(int i; i < ARRAY_TOTAL; i++)
		{
			GetArrayCount(i);
		}
		return;
	}
	
	if(!IsLoaded[LOAD_DATABASE])
		return;
	
	char szBuffer[256];
	FormatEx(szBuffer, 256, "SELECT COUNT(`id`) FROM `%s`", ArrayTitle[iArray]);
	DBG_SQL_Query(szBuffer)
	g_hDatabase.Query(SQL_Callback_GetArrayCount, szBuffer, iArray);
}

public void SQL_Callback_GetArrayCount(Database hDatabase, DBResultSet hResults, const char[] sError, int iArray) 
{
	DBG_SQL_Response("SQL_Callback_GetArrayCount")
	if(sError[0])
	{
		LogError("SQL_Callback_GetArrayCount: %s", sError);
		return;
	}
	
	if(hResults.FetchRow())
	{
		ArrayCount[iArray] = hResults.FetchInt(0);
		
	}
}

bool GetArrayData(int iArray, int iId)
{
	DebugMessage("GetArrayData")
	if(!IsLoaded[LOAD_DATABASE] || iId == -1 || ArrayData[iArray][ARRAY_DATA_LOADED][iId])
	{
		return false;
	}
	//PrintToServer("GetArrayData (%i %i)", ArrayData[iArray][ARRAY_DATA_ID][iId], iId);
	char szQuery[256];
	g_hDatabase.Format(szQuery, 256, "SELECT * FROM `%s` WHERE `id` = %i;", ArrayTitle[iArray], ArrayData[iArray][ARRAY_DATA_ID][iId]);
	DataPack hPack = new DataPack();
	hPack.WriteCell(iArray);
	hPack.WriteCell(iId);
	hPack.WriteCell(ArrayData[iArray][ARRAY_DATA_ID][iId]);
	DBG_SQL_Query(szQuery)
	g_hDatabase.Query(SQL_Callback_SelectArray, szQuery, hPack);
	return true;
}

public void SQL_Callback_SelectArray(Database hDatabase, DBResultSet hResults, const char[] sError, int iData)
{
	DBG_SQL_Response("SQL_Callback_SelectArray")
	DataPack hPack = view_as<DataPack>(iData);
	hPack.Reset();
	int iArray = hPack.ReadCell(), iId = hPack.ReadCell(), iClanId = hPack.ReadCell();
	delete hPack;
	if(sError[0])
	{
		LogError("SQL_Callback_SelectArray: %s", sError);
		return;
	}
	//PrintToServer("SQL_Callback_SelectArray2 (%i %i %i)", ArrayData[iArray][ARRAY_DATA_ID][iId], iClanId, ArrayData[iArray][ARRAY_DATA_LOADED][iId]);

	if(ArrayData[iArray][ARRAY_DATA_ID][iId] == iClanId && !ArrayData[iArray][ARRAY_DATA_LOADED][iId] && hResults.FetchRow())
	{
		//PrintToServer("SQL_Callback_SelectArray3");
		char szQuery[256];
		FormatEx(szQuery, 256, "UPDATE `%s` SET `lastvisit` = %i WHERE `id` = %i;", ArrayTitle[iArray], GetTime(), ArrayData[iArray][ARRAY_DATA_ID][iId]);
		DBG_SQL_Query(szQuery)
		g_hDatabase.Query(SQL_Callback_CheckError, szQuery);
		
		ArrayData[iArray][ARRAY_DATA_POINTS][iId] = hResults.FetchInt(4);
		int iColumn;
		for(int i; i < Modules; i++)
		{
			ArrayModule[iArray][i][iId] = hResults.FieldNameToNum(Module[i], iColumn) ? hResults.FetchInt(iColumn):0;
		}
		
		ArrayData[iArray][ARRAY_DATA_LOADED][iId] = 1;
	}
}

void SaveArrayDataAll(int iArray = -1)
{
	if(iArray == -1)
	{
		for(int i; i < ARRAY_TOTAL; i++)
		{
			SaveArrayDataAll(i);
		}
		return;
	}
	
	for(int i; i < MAXPLAYERS; i++)
	{
		SaveArrayData(iArray, i);
	}
}

void SaveArrayData(int iArray, int iId)
{
	DebugMessage("SaveArrayData (Array = %i, id = %i (load = %i), DB = %i, Require = %i", iArray, iId, ArrayData[iArray][ARRAY_DATA_LOADED][iId], view_as<int>(IsLoaded[LOAD_DATABASE]), ArrayRequiredValue[iArray])
	if(!IsLoaded[LOAD_DATABASE] || iId == -1 || ArrayData[iArray][ARRAY_DATA_ID][iId] <= ArrayRequiredValue[iArray] || !ArrayData[iArray][ARRAY_DATA_LOADED][iId])
	{
		return;
	}
	
	
	char szQuery[512];
	FormatEx(szQuery, sizeof(szQuery), "UPDATE `%s` SET `points` = %i WHERE `id` = %i;", ArrayTitle[iArray], ArrayData[iArray][ARRAY_DATA_POINTS][iId], ArrayData[iArray][ARRAY_DATA_ID][iId]);
	DBG_SQL_Query(szQuery)
	g_hDatabase.Query(SQL_Callback_CheckError, szQuery);
	
	for(int i; i < Modules; i++)
	{
		Format(szQuery, 256, "UPDATE `%s` SET `%s` = %i WHERE `id` = %i", ArrayTitle[iArray], Module[i], ArrayModule[iArray][i][iId], ArrayData[iArray][ARRAY_DATA_ID][iId]);
		DBG_SQL_Query(szQuery)
		g_hDatabase.Query(SQL_Callback_CheckError, szQuery);
	}

}

void ResetArrayDataAll(int iArray = -1)
{
	if(iArray == -1)
	{
		for(int i; i < ARRAY_TOTAL; i++)
		{
			ResetArrayDataAll(i);
		}
		return;
	}
	
	for(int i; i < MAXPLAYERS; i++)
	{
		ResetArrayData(iArray, i);
	}
}

void ResetClientArrayAll(int iArray = -1)
{
	if(iArray == -1)
	{
		for(int i; i < ARRAY_TOTAL; i++)
		{
			ResetClientArrayAll(i);
		}
		return;
	}

	
	for(int i = 1; i <= MaxClients; i++)
	{
		ResetClientArray(i, iArray);
	}
}

void ResetClientArray(int iClient, int iArray)
{
	ClientData[iClient][Array_GetClientData(iArray)] = -1;
}

void ResetArrayData(int iArray, int iId)
{
	DebugMessage("ResetArrayData")
	for(int i; i < ARRAY_DATA_TOTAL; i++)
	{
		ArrayData[iArray][i][iId] = 0;
	}
	for(int i; i < Modules; i++)
	{
		ArrayModule[iArray][i][iId] = 0;
	}

	ArrayName[iArray][iId][0] = 0;
}


int Array_GetClientValue(int iArray)
{
	switch(iArray)
	{
		case ARRAY_CLANS: 		return CLIENT_CLAN_ID;
		case ARRAY_COUNTRIES:	return CLIENT_COUNTRY_ID;
	}
	return -1;
}


int Array_GetClientData(int iArray)
{
	switch(iArray)
	{
		case ARRAY_CLANS: 		return CLIENT_ARRAY_CLAN_ID;
		case ARRAY_COUNTRIES:	return CLIENT_ARRAY_COUNTRY_ID;
	}
	return -1;
}


int GetArrayAttribute(int iArray, int iAttribute, int iId)
{
	return ArrayData[iArray][iAttribute][iId];
}

int Array_GetArrayByName(int iArray, const char[] name)
{
	for(int i; i < MAXPLAYERS; i++)
	{
		if(ArrayName[iArray][i][0] && !strcmp(name, ArrayName[iArray][i], false))
		{
			return i;
		}
	}
	return -1;
}

void AccountClientArray(int iClient, int iArray, int iIndex, int iPoints, int iValue)
{
	int iCData = Array_GetClientData(iArray);
	if(ClientData[iClient][iCData] != -1)
	{
		ArrayData[iArray][ARRAY_DATA_POINTS][ClientData[iClient][iCData]] += iPoints;
		ArrayModule[iArray][iIndex][ClientData[iClient][iCData]] += iValue;
	}
}

stock int FindValue(int[] array, int value)
{
	for(int i; i < MAXPLAYERS; i++)
	{
		if(array[i] == value)
		{
			return i;
		}
	}
	
	return -1;
}

stock int PushValue(int[] array, int value)
{
	for(int i; i < MAXPLAYERS; i++)
	{
		if(!array[i])
		{
			//PrintToServer("Pushing %i (index = %i)", value, i);
			array[i] = value;
			return i;
		}
	}
	
	return -1;
}

stock int PushValueEx(int[] array, int value)
{
	int iIndex = FindValue(array, value);
	return iIndex == -1 ? PushValue(array, value):iIndex;
}

