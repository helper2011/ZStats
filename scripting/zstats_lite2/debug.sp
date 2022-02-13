
#if DEBUG_MODE 1
char DebugLogFile[PLATFORM_MAX_PATH];

void DebugMsg(const char[] sMsg, any ...)
{
	static char szBuffer[512];
	VFormat(szBuffer, 512, sMsg, 2);
	LogToFile(DebugLogFile, szBuffer);
}
#define DebugMessage(%0) DebugMsg(%0);

#define LOG_QUERIES				// SQL Запросы
#define LOG_RESPONSE			// Ответы SQL запросов

#else
#define DebugMessage(%0)
#endif

#if defined LOG_QUERIES
#define DBG_SQL_Query(%0) DebugMsg("SQL_Query: %s", %0);
#else
#define DBG_SQL_Query(%0)
#endif

#if defined LOG_RESPONSE
#define DBG_SQL_Response(%0) DebugMsg("SQL_Response: " ... %0);
#else
#define DBG_SQL_Response(%0)
#endif

#if defined LOG_API
#define DBG_API(%0) DebugMsg("API: " ... %0);
#else
#define DBG_API(%0)
#endif
