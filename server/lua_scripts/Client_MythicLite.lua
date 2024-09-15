local AIO = AIO or require("AIO")

if AIO.AddAddon() then
	return
end

MYTHIC_KEYSTONE_ITEM_ID = 1899980
player_guid = nil

local MythicLiteHandlers = AIO.AddHandlers("Mythic_Lite", {})

local mapID_to_strings = { -- converts map IDs to strings for the client to properly translate them. to get a list of dungeons you can run this handy SQL.
	-- SELECT ID, mapname_lang_enus FROM map_dbc WHERE instancetype > 0;
	-- extract that list as delim text and you can convert it here
	[30] = "Alterac Valley",
	[33] = "Shadowfang Keep",
	[34] = "Stormwind Stockade",
	[36] = "The Deadmines", -- corrected from Deadmines
	[43] = "Wailing Caverns",
	[44] = "<unused> Monastery",
	[47] = "Razorfen Kraul",
	[48] = "Blackfathom Deeps",
	[70] = "Uldaman",
	[90] = "Gnomeregan",
	[109] = "The Temple of Atal'Hakkar", -- corrected from Sunken Temple
	[129] = "Razorfen Downs",
	[169] = "Emerald Dream",
	[189] = "Scarlet Monastery",
	[209] = "Zul'Farrak",
	[229] = "Blackrock Spire",
	[230] = "Blackrock Depths",
	[249] = "Onyxia's Lair",
	[269] = "Opening of the Dark Portal",
	[289] = "Scholomance",
	[309] = "Zul'Gurub",
	[329] = "Stratholme",
	[349] = "Maraudon",
	[389] = "Ragefire Chasm",
	[409] = "Molten Core",
	[429] = "Dire Maul",
	[469] = "Blackwing Lair",
	[489] = "Warsong Gulch",
	[509] = "Ruins of Ahn'Qiraj",
	[529] = "Arathi Basin",
	[531] = "Ahn'Qiraj Temple",
	[532] = "Karazhan",
	[533] = "Naxxramas",
	[534] = "The Battle for Mount Hyjal",
	[540] = "Hellfire Citadel: The Shattered Halls",
	[542] = "Hellfire Citadel: The Blood Furnace",
	[543] = "Hellfire Citadel: Ramparts",
	[544] = "Magtheridon's Lair",
	[545] = "Coilfang: The Steamvault",
	[546] = "Coilfang: The Underbog",
	[547] = "Coilfang: The Slave Pens",
	[548] = "Coilfang: Serpentshrine Cavern",
	[550] = "Tempest Keep",
	[552] = "Tempest Keep: The Arcatraz",
	[553] = "Tempest Keep: The Botanica",
	[554] = "Tempest Keep",
	[555] = "Auchindoun: Shadow Labyrinth",
	[556] = "Auchindoun: Sethekk Halls",
	[557] = "Auchindoun: Mana-Tombs",
	[558] = "Auchindoun: Auchenai Crypts",
	[559] = "Nagrand Arena",
	[560] = "The Escape From Durnholde",
	[562] = "Blade's Edge Arena",
	[564] = "Black Temple",
	[565] = "Gruul's Lair",
	[566] = "Eye of the Storm",
	[568] = "Zul'Aman",
	[572] = "Ruins of Lordaeron",
	[574] = "Utgarde Keep",
	[575] = "Utgarde Pinnacle",
	[576] = "The Nexus",
	[578] = "The Oculus",
	[580] = "The Sunwell",
	[585] = "Magister's Terrace",
	[595] = "The Culling of Stratholme",
	[598] = "Sunwell Fix (Unused)",
	[599] = "Halls of Stone",
	[600] = "Drak'Tharon Keep",
	[601] = "Azjol-Nerub",
	[602] = "Halls of Lightning",
	[603] = "Ulduar",
	[604] = "Gundrak",
	[607] = "Strand of the Ancients",
	[608] = "Violet Hold",
	[615] = "The Obsidian Sanctum",
	[616] = "The Eye of Eternity",
	[617] = "Dalaran Sewers",
	[618] = "The Ring of Valor",
	[619] = "Ahn'kahet: The Old Kingdom",
	[624] = "Vault of Archavon",
	[628] = "Isle of Conquest",
	[631] = "Icecrown Citadel",
	[632] = "The Forge of Souls",
	[649] = "Trial of the Crusader",
	[650] = "Trial of the Champion",
	[658] = "Pit of Saron",
	[668] = "Halls of Reflection",
	[724] = "The Ruby Sanctum"
}

-- Create the main frame
local mainframe = CreateFrame("Frame", "CustomItemDropFrame", UIParent)
mainframe:SetSize(300, 450) -- Set the size of the frame
mainframe:SetPoint("CENTER") -- Set the position of the frame
-- mainframe:SetBackdrop({
--     --bgFile = "AIO_Artwork\\mythic_bg.blp",
--     edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
--     -- tile = true, tileSize = 32, edgeSize = 32,
--     insets = { left = 11, right = 12, top = 12, bottom = 11 }
-- })
--mainframe:SetBackdropColor(0, 0, 0, 1)
mainframe:SetMovable(true)
mainframe:EnableMouse(true)
mainframe:RegisterForDrag("LeftButton")
mainframe:SetScript("OnDragStart", mainframe.StartMoving)
mainframe:SetScript("OnDragStop", mainframe.StopMovingOrSizing)
mainframe.Title = mainframe:CreateFontString(nil, "OVERLAY")
mainframe.Title:SetFontObject("GameFontHighlight")
mainframe.Title:SetPoint("TOP", mainframe, "TOP", 0, 9)
mainframe.Title:SetText("Mythic Keystone Pedestal")

-- create a texture frame for the background and scale it just a bit to fit the frame
local bgTexture = mainframe:CreateTexture(nil, "BACKGROUND")
bgTexture:SetTexture("AIO_Artwork\\mythic_bg.blp")
--bgTexture:SetAllPoints(mainframe)
bgTexture:SetPoint("TOPLEFT", mainframe, "TOPLEFT", -25, 90)
bgTexture:SetPoint("BOTTOMRIGHT", mainframe, "BOTTOMRIGHT", 25, -90)
bgTexture:SetTexCoord(0, 1, 0, 1)

-- Close button
local closeButton = CreateFrame("Button", nil, mainframe, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", mainframe, "TOPRIGHT", -11, -13)
closeButton:SetScript("OnClick", function()
	mainframe:Hide()
end)

local containerSlot = CreateFrame("Frame", "CustomItemDropContainer", mainframe) -- container that holds the itemicon texture slot
containerSlot:SetSize(64, 64)
containerSlot:SetPoint("CENTER", mainframe, "TOP", 0, -96)

local slotButton = CreateFrame("Button", nil, containerSlot, "UIPanelButtonTemplate")
slotButton:SetSize(containerSlot:GetWidth(), containerSlot:GetHeight()) -- square the button
slotButton:SetPoint("CENTER", 0, 0)
slotButton:SetNormalTexture(nil)
slotButton:SetPushedTexture(nil)

local slotTexture = slotButton:CreateTexture(nil, "BACKGROUND") -- Create a slot texture for visual representation
slotTexture:SetTexture("Interface\\Buttons\\UI-Slot-Background")
slotTexture:SetPoint("CENTER", 0, 0)
slotTexture:SetTexCoord(0.65, 0, 0, 0.65) -- Adjust the texture coordinates to fit better

local itemIconTexture = slotButton:CreateTexture(nil, "ARTWORK") -- Create a texture for the item icon
itemIconTexture:SetSize(slotButton:GetWidth(), slotButton:GetHeight())
itemIconTexture:SetPoint("CENTER", 0, 0)

local keystoneLevel = containerSlot:CreateFontString(nil, "OVERLAY") -- font string for the keystone level
keystoneLevel:SetFontObject("GameFontHighlight")
keystoneLevel:SetPoint("TOP", containerSlot, "TOP", 0, 40)
keystoneLevel:SetText("")

local keystoneContainerMap = CreateFrame("Frame", "KeystoneContainerMap", containerSlot) -- container for the keystone map name font string
keystoneContainerMap:SetSize(containerSlot:GetWidth() * 2, 12) -- * 2 cause idk, the paperdoll icon that holds the item labelled "container" is too small for the map name.
keystoneContainerMap:SetPoint("TOP", keystoneLevel, "BOTTOM", 0, -5)

local keystoneMap = keystoneContainerMap:CreateFontString(nil, "OVERLAY") -- keystone map name font string
keystoneMap:SetFontObject("GameFontHighlight")
keystoneMap:SetPoint("CENTER", 0, 0)
keystoneMap:SetText("")

local affixContainer = CreateFrame("Frame", "AffixContainer", mainframe)
affixContainer:SetPoint("BOTTOM", containerSlot, "BOTTOM", 0, -17)
affixContainer:SetSize(mainframe:GetWidth(), 1)
affixContainer.title = affixContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
affixContainer.title:SetPoint("TOP", affixContainer, "TOP", 0, 10)
affixContainer.title:SetText("")

local startButton = CreateFrame("Button", nil, mainframe, "UIPanelButtonTemplate") -- create a "start!" button at the bottom of the frame
startButton:SetSize(100, 30)
startButton:SetPoint("BOTTOM", mainframe, "BOTTOM", 0, 23)
startButton:SetText("Start!")
startButton:Disable()

-- function to handle clearing the mainframe
local function clearMainFrame()
	keystoneLevel:SetText("") -- clear the font objects that held the keystone data
	keystoneMap:SetText("")
	itemIconTexture:SetTexture(nil) -- clear the item icon texture
	GameTooltip:Hide()
	affixContainer.title:SetText("") -- clear affixes text
	for i, child in ipairs({affixContainer:GetChildren()}) do
		child:Hide() -- clear the children of the affixes container
	end
	slotButton:SetScript("OnEnter", function() GameTooltip:Hide() end)
	keystoneContainerMap:SetScript("OnEnter", function() GameTooltip:Hide() end)

	startButton:Disable() -- disable the start button
end

-- Function to handle item clicks
slotButton:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        local type, id, info = GetCursorInfo()
        if type == "item" then
			if myKeystone == nil then -- first, check if myKeystone data is empty. if it is, request the data from the server and return.
				print("[MythicLite]: There was an error in requesting your own keystone information. A request to the server was made. Please try again.")
				AIO.Handle("Mythic_Lite", "generateMyKeystone")
				AIO.Handle("Mythic_Lite", "generateKeystoneCache") -- we should also make another entire cache request to rebuild our public facing cache
				return
			end

            local itemName, itemLink, _, _, _, _, _, _, _, itemIcon = GetItemInfo(info)
            if not string.find(itemName, "Mythic Keystone") then -- check if the item is keystone or not
				print("[MythicLite]: The item placed is not a Mythic Keystone. Please try again.")
				return
			end

            -- Update the font strings based on the keystone that is dropped. This is only for the player's keystone.
            keystoneLevel:SetText("Mythic Keystone Level: " .. myKeystone[2])
			local mapname = mapID_to_strings[myKeystone[3]]
			if mapname == nil then
				mapname = "Unknown"
			end
            keystoneMap:SetText("Map: " .. mapname)

			affixContainer.title:SetText("Affixes")

            -- Update the texture of the frame to be the icon of the placed item
            itemIconTexture:SetTexture(itemIcon)
            GameTooltip:SetOwner(containerSlot, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(itemLink)
            GameTooltip:Show()           
            -- Set the item tooltip on the frame
            slotButton:SetScript("OnEnter", function()
                GameTooltip:SetOwner(containerSlot, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(itemLink)
                GameTooltip:Show()
            end)
            slotButton:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)

			local affixes = {} -- generate the list of affixes and their buttons based on the keystone data
			local affixString = myKeystone[4]
			for affix in string.gmatch(affixString, "%S+") do -- begin with breaking up the affixstring by spaces
				table.insert(affixes, tonumber(affix))
			end
			-- settings for keystone menu
			local yOffset = -30
			local yPadding = 8 -- padding between each affix button vertically
			local xOffset = 42 -- initial offset value of the first affix button within the affix container itself
			local xPadding = 56 -- padding between each affix button
			local keystone_level = myKeystone[2] -- get the keystone level
			local affixSize = 48
			local affixesPerRow = math.ceil(affixContainer:GetWidth()) - xOffset
			local affixesPerRow = math.floor(affixesPerRow / (affixSize + (xPadding - affixSize)))
			local rows = math.ceil(#affixes / affixesPerRow)

			for i = 1, rows do
				for j = 1, affixesPerRow do
					local affix = affixes[(i - 1) * affixesPerRow + j]
					if affix == nil then
						break
					end
					if affixStacks[affix] == nil then
						print("[MythicLite]: There was an error in requesting the affix information. A request to the server was made. Please try again.")
						AIO.Handle("Mythic_Lite", "generateAffixStacks")
						return false
					end

					local affixButton = CreateFrame("Button", nil, affixContainer, "UIPanelButtonTemplate")
					affixButton:SetSize(affixSize, affixSize) -- square the button
					affixButton:SetPoint("LEFT", xOffset, yOffset)
					affixButton:SetNormalTexture(nil)
					affixButton:SetPushedTexture(nil)

					local name, rank, icon = GetSpellInfo(affix)
					local affixTexture = affixButton:CreateTexture(nil, "ARTWORK")
					affixTexture:SetSize(affixSize, affixSize)
					affixTexture:SetPoint("CENTER", affixButton, "CENTER", 0, 0)
					affixTexture:SetTexture(icon)

					local totalStacks = affixStacks[affix][1] + (keystone_level - 1) * affixStacks[affix][2]
					local affixCounter = affixButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
					affixCounter:SetPoint("BOTTOMRIGHT", -7, 3)
					affixCounter:SetText("x" .. totalStacks)

					affixButton:SetScript("OnEnter", function(self)
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						GameTooltip:SetText(name.. " x" ..totalStacks)
						GameTooltip:Show()
					end)
					affixButton:SetScript("OnLeave", function(self)
						GameTooltip:Hide()
					end)
					xOffset = xOffset + xPadding
					if j == affixesPerRow then
						xOffset = 42
					end
				end
				yOffset = ((yOffset * i) - affixSize - yPadding)
			end

			local mapname = mapID_to_strings[myKeystone[3]] -- does the string to mapID match exist?
			if mapname == nil then
				mapname = "Unknown"
			end

			--print(GetRealZoneText()) -- to debug if the map zone names match correctly
			if mapname == GetRealZoneText() then -- does the player map name match the keystone map name?
				startButton:Enable() -- enable the start! button
				startButton:SetScript("OnEnter", function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					GameTooltip:SetText("Start the dungeon with the selected keystone.")
					GameTooltip:Show()
				end)
				startButton:SetScript("OnLeave", function(self)
					GameTooltip:Hide()
				end)
				startButton:SetScript("OnClick", function(self)
					-- AIO.Handle("PStart", "VersionCheck", build, CURRENT_VERSION)
					AIO.Handle("Mythic_Lite", "MythicStart")
					print("[MythicLite] Starting the dungeon with the selected keystone.")
				end)
				-- remove any error scripts that may have been set
				keystoneContainerMap:SetScript("OnEnter", nil)
				keystoneContainerMap:SetScript("OnLeave", nil)
			else
				mapname = "|cFFFF0000" .. mapname .. "|r" -- set mapname to red to indicate an error
				keystoneMap:SetText("Map: " .. mapname) -- update the mapname fontstring
				keystoneContainerMap:SetScript("OnEnter", function(self) -- hide the tooltip and describe the error that the maps do not match
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					GameTooltip:SetText("The map on the keystone does not match the current map.")
					GameTooltip:Show()
				end)
				keystoneContainerMap:SetScript("OnLeave", function(self)
					GameTooltip:Hide()
				end)
				keystoneContainerMap:EnableMouse(true)
				startButton:Disable()
			end
			ClearCursor()
		end
	elseif button == "RightButton" then
		clearMainFrame()
	end
end)

mainframe:SetScript("OnHide", function(self)
	clearMainFrame()
end)

-- Hide the frame
mainframe:Hide()

keystoneCache = {}
affixStacks = {}

function MythicLiteHandlers.ReceiveAffixStacks(player, cache)
	affixStacks = {} -- deconstruct the received cache
	-- this is the data the server sends
	--local spellID = query:GetUInt32(0)
	--local base_stack = query:GetUInt32(1)
	--local stack_per_level = query:GetUInt32(2)
	--mythiclite_affixes_template[x] = {spellID, base_stack, stack_per_level}

	-- regenerate the cache using the spellID, the first cache value, as the newly generated cache's key
	for k, v in pairs(cache) do
		affixStacks[tonumber(v[1])] = {tonumber(v[2]), tonumber(v[3])}
	end

	-- Print the cache for debugging
	--[[
	for k, v in pairs(affixStacks) do
		print("Cache Key: " .. k .. " Value: " .. table.concat(v, ", "))
	end
	]]
end

function MythicLiteHandlers.ReceiveKeystones(player, cache) -- receive all the keystones of all players and all information related.
	keystoneCache = {} -- deconstruct the received cache

    -- cache[itemGUID] = {playerGUID, mythicLevel, mapID, affixString, timestamp, progress, instanceID, lastboss}
    for k, v in pairs(cache) do
        keystoneCache[tostring(k)] = v -- Reconstruct the cache data in keystoneCache
    end

    -- Print the cache for debugging
	--[[
    for k, v in pairs(keystoneCache) do
        print("Cache Key: " .. k .. " Value: " .. table.concat(v, ", "))
    end
	]]
end

function MythicLiteHandlers.ReceiveMyKeystone(player, keystone) -- receive keystone of the individual player
    --print("Getting my Keystone")
	--[[
    for k, v in pairs(keystone) do
		print(k, v)
	end
	]]
	myKeystone = keystone
	player_guid = keystone[1]
end

function MythicLiteHandlers.OpenFrame(player) -- open the frame
	mainframe:Show()
end

local ACDFrame = CreateFrame("Frame", "ACDFrame", UIParent) -- source contribution from ArenaCountdown via https://github.com/Schaka/ArenaCountDown
ACDFrame:SetSize(1, 1)
ACDFrame:SetPoint("CENTER", 0, 77)

local ACDNumFrame = CreateFrame("Frame", "ACDNumFrame", ACDFrame)
ACDNumFrame:SetHeight(256)
ACDNumFrame:SetWidth(256)
ACDNumFrame:SetPoint("CENTER", 0, 0)
ACDNumFrame:Show()

local ACDNumTens = ACDNumFrame:CreateTexture("ACDNumTens", "HIGH")
ACDNumTens:SetWidth(256)
ACDNumTens:SetHeight(128)
ACDNumTens:SetPoint("CENTER", -48, 0)

local ACDNumOnes = ACDNumFrame:CreateTexture("ACDNumOnes", "HIGH")
ACDNumOnes:SetWidth(256)
ACDNumOnes:SetHeight(128)
ACDNumOnes:SetPoint("CENTER", 48, 0)

local ACDNumOne = ACDNumFrame:CreateTexture("ACDNumOne", "HIGH")
ACDNumOne:SetWidth(256)
ACDNumOne:SetHeight(128)
ACDNumOne:SetPoint("CENTER", 0, 0)

local hidden = false;

function MythicLiteHandlers.StartTimer(player, START_TIMER)
	ACDFrame:SetScript("OnUpdate", function(self, elapse )
		if (START_TIMER > 0) then
			hidden = false;
			
			if ((math.floor(START_TIMER) ~= math.floor(START_TIMER - elapse)) and (math.floor(START_TIMER - elapse) >= 0)) then
				local str = tostring(math.floor(START_TIMER - elapse));
				
				if (math.floor(START_TIMER - elapse) == 0) then
					ACDNumTens:Hide();
					ACDNumOnes:Hide();		
					ACDNumOne:Hide();
				elseif (string.len(str) == 2) then			
					-- Display has 2 digits
					ACDNumTens:Show();
					ACDNumOnes:Show();
					
					ACDNumTens:SetTexture("AIO_Artwork\\".. string.sub(str,0,1));
					ACDNumOnes:SetTexture("AIO_Artwork\\".. string.sub(str,2,2));
					ACDNumFrame:SetScale(0.7)
				elseif (string.len(str) == 1) then		
					-- Display has 1 digit
					ACDNumOne:Show();
					ACDNumOne:SetTexture("AIO_Artwork\\".. string.sub(str,0,1));				
					ACDNumOnes:Hide();
					ACDNumTens:Hide();
					ACDNumFrame:SetScale(1.0)
				end
			end
			START_TIMER = START_TIMER - elapse;
		elseif (not hidden) then
			hidden = true;
			ACDNumTens:Hide();
			ACDNumOnes:Hide();
			ACDNumOne:Hide();
		end
	end)
end

local function keystoneAppendSelf(self) -- fires on the case of hovering over the keystone item where applicable
	local itemName, itemLink = self:GetItem()
	if itemName and string.find(itemName, "Mythic Keystone") then
        if myKeystone == nil then
			print("[MythicLite]: There was an error in requesting your own keystone information. A request to the server was made. Please try again.")
			AIO.Handle("Mythic_Lite", "generateMyKeystone")
			return
		end
        self:AddLine("Mythic Keystone Level: " .. myKeystone[2])
		-- get mapname from mapID
		local mapname = mapID_to_strings[myKeystone[3]]
		if mapname == nil then
			mapname = "Unknown"
		end
        self:AddLine("Map ID: " .. mapname)
		-- break apart the affix string and convert each separated ID into the spell's name, reconcact the entire new string and display it
		local affixes = {}
		local affixString = myKeystone[4]
		for affix in string.gmatch(affixString, "%S+") do
			table.insert(affixes, tonumber(affix))
		end
		local affixString = ""
		for i, affix in ipairs(affixes) do
			local name, rank, icon, castTime, minRange, maxRange = GetSpellInfo(affix)
			affixString = affixString .. name .. ", "
		end
		self:AddLine("Affixes: " .. affixString)
        self:Show()
	end
end

local function keystoneAppendLink(self) -- Fires on clicking a link in chat
	local itemName, itemLink = self:GetItem()
	if itemName and string.find(itemName, "Mythic Keystone") then
        if myKeystone == nil then
			print("[MythicLite]: There was an error in requesting your own keystone information. A request to the server was made. Please try again.")
			AIO.Handle("Mythic_Lite", "generateMyKeystone")
			return
		end
        self:AddLine("Mythic Keystone Level: " .. myKeystone[2])
		-- get mapname from mapID
		local mapname = mapID_to_strings[myKeystone[3]]
		if mapname == nil then
			mapname = "Unknown"
		end
        self:AddLine("Map ID: " .. mapname)
		-- break apart the affix string and convert each separated ID into the spell's name, reconcact the entire new string and display it
		local affixes = {}
		local affixString = myKeystone[4]
		for affix in string.gmatch(affixString, "%S+") do
			table.insert(affixes, tonumber(affix))
		end
		local affixString = ""
		for i, affix in ipairs(affixes) do
			local name, rank, icon, castTime, minRange, maxRange = GetSpellInfo(affix)
			affixString = affixString .. name .. ", "
		end
		self:AddLine("Affixes: " .. affixString)
        self:Show()
	end
end

-- on tooltip item, append data to tooltip
GameTooltip:HookScript("OnTooltipSetItem", keystoneAppendSelf) -- fired when hovering over the item. this would only happen in the player's bags, making this the player's keystone
ItemRefTooltip:HookScript("OnTooltipSetItem", keystoneAppendLink) -- fired when clicking on a chat hyperlink. this means we can get the itemGUID from the itemLink




-- Reroll UI START
--
--

local rerollParent = CreateFrame("Frame", "ReRollparent", UIParent) -- main frame
rerollParent:SetSize((mainframe:GetWidth() * 2) - 12, mainframe:GetHeight()) -- Set the size of the frame. mult width by 2 for the 2 frames - oldkey, newkey + and extra width to consider their offset
rerollParent:SetPoint("CENTER", 0, 0) -- Set the position of the frame
--[[
rerollParent:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true, tileSize = 32, edgeSize = 32,
	insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
]]
--rerollParent:SetBackdropColor(0, 0, 0, 1)
rerollParent:SetMovable(true)
rerollParent:EnableMouse(true)
rerollParent:RegisterForDrag("LeftButton")
rerollParent:SetScript("OnDragStart", rerollParent.StartMoving)
rerollParent:SetScript("OnDragStop", rerollParent.StopMovingOrSizing)

-- OLD KEY STARTS HERE
--
-- create a container frame for the old key
local containerOldKey = CreateFrame("Frame", "OldKeyContainer", rerollParent)
containerOldKey:SetSize(mainframe:GetWidth(), mainframe:GetHeight())
containerOldKey:SetPoint("LEFT", 0, 0)
containerOldKey:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true, tileSize = 32, edgeSize = 32,
	insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
containerOldKey:SetBackdropColor(0, 0, 0, 1)
containerOldKey.Title = containerOldKey:CreateFontString(nil, "OVERLAY")
containerOldKey.Title:SetFontObject("GameFontHighlight")
containerOldKey.Title:SetPoint("TOP", containerOldKey, "TOP", 0, -17)
containerOldKey.Title:SetText("Your Old Mythic Keystone")

-- create a container frame for the item slot icon
local slotcontainerOldKey = CreateFrame("Frame", "OldKeySlotContainer", containerOldKey)
slotcontainerOldKey:SetSize(64, 64)
slotcontainerOldKey:SetPoint("CENTER", containerOldKey, "TOP", 0, -128)

-- Create a slot texture for visual representation
local slotOldKey = slotcontainerOldKey:CreateTexture(nil, "BACKGROUND")
slotOldKey:SetTexture("Interface\\Buttons\\UI-Slot-Background")
slotOldKey:SetPoint("CENTER", slotcontainerOldKey, "CENTER", 0, 0)
slotOldKey:SetTexCoord(0.65, 0, 0, 0.65) -- Adjust the texture coordinates to fit better

-- Create a texture for the key icon
local iconOldKey = slotcontainerOldKey:CreateTexture(nil, "ARTWORK")
iconOldKey:SetSize(slotOldKey:GetWidth(), slotOldKey:GetHeight())
iconOldKey:SetPoint("CENTER", slotcontainerOldKey, "CENTER", 0, 0)
local itemName, itemLink, _, _, _, _, _, _, _, itemIcon = GetItemInfo(MYTHIC_KEYSTONE_ITEM_ID)
iconOldKey:SetTexture(itemIcon)
slotcontainerOldKey:EnableMouse(true)
slotcontainerOldKey:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetHyperlink(itemLink)
	GameTooltip:Show()
end)
slotcontainerOldKey:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- create empty font strings. one for the keystone level, one for the keystone map
local levelOldKey = slotcontainerOldKey:CreateFontString(nil, "OVERLAY")
levelOldKey:SetFontObject("GameFontHighlight")
levelOldKey:SetPoint("TOP", slotcontainerOldKey, "TOP", 0, 40)
levelOldKey:SetText("Keystone Level: 0")
local mapOldKey = containerOldKey:CreateFontString(nil, "OVERLAY")
mapOldKey:SetFontObject("GameFontHighlight")
mapOldKey:SetPoint("TOP", levelOldKey, "BOTTOM", 0, -5)
mapOldKey:SetText("The Deadmeemes")
local affixcontainerOldKey = CreateFrame("Frame", "affixcontainerOldKey", containerOldKey)
affixcontainerOldKey:SetSize(mainframe:GetWidth(), 1)
affixcontainerOldKey:SetPoint("BOTTOM", slotcontainerOldKey, "BOTTOM", 0, -17)
affixcontainerOldKey.title = affixcontainerOldKey:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
affixcontainerOldKey.title:SetPoint("TOP", affixcontainerOldKey, "TOP", 0, 10)
affixcontainerOldKey.title:SetText("Affixes")

affixcontainerOldKey:SetScript("OnHide", function(self)
    -- clear the font objects that held the keystone data
    levelNewKey:SetText("")
    mapNewKey:SetText("")
    self:SetScript("OnEnter", function() GameTooltip:Hide() end)
	for i, child in ipairs({affixcontainerOldKey:GetChildren()}) do
		child:Hide()
	end
end)

-- cancel reroll button
local cancelButton = CreateFrame("Button", nil, containerOldKey, "UIPanelButtonTemplate")
cancelButton:SetSize(100, 30)
cancelButton:SetPoint("BOTTOM", containerOldKey, "BOTTOM", 0, 23)
cancelButton:SetText("Cancel")
cancelButton:SetScript("OnClick", function(self)
	--MythicLiteHandlers.POPUP_REROLL(player_guid)
	AIO.Handle("Mythic_Lite", "rerollCancel")
	--self:GetParent():GetParent():Hide()
end)

-- OLD KEY END
--
-- NEW KEY STARTS HERE

-- create a container frame for the new key
local containerNewKey = CreateFrame("Frame", "containerNewKey", rerollParent)
containerNewKey:SetSize(mainframe:GetWidth(), mainframe:GetHeight())
containerNewKey:SetPoint("RIGHT", 0, 0)
containerNewKey:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true, tileSize = 32, edgeSize = 32,
	insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
containerNewKey:SetBackdropColor(0, 0, 0, 1)
containerNewKey.Title = containerNewKey:CreateFontString(nil, "OVERLAY")
containerNewKey.Title:SetFontObject("GameFontHighlight")
containerNewKey.Title:SetPoint("TOP", containerNewKey, "TOP", 0, -17)
containerNewKey.Title:SetText("Your New Mythic Keystone")

-- create a container frame for the item slot icon
local slotcontainerNewKey = CreateFrame("Frame", "OldKeySlotContainer", containerNewKey)
slotcontainerNewKey:SetSize(64, 64)
slotcontainerNewKey:SetPoint("CENTER", containerNewKey, "TOP", 0, -128)

-- Create a slot texture for visual representation
local slotNewKey = slotcontainerNewKey:CreateTexture(nil, "BACKGROUND")
slotNewKey:SetTexture("Interface\\Buttons\\UI-Slot-Background")
slotNewKey:SetPoint("CENTER", slotcontainerNewKey, "CENTER", 0, 0)
slotNewKey:SetTexCoord(0.65, 0, 0, 0.65) -- Adjust the texture coordinates to fit better

-- Create a texture for the key icon
local iconNewKey = slotcontainerNewKey:CreateTexture(nil, "ARTWORK")
iconNewKey:SetSize(slotNewKey:GetWidth(), slotNewKey:GetHeight())
iconNewKey:SetPoint("CENTER", slotcontainerNewKey, "CENTER", 0, 0)
local itemName, itemLink, _, _, _, _, _, _, _, itemIcon = GetItemInfo(MYTHIC_KEYSTONE_ITEM_ID)
iconNewKey:SetTexture(itemIcon)
slotcontainerNewKey:EnableMouse(true)
slotcontainerNewKey:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetHyperlink(itemLink)
	GameTooltip:Show()
end)
slotcontainerNewKey:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- create empty font strings. one for the keystone level, one for the keystone map
local levelNewKey = slotcontainerNewKey:CreateFontString(nil, "OVERLAY")
levelNewKey:SetFontObject("GameFontHighlight")
levelNewKey:SetPoint("TOP", slotcontainerNewKey, "TOP", 0, 40)
levelNewKey:SetText("Keystone Level: 0")
local mapNewKey = containerNewKey:CreateFontString(nil, "OVERLAY")
mapNewKey:SetFontObject("GameFontHighlight")
mapNewKey:SetPoint("TOP", levelNewKey, "BOTTOM", 0, -5)
mapNewKey:SetText("The Deadmeemes")
local affixcontainerNewKey = CreateFrame("Frame", "affixcontainerNewKey", containerNewKey)
affixcontainerNewKey:SetSize(mainframe:GetWidth(), 1)
affixcontainerNewKey:SetPoint("BOTTOM", slotcontainerNewKey, "BOTTOM", 0, -17)
affixcontainerNewKey.title = affixcontainerNewKey:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
affixcontainerNewKey.title:SetPoint("TOP", affixcontainerNewKey, "TOP", 0, 10)
affixcontainerNewKey.title:SetText("Affixes")

affixcontainerNewKey:SetScript("OnHide", function(self)
    -- clear the font objects that held the keystone data
    levelNewKey:SetText("")
    mapNewKey:SetText("")
    self:SetScript("OnEnter", function() GameTooltip:Hide() end)
	for i, child in ipairs({affixcontainerNewKey:GetChildren()}) do
		child:Hide()
	end
end)

-- confirm reroll button
local confirmButton = CreateFrame("Button", nil, containerNewKey, "UIPanelButtonTemplate")
confirmButton:SetSize(100, 30)
confirmButton:SetPoint("BOTTOM", containerNewKey, "BOTTOM", 0, 23)
confirmButton:SetText("Confirm")
confirmButton:SetScript("OnClick", function(self)
	AIO.Handle("Mythic_Lite", "rerollConfirm")
end)

-- NEW KEY END
--
--

-- Create the main frame for the glow effect
local GlowFrame = CreateFrame("Frame", "RadiantGlowFrame", rerollParent)
GlowFrame:SetSize(rerollParent:GetHeight() - 7, rerollParent:GetHeight() - 7) -- Adjust the size as needed
GlowFrame:SetPoint("CENTER", rerollParent, "CENTER", 0, 0) -- Position at the center of the screen

-- Add a circular glow texture
local GlowTexture = rerollParent:CreateTexture(nil, "ARTWORK")
--GlowTexture:SetPoint("CENTER", GlowFrame, "CENTER", 0, 0)
GlowTexture:SetTexture("SPELLS\\AURARUNE256.BLP") -- Replace with your texture path
GlowTexture:SetAllPoints(rerollParent)
GlowTexture:SetVertexColor(0.25, 0.5, 0, 0.5) -- Adjust the color and transparency (RGBA)

-- arrow / chest texture indicating old to new
local arrowTexture = rerollParent:CreateTexture(nil, "ARTWORK")
--arrowTexture:SetSize(256, 256)
arrowTexture:SetTexture("AIO_Artwork\\ember_chest.blp")
arrowTexture:SetAllPoints(GlowFrame)
arrowTexture:SetPoint("CENTER", rerollParent, "CENTER", 0, 0)
arrowTexture:SetAlpha(1)

-- popup frame that identifies the player already having a keystone and asking if they would like to continue with the reroll
-- confirmation menus
function MythicLiteHandlers.POPUP_REROLL(player)
	StaticPopupDialogs["CONFIRM_REROLL"] = {
	text = "You are about to reroll your previous mythic keystone. Doing so will close any dungeon still open with your keystone and provide you with a new one. Are you sure you want to continue?",
	button1 = "Continue",
	button2 = "Decline",
	OnAccept = function()
		-- hide mainframe and reroll if open
		mainframe:Hide()
		rerollParent:Hide()
		AIO.Handle("Mythic_Lite", "rerollMyKeystone")
	end,
	OnDecline = function()
	end,
	timeout = 0,
	whileDead = false,
	hideOnEscape = true,
	preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
	}
	StaticPopup_Show("CONFIRM_REROLL")
end

-- the server is doing the following - 
-- AIO.Handle(player, "Mythic_Lite", "ReceiveReroll", playerKeystone[playerGUID], newKeystone[playerGUID])
-- playerKeystone[playerGUID]= {playerGUID, mythicLevel, mapID, affixString, timestamp, progress, instanceID, lastboss}
-- newKeystone[playerGUID] = {playerGUID, mythicLevel, mapID, affixString, timestamp, progress, instanceID, lastboss}
function MythicLiteHandlers.ReceiveReroll(player, oldkeystone, newkeystone) -- receive the old and new keystone data
	-- print the old keystone data
	--[[
	print("Old Keystone Data: ")
	for k, v in pairs(oldkeystone) do
		print(k, v)
	end
	-- print the new keystone data
	print("New Keystone Data: ")
	for k, v in pairs(newkeystone) do
		print(k, v)
	end
	]]

	--hide the frames if they were open
	rerollParent:Hide()

	-- update the values in the containerOldKey children
	levelOldKey:SetText("Keystone Level: " .. oldkeystone[2])
	local mapname = mapID_to_strings[oldkeystone[3]]
	if mapname == nil then
		mapname = "Unknown"
	end
	mapOldKey:SetText("Map: " .. mapname)

	-- update the values in the containerNewKey children
	levelNewKey:SetText("Keystone Level: " .. newkeystone[2])
	local mapname = mapID_to_strings[newkeystone[3]]
	if mapname == nil then
		mapname = "Unknown"
	end
	mapNewKey:SetText("Map: " .. mapname)

	-- break apart the affix string and convert each separated ID into the spell's name. create a texture of said spell in a manner similar to the other affixes
	local affixes = {}
	local affixString = oldkeystone[4]
	for affix in string.gmatch(affixString, "%S+") do
		table.insert(affixes, tonumber(affix))
	end

	-- settings for the oldkeystone menu
	local yOffset = -30
	local yPadding = 8 -- padding between each affix button vertically
	local xOffset = 42 -- initial offset value of the first affix button within the affix container itself
	local xPadding = 56 -- padding between each affix button
	local keystone_level = oldkeystone[2]
	local affixSize = 48
	local affixesPerRow = math.ceil(affixcontainerOldKey:GetWidth()) - xOffset
	local affixesPerRow = math.floor(affixesPerRow / (affixSize + (xPadding - affixSize)))
	local rows = math.ceil(#affixes / affixesPerRow)
	
	for i = 1, rows do
		for j = 1, affixesPerRow do
			local affix = affixes[(i - 1) * affixesPerRow + j]
			if affix == nil then
				break
			end
			if affixStacks[affix] == nil then
				print("[MythicLite]: There was an error in requesting the affix information. A request to the server was made. Please try again.")
				AIO.Handle("Mythic_Lite", "generateAffixStacks")
				return false
			end

			local affixButton = CreateFrame("Button", nil, affixcontainerOldKey, "UIPanelButtonTemplate")
			affixButton:SetSize(affixSize, affixSize) -- square the button
			affixButton:SetPoint("LEFT", xOffset, yOffset)
			affixButton:SetNormalTexture(nil)
			affixButton:SetPushedTexture(nil)

			local name, rank, icon = GetSpellInfo(affix)
			local affixTexture = affixButton:CreateTexture(nil, "ARTWORK")
			affixTexture:SetSize(affixSize, affixSize)
			affixTexture:SetPoint("CENTER", affixButton, "CENTER", 0, 0)
			affixTexture:SetTexture(icon)
			xOffset = xOffset + xPadding

			local totalStacks = affixStacks[affix][1] + (keystone_level - 1) * affixStacks[affix][2]
			local affixCounter = affixButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			affixCounter:SetPoint("BOTTOMRIGHT", -7, 3)
			affixCounter:SetText("x" .. totalStacks)

			affixButton:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

				GameTooltip:SetText(name.. " x" ..totalStacks)
				GameTooltip:Show()
			end)
			affixButton:SetScript("OnLeave", function(self)
				GameTooltip:Hide()
			end)
			if j == affixesPerRow then
				xOffset = 42
			end
		end
		yOffset = ((yOffset * i) - affixSize - yPadding)
	end

	-- settings for the new keystone menu
	local affixesNew = {}
	local affixNew = newkeystone[4]
	for affix in string.gmatch(affixNew, "%S+") do
		table.insert(affixesNew, tonumber(affix))
	end

	-- settings for new keystone menu
	local yOffset = -30
	local yPadding = 8 -- padding between each affix button vertically
	local xOffset = 42 -- initial offset value of the first affix button within the affix container itself
	local xPadding = 56 -- padding between each affix button
	local keystone_level = newkeystone[2]
	local affixSize = 48
	local affixesPerRow = math.ceil(affixcontainerNewKey:GetWidth()) - xOffset
	local affixesPerRow = math.floor(affixesPerRow / (affixSize + (xPadding - affixSize)))
	local rows = math.ceil(#affixesNew / affixesPerRow)


	for i = 1, rows do
		for j = 1, affixesPerRow do
			local affix = affixesNew[(i - 1) * affixesPerRow + j]
			if affix == nil then
				break
			end
			if affixStacks[affix] == nil then
				print("[MythicLite]: There was an error in requesting the affix information. A request to the server was made. Please try again.")
				AIO.Handle("Mythic_Lite", "generateAffixStacks")
				return false
			end

			local affixButton = CreateFrame("Button", nil, affixcontainerNewKey, "UIPanelButtonTemplate")
			affixButton:SetSize(affixSize, affixSize) -- square the button
			affixButton:SetPoint("LEFT", xOffset, yOffset)
			affixButton:SetNormalTexture(nil)
			affixButton:SetPushedTexture(nil)

			local name, rank, icon = GetSpellInfo(affix)
			local affixTexture = affixButton:CreateTexture(nil, "ARTWORK")
			affixTexture:SetSize(affixSize, affixSize)
			affixTexture:SetPoint("CENTER", affixButton, "CENTER", 0, 0)
			affixTexture:SetTexture(icon)
			xOffset = xOffset + xPadding

			local totalStacks = affixStacks[affix][1] + (keystone_level - 1) * affixStacks[affix][2]
			local affixCounter = affixButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			affixCounter:SetPoint("BOTTOMRIGHT", -7, 3)
			affixCounter:SetText("x" .. totalStacks)

			affixButton:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				local totalStacks = affixStacks[affix][1] + (keystone_level - 1) * affixStacks[affix][2] -- gather and calculate stacking amounts and append it to the tooltip. this is based on the affixStacks table

				GameTooltip:SetText(name.. " x" ..totalStacks)
				GameTooltip:Show()
			end)
			affixButton:SetScript("OnLeave", function(self)
				GameTooltip:Hide()
			end)
			if j == affixesPerRow then
				xOffset = 42
			end
		end
		yOffset = ((yOffset * i) - affixSize - yPadding)
	end

	slotcontainerNewKey:SetScript("OnEnter", function(self) -- update the NewKey ToolTip to show the proper info. remove the 3 lines that will exist by default - keystone level, map, affixes, and replace them with the new keystone info
		local itemName, itemLink, _, _, _, _, _, _, _, itemIcon = GetItemInfo(MYTHIC_KEYSTONE_ITEM_ID)

		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(itemName) -- do a gsub here to find and remove the 3 lines that should already exist by this point

		GameTooltip:AddLine("Keystone Level: " .. newkeystone[2])
		local mapname = mapID_to_strings[newkeystone[3]]
		if mapname == nil then
			mapname = "Unknown"
		end
		GameTooltip:AddLine("Map: " .. mapname)

		local affixNew = ""
		for i, affix in ipairs(affixesNew) do
			local name, rank, icon, castTime, minRange, maxRange = GetSpellInfo(affix)
			affixNew = affixNew .. name .. ", "
		end
		GameTooltip:AddLine("Affixes: " .. affixNew)
		GameTooltip:Show()
	end)

	rerollParent:Show() -- show the frame
end










-- Timer / Progress UI
-- Create the main frame
local prog = CreateFrame("Frame", "ProgressionContainer", UIParent)
prog:SetSize(330, 110) -- Set the size of the frame
prog:SetPoint("TOP", Minimap, "BOTTOM", 0, -12) -- anchor the frame underneath the minimap
--prog:SetBackdrop({
--    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
--    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
--    tile = true, tileSize = 32, edgeSize = 32,
--    insets = { left = 11, right = 12, top = 12, bottom = 11 }
--})
--prog:SetBackdropColor(0, 0, 0, 1)
prog:SetMovable(true)
prog:EnableMouse(true)
prog:RegisterForDrag("LeftButton")
prog:SetScript("OnDragStart", prog.StartMoving)
prog:SetScript("OnDragStop", prog.StopMovingOrSizing)
prog.Title = prog:CreateFontString(nil, "OVERLAY")
prog.Title:SetFontObject("GameFontHighlight")
prog.Title:SetPoint("TOP", prog, "TOP", 0, -27)
prog.Title:SetText("Dungeon Name")

-- create a texture frame for the background and scale it just a bit to fit the frame
prog.BGtexture = prog:CreateTexture(nil, "ARTWORK")
prog.BGtexture:SetTexture("AIO_Artwork\\prog_bg.blp")
prog.BGtexture:SetTexCoord(0.001953125, 0.9941406, 0.33789062, 0.6582031)
prog.BGtexture:SetPoint("TOPLEFT", prog, "TOPLEFT", 0, 15)
prog.BGtexture:SetPoint("BOTTOMRIGHT", prog, "BOTTOMRIGHT", 0, -15)

-- create a frame to handle the container
local container = CreateFrame("Frame", "ProgressTimerContainer", prog)
container:SetSize(155, 56)
container:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
container:SetBackdropColor(0, 0, 0, 1)
container:SetPoint("TOP", prog, "TOP", -63, -57)

-- Reparent the Stopwatch to the custom frame
StopwatchFrame:SetParent(container)
StopwatchFrame:Show()

-- Position the Stopwatch within the custom frame
StopwatchFrame:ClearAllPoints()
StopwatchFrame:SetPoint("CENTER", container, "CENTER", 0, 7)
--StopwatchFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
--StopwatchFrame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)

-- Hide the Stopwatch controls
StopwatchPlayPauseButton:Hide()
StopwatchResetButton:Hide()

StopwatchFrame:HookScript("OnHide", function(self) -- Prevent the Stopwatch from being hidden
    self:Show()
end)

-- Disable dragging of the Stopwatch while keeping mouse interaction
StopwatchFrame:SetScript("OnMouseDown", nil)
StopwatchFrame:SetScript("OnMouseUp", nil)
StopwatchFrame:SetMovable(false)

local function StartCustomTimer(duration) -- Start a 60-second timer with hidden controls
    Stopwatch_Clear()
    Stopwatch_StartCountdown(0, 0, duration)
    Stopwatch_Play()
end

-- texture icon of the keystone item and the keystone level text string
local mythiclvl_texture = StopwatchFrame:CreateTexture(nil, "ARTWORK")
mythiclvl_texture:SetSize(16, 16)
mythiclvl_texture:SetPoint("RIGHT", StopwatchFrame, "RIGHT", -5, -7)
local _, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(MYTHIC_KEYSTONE_ITEM_ID)
mythiclvl_texture:SetTexture(itemIcon)

mythiclvl_txt = StopwatchFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
mythiclvl_txt:SetPoint("CENTER", mythiclvl_texture, "CENTER", -19, 0)
mythiclvl_txt:SetText("5")

-- container frame for the affixes
local affix_container = CreateFrame("Frame", "AffixContainer", prog)
affix_container:SetSize(StopwatchFrame:GetWidth(), 26)
affix_container:SetPoint("TOP", StopwatchFrame, "RIGHT", math.floor(StopwatchFrame:GetWidth() / 2) + 7, math.floor(StopwatchFrame:GetHeight() / 2) + 3)
affix_container:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true, tileSize = 32, edgeSize = 32,
	insets = { left = 11, right = 12, top = 12, bottom = 11 }
})

local bar_container = CreateFrame("Frame", "ProgressBarContainer", prog)
bar_container:SetSize(prog:GetWidth() - 35, 40)
bar_container:SetPoint("CENTER", prog.Title, "CENTER", 0, 0)
bar_container:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})

-- create a generic blue progress bar with text overlaid like "50 %" and create a texture frame that would appropriately pair well with the progress bar. put like vertical bar aesthetic on it like any other wow progress bar.
local texture = bar_container:CreateTexture(nil, "BACKGROUND")
texture:SetSize(133, 20)
texture:SetPoint("LEFT", bar_container, "LEFT", 5, 0)
texture:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")

local statusbar = CreateFrame("StatusBar", nil, bar_container)
statusbar:SetSize(bar_container:GetWidth() - 23, bar_container:GetHeight() - 23)
statusbar:SetPoint("LEFT", bar_container, "LEFT", 11, -1)
statusbar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
statusbar:SetStatusBarColor(0, 0, 1, 1)
statusbar:SetMinMaxValues(0, 100)
statusbar:SetValue(50)

local statusbarText = statusbar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
statusbarText:SetPoint("CENTER", statusbar, "CENTER", 0, 0)
statusbarText:SetText("50%")
statusbarText:Hide()

-- on enter, show the tooltip of the progress value. otherwise hide. TO DO FIX MEEEEE
bar_container:EnableMouse(true)
bar_container:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
	GameTooltip:SetText("Progress: " .. statusbar:GetValue() .. "%")
	GameTooltip:Show()
	statusbarText:Show()
	prog.Title:Hide()
end)
bar_container:SetScript("OnLeave", function(self)
	GameTooltip:Hide()
	statusbarText:Hide()
	prog.Title:Show()
end)

-- frame container that holds a font object for the boss progress values. make it the size of teh statusbar container
local boss_progress_container = CreateFrame("Frame", "BossProgressContainer", prog)
boss_progress_container:SetSize(bar_container:GetWidth(), math.floor(bar_container:GetHeight() / 2))
boss_progress_container:SetPoint("BOTTOM", prog, "BOTTOM", 0, 15)
--boss_progress_container:SetBackdrop({
--	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
--	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
--	tile = true, tileSize = 32, edgeSize = 32,
--	insets = { left = 11, right = 12, top = 12, bottom = 11 }
--})

-- create a texture of the generic party leader crown icon
-- local crown_texture = boss_progress_container:CreateTexture(nil, "ARTWORK")
-- crown_texture:SetSize(16, 16)
-- crown_texture:SetPoint("CENTER", boss_progress_container, "CENTER", 0, 0)
-- crown_texture:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")

-- create a texture of a generic skull for the boss icon
-- local boss_texture = boss_progress_container:CreateTexture(nil, "ARTWORK")
-- boss_texture:SetSize(16, 16)
-- boss_texture:SetPoint("RIGHT", crown_texture, "RIGHT", crown_texture:GetWidth() + 5, 0)
-- boss_texture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")


-- local boss_progress_text = boss_progress_container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
-- boss_progress_text:SetPoint("CENTER", boss_progress_container, "CENTER", 0, 0)
-- boss_progress_text:SetText("Boss Progress: 0/5")

-- set script on enter, show a cached string list of boss names
--boss_progress_container:EnableMouse(true)
--boss_progress_container:SetScript("OnEnter", function(self)
--	GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
--	GameTooltip:SetText("Boss Progress: 0/5")
--	GameTooltip:AddLine("Boss 1: Boss Name")
--	GameTooltip:AddLine("Boss 2: Boss Name")
--	GameTooltip:AddLine("Boss 3: Boss Name")
--	GameTooltip:AddLine("Boss 4: Boss Name")
--	GameTooltip:AddLine("Boss 5: Boss Name")
--	GameTooltip:Show()
--end)
--boss_progress_container:SetScript("OnLeave", function(self)
--	GameTooltip:Hide()
--end)


-- set prog.title parent to statusbar
prog.Title:SetParent(bar_container)

--container:SetPoint("CENTER", affix_container, "CENTER", -30, 0) --repoint the stopwatch parent container since the objects necessary are now made
prog:Hide() -- hide the prog frame

local switchframe = CreateFrame("Frame")
function MythicLiteHandlers.Prog_Switch(player, state)
	print("rcvd prog switch" .. state)
	if state == "on" then
		switchframe:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		switchframe:RegisterEvent("PLAYER_TARGET_CHANGED")
		switchframe:SetScript("OnEvent", function(self, event, timestamp, combat_event)
			--print(event)
			if event == "COMBAT_LOG_EVENT_UNFILTERED" then
				--print(combat_event)
				if combat_event == "UNIT_DIED" then
					AIO.Handle("Mythic_Lite", "MythicKill") -- do an AIO event to say "we killed the thing!"
				end
			elseif event == "PLAYER_TARGET_CHANGED" then
				-- does target have spellID on aura? aka any affix?
				-- if so, print "YES"
				-- if not, print "NO"

				-- local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitAura("target", ??) -- ONLY WORKS ON CLIENT-SIDE VISIBLE SPELLS
				-- if spellId == nil then
				-- 	print("NO")
				-- else
				-- 	print("YES")
				-- end

			end
		end)
		AIO.Handle("Mythic_Lite", "generateProgressCache") -- request the initial dataset for the progress UI
	elseif state == "off" then
		switchframe:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		switchframe:UnregisterEvent("PLAYER_TARGET_CHANGED")
	end
end

local ZeroSwitchFrame = CreateFrame("Frame")
function MythicLiteHandlers.Zero_Switch(player, state) -- handler for progressing a dungeon that is not a keystone mythic but can generate a mythic keystone. switched to on when a player changes zone into a valid dungeon. switched to off when a player starts a keystone.
	print("rcvd zero switch" .. state)
	if state == "on" then
		ZeroSwitchFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		ZeroSwitchFrame:SetScript("OnEvent", function(self, event, timestamp, combat_event)
			if event == "COMBAT_LOG_EVENT_UNFILTERED" then
				if combat_event == "UNIT_DIED" then
					AIO.Handle("Mythic_Lite", "ZeroKill") -- do an AIO event to say "we killed the thing!"
				end
			end
		end)
	elseif state == "off" then
		ZeroSwitchFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end
end

local boss_max = 0
function MythicLiteHandlers.ProgressInit(player, client_progress_cache) -- receives client_progress_cache. {dungeon_name, timelimit, progress, affixstring, keystone_level, bosses, boss_progress}
	-- break down the data and define it for the script usage
	local dungeon = client_progress_cache["dungeon"]
	local duration = client_progress_cache["duration"]
	local progress = client_progress_cache["progress"]
	local affixstring = client_progress_cache["affixstring"]
	local keystone_level = client_progress_cache["keystone_level"]
	local boss_progress = client_progress_cache["boss_progress"] -- integer value of how many bosses have been killed in the dungeon.
	boss_max = #client_progress_cache["bosses"] -- integer value of how many bosses are in the dungeon. taken from a table of string names of the bosses.

	-- set the progress bar to the appropriate values
	prog:Show()
	StartCustomTimer(duration)
	statusbar:SetValue(tonumber(progress))
	statusbarText:SetText(tostring(progress) .. "%")
	prog.Title:SetText(dungeon)

	local affixes = {}
	local affixString = affixstring
	for affix in string.gmatch(affixString, "%S+") do
		table.insert(affixes, tonumber(affix))
	end
	local yOffset = -15
	local xOffset = 13
	local yPadding = 3
	local xPadding = 18
	local affixSize = 16
	-- math out the maximum amount of affixes per "row" and then calculate the amount of rows needed to display all the affixes
	-- calculate affixesperrow based on affixSize, xPadding, and xOffset
	local affixesPerRow = math.floor(affix_container:GetWidth())
	local affixesPerRow = affixesPerRow - xOffset
	local affixesPerRow = math.floor(affixesPerRow / (affixSize + (xPadding - affixSize)))
	local rows = math.ceil(#affixes / affixesPerRow)

	for i = 1, rows do
		for j = 1, affixesPerRow do
			local affix = affixes[(i - 1) * affixesPerRow + j]
			if affix == nil then
				break
			end
			if affixStacks[affix] == nil then
				print("[MythicLite]: There was an error in requesting the affix information. A request to the server was made. Please try again.")
				AIO.Handle("Mythic_Lite", "generateAffixStacks")
				return false
			end

			local affixButton = CreateFrame("Button", nil, affix_container, "UIPanelButtonTemplate")
			affixButton:SetSize(affixSize, affixSize) -- square the button
			affixButton:SetPoint("TOPLEFT", xOffset, yOffset)
			affixButton:SetNormalTexture(nil)
			affixButton:SetPushedTexture(nil)

			local name, rank, icon = GetSpellInfo(affix)
			local affixTexture = affixButton:CreateTexture(nil, "ARTWORK")
			affixTexture:SetSize(affixSize, affixSize)
			affixTexture:SetPoint("CENTER", affixButton, "CENTER", 0, 0)
			affixTexture:SetTexture(icon)

			local totalStacks = affixStacks[affix][1] + (keystone_level - 1) * affixStacks[affix][2]
			local affixCounter = affixButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			affixCounter:SetPoint("BOTTOMRIGHT", -3, 3)
			local fontFile, fontHeight, flags = affixCounter:GetFont() -- https://wowpedia.fandom.com/wiki/API_FontString_GetFont
			affixCounter:SetFont(fontFile, 7, "OUTLINE, THICK")
			affixCounter:SetText("x" .. totalStacks)

			affixButton:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(name.. " x" ..totalStacks)
				GameTooltip:Show()
			end)
			affixButton:SetScript("OnLeave", function(self)
				GameTooltip:Hide()
			end)
			xOffset = xOffset + xPadding
			if j == affixesPerRow then
				xOffset = 13
			end
		end
		yOffset = yOffset - affixSize - yPadding
		affix_container:SetHeight(affix_container:GetHeight() + affixSize + yPadding)
		prog:SetHeight(prog:GetHeight() + affixSize + yPadding)
	end

	-- generate button frames with the boss skull as their texture and on entry, show the boss name. reposition the skull and boss crown based on the amount of bosses to be proper centered in relation to the crown texture frame.
	local crownButton = CreateFrame("Button", nil, boss_progress_container, "UIPanelButtonTemplate")
	crownButton:SetSize(16, 16)
	crownButton:SetPoint("LEFT", xOffset, 0)
	crownButton:SetNormalTexture(nil)
	crownButton:SetPushedTexture(nil)

	local crown_texture = crownButton:CreateTexture(nil, "ARTWORK")
	crown_texture:SetSize(16, 16)
	crown_texture:SetPoint("CENTER", crownButton, "CENTER", 0, 0)
	crown_texture:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")

	crownButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Bosses killed: " .. client_progress_cache["boss_progress"] .. "/" .. boss_max)
		GameTooltip:Show()
	end)
	crownButton:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	local xOffset = crownButton:GetWidth() + 5
	for i = 1, boss_max do
		local bossButton = CreateFrame("Button", nil, boss_progress_container, "UIPanelButtonTemplate")
		bossButton:SetSize(16, 16)
		bossButton:SetPoint("CENTER", crownButton, "CENTER", xOffset, 0)
		bossButton:SetNormalTexture(nil)
		bossButton:SetPushedTexture(nil)

		local bossTexture = bossButton:CreateTexture(nil, "ARTWORK")
		bossTexture:SetSize(16, 16)
		bossTexture:SetPoint("CENTER", bossButton, "CENTER", 0, 0)
		bossTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")

		bossButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(client_progress_cache["bosses"][i])
			GameTooltip:Show()
		end)
		bossButton:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
		xOffset = xOffset + crownButton:GetWidth() + 5
	end
end

local win_bools = {
	["mobs"] = false,
	["bosses"] = false,
	["time"] = false
}

function MythicLiteHandlers.ProgressUpdate(player, value, boss_counter) -- update the progress bar value and text
	print("value:" .. value)

	if value >= 100 and win_bools["mobs"] == false then
		win_bools["mobs"] = true
		print("Mobs condition met!")
	end

	if value > 0 and value <= 100 then
		statusbar:SetValue(tonumber(value))
		statusbarText:SetText(tostring(value) .. "%")
		print("progressing mob condition")
	end

	if boss_counter >= boss_max and win_bools["bosses"] == false then
		win_bools["bosses"] = true
		print("Bosses condition met!")
	end

	-- loop through the win bools and if all are true, determine victory true

	for k, v in pairs(win_bools) do
		if v == false then
			print("Uh oh, you didn't win anything yet!")
			return false
		end
	end
	print("winner chicken dinner!")

	local fadeout = prog:CreateAnimationGroup()
	local fade = fadeout:CreateAnimation("Alpha")
	fade:SetFromAlpha(1)
	fade:SetToAlpha(0)
	fade:SetDuration(5)
	fade:SetOrder(1)
	fadeout:SetScript("OnFinished", function(self)
		prog:Hide()
	end)
	fadeout:Play()
	print("Congratulations, you won!")
end

function MythicLiteHandlers.CloseFrame(player) -- close all frames
	mainframe:Hide()
	rerollParent:Hide()
end