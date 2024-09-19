# MythicLite™
This is the formal documentation sheet for the MythicLite feature.

# Installation
MythicLite requires the following assets -

AIO by Rochet2
Eluna by Rochet2
AzerothCore
MythicLite™ repository

Once the following requirements are met, open the MythicLite repository. Go to the client folder. Copy and paste these contents into a new client-side patch. If you have a custom Spell.DBC, do not use the folder labeled “DBFilesClient”.

Next, navigate to the server folder. Move the contents to your server, where you would normally place lua_scripts.

To use the included spell.dbc, navigate to the data/dbc folder. Move spell.dbc to the server’s data directory, where dbc files are normally kept.

Installing the SQL requirements is the next step. Inside the server folder, open sql_to_insert.txt. Copy and paste, or run the file itself, inside the database manager client of your choice. If you receive any errors it is because there are already entries in your database with the same ID - just open the file itself and change the entry ID.

Because I prefer to document things, I’ll list what the SQL changes are. The SQL changes the following -

Added Mythic Keystone to item_template
Added “Forcefield 05” to gameobject_template
Added the following tables and their structures:
eluna_mythiclite_afixes_pool
eluna_mythiclite_afixes_template
eluna_mythiclite_keystones
eluna_mythiclite_progress
eluna_mythiclite_template
eluna_mythiclite_template_mobs
eluna_mythiclite_records
eluna_counters

Once you have ran and installed the contents of the SQL file, restart your server and your client.
# Configuration
This section contains documentation on variables, configurations, and what the user installing this feature can change.
Server_MythicLite.lua

The configuration values are broken up into separate locations. We will start with the file Server_MythicLite.lua.

local MYTHIC_ZERO_NORMAL = true
local MYTHIC_ZERO_HEROIC = true

	True or false.
	This determines if a mythic zero keystone can be obtained within normal and/or heroic variations of the dungeon.

local MYTHIC_NORMAL = true 
local MYTHIC_HEROIC = true

	True or false.
	This determines if a mythic keystone can gain levels within normal and/or heroic variations of the dungeon.

local KEYSTONE_LEVEL_STEP = 1

	Default = 1.
	This is the amount of levels a keystone progresses if the previous one has finished.

local KEYSTONE_LEVEL_BONUS = 1

	Default = 1.
	The amount of levels distributed when a keystone is considered valid for bonus levels, in addition to the level step. The bonus is determined by the bonus factor and can result in zero - no need to worry about incorrect math somewhere.

local KEYSTONE_LEVEL_BONUS_FACTOR = 4

	Default = 4
	When a dungeon is finished, the time limit of said dungeon is divided by this number. The result is compared to the time remaining of a mythic dungeon run, and for each whole number is a bonus level. 

So let’s say the duration for a dungeon is 300 seconds, a factor of 4 would divide 300 by 4. If the player finishes their keystone run with 75 seconds or more remaining, they get a bonus level. If they were to finish the dungeon in 151 seconds, they would gain a total of two bonus levels.

local MYTHIC_PEDESTAL = 1000100

	This is the entry ID of the Mythic Pedestal gameobject.

local MYTHIC_KEYSTONE = 1899980

	This is the entry ID of the Mythic Keystone item.

local MYTHIC_SPHERE = 1000003

	This is the entry ID of the sphere that keeps the players inside at the beginning countdown.

local MYTHIC_START_TIMER = 11
	
	This is how long, in seconds, the mythic dungeon counts down before it can be considered started. Add a +1 to any value you decide, otherwise the timer the client receives will start too early to see the first number.

local RBAC_LVL = 3

	Security level required for GM commands. Currently the only command is “generatekeystone” which prompts a Keystone generation for the player.

local MYTHIC_OBJECTIVES_ENEMY_FORCES = 1

	1 = true. 0 = false.
	Determines if the win condition for killing dungeon monsters is required or not.

local MYTHIC_OBJECTIVES_BOSS = 1 

	1 = true. 0 = false.
	Determines if the bosses are required for the win condition of the mythic dungeon. Requires MYTHIC_OBJECTIVES_ENEMY_FORCES = 1.

local AFFIX_RESET_TIMER = 604800
	The server makes a check to decide if the current time minus the timestamp of when the affixes were generated, is greater than this value or not. If this time passed, ie 1 week since the last affix generation, the server will prompt for another series of affixes to be generated.

local AFFIX_POOL_SIZE = 9

	Determines the maximum amount of affixes that the server will choose for that period’s affix generation.

local AFFIX_STEP = 3

	Determines the affixes per keystone level. For example, if affix_step is set to 3, then a keystone at level 3 will gain the AFFIX_STEP_AMOUNT in affixes.

local AFFIX_STEP_AMOUNT = 1

	How many affixes are added on each step. Default is 1.

local AFFIX_BASE = 7

	Determines the amount of affixes that every keystone starts with.

local REPICK_COST = 1000

	Determines the cost value of rerolling a keystone in money values.

local REPICK_ITEM = 0

	Determines the item entry required to perform a reroll, if enabled. 0 = disabled.

local REPICK_ITEM_QUANTITY = 1

	Determines the item amount required to perform a reroll, if enabled. 0 = disabled.

local REPICK_MAX = 3

	Determines the maximum possible amount of rerolls one player can have in a reroll session.

local REPICK_MOD_LEVEL = 0

	0 = default.
	Scales the cost of REPICK_COST, and REPICK_ITEM_QUANTITY based on the level of the keystone. For example, if the value is 1, then the cost will always be a modifier of * 1.


local REPICK_MOD_STACKING = 0

This concludes the file, Server_MythicLite.lua. There are no further configuration options. You can now close the file.
Client_MythicLite.lua

MYTHIC_KEYSTONE_ITEM_ID = 1899980

	This is the entry ID of the Mythic Keystone item. Currently this also needs to be defined in the client and the server. This will change in the future.

local mapID_to_strings = {
	[34] = "Stormwind Stockade",
	[33] = "Shadowfang Keep",
	[30] = "Alterac Valley"
},

	The client needs to turn map IDs into strings in order to render them correctly on the keystone frames. If you have custom dungeons, a dungeon that is not listed, or a dungeon incorrectly named, you would resolve that here.

	Here is a SQL command you can run that will allow you to easily capture the map names in relation to the IDs

	SELECT ID, mapname_lang_enus FROM map_dbc WHERE instancetype > 0;
SQL Database

[SQL] eluna_mythiclite_template

The following adjustments are in the eluna_mythiclite_template of your SQL database. This is where you will define the requirements or win conditions of each valid mythic dungeon. This list is also considered the valid list of keystones that can ever be made.

The following values are explained as so -
mapID = mapID of the dungeon that will be mythic
timelimit = the amount of time required to beat the dungeon
totalMod = the modifier value for total enemy forces required
dungeonName = the name of the dungeon.

[SQL] eluna_mythiclite_template_mobs

In the eluna_mythiclite_template_mobs table, exists the GUID of every creature that is valid for progressing a mythic dungeon. I attempted to create a SQL query that grabs all spawned hostile monsters based on the specified maps in the eluna_mythiclite_template table. Having it saved into the database allows you to manually remove a creature from this list, or manually add one that might not have been picked up by the SQL script. If you would like to add a new dungeon to the list of mythic dungeons, you need to populate this table as well. To do so, here is a SQL script that should make the process easier.

SELECT c.guid, c.map FROM fun_world.creature c INNER JOIN fun_world.eluna_mythiclite_template emt ON c.map = emt.mapID INNER JOIN fun_world.creature_template ct ON c.id1 = ct.entry WHERE ct.faction NOT IN (35, 31);

This would select all hostile creature GUIDs and their map ID within the mapIDs of 35,31. 

[SQL] eluna_mythiclite_affixes_template

This table determines which spells are available to be an affix, the amount of stacks at the beginning keystone level, and the amount of stacks per keystone level.

The explanations are as follows -
spellID = entry ID of the spell that can be considered an affix. Any aura.
base_stack = the amount of stacks given for a “level 0” keystone.
stack_per_level = the amount of stacks added per level of keystone.

[SQL] Other tables

eluna_mythiclite_keystones 
A table that contains all generated keystone data of the players. If players experience any strange errors, try deleting entries in here first.

eluna_mythiclite_affixes_pool 
Contains the generated list of valid affixes. Do not touch. Instead, adjust the timer reset for affix generation.

eluna_mythiclite_progress
Holds data related to mythic dungeons in progress and their progression.

eluna_mythiclite_records
Contains information related to finished mythic dungeons.

eluna_counters
I have a generic “counters” table in my own personal SQL database. This is where I’ve placed things like the affix generation timestamp. All the values found here should also contain a readable comment.
Logic

This section will be describing the logic process of the MythicLite features, how it all works, and how to interact with it.
Getting a Keystone

You first need to acquire a zero mythic keystone. To do so, kill all bosses in any of the dungeons listed in the mythiclite_template table. The configuration values, MYTHIC_ZERO_NORMAL and MYTHIC_ZERO_HEROIC, decide which dungeon mode(s) allow the initial zero mythic keystone. The configuration values MYTHIC_HEROIC and MYTHIC_NORMAL, decide which dungeon mode(s) allow a player to level up their mythic keystone at the end of the dungeon.

A Mythic Keystone is a unique item with the following attributes tied to it -
Affixes or selection of auras based on the above configuration values
Map that the keystone works in
Keystone Level that affects the amount of affixes based on the above configuration values. Keystone Level also affects the reroll cost and timer durations if applicable.
Right-click to generate a chat link that can be shared with others. Other people will not be able to see the attributes tied to a keystone unless you use this link.
Using a Keystone

The keystone you have now acquired can be used on any mythic pedestal gameobject. This does mean you will have to manually spawn these inside the dungeons you desire. You can do so with the command, `.gameobject spawn <MYTHIC_PEDESTAL_ENTRY>`. The pedestal is now permanent and should never disappear.

If you spawn a mythical pedestal inside of a dungeon, you must also have this information filled out appropriately in the following -

eluna_mythiclite_template
eluna_mythiclite_template_mobs
Client_MythicLite.lua -> Entry for MapID to strings
areatrigger_teleport (this is for teleporting at the start of a mythic dungeon)

Once these requirements are met, you can right click the Mythic Pedestal. The Mythic Pedestal UI will appear along with an item slot. Here you can place the mythic keystone item, so long as the keystone item is for the dungeon you are in.

When placed, the Mythic Pedestal will reveal the list of affixes and their stack count. This should provide transparent information to players who need to know what challenges await them. The start button is now green, click when ready.
Starting a Keystone

After pressing the start button, a timer lasting MYTHIC_START_TIMER seconds begins. When this timer starts, all players inside the dungeon are teleported to the start of the dungeon. The coordinates for this teleport are gathered from the SQL table, areatrigger_teleport, which should come with your AzerothCore database. 

A forcefield is then spawned around the group that lasts the duration mentioned above. A visual countdown appears to all players, counting the whole numbers down until the timer expires. On finishing, the forcefield despawns, all creatures are buffed with the aforementioned affixes, and all players are permitted to progress the keystone further.
Progressing a Keystone

In order to progress a Mythic Keystone, the dungeon must be finished within the timer specified in the SQL table, eluna_mythiclite_template. A dungeon is considered finished when the last boss of the dungeon is killed.

If MYTHIC_OBJECTIVES_ENEMY_FORCES is enabled, players are given a progress bar indicating they must kill creatures to fill this bar. This bar’s maximum value is ALL the creatures within the dungeon. The server then takes the totalMod value from the SQL table eluna_mythiclite_template, converts it into a percentage (ie: 1 = 1%), and multiplies the amount of forces required by that amount. So for example, if the dungeon happens to require 100 creatures killed, then a totalMod value of 1 would require only 1 of those creatures to be killed.

If MYTHIC_OBJECTIVES_BOSS is enabled alongside the enemy forces objective requirement, then players must also kill all bosses within the dungeon. Players are sent skulls indicating the names and progress of these bosses. This requirement is in addition to the forces and time requirements.
Winning a Keystone

Once all victory conditions have been met, players are then given their own keystone. If the dungeon is beat within the time limit, the keystone increments by KEYSTONE_LEVEL_STEP levels. So if the value were 1, then the key would increment by 1 level for finishing the victory conditions.

If the dungeon is beat with excess time leftover, the total duration of that dungeon is divided by KEYSTONE_LEVEL_BONUS_FACTOR. These are considered “time chunks” which will be used in applying bonuses for additional time. For example, if your time limit is 300 and your factor is 4, then the time chunks would be a length of 75 seconds each. 

Each time chunk that can be filled with the leftover time, KEYSTONE_LEVEL_BONUS is added to the new keystone’s level. For example, if you finish a dungeon with 154 seconds remaining in the above context, you will have completed 2 time chunks in addition to the base completion of the key. If the level bonus were to be 1 in this case, then the new Keystone’s level would have an additional 3 levels - 1 from completing the key in time, and 2 from bonus time chunks.

If players in the group already own a keystone, they are offered a chance to take a new key for free. This replaces their previous key, if any existed to begin with. If players do not like the keystone they are offered, players can continue with rerolling their keystone as explained in the next section.
Rerolling a Keystone

Every keystone generation that offers a new keystone also provides the option to reroll the keystone. The cost of rerolling a keystone can be money (REPICK_COST), an item (REPICK_ITEM , REPICK_ITEM_QUANTITY), or both options. 

When REPICK_MOD_LEVEL is set to a value greater than 0, the cost of the keystone is multiplied by the REPICK_MOD_LEVEL value of its own level. For example, if the level mod is set to 1, then the added cost is going to be the level of that keystone. 

If REPICK_MOD_STACKING is set to a value greater than 0, then repicking a keystone adds a stacking cost based on the amount of rerolls performed by the player in that session. For example, if a player has performed three rerolls and the original cost is 5 money, then a REPICK_MOD_STACKING of 1 would make the 4th roll cost 9 money.

Players can reroll their keystone to a maximum of REPICK_MAX times per reroll session.
Technical Breakdown
Here’s a brief explanation of nerd shit.

The server starts and loads all the aforementioned information in a cache. On player login, the server sends the cache. The players should be able to tooltip over the items by this point with the cached data and read them properly. Players can now enter any zero dungeon, in which the server will send an “on” state to a zero kill switch. Players progress an invisible boss progression and on completion, are rewarded with a keystone. On placing a keystone the affix information and keystone information is provided. On starting it, players are teleported and a switch is turned to “on” state for mythic kill tracking and the zero kill switch is turned “off”. Player kills are now sent to the server and ask for progression updates in relation to the mythic data. This switch also is fired on target swapping, which determines if the target needs affixes applied or not. Because there is no native way to grab all dungeon creatures, this was the best temporary solution I could find - the creatures are compared to a local array and if they are not buffed and are not in said array, then insert and tell the server to buff that creature.
