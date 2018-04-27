#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

#pragma newdecls required
#pragma semicolon 1

#define PREFIX "[\x04Glow Menu\x01]"

// Server ConVars;
ConVar sv_force_transmit_players;


// Plugin ConVars;
ConVar g_CVAR_GlowColor_Style;
ConVar g_CVAR_GlowColor_Default;
ConVar g_CVAR_GlowColor_Flag;

// Variables to Store ConVars values;

int g_GlowColor_Style;
int g_GlowColor_Default[3];
char g_GlowColor_Flag[3];

// Store's every player color value;
int GlowColor[MAXPLAYERS + 1][3];

Handle Cookie_GlowColor = INVALID_HANDLE;


char g_GlowColorPath[PLATFORM_MAX_PATH];


// Values to the Glow Skin;
#define EF_BONEMERGE                (1 << 0)
#define EF_NOSHADOW                 (1 << 4)
#define EF_NORECEIVESHADOW          (1 << 6)


// Values to store player models;
int playerModelsIndex[MAXPLAYERS + 1] =  { -1, ... };
int playerModels[MAXPLAYERS + 1] =  { INVALID_ENT_REFERENCE, ... };

public Plugin myinfo =
{
	name        = "[CS:GO Glow Menu]",
	author      = "Hallucinogenic Troll (Glow code mostly by Mitch)",
	description = "Allow users to activate Glow to themselves",
	version     = "1.0",
	url         = "HTConfigs.me"
};

public void OnPluginStart()
{
	sv_force_transmit_players 	= 	FindConVar("sv_force_transmit_players");
	
	RegConsoleCmd("sm_glow", Command_GlowColor, "Glow Color Menu");
	
	g_CVAR_GlowColor_Style = CreateConVar("sm_glowcolor_style", "1", "Type of Style that you want to the glow (0 gives WALLHACKS to everyone)", _, true, 0.0, true, 3.0);
	g_CVAR_GlowColor_Default = CreateConVar("sm_glowcolor_default", "255 255 255", "Color that you give to players by default");
	g_CVAR_GlowColor_Flag = CreateConVar("sm_glowcolor_flag", "", "Only gives the glow to players witha certain flag");



	HookEvent("player_spawn", 	Event_PlayerSpawn);
	HookEvent("player_death", 	Event_PlayerDeath);
	HookEvent("round_end", 		Event_RoundEnd);
	
	// Color's Menu CFG Path
	BuildPath(Path_SM, g_GlowColorPath, sizeof(g_GlowColorPath), "configs/glow_colors/colors.cfg");
	
	Cookie_GlowColor = RegClientCookie("glow_colors", "Glow Color Cookie", CookieAccess_Public);
	
	LoadTranslations("csgo_glowcolor_menu.phrases");
	
	AutoExecConfig(true, "csgo_glowcolor_menu");
}

public void OnConfigsExecuted()
{
	sv_force_transmit_players.IntValue = 1;
	
	char buffer[12];
	
	g_GlowColor_Style = g_CVAR_GlowColor_Style.IntValue;
	
	g_CVAR_GlowColor_Default.GetString(buffer, sizeof(buffer));
	
	g_CVAR_GlowColor_Flag.GetString(g_GlowColor_Flag, sizeof(g_GlowColor_Flag));
	
	if(strlen(buffer) > 0)
	{
		char buffer2[3][4];
		ExplodeString(buffer, " ", buffer2, 3, 4);
	
		for (int i = 0; i < 3; i++)
		{
			g_GlowColor_Default[i] = StringToInt(buffer2[i]);
		}
	}
	else
	{
		g_GlowColor_Default[0] = -1;
		g_GlowColor_Default[1] = -1;
		g_GlowColor_Default[2] = -1;
	}	
}

public void OnPluginEnd()
{
	for (int i = 0; i < MaxClients; i++)
	{
		RemoveSkin(i);
	}
}

public void OnClientDisconnect(int client)
{
	ResetSettings(client);
}

public void OnClientPutInServer(int client)
{
	ResetSettings(client);
}

public void OnClientCookiesCached(int client)
{	
	char buffer[12];
	
	GetClientCookie(client, Cookie_GlowColor, buffer, sizeof(buffer));
	
	if(StrEqual(buffer, "none", true))
	{
		GlowColor[client][0] = -1;
		GlowColor[client][1] = -1;
		GlowColor[client][2] = -1;
	}
	else if(strlen(buffer) < 1)
	{
		GlowColor[client][0] = g_GlowColor_Default[0];
		GlowColor[client][1] = g_GlowColor_Default[1];
		GlowColor[client][2] = g_GlowColor_Default[2];
	}
	else
	{
		char buffer2[3][4];
		ExplodeString(buffer, " ", buffer2, 3, 4);
		
		for(int i = 0; i < 3; i++)
		{
			GlowColor[client][i] = StringToInt(buffer2[i]);
		}
	}
}


public void ResetSettings(int client)
{
	playerModelsIndex[client] = -1;
	playerModels[client] = INVALID_ENT_REFERENCE;
	
	for (int i = 0; i < 3; i++)
	{
		GlowColor[client][i] = g_GlowColor_Default[i];
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client <= 0 || client > MaxClients || !IsClientInGame(client))
	{
		return;
	}
	
	CreateTimer(0.0, Timer_CreateGlow, client);
}

public Action Timer_CreateGlow(Handle timer, int client)
{
	if(IsValidClient(client))
	{
		RemoveSkin(client);
		CreateGlow(client);
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	RemoveSkin(client);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 0; i < MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			RemoveSkin(i);
		}
	}
}

public Action Command_GlowColor(int client, int args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}
	
	if(strlen(g_GlowColor_Flag) > 0)
	{
		int flag = ReadFlagString(g_GlowColor_Flag);
	
		if(!CheckCommandAccess(client, "", flag, true))
		{
			PrintToChat(client, "%s %T", PREFIX, "NoPermission");
			return Plugin_Continue;
		}
	}
	
	KeyValues kv = CreateKeyValues("glow_colors");
	kv.ImportFromFile(g_GlowColorPath);

	if (!kv.GotoFirstSubKey())
	{
		PrintToChat(client, "%s %T", PREFIX, "CFGFileError");
		return Plugin_Continue;
	}

	Menu menu = new Menu(GlowMenu_Handler);
	menu.SetTitle("Glow Colors Menu");
	menu.AddItem("none", "None");
	char ClassID[10];
	char name[150];
	do
	{
		kv.GetSectionName(ClassID, sizeof(ClassID));
		kv.GetString("name", name, sizeof(name));
		menu.AddItem(ClassID, name);
	} while (kv.GotoNextKey());
	
	delete kv;
	menu.Display(client, 0);
	
	return Plugin_Handled;
}

public int GlowMenu_Handler(Menu menu, MenuAction action, int client, int choice)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(choice, info, sizeof(info));
		
		if(StrEqual(info, "none", true))
		{
			/*for (int i = 0; i < MaxClients; i++)
			{
				RemoveSkin(i);
			}*/			
			RemoveSkin(client);
			Command_GlowColor(client, choice);
			return;
		}
		
		KeyValues kv = CreateKeyValues("glow_colors");
		kv.ImportFromFile(g_GlowColorPath);

		if (!kv.GotoFirstSubKey())
		{
			return;
		}

		char ClassID[10];
		char name[150];
		char colors[64];
		do
		{
			kv.GetSectionName(ClassID, sizeof(ClassID));
			kv.GetString("name", name, sizeof(name));
			kv.GetString("color", colors, sizeof(colors));

			if(StrEqual(info, ClassID, false))
			{
				break;
			}

		} while (kv.GotoNextKey());

		delete kv;
		
		SetClientCookie(client, Cookie_GlowColor, colors);
		
		char buffer2[3][3];
		ExplodeString(colors, " ", buffer2, 3, 4);
	
		for (int i = 0; i < 3; i++)
		{
			GlowColor[client][i] = StringToInt(buffer2[i]);
		}
		
		/*for (int i = 0; i < MaxClients; i++)
		{
			
			for (int j = 0; j < 3; j++)
			{
				GlowColor[i][j] = StringToInt(buffer2[j]);
			}
			if(IsValidClient(i))
			{
				RemoveSkin(i);
				CreateGlow(i);
			}
		}*/
		
		RemoveSkin(client);
		CreateGlow(client);
		
		PrintToChat(client, "%s %T", PREFIX, "ChangedGlowColor", name);
		Command_GlowColor(client, choice);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public void CreateGlow(int client) 
{	
	if((GlowColor[client][0] == -1) && (GlowColor[client][1] == -1) && (GlowColor[client][2] == -1))
	{
		return;
	}
	else if(strlen(g_GlowColor_Flag) > 0)
	{
		int flag = ReadFlagString(g_GlowColor_Flag);
	
		if(!CheckCommandAccess(client, "", flag, true))
		{
			return;
		}
	}
	
	char model[PLATFORM_MAX_PATH];
	int skin = -1;
	GetClientModel(client, model, sizeof(model));
	skin = CreatePlayerModelProp(client, model);
	if(skin > MaxClients)
	{
		if(SDKHookEx(skin, SDKHook_SetTransmit, OnSetTransmit_All))
		{
				SetupGlow(skin, client, GlowColor[client]);
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

public void SetupGlow(int entity, int client, int color[3])
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


	for(int i=0;i<3;i++)
	{
		SetEntData(entity, offset + i, GlowColor[client][i], _, true);
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
