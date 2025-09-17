--[[-------------------------------------------------------------------------
    [Reforger] Base (Framework)

    Unified system for advanced vehicle logic and damage simulation.
    Supports LVS / Simfphys / Gmod Glide. Open-source.

    Created by RareIridium77
    https://github.com/RareIridium77

-------------------------------------------------------------------------]]

--[[
    Reforger Addon Blacklist
    - Manages blacklisted addons that may break functionality
    - Features:
        * Stores blacklisted addon IDs with reasons
        * Provides API to get or modify blacklist
        * Checks mounted addons on init and logs blacklisted ones
        * Notifies clients about active blacklisted addons
    - Functions:
        * Reforger.GetAddonsBlacklist() → Returns blacklist table
        * Reforger.BlacklistAddon(id, reason, blacklisted) → Adds or updates blacklist entry
    - Hooks:
        * Reforger.Init → Scans addons and logs blacklisted ones
        * PlayerInitialSpawn → Sends blacklist info to joining players
    - Networking:
        * "Reforger.NotifyBAddon" → Sends active blacklist entries to clients
]]

local alreadyServerNotified = false

local ABlackList = {
    ["1604765873"] = {
        isBlacklisted = true,
        reason = "Disables/Brokes damage to players in vehicle. Fully"
    }, -- Earu's Errors fixer. Brokes damage to players.
}

function Reforger.GetAddonsBlacklist() return ABlackList end
function Reforger.BlacklistAddon(id, reason, blacklisted)
    assert(isstring(id), "Addon ID must be a string")
    assert(isstring(reason), "Reason must be a string")
    blacklisted = isbool(blacklisted) and blacklisted or true

    ABlackList[id] = {
        isBlacklisted = blacklisted,
        reason = reason,
    }
end

local activeBlacklistedAddons = {}

local defaultReason = "May cause errors/bugs/issues with addon."

hook.Add("Reforger.Init", "Reforger.BlacklistAddons", function()
    if alreadyServerNotified then return end

    local addons = engine.GetAddons()

    for _, addon in ipairs(addons) do
        local entry = ABlackList[addon.wsid]

        if addon.mounted and entry and entry.isBlacklisted then
            local msg = '[Reforger] Addon "' .. addon.title .. '" is blacklisted: ' .. (entry.reason or defaultReason)
            ErrorNoHalt(msg .. '\n')
            Reforger.ErrorLog(msg)

            activeBlacklistedAddons[addon.wsid] = addon.title
        end
    end

    alreadyServerNotified = true
end)

util.AddNetworkString("Reforger.NotifyBAddon")

hook.Add("PlayerInitialSpawn", "Reforger.NotifyClient", function(ply)
    if table.Count(activeBlacklistedAddons) == 0 then return end

    net.Start("Reforger.NotifyBAddon")
        net.WriteUInt(table.Count(activeBlacklistedAddons), 8)
        for wsid, title in pairs(activeBlacklistedAddons) do
            net.WriteString(wsid)
            net.WriteString(title)
        end
    net.Send(ply)
end)