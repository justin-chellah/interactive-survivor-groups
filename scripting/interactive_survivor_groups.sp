#include <sourcemod>

#define REQUIRE_EXTENSIONS
#include <imatchext>
#include <dhooks>

#define REQUIRE_PLUGINS
#include <sourcescramble>

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

#if defined DEBUG
static const char g_szSurvivorModels[][] =
{
	"models/survivors/survivor_namvet.mdl",
	"models/survivors/survivor_teenangst.mdl",
	"models/survivors/survivor_manager.mdl",
	"models/survivors/survivor_biker.mdl",

	"models/survivors/survivor_gambler.mdl",
	"models/survivors/survivor_producer.mdl",
	"models/survivors/survivor_mechanic.mdl",
	"models/survivors/survivor_coach.mdl",
}
#endif

SurvivorSet g_SurvivorSet = SurvivorSet_L4D2;	// default in CTerrorGameRules::GetSurvivorSet()

MemoryPatch g_hDistToNickSurvivorCharacterPatcher = null;
MemoryPatch g_hDistToRochelleSurvivorCharacterPatcher = null;
MemoryPatch g_hDistToCoachSurvivorCharacterPatcher = null;
MemoryPatch g_hDistToEllisSurvivorCharacterPatcher = null;

int CDirector_m_SurvivorCachedInfoForResponseRules = -1;
bool g_bJoinNewPlayer = false;

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

		PrecacheModel( g_szSurvivorModels[nCharacter] );
		SetEntityModel( iTarget, g_szSurvivorModels[nCharacter] );

		ReplyToCommand( iClient, "SetSurvivor %N to %d", iTarget, nCharacter );
	}
	else
	{
		SetEntProp( iClient, Prop_Send, "m_survivorCharacter", nCharacter );

		PrecacheModel( g_szSurvivorModels[nCharacter] );
		SetEntityModel( iClient, g_szSurvivorModels[nCharacter] );

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

		if ( g_SurvivorSet == SurvivorSet_L4D1 )
		{
			g_hDistToNickSurvivorCharacterPatcher.Enable();
			g_hDistToRochelleSurvivorCharacterPatcher.Enable();
			g_hDistToCoachSurvivorCharacterPatcher.Enable();
			g_hDistToEllisSurvivorCharacterPatcher.Enable();
		}
		else
		{
			g_hDistToNickSurvivorCharacterPatcher.Disable();
			g_hDistToRochelleSurvivorCharacterPatcher.Disable();
			g_hDistToCoachSurvivorCharacterPatcher.Disable();
			g_hDistToEllisSurvivorCharacterPatcher.Disable();
		}
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
			hReturn.SetString( "Gambler" );
		case SurvivorCharacter_TeenGirl:
			hReturn.SetString( "Producer" );
		case SurvivorCharacter_Biker:
			hReturn.SetString( "Mechanic" );
		case SurvivorCharacter_Manager:
			hReturn.SetString( "Coach" );
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
			hReturn.SetString(  "Nick" );
		case SurvivorCharacter_TeenGirl:
			hReturn.SetString(  "Rochelle" );
		case SurvivorCharacter_Biker:
			hReturn.SetString(  "Ellis" );
		case SurvivorCharacter_Manager:
			hReturn.SetString(  "Coach" );
		default:
			return MRES_Ignored;
	}

	return MRES_Supercede;
}

public MRESReturn DHook_GetCharacterFromName( DHookReturn hReturn, DHookParam hParams )
{
	// L4D2 set allows L4D and L4D2 characters
	if ( g_SurvivorSet == SurvivorSet_L4D2 )
	{
		return MRES_Ignored;
	}

	// L4D2 character names are stored inside avatar info key values so we shouldn't convert them because
	// then, the game will look for L4D2 survivors instead of the original set
	if ( g_bJoinNewPlayer )
	{
		return MRES_Ignored;
	}

	char szName[32];
	hParams.GetString( 1, szName, sizeof( szName ) );

	if ( StrEqual( szName, "NamVet", false ) || StrEqual( szName, "Bill", false ) )
	{
		hReturn.Value = SurvivorCharacter_Gambler;
		return MRES_Supercede;
	}

	if ( StrEqual( szName, "TeenGirl", false ) || StrEqual( szName, "Zoey", false ) || StrEqual( szName, "TeenAngst", false ) )
	{
		hReturn.Value = SurvivorCharacter_Producer;
		return MRES_Supercede;
	}

	if ( StrEqual( szName, "Manager", false ) || StrEqual( szName, "Louis", false ) )
	{
		hReturn.Value = SurvivorCharacter_Coach;
		return MRES_Supercede;
	}

	if ( StrEqual( szName, "Biker", false ) || StrEqual( szName, "Francis", false ) )
	{
		hReturn.Value = SurvivorCharacter_Mechanic;
		return MRES_Supercede;
	}

	if ( StrEqual( szName, "Gambler", false ) || StrEqual( szName, "Nick", false ) )
	{
		hReturn.Value = SurvivorCharacter_NamVet;
		return MRES_Supercede;
	}

	if ( StrEqual( szName, "Producer", false ) || StrEqual( szName, "Rochelle", false ) )
	{
		hReturn.Value = SurvivorCharacter_TeenGirl;
		return MRES_Supercede;
	}

	if ( StrEqual( szName, "Mechanic", false ) || StrEqual( szName, "Ellis", false ) )
	{
		hReturn.Value = SurvivorCharacter_Biker;
		return MRES_Supercede;
	}

	if ( StrEqual( szName, "Coach", false ) )
	{
		hReturn.Value = SurvivorCharacter_Manager;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DHook_ConvertToInternalCharacter( DHookReturn hReturn, DHookParam hParams )
{
	// L4D2 set allows L4D and L4D2 characters
	if ( g_SurvivorSet == SurvivorSet_L4D2 )
	{
		return MRES_Ignored;
	}

	SurvivorCharacterType eSurvivorCharacter = hParams.Get( 1 );
	hReturn.Value = eSurvivorCharacter;
	return MRES_Supercede;
}

public MRESReturn DHook_SurvivorResponseCachedInfo_GetClosestSurvivorTo( Address addrThis, DHookReturn hReturn, DHookParam hParams )
{
	SurvivorCharacterType eToSurvivorCharacter = hParams.Get( 1 );
	Address addr = addrThis + view_as< Address >( CDirector_m_SurvivorCachedInfoForResponseRules ) * view_as< Address >( eToSurvivorCharacter );

	SurvivorCharacterType eSurvivorCharacter;
	float flClosest = 99999.9;

	for ( SurvivorCharacterType iter = SurvivorCharacter_Gambler; iter <= SurvivorCharacter_Manager; ++iter )
	{
		if ( iter == eToSurvivorCharacter )
		{
			continue;
		}

		float flDistance = LoadFromAddress( addr + view_as< Address >( iter ) * view_as< Address >( 4 )/* sizeof( int ) */, NumberType_Int32 );
		if ( flDistance <= flClosest )
		{
			eSurvivorCharacter = iter;
			flClosest = flDistance;
		}
	}

	hReturn.Value = eSurvivorCharacter;
	return MRES_Supercede;
}

public MRESReturn DHook_CDirector_JoinNewPlayer_Pre( Address addrThis, DHookReturn hReturn, DHookParam hParams )
{
	g_bJoinNewPlayer = true;
	return MRES_Ignored;
}

public MRESReturn DHook_CDirector_JoinNewPlayer_Post( Address addrThis, DHookReturn hReturn, DHookParam hParams )
{
	g_bJoinNewPlayer = false;
	return MRES_Ignored;
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

	CDirector_m_SurvivorCachedInfoForResponseRules = hGameData.GetOffset( "CDirector::m_SurvivorCachedInfoForResponseRules" );
	if ( CDirector_m_SurvivorCachedInfoForResponseRules == -1 )
	{
		delete hGameData;

		SetFailState( "Unable to find gamedata offset entry for \"CDirector::m_SurvivorCachedInfoForResponseRules\"" );
	}

#define MEMORY_PATCH_WRAPPER(%0,%1)\
	%1 = MemoryPatch.CreateFromConf( hGameData, %0 );\
	\
	if ( !%1.Validate() )\
	{\
		delete hGameData;\
		\
		SetFailState( "Unable to validate patch for \"" ... %0 ... "\"" );\
	}

	MemoryPatch hDistToBillSurvivorCharacterPatcher;
	MEMORY_PATCH_WRAPPER( "Bill survivor character", hDistToBillSurvivorCharacterPatcher )

	MemoryPatch hDistToZoeySurvivorCharacterPatcher;
	MEMORY_PATCH_WRAPPER( "Zoey survivor character", hDistToZoeySurvivorCharacterPatcher )

	MemoryPatch hDistToFrancisSurvivorCharacterPatcher;
	MEMORY_PATCH_WRAPPER( "Francis survivor character", hDistToFrancisSurvivorCharacterPatcher )

	MemoryPatch hDistToLouisSurvivorCharacterPatcher;
	MEMORY_PATCH_WRAPPER( "Louis survivor character", hDistToLouisSurvivorCharacterPatcher )

	MEMORY_PATCH_WRAPPER( "Nick survivor character", g_hDistToNickSurvivorCharacterPatcher )
	MEMORY_PATCH_WRAPPER( "Rochelle survivor character", g_hDistToRochelleSurvivorCharacterPatcher )
	MEMORY_PATCH_WRAPPER( "Coach survivor character", g_hDistToCoachSurvivorCharacterPatcher )
	MEMORY_PATCH_WRAPPER( "Ellis survivor character", g_hDistToEllisSurvivorCharacterPatcher )

	hDistToBillSurvivorCharacterPatcher.Enable();
	hDistToZoeySurvivorCharacterPatcher.Enable();
	hDistToFrancisSurvivorCharacterPatcher.Enable();
	hDistToLouisSurvivorCharacterPatcher.Enable();

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

	DynamicDetour hDDetour_GetCharacterFromName = new DynamicDetour( Address_Null, CallConv_CDECL, ReturnType_Int, ThisPointer_Ignore );
	if ( !hDDetour_GetCharacterFromName.SetFromConf( hGameData, SDKConf_Signature, "GetCharacterFromName" ) )
	{
		delete hGameData;

		SetFailState( "Unable to find gamedata signature entry for \"GetCharacterFromName\"" );
	}

	DynamicDetour hDDetour_ConvertToInternalCharacter = new DynamicDetour( Address_Null, CallConv_CDECL, ReturnType_Int, ThisPointer_Ignore );
	if ( !hDDetour_ConvertToInternalCharacter.SetFromConf( hGameData, SDKConf_Signature, "ConvertToInternalCharacter" ) )
	{
		delete hGameData;

		SetFailState( "Unable to find gamedata signature entry for \"ConvertToInternalCharacter\"" );
	}

	DynamicDetour hDDetour_SurvivorResponseCachedInfo_GetClosestSurvivorTo = new DynamicDetour( Address_Null, CallConv_THISCALL, ReturnType_Int, ThisPointer_Address );
	if ( !hDDetour_SurvivorResponseCachedInfo_GetClosestSurvivorTo.SetFromConf( hGameData, SDKConf_Signature, "SurvivorResponseCachedInfo::GetClosestSurvivorTo" ) )
	{
		delete hGameData;

		SetFailState( "Unable to find gamedata signature entry for \"SurvivorResponseCachedInfo::GetClosestSurvivorTo\"" );
	}

	DynamicDetour hDDetour_CDirector_JoinNewPlayer = new DynamicDetour( Address_Null, CallConv_THISCALL, ReturnType_Void, ThisPointer_Address );
	if ( !hDDetour_CDirector_JoinNewPlayer.SetFromConf( hGameData, SDKConf_Signature, "CDirector::JoinNewPlayer" ) )
	{
		delete hGameData;

		SetFailState( "Unable to find gamedata signature entry for \"CDirector::JoinNewPlayer\"" );
	}

	delete hGameData;

	hDDetour_SurvivorCharacterName.AddParam( HookParamType_Int );
	hDDetour_SurvivorCharacterName.Enable( Hook_Pre, DHook_SurvivorCharacterName );

	hDDetour_SurvivorCharacterDisplayName.AddParam( HookParamType_Int );
	hDDetour_SurvivorCharacterDisplayName.Enable( Hook_Pre, DHook_SurvivorCharacterDisplayName );

	hDDetour_GetCharacterFromName.AddParam( HookParamType_CharPtr );
	hDDetour_GetCharacterFromName.Enable( Hook_Pre, DHook_GetCharacterFromName );

	hDDetour_ConvertToInternalCharacter.AddParam( HookParamType_Int );
	hDDetour_ConvertToInternalCharacter.Enable( Hook_Pre, DHook_ConvertToInternalCharacter );

	hDDetour_SurvivorResponseCachedInfo_GetClosestSurvivorTo.AddParam( HookParamType_Int );
	hDDetour_SurvivorResponseCachedInfo_GetClosestSurvivorTo.Enable( Hook_Pre, DHook_SurvivorResponseCachedInfo_GetClosestSurvivorTo );

	hDDetour_CDirector_JoinNewPlayer.AddParam( HookParamType_Int );		// DirectorNewPlayerType_t &
	hDDetour_CDirector_JoinNewPlayer.Enable( Hook_Pre, DHook_CDirector_JoinNewPlayer_Pre );
	hDDetour_CDirector_JoinNewPlayer.Enable( Hook_Post, DHook_CDirector_JoinNewPlayer_Post );

	#if defined DEBUG
	RegConsoleCmd( "sm_setsurvivor", Command_SetSurvivor );
	#endif
}

public Plugin myinfo =
{
	name = "[L4D2] Interactive Survivor Groups",
	author = "Justin \"Sir Jay\" Chellah",
	description = "Enables voice lines and adds respective server-side names for L4D2 characters on maps with L4D1 survivor set",
	version = "5.1.0",
	url = "https://www.justin-chellah.com/"
};