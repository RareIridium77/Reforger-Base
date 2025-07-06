if not Reforger then return end -- overthinker moment

Reforger.Log("Reforger Rotor special loaded")

function Reforger.RotorsGetDamage(veh, dmginfo)
    if not IsValid(veh) then return end

    local rotor = Reforger.FindRotorsAlongRay(veh, dmginfo)
    local vehicle_base = Reforger.GetVehicleBase(veh)

    if not IsValid(rotor) then return end

    if rotor.rotorHealth == nil and vehicle_base == "lvs" then
        rotor.rotorHealth = rotor.GetHP and rotor:GetHP() or Reforger.GetHealth(veh) * 0.15
    end

    rotor.rotorHealth = rotor.rotorHealth - dmginfo:GetDamage()

    if rotor.rotorHealth <= 0 and isfunction(rotor.Destroy) then
        rotor:Destroy()
        Reforger.DevLog("Rotor destroyed: " .. tostring(rotor))
    end
end

function Reforger.FindRotorsAlongRay(veh, dmginfo)
    if not IsValid(veh) then return nil end

    local rotors = Reforger.GetRotors(veh)
    if not istable(rotors) or #rotors == 0 then return nil end

    local classname = rotors[1]:GetClass()

    return Reforger.FindClosestByClass(veh, dmginfo, classname)
end

function Reforger.FindRotors(veh)
    if not IsValid(veh) then return {} end

    if veh._ReforgerRotors ~= nil and istable(veh._ReforgerRotors) then return veh._ReforgerRotors end

    local rotors = {}
    local vehicle_type = Reforger.GetVehicleType(veh)

    if veh.IsGlideVehicle then
        if IsValid(veh.mainRotor) then table.insert(rotors, veh.mainRotor) end
        if IsValid(veh.tailRotor) then table.insert(rotors, veh.tailRotor) end

        if #rotors == 0 and vehicle_type == "plane" then
            rotors = Reforger.PairEntityAll(veh, "glide_rotor")
        end
    end

    if veh.LVS then
        local lvs_rotors = Reforger.PairEntityAll(veh, "lvs_helicopter_rotor")
        if istable(lvs_rotors) then
            rotors = lvs_rotors
        end
    end

    return rotors
end

function Reforger.CacheRotors(veh)
    if not IsValid(veh) then return end

    local vehicle_type = Reforger.GetVehicleType(veh)
    local vehicle_base = Reforger.GetVehicleBase(veh)
    if vehicle_base == "simfphys" then return end
    if vehicle_type ~= "helicopter" and vehicle_type ~= "plane" then return end

    timer.Simple(0, function()
        veh._ReforgerRotors = Reforger.FindRotors(veh)

        Reforger.DevLog("Cached " .. #veh._ReforgerRotors .. " rotors for " .. tostring(veh))
    end)
end

function Reforger.GetRotors(veh)
    if not IsValid(veh) then return {} end
    return veh._ReforgerRotors or {}
end

concommand.Add("reforger_check_rotors", function(ply, cmd)
    if not IsValid(ply) then return end

    local tr = ply:GetEyeTraceNoCursor()
    if not IsValid(tr.Entity) then return end

    local rotors = Reforger.FindRotors(tr.Entity)

    if istable(rotors) then PrintTable(rotors) end
end)