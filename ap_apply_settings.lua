local json = require("json")
local XP = require("xp_cap")
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

WARRIOR_HEIRLOOM_ARMOR = {48685, 42949}
WARRIOR_HEIRLOOM_WEAPON = {48718, 42943, 42945, 44096}
WARRIOR_HEIRLOOM_TRINKET = {42991, 42992, 50255}
PALADIN_HEIRLOOM_ARMOR = {48685, 42949}
PALADIN_HEIRLOOM_WEAPON = {48718, 42948, 42945}
PALADIN_HEIRLOOM_TRINKET = {42991, 42992, 50255}
HUNTER_HEIRLOOM_ARMOR = {48677, 42950}
HUNTER_HEIRLOOM_WEAPON = {42945, 42944, 42944, 42943, 42946, 44093}
HUNTER_HEIRLOOM_TRINKET = {42991, 42992, 50255}
ROGUE_HEIRLOOM_ARMOR = {48689, 42952}
ROGUE_HEIRLOOM_WEAPON = {42945, 42944, 42944, 44096, 48716, 48716}
ROGUE_HEIRLOOM_TRINKET = {42991, 42992, 50255}
PRIEST_HEIRLOOM_ARMOR = {48691, 42985}
PRIEST_HEIRLOOM_WEAPON = {42947}
PRIEST_HEIRLOOM_TRINKET = {42991, 42992, 50255}
DEATH_KNIGHT_HEIRLOOM_ARMOR = {48685, 42949}
DEATH_KNIGHT_HEIRLOOM_WEAPON = {42945, 42943, 44096}
DEATH_KNIGHT_HEIRLOOM_TRINKET = {42991, 42992, 50255}
SHAMAN_HEIRLOOM_ARMOR = {48683, 42951}
SHAMAN_HEIRLOOM_WEAPON = {48718, 48716}
SHAMAN_HEIRLOOM_TRINKET = {42991, 42992, 50255}
MAGE_HEIRLOOM_ARMOR = {48691, 42985}
MAGE_HEIRLOOM_WEAPON = {42947}
MAGE_HEIRLOOM_TRINKET = {42991, 42992, 50255}
WARLOCK_HEIRLOOM_ARMOR = {48691, 42985}
WARLOCK_HEIRLOOM_WEAPON = {42947}
WARLOCK_HEIRLOOM_TRINKET = {42991, 42992, 50255}
DRUID_HEIRLOOM_ARMOR = {48689, 42952, 48687, 42984}
DRUID_HEIRLOOM_WEAPON = {42947}
DRUID_HEIRLOOM_TRINKET = {42991, 42992, 50255}

local HEIRLOOMS_BY_CLASS = {
    WARRIOR = {armor = WARRIOR_HEIRLOOM_ARMOR, weapon = WARRIOR_HEIRLOOM_WEAPON, trinket = WARRIOR_HEIRLOOM_TRINKET},
    PALADIN = {armor = PALADIN_HEIRLOOM_ARMOR, weapon = PALADIN_HEIRLOOM_WEAPON, trinket = PALADIN_HEIRLOOM_TRINKET},
    HUNTER = {armor = HUNTER_HEIRLOOM_ARMOR, weapon = HUNTER_HEIRLOOM_WEAPON, trinket = HUNTER_HEIRLOOM_TRINKET},
    ROGUE = {armor = ROGUE_HEIRLOOM_ARMOR, weapon = ROGUE_HEIRLOOM_WEAPON, trinket = ROGUE_HEIRLOOM_TRINKET},
    PRIEST = {armor = PRIEST_HEIRLOOM_ARMOR, weapon = PRIEST_HEIRLOOM_WEAPON, trinket = PRIEST_HEIRLOOM_TRINKET},
    DEATH_KNIGHT = {armor = DEATH_KNIGHT_HEIRLOOM_ARMOR, weapon = DEATH_KNIGHT_HEIRLOOM_WEAPON, trinket = DEATH_KNIGHT_HEIRLOOM_TRINKET},
    SHAMAN = {armor = SHAMAN_HEIRLOOM_ARMOR, weapon = SHAMAN_HEIRLOOM_WEAPON, trinket = SHAMAN_HEIRLOOM_TRINKET},
    MAGE = {armor = MAGE_HEIRLOOM_ARMOR, weapon = MAGE_HEIRLOOM_WEAPON, trinket = MAGE_HEIRLOOM_TRINKET},
    WARLOCK = {armor = WARLOCK_HEIRLOOM_ARMOR, weapon = WARLOCK_HEIRLOOM_WEAPON, trinket = WARLOCK_HEIRLOOM_TRINKET},
    DRUID = {armor = DRUID_HEIRLOOM_ARMOR, weapon = DRUID_HEIRLOOM_WEAPON, trinket = DRUID_HEIRLOOM_TRINKET},
}

-- loadSettings()
local function loadSettings()
        -- XP.setRate(1)
        -- zone unlocks
    print(settings)
    for key, value in pairs(settings) do
        print(key, value)
    end
    rate = math.min(10, settings.exp_rate)
    XP.setRate(rate)
end

local function applySettings(player)
    print('event fired', player:GetName())
    rate = settings.speed
    -- Assuming 'player' and 'targetUnit' are Unit objects
    --player:SetTarget(player)
    -- print(player:GetTarget())
    -- player.RunCommand(player, string.format('/target %s', player:GetName()))
    -- player.RunCommand(string.format('.target Fi))
    local restedRunSpeed = 60.0

    local convertedRestedRunSpeed = 1 + (restedRunSpeed / 100)
    player:SetSpeed(1, convertedRestedRunSpeed, true)  -- Increase run speed when entering a resting zone

    -- player.RunCommand(string.format('.modify speed %d', rate))
    -- local convertedRestedRunSpeed = 1 + (rate / 10)
    -- player:SetSpeed(1, convertedRestedRunSpeed, true)  -- Increase run speed when entering a resting zone
end

local function giveStartingItem(item, player)
    local added = player:AddItem(item, 1)

    if added then
        player:SendBroadcastMessage("You received item: " .. item)
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
        item, 1                        -- attachments
    )
end

local function giveStartingItems(player)
    print('Testing start')
    player_class = CLASS_ID_TO_NAME[player:GetClass()]
    heirloom_class_list = HEIRLOOMS_BY_CLASS[player_class]

    if settings.heirloom_armor then
        for _, value in ipairs(heirloom_class_list['armor']) do
            giveStartingItem(value, player)
        end
    end
    if settings.heirloom_weapons then
        for _, value in ipairs(heirloom_class_list['weapon']) do
            giveStartingItem(value, player)
        end    
    end
    if settings.heirloom_trinkets then
        for _, value in ipairs(heirloom_class_list['trinket']) do
            giveStartingItem(value, player)
        end
    end
    if settings.starting_money then
        player:ModifyMoney(settings.starting_money)
    end

    for _, zoneId in ipairs(settings["starting_zones"]) do
        if not ZoneLock.IsZoneUnlocked(player, zoneId) then
            ZoneLock.UnlockZone(player, zoneId)
        end
    end
end

-- Apply speed boost to enemy when combat starts
RegisterPlayerEvent(33, function(_, player, enemy)
    local rate = 1 + (settings.speed / 10)
    enemy:SetSpeed(1, rate, true)
end)


-- Apply speed boost to player on login
RegisterPlayerEvent(34, function(_, player)
    local rate = 1 + (settings.speed / 10)
    player:SetSpeed(1, rate, true)
end)

-- Give items on first login
RegisterPlayerEvent(30, function(_, player)
    giveStartingItems(player)
end)

loadSettings()