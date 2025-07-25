if not LVS then return end

local Bullets = {}

function Bullets.GetField(bulletData, field, fallbackTable, defaultValue, typeCheck)
    if not istable(bulletData) then return defaultValue end
    if not isstring(field) then return defaultValue end

    local value = bulletData[field]
    if not typeCheck or typeCheck(value) then
        return value
    end

    local tracerName = bulletData.TracerName
    if fallbackTable and istable(fallbackTable) and isstring(tracerName) then
        local fallback = fallbackTable[tracerName]
        if not typeCheck or typeCheck(fallback) then
            return fallback
        end
    end

    return defaultValue
end

hook.Add("Reforger.Init", "LVS_Reforger.ChangeBulletFire", function()
    local origFireBullet = LVS.FireBullet

    function LVS:FireBullet(data)
        origFireBullet(self, data)

        local maxIndex = nil
        local maxTime = 0

        for idx, b in pairs(LVS._ActiveBullets) do
            if istable(b) and b.StartTime and b.StartTime > maxTime then
                maxTime = b.StartTime
                maxIndex = idx
            end
        end

        if maxIndex then
            local bullet = LVS._ActiveBullets[maxIndex]
            if not bullet then return end
            
            if bullet.ReforgerChanged then return end

            if not istable(bullet.Filter) then
                bullet.Filter = {}
            end

            for i = #bullet.Filter, 1, -1 do
                if not IsValid(bullet.Filter[i]) then
                    table.remove(bullet.Filter, i)
                end
            end

            local attacker = bullet.Attacker
            local pod = attacker.reforgerPod
            if IsValid(pod) and not table.HasValue(bullet.Filter, pod) then
                table.insert(bullet.Filter, pod)
            end
 
            hook.Run("Reforger.LVS_BulletFired", bullet)

            local bulletOnCollide = bullet.OnCollide
            local bulletCallback = bullet.Callback
            local bulletRemove = bullet.Remove

            bullet.OnCollide = function( self, trace )
                hook.Run("Reforger.LVS_BulletOnCollide", self, trace)

                if bulletOnCollide then
                    bulletOnCollide( self, trace )
                end
            end

            bullet.Callback = function(attacker, trace, dmginfo)
                hook.Run("Reforger.LVS_BulletCallback", bullet, trace, attacker, dmginfo)

                if bulletCallback then
                    bulletCallback(attacker, trace, dmginfo)
                end
            end

            bullet.Remove = function( self )
                if bulletRemove then
                    bulletRemove( self )
                end

                self.bulletRemoved = true
            end

            bullet.ReforgerChanged = true
        end
    end
end)

Reforger.Bullets = Bullets