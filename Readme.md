# Reforger Base

**Reforger Base** is a shared system for my Garry's Mod addons under the [Reforger] tag.  
Its main purpose is to provide a unified damage and logic framework for different vehicle systems, such as:

- **[LVS](https://github.com/SpaxscE/lvs_base)**
- **[Simfphys](https://github.com/SpaxscE/simfphys_base)** 
- **[Gmod Glide](https://github.com/StyledStrike/gmod-glide)**

**For getting Reforger table write console command: `reforger.table`**

**Also reforger can automaticly load your modules for reforger. From your addons folder.**

**Example**:
`my_addon/lua/reforger/m/server/reforger_my_module.lua`

```lua
-- /reforger/m/server/reforger_my_module.lua
if Reforger then
    for i = 0, 10 do
        Reforger.Log("You loaded the test file")
    end
end
```
<img width="277" height="122" alt="изображение" src="https://github.com/user-attachments/assets/7d81278f-bc11-4919-944f-b199345c5f3e" />

**The output**

# Just a small examples

```lua
-- Shared Hooks

-- Reforger.Init
-- Called when Reforger Inits.
hook.Add("Reforger.Init", "Reforger_MyAddon.Init", function()
    print("[MyAddon] Reforger initialized!")
end)

-- Reforger.GlobalThink
-- Called by Think hook
-- Example make every reforger_pod to take damage
hook.Add("Reforger.GlobalThink", "Reforger_MyAddon.Think", function()
    for _, ent in ipairs(ents.FindByClass("reforger_pod")) do
        ent:TakeDamage(10)
    end
end)

-- Reforger.EntityFunctionsCalled(ent: Entity)
-- Called every Reforger.CallEntityFunctions
-- Example if ent (vehicle) reforgerBase is lvs (LVS based vehicle) then ignite it for 1 second
hook.Add("Reforger.EntityFunctionsCalled", "Reforger_MyAddon.IgniteLVS", function(ent)
    if ent.reforgerBase == "lvs" then -- if entity based on LVS ignite it
        ent:Ignite(1, 1)
    end
end)

-- Reforger.PreEntityDamage(ent: Entity, damage: number, attacker: Entity, inflictor: Entity, reforgerDamageType: number Reforger.DamageType, damagePos: Vector)
-- Called every Reforger.ApplyDamageToEnt
-- Example if damage more than 10 then don't take damage (false)
hook.Add("Reforger.PreEntityDamage", "Reforger_MyAddon.DamageBlock", function(ent, damage)
    if damage > 10 then return false end -- prevent damage if amount of damage more than 10
end)

-- Reforger.PostEntityDamage(ent: Entity, damage: number, attacker: Entity, inflictor: Entity, reforgerDamageType: number Reforger.DamageType, damagePos: Vector)
-- Called after damages applied in Reforger.ApplyDamageToEnt
-- Example kill player if it's admin :D
hook.Add("Reforger.PostEntityDamage", "Reforger_MyAddon.AdminInstantKill", function(ent)
    local ply = ent:IsPlayer() and ent or nil

    if IsValid(ply) and ply:IsAdmin() then ply:Kill() end
end)

-- Reforger.PreRotorDamage(rotor: Entity, dmginfo: CTakeDamageInfo)
-- Called when rotor gets damage.
-- You can change amount of damage with dmginfo:SetDamage or dmginfo: ScaleDamage
--
-- Return format:
--   allowDamage: bool
-- return false to block damage
-- Example destroy on any damage. Doesn't matter how many damage
hook.Add("Reforger.PreRotorDamage", "Reforger_MyAddon.RotorDamageHandle", function(rotor)
    Reforger.DestroyRotor(rotor) -- it's safe
end)

-- Reforger.PostRotorDamage(rotor: Entity, dmginfo: CTakeDamageInfo)
-- Called after rotor gets damaged
-- You can't change amount of damage. Hook just gives you damage information and you can handle it
--
-- Example if rotors vehicle base is glide then destroy it
hook.Add("Reforger.PostRotorDamage", "Reforger_MyAddon.RotorADamagedHandle", function(rotor, vehicle)
    if not IsValid(rotor) then return end
    local veh = rotor.reforgerVehicle

    if not IsValid(veh) then print("vehicle is not valid") return end
    
    local base = veh.reforgerBase

    if base == "glide" then
        Reforger.DestroyRotor(rotor)
    end
end)

-- Reforger.RotorDestroyed(rotor: Entity)
-- Called when rotor gets destroyed
-- Example play effect when rotor destroyed
hook.Add("Reforger.RotorDestroyed", "Reforger_MyAddon.RotorDestroyHandle", function(rotor)
    if not IsValid(rotor) then return end

    -- code from wiki
    -- https://wiki.facepunch.com/gmod/util.Effect

    local vPoint = rotor:GetPos() -- get position of rotor
    local effectdata = EffectData()
    effectdata:SetOrigin( vPoint )
    util.Effect( "HelicopterMegaBomb", effectdata )
end)

-- Reforger.PodBloodEffect(attacker: Entity, hitPos: Vector, damage: number)
-- Called when a Reforger pod takes direct \ traced damage (e.g. bullet, trace damage, etc)
-- 
-- Return format:
--   effectName: string or nil — name of effect to use (e.g. "BloodImpact", "ManhackSparks")
--   shouldDraw: boolean or nil — whether to actually draw the effect (false disables it)
--
-- Example disable blood for combine NPCs, show sparks instead if HP > 50 (like they shooting with something sparks on player)
hook.Add("Reforger.PodBloodEffect", "Reforger_MyAddon.NoBloodForDroids", function(attacker, hitPos, damage)
    if IsValid(attacker) and attacker:IsNPC() and attacker:GetClass() == "npc_combine" then
        local shouldDraw = attacker:Health() > 50
        return "ManhackSparks", shouldDraw
    end
end)

-- Reforger.ReforgerEntityInit(ent: Entity reforger entity)
-- Called when reforger_base_entity inits
-- Example give damage after 5 seconds entity inits
hook.Add("Reforger.ReforgerEntityInit", "Reforger_MyAddon.ReforgerEntityInited", function(ent)
    if ent.ReforgerDamageable then
        timer.Simple(5, function() -- take damage after 5 seconds entity inits
            ent:TakeDamage(10) -- DMG_GENERIC with damage amount 10
        end)
    end
end)

-------------------------
-------- LVS ------------
-------------------------

-- Reforger.LVS_BulletFired(bullet: table)
-- Called once when LVS bullet fired. BULLET IS A TABLE
hook.Add("Reforger.LVS_BulletFired", "Reforger_MyAddon.LogBullet", function(bullet)
    PrintTable(bullet)

    -- to get current pos you can firstly check if bullet.curpos then -- dostuff end
    -- for more about bullet data is here: https://github.com/SpaxscE/lvs_base/blob/main/lua/lvs_framework/autorun/lvs_bulletsystem.lua
end)

--------------------------------------------------------
-- Example you can track LVS bullets in your local table.
--------------------------------------------------------

local bullets = {}

hook.Add("Reforger.GlobalThink", "Reforger_MyAddon.UpdateLVSBullets", function()
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]

        -- if you want to properly remove bullet use bulletRemoved flag (Reforger set up)
        if not istable(bullet) or bullet.bulletRemoved == true then
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

--------------------------------------------------------
-- End of Example
--------------------------------------------------------


-- Reforger.LVS_BulletOnCollide(bullet: table, trace: TraceResult)
-- Called when bullet collides
-- Here example when LVS bullet collides HelicopterMegaBomb effect appears
hook.Add("Reforger.LVS_BulletOnCollide", "Reforger_MyAddon.LVS_BulletCollide", function(bullet, trace)
    if trace.Hit then
        debugoverlay.Sphere(trace.HitPos, 10, 1, Color(255, 255, 50), true)
        local effectdata = EffectData()
        effectdata:SetOrigin( trace.HitPos )
        util.Effect( "HelicopterMegaBomb", effectdata )
    end
end)

-- Reforger.LVS_BulletCallback(bullet: table, trace: TraceResult, attacker: Entity, dmginfo: CTakeDamageInfo)
-- Called after bullet collides and bullet has Callback(attacker, trace, dmginfo) set
-- Example
hook.Add("Reforger.LVS_BulletCallback", "Reforger_MyAddon.BulletCallback", function(bullet, trace, attacker, dmginfo)
    if IsValid(trace.Entity) then
        print("[BulletCallback] Hit entity:", trace.Entity:GetClass())
        print("[BulletCallback] Damage:", dmginfo:GetDamage())
    end
end)

```
# Possibly Conflicting Addons

- [Damage Players In Seats](https://steamcommunity.com/sharedfiles/filedetails/?id=428278317) (May increase damage to players in vehicle)

## License

You can freely use and modify this base within your GMod projects, but attribution is appreciated.