# [L4D2] Interactive Survivor Groups
This is a SourceMod Plugin that enables the voice lines and adds respective server-side names for L4D2 characters on maps with the original L4D1 survivors, e.g. No Mercy, Dead Air, etc. (custom campaigns included; nothing is hardcoded).

**IMPORTANT**: The way this plugin works is that it "splits" both groups of survivors under the hood if it's a campaign that has the original L4D1 survivors.

Let's take a look at this enum for further elaboration:
```
enum SurvivorCharacterType
{
	SurvivorCharacter_Gambler = 0,		// Nick
	SurvivorCharacter_Producer,		// Rochelle
	SurvivorCharacter_Coach,		// Coach
	SurvivorCharacter_Mechanic,		// Ellis

	SurvivorCharacter_NamVet,		// Bill
	SurvivorCharacter_TeenGirl,		// Zoey
	SurvivorCharacter_Biker,		// Francis
	SurvivorCharacter_Manager,		// Louis
	
	SurvivorCharacter_Unknown
};
```

Basically, the plugin will see the first four survivors in the enum as the L4D1 survivors and the last four as the L4D2 survivors. Most plugins that allow players to change characters aren't using the last four numbers so **a custom version of a character selection plugin will be required**.

# Requirements
- [SourceMod 1.11+](https://www.sourcemod.net/downloads.php?branch=stable)
- [Matchmaking Extension Interface](https://github.com/shqke/imatchext)

# Supported Platforms
- Windows
- Linux

# Supported Games
- Left 4 Dead 2