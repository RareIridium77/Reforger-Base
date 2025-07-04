if not Reforger then return end

Reforger.Log("Reforger_Damage Initialized")

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
    player_dmginfo:SetDamageType( DMG_ACID + DMG_DIRECT + DMG_BULLET )

    -- Just a gmod moment

    if ply:Alive() then
        ply:TakeDamageInfo(player_dmginfo)
        return true 
    end

    return false 
end

function Reforger.ApplyPlayerFireDamage(veh, dmginfo)
    if not IsValid(veh) or not IsValid(dmginfo) then return end

    local IsFireDamage = dmginfo:IsDamageType( DMG_BURN ) or (veh.IsGlideVehicle and dmginfo:IsDamageType( DMG_DIRECT )) -- Glide vehicles has own fun with damage

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

    local basePos = ply:EyePos()

    local hitboxes = {
        {name = "head", dmu = 5, pos = basePos, min = Vector(-5, -5, -7), max = Vector(5, 5, 12), color = Color(238, 255, 0, 150)},   -- Голова
    }
    
    local dmgMultiplier = 1

    local Len = veh:BoundingRadius()
    local dmgPos = dmginfo:GetDamagePosition()
    local dmgDir = dmginfo:GetDamageForce():GetNormalized()
    local dmgPenetration = dmgDir * Len

    local dmgStart = dmgPos - dmgDir * (Len * 0.5)

    for _, hb in ipairs(hitboxes) do
        local localdmgPos = WorldToLocal(dmgPos, Angle(0, 0, 0), hb.pos, veh:GetAngles())
        local hit = util.IntersectRayWithOBB(dmgStart, dmgDir * Len, hb.pos, veh:GetAngles(), hb.min, hb.max)

        if hit then
            dmgMultiplier = hb.dmu
            debugoverlay.Box(hb.pos, hb.min, hb.max, 1, hb.color)
            debugoverlay.Sphere(dmgPos, 2, 1, Color(255, 255, 0), true)
            Reforger.DevLog("HitBox detected: "..hb.name)
            break
        end
    end

    if dmgMultiplier == 0 then return end

    local damaged = Reforger.ApplyPlayerDamage(
        ply,
        dmginfo:GetDamage() * dmgMultiplier,
        dmginfo:GetAttacker(),
        dmginfo:GetInflictor()
    )

    if damaged and ply:Alive() then
        local eyepos = ply:EyePos()
        local eff = EffectData()

        eff:SetOrigin(eyepos + ply:GetAimVector() * 2)

        util.Effect("BloodImpact", eff)
        sound.Play("Flesh.ImpactHard", eyepos, 75, 100)
    end
end
