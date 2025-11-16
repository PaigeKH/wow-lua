-- xp_cap.lua
-- Handles level caps, stored XP, and zone locking

local json = require("json")
local XP = {}
XP.allowed_zones = {}

XP.MAX_LEVEL = 5
XP.tokens = 0
XP.stored_xp = {}
local xp_state_file = "lua_scripts/data/xp_cap.json"

-- =========================
-- Persistence
-- =========================
function XP.save()
    local f = io.open(xp_state_file, "w+")
    if not f then
        print("[XP-CAP] ERROR: Could not open file for writing:", xp_state_file)
        return
    end

    local stored_str = {}
    for guid, xp in pairs(XP.stored_xp) do
        stored_str[tostring(guid)] = xp
    end

    local data = {
        tokens = XP.tokens,
        stored_xp = stored_str,
        unlocked_zones = XP.unlocked_zones
    }

    f:write(json.encode(data))
    f:close()
end

function XP.load()
    local f = io.open(xp_state_file, "r")
    if not f then
        print("[XP-CAP] No existing XP state file, starting fresh (all zones locked)")
        XP.unlocked_zones = {}
        return
    end

    local content = f:read("*a")
    f:close()
    local ok, data = pcall(json.decode, content)
    if ok and data then
        XP.tokens = data.tokens or 0
        XP.stored_xp = {}
        XP.unlocked_zones = data.unlocked_zones or {}
        if data.stored_xp then
            for k, v in pairs(data.stored_xp) do
                XP.stored_xp[tonumber(k)] = v
            end
        end
        print(string.format("[XP-CAP] Loaded. Tokens=%d, Cap=%d, Unlocked zones=%d",
            XP.tokens, XP.GetCap(), #XP.unlocked_zones))
    else
        print("[XP-CAP] ERROR decoding XP file:", data)
        XP.unlocked_zones = {}
    end
end

-- =========================
-- Zone Lock Logic
-- =========================

function XP.SetUnlockedZones(zoneList)
    XP.allowed_zones = {}
    for _, id in ipairs(zoneList) do
        XP.allowed_zones[id] = true
    end
    print(string.format("[XP-CAP] Received %d unlocked zones from ZoneLock.", #zoneList))
end

-- =========================
-- Cap logic
-- =========================
function XP.GetCap()
    return XP.MAX_LEVEL + XP.tokens
end

local function getStoredXP(player)
    local guid = player:GetGUIDLow()
    return XP.stored_xp[guid] or 0
end

local function setStoredXP(player, amount)
    local guid = player:GetGUIDLow()
    XP.stored_xp[guid] = amount
    XP.save()
end

-- =========================
-- Hook: block XP if capped or zone locked
-- =========================
function XP.OnGiveXP(event, player, amount, victim)
    local zoneId = player:GetZoneId()

    -- Block all XP if zone not in allowed list
    if not XP.allowed_zones[zoneId] then
        player:SendBroadcastMessage(
            string.format("[AP-XP] Zone %d is locked. No XP gained or stored.", zoneId)
        )
        return 0
    end

    -- Otherwise, normal XP logic applies
    if player:GetLevel() >= XP.GetCap() then
        local stored = getStoredXP(player)
        setStoredXP(player, stored + amount)
        pet = player:GetPet()
        if pet and pet:GetLevel() < player:GetLevel() then
            pet:GiveXP(amount)
        end
        player:SendBroadcastMessage(
            string.format("[AP-XP] Stored %d XP (total stored: %d)", amount, stored + amount)
        )
        return 0
    end
    return amount
end

-- =========================
-- Token handling
-- =========================
local XP_TABLE = {
    [1] = 400, [2] = 900, [3] = 1400, [4] = 2100, [5] = 2800,
    [6] = 3600, [7] = 4500, [8] = 5400, [9] = 6500, [10] = 7600,
    [11] = 8800, [12] = 10100, [13] = 11400, [14] = 12900, [15] = 14400,
    [16] = 16000, [17] = 17700, [18] = 19400, [19] = 21300, [20] = 23200,
    [21] = 25200, [22] = 27300, [23] = 29400, [24] = 31700, [25] = 34000,
    [26] = 36400, [27] = 38900, [28] = 41400, [29] = 44300, [30] = 47400,
    [31] = 50800, [32] = 54500, [33] = 58600, [34] = 62800, [35] = 67100,
    [36] = 71600, [37] = 76100, [38] = 80800, [39] = 85700, [40] = 90700,
    [41] = 95800, [42] = 101000, [43] = 106300, [44] = 111800, [45] = 117500,
    [46] = 123200, [47] = 129100, [48] = 135100, [49] = 141200, [50] = 147500,
    [51] = 153800, [52] = 160300, [53] = 166900, [54] = 173600, [55] = 180400,
    [56] = 187300, [57] = 194300, [58] = 201400, [59] = 209000, [60] = 220000,
    [61] = 230000, [62] = 240000, [63] = 250000, [64] = 260000, [65] = 272000,
    [66] = 284000, [67] = 296000, [68] = 308000, [69] = 320000, [70] = 333000,
    [71] = 346000, [72] = 359000, [73] = 372000, [74] = 386000, [75] = 400000,
    [76] = 415000, [77] = 430000, [78] = 445000, [79] = 460000, [80] = 0
}

local function GetXPForLevel(level)
    return XP_TABLE[level] or 0
end

local function GrantLevelToken(player)
    local nextLevel = player:GetLevel() + 1
    if nextLevel <= XP.GetCap() then
        local xpNeeded = GetXPForLevel(nextLevel) - player:GetXP()
        local storedXP = getStoredXP(player)
        if storedXP >= xpNeeded then
            player:GiveXP(xpNeeded)
            setStoredXP(player, storedXP - xpNeeded)
            local pet = player:GetPet()
            if pet then
                pet:GivePetLevel(nextLevel)
            end
        else
            player:GiveXP(storedXP, 0)
            setStoredXP(player, 0)
            local pet = player:GetPet()
            if pet then
                pet:GivePetLevel(nextLevel)
            end
        end
    end
end

function XP.AddToken()
    XP.tokens = XP.tokens + 1
    print(string.format("[AP-XP] Token received. Tokens=%d, New cap=%d", XP.tokens, XP.GetCap()))
    for _, player in pairs(GetPlayersInWorld()) do
        GrantLevelToken(player)
    end
    XP.save()
end

RegisterPlayerEvent(3, function(event, player)
    player:SendBroadcastMessage(
        string.format("Your current level cap is %d.", XP.GetCap())
    )
end)

-- =========================
-- Startup
-- =========================
XP.load()

CreateLuaEvent(function()
    XP.save()
end, 300000, 0) -- save every 5 minutes

RegisterPlayerEvent(12, XP.OnGiveXP)

return XP
