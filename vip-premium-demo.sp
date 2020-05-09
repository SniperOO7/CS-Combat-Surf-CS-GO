#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "SNIPER007"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <clientprefs>

bool g_bBody[MAXPLAYERS + 1] = false;

//GUNMENU
char sza_wpn_list_class[][] = {"weapon_ak47","weapon_m4a1","weapon_m4a1_silencer","weapon_awp","weapon_nova"};
char sza_wpn_list_names[][] = {"AK47 + DEAGLE","M4A4 + DEAGLE", "M4A1-S + DEAGLE","AWP + DEAGLE","NOVA + DEAGLE"};

char g_szSelectedWeapon[MAXPLAYERS + 1];

bool Useda[MAXPLAYERS] = false; 

//SETTINGS
ConVar g_cVIPhealthbonus;
ConVar g_cVIPhealthspawn;
ConVar g_cVIPhit;
ConVar g_cVIPkill;
ConVar g_cVIPspeed;
ConVar g_cVIPgravity;

int round;
bool g_bGunActivated = false;

#pragma newdecls required

public Plugin myinfo = 
{
	name = "VIP Premium [Demo version]",
	author = PLUGIN_AUTHOR,
	description = "VIP Premium from Sniper007",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/Sniper-oo7/"
};

public void OnPluginStart()
{	
	RegConsoleCmd("sm_gun", CMD_Gunmenus);
	RegConsoleCmd("sm_gunmenu", CMD_Gunmenus);
	RegConsoleCmd("sm_guns", CMD_Gunmenus);
	
	HookEvent("round_start", Event_RoundStart);
    HookEvent("player_death", OnPlayerDeath); 
   	
   	//CHANGE IT
   	g_cVIPhealthbonus = CreateConVar("sm_vip_health_bonus", "5", "Bonus for kill HP");
	g_cVIPhealthspawn = CreateConVar("sm_vip_health_spawn", "10", "On round start VIP HP");
	g_cVIPhit = CreateConVar("sm_vip_money_hit", "50", "Bonus money for VIP for hit player");
	g_cVIPkill = CreateConVar("sm_vip_kill_money", "300", "Money for VIP for killing players");
	g_cVIPspeed = CreateConVar("sm_vip_speed", "1.2", "Speed for vip, 0 = disabled");
	g_cVIPgravity = CreateConVar("sm_vip_gravity", "0.7", "Gravity for vip, 0 = disabled");
	
	AutoExecConfig(true, "VIP-Premium");
	
	CreateTimer(1.0, VIPtag, _, TIMER_REPEAT);
}

public void OnClientPutInServer(int client)
{
	if(IsPravyClient(client))
    {
    	CreateTimer(1.0, JoinVIP, client);	
		Useda[client] = false;
    }
	
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action JoinVIP(Handle timer, int client)
{
	if(IsPravyClient(client))
	{
		if(IsClientVIP(client))
    	{
			PrintToChatAll(" \x01[\x04*\x01] Player \x04[VIP] \x10%N \x01has join to the server!", client);
		}
	}
}

public void OnClientDisconnect(int client)
{
	Useda[client] = false;
	if(IsPravyClient(client))
	{
		if(IsClientVIP(client))
		{
			PrintToChatAll(" \x01[\x04*\x01] Player \x04[VIP] \x10%N \x01has disconnect from the server!", client);
		}
	}
}

public Action CMD_Gunmenus(int client, int args)
{
	if(IsPravyClient(client))
	{	
		if(IsPlayerAlive(client))
		{	
			openGuny(client);
		}
		else
		{
			PrintToChat(client, " \x04[VIP]\x01 You have to live"); //You can edit text in quotation marks "TEXT" [WARNING: THIS MARKING COLOR -> \x04 \x01 .. <- (https://ctrlv.cz/shots/2015/03/08/Mlwd.png)]
		}
	}
   
    return Plugin_Handled;
}

public void Event_RoundStart(Event event, const char[] name, bool bDontBroadcast)
{   
    if (GameRules_GetProp("m_bWarmupPeriod") != 1)
    {
    	round++;
    	if(round == 4)
    	{
    		g_bGunActivated = true;
    	}
    }
    
    for (int i = 1; i <= MaxClients; i++)
	{
		if(IsPravyClient(i))
		{	
			if(IsClientVIP(i))
			{
				if(IsPlayerAlive(i))
				{
					//SPEED & GRAVITY
					if(g_cVIPspeed.FloatValue > 0)
					{
						SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", g_cVIPspeed.FloatValue);
					}
					
					if(g_cVIPgravity.FloatValue > 0)
					{
						SetEntityGravity(i, g_cVIPgravity.FloatValue);
					}
					
					//GUNS
					
					RemovePrimaryWeapons(i);
					RemoveSecondaryWeapons(i);
					
					GivePlayerItem(i, g_szSelectedWeapon[i]);
					Useda[i] = false;

					GivePlayerItem(i, "weapon_hegrenade");
					GivePlayerItem(i, "weapon_deagle");
					
					SetEntityHealth(i, g_cVIPhealthspawn.IntValue);
					Func_SetPlayerArmor(i);
				}
			}
		}
    }
}

public void OnPlayerDeath(Handle event, char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	int Zivoty = GetClientHealth(attacker) + g_cVIPhealthbonus.IntValue;
	
	if (GameRules_GetProp("m_bWarmupPeriod") != 1)
    {	
		if(IsPravyClient(attacker))
    	{
	    	if(IsPlayerAlive(attacker))
	    	{
	    		if(!IsFakeClient(attacker))
	    		{
					if(IsClientVIP(attacker))
					{	
						//BONUS HP
						SetEntityHealth(attacker, Zivoty);
						//MONEY FOR KILL
						int penizes = GetEntProp(attacker, Prop_Send, "m_iAccount");
						SetEntProp(attacker, Prop_Send, "m_iAccount", penizes + g_cVIPkill.IntValue);
					}
				}
			}
		}
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{    
	//BONUS MONEY FOR HIT (STEAM GROUP)
    if (GameRules_GetProp("m_bWarmupPeriod") != 1)
    {
	    if(IsPravyClient(attacker))
		{
			if(GetClientTeam(attacker) == CS_TEAM_T && GetClientTeam(victim) == CS_TEAM_CT || GetClientTeam(attacker) == CS_TEAM_CT && GetClientTeam(victim) == CS_TEAM_T)
			{
				if(IsClientVIP(attacker))
				{
					if(g_bBody[attacker] == false)
					{
						if(!IsFakeClient(attacker))
	    				{
	    					int ucet = GetEntProp(attacker, Prop_Send, "m_iAccount");
							SetEntProp(attacker, Prop_Send, "m_iAccount", ucet + g_cVIPhit.IntValue);
							PrintToChat(attacker, " \x04[VIP] \x01You got \x0450 $ \x01money for hurt player"); //You can edit text in quotation marks "TEXT" [WARNING: THIS IS MARKING COLOR -> \x04 \x01 .. <- (https://ctrlv.cz/shots/2015/03/08/Mlwd.png)]
							g_bBody[attacker] = true;
							CreateTimer(15.0, Body, attacker);
						}
					}
				}
			}
		}
	}
} 

public Action Body(Handle timer, int client)
{
	if(IsPravyClient(client))
	{
		if (IsPlayerAlive(client))
		{
			g_bBody[client] = false;
		}
	}
}

//GUN MENU
void openGuny(int client)
{
    Menu menu = new Menu(mAutHandler);
 
    menu.SetTitle("Choose Gun:");
 
	for(int wep; wep < sizeof(sza_wpn_list_class); wep++)
	{
		menu.AddItem(sza_wpn_list_class[wep], sza_wpn_list_names[wep]);
	}
 
    menu.Display(client, MENU_TIME_FOREVER);
}

public int mAutHandler(Menu menu, MenuAction action, int client, int index)
{
    switch(action)
    {
        case MenuAction_Select:
        {
           	if(g_bGunActivated == true)
           	{
	            if(Useda[client] == false)
	            {
		            if(IsPravyClient(client))
		            {
		            	if(IsPlayerAlive(client))
		            	{
							char szItem[32];
			                menu.GetItem(index, szItem, sizeof(szItem));
							Format(g_szSelectedWeapon[client], sizeof(g_szSelectedWeapon), "%s", szItem);
							RemovePrimaryWeapons(client);
							RemoveSecondaryWeapons(client);
							GivePlayerItem(client, g_szSelectedWeapon[client]);
							GivePlayerItem(client, "weapon_hegrenade");
							GivePlayerItem(client, "weapon_deagle");
							Useda[client] = true;
			        	}
			        	else
			            {
			           		PrintToChat(client, " \x04[VIP]\x01 You have to live!");
			           	}
		           	}
	            }
	            else
	            {
	           		PrintToChat(client, " \x04[VIP]\x01 You already chosen gun!");
	           	}
	    	}
    		else
            {
           		PrintToChat(client, " \x04[VIP]\x01 You have to wait for third round!");
           	}
        }
    }
}
 
 
void RemovePrimaryWeapons(int client)
{
	if(IsPravyClient(client))
	{
		int iWepIndex = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
		
		if(iWepIndex != -1)
		{
			RemovePlayerItem(client, iWepIndex);
			AcceptEntityInput(iWepIndex, "Kill");
		}
	}
}

void RemoveSecondaryWeapons(int client)
{
	if(IsPravyClient(client))
	{
		int iWepIndex = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
		
		if(iWepIndex != -1)
		{
			RemovePlayerItem(client, iWepIndex);
			AcceptEntityInput(iWepIndex, "Kill");
		}
	}
}

public Action VIPtag(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsPravyClient(i))
		{
			if(IsClientVIP(i))
			{
				CS_SetClientClanTag(i, "[VIP]");
			}
		}
	}
}

stock bool IsPravyClient(int client, bool alive = false)
{
    if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client) && (alive == false || IsPlayerAlive(client)))
    {
        return true;
    }
   
    return false;
}

stock bool IsClientVIP(int client)
{
    return CheckCommandAccess(client, "", ADMFLAG_RESERVATION);
}

stock void Func_SetPlayerArmor(int client, int health = 100, int type = 1)
{
    if(IsPravyClient(client))
    {
        SetEntProp(client, Prop_Send, "m_ArmorValue", health, type);
    }
}
