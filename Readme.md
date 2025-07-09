# Reforger Base

**Reforger Base** is a shared system for my Garry's Mod addons under the [Reforger] tag.  
Its main purpose is to provide a unified damage and logic framework for different vehicle systems, such as:

- **[LVS](https://github.com/SpaxscE/lvs_base)**
- **[Simfphys](https://github.com/SpaxscE/simfphys_base)** 
- **[Gmod Glide](https://github.com/StyledStrike/gmod-glide)**

# Just a small examples

```lua
-- Shared Hooks

-- Reforger.Init -- called when Reforger Inits.
hook.Add("Reforger.Init", "Reforger_MyAddon.Init", function()
    print("[MyAddon] Reforger initialized!")
end)

-- Reforger.GlobalThink -- Just called by Think. Like general update tick.
hook.Add("Reforger.GlobalThink", "Reforger_MyAddon.Think", function()
    for _, ent in ipairs(ents.FindByClass("reforger_pod")) do
        ent:TakeDamage(10)
    end
end)

-- Reforger.EntityFunctionsCalled(ent) -- called every Reforger.CallEntityFunctions
hook.Add("Reforger.EntityFunctionsCalled", "Reforger_MyAddon.IgniteLVS", function(ent)
    if ent.reforgerBase == "lvs" then -- if entity based on LVS ignite it
        ent:Ignite(1, 1)
    end
end)

-- Reforger.PreEntityDamage(ent, damage, attacker, inflictor, reforgerDamageType, damagePos) -- called every Reforger.ApplyDamageToEnt
hook.Add("Reforger.PreEntityDamage", "Reforger_MyAddon.DamageBlock", function(ent, damage)
    if damage > 10 then return false end -- prevent damage if amount of damage more than 10
end)

-- Reforger.PostEntityDamage(ent, damage, attacker, inflictor, reforgerDamageType, pos) -- called after damages applied in Reforger.ApplyDamageToEnt
hook.Add("Reforger.PostEntityDamage", "Reforger_MyAddon.AdminInstantKill", function(ent)
    local ply = ent:IsPlayer() and ent or nil

    if IsValid(ply) and ply:IsAdmin() then ply:Kill() end
end)

LVS

-- Reforger.LVS_BulletFired(table: bullet) -- Called once when LVS bullet fired. BULLET IS A TABLE
hook.Add("Reforger.LVS_BulletFired", "Reforger_MyAddon.LogBullet", function(bullet)
    PrintTable(bullet)

    -- to get current pos you can firstly check if bullet.curpos then -- dostuff end
end)


-- Also for example you can track LVS bullets in your local table.
local bullets = {}

hook.Add("Reforger.GlobalThink", "Reforger_MyAddon.UpdateLVSBullets", function()
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]

        if not istable(bullet) then
            table.remove(bullets, i)
            continue
        end

        if bullet.curpos then 
            -- BE CAREFUL: DO NOT DRAW MANY debugoverlay RENDERS IN THINK! 
            -- YOUR GAME WILL STALL OR FREEZE DUE TO OVERLAY ACCUMULATION!

            debugoverlay.Sphere(bullet.curpos, 2, 0.025, Color(255, 255, 0), true)

            -- BAD EXAMPLE (DON'T DO THIS IN THINK): 
            -- Causes excessive overlapping overlays
            ---------------------------------------->1<- big delay
            -- debugoverlay.Sphere(bullet.curpos, 2, 1, Color(255, 255, 0), true)
        end
    end
end)

-- Adding LVS bullet to your table

hook.Add("Reforger.LVS_BulletFired", "Reforger_MyAddon.AddLVSBulletToTracker", function(bullet)
    if not istable(bullet) then return end
    table.insert(bullets, bullet)
end)
```
# Possibly Conflicting Addons

- [Damage Players In Seats](https://steamcommunity.com/sharedfiles/filedetails/?id=428278317) (May increase damage to players in vehicle)

## License

You can freely use and modify this base within your GMod projects, but attribution is appreciated.

