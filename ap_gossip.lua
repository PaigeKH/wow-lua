-- ap_gossip.lua
local QuestStarters = require("quest_ids")
local ZoneLock = require("ap_zone_lock")
local SpellVendor = require("ap_spell_vendor") -- optional if needed

local Gossip = {}
Gossip.debug = true

-- Utility logger
local function log(msg)
    if Gossip.debug then
        print("[ap_gossip] " .. msg)
    end
end

-- Unified gossip hello handler
local function OnGossipHello(event, player, creature)
    local zoneId = player:GetZoneId()
    local entry = creature:GetEntry()
    log(string.format("Gossip opened with %s (Entry %d, Zone %d)", creature:GetName(), entry, zoneId))

    -- Zone lock enforcement
    if not ZoneLock.IsZoneUnlocked(player, zoneId) then
        player:GossipClearMenu()
        player:GossipMenuAddItem(0, "A strange force prevents you from interacting here.", 0, 1)
        player:GossipSendMenu(1, creature)
        log("Blocked gossip due to locked zone.")

    -- Custom trainer vendor handling
    elseif SpellVendor.IsTrainerForPlayerClass(player, creature) and ZoneLock.IsZoneUnlocked(player, zoneId) then
        if SpellVendor and SpellVendor.OnGossipHelloForClass then
            SpellVendor.OnGossipHelloForClass(player, creature)
            log("Opened custom trainer vendor UI.")
        else
            creature:SendTrainerList(player)
            log("Opened normal trainer list.")
        end

    -- Custom trainer vendor handling
    elseif SpellVendor.IsRidingTrainer(creature) and ZoneLock.IsZoneUnlocked(player, zoneId) then
        if SpellVendor and SpellVendor.OnGossipHelloForRiding then
            SpellVendor.OnGossipHelloForRiding(player, creature)
            log("Opened custom trainer vendor UI.")
        else
            creature:SendTrainerList(player)
            log("Opened normal trainer list.")
        end

    -- Default (allow quest, vendor, etc.)
    else
        return false
    end
end

-- Gossip select handler
local function OnGossipSelect(event, player, creature, sender, intid, code)
    print("selecting")
    if SpellVendor.IsRidingTrainer(creature) then
        SpellVendor.OnGossipSelectForRiding(player, creature, intid)
        return true   
    else
        spellList = SpellVendor.GetSpellListForPlayer(player)
        SpellVendor.OnGossipSelectForClass(player, creature, spellList, intid)
        return true
    end
end

listeningOn = {}

-- Register for all class trainers - must go first so both listeners are set
for _, entry in ipairs(SpellVendor.ALL_TRAINERS or {}) do
    if not listeningOn[entry] then
        listeningOn[entry] = true
        RegisterCreatureGossipEvent(entry, 1, OnGossipHello)
        RegisterCreatureGossipEvent(entry, 2, OnGossipSelect)
    end
end

-- Register handlers for all quest starter creatures
for _, entry in ipairs(QuestStarters.starters.creatures) do
    if not listeningOn[entry] then
        listeningOn[entry] = true
        RegisterCreatureGossipEvent(entry, 1, OnGossipHello)
    end
end

-- Register handlers for all quest ender creatures
for _, entry in ipairs(QuestStarters.enders.creatures) do
    if not listeningOn[entry] then
        listeningOn[entry] = true
        RegisterCreatureGossipEvent(entry, 1, OnGossipHello)
    end
end

-- Register handlers for all quest starter gameobjects (like candybuckets)
for _, entry in ipairs(QuestStarters.starters.gameobjects) do
    if not listeningOn[entry] then
        listeningOn[entry] = true
        RegisterGameObjectGossipEvent(entry, 1, OnGossipHello)
    end
end

-- Register handlers for all quest ender gameobjects (like candybuckets)
for _, entry in ipairs(QuestStarters.enders.gameobjects) do
    if not listeningOn[entry] then
        listeningOn[entry] = true
        RegisterGameObjectGossipEvent(entry, 1, OnGossipHello)
    end
end

-- Maybe later register on quest.starters.items if we have a way to map location


log("Registered gossip handlers for " .. #QuestStarters.starters.creatures .. " quest starters.")

return Gossip
