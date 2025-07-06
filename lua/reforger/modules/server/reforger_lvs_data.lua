if not Reforger then return end

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

concommand.Add("reforger_lvsdt", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not istable(args) or #args < 2 then 
        print("[Reforger] Invalid arguments. Usage: reforger_lvsdt <Type> <Name>")
        return 
    end

    local tr = ply:GetEyeTraceNoCursor()
    local ent = tr.Entity

    if not IsValid(ent) then 
        print("[Reforger] Invalid entity.")
        return
    end

    local dtType = args[1]
    local dtName = args[2]

    local val = Reforger.LVSGetDT(ent, dtType, dtName)
    if val ~= nil then 
        Reforger.Log(dtName.." value: "..tostring(val))
    else
        Reforger.Log("DT variable not found.")
    end
end)
