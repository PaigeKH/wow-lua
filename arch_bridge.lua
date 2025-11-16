-- arch_bridge.lua
local json = require("json")
local ap_items = require("AP_ItemIds")
local BRIDGE_URL = "http://localhost:3000"

local AP = {}
AP.handlers = {}
AP.PLAYER_NAME = "PaigeWoW"
AP_Checks = {}

-- Send a Lua table as JSON
function AP.send(packet)
    local body = json.encode(packet)
    print('send', packet, body)
    HttpRequest("POST", BRIDGE_URL .. "/send", body, "application/json", function(status, respBody)
        print("[AP] Sent:", body, "Status:", status)
    end)
end

-- Helper: send an item to Archipelago
function AP.sendItem(locationName)
    local locationId = AP_LocationIds[locationName]
    if not locationId then
        print("[AP] ERROR: Unknown location name: " .. tostring(locationName))
        return
    end
    local packet = {
        cmd = "LocationChecks",
        locations = { locationId }
    }
    print(locationId)
    print(string.format("[AP] Sending item (loc=%s)", locationId))
    AP.send(packet)
end

-- Incoming dispatcher
function AP.handleIncoming(msg)
    if not msg.cmd then
        print("[AP<-Bridge] Dropped unknown message:", json.encode(msg))
        return
    end

    print("[AP<-Bridge] Handling incoming:", msg.cmd, json.encode(msg)) -- <== more detail
    print('handleIncoming')
    if msg.cmd == "ReceivedItems" then  --not used 
        print('handleIncoming item')
        if msg.items then
            print(string.format("[AP] ReceivedItems payload with %d items", #msg.items))
            for _, item in ipairs(msg.items) do
                print(string.format("[AP] Received item: id=%d location=%d from player=%d flags=%d",
                                    item.item or -1,
                                    item.location or -1,
                                    item.player or -1,
                                    item.flags or -1))
                ap_items.AP_AddReceivedItem(item.item, item.player)
            end
        else
            print("[AP] ReceivedItems with no items payload")
        end
    elseif msg.cmd == "Print" or msg.cmd == "Say" then
	print('say')
        SendWorldMessage("[AP] " .. (msg.text or ""))
    else
        print("[AP<-Bridge] Unhandled:", json.encode(msg))
    end
end

function AP.onHttpReceive(body)
    print("[AP<-Bridge] Raw HTTP body:", body) -- <== raw logging
    local ok, msg = pcall(function() return json.decode(body) end)
    if not ok or not msg then
        print("[AP<-Bridge] Invalid JSON from bridge:", body)
        return
    end

    if msg[1] ~= nil then
        print(string.format("[AP<-Bridge] Decoded %d messages", #msg))
        for _, single in ipairs(msg) do
            AP.handleIncoming(single)
        end
    else
        print("[AP<-Bridge] Decoded single message")
        AP.handleIncoming(msg)
    end
end


-- Register a handler for incoming packets
function AP.on(cmd, fn)
    AP.handlers[cmd] = fn
end

-- Poll bridge for incoming messages
local function poll()
    -- Schedule the next poll *first* so it always happens
    CreateLuaEvent(poll, 2000, 1)

    HttpRequest("GET", BRIDGE_URL .. "/recv", function(status, body)
        if status == 200 and body and #body > 0 then
            local ok, messages = pcall(json.decode, body)
            if ok and type(messages) == "table" then
                for _, msg in ipairs(messages) do
                    print('[AP-RAW]', type(msg), json.encode(msg))
                    if msg.cmd and AP.handlers[msg.cmd] then
                        print("[AP-DISPATCH] ->", msg.cmd)
                        AP.handlers[msg.cmd](msg)
                    else
                        print("[AP] Got:", json.encode(msg))
                    end
                end
            else
                print("[AP] Decode failed:", body)
            end
        elseif status ~= 200 then
            print("[AP] Bridge not ready yet (status " .. tostring(status) .. ")")
        end
    end)
end



AP.on("ReceivedItems", function(msg)
    if msg.items then
        for _, item in ipairs(msg.items) do
            print(item)
            print(string.format("[AP] Received item: id=%d (from player %d), location=%d", item.item, item.player, item.location))
            -- Pass numeric ID only
            if item.location >= 0 then
                AP_AddReceivedItem(item.item, item.player, item.location)
            end
        end
        for _, player in pairs(GetPlayersInWorld()) do
            player:SaveToDB()
        end
    else
        print("[AP] ReceivedItems with no items payload")
    end
end)

-- Kick things off
poll()

-- On login
function AP.OnLogin(url, slot, password)
    print("logging in")

    local checkKeys = {}
    for key, _ in pairs(AP_Checks or {}) do
        table.insert(checkKeys, tonumber(key))
    end
    AP.send({cmd = "Login", checks = checkKeys, url = url, slot = slot, password = password})
    -- AP.send({cmd = "Login", checks = checkKeys, url = 'ws://localhost:38281', slot = 'PaigeWoW', password = ''})
    -- !connect ws://localhost:38281 paige
end

-- On logout
local function OnLogout(event, player)
    print("logging ouut")
    AP.send({cmd = "Logout"})
end


-- RegisterPlayerEvent(3, OnLogin)  -- Player logs in
RegisterPlayerEvent(4, OnLogout)  -- Player logs out


return AP
