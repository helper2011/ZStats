GlobalForward
	GF_OnClientGotPoints, 
	GF_OnDBLoaded, 
	GF_OnClientLoaded, 
	GF_OnMapLoaded, 
	GF_OnModuleLoaded;

void initGlobalForwards()
{
	GF_OnDBLoaded = new GlobalForward("ZStats_OnDBLoaded", ET_Ignore);
	GF_OnMapLoaded = new GlobalForward("ZStats_OnMapLoaded", ET_Ignore, Param_Cell);
	GF_OnClientLoaded = new GlobalForward("ZStats_OnClientLoaded", ET_Ignore, Param_Cell);
	GF_OnModuleLoaded = new GlobalForward("ZStats_OnModuleLoaded", ET_Ignore, Param_Cell, Param_String);
	GF_OnClientGotPoints = new GlobalForward("ZStats_OnClientGotPoints", ET_Ignore, Param_Cell, Param_CellByRef);
}

void Forward_OnModuleLoaded(int iId, const char[] module)
{
	Call_StartForward(GF_OnModuleLoaded);
	Call_PushCell(iId);
	Call_PushString(module);
	Call_Finish();
}


void Forward_OnMapLoaded()
{
	Call_StartForward(GF_OnMapLoaded);
	Call_PushCell(MapID);
	Call_Finish();
}

void Forward_OnDBLoaded()
{
	Call_StartForward(GF_OnDBLoaded);
	Call_Finish();
}

void Forward_OnClientLoaded(int iClient)
{
	Call_StartForward(GF_OnClientLoaded);
	Call_PushCell(iClient);
	Call_Finish();
}

void Forward_OnClientGotPoints(int iClient, int& iPoints)
{
	Call_StartForward(GF_OnClientGotPoints);
	Call_PushCell(iClient);
	Call_PushCellRef(iPoints);
	Call_Finish();
}


