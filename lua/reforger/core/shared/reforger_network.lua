--[[-------------------------------------------------------------------------
    [Reforger] Base (Framework)

    Unified system for advanced vehicle logic and damage simulation.
    Supports LVS / Simfphys / Gmod Glide. Open-source.

    Created by RareIridium77
    https://github.com/RareIridium77

-------------------------------------------------------------------------]]
Reforger = Reforger or {}

Reforger.NetworkTypes = {
    Bool = true,
    Float = true,
    String = true,
    Int = true,
    Vector = true,
    Angle = true,
    Entity = true
}

local PREFIX = "Reforger." -- Local Reforger Prefix

function Reforger.SetNetworkValue(ent, nType, nName, nValue)
    if not IsValid(ent) then return end
    if not Reforger.NetworkTypes[nType] then
        Reforger.DevLog("Network Type <"..nType.."> Is not supported")
        return 
    end

    local fullName = PREFIX .. nName

    -- Local Cache (SERVER)
    ent.ReforgerNet = ent.ReforgerNet or {}
    ent.ReforgerNet[nName] = {
        Type = nType,
        Value = nValue
    }

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