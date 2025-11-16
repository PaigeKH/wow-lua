-- ap_deathlink.lua
local AP = require("arch_bridge")

-- === WoW → Archipelago ===
-- When a player dies, notify AP
local function onPlayerDeath(event, killer, killed)
    cause = "died in Azeroth"
    if killer then
        cause = "was killed by " .. killer:GetName()
    end
    print("on pllayer DEATHG")
    print(event)
    print(killer)
    local msg = {
        cmd = "Bounce",
        targets = {
            tags = {"DeathLink"}
        },
        data = {{
            time = os.time(),
            source = killed:GetName(),
            cause = cause
        }}
    }
    AP.send(msg)
    print("[AP-DEATHLINK] Sent death for", killed:GetName())
end
RegisterPlayerEvent(6, onPlayerDeath) -- EVENT_ON_KILL_PLAYER - environmental (or pvp)
RegisterPlayerEvent(8, onPlayerDeath) -- EVENT_ON_KILLED_BY_CREATURE - killed by

-- === Archipelago → WoW ===
-- When we receive a DeathLink, kill all players
AP.on("Bounce", function(msg)
    if msg.tags then
        for _, tag in ipairs(msg.tags) do
            if tag == "DeathLink" and msg.data and msg.data[1] then
                local dl = msg.data[1]
                print("[AP-DEATHLINK] Received death from", dl.source or "unknown")

                for _, player in pairs(GetPlayersInWorld()) do
                    if player:IsAlive() then
                        player:Kill(player)
                    end
                end
            end
        end
    end
end)
