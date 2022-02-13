bool StageManager, HLStatsXLogHelper;

void CheckLibraries()
{
	StageManager = LibraryExists("StageManager");
	HLStatsXLogHelper = LibraryExists("HlstatsXLogHelper");
}

public void OnLibraryAdded(const char[] name)
{
	OnLibrary(name, true);
}

public void OnLibraryRemoved(const char[] name)
{
	OnLibrary(name, false);
}

void OnLibrary(const char[] name, bool bToggle)
{
	if(!strcmp(name, "StageManager", false))
	{
		StageManager = bToggle;
	}
	else if(!strcmp(name, "HLStatsXLogHelper", false))
	{
		HLStatsXLogHelper = bToggle;
	}
}