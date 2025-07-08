-- Reforger Networking

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

function Reforger.GetNetworkValue(ent, nType, nName)
    if not IsValid(ent) then return nil end
    if not Reforger.NetworkTypes[nType] then
        Reforger.Log("Network Type <"..nType.."> Is not supported")
        return nil
    end

    local fullName = PREFIX .. nName

    -- GetNW<TYPE>
    local getter = ent["GetNW" .. nType]
    if isfunction(getter) then
        return getter(ent, fullName)
    end

    Reforger.DevLog(nType.." was not handled by network. Is not supported")

    return nil
end

concommand.Add("reforger.dump.net", function(ply, cmd, args)
    if not Reforger.AdminDevToolValidation(ply) then return end

    local tr = ply:GetEyeTrace()
    local ent = tr.Entity

    if not Reforger.IsValidReforger(ent) then
        print("[Reforger] Наведись на сущность")
        return
    end

    print("[Reforger] Dump ReforgerNet:")
    for k, v in pairs(ent.ReforgerNet or {}) do
        print("  " .. k .. " [" .. v.Type .. "] = " .. tostring(v.Value))
    end
end)
