if not Reforger then return end -- overthinker moment

Reforger.Log("Reforger Helicopter special loaded")

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

    local rotors = Reforger.GetHeliRotors(veh)
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

function Reforger.FindHeliRotors(heli)
    if not IsValid(heli) then return {} end

    local rotors = {}

    if heli.IsGlideVehicle then
        if IsValid(heli.mainRotor) then table.insert(rotors, heli.mainRotor) end
        if IsValid(heli.tailRotor) then table.insert(rotors, heli.tailRotor) end
    end

    if heli.LVS then
        local lvs_rotors = Reforger.PairEntityAll(heli, "lvs_helicopter_rotor")
        if istable(lvs_rotors) then
            rotors = lvs_rotors
        end
    end

    return rotors
end

function Reforger.CacheHeliRotors(heli)
    if not IsValid(heli) then return end

    timer.Simple(0, function()
        heli._ReforgerRotors = Reforger.FindHeliRotors(heli)

        Reforger.DevLog("Cached " .. #heli._ReforgerRotors .. " rotors for " .. tostring(heli))
    end)
end

function Reforger.GetHeliRotors(heli)
    if not IsValid(heli) then return {} end
    return heli._ReforgerRotors or {}
end

concommand.Add("reforger_check_rotors", function(ply, cmd)
    if not IsValid(ply) then return end

    local tr = ply:GetEyeTraceNoCursor()
    if not IsValid(tr.Entity) then return end

    local rotors = Reforger.FindHeliRotors(tr.Entity)

    if istable(rotors) then PrintTable(rotors) end
end)

concommand.Add("reforger_destroy_rotors", function(ply, cmd)
    if not IsValid(ply) then return end

    local tr = ply:GetEyeTraceNoCursor()
    if not IsValid(tr.Entity) then return end

    local rotors = Reforger.FindHeliRotors(tr.Entity)

    if istable(rotors) then
        for _, rotor in ipairs(rotors) do
            if rotor.Destroy then
                rotor:Destroy()
            end
        end
    end
end)