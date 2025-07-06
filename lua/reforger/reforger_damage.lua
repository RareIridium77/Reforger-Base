if not Reforger then return end -- overthinker moment

Reforger.Log("Reforger_Damage Initialized")

Reforger.PlayerBypassTypes = [
    [DMG_BLAST] = true,
    [DMG_BLAST_SURFACE] = true,
    [DMG_BUCKSHOT] = false,
    [DMG_CLUB] = false
]

function Reforger.ApplyPlayerDamage(ply, damage, attacker, inflictor)
    if not IsValid(ply) or not ply:IsPlayer() or ply:HasGodMode() then return false end

    local preResult = hook.Run("Reforger.PrePlayerDamage", ply)
    if isbool(preResult) and not preResult then return false end

    if not IsValid( attacker ) then attacker = game.GetWorld() end
    if not IsValid( inflictor ) then inflictor = game.GetWorld() end
    if not isnumber( damage ) then damage = 10 end

    local player_dmginfo = DamageInfo()
    player_dmginfo:SetDamage( 2 * damage )
    player_dmginfo:SetAttacker( attacker )
    player_dmginfo:SetInflictor( inflictor )
    player_dmginfo:SetDamageType( DMG_DIRECT ) -- funny hell

    -- Just a gmod moment

    if ply:Alive() then
        ply:TakeDamageInfo(player_dmginfo)
        return true 
    end

    return false 
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

function Reforger.DamagePlayer(veh, dmginfo)
    if not IsValid(veh) or not IsValid(dmginfo) then return end

    local ply = Reforger.FindClosestPlayer(veh, dmginfo)
    if not IsValid(ply) then return end

    local dmgForce = dmginfo:GetDamageForce():Length()
    local dmgPos = dmginfo:GetDamagePosition()
    local dmgDir = dmginfo:GetDamageForce():GetNormalized()
    local vehType = veh.reforgerType or Reforger.GetVehicleType(veh)

    local penetrationThreshold = 50000

    if dmgForce < penetrationThreshold and not Reforger.PlayerBypassTypes[dmginfo:GetDamageType()] then
        Reforger.DevLog("Penetration blocked: Force too low - "..dmgForce)
        return
    end

    local basePos = ply:EyePos()
    local Len = veh:BoundingRadius()
    local dmgMultiplier = 1
    local newHitGroup = 0 -- Generic

    if vehType == "armored" then
        Len = Len * 0.5
        dmgMultiplier = dmgMultiplier * 0.5
    end

    local dmgPenetration = dmgDir * Len
    local dmgStart = dmgPos - dmgDir * (Len * 0.5)

    local hitboxes = {
        {name = "head", hgroup = 1, dmu = 5, pos = basePos, min = Vector(-5, -5, -7), max = Vector(5, 5, 12), color = Color(238, 255, 0, 150)},
    }

    for _, hb in ipairs(hitboxes) do
        local hit = util.IntersectRayWithOBB(dmgStart, dmgDir * Len, hb.pos, veh:GetAngles(), hb.min, hb.max)
        
        if hit then
            dmgMultiplier = dmgMultiplier * hb.dmu
            newHitGroup = hb.hgroup

            debugoverlay.Box(hb.pos, hb.min, hb.max, 1, hb.color)
            debugoverlay.Sphere(dmgPos, 2, 1, Color(255, 255, 0), true)

            Reforger.DevLog("HitBox detected: "..hb.name.." h "..ply:Health())
            break
        end
    end

    if dmgMultiplier <= 0 then return end

    if isnumber(newHitGroup) then ply:SetLastHitGroup(newHitGroup) end

    local damaged = Reforger.ApplyPlayerDamage(
        ply,
        dmginfo:GetDamage() * dmgMultiplier,
        dmginfo:GetAttacker(),
        dmginfo:GetInflictor()
    )

    if damaged and ply:Alive() then
        local eff = EffectData()
        eff:SetOrigin(ply:EyePos() + ply:GetAimVector() * 1.25)
        util.Effect("BloodImpact", eff)
        sound.Play("Flesh.ImpactHard", ply:EyePos(), 75, 100)
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