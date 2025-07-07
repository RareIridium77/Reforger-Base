if not Reforger or not LVS then return end

function Reforger.LVSInitializeReforgerDT(lvs)
    if not IsValid(lvs) or not lvs.LVS then return end
    lvs:AddDT("Bool", "Reforger.InnerFire")
end

function Reforger.LVSSetDT(lvs, dtType, dtName, value)
    if not IsValid(lvs) or not lvs.LVS then return nil end

    local setterName = "Set" .. dtName

    if isfunction(lvs[setterName]) then
        return lvs[setterName](lvs, value)
    end

    return nil
end

function Reforger.LVSGetDT(lvs, dtType, dtName)
    if not IsValid(lvs) or not lvs.LVS then return nil end
    if not lvs.DTlist or not lvs.DTlist[dtType] then return nil end

    for i = 0, lvs.DTlist[dtType] do
        local getterName = "Get" .. dtName

        if isfunction( lvs[getterName] ) then
            return lvs[getterName]( lvs )
        end
    end

    return nil
end