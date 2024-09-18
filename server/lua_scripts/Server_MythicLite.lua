-- INSERT INTO `gameobject_template` VALUES (1000100, 2, 6964, 'Altar of Mythical Challenge', '', '', '', 2, 0, 0, 0, 10219, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartGameObjectAI', '', 12340);

local AIO = AIO or require("AIO")
local MythicLiteHandlers = AIO.AddHandlers("Mythic_Lite", {})

local MYTHIC_ZERO_NORMAL = true -- determines if a zero key can be generated from a normal dungeon
local MYTHIC_ZERO_HEROIC = true -- determines if a zero key can be generated from a heroic dungeon

local MYTHIC_NORMAL = true -- determines if a key can level from a normal dungeon
local MYTHIC_HEROIC = true -- determines if a key can level from a heroic dungeon

local KEYSTONE_LEVEL_STEP = 1 -- how many levels a new key will be above the previous key
local KEYSTONE_LEVEL_BONUS = 1 -- how many levels are gained in addition to the level step when finishing a mythic dungeon within the requirements for a bonus. a bonus is determined by dungeon length in relation to the timer.
local KEYSTONE_LEVEL_BONUS_FACTOR = 4 -- this determines the factor that the base objective is divided by in order to be considered a bonus. so lets say the duration for a dungeon is 300 seconds, a factor of 2 would divide 300 by 2. if the player finishes the dungeon in 150 seconds or less, they get a bonus level.

local MYTHIC_PEDESTAL = 1000100
local MYTHIC_KEYSTONE = 1899980
local MYTHIC_SPHERE = 1000003 -- gameobject ID of the sphere that keeps the players inside for 5 seconds -- INSERT INTO `gameobject_template` VALUES (1000003, 5, 7203, 'Forcefield 000', '', '', '', 0.1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
local MYTHIC_START_TIMER = 11 -- how long in seconds the sphere will last before despawning and the mythic dungeon is started. we do 6 seconds instead of 5, otherwise the timer the client receives would start too early for the client to see "5" seconds.
local RBAC_LVL = 3 -- the security level required for the GM commands

local MYTHIC_OBJECTIVES_BOSS = 1 -- 1 = true, 0 = false. determines if bosses are required for the mythic dungeon. requires MYTHIC_OBJECTIVES_ENEMY_FORCES = 1.
-- ^ actually, needs to always be 1 because we are requiring bosses for the zero mythic dungeons.
local MYTHIC_OBJECTIVES_ENEMY_FORCES = 1 -- 1 = true, 0 = false. determines if the force requirement is enabled or not.

local function MythicLite_OnGameObjectUse(event, object, player)
	if (object:GetEntry() == MYTHIC_PEDESTAL) then
		player:SendBroadcastMessage("You have used the Altar of Mythical Challenge.")
		AIO.Handle(player, "Mythic_Lite", "CloseFrame") -- close frames if they were opened
		AIO.Handle(player, "Mythic_Lite", "OpenFrame")
		return
	end
end

RegisterGameObjectEvent(MYTHIC_PEDESTAL, 14, MythicLite_OnGameObjectUse)

local AFFIX_POOL_SIZE = 9 -- how many affixes are in the pool
local AFFIX_RESET_TIMER = 604800 --604800 -- 1 week in seconds
local AFFIX_STEP = 3 -- after how many levels the possible affixes increase
local AFFIX_STEP_AMOUNT = 1 -- how many affixes you would like per step
local AFFIX_BASE = 7 -- how many affixes every keystone starts with

local REPICK_COST = 1000 -- how much it costs to repick a keystone in currency
local REPICK_ITEM = 0 -- the item required to repick a keystone
local REPICK_ITEM_QUANTITY = 1 -- how many of the item is required to repick a keystone
local REPICK_MAX = 3 -- how many times one keystone can be rerolled / repicked
local REPICK_MOD_LEVEL = 1 -- the cost modifier for both currency and item quantity based on the keystones item level
local REPICK_MOD_STACKING = 1 -- the cost modifier for both currency and item quantity based on the amount of times the keystone has been rerolled / repicked. 0 = no stacking costs. 1 = a stacking cost rate of 1.0. ie (1000 * 1) + the_last_cost = new_cost

-- make databse structure
-- load it on server start into a cache
-- tables:
-- eluna_mythiclite_template
-- mapID, lastBossID, timelimit, totalMobs, totalMod, dungeonName
-- eluna_mythiclite_affixes_template
-- spellID, base_stack, stack_per_level
-- eluna_mythiclite_affixes_pool
-- affix
-- eluna_counters (val1, val2, script_name) = (timestamp, 0, "MythicLite.lua - Affix Weekly")
-- AFFIX_RESET_TIMER = 604800
-- eluna_mythiclite_keystones
-- itemGUID, playerGUID, mythicLevel, mapID, affixString, timestamp, progress, instanceID, lastboss
--[[
Affix String will be our "list" of affixes, since from my understanding we want a range from 0 to Z amount of affixes.
The timestamp will be when we start the mythic dungeon, used later.
The progress will be when we determine how far a mythic has progressed, used later. This is determined in a percentage 0-100.
[6:44 PM]grimreapaa: DungeonID will be the ID of the dungeon that keystone will be consumed in. Used later.
lastboss is a boolean, a yes/no. A true or false if the lastboss of the mythic has been killed. Used later.
]]

--[[ -- query that grabs very specific GUIDs. from here we can register all pre-spawned and known creatures to the unique event.
-- this list will need to be stored and accessible somewhere so it can be manually adjusted if ever needed.
SELECT c.guid, c.map
FROM fun_world.creature c
INNER JOIN fun_world.eluna_mythiclite_template emt
ON c.map = emt.mapID
INNER JOIN fun_world.creature_template ct
ON c.id1 = ct.entry
WHERE ct.faction NOT IN (35, 31);
]]

local DUMMY_SPELL = 3000032 -- the dummy spell we will use to ignore creatures that are parsed for the progression checks.

client_progress_cache = {} -- the client-side needs info for the UI to be displayed properly. this is the object that holds that info and is sent to the client. client_progress_cache[player:GetDBTableGUIDLow()] = {name of the dungeon related to the keystone, timelimit from mythic template, progress, affixstring, keystone_level}

function generateUniqueRolls(count, maxValue)
	-- Example usage
	--[[
	local count = 5
	local maxValue = 10
	local uniqueRolls = generateUniqueRolls(count, maxValue)
	
	for i = 1, #uniqueRolls do
	    print("Roll " .. i .. ": " .. uniqueRolls[i])
	end
	]]


    local rolls = {}
    
    -- Function to check if a value is in the array
    local function contains(array, value)
        for i = 1, #array do
            if array[i] == value then
                return true
            end
        end
        return false
    end
    
    -- Function to generate unique rolls
    local function rollUniqueValues()
        for i = 1, count do
            local roll
            repeat
                roll = math.random(1, maxValue)
            until not contains(rolls, roll) -- Ensure the roll is unique
            rolls[i] = roll
        end
    end
    
    -- Roll initial values
    rollUniqueValues()
    
    -- Check for duplicates and reroll if any are found
    local function rerollDuplicates()
        local unique = true
        for i = 1, count do
            for j = i + 1, count do
                if rolls[i] == rolls[j] then
                    rolls[j] = math.random(1, maxValue)
                    unique = false
                end
            end
        end
        if not unique then
            rerollDuplicates()
        end
    end
    
    -- Initial check and reroll if needed
    rerollDuplicates()
    
    return rolls
end

local function AffixCheck()
	-- compare timestamp to affix timestamp variable and print if greater, meaning we should generate new affixes
	local current_time = os.time()
	if (current_time - mythiclite_affix_timestamp >= AFFIX_RESET_TIMER) then
		-- remove all affixes from the pool
		WorldDBQuery("DELETE FROM eluna_mythiclite_affixes_pool;")
		mythiclite_affixes_pool = {}
		-- generate new affixes
		local uniqueRolls = generateUniqueRolls(AFFIX_POOL_SIZE, #mythiclite_affixes_template)
		for i = 1, #uniqueRolls do
			local affixID = mythiclite_affixes_template[uniqueRolls[i]][1]
			WorldDBQuery("INSERT INTO eluna_mythiclite_affixes_pool (spellID) VALUES ("..affixID..");")
			mythiclite_affixes_pool[i] = affixID
			print("Generated affix : " .. affixID)
		end

		local temp_affixes = {}
		print("MythicLite.lua - Affix Weekly timestamp: ", "Generating new affixes")
		WorldDBQuery("UPDATE eluna_counters SET `value_1` = "..current_time.." WHERE script_name = 'Server_MythicLite.lua';")
		print("Affixes made.")
	end
end

local function Cache_Data()
	mythiclite_template = {}
	mythiclite_affixes_template = {}
	mythiclite_affixes_pool = {}
	mythiclite_keystones = {}
	mythiclite_affix_timestamp = 0
	mythiclite_teleport = {}
	mythiclite_template_mobs = {}
	mythiclite_template_bosses = {}
	mythiclite_progress = {}
	mythiclite_records = {}
	wip_affixes_template = {} -- a wip cache object that is slowly phasing out the current template object.

	print("[MythicLite.lua] Performing cache generation of data . . .")
	local query = WorldDBQuery("SELECT * FROM eluna_mythiclite_template;") -- cache the dungeon templates. mythiclite_template[x] = {mapID, lastBossID, timelimit, totalMod, dungeonName}
	if query then
		print("[MythicLite.lua] Caching mythic dungeon templates . . .")
		for x=1,query:GetRowCount(),1 do
			local mapID = query:GetInt32(0)
		--	local lastBossID = query:GetUInt32(1)
			local timelimit = query:GetInt32(1)
		--	local totalMobs = query:GetUInt32(3)
			local totalMod = query:GetInt32(2)
			local dungeonName = query:GetString(3)
			-- mythiclite_template[x] = {mapID, timelimit, totalMod, dungeonName}
			mythiclite_template[x] = {mapID, timelimit, 0, totalMod, dungeonName}
			query:NextRow()
		end
		-- print the cache
		
		for k,v in pairs(mythiclite_template) do
			--print(k, v[1], v[2], v[3], v[4], v[5], v[6])
			print("MapID: " .. v[1], "Timelimit: " .. v[2], "TotalMod: " .. v[4], "DungeonName: " .. v[5])
		end
		
		-- print the total amount of dungeons cached
		print("[MythicLite.lua] Total dungeon templates cached: " .. #mythiclite_template)
	else
		print("[MythicLite.lua] No mythic dungeon templates found. Cannot continue.")
		return
	end
	query = WorldDBQuery("SELECT * FROM eluna_mythiclite_affixes_template;") -- cache the affix templates
	if query then
		for x=1,query:GetRowCount(),1 do
			local spellID = query:GetUInt32(0)
			local base_stack = query:GetUInt32(1)
			local stack_per_level = query:GetUInt32(2)
			mythiclite_affixes_template[x] = {spellID, base_stack, stack_per_level}
			
			if (wip_affixes_template[spellID] == nil) then
				wip_affixes_template[spellID] = {}
			end

			wip_affixes_template[spellID]["base_stacks"] = base_stack
			wip_affixes_template[spellID]["stacks_per_level"] = stack_per_level
			
			query:NextRow()
		end
		-- print the cache
		--[[
		for k,v in pairs(mythiclite_affixes_template) do
			print(k, v[1], v[2])
		end
		]]
		-- print the total amount of affixes cached
		print("[MythicLite.lua] Total affix templates cached: " .. #mythiclite_affixes_template)
	else
		print("[MythicLite.lua] No affix templates found. Cannot continue.")
		return
	end
	query = WorldDBQuery("SELECT * FROM eluna_mythiclite_affixes_pool;") -- cache affix pool
	if query then
		for x=1,query:GetRowCount(),1 do
			local affix = query:GetUInt32(0)
			mythiclite_affixes_pool[x] = affix
			query:NextRow()
		end
		-- print the cache
		--[[
		for k,v in pairs(mythiclite_affixes_pool) do
			print(k, v)
		end
		]]
		-- print a string. <Total amount of affixes> : <affixID1>, <affixID2>, <affixID3> ...
		local temp_affixes = ""
		for k,v in pairs(mythiclite_affixes_pool) do
			temp_affixes = temp_affixes .. v .. ", "
		end
		print("[MythicLite.lua] Affixes cached for the current pool: " .. #mythiclite_affixes_pool .. " : " .. temp_affixes)
	else
		print("[MythicLite.lua] No affix pool found. This is okay. We will generate new affixes after the server starts.")
	end
	query = WorldDBQuery("SELECT * FROM eluna_mythiclite_keystones;") -- cache keystone data
	if query then
		print("[MythicLite.lua] Caching keystone data . . .")
		for x=1,query:GetRowCount(),1 do
			local itemGUID = query:GetUInt32(0)
			local playerGUID = query:GetUInt32(1)
			local mythicLevel = query:GetUInt32(2)
			local mapID = query:GetUInt32(3)
			local affixString = query:GetString(4)
			local timestamp = query:GetUInt32(5)
			local progress = query:GetUInt32(6)
			local instanceID = query:GetUInt32(7)
			local bosses = query:GetUInt32(8)
			mythiclite_keystones[itemGUID] = {playerGUID, mythicLevel, mapID, affixString, timestamp, progress, instanceID, bosses}
			query:NextRow()
		end
		-- print the cache
		--[[
		for k,v in pairs(mythiclite_keystones) do
			print(k, v[1], v[2], v[3], v[4], v[5], v[6], v[7], v[8])
		end
		]]
		-- print total keystones cached
		print("[MythicLite.lua] Total keystones cached: " .. #mythiclite_keystones)
	else
		print("[MythicLite.lua] No keystone data found. This is okay. We will generate keystones as players finish valid dungeons.")
	end
	-- cache the teleport data relevant to the dungeon data. this is stored in areatrigger_teleport
	-- INSERT INTO `areatrigger_teleport` VALUES (45, 'Scarlet Monastery - Graveyard (Entrance)', 189, 1688.99, 1053.48, 18.6775, 0.00117); example data piece
	query = WorldDBQuery("SELECT * FROM areatrigger_teleport;") -- cache teleport data. this indicates where players start in relation to the mapID when a mythic dungeon starts.
	if query then
		print("[MythicLite.lua] Caching teleport data . . .")
		for x=1,query:GetRowCount(),1 do
			local id = query:GetUInt32(0)
			local name = query:GetString(1)
			local mapID = query:GetUInt32(2)
			local x = query:GetFloat(3)
			local y = query:GetFloat(4)
			local z = query:GetFloat(5)
			local o = query:GetFloat(6)
			mythiclite_teleport[mapID] = {name, mapID, x, y, z, o}
			query:NextRow()
		end
		-- print the cache
		--for k,v in pairs(mythiclite_teleport) do
		--	print(k, v[1], v[2], v[3], v[4], v[5], v[6])
		--end
		print("[MythicLite.lua] Total teleport data cached: " .. #mythiclite_teleport) -- print the total amount of teleports cached
	else
		print("[MythicLite.lua] No teleport data found. Cannot continue.")
		return
	end
	query = WorldDBQuery("SELECT value_1 FROM eluna_counters WHERE script_name = 'Server_MythicLite.lua';") -- cache the timestamp relevant to the script
	if query then
		mythiclite_affix_timestamp = query:GetUInt32(0)
		print("[MythicLite.lua] Affix Weekly timestamp: ", mythiclite_affix_timestamp)
	else -- make a new timestamp and cache that
		mythiclite_affix_timestamp = os.time()
		WorldDBQuery("INSERT INTO eluna_counters (value_1, value_2, script_name) VALUES ("..mythiclite_affix_timestamp..", 0, 'Server_MythicLite.lua');")
		print("[MythicLite.lua] NEW Affix Weekly timestamp: ", mythiclite_affix_timestamp)
	end
	-- cache the dbtableguidlows of the creatures because we will need that to track the progression
	-- the following query produces dbtableguidlow results for all hostiles creatures on any maps listed in mythiclite_template, excluding faction 35 and 31 (friendly / neutral(passive)).
	-- query = WorldDBQuery("SELECT c.guid, c.map FROM fun_world.creature c INNER JOIN fun_world.eluna_mythiclite_template emt ON c.map = emt.mapID INNER JOIN fun_world.creature_template ct ON c.id1 = ct.entry WHERE ct.faction NOT IN (35, 31);")
	print("[MythicLite.Lua] Caching enemy forces data...")
	query = WorldDBQuery("SELECT `guid`, `mapID` FROM fun_world.eluna_mythiclite_template_mobs;")
	if query then -- local mythiclite_template_mobs = [mapID] = {guid1, guid2, guid3, ...}
		for x=1,query:GetRowCount(),1 do
			local guid = query:GetUInt32(0)
			local mapID = query:GetUInt32(1)
			if (mythiclite_template_mobs[mapID] == nil) then
				mythiclite_template_mobs[mapID] = {}
			end
			table.insert(mythiclite_template_mobs[mapID], guid)
			query:NextRow()
		end
		-- print the amount of mobs cached and the amount of dungeons separately
		print("[MythicLite.Lua] Collating mob data...")
		for k,v in pairs(mythiclite_template_mobs) do
			print("MapID:" .. k, "Mobs:" .. #v)
		end
		print("[MythicLite.Lua] Mob data cached.")
	else
		print("[MythicLite.Lua] No mob data found. We can continue, but enemy forces objectives will be disabled.")
	end
	-- cache bosses query
	--[[
	SELECT 
    c.guid AS CreatureGUID, 
	c.map AS CreatureMap,
    c.id1 AS CreatureEntry, 
    ct.name AS CreatureName
FROM 
    creature c
JOIN 
    creature_template ct ON c.id1 = ct.entry
WHERE 
    c.guid IN (list_of_monsters)
AND (
    (ct.mechanic_immune_mask & (1 << 1)) != 0
    OR (ct.mechanic_immune_mask & (1 << 5)) != 0
    OR (ct.mechanic_immune_mask & (1 << 7)) != 0
    OR ct.rank = 3
);]]
	print("[MythicLite.Lua] Caching boss data...")
	if mythiclite_template_mobs == nil then -- check if mob data nil
		print("[MythicLite.Lua] No mob data found. We can continue, but boss objectives will be disabled.")
	end

	local query_string = ""
	for k,v in pairs(mythiclite_template_mobs) do
		for i = 1, #v do
			if i == #v then -- do not leave a trailing comma
				query_string = query_string .. v[i]
			else
				query_string = query_string .. v[i] .. ", "
			end
		end
	end

	--local query = "SELECT c.guid AS CreatureGUID, c.map AS CreatureMap FROM creature c JOIN creature_template ct ON c.id1 = ct.entry WHERE c.guid IN (" ..query_string .. ") AND ((ct.mechanic_immune_mask & (1 << 1)) != 0 OR (ct.mechanic_immune_mask & (1 << 5)) != 0 OR (ct.mechanic_immune_mask & (1 << 7)) != 0 OR ct.rank = 3);"
	query = WorldDBQuery("SELECT c.guid AS CreatureGUID, c.map AS CreatureMap, ct.name AS CreatureName FROM creature c JOIN creature_template ct ON c.id1 = ct.entry WHERE c.guid IN (" ..query_string .. ") AND ((ct.mechanic_immune_mask & (1 << 1)) != 0 OR (ct.mechanic_immune_mask & (1 << 5)) != 0 OR (ct.mechanic_immune_mask & (1 << 7)) != 0 OR ct.rank = 3);")
	if query then -- cache the bosses
		for x=1,query:GetRowCount(),1 do -- mythiclite_template_bosses[mapID] = ["IDs"] = {GUID1, GUID2, GUID3...}, ["Names"] = {Name1, Name2, Name3...}
			local guid = query:GetUInt32(0)
			local mapID = query:GetUInt32(1)
			local name = query:GetString(2)
			if (mythiclite_template_bosses[mapID] == nil) then
				mythiclite_template_bosses[mapID] = {}
			end
			if (mythiclite_template_bosses[mapID]["IDs"] == nil) then
				mythiclite_template_bosses[mapID]["IDs"] = {}
			end
			if (mythiclite_template_bosses[mapID]["Names"] == nil) then
				mythiclite_template_bosses[mapID]["Names"] = {}
			end
			-- if (mythiclite_template_bosses[mapID]["Alive"] == nil) then
			-- 	mythiclite_template_bosses[mapID]["Alive"] = {}
			-- end
			table.insert(mythiclite_template_bosses[mapID]["IDs"], guid)
			table.insert(mythiclite_template_bosses[mapID]["Names"], name)
			--table.insert(mythiclite_template_bosses[mapID]["Alive"], true)
			query:NextRow()
		end
		-- print the amount of bosses cached to which dungeon separately
		print("[MythicLite.Lua] Collating boss data...")
		for k,v in pairs(mythiclite_template_bosses) do
			print("MapID:" .. k, "Bosses:" .. #v["IDs"])
		end
		print("[MythicLite.Lua] Boss data cached.")
	else
		print("[MythicLite.Lua] No boss data found. We can continue, but boss objectives will be disabled. Error Version 2.")
	end
	query = WorldDBQuery("SELECT creatureGUID, instanceID FROM eluna_mythiclite_progress;") -- cache the creature kills of the keystone
	if query then -- mythiclite_progress = [instanceID] = {creatureGUID, creatureGUID2, creatureGUID3 ..}
		print("[MythicLite.Lua] Caching progress data...")
		for x=1,query:GetRowCount(),1 do
			local creatureGUID = query:GetUInt32(0)
			local instanceID = query:GetUInt32(1)
			if (mythiclite_progress[instanceID] == nil) then
				mythiclite_progress[instanceID] = {}
			end
			table.insert(mythiclite_progress[instanceID], creatureGUID)
			query:NextRow()
		end
		-- print the amount of mobs cached and the amount of dungeons separately
		print("[MythicLite.Lua] Collating progress data...")
		for k,v in pairs(mythiclite_progress) do
			print("InstanceID:" .. k, "Progress:" .. #v)
		end
		print("[MythicLite.Lua] Progress data cached.")
	else
		print("[MythicLite.Lua] No progress data found. We can continue as progress data will generate on keystone use.")
	end
	query = WorldDBQuery("SELECT * FROM eluna_mythiclite_records;") -- cache the records of completed mythic dungeons
	if query then
		print("[MythicLite.lua] Caching available records . . .")
		for x=1,query:GetRowCount(),1 do
			local itemGUID = query:GetUInt32(0)
			local mythicLevel = query:GetUInt32(1)
			local mapID = query:GetUInt32(2)
			local duration = query:GetUInt32(3)
			local affixString = query:GetUInt32(4)
			local player1 = query:GetUInt32(5)
			local player2 = query:GetUInt32(6)
			local player3 = query:GetUInt32(7)
			local player4 = query:GetUInt32(8)
			local player5 = query:GetUInt32(9)
			mythiclite_records[itemGUID] = {mythicLevel, mapID, duration, affixString, player1, player2, player3, player4, player5}
			query:NextRow()
		end
		-- print the cache
		--[[
		for k,v in pairs(mythiclite_records) do
			print(k, v[1], v[2], v[3], v[4], v[5], v[6], v[7], v[8], v[9])
		end
		]]
		-- print total records cached
		print("[MythicLite.lua] Total records cached: " .. #mythiclite_records)
	else
		print("[MythicLite.lua] No records of completed mythic dungeons. This is okay. We will generate records as players finish valid dungeons.")
	end

	-- register a looping event here to check the affix status and if it needs to be generated again or not
	CreateLuaEvent( AffixCheck, 5000 , 0) -- perform the check every X seconds
	print("[MythicLite.lua] Cache generation complete.")
end

-- now with the data cached and affixes are generated, we can work on the keystone generation function
local function generateKeystone(player)
	-- check to see if the player already has a keystone item or an entry in the keystone cache
	if player:HasItem(MYTHIC_KEYSTONE) then
		player:SendBroadcastMessage("You already have a Mythic Keystone.")
		AIO.Handle(player, "Mythic_Lite", "POPUP_REROLL")
		return
	end

	-- check to see if the player has a keystone in progress or not via instanceID and playerGUID
	for k,v in pairs(mythiclite_keystones) do
		if v[1] == player:GetGUIDLow() then
			player:SendBroadcastMessage("You already have a Mythic Keystone.")
			AIO.Handle(player, "Mythic_Lite", "POPUP_REROLL")
			return
		end

		if v[7] == player:GetInstanceId() then
			player:SendBroadcastMessage("This instance already has a Mythic Keystone active.")
			return
		end

		if v[7] ~= 0 then
			player:SendBroadcastMessage("This keystone is still in progress elsewhere.")
			AIO.Handle(player, "Mythic_Lite", "POPUP_REROLL")
			return
		end
	end

	player:AddItem(MYTHIC_KEYSTONE, 1)
	-- generate the dungeon for the keystone
	local dungeon = math.random(1, #mythiclite_template)
	local dungeon = mythiclite_template[dungeon][1]
	local affix_string = ""
	local mythiclevel = 0

	-- generate unique rolls here to get unique affixes for the keystone
	-- determine how many affixes the keystone will have based on the affix steps and the mythic keystone level. always add 1 to affixes.
	local how_many_affixes = math.floor(mythiclevel / AFFIX_STEP) * AFFIX_STEP_AMOUNT
	how_many_affixes = how_many_affixes + AFFIX_BASE

	local uniqueRolls = generateUniqueRolls(how_many_affixes, #mythiclite_affixes_pool)
	for i = 1, #uniqueRolls do
		affix_string = affix_string .. mythiclite_affixes_pool[uniqueRolls[i]] .. " "
	end
	-- get the item GUID of the keystone
	local item = player:GetItemByEntry(MYTHIC_KEYSTONE)
	local item = item:GetGUIDLow()
	WorldDBQuery("INSERT INTO eluna_mythiclite_keystones (itemGUID, playerGUID, mythicLevel, mapID, affixString, timestamp, progress, instanceID, bosses) VALUES ("..item..", "..player:GetGUIDLow()..", " ..mythiclevel.. ", "..dungeon..", '"..affix_string.."', 0, 0, 0, 0);")
	-- mythiclite_keystones[itemGUID] = {playerGUID, mythicLevel, mapID, affixString, timestamp, progress, instanceID, bosses}
	mythiclite_keystones[item] = {player:GetGUIDLow(), mythiclevel, dungeon, affix_string, 0, 0, 0, 0}
	player:SendBroadcastMessage("You have received a Mythic Keystone.")
end

-- make a command that performs ggeneratekeystone on the target
local function GenerateKeystoneCommand(event, player, command)
	if (command == "generatekeystone") then
		generateKeystone(player)
		return false
	end
end

local function GenerateCacheCommand(event, player, command)
	if (command == "generatecache") then
		Cache_Data()
		player:SendBroadcastMessage("[MythicLite.lua] Cache has been re-generated.")
		return false
	end
end

RegisterPlayerEvent(42, GenerateCacheCommand)
RegisterPlayerEvent(42, GenerateKeystoneCommand)

Cache_Data()

-- make an aio function that accepts a request for keystone information based on the itemguid?

-- on mythic keystone right-click, generate an appended item link to send to the player.

local function keystoneOnUse(event, player, item, target)
	-- generate the item link and append it with related information and send the link
	local itemGUID = item:GetGUIDLow()
	local keystone = mythiclite_keystones[itemGUID]
	local keystoneLevel = keystone[2]
	local keystoneMap = keystone[3]
	local keystoneAffixes = keystone[4]
	local link = item:GetItemLink( 0 )
	-- break up the chat hyperlink so we can properly append it
	-- |cffffffff|Hitem:1899980:0:0:0:0:0:0:0:53|h[Mythic Keystone]|h|r
	-- theres no way to set the description????
	-- uniqueID is before the level 53?
	-- insert itemGUID and send new link to player
	-- local newLink = "|cffffffff|Hitem:1899980:0:0:0:0:0:0:0:"..itemGUID.."|h[Mythic Keystone]|h|r"
	local newLink = "|cffffffff|Hitem:1899980:0:0:0:0:0:0:" .. itemGUID .. ":0|h[Mythic Keystone]|h|r"
	-- player:SendBroadcastMessage("Keystone Level: " .. keystoneLevel .. " Dungeon: " .. keystoneMap .. " Affixes: " .. keystoneAffixes .. " ItemGUID: " .. itemGUID)
	print(newLink)
	player:SendBroadcastMessage("Keystone Link: " .. newLink)
end

RegisterItemEvent(MYTHIC_KEYSTONE, 2, keystoneOnUse)

-- on player login, send keystone cache
local function keystoneOnLogin(event, player)
	local playerGUID = player:GetGUIDLow()
	-- mythiclite_keystones[itemGUID] = {playerGUID, mythicLevel, mapID, affixString, timestamp, progress, instanceID, bosses}
	-- construct a table object to send that is exclusiely the keystone information of the player
	local playerKeystone = {}
	for k,v in pairs(mythiclite_keystones) do
		if (v[1] == playerGUID) then
			playerKeystone = v
		end
	end
	AIO.Handle(player, "Mythic_Lite", "ReceiveKeystones", mythiclite_keystones)
	AIO.Handle(player, "Mythic_Lite", "ReceiveMyKeystone", playerKeystone)
	AIO.Handle(player, "Mythic_Lite", "ReceiveAffixStacks", mythiclite_affixes_template)
end



local function UniqueEvent() -- the event triggered by RegisterUniqueCreatureEvent. on death, update the progress to +1 of that keystone.

end

local function MythicStart_TimerInit(eventid, delay, repeats, player)
	local orb = player:SummonGameObject( MYTHIC_SPHERE, player:GetX(), player:GetY(), player:GetZ(), player:GetO(), MYTHIC_START_TIMER )
end

local function MythicStart_ProgressSwitch(eventid, delay, repeats, player)
	AIO.Handle(player, "Mythic_Lite", "Prog_Switch", "on")
	AIO.Handle(player, "Mythic_Lite", "Zero_Switch", "off")
end

function MythicLiteHandlers.MythicStart(player)

	local target_keystone = player:GetItemByEntry(MYTHIC_KEYSTONE) -- get the keystone information
	local target_keystone = target_keystone:GetGUIDLow()

	if player:GetMapId() ~= mythiclite_keystones[target_keystone][3] then -- is the player in the same dungeon as the keystone is required to be in?
		player:SendBroadcastMessage("[MythicLite] You are not in the correct dungeon to start this keystone.")
		return
	end

	WorldDBQuery("UPDATE eluna_mythiclite_keystones SET timestamp = "..os.time()..", instanceID = " ..player:GetInstanceId().. " WHERE playerGUID = "..player:GetGUIDLow()..";")
	-- update the player keystone in the server-side cache, mythiclite_keystsones[itemGUID] = {playerGUID, mythicLevel, mapID, affixString, timestamp, progress, instanceID, lastboss}
	mythiclite_keystones[target_keystone][5] = os.time() -- update the mythiclite_keystsones[target_keystone] entry to have player:GetInstanceId()
	mythiclite_keystones[target_keystone][7] = player:GetInstanceId() -- update the mythiclite_keystones[target_keystone] entry to have timestamp = os.time()

	local keystoneInfo = mythiclite_keystones[target_keystone] -- get the keystone information


	-- are the group members inside the same instance/dungeon as the player?

	local teleportInfo = mythiclite_teleport[keystoneInfo[3]] -- get the teleport info
	local group = player:GetGroup()
	if group then -- perform loop on group if exists
		for i = 1, group:GetMemberCount() , 1 do
			local member = group:GetMember(i)
			if member:GetMapId() == player:GetMapId() then
				AIO.Handle(player, "Mythic_Lite", "StartTimer", MYTHIC_START_TIMER)
				AIO.Handle(member, "Mythic_Lite", "CloseFrame") -- force close the ui for all members as well
				member:RegisterEvent(MythicStart_ProgressSwitch, MYTHIC_START_TIMER * 1000 )
				member:Teleport(teleportInfo[2], teleportInfo[3], teleportInfo[4], teleportInfo[5], teleportInfo[6])
			end
		end
	else -- otherwise it is only 1 player, perform player handling.
		AIO.Handle(player, "Mythic_Lite", "StartTimer", MYTHIC_START_TIMER)
		AIO.Handle(player, "Mythic_Lite", "CloseFrame") -- force close the ui for the player
		player:RegisterEvent(MythicStart_ProgressSwitch, MYTHIC_START_TIMER * 1000 )
		player:Teleport(teleportInfo[2], teleportInfo[3], teleportInfo[4], teleportInfo[5], teleportInfo[6])
	end

	player:RegisterEvent(MythicStart_TimerInit, 1000 ) -- spawn the forcefield orb
	player:RemoveItem(player:GetItemByEntry(MYTHIC_KEYSTONE), 1) -- eat the keystone
end

local zerokill_cache = {}
function MythicLiteHandlers.ZeroKill(player) -- any player is sending this when a unit dies in their combat log
	print("zerokill performed")

	-- check units nearby if they match a guid in the bosses_template table.
	local creatures = player:GetCreaturesInRange(25, 0, 1, 2)
	local instanceID = player:GetInstanceId()
	for i = 1, #creatures do
		local creature = creatures[i]
		local creatureGUID = creature:GetDBTableGUIDLow()

		print('looking in template')
		--loop through boss template and decide if the creature is in the template or not
		local found_in_template = false
		for k,v in pairs(mythiclite_template_bosses[player:GetMapId()]["IDs"]) do
			if (v == creatureGUID) then
				found_in_template = true
				print('found in template')
			end
		end
		print('template search done')

		-- loop through and decide if the creature has been added to the cache table already or not
		local found_in_zerokill = false
		print('looking in zerokill')
		-- check if zerokill cache is nil before looping trhough it
		if zerokill_cache[instanceID] == nil then
			zerokill_cache[instanceID] = {}
		end

		for k,v in pairs(zerokill_cache[instanceID]) do
			if (v == creatureGUID) then
				found_in_zerokill = true
				print('found in zerokill')
			end
		end
		print('zerokill search done')

		if not found_in_zerokill and found_in_template then
			print("going")
			for k,v in pairs(mythiclite_template_bosses[player:GetMapId()]["IDs"]) do
				print("gonnnng")
				if (v == creatureGUID) then
					if zerokill_cache[instanceID] == nil then
						zerokill_cache[instanceID] = {}
					end

					table.insert(zerokill_cache[instanceID], creatureGUID) -- store the killed bosses of this dungeon in a cache
					print("zerokill boss inserted")
				end
			end
		end
	end

	-- check if the killed bosses, zerokill_cache, meets the length of the boss templates for this dungeon.
	local total_bosses = #mythiclite_template_bosses[player:GetMapId()]["IDs"]
	local current_bosses = 0
	if (zerokill_cache[instanceID] ~= nil) then
		current_bosses = #zerokill_cache[instanceID]
	end

	print(current_bosses)
	print(total_bosses)
	if current_bosses == total_bosses then
		print("zerokill victory")
		-- victory
		player:SendBroadcastMessage("[MythicLite] You have completed the ZERO dungeon.")

		-- check if key, if not generate keystone
		local key = player:GetItemByEntry(MYTHIC_KEYSTONE)
		if key then
			player:SendBroadcastMessage("[MythicLite] You have a keystone.")
			AIO.Handle(player, "Mythic_Lite", "POPUP_REROLL")
		else
			generateKeystone(player)
		end

		zerokill_cache[instanceID] = nil -- clear the cache

		-- switch zerokill switch to "off" state
		AIO.Handle(player, "Mythic_Lite", "Zero_Switch", "off")
	end
end


function MythicLiteHandlers.MythicKill(player) -- any player is sending this when a unit dies in their combat log and a player has started a mythic dungeon
	-- check for nearby units that are not yet included in the mythiclite_progress[instanceID] table.
	-- if the creature is in the mythiclite_template_mobs[mapID] table, add it to the mythiclite_progress[instanceID] table.
	-- if the creature is the last boss, set the lastboss value of the keystone to true.

	local creatures = player:GetCreaturesInRange(25, 0, 1, 2)
	local instanceID = player:GetInstanceId()
	local mapID = player:GetMapId()
	if (mythiclite_progress[instanceID] == nil) then
		mythiclite_progress[instanceID] = {0}
	end

	for i = 1, #creatures do
		local creature = creatures[i]
		local creatureGUID = creature:GetDBTableGUIDLow()

		--loop through and decide if the creature is in the template or not
		local found_in_template = false
		for k,v in pairs(mythiclite_template_mobs[mapID]) do
			if (v == creatureGUID) then
				found_in_template = true
			end
		end

		-- loop through and decide if the creature has been added to the progress table already or not
		local found_in_progress = false
		for k,v in pairs(mythiclite_progress[instanceID]) do
			if (v == creatureGUID) then
				found_in_progress = true
			end
		end

		if not found_in_progress and found_in_template then
			table.insert(mythiclite_progress[instanceID], creatureGUID)
			WorldDBQuery("INSERT INTO eluna_mythiclite_progress (creatureGUID, instanceID) VALUES ("..creatureGUID..", "..instanceID..");")
			print("[MythicLite.lua] Creature added to progress: " .. creatureGUID)

			-- get the modifier for total forces required
			local prog_modifier = 0
			for k,v in pairs(mythiclite_template) do
				if (v[1] == player:GetMapId()) then
					prog_modifier = v[4]
				end
			end

			local total_mobs = #mythiclite_template_mobs[player:GetMapId()] -- get the amount of total forces required
			local req_kills = math.floor(total_mobs * (prog_modifier / 100.0)) -- modify the amount by the modifier
			-- determine the current kills, assume 0 by default.
			local current_kills = 0
			if (mythiclite_progress[player:GetInstanceId()] ~= nil) then
				current_kills = #mythiclite_progress[player:GetInstanceId()]
			end

			local new_progress = math.floor((current_kills / req_kills) * 100) -- the result here is the progression of the total forces requirement and is a whole integer

			if (MYTHIC_OBJECTIVES_ENEMY_FORCES == 0) then -- determine if forces objective is enabled or not, if not then set the progress to 100
				new_progress = 100
			end

			if new_progress > 100 then -- normalize the progress if it is over 100
				new_progress = 100
			end

			-- is the killed unit a boss?
			local is_boss = false
			for k,v in pairs(mythiclite_template_bosses[mapID]["IDs"]) do
				if (v == creatureGUID) then
					is_boss = true
				end
			end

			if is_boss then -- if is_boss, then add the boss name to the table of strings in boss_progress
				if (client_progress_cache[player:GetGUIDLow()]["boss_progress"] == nil) then
					client_progress_cache[player:GetGUIDLow()]["boss_progress"] = {}
				end
				table.insert(client_progress_cache[player:GetGUIDLow()]["boss_progress"], creature:GetName())
				--for k,v in pairs(client_progress_cache[player:GetGUIDLow()]["boss_progress"]) do -- print the boss_progress table for debug
				--	print(v)
				--end

				-- send an AIO update to the client
				local group = player:GetGroup()
				if group then
					for i = 1, group:GetMemberCount() , 1 do
						local member = group:GetMember(i)
						if member:GetMapId() == player:GetMapId() then
							AIO.Handle(member, "Mythic_Lite", "ProgressUpdate", "skull", client_progress_cache[player:GetGUIDLow()]["boss_progress"])
						end
					end
				else
					AIO.Handle(player, "Mythic_Lite", "ProgressUpdate", "skull", client_progress_cache[player:GetGUIDLow()]["boss_progress"])
				end
			end

			local list_of_players = {}

			if (client_progress_cache[player:GetGUIDLow()]["progress"] ~= new_progress) and client_progress_cache[player:GetGUIDLow()]["progress"] <= 100 then -- compare progress and if it is different and not finished, continue
				client_progress_cache[player:GetGUIDLow()]["progress"] = new_progress -- update our cached entry of user progress
				local group = player:GetGroup() -- send to group if available, else send to player
				if group then -- perform loop on group if exists
					for i = 1, group:GetMemberCount() , 1 do
						local member = group:GetMember(i)
						if member:GetMapId() == player:GetMapId() then
							AIO.Handle(member, "Mythic_Lite", "ProgressUpdate", "bar", new_progress)
						end
						table.insert(list_of_players, member:GetGUIDLow())
					end
				else
					table.insert(list_of_players, player:GetGUIDLow())
					AIO.Handle(player, "Mythic_Lite", "ProgressUpdate", "bar", new_progress)
				end
			end

			WorldDBQuery("UPDATE eluna_mythiclite_keystones SET progress = "..client_progress_cache[player:GetGUIDLow()]["progress"].." AND bosses = " .. client_progress_cache[player:GetGUIDLow()]["boss_progress"] .. " WHERE instanceID = " ..instanceID.. ";")

			if (client_progress_cache[player:GetGUIDLow()]["progress"] ~= new_progress) then -- perform progress updates
				client_progress_cache[player:GetGUIDLow()]["progress"] = new_progress
				local group = player:GetGroup()
				if group then
					for i = 1, group:GetMemberCount() , 1 do
						local member = group:GetMember(i)
						if member:GetMapId() == player:GetMapId() then
							AIO.Handle(member, "Mythic_Lite", "ProgressUpdate", new_progress, client_progress_cache[player:GetGUIDLow()]["boss_progress"])
						end
						table.insert(list_of_players, member:GetGUIDLow())
					end
				else
					table.insert(list_of_players, player:GetGUIDLow())
					AIO.Handle(player, "Mythic_Lite", "ProgressUpdate", new_progress, client_progress_cache[player:GetGUIDLow()]["boss_progress"])
				end
				WorldDBQuery("UPDATE eluna_mythiclite_keystones SET progress = "..client_progress_cache[player:GetGUIDLow()]["progress"].." AND bosses = " .. #client_progress_cache[player:GetGUIDLow()]["boss_progress"] .. " WHERE instanceID = " ..instanceID.. ";")
			end

			-- check the win conditions in case it is victory
			if client_progress_cache[player:GetGUIDLow()]["progress"] >= 100 and #client_progress_cache[player:GetGUIDLow()]["boss_progress"] >= #mythiclite_template_bosses[mapID]["IDs"] then
			-- perform a boss and mob check separately 
			
			-- victory
				player:SendBroadcastMessage("[MythicLite] You have completed the dungeon.")

				-- if the player does not have a keystone, generate a new keystone. otherwise prompt the reroll generation to the player.
				if not player:HasItem(MYTHIC_KEYSTONE) then
					generateKeystone(player)
				else
					AIO.Handle(player, "Mythic_Lite", "POPUP_REROLL")
				end

				while #list_of_players < 5 do -- insert 0 and ensure the table is 5 players long.
					table.insert(list_of_players, 0)
				end

				-- get the keystone level, affixstring, and timestamp by looking for the key matching the player's instanceID
				local keystone_level = 0
				local affixstring = ""
				for k,v in pairs(mythiclite_keystones) do
					if (v[7] == player:GetInstanceId()) then
						keystone_level = v[2]
						affixstring = v[4]
						timestamp = v[5]
					end
				end

				-- determine "duration" by comparing the timestamp of the keystone
				local duration = os.time() - timestamp

				-- insert the record into the database
				WorldDBQuery("INSERT INTO eluna_mythiclite_records (mythicLevel, mapID, duration, affixString, player1, player2, player3, player4, player5) VALUES ("..keystone_level..", "..mapID..", "..duration..", '"..affixstring.."', "..list_of_players[1]..", "..list_of_players[2]..", "..list_of_players[3]..", "..list_of_players[4]..", "..list_of_players[5]..");")
			
				-- delete all old info related to the now completed keystone
				WorldDBQuery("DELETE FROM eluna_mythiclite_keystones WHERE instanceID = " .. instanceID .. ";")
				WorldDBQuery("DELETE FROM eluna_mythiclite_progress WHERE instanceID = " .. instanceID .. ";")

				-- loop through the cache, find the right keystone, and update the cache accordingly.
				for k,v in pairs(mythiclite_keystones) do
					if (v[7] == player:GetInstanceId()) then
						mythiclite_keystones[k] = nil
					end
				end

				for k,v in pairs(mythiclite_progress) do
					if (k == player:GetInstanceId()) then
						mythiclite_progress[k] = nil
					end
				end

				-- loop through the list of party members to find their caches and update them accordingly
				for i = 1, #list_of_players do
					local playerGUID = list_of_players[i]
					if playerGUID ~= 0 then
						for k,v in pairs(client_progress_cache) do
							if (k == playerGUID) then
								client_progress_cache[k] = nil
							end
						end
					end
				end

				print("[MythicLite] Mythic Dungeon completed.")
			end
		end
	end
end

function MythicLiteHandlers.generateKeystoneCache(player) -- sends and regenerates the client-side cache to the client. currently sends the entire mythiclite_affixes_template object
	AIO.Handle(player, "Mythic_Lite", "ReceiveKeystones", mythiclite_keystones)
end

function MythicLiteHandlers.generateAffixStacks(player) -- sends and regenerates the client-side cache to the client. currently sends the entire mythiclite_affixes_template object
	AIO.Handle(player, "Mythic_Lite", "ReceiveAffixStacks", mythiclite_affixes_template)
end

function MythicLiteHandlers.generateProgressCache(player)

	-- take totalMod from mythic template, #mythiclite_template_mobs[mapID] = value of total mobs, and multiply by totalMod to get the total amount of kills required for the keystone.
	-- take the amount of kills in mythiclite_progress[instanceID] and divide by the total amount of kills required for the keystone to get the progress percentage.
	-- mythiclite_template[x] = {mapID, lastBossID, timelimit, totalMod, dungeonName}
	-- perform a for loop through mythiclite_template[x] and if mapID == player:GetMapID() then that is our totalMod we will use to define prog_modifier
	local prog_modifier = 0
	local dungeon_name = ""
	local timelimit = 0
	for k,v in pairs(mythiclite_template) do
		if (v[1] == player:GetMapId()) then
			prog_modifier = v[4]
			dungeon_name = v[5]
			timelimit = v[2]
		end
	end
	print(prog_modifier)
	print(timelimit)
	print(dungeon_name)

	local prog_modifier = prog_modifier / 100 -- convert the totalMod to a percentage
	local total_mobs = #mythiclite_template_mobs[player:GetMapId()]
	local req_kills = math.ceil(total_mobs * prog_modifier)
	local current_kills = 0
	if (mythiclite_progress[player:GetInstanceId()] ~= nil) then
		current_kills = #mythiclite_progress[player:GetInstanceId()]
	end
	local progress = math.floor((current_kills / req_kills) * 100) -- the result here is a whole integer

	local keystone_level = 0
	local affixstring = ""
	for k,v in pairs(mythiclite_keystones) do -- loop through keystones to find matching instance ID of the player and that will be our keystone level and affixstring -- mythiclite_keystones[itemGUID] = {playerGUID, mythicLevel, mapID, affixString, timestamp, progress, instanceID, lastboss}
		if (v[7] == player:GetInstanceId()) then
			keystone_level = v[2]
			affixstring = v[4]
		end
	end

	-- get max amount of bosses in Dungeon
	--[[
	local boss_max = #mythiclite_template_bosses[player:GetMapId()]
	]]

	-- send the string table of boss monsters
	local bosses = mythiclite_template_bosses[player:GetMapId()]["Names"]

	-- get the boss progress, determine empty set by default.
	local boss_progress = {}

	-- client_progress_cache[player:GetGUIDLow()] = {dungeon = dungeon_name, duration = timelimit, progress = progress, affixstring = affixstring, keystone_level = keystone_level, boss_progress = {boss_progress, boss_max}}
	client_progress_cache[player:GetGUIDLow()] = {dungeon = dungeon_name, duration = timelimit, progress = progress, affixstring = affixstring, keystone_level = keystone_level, bosses = bosses, boss_progress = boss_progress}
	AIO.Handle(player, "Mythic_Lite", "ProgressInit", client_progress_cache[player:GetGUIDLow()])
end

function MythicLiteHandlers.generateMyKeystone(player) -- sends and regenerates the client-side keystone of the player.
	local playerGUID = player:GetGUIDLow()
	-- mythiclite_keystones[itemGUID] = {playerGUID, mythicLevel, mapID, affixString, timestamp, progress, instanceID, lastboss}
	local playerKeystone = {} -- construct a table object to send that is exclusiely the keystone information of the player
	for k,v in pairs(mythiclite_keystones) do
		if (v[1] == playerGUID) then
			playerKeystone = v
		end
	end
	AIO.Handle(player, "Mythic_Lite", "ReceiveMyKeystone", playerKeystone)
end

awaiting_reroll_cache = {} -- a table to store the playerGUID of players who have requested a reroll of their keystone. awaiting_reroll_cache[X] = playerGUID
newKeystone = {} -- construct a table object to send that is exclusiely the keystone information of the new key. newKeystone[playerGUID] = {playerGUID, mythicLevel, mapID, affixString, timestamp, progress, instanceID, lastboss}]

function MythicLiteHandlers.rerollCancel(player) -- find the player in the awaiting_reroll_cache and remove them
	for k,v in pairs(awaiting_reroll_cache) do
		if (v == player:GetGUIDLow()) then
			table.remove(awaiting_reroll_cache, k)
		end
	end
	player:SendBroadcastMessage("[MythicLite] You have cancelled your reroll request.")
	AIO.Handle(player, "Mythic_Lite", "CloseFrame")
	return
end

function MythicLiteHandlers.rerollConfirm(player) -- the player has sent a "yes i want this" to the server
	local valid_request = false
	for k,v in pairs(awaiting_reroll_cache) do -- first check if the player is making a valid request. are they in our request array?
		if (v == player:GetGUIDLow()) then
			valid_request = true
		end
	end

	if not valid_request then
		player:SendBroadcastMessage("[MythicLite] You have not requested a reroll. Wait, how'd you get this?")
		return
	end

	local itemGUID = nil
	for k,v in pairs(mythiclite_keystones) do -- loop through mythiclite_keystones and verify the player owns a keystone. its possible to get this far by UI hacking.
		if (v[1] == player:GetGUIDLow()) then
			valid_request = true
			itemGUID = k -- grab the itemGUID
		end
	end

	if not valid_request then
		player:SendBroadcastMessage("[MythicLite] You do not have a keystone. Wait, how'd you get this?")
		return
	end

	if player:HasItem(MYTHIC_KEYSTONE) then -- remove keystone item if previously carried
		player:RemoveItem(player:GetItemByEntry(MYTHIC_KEYSTONE), 1)
	end
	-- perform a delete query on progress and keystone tables. get instanceID from keystone cache.
	WorldDBQuery("DELETE FROM eluna_mythiclite_keystones WHERE playerGUID = "..player:GetGUIDLow()..";")
	WorldDBQuery("DELETE FROM eluna_mythiclite_progress WHERE instanceID = "..mythiclite_keystones[itemGUID][7]..";")

	player:AddItem(MYTHIC_KEYSTONE, 1) -- generate the new keystone item
	local item = player:GetItemByEntry(MYTHIC_KEYSTONE) -- find the new keystone item
	local item = item:GetGUIDLow() 
	mythiclite_keystones[item] = newKeystone[player:GetGUIDLow()] -- update the cache with the new keystone
	-- insert into world db
	WorldDBQuery("INSERT INTO eluna_mythiclite_keystones (itemGUID, playerGUID, mythicLevel, mapID, affixString, timestamp, progress, instanceID, bosses) VALUES ("..item..", "..player:GetGUIDLow()..", " ..newKeystone[player:GetGUIDLow()][2].. ", "..newKeystone[player:GetGUIDLow()][3]..", '"..newKeystone[player:GetGUIDLow()][4].."', 0, 0, 0, 0);")
	-- send new caches to the player
	AIO.Handle(player, "Mythic_Lite", "ReceiveKeystones", mythiclite_keystones)
	AIO.Handle(player, "Mythic_Lite", "ReceiveMyKeystone", newKeystone[player:GetGUIDLow()])
	for k,v in pairs(awaiting_reroll_cache) do -- remove the playerGUID from the awaiting_reroll_cache
		if (v == player:GetGUIDLow()) then
			table.remove(awaiting_reroll_cache, k)
		end
	end
	player:SendBroadcastMessage("[MythicLite] You succesfully rerolled your Mythic Keystone.")
	AIO.Handle(player, "Mythic_Lite", "CloseFrame")
end

function MythicLiteHandlers.rerollMyKeystone(player)
	-- look up the current keystone and temporarily store it to show the client later
	-- generate a new keystone but only store its values temporarily

	-- mythiclite_keystones[itemGUID] = {playerGUID, mythicLevel, mapID, affixString, timestamp, progress, instanceID, lastboss}
	local playerGUID = player:GetGUIDLow()
	local playerKeystone = {} -- construct a table object to send that is exclusiely the keystone information of the player
	if playerKeystone[playerGUID] == nil then
		playerKeystone[playerGUID] = {} -- init the table if it does not exist
	end
	local itemGUID = nil
	for k,v in pairs(mythiclite_keystones) do -- get the current keystone
		if (v[1] == playerGUID) then
			playerKeystone[playerGUID] = v
			itemGUID = k -- define itemguid
		end
	end

	-- generate a new keystone
	local dungeon_roll = math.random(1, #mythiclite_template)
	local dungeon_map = mythiclite_template[dungeon_roll][1]
	local dungeon_timer = mythiclite_template[dungeon_roll][3]
	local affix_string = ""
	local mythiclevel = 0
	local duration = 0

	-- search for the old keystone level by looking up the itemguid in mythiclite_records, this would indicate this is a finished keystone and will level up next.
	for k,v in pairs(mythiclite_records) do
		if (v[1] == itemGUID) then
			--mythiclevel = v[2] + KEYSTONE_LEVEL_STEP -- increment by the level increment variable
			-- grab the duration of the record while we are at it
			duration = v[3]
		end
	end

	-- determine if the dungeon has been finished within the timelimit, if not, set the level to be unchanged from the old keystone level
	if duration > dungeon_timer then
		mythiclevel = playerKeystone[playerGUID][2]
	elseif duration ~= 0 then
		-- determine the time remaining in the mythic keystone
		local time_remaining = dungeon_timer - duration

		-- determine the amount of time chunks that exist in relation to the mythic keystone template and the factor value
		local time_chunks = math.floor(dungeon_timer / KEYSTONE_LEVEL_BONUS_FACTOR) -- ie: 300 / 2 = 150. the length of each chunk of "time" is 150.

		-- how many time chunks exist in time_remaining
		local time_chunks = math.floor(time_remaining / time_chunks) -- ie: 135 / 150 = 0. the amount of chunks of time that have passed is 0. this is our bonus value.

		-- add the bonus to the mythic_level
		mythiclevel = mythiclevel + (KEYSTONE_LEVEL_BONUS * time_chunks)
		
		-- add the base level value to the mythic level because we have time leftover, which means we won the key regardless of time chunks.
		mythiclevel = mythiclevel + KEYSTONE_LEVEL_STEP
	end

	-- generate unique rolls here to get unique affixes for the keystone
	-- determine how many affixes the keystone will have based on the affix steps and the mythic keystone level. always add 1 to affixes.
	local how_many_affixes = math.floor(mythiclevel / AFFIX_STEP) * AFFIX_STEP_AMOUNT
	how_many_affixes = how_many_affixes + AFFIX_BASE

	local uniqueRolls = generateUniqueRolls(how_many_affixes, #mythiclite_affixes_pool)
	for i = 1, #uniqueRolls do
		affix_string = affix_string .. mythiclite_affixes_pool[uniqueRolls[i]] .. " "
	end

	if newKeystone[playerGUID] == nil then
		newKeystone[playerGUID] = {} -- init the table if it does not exist
	end
	newKeystone[playerGUID] = {playerGUID, mythiclevel, dungeon_map, affix_string, 0, 0, 0, 0} -- store this new information in an object to send to the client
	table.insert(awaiting_reroll_cache, playerGUID) -- store the playerGUID in the awaiting_reroll_cache table
	-- close open frames before doing anything else
	--AIO.Handle(player, "Mythic_Lite", "CloseFrame")
	AIO.Handle(player, "Mythic_Lite", "ReceiveReroll", playerKeystone[playerGUID], newKeystone[playerGUID])
end

RegisterPlayerEvent(3, keystoneOnLogin)

local function Turn_ZeroSwitch_On(event, player)
	-- loop through and see if the mapid is in any of the mythic templates to be considered a valid dungeon
	local valid_dungeon = false
	for k,v in pairs(mythiclite_template) do
		if (v[1] == player:GetMapId()) then
			valid_dungeon = true
		end
	end

	-- loop through to see if this instance id exists in progress, which would indicate this is a mythic keystone in progress.
	local keystone_in_progress = false
	for k,v in pairs(mythiclite_progress) do
		if (k == player:GetInstanceId()) then
			keystone_in_progress = true
		end
	end

	AIO.Handle(player, "Mythic_Lite", "Zero_Switch", "off") -- turn the switches off
	AIO.Handle(player, "Mythic_Lite", "Prog_Switch", "off")

	local playerMap = player:GetMap()
	local playerHeroic = playerMap:IsHeroic()

	-- determine if the settings combined with appropriate logic should result in progress generation for zero_key or a mythic dungeon
	if not keystone_in_progress and valid_dungeon then
		if playerHeroic and MYTHIC_ZERO_HEROIC then
			AIO.Handle(player, "Mythic_Lite", "Zero_Switch", "on")
			return
		elseif not playerHeroic and MYTHIC_ZERO_NORMAL then
			AIO.Handle(player, "Mythic_Lite", "Zero_Switch", "on")
			return
		end
	elseif keystone_in_progress and valid_dungeon then
		if playerHeroic and MYTHIC_HEROIC then
			AIO.Handle(player, "Mythic_Lite", "Prog_Switch", "on")
			return
		elseif not playerHeroic and MYTHIC_NORMAL then
			AIO.Handle(player, "Mythic_Lite", "Prog_Switch", "on")
			return
		end
	end
end

RegisterPlayerEvent(28, Turn_ZeroSwitch_On)

function MythicLiteHandlers.affixUnit(player)

	local playerGUID = player:GetGUIDLow()
	local affixString = ""
	local affixStacks = {}
	local keystoneLevel = 0
	local target = player:GetSelection()

	if target:HasAura(DUMMY_SPELL) then -- if target is already aura'd with the dummy aura, skip
		return
	end

	-- if target is player then skip
	if target:IsPlayer() then
		return
	end

	for k,v in pairs(mythiclite_keystones) do
		if (v[7] == player:GetInstanceId()) then
			affixString = v[4]
			keystoneLevel = v[2]
		end
	end

	local affixes = {}
	for word in affixString:gmatch("%w+") do -- break down the affixstring into individual spell IDs
		table.insert(affixes, word)
	end

	-- loop through the affixes and apply them to the player target using wip_affixes_template[spellID]["base_stacks"] and wip_affixes_template[spellID]["stacks_per_level"] and wip_affixes_template[spellID]
	for i = 1, #affixes do
		local spellID = tonumber(affixes[i])
		local base_stacks = wip_affixes_template[spellID]["base_stacks"]
		local stacks_per_level = wip_affixes_template[spellID]["stacks_per_level"]
		local stacks = base_stacks + (keystoneLevel * stacks_per_level)
		target:AddAura(spellID, target) -- apply the aura to the target
		target:GetAura(spellID):SetStackAmount(stacks)
	end
	target:AddAura(DUMMY_SPELL, target)
end