if not Reforger then return end -- overthinker moment

Reforger.Log("Damage Module Loaded")

Reforger.DamageType = {
    DIRECT = 0,
    TRACED = 1,
    BURN   = 2
}

Reforger.PlayerBypassTypes = {
    [DMG_GENERIC] = false,
    [DMG_BLAST] = true,
    [DMG_BLAST_SURFACE] = true,
    [DMG_BUCKSHOT] = false,
    [DMG_CLUB] = false
}

Reforger.CollisionDamageConfig = {
    light = {
        minVelocity = 400,
        fireChance = 0.3,
        explodeChance = 0.35
    },
    armored = {
        minVelocity = 800,
        fireChance = 0.1,
        explodeChance = 0.05
    },
    plane = {
        minVelocity = 600,
        fireChance = 0.4,
        explodeChance = 0.5
    },
    helicopter = {
        minVelocity = 500,
        fireChance = 0.5,
        explodeChance = 0.35
    },
    undefined = {
        minVelocity = 500,
        fireChance = 0.2,
        explodeChance = 0.8
    }
}

function Reforger.ApplyDamageToEnt(ent, damage, attacker, inflictor, custom, pos)
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

function Reforger.ApplyPlayerDamage(ply, damage, attacker, inflictor, custom)
    if not IsValid(ply) or not ply:IsPlayer() or ply:HasGodMode() then return false end
    return Reforger.ApplyDamageToEnt(ply, damage, attacker, inflictor, custom)
end

function Reforger.ApplyPlayersDamage(veh, dmginfo)
    if not IsValid(veh) or not IsValid(dmginfo) then return end
    for _, ply in ipairs(Reforger.GetEveryone(veh)) do
        Reforger.ApplyPlayerDamage(
            ply,
            dmginfo:GetDamage(),
            dmginfo:GetAttacker(),
            dmginfo:GetInflictor(),
            Reforger.DamageType.DIRECT
        )
    end
end

function Reforger.HandleCollisionDamage(veh, dmginfo)
    if not IsValid(veh) then return end
    if not (dmginfo:IsDamageType(DMG_CRUSH) or dmginfo:IsDamageType(DMG_VEHICLE) or dmginfo:IsDamageType(DMG_GENERIC)) then return end

    local vtype = veh.reforgerType or "undefined"
    local cfg = Reforger.CollisionDamageConfig[vtype] or Reforger.CollisionDamageConfig["undefined"]

    local velocity = veh:GetVelocity():Length()
    if velocity < cfg.minVelocity then return end

    local delay = math.Rand(1, 2)
    local canExplode = math.random() < cfg.explodeChance
    local canIgnite = math.random() < cfg.fireChance

    if canIgnite and veh.SetIsEngineOnFire then
        veh:SetIsEngineOnFire(true)
    end

    timer.Simple(delay, function()
        if not IsValid(veh) then return end
        if canExplode then
            if veh.Destroy then veh:Destroy() end
            if veh.Explode then veh:Explode() end
            if veh.ExplodeVehicle then veh:ExplodeVehicle() end

            Reforger.Log(string.format("[%s] Explosion by collision | V=%.0f | Delay=%.2fs", vtype, velocity, delay))
        end
    end)
end

function Reforger.HandleRayDamage(veh, dmginfo)
    if not IsValid(veh) or not IsValid(dmginfo) then return end

    local Len = veh:BoundingRadius()
	local dmgPos = dmginfo:GetDamagePosition()
	local dmgDir = dmginfo:GetDamageForce():GetNormalized()

	local start = dmgPos - dmgDir * (Len * 0.1)
	local finish = start + dmgDir * Len * 2

	debugoverlay.Line(dmgPos - dmgDir * 2, finish, 0.8, Color(255, 0, 0))

    local tr = util.TraceLine({
        start = start,
        endpos = finish,
        filter = function(ent) return ent ~= veh end
    })

    if tr.HitPos then debugoverlay.Sphere(tr.HitPos, 2, 0.8, Color(255, 0, 212), true) end

    local hitEnt = tr.Entity
    if not IsValid(hitEnt) or not hitEnt.ReforgerDamageable then return end

    local dmgType = dmginfo:GetDamageType()
    local originalDmg = dmginfo:GetDamage()
    local isSmall = bit.band(dmgType, DMG_BULLET + DMG_BUCKSHOT + DMG_CLUB) ~= 0

    local finalDmg = originalDmg
    if isSmall and veh.reforgerType == "armored" then
        finalDmg = originalDmg * 0.25
    end

    Reforger.ApplyDamageToEnt(hitEnt, finalDmg, dmginfo:GetAttacker(), dmginfo:GetInflictor(), Reforger.DamageType.TRACED, tr.HitPos)
end

function Reforger.IgniteLimited(ent, size, repeatCount)
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

function Reforger.StopLimitedFire(ent)
    if not IsValid(ent) then return end
    timer.Remove("reforger_limited_fire_" .. ent:EntIndex())
    ent._ignitingForever = nil
end
