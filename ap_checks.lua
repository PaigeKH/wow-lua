-- ap_checks.lua
local AP = require("arch_bridge")
local json = require("json")
local checksFilePath = "lua_scripts/data/archipelago_checks.json"

-- Utility: count table entries
local function tablelength(t)
    local c = 0
    for _ in pairs(t) do c = c + 1 end
    return c
end

local PREPEND = 12

local BREADCRUMB_MAP = { -- these quests are unavailable if the next step is completed
  [5] = {163},
  [11] = {239},
  [95] = {164},
  [148] = {165},
  [261] = {6141},
  [276] = {463},
  [297] = {436},
  [353] = {1097},
  [364] = {363},
  [413] = {415},
  [429] = {428},
  [455] = {468},
  [466] = {467},
  [518] = {495},
  [639] = {638},
  [691] = {690},
  [729] = {730},
  [788] = {787, 4641},
  [844] = {860},
  [870] = {886},
  [1011] = {4581},
  [1057] = {1056},
  [1085] = {1070},
  [1204] = {1260},
  [1275] = {3765},
  [1302] = {1301},
  [1338] = {1339},
  [1395] = {1477},
  [1420] = {1418},
  [1473] = {1478},
  [1501] = {1506},
  [1524] = {1522, 1523, 2983, 2984},
  [1530] = {1528, 1529, 2985, 2986},
  [1688] = {1685, 1715},
  [1699] = {1698},
  [1705] = {1700},
  [1708] = {1704},
  [1710] = {1703},
  [1716] = {1717},
  [1758] = {1798},
  [1796] = {4736, 4737, 4738, 4739},
  [1799] = {4965, 4967, 4968, 4969},
  [1801] = {2996, 3001},
  [1824] = {1823},
  [1842] = {1839},
  [1844] = {1840},
  [1846] = {1841},
  [1861] = {1860},
  [1880] = {1879},
  [1882] = {1881},
  [1884] = {1883},
  [1920] = {1919},
  [1938] = {1939},
  [1944] = {1943},
  [1960] = {1959},
  [2038] = {2039},
  [2040] = {2041},
  [2206] = {2205},
  [2238] = {2218},
  [2242] = {2241},
  [2260] = {2259},
  [2281] = {2260, 2298, 2300},
  [2298] = {2299},
  [2770] = {2769},
  [2846] = {2861},
  [2865] = {2864},
  [2922] = {2923},
  [2924] = {2925},
  [2930] = {2931},
  [2975] = {2981},
  [3761] = {936, 3762, 3784},
  [3764] = {3763, 3789, 3790},
  [3791] = {3787, 3788},
  [4126] = {4128},
  [4134] = {4133},
  [4136] = {4324},
  [4505] = {6605},
  [4734] = {4907},
  [4764] = {4766},
  [4768] = {4769},
  [4861] = {6604},
  [5082] = {6603},
  [5092] = {5066, 5090, 5091},
  [5096] = {5093, 5094, 5095},
  [5244] = {5249, 5250},
  [6383] = {235, 742, 6382},
  [6607] = {6609},
  [6610] = {6611, 6612},
  [6622] = {6623, 6623, 6623, 6623},
  [6624] = {6625, 6625, 6625, 6625},
  [7488] = {7494},
  [7489] = {7492},
  [8280] = {8275, 8276},
  [8414] = {8415},
  [9052] = {9063},
}

-- Save completed locations to file
local function saveChecks()
    local file = io.open(checksFilePath, "w")
    if not file then
        print("[AP-CHECKS] Failed to open for writing:", checksFilePath)
        return
    end
    file:write(json.encode(AP_Checks))
    file:close()
    print(string.format("[AP-CHECKS] Saved %d completed locations.", tablelength(AP_Checks)))
end

-- Load completed locations from file
local function loadChecks()
    local file = io.open(checksFilePath, "r")
    if not file then
        print("[AP-CHECKS] No previous checks file found.")
        return
    end
    local content = file:read("*a")
    file:close()

    local ok, data = pcall(json.decode, content)
    if ok and type(data) == "table" then
        AP_Checks = data
        print(string.format("[AP-CHECKS] Loaded %d completed locations.", tablelength(AP_Checks)))
    else
        print("[AP-CHECKS] Failed to parse check file.")
    end
end

-- Send a quest completion as a LocationCheck via bridge
local function completeQuestCheck(player, questId)
    local loc = tostring(AP_CATEGORY.QUEST) .. tostring(questId)
    if not loc then
        print("[AP-CHECKS] No AP location for quest:", questId)
        return
    end

    dependsOn = BREADCRUMB_MAP[questId]
    if dependsOn then
        for _, subQuestId in ipairs(dependsOn) do
            completeQuestCheck(player, subQuestId)
        end
    end

    if loc then
        AP_Checks[loc] = true
        saveChecks()
    end

    print(string.format("[AP-CHECKS] Quest complete -> sent location %s", key))
    AP.sendItem(loc, 0)
end

-- Hook quest reward
RegisterPlayerEvent(54, function(event, player, quest)
    player:SaveToDB()
    print("quest hit", quest:GetId())
    completeQuestCheck(player, quest:GetId())
end)

-- Hook level-up
RegisterPlayerEvent(13, function(event, player, oldLevel)
    local newLevel = player:GetLevel()
    local loc = tostring(AP_CATEGORY.LEVEL) .. tostring(newLevel)

    player:SaveToDB()
    print("[AP-CHECKS] Player leveled up:", newLevel)
    if loc then
        AP_Checks[loc] = true
        saveChecks()
        AP.sendItem(loc, 0)
    end
end)


local CHECKS = {}

-- On purchasing a spell
function CHECKS.completeSpellCheck(player, spellId)
    print(player, spellId)
    player:SaveToDB()
    local playerClass = player:GetClass()
    local loc = 0

    if playerClass == 1 then
        loc = tostring(AP_CATEGORY.WARRIOR) .. tostring(spellId)
    elseif playerClass == 2 then
        loc = tostring(AP_CATEGORY.PALADIN) .. tostring(spellId)
    elseif playerClass == 3 then
        loc = tostring(AP_CATEGORY.HUNTER) .. tostring(spellId)
    elseif playerClass == 4 then
        loc = tostring(AP_CATEGORY.ROGUE) .. tostring(spellId)
    elseif playerClass == 5 then
        loc = tostring(AP_CATEGORY.PRIEST) .. tostring(spellId)
    elseif playerClass == 6 then
        loc = tostring(AP_CATEGORY.DEATHKNIGHT) .. tostring(spellId)
    elseif playerClass == 7 then
        loc = tostring(AP_CATEGORY.SHAMAN) .. tostring(spellId)
    elseif playerClass == 8 then
        loc = tostring(AP_CATEGORY.MAGE) .. tostring(spellId)
    elseif playerClass == 9 then
        loc = tostring(AP_CATEGORY.WARLOCK) .. tostring(spellId)
    elseif playerClass == 11 then
        loc = tostring(AP_CATEGORY.DRUID) .. tostring(spellId)
    end

    if loc then
        AP_Checks[loc] = true
        saveChecks()
        print("[AP-CHECKS] Quest complete -> AP location:", loc)
        AP.sendItem(loc, 0)
    end
end

-- On learn
local function OnLearnSpell(event, player, spellId)
    if spellId < 900000 then
        RunCommand(string.format(".player unlearn %s %d", player:GetName(), spellId))
        CHECKS.completeSpellCheck(player, spellId)
    end
end

RegisterPlayerEvent(44, OnLearnSpell)


-- Load data on login
RegisterPlayerEvent(3, function(_, player)
    loadChecks(player)
end)



return CHECKS
