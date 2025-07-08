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

    self:PhysicsInit(SOLID_BBOX)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_PLAYER)
    self:SetCollisionBounds(self.min, self.max)

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
end

function ENT:Think()
    if CLIENT then return end

    if not IsValid(self.VehicleBase) then
        self:Remove()
        return
    end

    debugoverlay.BoxAngles(
        self:GetPos(),
        self.min,
        self.max,
        self:GetAngles(),
        0.2,
        Color(255, 50, 50, 120)
    )

    self:NextThink(CurTime() + 0.2)
    return true
end

function ENT:OnTakeDamage(dmginfo)
    debugoverlay.BoxAngles(
        self:GetPos(),
        self.min,
        self.max,
        self:GetAngles(),
        0.1,
        Color(255, 50, 50, 248)
    )
end
