if not LVS then return end

-- Shitty for shitty =D
local function MainThink_Bullet()
    if not LVS then
        hook.Remove("Reforger.GlobalThink", "LVS_Reforger.BulletThink")
        return
    end

    if not LVS._ActiveBullets then return end

    for idx, bullet in pairs(LVS._ActiveBullets) do
        if bullet.ReforgerChanged then continue end

        if not istable(bullet.Filter) then
            bullet.Filter = {}
        end

        for i = #bullet.Filter, 1, -1 do
            if not IsValid(bullet.Filter[i]) then
                table.remove(bullet.Filter, i)
            end
        end

        local attacker = bullet.Attacker
        if IsValid(attacker) and IsValid(attacker.reforgerPod) then
            table.insert(bullet.Filter, attacker.reforgerPod)
        end

        hook.Run("Reforger.LVS_BulletFired", bullet)

        bullet.ReforgerChanged = true
    end
end

hook.Add("Reforger.GlobalThink", "LVS_Reforger.BulletThink", MainThink_Bullet)