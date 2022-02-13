void ZStatsMenu(int iClient, int iClient2 = 0)
{
	if(!ClientData[iClient][CLIENT_LOADED])
		return;
	
	if(!iClient2)
		iClient2 = iClient;
	
	char szBuffer[1024];
	Menu hMenu = new Menu(ZStatsH);
	if(ClientData[iClient][CLIENT_ARRAY_CLAN_ID] != -1)
	{
		FormatEx(szBuffer, 1024, "%T\n ", "ZStats with clan menu title", iClient2, ArrayName[ARRAY_CLANS][ClientData[iClient][CLIENT_ARRAY_CLAN_ID]], iClient, ClientData[iClient][CLIENT_POINTS]);
	}
	else
	{
		FormatEx(szBuffer, 1024, "%T\n ", "ZStats menu title", iClient2, iClient, ClientData[iClient][CLIENT_POINTS]);
	}
	
	int iCount;
	for(int i; i < Modules; i++)
	{
		if(!ModuleData[i][MODULE_SHOWSTATS] || !ClientModuleValue[iClient][i])
			continue;
		
		char szBuffer2[256];
		
		FormatEx(szBuffer2, 256, "%s 3", Module[i]);
		Format(szBuffer, 1024, "%s\n· %T", szBuffer, szBuffer2, iClient2, ClientModuleValue[iClient][i]);
		iCount++;
	}
	if(iCount)
	{
		Format(szBuffer, 1024, "%s\n ", szBuffer);
	}
	hMenu.SetTitle(szBuffer);
	int style = (iClient == iClient2) ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED;
	AddMenuItem2(hMenu, style, "", "%T", "Players", iClient2);
	AddMenuItem2(hMenu, style, "", "%T", "Clans", iClient2);
	AddMenuItem2(hMenu, style, "", "%T", "Countries", iClient2);
	hMenu.ExitBackButton = (iClient != iClient2);
	hMenu.Display(iClient2, 0);
	
}

public int ZStatsH(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	if(action == MenuAction_End)
	{
		delete hMenu;
	}
	else if(action == MenuAction_Cancel)
	{
		if(iItem == MenuCancel_ExitBack)
		{
			PlayersListMenu(iClient);
		}
	}
	else if(action == MenuAction_Select)
	{
		if(iItem == 0)
		{
			PlayersListMenu(iClient);
		}
		else if(iItem == 1)
		{
			ClansListMenu(iClient);
		}
		else if(iItem == 2)
		{
			CountriesListMenu(iClient);
		}
	}
}

void PlayersListMenu(int iClient)
{
	char szBuffer[256], szBuffer2[16]; int iCount;
	Menu hMenu = new Menu(PlayersListH);
	
	hMenu.SetTitle("%T\n ", "Players list menu title", iClient, Clients);

	AddMenuItem2(hMenu, ITEMDRAW_DEFAULT, "top", "[%T]\n ", "Top Players", iClient);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && ClientData[i][CLIENT_LOADED])
		{
			if(iCount > 5 && iCount % 6 == 0)
			{
				AddMenuItem2(hMenu, ITEMDRAW_DEFAULT, "top", "[%T]\n ", "Top Players", iClient);
			}
			GetClientName(i, szBuffer, 256);
			IntToString(GetClientUserId(i), szBuffer2, 16);
			hMenu.AddItem(szBuffer2, szBuffer);
			iCount++;
		}
	}
	
	
	hMenu.ExitBackButton = true;
	hMenu.Display(iClient, 0);
}

public int PlayersListH(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	if(action == MenuAction_End)
	{
		delete hMenu;
	}
	else if(action == MenuAction_Cancel)
	{
		if(iItem == MenuCancel_ExitBack)
		{
			ZStatsMenu(iClient);
		}
	}
	else if(action == MenuAction_Select)
	{
		char szBuffer[16];
		hMenu.GetItem(iItem, szBuffer, 16);
		if(!strcmp(szBuffer, "top", false))
		{
			DisplayClientTopMenu(iClient);
		}
		else
		{
			int iTarget = GetClientOfUserId(StringToInt(szBuffer));
		
			if(iTarget > 0 && IsClientInGame(iTarget) && ClientData[iTarget][CLIENT_LOADED])
			{
				ZStatsMenu(iTarget, iClient);
			}
			else
			{
				PrintToChat2(iClient, "%t", "Client is unavailbale");
				PlayersListMenu(iClient);
			}
		}

	}
}

void ClansListMenu(int iClient)
{
	int iCount;
	Menu hMenu = new Menu(ClansListMenuH);
	
	hMenu.SetTitle("%T\n ", "Clans list menu title", iClient, ArrayCount[ARRAY_CLANS]);

	AddMenuItem2(hMenu, ITEMDRAW_DEFAULT, "top", "[%T]\n ", "Top Clans", iClient);
	for(int i; i < MAXPLAYERS; i++)
	{
		if(ArrayData[ARRAY_CLANS][ARRAY_DATA_LOADED][i])
		{
			if(iCount > 5 && iCount % 6 == 0)
			{
				AddMenuItem2(hMenu, ITEMDRAW_DEFAULT, "top", "[%T]\n ", "Top Clans", iClient);
			}
			char szBuffer[64];
			FormatEx(szBuffer, 64, "%i_%i", i, ArrayData[ARRAY_CLANS][ARRAY_DATA_ID][i]);
			AddMenuItem2(hMenu, ITEMDRAW_DEFAULT, szBuffer, ArrayName[ARRAY_CLANS][i]);
			iCount++;
		}
	}
	
	
	hMenu.ExitBackButton = true;
	hMenu.Display(iClient, 0);
}

public int ClansListMenuH(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	if(action == MenuAction_End)
	{
		delete hMenu;
	}
	else if(action == MenuAction_Cancel)
	{
		if(iItem == MenuCancel_ExitBack)
		{
			ZStatsMenu(iClient);
		}
	}
	else if(action == MenuAction_Select)
	{
		char szBuffer[64];
		char szBuffer2[2][32];
		hMenu.GetItem(iItem, szBuffer, 16);
		if(!strcmp(szBuffer, "top", false))
		{
			DisplayClientTopMenu(iClient, TOP_CLANS);
		}
		else if(ExplodeString(szBuffer, "_", szBuffer2, 2, 32) > 1)
		{
			int iClanId = StringToInt(szBuffer2[0]);
			if(ArrayData[ARRAY_CLANS][ARRAY_DATA_ID][iClanId] == StringToInt(szBuffer2[1]) && ArrayData[ARRAY_CLANS][ARRAY_DATA_LOADED][iClanId])
			{
				ClanInfoMenu(iClient, iClanId);
			}
			else
			{
				PrintToChat2(iClient, "%t", "Clan is unavailbale");
			}
		}

	}
}

void ClanInfoMenu(int iClient, int iClanId)
{
	char szBuffer[1024];
	Menu hMenu = new Menu(ClanInfoMenuH);
	FormatEx(szBuffer, 1024, "%T\n ", "Clan info menu title", iClient, ArrayName[ARRAY_CLANS][iClanId], ArrayData[ARRAY_CLANS][ARRAY_DATA_POINTS][iClanId], ArrayData[ARRAY_CLANS][ARRAY_DATA_CLIENTS][iClanId]);
	int iCount;
	for(int i; i < Modules; i++)
	{
		if(!ModuleData[i][MODULE_SHOWSTATS] || !ArrayModule[ARRAY_CLANS][i][iClanId])
			continue;
		
		char szBuffer2[256];
		
		FormatEx(szBuffer2, 256, "%s 3", Module[i]);
		Format(szBuffer, 1024, "%s\n· %T", szBuffer, szBuffer2, iClient, ArrayModule[ARRAY_CLANS][i][iClanId]);
		iCount++;
	}
	if(iCount)
	{
		Format(szBuffer, 1024, "%s\n ", szBuffer);
	}
	AddMenuItem2(hMenu, _, "", "%T", "Back", iClient);
	hMenu.SetTitle(szBuffer);
	hMenu.Display(iClient, 0);
	
}

public int ClanInfoMenuH(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	if(action == MenuAction_End)
	{
		delete hMenu;
	}
	else if(action == MenuAction_Select)
	{
		ClansListMenu(iClient);
	}
}

void CountriesListMenu(int iClient)
{
	int iCount;
	Menu hMenu = new Menu(CountriesListMenuH);
	
	hMenu.SetTitle("%T\n ", "Countries list menu title", iClient, ArrayCount[ARRAY_COUNTRIES]);

	AddMenuItem2(hMenu, ITEMDRAW_DEFAULT, "top", "[%T]\n ", "Top Countries", iClient);
	for(int i; i < MAXPLAYERS; i++)
	{
		if(ArrayData[ARRAY_COUNTRIES][ARRAY_DATA_LOADED][i])
		{
			if(iCount > 5 && iCount % 6 == 0)
			{
				AddMenuItem2(hMenu, ITEMDRAW_DEFAULT, "top", "[%T]\n ", "Top Countries", iClient);
			}
			char szBuffer[64];
			FormatEx(szBuffer, 64, "%i_%i", i, ArrayData[ARRAY_COUNTRIES][ARRAY_DATA_ID][i]);
			AddMenuItem2(hMenu, ITEMDRAW_DEFAULT, szBuffer, ArrayName[ARRAY_COUNTRIES][i]);
			iCount++;
		}
	}
	
	
	hMenu.ExitBackButton = true;
	hMenu.Display(iClient, 0);
}

public int CountriesListMenuH(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	if(action == MenuAction_End)
	{
		delete hMenu;
	}
	else if(action == MenuAction_Cancel)
	{
		if(iItem == MenuCancel_ExitBack)
		{
			ZStatsMenu(iClient);
		}
	}
	else if(action == MenuAction_Select)
	{
		char szBuffer[64];
		char szBuffer2[2][32];
		hMenu.GetItem(iItem, szBuffer, 16);
		if(!strcmp(szBuffer, "top", false))
		{
			DisplayClientTopMenu(iClient, TOP_COUNTRIES);
		}
		else if(ExplodeString(szBuffer, "_", szBuffer2, 2, 32) > 1)
		{
			int iCountry = StringToInt(szBuffer2[0]);
			if(ArrayData[ARRAY_COUNTRIES][ARRAY_DATA_ID][iCountry] == StringToInt(szBuffer2[1]) && ArrayData[ARRAY_COUNTRIES][ARRAY_DATA_LOADED][iCountry])
			{
				CountryInfoMenu(iClient, iCountry);
			}
			else
			{
				PrintToChat2(iClient, "%t", "Country is unavailbale");
			}
		}

	}
}

void CountryInfoMenu(int iClient, int iId)
{
	char szBuffer[1024];
	Menu hMenu = new Menu(CountryInfoMenuH);
	FormatEx(szBuffer, 1024, "%T\n ", "Country info menu title", iClient, ArrayName[ARRAY_COUNTRIES][iId], ArrayData[ARRAY_COUNTRIES][ARRAY_DATA_POINTS][iId], ArrayData[ARRAY_COUNTRIES][ARRAY_DATA_CLIENTS][iId]);
	int iCount;
	for(int i; i < Modules; i++)
	{
		if(!ModuleData[i][MODULE_SHOWSTATS] || !ArrayModule[ARRAY_COUNTRIES][i][iId])
			continue;
		
		char szBuffer2[256];
		
		FormatEx(szBuffer2, 256, "%s 3", Module[i]);
		Format(szBuffer, 1024, "%s\n· %T", szBuffer, szBuffer2, iClient, ArrayModule[ARRAY_COUNTRIES][i][iId]);
		iCount++;
	}
	if(iCount)
	{
		Format(szBuffer, 1024, "%s\n ", szBuffer);
	}
	AddMenuItem2(hMenu, _, "", "%T", "Back", iClient);
	hMenu.SetTitle(szBuffer);
	hMenu.Display(iClient, 0);
	
}

public int CountryInfoMenuH(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	if(action == MenuAction_End)
	{
		delete hMenu;
	}
	else if(action == MenuAction_Select)
	{
		CountriesListMenu(iClient);
	}
}



void AddMenuItem2(Menu hMenu, int style = ITEMDRAW_DEFAULT, const char[] buffer, const char[] format, any ...)
{
	int iLen = strlen(format) + 255;
	char[] szBuffer = new char[iLen];
	VFormat(szBuffer, iLen, format, 5);
	
	hMenu.AddItem(buffer, szBuffer, style);
}