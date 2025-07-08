if not Reforger then return end -- overthinker moment

Reforger.DevLog("Reforger Rotors Loaded")

function Reforger.RotorsGetDamage(veh, dmginfo)
    if not IsValid(veh) then return end

    local rotor = Reforger.FindRotorsAlongRay(veh, dmginfo)

    if not IsValid(rotor) then return end

    if rotor.rotorHealth == nil and veh.reforgerBase == "lvs" then
        rotor.rotorHealth = rotor.GetHP and rotor:GetHP() or Reforger.GetHealth(veh) * 0.15
    end

    rotor.rotorHealth = rotor.rotorHealth - dmginfo:GetDamage()

    if rotor.rotorHealth <= 0 and isfunction(rotor.Destroy) then
        rotor:Destroy()
    end
end

function Reforger.FindRotorsAlongRay(veh, dmginfo)
    if not IsValid(veh) then return nil end

    local rotors = Reforger.GetRotors(veh)
    if not istable(rotors) or #rotors == 0 then return nil end
    
    local classname = nil

    if veh.IsGlideVehicle then
        classname = "glide_rotor"
    elseif veh.LVS then 
        classname = "lvs_helicopter_rotor"
    end

    if not isstring(classname) then return nil end
    return Reforger.FindClosestByClass(veh, dmginfo, classname)
end

function Reforger.FindRotors(veh)
    if not IsValid(veh) then return {} end

    if istable(veh.reforgerRotors) then return veh.reforgerRotors end

    local rotors = {}
    local vehicle_type = veh.reforgerType

    if veh.reforgerBase == "glide" then
        if IsValid(veh.mainRotor) then table.insert(rotors, veh.mainRotor) end
        if IsValid(veh.tailRotor) then table.insert(rotors, veh.tailRotor) end

        if #rotors == 0 and vehicle_type == "plane" then
            rotors = Reforger.PairEntityAll(veh, "glide_rotor")
        end
    end

    if veh.reforgerBase == "lvs" then
        local lvs_rotors = {}

        if veh.TailRotor then table.insert(lvs_rotors, veh.TailRotor) end
        if veh.Rotor then
            veh.Rotor.reforgerMainRotor = true
            table.insert(lvs_rotors, veh.Rotor)
        end

        if istable(lvs_rotors) then rotors = lvs_rotors end

        if #rotors == 0 then
            rotors = Reforger.PairEntityAll(veh, "lvs_helicopter_rotor")
        end
    end

    return rotors
end

function Reforger.RepairRotors(veh)
    if veh.reforgerType ~= "plane" then return end

    for _, rotor in ipairs(Reforger.GetRotors(veh)) do
        if rotor.Repair then rotor:Repair() end
    end
end

function Reforger.CacheRotors(veh)
    if not IsValid(veh) then return end

    Reforger.DevLog("Tring to cache rotors for ", veh)

    if veh.reforgerBase == "simfphys" then return end
    if veh.reforgerType ~= "helicopter" and veh.reforgerType ~= "plane" then return end

    timer.Simple(0, function()
        veh.reforgerRotors = Reforger.FindRotors(veh)

        Reforger.DevLog("Cached " .. #veh.reforgerRotors .. " rotors for " .. tostring(veh))

        hook.Run("Reforger.RotorsCached", veh, veh.reforgerRotors)
    end)
end

function Reforger.GetRotors(veh)
    if not IsValid(veh) then return {} end
    return veh.reforgerRotors or {}
end

concommand.Add("reforger.check.rotors", function(ply, cmd)
    if not Reforger.AdminDevToolValidation(ply) then return end

    if not IsValid(ply) then return end

    local tr = ply:GetEyeTraceNoCursor()
    if not IsValid(tr.Entity) then return end

    local rotors = Reforger.FindRotors(tr.Entity)

    if istable(rotors) then PrintTable(rotors) end
end)

concommand.Add("reforger.check.rotors.table", function(ply, cmd)
    if not Reforger.AdminDevToolValidation(ply) then return end

    if not IsValid(ply) then return end

    local tr = ply:GetEyeTraceNoCursor()
    if not IsValid(tr.Entity) then return end

    local rotors = Reforger.FindRotors(tr.Entity)

    if istable(rotors) then
        for _, rotor in ipairs(rotors) do
            if IsValid(rotor) then
                print("----------------------------------------------------------")
                print("----------------------------------------------------------")
                print("----------------------------------------------------------")
                PrintTable(rotor:GetTable())
            end
        end
    end
end)