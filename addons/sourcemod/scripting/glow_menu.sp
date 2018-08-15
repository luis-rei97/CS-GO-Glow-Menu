#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colorvariables>

#pragma newdecls required
#pragma semicolon 1

Handle db;

ArrayList g_GlowColor;
ArrayList g_GlowColorName;

// Server ConVars;
ConVar sv_force_transmit_players;
ConVar g_CVAR_GlowColor_Style;
ConVar g_CVAR_GlowColor_Flag;
ConVar g_CVAR_GlowColor_Prefix;
ConVar g_CVAR_GlowColor_Random;

int g_GlowColor_Style;
int g_GlowColor_Flag;
int g_GlowColor_Random;

char g_GlowColor_Prefix[40];

int playerModels[MAXPLAYERS + 1];
int playerModelsIndex[MAXPLAYERS + 1];

int force_transmit;

int GlowIndex[MAXPLAYERS + 1];

char g_GlowColorPath[PLATFORM_MAX_PATH];

// Values to the Glow Skin;
#define EF_BONEMERGE                (1 << 0)
#define EF_NOSHADOW                 (1 << 4)
#define EF_NORECEIVESHADOW          (1 << 6)

public Plugin myinfo =
{
	name        = "[CS:GO Glow Menu]",
	author      = "Hallucinogenic Troll (Glow code mostly by Mitch)",
	description = "Allow users to activate Glow to themselves",
	version     = "2.0",
	url         = "HTConfigs.me"
};

public void OnPluginStart()
{
	g_GlowColor = new ArrayList(256);
	g_GlowColorName = new ArrayList(256);
	
	SQL_TConnect(OnSQLConnect, "glow_menu");
	
	sv_force_transmit_players 	= 	FindConVar("sv_force_transmit_players");
	
	g_CVAR_GlowColor_Style = CreateConVar("sm_glowmenu_style", "1", "Type of Style that you want to the glow (0 gives WALLHACKS to everyone)", _, true, 0.0, true, 3.0);
	g_CVAR_GlowColor_Random = CreateConVar("sm_glowmenu_random", "0", "It lets players have a choice to select if the glow should be random every X seconds", _, true, 0.0, true, 1.0);
	g_CVAR_GlowColor_Flag = CreateConVar("sm_glowmenu_flag", "", "Only gives the glow to players with a certain flag");
	g_CVAR_GlowColor_Prefix = CreateConVar("sm_glowmenu_prefix", "[Glow Menu]", "Chat's Prefix");
	
	
	BuildPath(Path_SM, g_GlowColorPath, sizeof(g_GlowColorPath), "configs/glow_menu.ini");
	
	RegConsoleCmd("sm_glow", Command_GlowMenu, "Glow Color Menu");
	
	HookEvent("player_spawn", 	Event_PlayerSpawn);
	HookEvent("player_death", 	Event_PlayerDeath);
	
	AutoExecConfig(true, "glow_menu");
	LoadTranslations("glow_menu.phrases");
}

public void OnConfigsExecuted()
{
	g_GlowColor.Clear();
	g_GlowColorName.Clear();
	force_transmit = sv_force_transmit_players.IntValue;
	
	g_GlowColor_Random = g_CVAR_GlowColor_Random.IntValue;
	
	g_GlowColor_Style = g_CVAR_GlowColor_Style.IntValue;
	
	g_CVAR_GlowColor_Prefix.GetString(g_GlowColor_Prefix, sizeof(g_GlowColor_Prefix));
	
	char buffer[40];
	g_CVAR_GlowColor_Flag.GetString(buffer, sizeof(buffer));
	
	g_GlowColor_Flag = ReadFlagString(buffer);
	
	if(force_transmit == 0)
	{
		sv_force_transmit_players.SetInt(1, true);
	}
	
	KeyValues kv = CreateKeyValues("glow_colors");
	kv.ImportFromFile(g_GlowColorPath);

	if (!kv.GotoFirstSubKey())
	{
		return;
	}
	
	char colors[150];
	char colors2[150][3];
	int icolors[3];
	char name[150];
	do
	{
		kv.GetString("name", name, sizeof(name));
		kv.GetString("color", colors, sizeof(colors));
		
		ExplodeString(colors, " ", colors2, 3, sizeof(colors));
		
		for (int i = 0; i < 3; i++)
		{
			icolors[0] = StringToInt(colors2[i]);
		}
		
		g_GlowColor.PushArray(icolors);
		g_GlowColorName.PushString(name);
		
	} while (kv.GotoNextKey());
	
	delete kv;
}

public int OnSQLConnect(Handle owner, Handle hndl, char [] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("[GLOW COLOR] Error: %s", error);
		
		SetFailState("Databases dont work");
	}
	else
	{
		db = hndl;
		
		char buffer[3096];
		SQL_GetDriverIdent(SQL_ReadDriver(db), buffer, sizeof(buffer));
		
		if(StrEqual(buffer,"mysql", false))
		{
			Format(buffer, sizeof(buffer), "CREATE TABLE IF NOT EXISTS glow(SteamID NVARCHAR(64) NOT NULL DEFAULT '', color INT NOT NULL DEFAULT 0);");
			SQL_TQuery(db, OnSQLConnectCallback, buffer);
		}
	}
}

public int OnSQLConnectCallback(Handle owner, Handle hndl, char [] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("[GLOW COLOR] Error: %s", error);
		return;
	}

	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			OnClientPostAdminCheck(client);
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
	playerModelsIndex[client] = -1;
	playerModels[client] = INVALID_ENT_REFERENCE;
	
	GlowIndex[client] = -1;
	
	char SteamID[64];
	GetClientAuthId(client, AuthId_Steam3, SteamID, sizeof(SteamID));
	
	if(db != INVALID_HANDLE)
	{
		char buffer[1024];
		Format(buffer, sizeof(buffer), "SELECT * FROM glow WHERE SteamID = '%s';", SteamID);
		SQL_TQuery(db, SQL_LoadPlayerCallback, buffer, client);
	}
}

public void SQL_LoadPlayerCallback(Handle DB, Handle results, const char[] error, any client)
{
	if(!IsClientInGame(client) || IsFakeClient(client))
	{
		return;
	}
	
	if(results == INVALID_HANDLE)
	{
		LogError("[GLOW COLOR] Error: %s", error);
		return;
	}

	if(SQL_HasResultSet(results) && SQL_FetchRow(results))
	{
		GlowIndex[client] = SQL_FetchInt(results, 1);
		
		if(!g_GlowColor_Random && GlowIndex[client] == -2)
		{
			GlowIndex[client] = -1;
		}
	}
	else
	{
		char buffer[2056];
		char SteamID[64];
		GetClientAuthId(client, AuthId_Steam3, SteamID, sizeof(SteamID));
		Format(buffer, sizeof(buffer), "INSERT INTO glow(SteamID, color) VALUES ('%s', -1)", SteamID[client]);
		SQL_TQuery(db, SQL_NothingCallback, buffer);
	}
	
}

public void OnClientDisconnect(int client)
{
	if(!IsValidClient(client))
	{
		return;
	}
	
	if(db != INVALID_HANDLE)
	{
		char buffer[1024];
		char SteamID[64];
		GetClientAuthId(client, AuthId_Steam3, SteamID, sizeof(SteamID));
		Format(buffer, sizeof(buffer), "UPDATE glow SET color = %d WHERE SteamID = '%s';", GlowIndex[client], SteamID);
		SQL_TQuery(db, SQL_NothingCallback, buffer);
	}
}

public int SQL_NothingCallback(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("[GLOW COLOR] Error: %s", error);
		return;
	}
}



public Action Command_GlowMenu(int client, int args)
{
	if (!IsValidClient(client))
	{
		return;
	}
	
	if(!CheckCommandAccess(client, "", g_GlowColor_Flag, true))
	{
		CPrintToChat(client, "%s %t", g_GlowColor_Prefix, "NoPermission");
		return;
	}
	
	char buffer[256];
	Menu menu = new Menu(Menu_Glow_Handler);
	Format(buffer, sizeof(buffer), "%t", "MenuTitle");
	menu.SetTitle(buffer);
	Format(buffer, sizeof(buffer), "%t", "MenuNone");
	menu.AddItem("-1", buffer);
	menu.AddItem("-2", "Random");
	for (int i = 0; i < g_GlowColorName.Length; i++)
	{
		g_GlowColorName.GetString(i, buffer, sizeof(buffer));
		menu.AddItem(buffer, buffer);
	}
	menu.ExitButton = true;
	menu.Display(client, 20);
}

public int Menu_Glow_Handler(Menu menu, MenuAction action, int client, int choice)
{
	if(action == MenuAction_Select)
	{
		GlowIndex[client] = choice - 2;
		if(choice == 0)
		{
			// Just to be sure it's -1;
			GlowIndex[client] = -1;
			CPrintToChat(client, "%s %t", g_GlowColor_Prefix, "DisabledGlow");
		}
		else if(choice == 1)
		{
			// Just to be sure it's -2;
			GlowIndex[client] = -2;
			CPrintToChat(client, "%s Now it will change colors randomly!", g_GlowColor_Prefix);
		}
		else
		{	
			char info[256];
			menu.GetItem(choice, info, sizeof(info));
			
			CPrintToChat(client, "%s %t", g_GlowColor_Prefix, "ChangedGlowColor", info);
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(!IsValidClient(client) || GlowIndex[client] == -1 || !CheckCommandAccess(client, "", g_GlowColor_Flag, true))
	{
		return;
	}
	
	RemoveSkin(client);
	CreateGlow(client);
	
	if(g_GlowColor_Random && GlowIndex[client] == -2)
	{
		CreateTimer(2.0, Timer_RandomGlow, GetClientSerial(client), TIMER_REPEAT);
	}
}

public Action Timer_RandomGlow(Handle timer, any data)
{
	int client = GetClientFromSerial(data);
	
	if(!IsValidClient(client) || !IsPlayerAlive(client) || !IsValidEntity(playerModels[client]) || GlowIndex[client] != -2)
	{
		return Plugin_Stop;
	}
	
	SetupGlow(playerModelsIndex[client], client);
	
	return Plugin_Continue;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(!IsValidClient(client) || GlowIndex[client] == -1 || !CheckCommandAccess(client, "", g_GlowColor_Flag, true))
	{
		return;
	}
	
	RemoveSkin(client);
}

public void CreateGlow(int client) 
{	
	char model[PLATFORM_MAX_PATH];
	int skin = -1;
	GetClientModel(client, model, sizeof(model));
	skin = CreatePlayerModelProp(client, model);
	if(skin > MaxClients)
	{
		if(SDKHookEx(skin, SDKHook_SetTransmit, OnSetTransmit_All))
		{
				SetupGlow(skin, client);
		}
	}
}

public Action OnSetTransmit_All(int entity, int client)
{
	if(playerModelsIndex[client] != entity)
	{
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

public void SetupGlow(int entity, int client)
{
	static int offset = -1;
	
	if ((offset = GetEntSendPropOffs(entity, "m_clrGlow")) == -1)
	{
		LogError("Unable to find property offset: \"m_clrGlow\"!");
		return;
	}


	SetEntProp(entity, Prop_Send, "m_bShouldGlow", true, true);
	SetEntProp(entity, Prop_Send, "m_nGlowStyle", g_GlowColor_Style);
	SetEntPropFloat(entity, Prop_Send, "m_flGlowMaxDist", 10000.0);

	int colors[3];
	
	if(GlowIndex[client] == -2)
	{
		colors[0] = GetRandomInt(0, 255);
		colors[1] = GetRandomInt(0, 255);
		colors[2] = GetRandomInt(0, 255);
	}
	else
	{
		g_GlowColor.GetArray(GlowIndex[client], colors);
	}
	
	for(int i=0;i<3;i++)
	{		
		SetEntData(entity, offset + i, colors[i], _, true);
	}
}

//////////////////////////////////////////////////////////////////////////
///// THE CODE BELOW IS 100% MADE FROM Mitchell's Advanced Admin ESP /////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
public int CreatePlayerModelProp(int client, char[] sModel)
{
	RemoveSkin(client);
	int skin = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(skin, "model", sModel);
	DispatchKeyValue(skin, "disablereceiveshadows", "1");
	DispatchKeyValue(skin, "disableshadows", "1");
	DispatchKeyValue(skin, "solid", "0");
	DispatchKeyValue(skin, "spawnflags", "256");
	SetEntProp(skin, Prop_Send, "m_CollisionGroup", 0);
	DispatchSpawn(skin);
	SetEntityRenderMode(skin, RENDER_TRANSALPHA);
	SetEntityRenderColor(skin, 0, 0, 0, 0);
	SetEntProp(skin, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_NOSHADOW|EF_NORECEIVESHADOW);
	SetVariantString("!activator");
	AcceptEntityInput(skin, "SetParent", client, skin);
	SetVariantString("primary");
	AcceptEntityInput(skin, "SetParentAttachment", skin, skin, 0);
	playerModels[client] = EntIndexToEntRef(skin);
	playerModelsIndex[client] = skin;
	return skin;
}

public void RemoveSkin(int client)
{
	if(IsValidEntity(playerModels[client]))
	{
		AcceptEntityInput(playerModels[client], "Kill");
	}
	playerModels[client] = INVALID_ENT_REFERENCE;
	playerModelsIndex[client] = -1;
}

public bool IsValidClient(int client)
{
	return (1 <= client && client <= MaxClients && IsClientInGame(client));
}