local Projectiles   = Reforger.Projectiles  or {}

Projectiles.Bomb    = Projectiles.Bomb      or {}
Projectiles.Missile = Projectiles.Missile   or {}

local runhook = hook.Run
local rafunc = Reforger.AddEntityFunction

local bombstr = "bomb"
local missilestr = "missile"

function Projectiles.IsProjectile( ent )
    return IsValid(ent) and ent.lvsProjectile
end

function Projectiles.IsBomb(ent)
    return Projectiles.IsProjectile(ent) and ent:GetClass() == "lvs_bomb"
end

function Projectiles.IsMissile(ent)
    return Projectiles.IsProjectile(ent) and ent:GetClass() == "lvs_missile"
end

--- [ LVS_BOMB ] ---

local function __bomb_touch( bomb )
    local otouch = bomb.StartTouch

    bomb.StartTouch = function(self, entity)
        if otouch then otouch(self, entity) end
        runhook("Reforger.LVS_BombTouch", self, entity)
        runhook("Reforger.LVS_ProjectileTouch", self, entity, bombstr)
    end
end

local function __bomb_collide( bomb )
    local ocollide = bomb.PhysicsCollide

    bomb.PhysicsCollide = function(self, data)
        if ocollide then ocollide(self, data) end
        runhook("Reforger.LVS_BombCollide", self, data)
        runhook("Reforger.LVS_ProjectileCollide", self, data, bombstr)
    end
end

local function __bomb_detonate(bomb)
    local odetonate = bomb.Detonate

    bomb.Detonate = function(self, target)
        if odetonate then odetonate(self, target) end
        runhook("Reforger.LVS_BombDetonated", self, target)
        runhook("Reforger.LVS_ProjectileDetonated", self, target, bombstr)
    end
end

local function __bomb_hooks(bomb)
    if not Projectiles.IsBomb(bomb) then return end
    
    __bomb_touch(bomb)
    __bomb_collide(bomb)
    __bomb_detonate(bomb)
end

rafunc("Reforger.LVS_Bombs", __bomb_hooks)

--- [ LVS_MISSILE ] ---

local function __missile_touch(missile)
    local otouch = missile.StartTouch

    missile.StartTouch = function(self, entity)
        if otouch then otouch(self, entity) end
        runhook("Reforger.LVS_MissileTouch", self, entity)
        runhook("Reforger.LVS_ProjectileTouch", self, entity, missilestr)
    end
end

local function __missile_collide( missile )
    local ocollide = missile.PhysicsCollide

    missile.PhysicsCollide = function( self, data )
        if ocollide then ocollide( self, data ) end
        runhook("Reforger.LVS_MissileCollide", self, data)
        runhook("Reforger.LVS_ProjectileCollide", self, data, missilestr)
    end
end

local function __missile_detonate(missile)
    local odetonate = missile.Detonate

    missile.Detonate = function(self, target)
        if odetonate then odetonate(self, target) end
        runhook("Reforger.LVS_MissileDetonated", self, target)
        runhook("Reforger.LVS_ProjectileDetonated", self, target, missilestr)
    end
end

local function __missile_hooks(missile)
    if not Projectiles.IsMissile(missile) then return end

    __missile_touch(missile)
    __missile_collide(missile)
    __missile_detonate(missile)
end

rafunc("Reforger.LVS_Missiles", __missile_hooks)

--- [ Projectiles ] ---

Reforger.Projectiles = Projectiles