
AP_SETTINGS = {}

local function loadSettings()
    path = ""
    local f = io.open(path, "r")

    local content = f:read("*a")
    f:close()


    XP.setRate(1)
    -- zone ids to unlock go here
end

local function applySettings(player)
    player:SetSpeed(1, 1, true)
end

local function giveStartingItems(player)
    print('Testing start')
end

-- Apply settings on login
RegisterPlayerEvent(3, function(_, player)
    applySettings(player)
end)

-- Give items on first login
RegisterPlayerEvent(30, function(_, player)
    giveStartingItems(player)
end)

-- loadSettings()