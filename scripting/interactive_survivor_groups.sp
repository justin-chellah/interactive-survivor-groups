#include <sourcemod>
#include <imatchext>

#define REQUIRE_EXTENSIONS
#include <dhooks>

#define GAMEDATA_FILE	"interactive_survivor_groups"
// #define DEBUG

enum SurvivorCharacterType
{
	SurvivorCharacter_Gambler = 0,	// Nick
	SurvivorCharacter_Producer,		// Rochelle
	SurvivorCharacter_Coach,		// Coach
	SurvivorCharacter_Mechanic,		// Ellis

	SurvivorCharacter_NamVet,		// Bill
	SurvivorCharacter_TeenGirl,		// Zoey
	SurvivorCharacter_Biker,		// Francis
	SurvivorCharacter_Manager,		// Louis
	
	SurvivorCharacter_Unknown
};

SurvivorSet g_SurvivorSet = SurvivorSet_L4D2;	// default in CTerrorGameRules::GetSurvivorSet()

#if defined DEBUG
public Action Command_SetSurvivor( int iClient, int nArgs )
{
	char szArg[32];
	GetCmdArg( 1, szArg, sizeof( szArg ) );

	int nCharacter = StringToInt( szArg );

	int iTarget = GetClientAimTarget( iClient, true );
	if ( iTarget != INVALID_ENT_REFERENCE )
	{
		SetEntProp( iTarget, Prop_Send, "m_survivorCharacter", nCharacter );

		ReplyToCommand( iClient, "SetSurvivor %N to %d", iTarget, nCharacter );
	}
	else
	{
		SetEntProp( iClient, Prop_Send, "m_survivorCharacter", nCharacter );

		ReplyToCommand( iClient, "SetSurvivor %N to %d", iClient, nCharacter );
	}

	return Plugin_Handled;
}
#endif

public void OnMapStart()
{
	char szCurrMapName[PLATFORM_MAX_PATH];
	GetCurrentMap( szCurrMapName, sizeof( szCurrMapName ) );

	KeyValues hKvMissionInfo = new KeyValues( NULL_STRING );
	if ( GetMapInfoByBspName( szCurrMapName, NULL_STRING, null, hKvMissionInfo ) )
	{
		// Is there ever a case where we'd want to call CTerrorGameRules::FastGetSurvivorSet() instead of looking through server-side mission files?
		// Because survivor images will only be displayed properly if survivor_set is changed on the client side which we can't do from the server
		g_SurvivorSet = view_as< SurvivorSet >( hKvMissionInfo.GetNum( "survivor_set",
			view_as< int >( SurvivorSet_L4D2 ) ) );	// default in CTerrorGameRules::GetSurvivorSet()
	}

	delete hKvMissionInfo;
}

public MRESReturn DHook_SurvivorCharacterName( DHookReturn hReturn, DHookParam hParams )
{
	// L4D2 set allows L4D and L4D2 characters
	if ( g_SurvivorSet == SurvivorSet_L4D2 )
	{
		return MRES_Ignored;
	}

	SurvivorCharacterType eSurvivorCharacter = hParams.Get( 1 );
	if ( eSurvivorCharacter < SurvivorCharacter_NamVet )
	{
		return MRES_Ignored;
	}

	switch ( eSurvivorCharacter )
	{
		case SurvivorCharacter_NamVet:
			DHookSetReturnString( hReturn, "Gambler" );
		case SurvivorCharacter_TeenGirl:
			DHookSetReturnString( hReturn, "Producer" );
		case SurvivorCharacter_Biker:
			DHookSetReturnString( hReturn, "Mechanic" );
		case SurvivorCharacter_Manager:
			DHookSetReturnString( hReturn, "Coach" );
		default:
			return MRES_Ignored;
	}

	return MRES_Supercede;
}

public MRESReturn DHook_SurvivorCharacterDisplayName( DHookReturn hReturn, DHookParam hParams )
{
	// L4D2 set allows L4D and L4D2 characters
	if ( g_SurvivorSet == SurvivorSet_L4D2 )
	{
		return MRES_Ignored;
	}

	SurvivorCharacterType eSurvivorCharacter = hParams.Get( 1 );
	if ( eSurvivorCharacter < SurvivorCharacter_NamVet )
	{
		return MRES_Ignored;
	}

	switch ( eSurvivorCharacter )
	{
		case SurvivorCharacter_NamVet:
			DHookSetReturnString( hReturn, "Nick" );
		case SurvivorCharacter_TeenGirl:
			DHookSetReturnString( hReturn, "Rochelle" );
		case SurvivorCharacter_Biker:
			DHookSetReturnString( hReturn, "Ellis" );
		case SurvivorCharacter_Manager:
			DHookSetReturnString( hReturn, "Coach" );
		default:
			return MRES_Ignored;
	}

	return MRES_Supercede;
}

// https://www.unknowncheats.me/forum/general-programming-and-reversing/375888-address-direct-reference.html
Address GetFunctionAddressFromRelativeCall( Address addr )
{
	Address addrRelativeCall = LoadFromAddress( addr, NumberType_Int32 );
	Address addrFunction = addr + view_as< Address >( 4 )/* sizeof( int ) */ + addrRelativeCall;
	return addrFunction;
}

public void OnPluginStart()
{
	GameData hGameData = new GameData( GAMEDATA_FILE );
	if ( hGameData == null )
	{
		SetFailState( "Unable to load gamedata file \"" ... GAMEDATA_FILE ... "\"" );
	}

	Address addrSurvivorCharacterNameRelativeCall = hGameData.GetAddress( "SurvivorCharacterName relative call" );
	if ( addrSurvivorCharacterNameRelativeCall == Address_Null )
	{
		delete hGameData;

		SetFailState( "Unable to find gamedata address entry or address in binary for \"SurvivorCharacterName relative call\"" );
	}

	Address addrSurvivorCharacterDisplayNameRelativeCall = hGameData.GetAddress( "SurvivorCharacterDisplayName relative call" );
	if ( addrSurvivorCharacterDisplayNameRelativeCall == Address_Null )
	{
		delete hGameData;

		SetFailState( "Unable to find gamedata address entry or address in binary for \"SurvivorCharacterDisplayName relative call\"" );
	}

	Address addrSurvivorCharacterName = GetFunctionAddressFromRelativeCall( addrSurvivorCharacterNameRelativeCall );
	DynamicDetour hDDetour_SurvivorCharacterName = new DynamicDetour( addrSurvivorCharacterName, CallConv_CDECL, ReturnType_CharPtr, ThisPointer_Ignore );
	if ( hDDetour_SurvivorCharacterName == null )
	{
		delete hGameData;

		SetFailState( "Unable to setup dynamic detour for \"SurvivorCharacterName\"" );
	}

	Address addrSurvivorCharacterDisplayName = GetFunctionAddressFromRelativeCall( addrSurvivorCharacterDisplayNameRelativeCall );
	DynamicDetour hDDetour_SurvivorCharacterDisplayName = new DynamicDetour( addrSurvivorCharacterDisplayName, CallConv_CDECL, ReturnType_CharPtr, ThisPointer_Ignore );
	if ( hDDetour_SurvivorCharacterDisplayName == null )
	{
		delete hGameData;

		SetFailState( "Unable to setup dynamic detour for \"SurvivorCharacterDisplayName\"" );
	}

	delete hGameData;

	hDDetour_SurvivorCharacterName.AddParam( HookParamType_Int );
	hDDetour_SurvivorCharacterName.Enable( Hook_Pre, DHook_SurvivorCharacterName );

	hDDetour_SurvivorCharacterDisplayName.AddParam( HookParamType_Int );
	hDDetour_SurvivorCharacterDisplayName.Enable( Hook_Pre, DHook_SurvivorCharacterDisplayName );

	#if defined DEBUG
	RegConsoleCmd( "sm_setsurvivor", Command_SetSurvivor );
	#endif
}

public Plugin myinfo =
{
	name = "[L4D2] Interactive Survivor Groups",
	author = "Justin \"Sir Jay\" Chellah",
	description = "Enables voice lines and adds respective server-side names for L4D2 characters on maps with L4D1 survivor set",
	version = "2.0.0",
	url = "https://www.justin-chellah.com/"
};