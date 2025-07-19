-- TODO: Fix projectile activation.

local Projectiles   = Reforger.Projectiles  or {}

Projectiles.Bomb    = Projectiles.Bomb      or {}
Projectiles.Missile = Projectiles.Missile   or {}

local runhook       = hook.Run
local rafunc        = Reforger.AddEntityFunction
local bombstr = "bomb"

local missilestr = "missile"

function Projectiles.IsProjectile( ent )
    if not IsValid(ent) then return false end
    
    return ent.lvsProjectile or ent.SWBombV3 or ent.IsRocket
end

--- CURRENTLY SUPPORTS ONLY LVS BOMBS ---
function Projectiles.IsBomb(ent)
    return Projectiles.IsProjectile(ent) and ent:GetClass() == "lvs_bomb" or (ent.SWBombV3 and not ent.IsRocket)
end

function Projectiles.IsMissile(ent)
    return Projectiles.IsProjectile(ent) and (ent:GetClass() == "lvs_missile" or ent.IsRocket)
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

local function __bomb_active(bomb)
    local oactivate = bomb.Enable

    bomb.Enable = function(self)
        if oactivate then oactivate(self) end
        runhook("Reforger.LVS_BombActivated", self)
        runhook("Reforger.LVS_ProjectileActivated", self, bombstr)
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
        if self._rlfx_detonated then return end
        self._rlfx_detonated = true
        runhook("Reforger.LVS_BombDetonated", self, target)
        runhook("Reforger.LVS_ProjectileDetonated", self, target, bombstr)
    end
end

local function __bomb_hooks(bomb)
    if not Projectiles.IsBomb(bomb) then return end
    print(bomb)
    __bomb_touch(bomb)
    __bomb_active(bomb)
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

local function __missile_active(missile)
    local function doAct()
        runhook("Reforger.LVS_MissileActivated", missile)
        runhook("Reforger.LVS_ProjectileActivated", missile, missilestr)
    end

    if missile.Launch then
        local olaunch = missile.Launch

        missile.Launch = function(self, phys)
            if olaunch then olaunch(self, phys) end
            doAct()
        end
    else
        doAct()
    end
end

local function __missile_collide( missile ) -- I just wanna some style in code, but I can do that normally
    local ocollide = missile.PhysicsCollide

    missile.PhysicsCollide = function( self, data )
        if ocollide then ocollide( self, data ) end
        runhook("Reforger.LVS_MissileCollide", self, data)
        runhook("Reforger.LVS_ProjectileCollide", self, data, missilestr)
    end
end

local function __missile_detonate(missile)
    if missile.Detonate then
        local odetonate = missile.Detonate

        missile.Detonate = function(self, target)
            if odetonate then odetonate(self, target) end
            if self._rlfx_detonated then return end
            self._rlfx_detonated = true
            runhook("Reforger.LVS_MissileDetonated", self, target)
            runhook("Reforger.LVS_ProjectileDetonated", self, target, missilestr)
        end
    elseif missile.Explode then
        local oexplode = missile.Explode

        missile.Explode = function(self, target)
            if oexplode then oexplode(self, target) end
            if self._rlfx_detonated then return end
            self._rlfx_detonated = true
            runhook("Reforger.LVS_MissileDetonated", self, target)
            runhook("Reforger.LVS_ProjectileDetonated", self, target, missilestr)
        end
    end
end

local function __missile_hooks(missile)
    if not Projectiles.IsMissile(missile) then return end
    __missile_touch(missile)
    __missile_active(missile)
    __missile_collide(missile)
    __missile_detonate(missile)
end

rafunc("Reforger.LVS_Missiles", __missile_hooks)

--- [ Projectiles ] ---

Reforger.Projectiles = Projectiles