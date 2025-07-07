if not Reforger then return end -- overthinker moment

Reforger.Log("Reforger_Damage Initialized")

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


function Reforger.ApplyDamageToEnt(ent, damage, attacker, inflictor)
    if not IsValid(ent) then return false end

    local preResult = hook.Run("Reforger.PreEntityDamage", ent)
    if isbool(preResult) and not preResult then return false end

    if not IsValid( attacker ) then attacker = game.GetWorld() end
    if not IsValid( inflictor ) then inflictor = game.GetWorld() end
    if not isnumber( damage ) then damage = 10 end

    local ent_dmginfo = DamageInfo()
    ent_dmginfo:SetDamage( 2 * damage )
    ent_dmginfo:SetAttacker( attacker )
    ent_dmginfo:SetInflictor( inflictor )
    ent_dmginfo:SetDamageType( DMG_DIRECT ) -- funny hell

    -- Just a gmod moment
    local success = false

    if ent:Alive() then
        ent:TakeDamageInfo(ent_dmginfo)
        success = true
    end

    return success 
end

function Reforger.ApplyPlayerDamage(ply, damage, attacker, inflictor)
    if not IsValid(ply) or not ply:IsPlayer() or ply:HasGodMode() then return false end

    return Reforger.ApplyDamageToEnt(ply, damage, attacker, inflictor)
end

function Reforger.ApplyPlayerFireDamage(veh, dmginfo)
    if not IsValid(veh) or not IsValid(dmginfo) then return end

    local IsFireDamage = veh:IsOnFire()

    if IsFireDamage then
        local veh_players = Reforger.GetEveryone(veh)
        
        for _, ply in ipairs(veh_players) do
            Reforger.ApplyPlayerDamage(
                ply,
                dmginfo:GetDamage(),
                dmginfo:GetAttacker(),
                dmginfo:GetInflictor()
            )
            hook.Run("Reforger.PlayerBurningInVehicle", ply, veh)
        end
    end
end

function Reforger.HandleCollisionDamage(veh, dmginfo)
    if not IsValid(veh) then return end

    local isCollision = dmginfo:IsDamageType(DMG_CRUSH) or dmginfo:IsDamageType(DMG_VEHICLE)
    if veh.IsSimfphysVehicle then
        isCollision = dmginfo:IsDamageType(DMG_GENERIC)
    end
    if not isCollision then return end

    local velocity = veh:GetVelocity():Length()
    local vtype = veh.reforgerType or "undefined"

    local cfg = Reforger.CollisionDamageConfig[vtype]

    if not cfg then
        cfg = Reforger.CollisionDamageConfig["undefined"]
        Reforger.DevLog("[WARN] Unknown reforgerType: " .. tostring(vtype))
    end

    if velocity < cfg.minVelocity then return end
    if math.random() > cfg.fireChance then return end

    if veh.SetIsEngineOnFire then
        veh:SetIsEngineOnFire(true)
    end

    local delay = math.Rand(1, 2)
    timer.Simple(delay, function()
        if not IsValid(veh) then return end
        if math.random() < cfg.explodeChance then
            if veh.Destroy then veh:Destroy() end
            if veh.Explode then veh:Explode() end
            if veh.ExplodeVehicle then veh:ExplodeVehicle() end

            Reforger.DevLog("[" .. vtype .. "] Explosion triggered by collision | Velocity: " .. math.Round(velocity) .. " | Delay: " .. string.format("%.2f", delay))
        end
    end)
end

function Reforger.HandleRayDamage(veh, dmginfo)
    if not IsValid(veh) or not IsValid(dmginfo) then return end

    local Len = veh:BoundingRadius()
	local dmgPos = dmginfo:GetDamagePosition()
	local dmgDir = dmginfo:GetDamageForce():GetNormalized()

	local dmgPenetration = dmgDir * Len
    local dmgStart = dmgPos - dmgDir * (Len * 0.1)

	debugoverlay.Line( dmgPos - dmgDir * 2, dmgPos + dmgPenetration, 0.2, Color( 255, 0, 0) )
    debugoverlay.Sphere(dmgStart, 2, 0.2, Color(255, 0, 0), true)
    debugoverlay.Sphere(dmgPos + dmgPenetration, 2, 0.2, Color(255, 0, 0), true)

    local tr = util.TraceLine({
        start = dmgStart,
        endpos = dmgStart + dmgDir * Len * 2,
        filter = function(ent)
            return ent ~= veh
        end
    })

    if tr.HitPos then
        debugoverlay.Sphere(tr.HitPos, 2, 0.2, Color(255, 0, 0), true)
    end

    local ent = tr.Entity

    if IsValid(ent) and ent.ReforgerDamageable and ent.Player ~= dmginfo:GetAttacker() then
        Reforger.ApplyDamageToEnt(
            ent,
            dmginfo:GetDamage(),
            dmginfo:GetAttacker(),
            dmginfo:GetInflictor()
        )
    end
end

function Reforger.IgniteForever(ent, size)
    if not IsValid(ent) then return end

    size = size or ent:BoundingRadius()

    if ent._ignitingForever then return end
    ent._ignitingForever = true

    ent:Ignite(5, size)

    local timerID = "reforger_infinite_fire_" .. ent:EntIndex()

    if timer.Exists(timerID) then return end

    timer.Create(timerID, 4.75, 0, function()
        if not IsValid(ent) then
            timer.Remove(timerID)
            return
        end

        if not ent:IsOnFire() then
            ent._ignitingForever = nil
            timer.Remove(timerID)
            return
        end

        ent:Ignite(5, size)
    end)
end

function Reforger.StopInfiniteFire(ent)
    if not IsValid(ent) then return end

    local timerID = "reforger_infinite_fire_" .. ent:EntIndex()
    timer.Remove(timerID)
    ent._ignitingForever = nil
end