if not Reforger then return end -- overthinker moment

Reforger.Log("Reforger Rotor special loaded")

function Reforger.RotorsGetDamage(veh, dmginfo)
    if not IsValid(veh) then return end

    local rotor = Reforger.FindRotorsAlongRay(veh, dmginfo)
    print(rotor)
    if not IsValid(rotor) then return end

    if rotor.rotorHealth == nil then
        rotor.rotorHealth = 0.5 * Reforger.GetHealth(veh)
    end

    rotor.rotorHealth = rotor.rotorHealth - dmginfo:GetDamage() / 2

    if rotor.rotorHealth <= 0 and rotor.Destroy then
        rotor:Destroy()
        Reforger.DevLog("Rotor destroyed: " .. tostring(rotor))
    end
end

function Reforger.FindRotorsAlongRay(veh, dmginfo)
    if not IsValid(veh) then return nil end

    local Len = veh:BoundingRadius()
    local dmgPos = dmginfo:GetDamagePosition()
    local dmgDir = dmginfo:GetDamageForce():GetNormalized()

    if dmgDir:Length() == 0 then return nil end

    local dmgPenetration = dmgDir * Len
    local dmgStart = dmgPos - dmgDir * (Len * 0.5)

    local closestRotor = nil
    local closestDist = Len * 2

    local rotors = Reforger.GetRotors(veh)
    if not istable(rotors) or #rotors == 0 then return nil end

    for _, rotor in ipairs(rotors) do
        if not IsValid(rotor) then continue end

        local mins, maxs = rotor:OBBMins(), rotor:OBBMaxs()
        local pos, ang = rotor:GetPos(), rotor:GetAngles()

        local HitPos = util.IntersectRayWithOBB(dmgStart, dmgDir * Len * 1.5, pos, ang, mins, maxs)

        if HitPos then
            debugoverlay.BoxAngles(pos, mins, maxs, ang, 1, Color(255, 100, 0, 50))

            local dist = (HitPos - dmgPos):Length()
            if dist < closestDist then
                closestRotor = rotor
                closestDist = dist
            end
        end
    end

    return closestRotor
end

function Reforger.FindRotors(veh)
    if not IsValid(veh) then return {} end

    if veh._ReforgerRotors ~= nil and istable(veh._ReforgerRotors) then return veh._ReforgerRotors end

    local rotors = {}
    local vehicle_type = Reforger.GetVehicleType(veh)

    if veh.IsGlideVehicle then
        if IsValid(veh.mainRotor) then table.insert(rotors, veh.mainRotor) end
        if IsValid(veh.tailRotor) then table.insert(rotors, veh.tailRotor) end

        if #rotors == 0 and (vehicle_type == "plane" or vehicle_type == "helicopter") then
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
    if vehicle_base ~= "simfphys" then return end
    if vehicle_type ~= "helicopter" or vehicle_type ~= "plane" then return end

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

concommand.Add("reforger_destroy_rotors", function(ply, cmd)
    if not IsValid(ply) then return end

    local tr = ply:GetEyeTraceNoCursor()
    if not IsValid(tr.Entity) then return end

    local rotors = Reforger.FindRotors(tr.Entity)

    if istable(rotors) then
        for _, rotor in ipairs(rotors) do
            if rotor.Destroy then
                rotor:Destroy()
            end
        end
    end
end)