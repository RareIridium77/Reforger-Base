--[[
    Rotors Module for Reforger
    - Manages rotor entities for helicopters and planes
    - Provides damage handling, destruction, ignition, and caching
    - Functions:
        * RotorsGetDamage(veh, dmginfo) → Handles rotor damage, ignition, and critical hits
        * DestroyRotor(rotor) → Marks rotor destroyed and calls entity Destroy
        * IsRotorSpinning(rotor) → Checks if rotor is currently spinning
        * FindRotorAlongRay(veh, dmginfo) → Traces and finds rotor hit by damage ray
        * FindRotors(veh) → Finds and caches rotors depending on vehicle base/type
        * RepairRotors(veh) → Repairs rotors if applicable
        * GetRotors(veh) → Returns cached rotor entities
        * _internal:CacheRotors(veh) → Scans and caches rotors for valid vehicles
    - Config (ConVars, reforger.):
        * rotor.chance.damage → Chance of rotor taking normal damage
        * rotor.chance.damage.critical → Chance of rotor taking critical damage
        * rotor.chance.ignite → Chance of rotor igniting
        * rotor.time.ignite → Rotor ignition duration
    - Hooks (Reforger.):
        * PreRotorDamage / PostRotorDamage
        * RotorGotCriticalDamage
        * RotorIgnited
        * RotorDestroyed
        * RotorsCached
]]

local Rotors = {}
Rotors._internal = {}

Reforger.Log("Reforger Rotors Loaded")

local VehBase = Reforger.VehicleBases
local VehType = Reforger.VehicleTypes
local isdevmode = Reforger.IsDeveloper

local random = math.random
local runhook = hook.Run

local rotorDamageChanceCvar = Reforger.CreateConvar(
    "rotor.chance.damage", "0.35",
    "Chance of rotor damage on hit. 0.35 = 35% chance.",
    0, 1
)

local rotorCriticalDamageChanceCvar = Reforger.CreateConvar(
    "rotor.chance.damage.critical", "0.15",
    "Chance of rotor critical damage on hit. 0.15 = 15% chance.",
    0, 1
)

local rotorIgniteChanceCvar = Reforger.CreateConvar(
    "rotor.chance.ignite", "0.5",
    "Chance of rotor ignition on hit. 0.5 = 50% chance.",
    0, 1
)

local rotorIgniteTimeCvar = Reforger.CreateConvar(
    "rotor.time.ignite", "10",
    "Time of rotor ignition in seconds. 10 = 10 seconds.",
    0, 60
)

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

    local damageChance = rotorDamageChanceCvar:GetFloat() or 0.35
    local criticalChance = rotorCriticalDamageChanceCvar:GetFloat() or 0.15
    local igniteChance = rotorIgniteChanceCvar:GetFloat() or 0.5
    local igniteTime = rotorIgniteTimeCvar:GetInt() or 10

    -- Damage chance
    if random() < damageChance then
        local pre = runhook("Reforger.PreRotorDamage", rotor, dmginfo)
        if pre == false then return end

        rotor.rotorHealth = rotor.rotorHealth - dmginfo:GetDamage()
        runhook("Reforger.PostRotorDamage", rotor, dmginfo)

        if rotor.rotorHealth <= 0 and isfunction(rotor.Destroy) then
            Rotors.DestroyRotor(rotor)
        end
    end

    -- Critical damage chance (independent)
    if not rotor._criticalDamage and random() < criticalChance then
        rotor._criticalDamage = true
        runhook("Reforger.RotorGotCriticalDamage", rotor, dmginfo)
    end

    -- Ignite chance (independent)
    if IsValid(rotor) and random() < igniteChance and not rotor:IsOnFire() then
        rotor:Ignite(igniteTime, 2)
        runhook("Reforger.RotorIgnited", rotor, dmginfo)
    end
end

function Rotors.DestroyRotor(rotor)
    if not IsValid(rotor) or rotor.destroyed then return end

    rotor.destroyed = true
    rotor:Destroy()

    runhook("Reforger.RotorDestroyed", rotor)
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

-- // NOTE: rotors needs own scanner, because in LVS rotors are just box entity.
function Rotors.FindRotorAlongRay(veh, dmginfo)
    if not IsValid(veh) then return nil end

    local Len = veh:BoundingRadius() or 10
    local dmgPos = dmginfo:GetDamagePosition()
    local dmgDir = dmginfo:GetDamageForce():GetNormalized()
    local dmgStart = dmgPos - dmgDir * (Len * 0.5)

    local closestEnt, closestDist = nil, Len * 2
    local rotors = veh.reforgerRotors or Rotors.FindRotors(veh)

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
            if isdevmode() then debugoverlay.BoxAngles(pos, mins, maxs, ang, 1, Color(255, 0, 0, 50)) end

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

        runhook("Reforger.RotorsCached", veh, veh.reforgerRotors)
        Reforger.DevLog("Rotors Cached")
    end)
end

Reforger.Rotors = Rotors