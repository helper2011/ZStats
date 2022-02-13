enum
{
	TOP_PLAYERS,
	TOP_CLANS,
	TOP_COUNTRIES,
	TOP_TOTAL
}

const int TOP_SIZE = 25;

Menu TopMenu[TOP_TOTAL][MAX_MODULES + 1];

void DisplayClientTopMenu(int iClient, int iTop = TOP_PLAYERS, int iId = 0)
{
	if(TopMenu[iTop][iId])
	{
		TopMenu[iTop][iId].Display(iClient, 0);
	}
}

void BuildTopMenu(int iTop = -1, bool bTotal = true)
{
	if(!IsLoaded[LOAD_DATABASE])
		return;
	
	if(iTop == -1)
	{
		BuildTopMenu(TOP_PLAYERS, bTotal);
		BuildTopMenu(TOP_CLANS, bTotal);
		BuildTopMenu(TOP_COUNTRIES, bTotal);
		return;
	}
	
	char szBuffer[256], szBuffer2[32];
	strcopy(szBuffer2, 32, iTop == TOP_PLAYERS ? "players":iTop == TOP_CLANS ? "clans":"countries");
	
	if(bTotal)
	{
		DataPack hPack = new DataPack();
		hPack.WriteCell(iTop);
		hPack.WriteCell(0);
		delete TopMenu[iTop][0];
		FormatEx(szBuffer, 256, "SELECT `name`, `points` FROM `%s` ORDER BY `points` DESC LIMIT %i", szBuffer2, TOP_SIZE);
		g_hDatabase.Query(SQL_Callback_GetTop, szBuffer, hPack);
		DBG_SQL_Query(szBuffer)
	}
	else
	{
		for(int i; i < Modules; i++)
		{
			delete TopMenu[iTop][i + 1];
			if(ModuleData[i][MODULE_SHOWTOP])
			{
				FormatEx(szBuffer, 256, "SELECT `name`, `%s` FROM `%s` ORDER BY `%s` DESC LIMIT %i", Module[i], szBuffer2, Module[i], TOP_SIZE);
				DataPack hPack = new DataPack();
				hPack.WriteCell(iTop);
				hPack.WriteCell(i + 1);
				DBG_SQL_Query(szBuffer)
				g_hDatabase.Query(SQL_Callback_GetTop, szBuffer, hPack);
				
			}
		}
	}
}

public void SQL_Callback_GetTop(Database hDatabase, DBResultSet hResults, const char[] sError, DataPack hPack) 
{
	DBG_SQL_Response("SQL_Callback_GetTop")
	hPack.Reset();
	int iTop = hPack.ReadCell(), iId = hPack.ReadCell();
	delete hPack;
	if(sError[0])
	{
		LogError("SQL_Callback_GetTop: %s", sError);
		return;
	}
	
	int iCount = hResults.RowCount;
	if (iCount > TOP_SIZE)
	{
		iCount = TOP_SIZE;
	}
	else if (!iCount)
	{
		return;
	}
	char szBuffer[256];
	TopMenu[iTop][iId] = new Menu(TopMenuH, MenuAction_Cancel|MenuAction_Select|MenuAction_Display|MenuAction_DisplayItem);
	TopMenu[iTop][iId].SetTitle("%i_%i_%i", iTop, iId, iCount);
	TopMenu[iTop][iId].ExitBackButton = true;
	AddMenuItem2(TopMenu[iTop][iId], ITEMDRAW_DEFAULT, "", "Change top");
	for(int i = 1; i <= iCount; i++)
	{
		hResults.FetchRow();
		hResults.FetchString(0, szBuffer, 256);
		Format(szBuffer, 256, "#%i. [%i] %s", i, hResults.FetchInt(1), szBuffer);
		TopMenu[iTop][iId].AddItem("", szBuffer, ITEMDRAW_DISABLED);
		
	}
}

public int TopMenuH(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			char szTitle[256], szBuffer[3][16];
			hMenu.GetTitle(szTitle, 256);
			if(ExplodeString(szTitle, "_", szBuffer, 3, 16) > 2)
			{
				SetGlobalTransTarget(iClient);
				int iTop = StringToInt(szBuffer[0]), iId = StringToInt(szBuffer[1]) - 1;
				FormatEx(szTitle, 256, "Top %s menu title", iTop == TOP_PLAYERS ? "Players":iTop == TOP_CLANS ? "Clans":"Countries");
				Format(szTitle, 256, "%t", szTitle, StringToInt(szBuffer[2]), (iId != -1 ? Module[iId]:"Common"));
				(view_as<Panel>(iItem)).SetTitle(szTitle);
			}
		}
		case MenuAction_DisplayItem:
		{
			if(iItem == 0)
			{
				char szBuffer[256];
				hMenu.GetItem(iItem, "", 0, _, szBuffer, 256);
				Format(szBuffer, 256, "[%T]\n ", szBuffer, iClient);
				return RedrawMenuItem(szBuffer);
			}

		}
		case MenuAction_Select:
		{
			char szTitle[256], szBuffer[3][16];
			hMenu.GetTitle(szTitle, 256);
			if(ExplodeString(szTitle, "_", szBuffer, 3, 16) > 2)
			{
				if(iItem == 0)
				{
					int iTop = StringToInt(szBuffer[0]), iCurrentTop = StringToInt(szBuffer[1]), iNextTop;
					
					for(int i = iCurrentTop + 1; i < MAX_MODULES + 1; i++)
					{
						if(TopMenu[iTop][i])
						{
							iNextTop = i;
							break;
						}
					}
					DisplayClientTopMenu(iClient, iTop, iNextTop);
				}
			}

		}
		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack)
			{
				ZStatsMenu(iClient);
			}
		}
	}
	return 0;
}