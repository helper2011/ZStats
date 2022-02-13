void CreateConsoleCommands()
{
	RegConsoleCmd("sm_zstats", Command_ZStats);
}

public Action Command_ZStats(int iClient, int iArgs)
{
	if(Cmd_IsValidClient(iClient))
	{
		ZStatsMenu(iClient);
	}
	
	return Plugin_Handled;
}

bool Cmd_IsValidClient(int iClient)
{
	return iClient && !IsFakeClient(iClient);
}