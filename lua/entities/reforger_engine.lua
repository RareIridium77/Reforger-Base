AddCSLuaFile()

DEFINE_BASECLASS("reforger_base_entity")

ENT.Type              = "anim"
ENT.Base              = "reforger_base_entity"
ENT.PrintName         = "Reforger Fake Engine Collision"
ENT.Spawnable         = false

ENT.IsReforgerEntity  = true
ENT.ReforgerDamageable = true
ENT.PhysgunDisabled   = true
ENT.DoNotDuplicate    = true
ENT.DisableDuplicator = true
ENT.CallDamageHook = true 

local COLLISION_BOUNDS = {
    min = Vector(-8, -8, -4),
    max = Vector( 8,  8,  4),
}

local COLLISION_GROUP  = COLLISION_GROUP_WEAPON -- solid to bullets
local ENGINE_HEALTH    = 350                   -- simfphys engine health
local DAMAGE_REDUCTION = 0.35                  -- multiplier for simfphys damage
local DAMAGE_RAND_MIN  = 0.10                  -- glide: min random damage
local DAMAGE_RAND_MAX  = 0.25                  -- glide: max random damage

local STALL_THRESHOLD  = 0.75                  -- simfphys: engine stall threshold
local FIRE_THRESHOLD   = 0.35                  -- simfphys: fire trigger threshold

local DEBUG_DURATION   = 2                     -- debugoverlay duration
local DEBUG_COLOR_HIT  = Color(255, 50, 50, 248)
local DEBUG_COLOR_BOX  = Color(255, 50, 50, 49)

if CLIENT then return end

function ENT:InitReforgerEntity()
    self.min = COLLISION_BOUNDS.min
    self.max = COLLISION_BOUNDS.max

    self:SetNoDraw(true)
    self:SetTrigger(true)
    self:SetNotSolid(false)
    self:SetCollisionGroup(COLLISION_GROUP)
    self:SetCollisionBounds(self.min, self.max)
    self:SetMoveType(MOVETYPE_NONE)

    self.simHealth = -1
    self.firstSet = false
end

function ENT:SetEngineData(data)
    if not istable(data) then return end

    self.EngineOffset = data.offset or Vector(0, 0, 0)
    self.WorldOffset  = false

    if not IsValid(self.VehicleBase) then
        self:Remove()
        return
    end

    local pos = self.EngineOffset
    if self.VehicleBase.reforgerBase == "simfphys" then
        pos = self.VehicleBase:LocalToWorld(pos)
    end

    self:SetPos(pos)
    self:SetAngles(self.VehicleBase:GetAngles())
    self:SetParent(self.VehicleBase)

    self.simMaxHealth = ENGINE_HEALTH
    self.simHealth = self.simMaxHealth

    debugoverlay.Sphere(pos, 10, DEBUG_DURATION, Color(25, 25, 255), true)
    debugoverlay.Line(self.VehicleBase:GetPos(), pos, DEBUG_DURATION, Color(255, 0, 0), true)
    debugoverlay.Sphere(self.VehicleBase:GetPos(), 10, DEBUG_DURATION, Color(25, 255, 25), true)
end

function ENT:Think()
    if not IsValid(self.VehicleBase) then
        self:Remove()
        return
    end

    debugoverlay.Box(self:GetPos(), self.min, self.max, 0.2, Color(255, 255, 255, 28))
    debugoverlay.BoxAngles(self:GetPos(), self.min, self.max, self:GetAngles(), 0.2, DEBUG_COLOR_BOX)

    self:NextThink(CurTime())
    return true
end

function ENT:OnTakeDamage(dmginfo)
    if not IsValid(self.VehicleBase) then return end

    local vehicle = self.VehicleBase
    local vehBase = vehicle.reforgerBase
    local damage  = dmginfo:GetDamage()
    local isSmallDamage = bit.band(dmginfo:GetDamageType(), DMG_BULLET + DMG_BUCKSHOT + DMG_CLUB) ~= 0

    if isSmallDamage and self.VehicleBase.reforgerType == "armored" then return end

    if vehBase == "glide" and vehicle.TakeEngineDamage then
        if not vehicle:IsEngineStarted() then return end
        vehicle:TakeEngineDamage(damage * math.Rand(DAMAGE_RAND_MIN, DAMAGE_RAND_MAX))

    elseif vehBase == "simfphys" then
        if not vehicle:EngineActive() then return end

        self.simHealth = math.Clamp(self.simHealth - damage * DAMAGE_REDUCTION, -self.simMaxHealth, self.simMaxHealth)
        local healthFrac = self.simHealth / self.simMaxHealth

        if healthFrac < STALL_THRESHOLD and healthFrac > FIRE_THRESHOLD then
            if vehicle:EngineActive() then
                vehicle:DamageStall()
            end
        end

        if healthFrac < FIRE_THRESHOLD then
            vehicle:SetOnFire(true)
        end
    end

    debugoverlay.BoxAngles(self:GetPos(), self.min, self.max, self:GetAngles(), 0.1, DEBUG_COLOR_HIT)
end