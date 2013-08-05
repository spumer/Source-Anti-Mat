#include <sourcemod>
#include <matgag>
#include <donator>
#pragma semicolon 1
#define PLUGIN_VERSION "0.3"

#define MINSYMBLOS 3

new bool:isGagged[32+1] = false;
new bool:toOut[32+1] = false; // show message or go to filter proccess

new bool:donateLibStatus;

new String:logfile[PLATFORM_MAX_PATH];
new Handle:badWords;
new Handle:excludedWords;
new Handle:matPairs;

public Plugin:myinfo =
{
  name = "Mat GAG",
	author = "AntiQar & Spumer",
	description = "GAG players who type mat in chat",
	version = PLUGIN_VERSION,
	url = "zo-zo.org"
}

public OnPluginStart()
{
	new String:sExcludedWords[PLATFORM_MAX_PATH], String:sBadWords[PLATFORM_MAX_PATH], String:sPairs[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, logfile, sizeof(logfile), "logs/mat_gag.log");
	BuildPath(Path_SM, sExcludedWords, sizeof(sExcludedWords), "data/mat_exclude.txt");
	BuildPath(Path_SM, sBadWords, sizeof(sBadWords), "data/mat_list.txt");
	BuildPath(Path_SM, sPairs, sizeof(sPairs), "data/mat_pairs.txt");
	
	// Read "whitelist" and "blacklist" to memory.
	ReadList(sBadWords, badWords);
	ReadList(sExcludedWords, excludedWords);
	
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	
	LoadPairs(sPairs, matPairs);
}

public OnPluginEnd()
{
	if(badWords) CloseHandle(badWords);
	if(excludedWords) CloseHandle(excludedWords);
	if(matPairs) CloseHandle(matPairs);
}

public OnAllPluginsLoaded()
{
	donateLibStatus = LibraryExists("donator.core");
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "donator.core"))
	{
		donateLibStatus = true;
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "donator.core"))
	{
		donateLibStatus = false;
	}
}

public OnClientPostAdminCheck(client)
{
	if (!IsFakeClient(client)) isGagged[client] = false;
}

public Action:Command_Say(client, const String:command[], args)
{
	if( !client /*|| client > MaxClients*/ ) return Plugin_Continue;
	if( toOut[client] ) { toOut[client] = false; return Plugin_Continue; } // Show message if it already filtered.
	if(donateLibStatus && IsPlayerDonator(client)) return Plugin_Continue;
	
	if (!isGagged[client])
	{
		decl String:strOrig[192], String:strText[192], String:strText_mod[sizeof(strText)*2+1];
		GetCmdArg(1, strOrig, sizeof(strOrig));
		new wrnStatus; // warning status 0000 - nothing, 0001 - replaced, 0010 - hidden mat found
		
		// Step 1
		strcopy(strText, sizeof(strText), strOrig);
		Rus_tolower(strText, sizeof(strText));
		StripMat(strText, sizeof(strText), strlen(strText), wrnStatus);
		// Step 2
		strcopy(strText_mod, sizeof(strText_mod), strText);
		StripExclude(strText_mod, sizeof(strText_mod)); // Remove excluded words from string.
		StrToLower(strText_mod, sizeof(strText_mod));
		Hidden_Mat(strText_mod, sizeof(strText_mod), wrnStatus);
		if( !(wrnStatus & 2) ) { // if hidden status not set
			toOut[client] = true;
			ReplaceString(strText, sizeof(strText), "\"", "\\\"");
			FakeClientCommand(client, "%s %s", command, strText);
		}
		GAG_Player(client, strOrig, wrnStatus);
	}
	
	return Plugin_Handled;
}

stock GAG_Player(client, const String:strText[], wrnSt)
{
	if(wrnSt)
	{
		decl String:SteamID[32];
		GetClientAuthString(client, SteamID, sizeof(SteamID));
		
		LogToFileEx(logfile, "%N [%s][%s] : %s", client, SteamID, wrnSt & 2 ? "HIDDEN" : "REPLACED", strText);
		if(wrnSt & 2){
			isGagged[client] = true;
			PrintToChat(client, "\x04[AntiMat]\x01 Вам отключен чат за использование мата или оскорблений.");
		}
	}
}

stock Rus_tolower(String:line[], maxlen)
{
	ReplaceString(line, maxlen, "А", "а");
	ReplaceString(line, maxlen, "Б", "б");
	ReplaceString(line, maxlen, "В", "в");
	ReplaceString(line, maxlen, "Г", "г");
	ReplaceString(line, maxlen, "Д", "д");
	ReplaceString(line, maxlen, "Е", "е");
	ReplaceString(line, maxlen, "Ё", "е"); //Замена ё на е
	ReplaceString(line, maxlen, "Ж", "ж");
	ReplaceString(line, maxlen, "З", "з");
	ReplaceString(line, maxlen, "И", "и");
	ReplaceString(line, maxlen, "Й", "й");
	ReplaceString(line, maxlen, "К", "к");
	ReplaceString(line, maxlen, "Л", "л");
	ReplaceString(line, maxlen, "М", "м");
	ReplaceString(line, maxlen, "Н", "н");
	ReplaceString(line, maxlen, "О", "о");
	ReplaceString(line, maxlen, "П", "п");
	ReplaceString(line, maxlen, "Р", "р");
	ReplaceString(line, maxlen, "С", "с");
	ReplaceString(line, maxlen, "Т", "т");
	ReplaceString(line, maxlen, "У", "у");
	ReplaceString(line, maxlen, "Ф", "ф");
	ReplaceString(line, maxlen, "Х", "х");
	ReplaceString(line, maxlen, "Ц", "ц");
	ReplaceString(line, maxlen, "Ч", "ч");
	ReplaceString(line, maxlen, "Ш", "ш");
	ReplaceString(line, maxlen, "Щ", "щ");
	ReplaceString(line, maxlen, "Ъ", "ъ");
	ReplaceString(line, maxlen, "Ы", "ы");
	ReplaceString(line, maxlen, "Ь", "ь");
	ReplaceString(line, maxlen, "Э", "э");
	ReplaceString(line, maxlen, "Ю", "ю");
	ReplaceString(line, maxlen, "Я", "я");
	
	ReplaceString(line, maxlen, "ё", "е"); //доп. замена ё на е
	//ReplaceString(line, maxlen, "й", "и"); //доп. замена й на и
}

stock Hidden_Mat(String:line[], maxlen, &wrnSt)
{
	//Замена похожей латиницы и цифр
	ReplaceString(line, maxlen, "x", "х", false);
	ReplaceString(line, maxlen, "y", "у", false);
	ReplaceString(line, maxlen, "s", "с", false);
	ReplaceString(line, maxlen, "c", "с", false);
	ReplaceString(line, maxlen, "o", "о", false);
	ReplaceString(line, maxlen, "0", "о", false);
	ReplaceString(line, maxlen, "6", "б", false);
	ReplaceString(line, maxlen, "b", "б", false);
	ReplaceString(line, maxlen, "l", "л", false);
	ReplaceString(line, maxlen, "e", "е", false);
	ReplaceString(line, maxlen, "h", "н", false);
	ReplaceString(line, maxlen, "a", "а", false);
	ReplaceString(line, maxlen, "k", "к", false);
	ReplaceString(line, maxlen, "n", "н", false);
	ReplaceString(line, maxlen, "i", "и", false);
	ReplaceString(line, maxlen, "t", "т", false);
	ReplaceString(line, maxlen, "3", "з", false);
	ReplaceString(line, maxlen, "9", "я", false);
	ReplaceString(line, maxlen, "p", "п", false);
	ReplaceString(line, maxlen, "zh", "ж", false);
	ReplaceString(line, maxlen, "sh", "ш", false);
	ReplaceString(line, maxlen, "r", "р", false);
	ReplaceString(line, maxlen, "w", "в", false);
	ReplaceString(line, maxlen, "v", "в", false);
	ReplaceString(line, maxlen, "m", "м", false);
	ReplaceString(line, maxlen, "z", "з", false);
	ReplaceString(line, maxlen, "d", "д", false);
	ReplaceString(line, maxlen, "ya", "я", false);
	
	// Replace all non-russian symbols to whitespace and remove them all
	decl len, /*nlen,*/ i;
	len = /*nlen =*/ strlen(line);
	for(i = 0; i < len; ++i) {
		if( strncmp(line[i], "А", 2) > -1 ) ++i;
		else { line[i] = ' '; /*--nlen;*/ continue; }
		// Replace duplicated non-russian symbols to whitespaces
		if( !strncmp(line[i-1], line[i+1], 2) ) { line[i] = line[i-1] = ' '; /*nlen-=2;*/ }
	}
	ReplaceString(line, maxlen, " ", "", false);
	
	len = GetArraySize(badWords);
	decl String:buf[33];
	for(i = 0;i < len; ++i) {
		GetArrayString(badWords, i, buf, sizeof(buf));
		//if( myStrStr(line, nlen, buf, strlen(buf)) ){
		if( StrContains(line, buf) != -1 ) {
			wrnSt |= 2;
			LogToFileEx(logfile, "STRING WHERE i found hidden mat: %s. I found word: %s", line, buf);
			break;
		}
	}
}

stock ReadList(const String:sPath[], &Handle:hArray)
{
	hArray = CreateArray(33); // 32 bytes for word and 1 byte for '\0'
	decl String:sWord[33];
	new Handle:h_file = OpenFile(sPath, "r");
	if( h_file == INVALID_HANDLE) SetFailState("Unable to load mat file (%s)", sPath);
	while( !IsEndOfFile(h_file) && ReadFileLine(h_file, sWord, sizeof(sWord)) ){
		sWord[ strlen(sWord) -1 ] = '\0';
		PushArrayString(hArray, sWord);
	}
	CloseHandle(h_file);
}

stock StripExclude(String:sInput[], maxlen)
{
	new size = GetArraySize(excludedWords);
	decl String:sWord[33];
	for(new i; i < size; ++i) {
		GetArrayString(excludedWords, i, sWord, sizeof(sWord));
		ReplaceString(sInput, maxlen, sWord, "", false);
	}
}
// replace mat with new word or delete it (work with copy, but replace in original string)
stock StripMat(String:sInput[], maxlen, len, &wrnSt)
{
	new excludedSize = GetArraySize(excludedWords);
	new badSize = GetArraySize(badWords);
	decl String:buf[64], String:buf1[33], p, start, j;
	for(new i; i < len; ++i) {
		if( strncmp(sInput[i], "А", 2) > -1 ) {
			p = 0; // p is a pointer to end of non-ASCII word
			start = i; // start is a pointer to begin of non-ASCII word
			// Calculate word len
			do {
				buf[p++] = sInput[i++];
				buf[p++] = sInput[i++];
				//p+=2; i+=2;
			}
			while(strncmp(sInput[i], "А", 2) > -1 && (p+2)<sizeof(buf));
			
			if(p < 2*MINSYMBLOS) continue; // skip word with len less /MINSYMBLOS/ symbols (2byte per symbol)
			buf[p] = '\0';
			//PrintToChatAll("I found non ASCII word: %s", buf);
			
			for(j = 0;j < excludedSize; ++j) {
				GetArrayString(excludedWords, j, buf1, sizeof(buf1));
				//if( strlen(buf1) == p && !strncmp(sInput[start], buf1, p) ){ //! replace it
				//if( myStrStr(sInput[start], p, buf1, strlen(buf1)) ) { //! replace mystrstr with api func
				if( StrContains(buf, buf1) != -1 ) {
					j = -1; // Mark this word as excluded
					break;
				}
			}
			if( j == -1 ) continue; // Go to next word
			
			for(j = 0;j < badSize; ++j) {
				GetArrayString(badWords, j, buf1, sizeof(buf1));
				//if( myStrStr(sInput[start], p, buf1, strlen(buf1)) ) { //! replace mystrstr with api func
				if( StrContains(buf, buf1) != -1 ) {
					// replace with pair in keyvalues or delete
					KvJumpToKey(matPairs, buf, true);
					KvGetString(matPairs, "value", buf1, sizeof(buf1), "");
					KvGoBack(matPairs);

					sInput[start] = '\0';
					if(sInput[start+p] == ',') ++p; // remove ',' character after mat word
					// fix new str len and i counter
					i -= len - (len = Format(sInput, maxlen, "%s%s%s", sInput, buf1, sInput[start+p]));
					
					wrnSt |= 1; // Set warning status to "REPLACED"
					break;
				}
			}
			
		} // IF
	} // FOR i
} // FUNCTION StripMat

// search str2 in str1 
stock bool:myStrStr(const String:str1[], str1len, const String:str2[], str2len)
{	
	if( str1len >= str2len) {
		new str2len2 = --str2len;
		while( str1len-- ) {
			if( str1[str1len] == str2[str2len] ){
				if(--str2len == -1) return true;
			}
			else str2len = str2len2;
		}
	}
	return false;
}

// UTF-safe function.
stock StrToLower(String:in[], maxlen)
{
	for(new len; len < maxlen; ++len) {
		if(IsCharMB(in[len])) continue;
		in[len] = CharToLower(in[len]);
	}
}

stock bool:LoadPairs(const String:sPath[], &Handle:h_KV) {
	h_KV = CreateKeyValues("PAIRS");
	if(h_KV == INVALID_HANDLE)
		return false;
	else if(!FileToKeyValues(h_KV, sPath)) {
		CloseHandle(h_KV); h_KV = INVALID_HANDLE;
		return false;
	}
	return true;
}

public Native_Filter(Handle:plugin, numParams)
{
	new client = GetClientOfUserId(GetNativeCell(1));
	if(!client || isGagged[client]) return false;
	
	new maxlen = GetNativeCell(3);
	new mod_maxlen = maxlen*2+1;
	new wrnStatus;
	
	decl String:str[maxlen];
	GetNativeString(2, str, maxlen);
	
	decl String:strText[maxlen], String:strText_mod[mod_maxlen];
	
	// Step 1
	strcopy(strText, maxlen, str);
	Rus_tolower(strText, maxlen);
	StripMat(strText, maxlen, strlen(strText), wrnStatus);
	// Step 2
	strcopy(strText_mod, mod_maxlen, strText);
	StripExclude(strText_mod, mod_maxlen); // Remove excluded words from string.
	StrToLower(strText_mod, mod_maxlen);
	Hidden_Mat(strText_mod, mod_maxlen, wrnStatus);
	
	GAG_Player(client, str, wrnStatus);
	if( wrnStatus & 2)
	{
		return false;
	}

	ReplaceString(strText, maxlen, "\"", "\\\"");
	SetNativeString(2, strText, maxlen, true);
	return true;
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("matgag.filter");
	CreateNative("MatGag_Filter", Native_Filter);
	return APLRes_Success;
}
