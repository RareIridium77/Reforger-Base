if not Reforger then return end -- overthinker moment

Reforger.Log("Reforger_Damage Initialized")

Reforger.PlayerBypassTypes = {
    [DMG_GENERIC] = false,
    [DMG_BLAST] = true,
    [DMG_BLAST_SURFACE] = true,
    [DMG_BUCKSHOT] = false,
    [DMG_CLUB] = false
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

    local isCollision = dmginfo:IsDamageType( DMG_CRUSH ) or dmginfo:IsDamageType( DMG_VEHICLE )
    local velocity = veh:GetVelocity():Length()

    if veh.IsSimfphysVehicle then isCollision = dmginfo:IsDamageType( DMG_GENERIC ) end

    if velocity > 500 and isCollision then
        local function explode()
            if veh.Destroy then veh:Destroy() end
            if veh.Explode then veh:Explode() end
            if veh.ExplodeVehicle then veh:ExplodeVehicle() end
        end
        timer.Simple(1, explode)
    end
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