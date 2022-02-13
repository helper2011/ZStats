public int Native_GetDatabase(Handle plugin, int numParams)
{
	return view_as<int>(CloneHandle(g_hDatabase, plugin));
}

public int Native_PrintToChat(Handle plugin, int numParams)
{
	char szBuffer[256];
	int iClient = GetNativeCell(1);
	SetGlobalTransTarget(iClient);
	FormatNativeString(0, 2, 3, 256, _, szBuffer);
	PrintToChat2(iClient, szBuffer);
}

public int Native_PrintToChatAll(Handle plugin, int numParams)
{
	char szBuffer[256];
	for(int i = 1;i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		SetGlobalTransTarget(i);
		FormatNativeString(0, 1, 2, 256, _, szBuffer);
		PrintToChat2(i, szBuffer);
	}
}


public int Native_IsDBLoaded(Handle plugin, int numParams)
{
	return view_as<int>(IsLoaded[LOAD_DATABASE]);
}

public int Native_IsMapLoaded(Handle plugin, int numParams)
{
	return view_as<int>(IsLoaded[LOAD_MAP]);
}

public int Native_IsModulesLoaded(Handle plugin, int numParams)
{
	return view_as<int>(IsLoaded[LOAD_MODULES]);
}

public int Native_GetModuleIdByName(Handle plugin, int numParams)
{
	char szBuffer[64];
	GetNativeString(1, szBuffer, 64);
	return GetModuleIdByName(szBuffer);

}

public int Native_GetModuleIndexByName(Handle plugin, int numParams)
{
	char szBuffer[64];
	GetNativeString(1, szBuffer, 64);
	return GetModuleIndexByName(szBuffer);

}

public int Native_GetModuleIndex(Handle plugin, int numParams)
{
	return GetModuleIndex(GetNativeCell(1));
}

public int Native_GetModuleData(Handle plugin, int numParams)
{
	int iModuleId = GetModuleIndex(GetNativeCell(1));
	
	return iModuleId != -1 ? ModuleData[iModuleId][GetNativeCell(2)]:-1;
}

public int Native_GetClientData(Handle plugin, int numParams)
{
	return ClientData[GetNativeCell(1)][GetNativeCell(2)];
}



public int Native_GiveClientPoints(Handle plugin, int numParams)
{
	char szBuffer[256];
	GetNativeString(3, szBuffer, 256);
	return GiveClientPoints(GetNativeCell(1), GetNativeCell(2), szBuffer, GetNativeCell(4), GetNativeCell(5));
}

public int Native_GiveMapPoints(Handle plugin, int numParams)
{
	return GiveMapPoints(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
}