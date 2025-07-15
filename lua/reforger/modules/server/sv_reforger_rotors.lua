local Rotors = {}
Rotors._internal = {}

Reforger.Log("Reforger Rotors Loaded")

local VehBase = Reforger.VehicleBases
local VehType = Reforger.VehicleTypes

function Rotors.RotorsGetDamage(veh, dmginfo)
    if not IsValid(veh) then return end

    local rotor = Rotors.FindRotorAlongRay(veh, dmginfo)

    if not IsValid(rotor) then return end
    if rotor.destroyed then return end
    if not Rotors.IsRotorSpinning(rotor) then return end

    if rotor.rotorHealth == nil and veh.reforgerBase == VehBase.LVS then
        if rotor.GetHP then
            rotor.rotorHealth = rotor:GetHP()
        else
            rotor.rotorHealth = Reforger.GetHealth(veh) * 0.15
        end
    end

    if math.random() < 0.35 then
        local pre = hook.Run("Reforger.PreRotorDamage", rotor, dmginfo)

        if pre == false then return end

        rotor.rotorHealth = rotor.rotorHealth - dmginfo:GetDamage()

        hook.Run("Reforger.PostRotorDamage", rotor, dmginfo)

        if rotor.rotorHealth <= 0 and isfunction(rotor.Destroy) then
            Rotors.DestroyRotor(rotor)
        end
    end
end

function Rotors.DestroyRotor(rotor)
    if not IsValid(rotor) or rotor.destroyed then return end

    rotor.destroyed = true
    rotor:Destroy()

    hook.Run("Reforger.RotorDestroyed", rotor)
end

function Rotors.IsRotorSpinning(rotor)
    if not IsValid(rotor) then
        Reforger.DevLog("Rotor is not valid entity")
        return false
    end
    
    local veh = rotor.reforgerVehicle

    if not IsValid(veh) then
        Reforger.DevLog("Vehicle of Rotor are not valid entity")
        return false
    end

    local vehBase = veh.reforgerBase
    local isSpinning = false
    
    if vehBase == VehBase.Glide then
        isSpinning = rotor.spinMultiplier > 0.2
    elseif vehBase == VehBase.LVS then
        local base = rotor:GetBase()
        isSpinning = base:GetThrottle() > 0.5
    end

    return isSpinning
end

-- rotors needs own scanner, because in LVS rotors are just box entity.
function Rotors.FindRotorAlongRay(veh, dmginfo)
    if not IsValid(veh) then return nil end

    local Len = veh:BoundingRadius() or 10
    local dmgPos = dmginfo:GetDamagePosition()
    local dmgDir = dmginfo:GetDamageForce():GetNormalized()
    local dmgStart = dmgPos - dmgDir * (Len * 0.5)

    local closestEnt, closestDist = nil, Len * 2
    local rotors = Rotors.FindRotors(veh)

    for _, ent in ipairs(rotors) do
        if not IsValid(ent) or ent:GetParent() ~= veh then continue end

        local pos = ent:GetPos()
        local ang = ent:GetAngles()
        local radius = 120

        if veh.reforgerBase == VehBase.LVS then
            radius = ent:GetRadius()
        elseif veh.reforgerBase == VehBase.Glide then
            ang = veh:LocalToWorldAngles(ent.baseAngles)
            local axis = ent.spinAxis or "Forward"
            local rotAxis = ang[axis] and ang[axis](ang) or ang:Forward()
            ang:RotateAroundAxis(rotAxis, ent.traceAngle or 0)
            radius = ent.radius
        end

        radius = radius * 0.35
        local mins, maxs = Vector(-radius, -radius, -1), Vector(radius, radius, 1)

        if dmgPos:Distance(veh:GetPos()) > Len * 5 then
            dmgPos = ent:GetPos()
        end

        local HitPos = util.IntersectRayWithOBB(dmgStart, dmgDir * Len * 1.5, pos, ang, mins, maxs)

        if HitPos then
            debugoverlay.BoxAngles(pos, mins, maxs, ang, 1, Color(255, 0, 0, 50))

            local dist = (HitPos - dmgPos):Length()
            if dist < closestDist then
                closestEnt = ent
                closestDist = dist
            end
        end
    end

    return closestEnt
end

function Rotors.FindRotors(veh)
    if not IsValid(veh) then return {} end

    if istable(veh.reforgerRotors) then return veh.reforgerRotors end

    local rotors = {}
    local vehicle_type = veh.reforgerType

    if veh.reforgerBase == VehBase.Glide then
        if IsValid(veh.mainRotor) then table.insert(rotors, veh.mainRotor) end
        if IsValid(veh.tailRotor) then table.insert(rotors, veh.tailRotor) end

        if #rotors == 0 and vehicle_type == VehType.PLANE then
            rotors = Reforger.Scanners.PairEntityAll(veh, "glide_rotor")
        end
    end

    if veh.reforgerBase == VehBase.LVS then
        local lvs_rotors = {}

        if veh.TailRotor then table.insert(lvs_rotors, veh.TailRotor) end
        if veh.Rotor then
            veh.Rotor.reforgerMainRotor = true
            table.insert(lvs_rotors, veh.Rotor)
        end

        if istable(lvs_rotors) then rotors = lvs_rotors end

        if #rotors == 0 then
            rotors = Reforger.Scanners.PairEntityAll(veh, "lvs_helicopter_rotor")
        end
    end

    return rotors
end

function Rotors.RepairRotors(veh)
    if veh.reforgerType ~= VehType.PLANE then return end

    for _, rotor in ipairs(Reforger.GetRotors(veh)) do
        if rotor.Repair then rotor:Repair() end
    end
end

function Rotors.GetRotors(veh)
    if not IsValid(veh) then return {} end
    return veh.reforgerRotors or {}
end

function Rotors._internal:CacheRotors(veh)
    if not IsValid(veh) then return end

    if veh.reforgerBase == VehBase.Simfphys then return end
    if veh.reforgerType ~= VehType.HELICOPTER and veh.reforgerType ~=VehType.PLANE then return end

    timer.Simple(0, function()
        veh.reforgerRotors = Rotors.FindRotors(veh)

        for _, rotor in ipairs(veh.reforgerRotors) do
            if IsValid(rotor) then
                rotor.reforgerVehicle = veh
            end
        end

        hook.Run("Reforger.RotorsCached", veh, veh.reforgerRotors)
        Reforger.DevLog("Rotors Cached")
    end)
end

Reforger.Rotors = Rotors