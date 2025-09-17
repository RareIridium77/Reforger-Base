--[[-------------------------------------------------------------------------
    [Reforger] Base (Framework)

    Unified system for advanced vehicle logic and damage simulation.
    Supports LVS / Simfphys / Gmod Glide. Open-source.

    Created by RareIridium77
    https://github.com/RareIridium77

-------------------------------------------------------------------------]]

--[[
    Reforger Blacklisted Addon Notifier
    - Listens for server notification about blacklisted addons
    - Networking:
        * net.Receive("Reforger.NotifyBAddon")
            - Reads count of addons
            - Prints each addon’s title and WSID to chat
    - Purpose:
        * Warns players about mounted blacklisted addons that may cause issues
]]

net.Receive("Reforger.NotifyBAddon", function()
    local count = net.ReadUInt(8)
    if count <= 0 then return end

    chat.AddText(Color(255, 50, 50), "[Reforger] ⚠ One or more blacklisted addons are mounted on the server:")

    for i = 1, count do
        local wsid = net.ReadString()
        local title = net.ReadString()

        chat.AddText(Color(255, 100, 100), " - " .. title .. " (WSID: " .. wsid .. ")")
    end

    chat.AddText(Color(255, 50, 50), "[Reforger] These addons may cause bugs or break functionality.")
end)
