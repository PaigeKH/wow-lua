local json = require("json")
local itemQueueFile = "lua_scripts/ap_itemqueue.json"
local itemQueue = {}
local XP = require("xp_cap")
local ITEM_IDS = {
    [3] = "Progressive Level",
    [2] = "Gold",
    [5] = "Random Buff",
    [6] = "Random Debuff",
    [4] = "Progressive Riding",
    [7] = "Random Bag",
    [1] = "Victory"
}
local ZoneLock = require("ap_zone_lock")

local seenLocations = {}
local seenFilePath = "lua_scripts/data/archipelago_seen_locations.json"
local progressiveItemTotals = {}
local itemTotalsPath = "lua_scripts/data/archipelago_item_count.json"

local GOLD_AMOUNT = {
    [0] =  100 , -- 1s
    [1]  =  1000 , -- 10s
    [2] =  10000 , -- 1g
    [3]  =  100000 , -- 10g
    [4] =  1000000 , -- 100g
}

AP_CATEGORY = {
    -- Shared ids
    BASE = 10,
    ITEM = 11,
    QUEST = 12,
    ZONE = 13,
    LEVEL = 14,
    SPELL = 15,
    -- Class specific spells:
    WARRIOR = 20,
    DEATHKNIGHT = 21,
    PALADIN = 22,
    HUNTER = 23,
    SHAMAN = 24,
    ROGUE = 25,
    DRUID = 26, 
    PRIEST = 27,
    WARLOCK = 28,
    MAGE = 29
}

local APPRENTICE = {580, 470, 472, 6648, 458, 6653, 6654, 6777, 6899, 6898, 10873, 8395, 10796, 10799, 10969, 10793, 8394, 10789, 16058, 16059, 16060, 17453, 17454, 17455, 17456, 17458, 17462, 17463, 17464, 18989, 18990, 34406, 34795, 35020, 35022, 35018, 35711, 35710, 43899, 49378, 58983, 64658, 64657, 64977, 66847, 48025, 42776, 73313, 72286, 71342, 75614, 42776}
local JOURNEYMAN = {43688, 16056, 67466, 60114, 60116, 51412, 22719, 16055, 59572, 26656, 60118, 60119, 48027, 22718, 59785, 59788, 22720, 22721, 22717, 22723, 22724, 64656, 59573, 39315, 34896, 68188, 68187, 39316, 34790, 63635, 63637, 63639, 63643, 17460, 23509, 63638, 35713, 49379, 23249, 34407, 65641, 23248, 35712, 35714, 65637, 23247, 17465, 17459, 63656, 65917, 55531, 60424, 16084, 29059, 66846, 63640, 23246, 66090, 41252, 22722, 17481, 39317, 34898, 63642, 23510, 63232, 66091, 68057, 23241, 43900, 23238, 23229, 23250, 65646, 23220, 23221, 23239, 65640, 23252, 68056, 23219, 65638, 23242, 23243, 23227, 33660, 35027, 65644, 24242, 65639, 42777, 23338, 23251, 65643, 47037, 35028, 46628, 23223, 23240, 23228, 23222, 49322, 39318, 34899, 63641, 65642, 15779, 54753, 39319, 65645, 34897, 17229}
local EXPERT = {32244, 32239, 32235, 32245, 32240, 32243, 46197}
local ARTISAN = {60025, 63844, 61230, 61229, 40192, 59567, 41514, 62048, 59650, 59976, 72808, 61996, 59568, 59996, 39803, 59569, 58615, 43927, 41515, 64927, 48310, 65439, 61294, 39798, 72807, 63956, 44317, 44744, 63796, 41513, 69395, 60021, 41516, 39801, 59570, 59961, 61997, 39800, 67336, 63963, 66087, 39802, 66088, 32242, 32290, 37015, 32292, 32297, 32289, 32246, 32296, 60002, 59571, 49193, 41517, 41518, 60024, 46199}
local MAMMOTH = {61425, 61447}

local RIDING_SPELLS = {33388, 33391, 0, 34090, 54197, 34091}
local BUFFS = {57294, 72590, 48470, 20217, 48074, 20911, 48936, 17038}
local DEBUFFS = {7054, 3150, 8137, 16458, 15848, 23170, 15007, 5782, 8014, 6946, 16247}
local BAGS = {51809, 35874, 41600, 38082, 43345, 49295, 50316, 41599, 35516, 1977, 21876, 50317, 34067, 34845, 33117, 14156, 17966, 22679, 21843, 19914, 27680, 13330, 21841, 20400, 14155, 4500, 11742, 22233, 10959, 10683, 14046, 30744, 3914, 1685, 9587, 11324, 19291, 10050, 1652, 1725, 4499, 38145, 4981, 10051, 1623, 3762, 16057, 932, 4245, 804, 5764, 4497, 5575, 5576, 918, 857, 933, 6446, 3352, 1470, 1729, 5765, 5574, 3343, 4498, 1537, 5573, 5603, 3233, 5763, 6754, 856, 11845, 2657, 4240, 4241, 23852, 6756, 22571, 2082, 4496, 5762, 805, 4930, 5081, 4957, 5571, 828, 5572, 4238, 20474, 23389, 22976, 37606, 30806}

-- Utility to save local data
local function saveToFile()
    local file = io.open(seenFilePath, "w")
    if not file then
        print("[AP-LOC] Failed to open " .. seenFilePath .. " for writing.")
        return
    end
    local json = require("json")
    file:write(json.encode(seenLocations))
    file:close()
    print(string.format("[AP-LOC] Saved %d seen locations.", tablelength(seenLocations)))

    local file = io.open(itemTotalsPath, "w")
    if not file then
        print("[AP-LOC] Failed to open " .. itemTotalsPath .. " for writing.")
        return
    end
    local json = require("json")
    file:write(json.encode(progressiveItemTotals))
    file:close()
end

-- Utility to load on startup
local function loadFiles()
    local file = io.open(seenFilePath, "r")
    if not file then
        print("[AP-LOC] No seen locations file found.")
        return
    end
    local json = require("json")
    local content = file:read("*a")
    file:close()
    local ok, data = pcall(json.decode, content)
    if ok and type(data) == "table" then
        seenLocations = data
        print(string.format("[AP-LOC] Loaded %d seen locations.", tablelength(seenLocations)))
    else
        print("[AP-LOC] Failed to parse seen locations JSON.")
    end

    local file = io.open(itemTotalsPath, "r")
    if not file then
        print("[AP-LOC] No item counts file found.")
        return
    end
    local json = require("json")
    local content = file:read("*a")
    file:close()
    local ok, data = pcall(json.decode, content)
    if ok and type(data) == "table" then
        progressiveItemTotals = data
    else
        print("[AP-LOC] Failed to parse item counts JSON.")
    end
end

-- Utility to count table entries
function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

-- Load once when script starts
loadFiles()

-- Utility to read itemId
local function DecodeAPId(id)
    local s = tostring(id)
    local category = tonumber(s:sub(1, 2))
    local wowId    = tonumber(s:sub(3))
    return category, wowId
end


local M = {}

-- Handle received items from AP
function AP_AddReceivedItem(itemId, fromPlayer, locationId)

    print("AP_AddReceivedItem")
    print(seenLocations, locationId)
    print(seenLocations[locationId])
    print("checked location id")

    name = AP_ItemID_to_Name[itemId]
    print(name, itemId)

    -- Check if this item has been processed already
    if seenLocations[tostring(locationId)] then

        print(string.format("[AP-ITEMS] Skipping duplicate location %d (item %d)", locationId, itemId))
        return
    end

    -- Mark this location as seen and save
    seenLocations[tostring(locationId)] = true

    saveToFile()

    local players = GetPlayersInWorld()
    if #players == 0 then
        print("[AP-ITEMS] No players online, queuing item:", itemId)
        table.insert(itemQueue, itemId)
        saveQueue()
        return
    end 
    -- Apply effect to all online players

    local category, wowId = DecodeAPId(itemId)
    for _, player in pairs(GetPlayersInWorld()) do
        if itemId == 101 then -- victory
            player:CastSpell(player, 483, true)     -- Learn visual
            player:CastSpell(player, 21249, true)   -- Blue glow burst
            player:CastSpell(player, 6619, true)    -- Sparkle swirl
        elseif itemId == 102 then -- gold
            if not progressiveItemTotals["Gold"] then
                progressiveItemTotals["Gold"] = 0
            end
            progressiveItemTotals["Gold"] = 1 + progressiveItemTotals["Gold"]
            totalGold = progressiveItemTotals["Gold"]
            goldToGive = GOLD_AMOUNT[math.min(4, math.floor(totalGold / 100))]
            print("[AP-ITEMS] Granting gold")
            player:ModifyMoney(goldToGive)   
        elseif itemId == 103 then -- progressive level
            XP.AddToken()
            player:SendBroadcastMessage("|cff00FF00[AP]|r You received a Level Cap increase!")   
        elseif itemId == 104 then -- progressive riding
            if not progressiveItemTotals["Riding"] then
                progressiveItemTotals["Riding"] = 0
            end
            progressiveItemTotals["Riding"] = 1 + progressiveItemTotals["Riding"]
            totalRiding = progressiveItemTotals["Riding"]
            skill = RIDING_SPELLS[totalRiding]
            mount = APPRENTICE[math.random(#APPRENTICE)]
            if skill then
                player:LearnSpell(skill) -- skip mammoth tier
            end
            if totalRiding == 2 then
                mount = JOURNEYMAN[math.random(#JOURNEYMAN)]
            end
            if totalRiding == 3 then
                if player:IsAlliance() then
                    mount = MAMMOTH[1]
                else
                    mount = MAMMOTH[2]
                end
            end
            if totalRiding == 4 then
                mount = EXPERT[math.random(#EXPERT)]
            end
            -- 5 is cold weather and has no specific mount
            if totalRiding == 6 then
                mount = ARTISAN[math.random(#ARTISAN)]
            end
            if not totalRiding == 5 then
                player:LearnSpell(mount)
            end   
        elseif itemId == 105 then -- random buff
            buff = BUFFS[math.random(#BUFFS)]
            print("Adding buff", buff)
            player:CastSpell(player, buff , true)
            player:AddAura(buff, player)
            local pet = player:GetPet()
            if pet then
                pet:CastSpell(pet, buff , true)
                pet:AddAura(buff, pet)
            end   
        elseif itemId == 106 then -- random debuff
            debuff = DEBUFFS[math.random(#DEBUFFS)]
            print("Adding debuff", debuff)
            print(debuff)
            local pet = player:GetPet()
            if pet then
                pet:CastSpell(pet, debuff , true)
                pet:AddAura(debuff, pet)
            end
            player:CastSpell(player, debuff , true)
            player:AddAura(debuff, player)  
        elseif itemId == 107 then -- random bag
            bag = BAGS[math.random(#BAGS)]
            -- Try to add the item directly
            local added = player:AddItem(bag, 1)

            if added then
                player:SendBroadcastMessage("You received item: " .. bag)
                return
            end

            -- If AddItem failed (no space or restricted slot)
            local subject = "Item Delivery"
            local body = "Your bags were full, so your item was mailed instead."

            SendMail(
                subject,
                body,
                player:GetGUIDLow(),          -- receiver GUID
                player:GetGUIDLow(),          -- sender GUID
                41,                           -- stationery type
                0, 0, 0,                      -- money, COD, delay
                bag, 1                        -- attachments
            )
            
        elseif category == AP_CATEGORY.ZONE then
            -- handle WoW zone
            print("Handling Zone ID:", wowId)
            local zoneName = GetAreaName(wowId)
            player:SendBroadcastMessage(string.format("|cff00FFFF[AP]|r You unlocked |cffFFFFFF%s|r!", zoneName))
            print(string.format("[AP-ITEMS] %s gained %s (%d)", player:GetName(), zoneName, wowId))
            ZoneLock.UnlockZone(player, wowId)

        elseif category == AP_CATEGORY.SPELL then

            -- handle WoW spell
            print("Handling Spell ID:", wowId)

        elseif category == AP_CATEGORY.WARRIOR and player:GetClass() == 1 then
            player:LearnSpell(wowId)

        elseif category == AP_CATEGORY.DEATHKNIGHT and player:GetClass() == 6 then
            player:LearnSpell(wowId)


        elseif category == AP_CATEGORY.PALADIN and player:GetClass() == 2 then
            player:LearnSpell(wowId)


        elseif category == AP_CATEGORY.HUNTER and player:GetClass() == 3 then
            player:LearnSpell(wowId)
            if wowId == 1515 then
                player:LearnSpell(982) -- hunters need revive pet if they tame a pet so they don't softlock
            end

        elseif category == AP_CATEGORY.SHAMAN and player:GetClass() == 7 then
            player:LearnSpell(wowId)


        elseif category == AP_CATEGORY.ROGUE and player:GetClass() == 4 then
            player:LearnSpell(wowId)


        elseif category == AP_CATEGORY.DRUID and player:GetClass() == 11 then
            player:LearnSpell(wowId)


        elseif category == AP_CATEGORY.PRIEST and player:GetClass() == 5 then
            player:LearnSpell(wowId)


        elseif category == AP_CATEGORY.WARLOCK and player:GetClass() == 9 then
            player:LearnSpell(wowId)


        elseif category == AP_CATEGORY.MAGE and player:GetClass() == 8 then
            player:LearnSpell(wowId)

        else
            -- unknown fallback
            print("Unknown AP category:", category, "for ID:", apId)
        end
        player:SaveToDB()
    end
end

return M
