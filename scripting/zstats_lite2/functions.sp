int GiveClientPoints(int iClient, int iPoints, const char[] message, int iIndex, int iValue = 1)
{
	if(iIndex == -1)
		return -1;
		
	DebugMessage("GiveClientPoints: %N (Points = %i for %s [%i %i])", iClient, iPoints, message, iIndex, iValue)
	
	int iTime = GetTime(), iStage, ClanID;
	if(!ClientData[iClient][CLIENT_LOADED] || (ModuleData[iIndex][MODULE_MAX_REWARDS] > 0 && ClientModuleRewards[iClient][iIndex] >= ModuleData[iIndex][MODULE_MAX_REWARDS]) || ClientModuleCD[iClient][iIndex] > iTime || ModuleData[iIndex][MODULE_MIN_PLAYERS] > GetClientCount2())	return -1;
	
	if(ModuleData[iIndex][MODULE_POINTS] > 0)
		iPoints = ModuleData[iIndex][MODULE_POINTS];
	if(ModuleData[iIndex][MODULE_MAX_REWARDS] > 0)
		ClientModuleRewards[iClient][iIndex]++;
	if(ModuleData[iIndex][MODULE_COOLDOWN] > 0)
		ClientModuleCD[iClient][iIndex] = iTime + ModuleData[iIndex][MODULE_COOLDOWN];
	
	
	ClientModuleValue[iClient][iIndex] += iValue;
	
	if(!ModuleData[iIndex][MODULE_ACCOUNT_OPTIMIZE])
	{
		if(StageManager)
		{
			iStage = StageManager_GetCurrentStage();
		}
		
		ClanID = ClientData[iClient][CLIENT_CLAN_ID];
	}
		
	
	Forward_OnClientGotPoints(iClient, iPoints);
	
	ClientData[iClient][CLIENT_POINTS] += iPoints;
	AccountClientArray(iClient, ARRAY_CLANS, iIndex, iPoints, iValue);
	AccountClientArray(iClient, ARRAY_COUNTRIES, iIndex, iPoints, iValue);
	int iZombies = GetZombiesCount();
	if(message[0])
	{
		if(HLStatsXLogHelper)
		{
			char szBuffer[256];
			FormatEx(szBuffer, 256, "%s_%i_%i", message, iValue, iZombies);
			LH_LogPlayerEvent(iClient, "triggered", szBuffer);
		}
		if(iPoints)
			PrintToChat2(iClient, "%t", "Give client points", iClient, iPoints, ClientData[iClient][CLIENT_POINTS], message);
	}
	
	
	
	if(ModuleData[iIndex][MODULE_ACCOUNT] > 0 && ModuleData[iIndex][MODULE_ID] > 0 && iValue > 0 && MapID > 0)
	{
		int iArrayID;
		if(ModuleData[iIndex][MODULE_ACCOUNT_OPTIMIZE])
		{
			iArrayID = 1;
			if((iIndex = Queries_GetIndexByID(iClient, ModuleData[iIndex][MODULE_ID], 1)) != -1)
			{
				Queries[iClient][iArrayID].Set(iIndex + QUERY_POINTS, Queries[iClient][iArrayID].Get(iIndex + QUERY_POINTS) + iPoints);
				Queries[iClient][iArrayID].Set(iIndex + QUERY_VALUE, Queries[iClient][iArrayID].Get(iIndex + QUERY_VALUE) + iValue);
				Queries[iClient][iArrayID].Set(iIndex + QUERY_ZOMBIES, Queries[iClient][iArrayID].Get(iIndex + QUERY_ZOMBIES) + iZombies);

				Queries[iClient][iArrayID].Set(iIndex + QUERY_TIME, iTime);
				return iPoints;
			}

		}
		
		Queries[iClient][iArrayID].Push(ClanID);
		Queries[iClient][iArrayID].Push(ClientData[iClient][CLIENT_COUNTRY_ID]);
		Queries[iClient][iArrayID].Push(MapID);
		Queries[iClient][iArrayID].Push(ModuleData[iIndex][MODULE_ID]);
		Queries[iClient][iArrayID].Push(iStage);
		Queries[iClient][iArrayID].Push(iPoints);
		Queries[iClient][iArrayID].Push(iValue);
		Queries[iClient][iArrayID].Push(iZombies);
		Queries[iClient][iArrayID].Push(iTime);
	}
	
	return iPoints;
}

int GiveMapPoints(int iPoints, int iIndex, int iValue = 1)
{
	if(iIndex == -1)
		return -1;
	DebugMessage("GiveMapPoints: %i (Points = %i [%i %i])", MapID, iPoints, iIndex, iValue)
	int iTime = GetTime(), iStage;

	if(ModuleData[iIndex][MODULE_POINTS] > 0)
		iPoints = ModuleData[iIndex][MODULE_POINTS];
	
	MapModuleValue[iIndex] += iValue;
	
	if(StageManager)
	{
		iStage = StageManager_GetCurrentStage();
	}
	
	MapPoints += iPoints;
	
	if(ModuleData[iIndex][MODULE_ACCOUNT] && ModuleData[iIndex][MODULE_ID] > 0 && iValue > 0 && MapID > 0)
	{
		MapQueries.Push(ModuleData[iIndex][MODULE_ID]);
		MapQueries.Push(iStage);
		MapQueries.Push(iPoints);
		MapQueries.Push(iValue);
		MapQueries.Push(GetZombiesCount());
		MapQueries.Push(iTime);
	}
	
	return iPoints;
}

stock void StringToLowercase(char[] sText)
{
	int iLen = strlen(sText);
	for(int i; i < iLen; i++)
	{
		if(IsCharUpper(sText[i]))
		{
			sText[i] = CharToLower(sText[i]);
		}
	}
}

int GetModuleIdByName(const char[] module)
{
	for(int i; i < Modules; i++)
	{
		if(!strcmp(module, Module[i], false))
			return ModuleData[i][MODULE_ID];
	}
	
	return 0;
}

int GetModuleIndexByName(const char[] module)
{
	for(int i; i < Modules; i++)
	{
		if(!strcmp(module, Module[i], false))
			return i;
	}
	
	return -1;
}

int GetModuleIndex(int iModuleID)
{
	if(!iModuleID)
		return -1;
	
	for(int i; i < Modules; i++)
	{
		if(ModuleData[i][MODULE_ID] == iModuleID)
			return i;
	}
	
	return -1;
}

void PrintToChat2(int iClient, const char[] message, any ...)
{
	int iLen = strlen(message) + 255;
	char[] szBuffer = new char[iLen];
	SetGlobalTransTarget(iClient);
	VFormat(szBuffer, iLen, message, 3);
	SendMessage(iClient, szBuffer, iLen);
}


stock void PrintToChatAll2(const char[] message, any ...)
{
	int iLen = strlen(message) + 255;
	char[] szBuffer = new char[iLen];
	for(int i = 1;i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			SetGlobalTransTarget(i);
			VFormat(szBuffer, iLen, message, 2);
			SendMessage(i, szBuffer, iLen);
		}
	}
}


void SendMessage(int iClient, char[] szBuffer, int iSize)
{
	static int mode = -1;
	if(mode == -1)
	{
		mode = view_as<int>(GetUserMessageType() == UM_Protobuf);
	}
	SetGlobalTransTarget(iClient);
	Format(szBuffer, iSize, "%s%t %s%s", MAIN_COLOR, "Tag", COLOR_FIRST, szBuffer);
	ReplaceString(szBuffer, iSize, "{C}", "\x07");
	ReplaceString(szBuffer, iSize, "{MC}", MAIN_COLOR);
	ReplaceString(szBuffer, iSize, "{C1}", COLOR_FIRST);
	ReplaceString(szBuffer, iSize, "{C2}", COLOR_SECOND);

	
	Handle hMessage = StartMessageOne("SayText2", iClient, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	switch(mode)
	{
		case 0:
		{
			BfWrite bfWrite = UserMessageToBfWrite(hMessage);
			bfWrite.WriteByte(iClient);
			bfWrite.WriteByte(true);
			bfWrite.WriteString(szBuffer);
		}
		case 1:
		{
			Protobuf protoBuf = UserMessageToProtobuf(hMessage);
			protoBuf.SetInt("ent_idx", iClient);
			protoBuf.SetBool("chat", true);
			protoBuf.SetString("msg_name", szBuffer);
			for(int k;k < 4;k++)	
				protoBuf.AddString("params", "");
		}
	}
	EndMessage();
}

int Queries_GetIndexByID(int iClient, int iModuleID, int iArrayID)
{
	int iLength = Queries[iClient][iArrayID].Length;
	
	for(int i; i < iLength; i += QUERY_SIZE)
	{
		if(Queries[iClient][iArrayID].Get(i + QUERY_MODULE_ID) == iModuleID)
		{
			return i;
		}
	}
	
	return -1;
}

int GetClientCount2()
{
	int iTime = GetTime();
	static int LastTime, Count;
	
	if(iTime - LastTime <= 2)
		return Count;
	
	Count = 0;
	LastTime = iTime;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			Count++;
		}
	}
	
	return Count;
}

stock int GetZombiesCount()
{
	int iCount;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsPlayerAlive(i))
		{
			iCount++;
		}
	}
	
	return iCount;
}


