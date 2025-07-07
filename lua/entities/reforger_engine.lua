AddCSLuaFile()

DEFINE_BASECLASS("reforger_base_entity")

ENT.Type = "anim"
ENT.Base = "reforger_base_entity"
ENT.PrintName = "Reforger Fake Engine Collision"
ENT.Spawnable = false

ENT.IsReforgerEntity = true
ENT.ReforgerDamageable = true
ENT.PhysgunDisabled = true
ENT.DoNotDuplicate = true
ENT.DisableDuplicator = true

if CLIENT then return end

function ENT:InitReforgerEntity()
    if CLIENT then return end

    self.min = Vector(-4, -4, -4)
    self.max = Vector(4, 4, 4)

    self:SetNoDraw(true)
    self:SetTrigger(true)
    self:SetNotSolid(false )

    self:PhysicsInit( SOLID_BBOX )
    self:SetMoveType( MOVETYPE_NONE )

    self:SetCollisionGroup( COLLISION_GROUP_PLAYER )
    self:SetCollisionBounds( self.min, self.max )
end

function ENT:SetEngineData(data)
    if not istable(data) then return end

    self.EngineOffset = data.offset or Vector(0, 0, 0)
    self.WorldOffset = data.world_coords == true
end

function ENT:Think()
    if CLIENT then return end
    if not IsValid(self.VehicleBase) then
        self:Remove()
        return
    end

    local basePos = self.VehicleBase:GetPos()
    local pos = self.WorldOffset and self.EngineOffset or self.VehicleBase:LocalToWorld(self.EngineOffset)

    self:SetPos(pos)
    self:SetAngles(self.VehicleBase:GetAngles())

    debugoverlay.BoxAngles(self:GetPos(), self.min, self.max, self:GetAngles(), 0.05, Color(255, 50, 50, 120))

    self:NextThink(CurTime() + 0.03)
    return true
end
