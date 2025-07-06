AddCSLuaFile()

DEFINE_BASECLASS("base_entity")

ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "Reforger Fake Player Collision"
ENT.Spawnable = false
ENT.IsReforgerEntity = true

function ENT:Initialize()
    if CLIENT then return end

    self:SetNoDraw(true)
    self:SetTrigger(true)
    self:SetNotSolid(false)

    self:SetSolid(SOLID_BBOX)
    self:PhysicsInit(SOLID_BBOX)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)

    self.min = Vector(-5, -7, -20.5)
    self.max = Vector(5, 7, 10)
    self:SetCollisionBounds(self.min, self.max)

    Reforger.Log("Fake Collision Created", self)
end

function ENT:Think()
    if CLIENT then return end

    if not IsValid(self.Vehicle) or not IsValid(self.Player) or not self.Player:InVehicle() then
        self:Remove()
        return
    end

    local mins, maxs = self.Player:OBBMins(), self.Player:OBBMaxs()

    local newMin = Vector(mins.x * 0.5, mins.y * 0.5, mins.z)
    local newMax = Vector(maxs.x * 0.5, maxs.y * 0.5, maxs.z * 0.60)

    if self.min:DistToSqr(newMin) > 1 or self.max:DistToSqr(newMax) > 1 then
        self.min = newMin
        self.max = newMax
        self:SetCollisionBounds(self.min, self.max)
    end

    local offset = self.Vehicle:GetForward() * 4
    self:SetPos(self.Vehicle:GetPos() + offset)
    self:SetAngles(self.Vehicle:GetAngles())

    debugoverlay.BoxAngles(self:GetPos(), self.min, self.max, self:GetAngles(), 0.05, Color(225, 155, 155, 121))

    self:NextThink(CurTime())
    return true
end

function ENT:DoImpactEffect()
    return true -- чтобы отключить стандартные эффекты
end

function ENT:OnTakeDamage(dmginfo)
    if not IsValid(self.Player) then return end

    Reforger.ApplyPlayerDamage(self.Player, dmginfo:GetDamage(), dmginfo:GetAttacker(), dmginfo:GetInflictor())
end

function ENT:OnRemove()
    if CLIENT then return end
    Reforger.Log("Fake Collision Removed")
end

if CLIENT then
    function ENT:Draw()
        if not IsValid(self) then return end
        render.SetColorMaterial()
        render.DrawBox(self:GetPos(), self:GetAngles(), self.min, self.max, Color(255, 0, 0, 100), true)
    end
end
