local json = require("json") -- make sure lua_scripts/json.lua is available
local XP = require("xp_cap")

-- Path to save per-player zone data
local ZONE_SAVE_PATH = "lua_scripts/data/zone"

-- Cache of player zone unlocks (loaded from disk)
local PlayerZones = {}
local ZoneLock = {}


-- When a main zone is unlocked, also unlock these subzones
local ZONE_SUBZONE_MAP = {
    [12] = { 1519 },
    [14]  = { 1637 },
    [141] = { 1657 },
    [215]  = { 1638 },
    [85] = { 1497 },
    [1]  = { 1537 },
    [3430] = { 3487 },
    [3524]  = { 3557 },
    [3519] = { 3703 },
    [2817]  = { 4395 },
}


--------------------------------------------------
-- Utility functions
--------------------------------------------------

local function GetZoneFile(player)
    return string.format("%s%d.json", ZONE_SAVE_PATH, player:GetGUIDLow())
end

function ZoneLock.IsZoneUnlocked(player, zoneId)
    local guid = player:GetGUIDLow()
    return PlayerZones[guid] and PlayerZones[guid][zoneId]
end

local function SaveZones(player)
    local guid = player:GetGUIDLow()
    local zones = PlayerZones[guid] or {}

    -- convert numeric zone IDs to string keys for JSON safety
    local safeZones = {}
    for id, v in pairs(zones) do
        safeZones[tostring(id)] = v
    end

    local data = { unlocked_zones = safeZones }

    local f, err = io.open(GetZoneFile(player), "w")
    if not f then
        print("[ZoneLock] Failed to open file for write:", err)
        return
    end

    f:write(json.encode(data))
    f:close()
end

local function LoadZones(player)
    local guid = player:GetGUIDLow()
    local path = GetZoneFile(player)

    local f = io.open(path, "r")
    if not f then
        PlayerZones[guid] = {}
        return
    end

    local content = f:read("*a")
    f:close()

    local ok, data = pcall(json.decode, content)
    if ok and type(data) == "table" and type(data.unlocked_zones) == "table" then
        -- convert string keys back to numbers
        PlayerZones[guid] = {}
        for k, v in pairs(data.unlocked_zones) do
            PlayerZones[guid][tonumber(k)] = v
        end
    else
        PlayerZones[guid] = {}
        print("[ZoneLock] Invalid JSON for player " .. guid)
    end
end


local function SendZonesToXP()
    -- Combine all unlocked zones across all players (or global unlocks if desired)
    local globalUnlocked = {}
    local unique = {}
    for _, zones in pairs(PlayerZones) do
        for id, unlocked in pairs(zones) do
            if unlocked and not unique[id] then
                table.insert(globalUnlocked, id)
                unique[id] = true
            end
        end
    end
    XP.SetUnlockedZones(globalUnlocked)
end

--------------------------------------------------
-- Public API (for Archipelago items)
--------------------------------------------------

function ZoneLock.UnlockZone(player, zoneId)
    local guid = player:GetGUIDLow()
    PlayerZones[guid] = PlayerZones[guid] or {}

    local function unlockOne(id)
        if not PlayerZones[guid][id] then
            PlayerZones[guid][id] = true
            print(string.format("[ZoneLock] %s unlocked zone %d", player:GetName(), id))
        end
    end

    unlockOne(zoneId)

    if ZONE_SUBZONE_MAP[zoneId] then
        for _, subId in ipairs(ZONE_SUBZONE_MAP[zoneId]) do
            unlockOne(subId)
        end
    end

    SaveZones(player)
    SendZonesToXP()
    player:SendBroadcastMessage(string.format("Zone %d and subzones unlocked!", zoneId))
end


--------------------------------------------------
-- Event Handlers
--------------------------------------------------

-- Load data on login
RegisterPlayerEvent(3, function(_, player)
    LoadZones(player)
    SendZonesToXP()
end)

return ZoneLock
