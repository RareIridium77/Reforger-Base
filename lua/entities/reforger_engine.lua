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

if CLIENT then return end

function ENT:InitReforgerEntity()
    if CLIENT then return end

    self.min = Vector(-8, -8, -4)
    self.max = Vector(8, 8,  4)

    
    self:SetNoDraw(true)
    self:SetTrigger(true)
    
    self:SetNotSolid(false)
    
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON) -- solid to bullets
    
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

    self.simMaxHealth = 350
    self.simHealth = self.simMaxHealth

    debugoverlay.Sphere(pos, 10, 2, Color(25, 25, 255), true)
    debugoverlay.Line(self.VehicleBase:GetPos(), pos, 2, Color(255, 0, 0), true)
    debugoverlay.Sphere(self.VehicleBase:GetPos(), 10, 2, Color(25, 255, 25), true)

    Reforger.DevLog(("[EngineCollision] Engine initialized: MaxHealth = %.2f"):format(self.simMaxHealth))
end

function ENT:Think()
    if CLIENT then return end

    if not IsValid(self.VehicleBase) then
        self:Remove()
        return
    end
    debugoverlay.Box(
        self:GetPos(),
        self.min,
        self.max,
        0.2,
        Color(255, 255, 255, 28)
    )
    debugoverlay.BoxAngles(
        self:GetPos(),
        self.min,
        self.max,
        self:GetAngles(),
        0.2,
        Color(255, 50, 50, 49)
    )

    self:NextThink(CurTime())
    return true
end

function ENT:OnTakeDamage(dmginfo)
    if not IsValid(self.VehicleBase) then return end

    local vehicle = self.VehicleBase
    local vehBase = vehicle.reforgerBase
    local damage = dmginfo:GetDamage()
    local isSmallDamage = bit.band(dmginfo:GetDamageType(), DMG_BULLET + DMG_BUCKSHOT + DMG_CLUB) ~= 0

    if isSmallDamage and self.VehicleBase.reforgerType == "armored" then return end

    Reforger.DevLog(("[EngineCollision] Took damage: %.2f from %s"):format(damage * 0.35, tostring(dmginfo:GetAttacker())))

    if vehBase == "glide" and vehicle.TakeEngineDamage then
        if not vehicle:IsEngineStarted() then return end

        vehicle:TakeEngineDamage(damage * math.Rand(0.1, 0.25))
        Reforger.DevLog("[EngineCollision] Passed damage to Glide vehicle engine")
    elseif vehBase == "simfphys" then
        if not vehicle:EngineActive() then return end

        self.simHealth = math.Clamp(self.simHealth - damage * 0.35, -self.simMaxHealth, self.simMaxHealth)
        local lol = self.simHealth / self.simMaxHealth

        Reforger.DevLog(("[EngineCollision] simHealth = %.2f (%.1f%%)"):format(self.simHealth, lol * 100))

        if lol < 0.75 and lol > 0.35 then
            if vehicle:EngineActive() then
                Reforger.DevLog("[EngineCollision] EngineActive: triggering DamageStall()")
                vehicle:DamageStall()
            end
        end

        if lol < 0.35 then
            Reforger.DevLog("[EngineCollision] simHealth critically low, setting vehicle on fire")
            vehicle:SetOnFire(true)
        end
    end

    debugoverlay.BoxAngles(
        self:GetPos(),
        self.min,
        self.max,
        self:GetAngles(),
        0.1,
        Color(255, 50, 50, 248)
    )
end