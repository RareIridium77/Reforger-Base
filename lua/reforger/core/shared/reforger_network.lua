--[[-------------------------------------------------------------------------
    [Reforger] Base (Framework)

    Unified system for advanced vehicle logic and damage simulation.
    Supports LVS / Simfphys / Gmod Glide. Open-source.

    Created by RareIridium77
    https://github.com/RareIridium77

-------------------------------------------------------------------------]]

--[[
    Reforger Network System
    - Provides abstraction layer for safe NWVar setting/getting with Reforger namespace.
    - Ensures server authority and local caching for networked values.

    Functions:
        * SetNetworkValue(ent, nType, nName, nValue)
            - Only allowed on server
            - Validates entity and network type
            - Stores value in local cache (ent.ReforgerNet)
            - Uses SetNW<TYPE> if available
            - Logs unsupported types

        * GetNetworkValue(ent, nType, nName, fallback)
            - Validates entity and type
            - Uses GetNW<TYPE> if available
            - Returns fallback if not supported
            - DevLogs unsupported cases

    Notes:
        - PREFIX = "Reforger." prepends all network keys
        - Reforger.NetworkTypes must define supported NW types (e.g., "Int", "Bool", "String")
]]

Reforger = Reforger or {}

local PREFIX = "Reforger." -- Local Reforger Prefix

function Reforger.SetNetworkValue(ent, nType, nName, nValue)
    if CLIENT then
        Reforger.ErrorLog("Blocked client-side SetNetworkValue for "..nName)
        return 
    end

    if not IsValid(ent) then return end
    if not Reforger.NetworkTypes[nType] then
        Reforger.DevLog("Network Type <"..nType.."> Is not supported")
        return 
    end

    local fullName = PREFIX .. nName

    -- Local Cache (SERVER)
    if SERVER then
        ent.ReforgerNet = ent.ReforgerNet or {}
        ent.ReforgerNet[nName] = {
            Type = nType,
            Value = nValue
        }
    end

    -- SetNW<TYPE>
    local setter = ent["SetNW" .. nType]
    if isfunction(setter) then
        setter(ent, fullName, nValue)
        return 
    end

    Reforger.Log(nType.." was not handled by network. Is not supported")
end

function Reforger.GetNetworkValue(ent, nType, nName, fallback)
    if not IsValid(ent) then return fallback end
    if not Reforger.NetworkTypes[nType] then
        Reforger.Log("Network Type <"..nType.."> Is not supported")
        return fallback
    end

    local fullName = PREFIX .. nName

    -- GetNW<TYPE>
    local getter = ent["GetNW" .. nType]
    if isfunction(getter) then
        return getter(ent, fullName)
    end

    Reforger.DevLog(nType.." was not handled by network. Is not supported")

    return fallback
end