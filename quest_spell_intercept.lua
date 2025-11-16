


RegisterPlayerEvent(5, function(event, player, spell, skipCheck)
    banned = {5396, 2075, 8073, 34766, 53821, 53431, 40123, 1413, 52382, 7329, 1373, 3578, 11520, 5503, 11519, 20700, 13820, 23160, 28285, 34768, 7329, 5785, 5488, 1579, 5300, 1446, 8947}
    incoming = spell:GetEntry()
    for _, id in ipairs(banned) do
        if id == incoming then
            spell:Cancel()
        end
    end
end)

