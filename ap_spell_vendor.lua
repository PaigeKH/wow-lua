local CHECKS = require("ap_checks")
local json = require("json")
local playerDataPath = "lua_scripts/data"
local pageSize = 20 -- spells per page
local ZoneLock = require("ap_zone_lock")

local CLASS_ID_TO_NAME = {
    [1] = "WARRIOR",
    [2] = "PALADIN",
    [3] = "HUNTER",
    [4] = "ROGUE",
    [5] = "PRIEST",
    [6] = "DEATH_KNIGHT",
    [7] = "SHAMAN",
    [8] = "MAGE",
    [9] = "WARLOCK",
    [11] = "DRUID",
}


local WARRIOR_TRAINERS = { 3593, 914, 4594, 4087, 2131, 4595, 5114, 8141, 4593, 2119, 7315, 3153, 1229, 3353, 3059, 5480, 1901, 5113, 3043, 3063, 3598, 911, 913, 985, 3042, 4089, 514, 3354, 3169, 912, 3041, 5479, 3408 }
local PALADIN_TRAINERS = { 5491, 16501, 1232, 16761, 5148, 5149, 926, 8140, 925, 927, 16681, 20406, 16680, 15280, 17509, 5492, 17121, 928, 23128, 16275, 16679, 35281, 17483, 5147, 17844 }
local HUNTER_TRAINERS = { 17110, 8308, 3596, 5115, 3963, 10930, 3601, 16738, 4205, 5515, 1231, 16270, 3039, 4138, 3154, 4146, 5501, 3038, 16499, 17505, 1404, 3061, 987, 5116, 16673, 3352, 15513, 5117, 3407, 16672, 5517, 895, 3171, 5516, 3040, 17122, 3406, 3065, 16674 }
local ROGUE_TRAINERS = { 4215, 4582, 2122, 16685, 4214, 6707, 5167, 3594, 3327, 4584, 1234, 5165, 1411, 3599, 915, 3170, 917, 13283, 2130, 4583, 16686, 3328, 5166, 918, 15285, 3155, 3401, 916, 4163, 16279, 16684 }
local PRIEST_TRAINERS = { 4606, 16658, 4090, 16660, 5142, 837, 5484, 5489, 16756, 2129, 2123, 17511, 3046, 4607, 4608, 17482, 11406, 376, 17510, 4091, 3707, 4092, 3600, 16659, 3045, 15284, 1226, 3044, 11397, 16276, 11401, 375, 377, 3595, 3706, 5141, 5143, 6018, 6014, 16502, 5994 }
local DEATH_KNIGHT_TRAINERS = { 28474, 29194, 31084, 28471, 29195, 28472, 29196 }
local SHAMAN_TRAINERS = { 3032, 23127, 17204, 20407, 17089, 17520, 986, 17519, 3344, 3062, 3066, 13417, 3157, 3403, 3030, 17219, 3173, 3031, 17212 }
local MAGE_TRAINERS = { 28958, 28956, 29156, 944, 1228, 198, 328, 4165, 5144, 5145, 5146, 2489, 5498, 5497, 2485, 16500, 17481, 17514, 16749, 17513, 16755, 5884, 5880, 2124, 2128, 5885, 5883, 5882, 7311, 5958, 3047, 3049, 3048, 5957, 4568, 4566, 4567, 2492, 15279, 16269, 16653, 16652, 16651, 16654, 27703, 27705, 20791, 19340 }
local WARLOCK_TRAINERS = { 460, 16646, 5173, 23534, 5172, 16266, 461, 3172, 459, 5612, 3324, 4563, 988, 4564, 906, 2126, 3325, 3156, 4565, 2127, 5496, 6251, 15283, 16647, 5171, 5495, 16648, 3326 }
local DRUID_TRAINERS = { 4218, 4219, 3060, 3064, 9465, 16655, 8142, 3602, 3036, 12042, 5506, 3597, 4217, 16721, 3034, 5504, 5505, 3033 }
local RIDING_TRAINERS = { 20914, 7954, 35100, 31238, 20511, 4753, 3690, 4752, 35133, 20500, 16280, 28746, 4732, 31247, 4772, 4773, 35093, 35135, 7953 }

local SpellVendor = {}

-- High intid ranges for paging buttons
local NEXT_PAGE_BASE = 100000
local PREV_PAGE_BASE = 200000
local TALENT_RELEARN_BASE = 300000

-- Example class trainers and spell lists
-- Todo: spell_list is no longer listed by class
local CLASS_TRAINERS = {
    WARRIOR = {trainers = WARRIOR_TRAINERS, spells = SPELL_LIST_WARRIOR},
    PALADIN = {trainers = PALADIN_TRAINERS, spells = SPELL_LIST_PALADIN},
    HUNTER = {trainers = HUNTER_TRAINERS, spells = SPELL_LIST_HUNTER},
    ROGUE = {trainers = ROGUE_TRAINERS, spells = SPELL_LIST_ROGUE},
    PRIEST = {trainers = PRIEST_TRAINERS, spells = SPELL_LIST_PRIEST},
    DEATH_KNIGHT = {trainers = DEATH_KNIGHT_TRAINERS, spells = SPELL_LIST_DEATH_KNIGHT},
    SHAMAN = {trainers = SHAMAN_TRAINERS, spells = SPELL_LIST_SHAMAN},
    MAGE = {trainers = MAGE_TRAINERS, spells = SPELL_LIST_MAGE},
    WARLOCK = {trainers = WARLOCK_TRAINERS, spells = SPELL_LIST_WARLOCK},
    DRUID = {trainers = DRUID_TRAINERS, spells = SPELL_LIST_DRUID},
}

SpellVendor.SPELL_LIST_RIDING = {
    {54197, 10000000, 77, "Cold Weather Flying"},
    {34091, 50000000, 70, "Artisan Riding"},
    {34090, 2500000, 60, "Expert Riding"},
    {33391, 500000, 40, "Journeyman Riding"},
    {33388, 50000, 20, "Apprentice Riding"},
}

-- Ensure the purchases folder exists (no lfs required)
local function EnsurePurchaseDir()
    local testfile = io.open(playerDataPath .. "/_dirtest", "w")
    if not testfile then
        print("[ap_spell_vendor] Creating directory for purchases:", playerDataPath)
        os.execute("mkdir \"" .. playerDataPath .. "\"")
    else
        testfile:close()
        os.remove(playerDataPath .. "/_dirtest")
    end
end

EnsurePurchaseDir()

-- Money formatting helper
local function FormatMoney(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local copperRem = copper % 100
    local parts = {}
    if gold > 0 then table.insert(parts, gold .. "g") end
    if silver > 0 then table.insert(parts, silver .. "s") end
    if copperRem > 0 then table.insert(parts, copperRem .. "c") end
    if #parts == 0 then return "0c" end
    return table.concat(parts, " ")
end

-- JSON storage helpers
local function GetPlayerPurchasesFile(player)
    return string.format("%s/spell%d.json", playerDataPath, player:GetGUIDLow())
end

local function LoadPlayerPurchases(player)
    local path = GetPlayerPurchasesFile(player)
    local file = io.open(path, "r")
    if not file then return {} end
    local content = file:read("*a")
    file:close()
    local ok, data = pcall(json.decode, content)
    return ok and data or {}
end

local function SavePlayerPurchases(player, purchases)
    local path = GetPlayerPurchasesFile(player)
    local file = io.open(path, "w+")
    if file then
        file:write(json.encode(purchases))
        file:close()
    end
end

-- Filter available spells for a player
local function GetAvailableSpellsForClass(player, spellList)
    local purchases = LoadPlayerPurchases(player)
    local available = {}
    for i, entry in ipairs(spellList) do
        local spellId, cost, reqLevel, spellName = table.unpack(entry)
        if not purchases[tostring(spellId)] then
            table.insert(available, {
                index = i,
                spell = spellId,
                name = spellName,
                cost = cost,
                reqLevel = reqLevel
            })
        end
    end
    return available
end

-- Show a page of spells
local function ShowSpellPageForClass(player, creature, spellList, page)
    local spells = GetAvailableSpellsForClass(player, spellList)
    local totalPages = math.ceil(#spells / pageSize)
    if totalPages == 0 then
        if player.GossipClearMenu then player:GossipClearMenu() end
        player:GossipMenuAddItem(0, "|cff00ff00You have purchased all available spells!|r", 0, 0)
        player:GossipSendMenu(1, creature)
        return
    end
    if page < 1 then page = 1 end
    if page > totalPages then page = totalPages end
    local startIndex = (page - 1) * pageSize + 1
    local endIndex = math.min(startIndex + pageSize - 1, #spells)

    if player.GossipClearMenu then player:GossipClearMenu() end

    -- Add spells to gossip menu
    for i = startIndex, endIndex do
        local spell = spells[i]
        local color = "|cff660c0c"
        if player:GetLevel() >= spell.reqLevel then
            color = "|cff206720"
        end
        local label = string.format("%s%s - %s", color, spell.name, FormatMoney(spell.cost))
        if spell.reqLevel > 1 then
            label = label .. string.format(" (Requires level %d)", spell.reqLevel)
        end
        local intid = page * 1000 + spell.index
        player:GossipMenuAddItem(3, label, 0, intid)
    end

    -- Paging buttons
    if page > 1 then
        player:GossipMenuAddItem(0, "|cff00ff00« Previous Page|r", 0, PREV_PAGE_BASE + page)
    end
    if page < totalPages then
        player:GossipMenuAddItem(0, "|cff00ff00Next Page »|r", 0, NEXT_PAGE_BASE + page)
    end
    local label = string.format("Reset Talents for %s", FormatMoney(player:ResetTalentsCost()))
    player:GossipMenuAddItem(0, label, 0, TALENT_RELEARN_BASE)

    -- Show available quests (if any)
    if player.GossipAddQuests then
        player:GossipAddQuests(creature)
    end

    player:GossipSendMenu(1, creature)
end

-- Show a page of spells
local function ShowSpellPageForRiding(player, creature)
    local spells = GetAvailableSpellsForClass(player, SpellVendor.SPELL_LIST_RIDING)
    if #spells == 0 then
        if player.GossipClearMenu then player:GossipClearMenu() end
        player:GossipMenuAddItem(0, "|cff00ff00You have purchased all available spells!|r", 0, 0)
        player:GossipSendMenu(1, creature)
        return
    end

    if player.GossipClearMenu then player:GossipClearMenu() end

    -- Add spells to gossip menu
    for i = 1, #spells do
        local spell = spells[i]
        local color = "|cff660c0c"
        if player:GetLevel() >= spell.reqLevel then
            color = "|cff206720"
        end
        local label = string.format("%s%s - %s", color, spell.name, FormatMoney(spell.cost))
        if spell.reqLevel > 1 then
            label = label .. string.format(" (Requires level %d)", spell.reqLevel)
        end
        local intid = spell.index
        player:GossipMenuAddItem(3, label, 0, intid)
    end

    -- Show available quests (if any)
    if player.GossipAddQuests then
        player:GossipAddQuests(creature)
    end

    player:GossipSendMenu(1, creature)
end

-- Handle gossip selection (no real spell learning)
function SpellVendor.OnGossipSelectForClass(player, creature, spellList, intid)
    if not intid then return end

    -- Handle Reset Talents button
    if intid == TALENT_RELEARN_BASE then
        if player:GetFreeTalentPoints() == player:GetLevel() - 9 or player:GetLevel() < 10 then
            player:SendAreaTriggerMessage("No points to reset.")
            player:PlayDirectSound(1428)
            player:GossipComplete()
            return
        elseif player:GetCoinage() < player:ResetTalentsCost() then
            player:SendAreaTriggerMessage("Not enough gold.")
            player:PlayDirectSound(1428)
            player:GossipComplete()
            return
        end
        player:ModifyMoney(-player:ResetTalentsCost())
        player:SendBroadcastMessage("|cffffd700Your talents have been reset.|r")
        player:ResetTalents()
        ShowSpellPageForClass(player, creature, spellList, 1)
        player:GossipComplete()
        return
    end

    -- Handle paging buttons
    if intid >= NEXT_PAGE_BASE and intid < PREV_PAGE_BASE then
        local page = intid - NEXT_PAGE_BASE
        ShowSpellPageForClass(player, creature, spellList, page + 1)
        return
    elseif intid >= PREV_PAGE_BASE then
        local page = intid - PREV_PAGE_BASE
        ShowSpellPageForClass(player, creature, spellList, page - 1)
        return
    end

    -- Decode page + spellIndex
    local page = math.floor(intid / 1000)
    local spellIndex = intid % 1000
    local spellData = spellList[spellIndex]
    if not spellData then return end

    local spellId, cost, reqLevel, spellName = table.unpack(spellData)
    -- Level check
    if player:GetLevel() < reqLevel then
        player:SendAreaTriggerMessage("Requires level " .. reqLevel)
        player:PlayDirectSound(1428)
        ShowSpellPageForClass(player, creature, spellList, page)
    -- Gold check
    elseif player:GetCoinage() < cost then
        player:SendAreaTriggerMessage("Not enough gold.")
        player:PlayDirectSound(1428)
        ShowSpellPageForClass(player, creature, spellList, page)
    else
        -- Deduct gold
        player:ModifyMoney(-cost)
        -- “Learn Spell” visual effect
        player:CastSpell(player, 483, true)

        -- Archipelago integration: send location check
        CHECKS.completeSpellCheck(player, spellId)

        -- Save purchase locally to JSON
        local purchases = LoadPlayerPurchases(player)
        purchases[tostring(spellId)] = true
        SavePlayerPurchases(player, purchases)

        -- Message and refresh
        player:SendBroadcastMessage("Archipelago check sent for: " .. spellName)
        ShowSpellPageForClass(player, creature, spellList, page)
    end
end

-- Handle gossip selection (no real spell learning)
function SpellVendor.OnGossipSelectForRiding(player, creature, intid)
    -- Decode page + spellIndex
    local spellData = SpellVendor.SPELL_LIST_RIDING

    local spellId, cost, reqLevel, spellName = table.unpack(spellData[intid])
    print('hi', spellId, cost, reqLevel, spellName)

    -- Level check
    if player:GetLevel() < reqLevel then
        player:SendAreaTriggerMessage("Requires level " .. reqLevel)
        player:PlayDirectSound(1428)
        ShowSpellPageForRiding(player, creature)
    -- Gold check
    elseif player:GetCoinage() < cost then
        player:SendAreaTriggerMessage("Not enough gold.")
        player:PlayDirectSound(1428)
        ShowSpellPageForRiding(player, creature)
    else
        -- Deduct gold
        player:ModifyMoney(-cost)
        -- “Learn Spell” visual effect
        player:CastSpell(player, 483, true)

        -- Archipelago integration: send location check
        CHECKS.completeSpellCheck(player, spellId)

        -- Save purchase locally to JSON
        local purchases = LoadPlayerPurchases(player)
        purchases[tostring(spellId)] = true
        SavePlayerPurchases(player, purchases)

        -- Message and refresh
        player:SendBroadcastMessage("Archipelago check sent for: " .. spellName)
        ShowSpellPageForRiding(player, creature)
    end
end

-- Handle gossip hello 
function SpellVendor.OnGossipHelloForClass(player, creature) 
    local playerClass = player:GetClass()
    local className = CLASS_ID_TO_NAME[playerClass]
    local classData = CLASS_TRAINERS[className]

    ShowSpellPageForClass(player, creature, classData.spells, 1)
end

-- Handle gossip hello 
function SpellVendor.OnGossipHelloForRiding(player, creature) 
    ShowSpellPageForRiding(player, creature)
end

-- Fetch all spells for a class
function SpellVendor.GetSpellListForPlayer(player)
    local playerClass = player:GetClass()
    local className = CLASS_ID_TO_NAME[playerClass]
    local spellList = CLASS_TRAINERS[className].spells
    return spellList
end

function SpellVendor.IsTrainerForPlayerClass(player, creature)
    local classId = player:GetClass()
    local className = CLASS_ID_TO_NAME[classId]
    local classData = CLASS_TRAINERS[className]
    local creatureId = creature:GetEntry()
    for _, id in ipairs(classData.trainers or {}) do
        if id == creatureId then
            return true
        end
    end
    return false
end

function SpellVendor.IsRidingTrainer(creature)
    local creatureId = creature:GetEntry()
    for _, id in ipairs(RIDING_TRAINERS or {}) do
        if id == creatureId then
            return true
        end
    end
    return false
end

-- Combined list of all trainer IDs (for ap_gossip.lua)
SpellVendor.ALL_TRAINERS = {}

for _, data in pairs(CLASS_TRAINERS) do
    for _, entryId in ipairs(data.trainers or {}) do
        table.insert(SpellVendor.ALL_TRAINERS, entryId)
    end
end
for _, id in ipairs(RIDING_TRAINERS or {}) do
    table.insert(SpellVendor.ALL_TRAINERS, id)
end

return SpellVendor
