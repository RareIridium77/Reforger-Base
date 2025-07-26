Reforger = Reforger or {}

local Damage = {}

local VehBase = Reforger.VehicleBases
local VehType = Reforger.VehicleTypes

Damage.DamageType = {
    DIRECT = 0,
    TRACED = 1,
}

Damage.CollisionDamageConfig = {
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

function Damage.FixDamageForce(dmginfo, attacker, victim)
    assert(IsValid(dmginfo), "CTakeDamageInfo is not valid!")
    assert(IsValid(victim), "Entity Victim is not valid")
    
    -- TODO: FIX ATTACKER IS NULL, NIL

    local attk = Reforger.SafeEntity(attacker)

    if dmginfo:GetDamageForce():IsZero() then
        local dir = (victim:GetPos() - attk:GetPos()):GetNormalized()
        local pushStrength = 2 -- arbitrary low force
        dmginfo:SetDamageForce(dir * pushStrength)
    end
end

function Damage.IsMeleeDamageType(dmgType)
    local hasClub     = bit.band(dmgType, DMG_CLUB)     ~= 0
    local hasSlash    = bit.band(dmgType, DMG_SLASH)    ~= 0

    if hasClub or hasSlash then
        return true
    else
        return false
    end
end

function Damage.IsSmallDamageType(dmgType)
    assert(isnumber(dmgType), "IS NOT NUMBER TO CHECK DAMAGE TYPE: " .. tostring(dmgType))

    local hasBullet   = bit.band(dmgType, DMG_BULLET)   ~= 0
    local hasBuckshot = bit.band(dmgType, DMG_BUCKSHOT) ~= 0
    local hasClub     = bit.band(dmgType, DMG_CLUB)     ~= 0
    local hasSlash    = bit.band(dmgType, DMG_SLASH)    ~= 0

    if hasBullet or hasBuckshot or hasClub or hasSlash then
        return true
    else
        return false
    end
end

function Damage.IsCollisionDamageType(dmgType)
    assert(isnumber(dmgType), "IS NOT NUMBER TO CHECK DAMAGE TYPE: " .. tostring(dmgType))
    return (dmgType == (DMG_VEHICLE + DMG_CRUSH) or dmgType == DMG_VEHICLE or dmgType == DMG_CRUSH)
end

local FIRE_DAMAGE_MASK = bit.bor(DMG_BURN, DMG_SLOWBURN, DMG_DIRECT)

function Damage.IsFireDamageType(veh, dmgType)
    assert(IsValid(veh), "IS NOT VALID VEHICLE TO CHECK DAMAGE TYPE: " .. tostring(veh))
    assert(isnumber(dmgType), "IS NOT NUMBER TO CHECK DAMAGE TYPE: " .. tostring(dmgType))

    if veh.reforgerBase == VehBase.Glide then
        return dmgType == DMG_DIRECT or (bit.band(dmgType, DMG_CRUSH) ~= 0 and veh:IsOnFire())
    end

    return bit.band(dmgType, FIRE_DAMAGE_MASK) ~= 0
end

function Damage.ApplyDamageToEnt(ent, damage, attacker, inflictor, custom, pos)
    if not IsValid(ent) then return false end
    if not isnumber(damage) or damage <= 0 then return false end

    local pre = hook.Run("Reforger.PreEntityDamage", ent, damage, attacker, inflictor, custom, pos)
    if pre == false then return false end

    attacker = IsValid(attacker) and attacker or game.GetWorld()
    inflictor = IsValid(inflictor) and inflictor or game.GetWorld()

    local dmg = DamageInfo()
    dmg:SetDamage(damage * 2)
    dmg:SetAttacker(attacker)
    dmg:SetInflictor(inflictor)
    dmg:SetDamageType(DMG_DIRECT)
    dmg:SetDamagePosition(pos or ent:GetPos())

    if isnumber(custom) and custom > 0 and custom < 4096 then
        dmg:SetDamageCustom(custom)
    end

    ent:TakeDamageInfo(dmg)

    hook.Run("Reforger.PostEntityDamage", ent, damage, attacker, inflictor, custom, pos)
    return true
end

function Damage.ApplyPlayerDamage(ply, damage, attacker, inflictor, custom)
    if not IsValid(ply) or not ply:IsPlayer() or ply:HasGodMode() then return false end
    return Damage.ApplyDamageToEnt(ply, damage, attacker, inflictor, custom)
end

function Damage.ApplyPlayersDamage(veh, dmginfo)
    if not IsValid(veh) or not IsValid(dmginfo) then return end
    for _, ply in ipairs(Reforger.Scanners.GetEveryone(veh)) do
        Damage.ApplyPlayerDamage(
            ply,
            dmginfo:GetDamage(),
            dmginfo:GetAttacker(),
            dmginfo:GetInflictor(),
            Damage.DamageType.DIRECT
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
            local newHP = math.Clamp(curHP - damage, -maxHP, maxHP)

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
    local cfg = Damage.CollisionDamageConfig[vtype] or Damage.CollisionDamageConfig["undefined"]

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
	local dmgDir = dmginfo:GetDamageForce():GetNormalized()

	local start = dmgPos - dmgDir * (Len * 0.1)
	local finish = start + dmgDir * Len * 2

    local tr = util.TraceLine({
        start = start,
        endpos = finish,
        filter = function(ent) return ent ~= veh end
    })

    Reforger.DoInDev(function()
        debugoverlay.Line(dmgPos - dmgDir * 2, finish, 0.8, Color(255, 0, 0))

        if tr.HitPos then
            debugoverlay.Sphere(tr.HitPos, 2, 0.8, Color(255, 0, 212), true)
        end
    end)

    local hitEnt = tr.Entity
    if not IsValid(hitEnt) or not hitEnt.ReforgerDamageable then return end

    local dmgType = dmginfo:GetDamageType()
    local originalDmg = dmginfo:GetDamage()
    local isSmall = bit.band(dmgType, DMG_BULLET + DMG_BUCKSHOT + DMG_CLUB) ~= 0

    local finalDmg = originalDmg
    if isSmall and veh.reforgerType == VehType.ARMORED then finalDmg = originalDmg * 0.25 end

    Damage.ApplyDamageToEnt(hitEnt, finalDmg, dmginfo:GetAttacker(), dmginfo:GetInflictor(), Damage.DamageType.TRACED, tr.HitPos)
end

function Damage.IgniteLimited(ent, size, repeatCount)
    if not IsValid(ent) then return end
    if ent._ignitingForever then return end

    local radius = size or ent:BoundingRadius()
    local maxRepeats = repeatCount or 5
    local repeats = 0
    local timerID = "reforger_limited_fire_" .. ent:EntIndex()

    ent._ignitingForever = true
    ent:Ignite(5, radius)

    if timer.Exists(timerID) then timer.Remove(timerID) return end

    timer.Create(timerID, 4.75, 0, function()
        if not IsValid(ent) then return timer.Remove(timerID) end
        if not ent:IsOnFire() then ent._ignitingForever = nil return timer.Remove(timerID) end

        repeats = repeats + 1
        if repeats >= maxRepeats then
            ent._ignitingForever = nil
            return timer.Remove(timerID)
        end

        ent:Ignite(5, radius)
    end)
end

function Damage.StopLimitedFire(ent)
    if not IsValid(ent) then return end
    timer.Remove("reforger_limited_fire_" .. ent:EntIndex())
    ent._ignitingForever = nil
end

Reforger.Damage = {}
Reforger.Damage = Damage