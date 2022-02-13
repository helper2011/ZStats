const int 
	MAX_MODULES = 25,
	MAX_MAP_MODULES = 15;

Database
	g_hDatabase;

bool
	SQLite,
	IsLoaded[LOAD_DATA_TOTAL];

int
	AverageClientPoints,
	Clients,
	//AverageAccountClientPoints,
	Modules, 
	ModuleData[MAX_MODULES][MODULE_DATA_TOTAL];
char
	Module[MAX_MODULES][64];
	
void ConnectToDatabase()
{
	DebugMessage("ConnectToDatabase")
	if(SQL_CheckConfig("zstats"))
	{
		Database.Connect(ConnectCallBack, "zstats", 0);
	}
	else
	{
		char szBuffer[256];
		g_hDatabase = SQLite_UseDatabase("zstats", szBuffer, 256);
		ConnectCallBack(g_hDatabase, szBuffer, 1);
	}
}

public void ConnectCallBack(Database hDatabase, const char[] sError, int iData)
{
	DebugMessage("ConnectCallBack")
	if (!hDatabase)
	{
		SetFailState("Database failure: %s", sError);
	}
	
	g_hDatabase = hDatabase;
	
	
	if(iData == 1)
	{
		char szBuffer[16];
		DBDriver hDBDriver = g_hDatabase.Driver;
		hDBDriver.GetIdentifier(szBuffer, 16);
		
		if (!strcmp(szBuffer, "mysql", false))
		{
			SQLite = false;
		}
		else if (!strcmp(szBuffer, "sqlite", false))
		{
			SQLite = true;
		}
		else
		{
			SetFailState("ConnectCallBack: Driver \"%s\" is not supported!", szBuffer);
		}
	}
	else
	{
		SQLite = true;
	}

	
	SQL_LockDatabase(g_hDatabase);
	DBG_SQL_Query("SQL_Callback_CreateTables")
	if(SQLite)
	{
		g_hDatabase.Query(SQL_Callback_CreateTables, "CREATE TABLE IF NOT EXISTS `players` (\
																`id` INTEGER NOT NULL PRIMARY KEY,\
																`name` VARCHAR(32) NOT NULL default 'unknown',\
																`joined` INTEGER UNSIGNED NOT NULL,\
																`lastvisit` INTEGER UNSIGNED NOT NULL,\
																`points` INTEGER NOT NULL default '0');", 0);
																
		g_hDatabase.Query(SQL_Callback_CreateTables, "CREATE TABLE IF NOT EXISTS `clans` (\
																`id` INTEGER NOT NULL PRIMARY KEY,\
																`name` VARCHAR(32) NOT NULL,\
																`joined` INTEGER UNSIGNED NOT NULL,\
																`lastvisit` INTEGER UNSIGNED NOT NULL,\
																`points` INTEGER NOT NULL default '0');", 1);
																
		g_hDatabase.Query(SQL_Callback_CreateTables, "CREATE TABLE IF NOT EXISTS `countries` (\
																`id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,\
																`name` VARCHAR(32) NOT NULL,\
																`joined` INTEGER UNSIGNED NOT NULL,\
																`lastvisit` INTEGER UNSIGNED NOT NULL,\
																`points` INTEGER NOT NULL default '0');", 2);

		g_hDatabase.Query(SQL_Callback_CreateTables, "CREATE TABLE IF NOT EXISTS `maps` (\
																`id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,\
																`name` VARCHAR(32) NOT NULL,\
																`joined` INTEGER UNSIGNED NOT NULL,\
																`lastvisit` INTEGER UNSIGNED NOT NULL,\
																`points` INTEGER NOT NULL default '0');", 3);
		
		g_hDatabase.Query(SQL_Callback_CreateTables, "CREATE TABLE IF NOT EXISTS `modules` (\
																`id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,\
																`name` VARCHAR(32) NOT NULL);", 4);
		

																
																
		g_hDatabase.Query(SQL_Callback_CreateTables, "CREATE TABLE IF NOT EXISTS `client_account` (\
																`player_id` INTEGER NOT NULL,\
																`clan_id` INTEGER NOT NULL,\
																`country_id` INTEGER NOT NULL,\
																`map_id` INTEGER NOT NULL,\
																`module_id` INTEGER NOT NULL,\
																`stage` INTEGER NOT NULL default '0',\
																`points` INTEGER NOT NULL default '0',\
																`value` INTEGER NOT NULL default '0',\
																`zombies` INTEGER NOT NULL default '0',\
																`time` INTEGER NOT NULL);", 5);
		
		g_hDatabase.Query(SQL_Callback_CreateTables, "CREATE TABLE IF NOT EXISTS `map_account` (\
																`map_id` INTEGER NOT NULL,\
																`module_id` INTEGER NOT NULL,\
																`stage` INTEGER NOT NULL default '0',\
																`points` INTEGER NOT NULL default '0',\
																`value` INTEGER NOT NULL default '0',\
																`zombies` INTEGER NOT NULL default '0',\
																`time` INTEGER NOT NULL);", 6);
		
	}
	else
	{
		g_hDatabase.Query(SQL_Callback_CreateTables, "CREATE TABLE IF NOT EXISTS `players` (\
																`id` INT NOT NULL, \
																`name` VARCHAR(64) NOT NULL default 'unknown' COLLATE '" ... COLLATION ... "', \
																`joined` INT UNSIGNED NOT NULL default 0, \
																`lastvisit` INT UNSIGNED NOT NULL default 0, \
																`points` INT NOT NULL default 0, \
																CONSTRAINT pk_PlayerID PRIMARY KEY (`id`) \
																) DEFAULT CHARSET=" ... CHARSET ... ";");
																
		g_hDatabase.Query(SQL_Callback_CreateTables, "CREATE TABLE IF NOT EXISTS `clans` (\
																`id` INT NOT NULL, \
																`name` VARCHAR(64) NOT NULL default 'unknown' COLLATE '" ... COLLATION ... "', \
																`joined` INT UNSIGNED NOT NULL default 0, \
																`lastvisit` INT UNSIGNED NOT NULL default 0, \
																`points` INT NOT NULL default 0, \
																CONSTRAINT pk_ClanID PRIMARY KEY (`id`) \
																) DEFAULT CHARSET=" ... CHARSET ... ";");
																
		g_hDatabase.Query(SQL_Callback_CreateTables, "CREATE TABLE IF NOT EXISTS `countries` (\
																`id` INT NOT NULL, \
																`name` VARCHAR(64) NOT NULL default 'unknown' COLLATE '" ... COLLATION ... "', \
																`joined` INT UNSIGNED NOT NULL default 0, \
																`lastvisit` INT UNSIGNED NOT NULL default 0, \
																`points` INT NOT NULL default 0, \
																CONSTRAINT pk_CountryID PRIMARY KEY (`id`) \
																) DEFAULT CHARSET=" ... CHARSET ... ";");
																
		g_hDatabase.Query(SQL_Callback_CreateTables, "CREATE TABLE IF NOT EXISTS `maps` (\
																`id` INT NOT NULL, \
																`name` VARCHAR(64) NOT NULL default 'unknown' COLLATE '" ... COLLATION ... "', \
																`joined` INT UNSIGNED NOT NULL default 0, \
																`lastvisit` INT UNSIGNED NOT NULL default 0, \
																`points` INT NOT NULL default 0, \
																CONSTRAINT pk_MapID PRIMARY KEY (`id`) \
																) DEFAULT CHARSET=" ... CHARSET ... ";");


		g_hDatabase.Query(SQL_Callback_CreateTables, "CREATE TABLE IF NOT EXISTS `modules` (\
																`id` INT NOT NULL, \
																`name` VARCHAR(64) NOT NULL default 'unknown' COLLATE '" ... COLLATION ... "', \
																CONSTRAINT pk_ModuleID PRIMARY KEY (`id`) \
																) DEFAULT CHARSET=" ... CHARSET ... ";");
	
		g_hDatabase.Query(SQL_Callback_CreateTables, "CREATE TABLE IF NOT EXISTS `client_account` (\
																`player_id` INT NOT NULL, \
																`clan_id` INT NOT NULL, \
																`country_id` INT NOT NULL, \
																`map_id` INT NOT NULL, \
																`module_id` INT NOT NULL, \
																`stage` INT NOT NULL, \
																`points` INT NOT NULL, \
																`value` INT NOT NULL, \
																`zombies` INT NOT NULL, \
																`time` INT NOT NULL) DEFAULT CHARSET=" ... CHARSET ... ";");
																
		g_hDatabase.Query(SQL_Callback_CreateTables, "CREATE TABLE IF NOT EXISTS `map_account` (\
																`map_id` INT NOT NULL, \
																`module_id` INT NOT NULL, \
																`stage` INT NOT NULL, \
																`points` INT NOT NULL, \
																`value` INT NOT NULL, \
																`zombies` INT NOT NULL, \
																`time` INT NOT NULL) DEFAULT CHARSET=" ... CHARSET ... ";");

	}
	
							  
	SQL_UnlockDatabase(g_hDatabase);
	
	g_hDatabase.SetCharset("utf8");
}



public void SQL_Callback_CreateTables(Database hDatabase, DBResultSet results, const char[] szError, int iData)
{
	DBG_SQL_Response("SQL_Callback_CreateTables")
	if(szError[0])
	{
		LogError("SQL_Callback_CreateTables: %s", szError);
		return;
	}
	
	if(iData == 6)
	{
		OnDBLoaded();
	}
}


void OnDBLoaded()
{
	DebugMessage("OnDBLoaded")
	IsLoaded[LOAD_DATABASE] = true;
	LoadModules();
	DB_GetMap();
	DB_GetClientAveragePoints();
	DB_GetClientsCount();
	GetArrayCount();
	BuildTopMenu();
	BuildTopMenu(_, false);
	Forward_OnDBLoaded();
	AuthClients();
}

void AuthClients()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPostAdminCheck(i);
		}
	}
}




void LoadModules()
{
	char szBuffer[256], szQuery[256];
	BuildPath(Path_SM, szBuffer, 256, "configs/zstats.cfg");
	KeyValues hKeyValues = new KeyValues("ZStats");
	
	if(!hKeyValues.ImportFromFile(szBuffer) || !hKeyValues.GotoFirstSubKey())
	{
		SetFailState("Config file \"%s\" doesnt exists", szBuffer);
	}
	SQL_LockDatabase(g_hDatabase);
	do
	{
		
		ModuleData[Modules][MODULE_POINTS] = hKeyValues.GetNum("points");
		ModuleData[Modules][MODULE_ACCOUNT] = hKeyValues.GetNum("account");
		ModuleData[Modules][MODULE_COOLDOWN] = hKeyValues.GetNum("cooldown");
		ModuleData[Modules][MODULE_SHOWTOP] = hKeyValues.GetNum("top");
		ModuleData[Modules][MODULE_SHOWSTATS] = hKeyValues.GetNum("stats");
		ModuleData[Modules][MODULE_MIN_PLAYERS] = hKeyValues.GetNum("min_players", 4);
		ModuleData[Modules][MODULE_MAX_REWARDS] = hKeyValues.GetNum("max_rewards");
		ModuleData[Modules][MODULE_ACCOUNT_OPTIMIZE] = hKeyValues.GetNum("account_optimize");
		hKeyValues.GetSectionName(Module[Modules], 64);
		StringToLowercase(Module[Modules]);
		
		DB_AddColumn("players", Module[Modules]);
		DB_AddColumn("maps", Module[Modules]);
		DB_AddColumn("clans", Module[Modules]);
		DB_AddColumn("countries", Module[Modules]);

		if(ModuleData[Modules][MODULE_ACCOUNT])
		{
			FormatEx(szQuery, 256, "SELECT `id` FROM `modules` WHERE `name` = '%s'", Module[Modules]);
			DBG_SQL_Query(szQuery)
			DBResultSet hResults = SQL_Query(g_hDatabase, szQuery);
			
			if(hResults)
			{
				if(hResults.FetchRow())
				{
					ModuleData[Modules][MODULE_ID] = hResults.FetchInt(0);
				}
				else
				{
					if(SQLite)
					{
						FormatEx(szQuery, 256, "INSERT OR REPLACE INTO `modules` (`name`) VALUES ('%s');", Module[Modules]);
					}
					else
					{
						FormatEx(szQuery, 256, "INSERT INTO `modules` (`name`) VALUES ('%s') \ 
						ON DUPLICATE KEY UPDATE `name` = '%s';", Module[Modules], Module[Modules]);
					}
					DBG_SQL_Query(szQuery)
					DBResultSet hResults2 = SQL_Query(g_hDatabase, szQuery);
					if(hResults2)
					{
						ModuleData[Modules][MODULE_ID] = hResults2.InsertId;
					}
					delete hResults2;
				}
			}
			
			delete hResults;
			
		}
		Modules++;
	}
	while(hKeyValues.GotoNextKey() && Modules < MAX_MODULES);
	
	SQL_UnlockDatabase(g_hDatabase);
	
	delete hKeyValues;
	
	for(int i; i < Modules; i++)
	{
		Forward_OnModuleLoaded(i, Module[i]);
	}
	
	IsLoaded[LOAD_MODULES] = true;
}

void DB_AddColumn(const char[] table, const char[] module)
{
	char szBuffer[256];
	FormatEx(szBuffer, 256, "SELECT `%s` FROM `%s` LIMIT 1", module, table);
	if(!SQL_FastQuery(g_hDatabase, szBuffer))
	{
		FormatEx(szBuffer, 256, "ALTER TABLE `%s` ADD COLUMN `%s` INTEGER NOT NULL default '0'", table, Module[Modules]);
		g_hDatabase.Query(SQL_Callback_CheckError, szBuffer);
	}
}

void DB_GetClientAveragePoints()
{
	if(!IsLoaded[LOAD_DATABASE] || AverageClientPoints)
		return;

	char szBuffer[256];
	FormatEx(szBuffer, 256, "SELECT AVG(`points`) FROM `players` WHERE `points` > 0");
	DBG_SQL_Query(szBuffer)
	g_hDatabase.Query(SQL_Callback_GetClientAveragePoints, szBuffer);
}

public void SQL_Callback_GetClientAveragePoints(Database hDatabase, DBResultSet hResults, const char[] sError, any data) 
{
	DBG_SQL_Response("SQL_Callback_GetClientAveragePoints")
	if(sError[0])
	{
		LogError("SQL_Callback_GetClientAveragePoints: %s", sError);
		return;
	}
	
	if(hResults.FetchRow())
	{
		AverageClientPoints = hResults.FetchInt(0);
		//DB_GetAccountAverage();
	}
}


void DB_GetClientsCount()
{
	if(!IsLoaded[LOAD_DATABASE])
		return;
	
	char szBuffer[256];
	FormatEx(szBuffer, 256, "SELECT COUNT(`id`) FROM `players`");
	DBG_SQL_Query(szBuffer)
	g_hDatabase.Query(SQL_Callback_GetCountPlayers, szBuffer);
}

public void SQL_Callback_GetCountPlayers(Database hDatabase, DBResultSet hResults, const char[] sError, any data) 
{
	DBG_SQL_Response("SQL_Callback_GetCountPlayers")
	if(sError[0])
	{
		LogError("SQL_Callback_GetCountPlayers: %s", sError);
		return;
	}
	
	if(hResults.FetchRow())
	{
		Clients = hResults.FetchInt(0);
		
	}
}



public void SQL_Callback_CheckError(Database hDatabase, DBResultSet hResults, const char[] szError, any data)
{
	if(szError[0])
	{
		LogError("SQL_Callback_CheckError: %s", szError);
	}
}

