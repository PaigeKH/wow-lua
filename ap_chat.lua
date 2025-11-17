-- ap_chat.lua
local AP = require("arch_bridge")

-- WoW → Archipelago
local function onPlayerChat(event, player, msg, type, lang)
    command = msg:gsub("^%s*(.-)%s*$", "%1")
    lowerCommand = string.lower(command)

    if lowerCommand:find("^" .. "!connect") then -- Check prefix

        data = {}
        for chunk in string.gmatch(command, "%S+") do
            table.insert(data, chunk)
        end


        if #data == 3 or #data == 4 then
            AP.OnLogin(data[2], data[3], (data[4] or ""))
        end

        
    else 
        AP.send({
            cmd = "Say",
            text = msg,
        })
        print("[AP-CHAT] Sent:", msg)
    end
end
RegisterPlayerEvent(18, onPlayerChat) -- EVENT_PLAYER_CHAT

-- Archipelago → WoW
AP.on("Say", function(msg)
    local text = "[AP] " .. (msg.sender or "") .. ": " .. (msg.text or "")
    print("[AP-CHAT] Recv:", text)

    -- Send to all WoW players
    for _, player in pairs(GetPlayersInWorld()) do
        player:SendBroadcastMessage(text)
    end
end)

RegisterPlayerEvent(42, function(event, player, command, chatHandler)
    print(command)
end)