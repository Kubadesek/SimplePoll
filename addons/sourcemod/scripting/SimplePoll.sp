#include <sourcemod>
#include <AutoExecConfig>
#include <multicolors>

#define Plugin_Version "1.0"

enum struct e_SimplePoll
{
	Handle Timer;
	int Yes;
	int No;
	char Question[64];
	bool Voted[MAXPLAYERS+1];
	Handle Timer_CoolDown;
	int CoolDown[MAXPLAYERS+1];
}
e_SimplePoll SimplePoll;

ConVar c_SimplePollCMD, c_SimplePollFlagCMD, c_SimplePollCoolDown, c_SimplePollAdminFlag,
		c_SimplePollTime, c_SimplePollAdminCMD, c_SimplePollYesCMD, c_SimplePollNoCMD;

public Plugin myinfo =
{
	name = "SimplePoll",
	author = "Kubad",
	description = "This plugin makes Poll for Players",
	version = Plugin_Version,
	url = "https://kbd.wtf"
};

public void OnPluginStart()
{
	AutoExecConfig_SetFile("SimplePoll", "KBD");
	AutoExecConfig_SetCreateFile(true);

	c_SimplePollFlagCMD = AutoExecConfig_CreateConVar("sm_simplepoll_flag_cmd", "a", "Flag for Access SimplePoll Command.\nUse '-' Access for Everyone.");
	c_SimplePollCMD = AutoExecConfig_CreateConVar("sm_simplepoll_cmd", "sm_poll;sm_simplepoll", "this is main command for SimplePoll must be started by 'sm_' and they can be 6 max.");

	c_SimplePollYesCMD = AutoExecConfig_CreateConVar("sm_simplepoll_yes_cmd", "sm_yes;sm_voteyes", "this is yes command for SimplePoll must be started by 'sm_' and they can be 6 max.");
	c_SimplePollNoCMD = AutoExecConfig_CreateConVar("sm_simplepoll_no_cmd", "sm_no;sm_voteno", "this is no command for SimplePoll must be started by 'sm_' and they can be 6 max.");

	c_SimplePollAdminFlag = AutoExecConfig_CreateConVar("sm_simplepoll_admin_flag", "b", "Admin flag for controling SimplePoll.");
	c_SimplePollAdminCMD = AutoExecConfig_CreateConVar("sm_simplepoll_admin_cmd", "sm_cancelpoll;sm_stoppoll;sm_delpoll", "this is admin command for stopping SimplePoll must be started by 'sm_' and they can be 6 max.");

	c_SimplePollTime = AutoExecConfig_CreateConVar("sm_simplepoll_time", "30.0", "Time how long SimplePoll will be active.", 0, true, 15.0);
	c_SimplePollCoolDown = AutoExecConfig_CreateConVar("sm_simplepoll_cooldown", "10", "this is cooldown after SimplePoll Started (in minutes).\nUse '0' for disabling timer.", 0, true, 0.0);
	
	c_SimplePollCMD.AddChangeHook(ConVarChanged);
	c_SimplePollYesCMD.AddChangeHook(ConVarChanged);
	c_SimplePollNoCMD.AddChangeHook(ConVarChanged);
	c_SimplePollAdminCMD.AddChangeHook(ConVarChanged);
	c_SimplePollCoolDown.AddChangeHook(ConVarChanged);

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	if(c_SimplePollCoolDown.IntValue != 0) SimplePoll.Timer_CoolDown = CreateTimer(60.0, Timer_SimplePollCooldown, TIMER_REPEAT);

	LoadTranslations("SimplePoll.phrases");
}

public void ConVarChanged(ConVar cvar, char[] oldvalue, char[] newvalue)
{
	//timer
	if(cvar == c_SimplePollCoolDown)
	{
		int iold = StringToInt(oldvalue);
		int inew = StringToInt(newvalue);
		if(iold == 0 && inew >= 1)
		{
			SimplePoll.Timer_CoolDown = CreateTimer(60.0, Timer_SimplePollCooldown, TIMER_REPEAT);
		}else if(inew == 0)
		{
			ClearTimer(SimplePoll.Timer_CoolDown);
		}
	}
	//Main Command
	if(cvar == c_SimplePollCMD)
	{
		char temp[6][32];
		int count = ExplodeString(newvalue, ";", temp, sizeof(temp), sizeof(temp[]));
		for(int c = 0; c < count; c++)
		{
			if(CommandExists(temp[c])) continue;
		
			RegConsoleCmd(temp[c], Command_SimplePoll);
		}
	}
	//Cancel Command
	if(cvar == c_SimplePollAdminCMD)
	{
		char temp[6][32];
		int count = ExplodeString(newvalue, ";", temp, sizeof(temp), sizeof(temp[]));
		for(int c = 0; c < count; c++)
		{
			if(CommandExists(temp[c])) continue;
		
			RegConsoleCmd(temp[c], Command_SimplePollCancel);
		}
	}
	//Yes Command
	if(cvar == c_SimplePollYesCMD)
	{
		char temp[6][32];
		int count = ExplodeString(newvalue, ";", temp, sizeof(temp), sizeof(temp[]));
		for(int c = 0; c < count; c++)
		{
			if(CommandExists(temp[c])) continue;
		
			RegConsoleCmd(temp[c], Command_SimplePollVoteYes);
		}
	}
	//No Command
	if(cvar == c_SimplePollNoCMD)
	{
		char temp[6][32];
		int count = ExplodeString(newvalue, ";", temp, sizeof(temp), sizeof(temp[]));
		for(int c = 0; c < count; c++)
		{
			if(CommandExists(temp[c])) continue;
		
			RegConsoleCmd(temp[c], Command_SimplePollVoteNo);
		}
	}
}

public void OnConfigsExecuted()
{
	char temp[128];
	char temp2[6][32];
	int count;

	//Main Command
	c_SimplePollCMD.GetString(temp, sizeof(temp));
	count = ExplodeString(temp, ";", temp2, sizeof(temp2), sizeof(temp2[]));
	for(int c = 0; c < count; c++)
	{
		if(CommandExists(temp2[c])) continue;
		
		RegConsoleCmd(temp2[c], Command_SimplePoll);
	}

	//Cancel Command
	c_SimplePollAdminCMD.GetString(temp, sizeof(temp));
	count = ExplodeString(temp, ";", temp2, sizeof(temp2), sizeof(temp2[]));
	for(int c = 0; c < count; c++)
	{
		if(CommandExists(temp2[c])) continue;
		
		RegConsoleCmd(temp2[c], Command_SimplePollCancel);
	}

	//Vote Yes Command
	c_SimplePollYesCMD.GetString(temp, sizeof(temp));
	count = ExplodeString(temp, ";", temp2, sizeof(temp2), sizeof(temp2[]));
	for(int c = 0; c < count; c++)
	{
		if(CommandExists(temp2[c])) continue;
		
		RegConsoleCmd(temp2[c], Command_SimplePollVoteYes);
	}

	//Vote No Command
	c_SimplePollNoCMD.GetString(temp, sizeof(temp));
	count = ExplodeString(temp, ";", temp2, sizeof(temp2), sizeof(temp2[]));
	for(int c = 0; c < count; c++)
	{
		if(CommandExists(temp2[c])) continue;
		
		RegConsoleCmd(temp2[c], Command_SimplePollVoteNo);
	}
}

//Timers
public Action Timer_SimplePoll(Handle Timer)
{
	if(SimplePoll.Timer != INVALID_HANDLE)
	{
		CPrintToChatAll("%t %t", "poll_prefix", "poll_ended", SimplePoll.Question, SimplePoll.Yes, SimplePoll.No);

		SimplePoll.Timer = INVALID_HANDLE;
		SimplePoll.Yes = 0;
		SimplePoll.No = 0;
		Format(SimplePoll.Question, sizeof(SimplePoll.Question), "");

		for (int idx = 1; idx <= MaxClients; idx++)
		{
			if(!IsValidClient(idx)) continue;
			SimplePoll.Voted[idx] = false;
		}
	}
	return Plugin_Stop;
}

public Action Timer_SimplePollCooldown(Handle Timer)
{
	if(c_SimplePollCoolDown.IntValue == 0)
		return Plugin_Stop;

	for(int idx = 1; idx <= MaxClients; idx++)
	{
		if(!IsValidClient(idx)) continue;
		if(SimplePoll.CoolDown[idx] == 0) continue;

		SimplePoll.CoolDown[idx]--;
	}

	return Plugin_Continue;
}

//Commands
public Action Command_SimplePoll(int client, int args)
{
	char temp[16];
	c_SimplePollFlagCMD.GetString(temp, sizeof(temp));

	if(!HasClientAccess(client, temp))
	{
		CPrintToChat(client, "%t %t", "poll_prefix", "poll_no_permission");
		return Plugin_Handled;
	}

	c_SimplePollAdminFlag.GetString(temp, sizeof(temp));
	if(SimplePoll.CoolDown[client] != 0 && !HasClientAccess(client, temp, false))
	{
		CReplyToCommand(client,"%t %t", "poll_prefix", "poll_cooldown", SimplePoll.CoolDown[client]);
		return Plugin_Handled;
	}

	if(SimplePoll.Timer != INVALID_HANDLE)
	{
		CReplyToCommand(client, "%t %t", "poll_prefix", "poll_another_started");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		char CMD[32];
		GetCmdArg(0, CMD, sizeof(CMD));
		ReplaceString(CMD, sizeof(CMD), "sm_", "/");
		CReplyToCommand(client, "%t %t", "poll_prefix", "poll_command_usage", CMD);
		return Plugin_Handled;
	}
			
	char question[48];
	GetCmdArgString(question, sizeof(question));

	if(StrEqual(question, "") || StrEqual(question, " ")) return Plugin_Handled;

	char yes[128], no[128];
	ProcessString(yes, sizeof(yes), c_SimplePollYesCMD);
	ProcessString(no, sizeof(no), c_SimplePollNoCMD);
			
	CPrintToChatAll("%t %t", "poll_prefix", "poll_started", client, question, yes, no);	

	SimplePoll.CoolDown[client] = c_SimplePollCoolDown.IntValue;
	Format(SimplePoll.Question, sizeof(SimplePoll.Question), question);

	SimplePoll.Timer = CreateTimer(c_SimplePollTime.FloatValue, Timer_SimplePoll);
			
	return Plugin_Handled;
}

public Action Command_SimplePollCancel(int client, int args)
{
	if(SimplePoll.Timer == INVALID_HANDLE)
	{
		CReplyToCommand(client, "%t %t", "poll_prefix", "poll_not_started");
		return Plugin_Handled;
	}

	if (args > 0)
	{
		char reason[64];
		GetCmdArgString(reason, sizeof(reason));
		CPrintToChatAll("%t %t", "poll_prefix", "poll_removed_reasoned", client, reason);
	}else{
		CPrintToChatAll("%t %t", "poll_prefix", "poll_removed", client);
	}
	
	for (int idx = 1; idx <= MaxClients; idx++)
	{
		if(!IsValidClient(idx)) continue;
		SimplePoll.Voted[idx] = false;
	}
	
	Format(SimplePoll.Question, sizeof(SimplePoll.Question), "");
	SimplePoll.Yes = 0;
	SimplePoll.No = 0;
	ClearTimer(SimplePoll.Timer);
	
	return Plugin_Handled;
}

public Action Command_SimplePollVoteYes(int client, int args)
{
	if(SimplePoll.Timer == INVALID_HANDLE)
	{
		CReplyToCommand(client, "%t %t", "poll_prefix", "poll_not_started");
		return Plugin_Handled;
	}
	
	if(SimplePoll.Voted[client])
	{
		CReplyToCommand(client, "%t %t", "poll_prefix", "poll_already_voted");
		return Plugin_Handled;
	}
	
	SimplePoll.Voted[client] = true;
	SimplePoll.Yes++;
	
	CPrintToChat(client, "%t %t", "poll_prefix", "poll_vote", SimplePoll.Question, SimplePoll.Yes, SimplePoll.No);
	return Plugin_Handled;
}

public Action Command_SimplePollVoteNo(int client, int args)
{
	if(SimplePoll.Timer == INVALID_HANDLE)
	{
		CReplyToCommand(client, "%t %t", "poll_prefix", "poll_not_started");
		return Plugin_Handled;
	}
	
	if(SimplePoll.Voted[client])
	{
		CReplyToCommand(client, "%t %t", "poll_prefix", "poll_already_voted");
		return Plugin_Handled;
	}
	
	SimplePoll.Voted[client] = true;
	SimplePoll.No++;
	
	CPrintToChat(client, "%t %t", "poll_prefix", "poll_vote", SimplePoll.Question, SimplePoll.Yes, SimplePoll.No);
	return Plugin_Handled;
}

//stocks
stock bool HasClientAccess(int client, char[] flag, bool CanBeDisabled = true)
{
	int flags = ReadFlagString(flag);

	if((StrEqual(flag, "-") && CanBeDisabled) || GetUserFlagBits(client) & ADMFLAG_ROOT || GetUserFlagBits(client) & flags == flags)
	{
		return true;
	}
	return false;
}

stock bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client))
	{
		return true;
	}
	return false;
}

stock void ProcessString(char[] buffer, int length, ConVar cvar)
{
	cvar.GetString(buffer, length);
	SplitString(buffer, ";", buffer, length);
	ReplaceString(buffer, length, "sm_", "/");
}

stock void ClearTimer(Handle &timer)
{
    if (timer != INVALID_HANDLE)
    {
        KillTimer(timer);
        timer = INVALID_HANDLE;
    }
}