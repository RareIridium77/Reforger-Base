Reforger = Reforger or {}

local Damage = {}

local VehBase = Reforger.VehicleBases
local VehType = Reforger.VehicleTypes

Damage.Type = {
    DIRECT = 0,
    TRACED = 1,
}

Damage.Multipliers = {
    SmallToArmored = 0.25
}

Damage.CollisionConfig = {
    light = {
        minVelocity = 550,
        fireChance = 0.5,
        explodeChance = 0.1,
        minDelay = 1,
        maxDelay = 2.0
    },
    armored = {
        minVelocity = 800,
        fireChance = 0.1,
        explodeChance = 0.05,
        minDelay = 2.0,
        maxDelay = 4.0
    },
    plane = {
        minVelocity = 750,
        fireChance = 0.1,
        explodeChance = 0.75,
        minDelay = 0.25,
        maxDelay = 0.75
    },
    helicopter = {
        minVelocity = 450,
        fireChance = 0.75,
        explodeChance = 0.25,
        minDelay = 2,
        maxDelay = 7
    },
    undefined = {
        minVelocity = 500,
        fireChance = 0.5,
        explodeChance = 0.5,
        minDelay = 1.5,
        maxDelay = 3.0
    }
}

local hrun = hook.Run

function Damage.HasDamageType(dmgType, mask)
    assert(isnumber(dmgType), "IS NOT NUMBER TO CHECK DAMAGE TYPE: " .. tostring(dmgType))

    return bit.band(dmgType, mask) ~= 0
end

local hasdmgtype = Damage.HasDamageType

function Damage.HasAnyType(dmgType, ...)
    for _, mask in ipairs({...}) do
        if hasdmgtype(dmgType, mask) then return true end
    end
    return false
end

local dmganytype = Damage.HasAnyType

function Damage.FixDamageForce(dmginfo, attacker, victim)
    assert(dmginfo and isfunction(dmginfo.GetDamage), "CTakeDamageInfo is not valid!")
    assert(IsValid(victim), "Entity Victim is not valid")

    local attk = Reforger.SafeEntity(attacker)
    local damageForce = dmginfo:GetDamageForce()

    if damageForce:IsZero() then
        local delta = (victim:GetPos() - attk:GetPos())
        local dir = delta:IsZero() and VectorRand() or delta:GetNormalized()

        local pushStrength = 2 -- arbitrary low force
        dmginfo:SetDamageForce(dir * pushStrength)
    end
end

function Damage.IsMeleeDamageType(dmgType) return dmganytype(dmgType, DMG_CLUB, DMG_SLASH) end
function Damage.IsSmallDamageType(dmgType) return dmganytype(dmgType, DMG_BULLET, DMG_BUCKSHOT, DMG_SLASH, DMG_CLUB) end
function Damage.IsCollisionDamageType(dmgType) return dmganytype(dmgType, DMG_VEHICLE, DMG_CRUSH) end

function Damage.IsFireDamageType(veh, dmgType)
    if not dmgType then return false end

    local vehValid = isentity(veh) and IsValid(veh)

    if vehValid and veh.reforgerBase == VehBase.Glide then
        return hasdmgtype(dmgType, DMG_DIRECT) or (hasdmgtype(dmgType, DMG_CRUSH) and veh:IsOnFire())
    end

    if vehValid and veh:IsOnFire() then return true end

    if vFireInstalled then
        return dmganytype(dmgType, DMG_BURN, DMG_SLOWBURN, DMG_NEVERGIB, DMG_NERVEGAS)
    end

    return dmganytype(dmgType, DMG_BURN, DMG_SLOWBURN)
end

function Damage.ApplyDamageToEnt(ent, damage, attacker, inflictor, custom, pos)
    if not IsValid(ent) then return false end
    if not isnumber(damage) or damage <= 0 then return false end

    local pre = hrun("Reforger.PreEntityDamage", ent, damage, attacker, inflictor, custom, pos)
    if pre == false then return false end

    attacker = IsValid(attacker) and attacker or game.GetWorld()
    inflictor = IsValid(inflictor) and inflictor or game.GetWorld()

    local dmg = DamageInfo()
    dmg:SetDamage(damage)
    dmg:SetAttacker(attacker)
    dmg:SetInflictor(inflictor)
    dmg:SetDamageType(DMG_DIRECT)
    dmg:SetDamagePosition(pos or ent:GetPos())

    if isnumber(custom) and custom > 0 and custom < 4096 then
        dmg:SetDamageBonus(custom) -- Upd: changed SetDamageCustom -> SetDamageBonus because it's not work
    end

    ent:TakeDamageInfo(dmg)

    hrun("Reforger.PostEntityDamage", ent, damage, attacker, inflictor, custom, pos)
    return true
end

function Damage.ApplyPlayerDamage(ply, damage, attacker, inflictor, custom)
    if not IsValid(ply) or not ply:IsPlayer() or ply:HasGodMode() then return false end
    return Damage.ApplyDamageToEnt(ply, damage, attacker, inflictor, custom)
end

function Damage.ApplyPlayersDamage(veh, dmginfo)
    if not IsValid(veh) or not IsValid(dmginfo) then return end
    for _, ply in ipairs(Reforger.Scanners.GetEveryone(veh)) do
        if not IsValid(ply) or not ply:InVehicle() then continue end -- Fix: Damage applies to player that not in vehicle lol.
        if ply:HasGodMode() then continue end

        Damage.ApplyPlayerDamage(
            ply,
            dmginfo:GetDamage(),
            dmginfo:GetAttacker(),
            dmginfo:GetInflictor(),
            Damage.Type.DIRECT
        )
    end
end

function Damage.DamageParts(veh, damage)
    if not IsValid(veh) then return end

    if isnumber(damage) and damage <= 0 then return end

    local newDamage = isnumber(damage) and damage or 10

    if istable(veh._dmgParts) and #veh._dmgParts > 0 then
        for _, part in ipairs(veh._dmgParts) do
            if not IsValid(part) or not part.GetHP or not part.GetMaxHP then continue end

            local curHP = part:GetHP()
            local maxHP = part:GetMaxHP()
            local newHP = math.Clamp(curHP - newDamage, -maxHP, maxHP)

            if part.SetHP then
                part:SetHP(newHP) end
        end
    end
end

function Damage.HandleCollisionDamage(veh, dmginfo)
    if not IsValid(veh) then return end

    local isCollisionDamage = Damage.IsCollisionDamageType(dmginfo:GetDamageType())

    if not isCollisionDamage then return end

    local vtype = veh.reforgerType or "undefined"
    local cfg = Damage.CollisionConfig[vtype] or Damage.CollisionConfig["undefined"]

    local velocity = veh:GetVelocity():Length()
    if velocity < cfg.minVelocity then return end

    local canExplode = math.random() < cfg.explodeChance
    local canIgnite = math.random() < cfg.fireChance

    if canIgnite then
        if veh.reforgerBase == VehBase.Glide then
            veh:SetIsEngineOnFire(true)
        end
        
        if veh.reforgerBase == VehBase.Simfphys then
            veh:SetOnFire( true )
			veh:SetOnSmoke( false )
        end

        if canExplode then
            Damage.IgniteLimited(veh, veh:BoundingRadius(), 2)
        else
            timer.Simple(math.Rand(0.5, 2), function()
                if not IsValid(veh) then return end

                Damage.IgniteLimited(veh, veh:BoundingRadius(), 2)
            end)
        end
    end

    if canExplode then
        local delay = 0

        if canIgnite then
            local minDelay = cfg.minDelay or 1.5
            local maxDelay = cfg.maxDelay or 2.0
            delay = math.Rand(minDelay, maxDelay)
        end

        timer.Simple(delay, function()
            if not IsValid(veh) then return end
            if veh.Destroy then veh:Destroy() end
            if veh.Explode then veh:Explode() end
            if veh.ExplodeVehicle then veh:ExplodeVehicle() end

            Reforger.Log(string.format("[%s] Explosion by collision | V=%.0f | Delay=%.2fs", vtype, velocity, delay))
        end)
    end
end

function Damage.HandleRayDamage(veh, dmginfo)
    if not IsValid(veh) or not IsValid(dmginfo) then return end
    local Len = veh:BoundingRadius()
	local dmgPos = dmginfo:GetDamagePosition()
	local force = dmginfo:GetDamageForce()
    local dmgDir = force:IsZero() and Vector(0, 0, -1) or force:GetNormalized()

	local start = dmgPos - dmgDir * (Len * 0.1)
	local finish = start + dmgDir * Len * 2

    local tr = util.TraceLine({
        start = start,
        endpos = finish,
        filter = function(ent)
            return ent ~= veh and ent.IsReforgerEntity and not ent:IsPlayer() and not ent:IsVehicle()
        end
    })

    Reforger.DoInDev(function()
        debugoverlay.Sphere(start, 2, 0.8, Color(255, 0, 200), true)

        debugoverlay.Line(start, finish, 0.8, Color(255, 0, 0))

        if tr.HitPos then
            debugoverlay.Sphere(tr.HitPos, 2, 0.8, Color(9, 255, 0), true)
        end
    end)

    local hitEnt = tr.Entity
    if not IsValid(hitEnt) or not hitEnt.ReforgerDamageable then return end

    local hitEntParent = hitEnt:GetParent()
    if not IsValid(hitEntParent) and hitEnt == veh then return end

    -- Damage reducing: Warthunder Technology 🤣
    local travelDist = dmgPos:Distance(tr.HitPos)
    local maxDist = Len * 2
    local damageFalloff = 1 - (travelDist / maxDist)
    damageFalloff = math.Clamp(damageFalloff, 0.1, 1) -- minimum is 10%

    Reforger.DevLog("Damage Fallof: ", damageFalloff)
    
    local dmgType = dmginfo:GetDamageType()
    local notvaliddmg = Damage.IsCollisionDamageType(dmgType) or Damage.IsFireDamageType(veh, dmgType)

    if notvaliddmg then return end

    local originalDmg = dmginfo:GetDamage()
    local finalDmg = originalDmg * damageFalloff

    local isSmall = Damage.IsSmallDamageType(dmgType)

    if isSmall and veh.reforgerType == VehType.ARMORED then
        finalDmg = finalDmg * (Damage.Multipliers.SmallToArmored or 0.25)
    end

    Damage.ApplyDamageToEnt(hitEnt, finalDmg, dmginfo:GetAttacker(), dmginfo:GetInflictor(), Damage.Type.TRACED, tr.HitPos)
end

function Damage.IgniteLimited(ent, size, repeatCount)
    if not IsValid(ent) then return end
    if ent._ignitingForever then return end

    if not isfunction(ent.Ignite) or not isfunction(ent.Extinguish) then return end

    local id = ent:EntIndex()
    if id <= 0 then return end

    local radius = size or ent:BoundingRadius()
    local maxRepeats = repeatCount or 5
    local repeats = 0
    local timerID = "reforger_limited_fire_" .. id

    ent._ignitingForever = true
    ent:Ignite(5, radius)

    timer.Create(timerID, 4.75, 0, function()
        if not IsValid(ent) then
            timer.Remove(timerID)
            return
        end

        repeats = repeats + 1

        if repeats >= maxRepeats then
            ent._ignitingForever = nil
            timer.Remove(timerID)
            return
        end

        ent:Extinguish()
        ent:Ignite(5, radius)
    end)
end

function Damage.StopLimitedFire(ent)
    if not IsValid(ent) then return end
    if ent:EntIndex() <= 0 then return end

    ent:Extinguish() -- Now in base.

    timer.Remove("reforger_limited_fire_" .. ent:EntIndex())
    ent._ignitingForever = nil
end

local function HandleReforgerDamage(target, dmginfo)
    if Reforger.IsValidReforger(target) then
        if target.CallDamageHook == false then return end

        local attacker = dmginfo:GetAttacker()
        local victim = target

        Damage.FixDamageForce(dmginfo, attacker, victim)
        hrun("Reforger.ReforgerTookDamage", dmginfo, attacker, victim)
    end
end
hook.Add("EntityTakeDamage", "Reforger.DamageHook", HandleReforgerDamage)

Reforger.Damage = Damage