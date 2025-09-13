if not LVS then return end

local runhook   = hook.Run
local addmodule = Reforger.AddEntityModule
local rafunc    = function(idf, func)
    addmodule(Reforger, idf, func)
end

// SECTION Reforger LVS Bullet System]

local Bullets = {}

function Bullets.GetField(bulletData, field, fallbackTable, defaultValue, typeCheck) // REVIEW
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

// !SECTION

// SECTION Reforger LVS Explosion

local function __lvs_explode(lvs)
    local oexplode = lvs.Explode

    lvs.Explode = function(self)
        if self.reforgerExploded then return end
        
        if oexplode then oexplode(self) end
        runhook("Reforger.LVS_Exploded", self)

        self.reforgerExploded = true
    end
end

local function __lvs_hooks(ent)
    if not IsValid(ent) or not ent.LVS then return end

    __lvs_explode(ent)
end

// !SECTION

// SECTION Reforger LVS Projectiles

// TODO Fix projectile activation.

local Projectiles   = Reforger.Projectiles  or {}

Projectiles.Bomb    = Projectiles.Bomb      or {}
Projectiles.Missile = Projectiles.Missile   or {}

local bombstr = "bomb"

local missilestr = "missile"

function Projectiles.IsProjectile( ent )
    if not IsValid(ent) then return false end
    
    return ent.lvsProjectile or ent.SWBombV3 or ent.IsRocket
end

// NOTE CURRENTLY SUPPORTS ONLY LVS BOMBS
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
    __bomb_touch(bomb)
    __bomb_active(bomb)
    __bomb_collide(bomb)
    __bomb_detonate(bomb)
end

--- [ LVS_MISSILE ] ---

local function __missile_touch(missile)
    local otouch = missile.StartTouch

    missile.StartTouch = function(self, entity)
        if otouch then otouch(self, entity) end
        runhook("Reforger.LVS_MissileTouch", self, entity)
        runhook("Reforger.LVS_ProjectileTouch", self, entity, missilestr)
    end
end

local function __missile_active(missile) // REVIEW Missile Activation methods
    local function doAct()
        runhook("Reforger.LVS_MissileActivated", missile)
        runhook("Reforger.LVS_ProjectileActivated", missile, missilestr)
    end

    if missile.Enable then
        local olaunch = missile.Enable

        missile.Enable = function(self)
            if olaunch then olaunch(self) end
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

// !SECTION

// SECTION Reforger LVS Weapons
// TODO: Extend

local Weapons   = Reforger.Weapons or {}

local function IsWeaponed(veh)
    return IsValid(veh) and veh.LVS and istable(veh.WEAPONS)
end

--- [ Global Reforger ] ---

function Weapons.IsWeaponed(veh)  return IsWeaponed(veh) end
function Weapons.Get(veh)
    if not IsWeaponed(veh) then return {} end
    return veh.WEAPONS
end
function Weapons.GetActive(veh)
	if not Weapons.IsWeaponed(veh) then return nil end

	local getSelected = isfunction(veh.GetSelectedWeapon) and veh.GetSelectedWeapon or veh.GetSelectedWeaponID
	if not isfunction(getSelected) then return nil end

	local selectedID = getSelected(veh)
	if not selectedID then return nil end

	local weaponGroups = veh.WEAPONS
	if not istable(weaponGroups) then return nil end

	local group = weaponGroups[selectedID]
	if istable(group) and istable(group[1]) then
		return group[1]
	elseif istable(group) then
		return group
	end

	return nil
end

--- [ LVS Weapons ] ---

local function __weapon_init(veh, weapon)
    if not IsValid(veh) then return end

    weapon.ReforgedVehicle = veh
    
    runhook("Reforger.LVS_WeaponInit", weapon, veh)
end

local function __weapon_aevents(weapon)
    if not istable(weapon) then return end

    local osattack = weapon.StartAttack
    local oattack = weapon.Attack
    local ofattack = weapon.FinishAttack

    weapon.StartAttack = function(ent)
        if osattack then osattack(ent) end
        runhook("Reforger.LVS_WeaponStartAttack", weapon, ent)
    end

    weapon.Attack = function(ent)
        local can = runhook("Reforger.LVS_WeaponCanAttack", weapon, ent)

        if can == false then
            Reforger.DevLog("[Reforger] Weapon attack prevented by hook")
            return
        end

        if oattack then oattack(ent) end
        runhook("Reforger.LVS_WeaponAttack", weapon, ent)
    end

    weapon.FinishAttack = function(ent)
        if ofattack then ofattack(ent) end
        runhook("Reforger.LVS_WeaponFinishAttack", weapon, ent)
    end
end

local function __weapon_hooks(ent)
    if not IsWeaponed(ent) then return end

    local lvsWeapons = ent.WEAPONS

    for outerIndex, weaponGroup in ipairs(ent.WEAPONS) do
        for innerIndex, weapon in pairs(weaponGroup) do
            __weapon_init(ent, weapon)
            __weapon_aevents(weapon)
        end
    end
end

// !SECTION


// SECTION Reg Functions
Reforger.Bullets = Bullets
rafunc("Reforger.LVS_Explosion", __lvs_hooks)

rafunc("Reforger.LVS_Bombs", __bomb_hooks)
rafunc("Reforger.LVS_Missiles", __missile_hooks)
Reforger.Projectiles = Projectiles

rafunc("Reforger.LVS_Weapons", __weapon_hooks)
Reforger.Weapons = Weapons
// !SECTION