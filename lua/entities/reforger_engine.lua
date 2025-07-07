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

end