AddCSLuaFile()

DEFINE_BASECLASS("base_entity")

ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "Reforger Fake Engine Collision"
ENT.Spawnable = false

ENT.IsReforgerEntity = true
ENT.ReforgerDamageable = true
ENT.PhysgunDisabled = true
ENT.DoNotDuplicate = true
ENT.DisableDuplicator = true

function ENT:Initialize()
    if CLIENT then return end

    self:SetNoDraw(true)
    self:SetTrigger(true)
    self:SetNotSolid(false )

    self:PhysicsInit( SOLID_BBOX )
    self:SetMoveType( MOVETYPE_NONE )
    self:SetCollisionGroup( COLLISION_GROUP_PLAYER )

    self.min = Vector(-4, -4, -4)
    self.max = Vector(4, 4, 4)
    self:SetCollisionBounds( self.min, self.max )

    Reforger.Log("Fake Engine Created", self)
end

function ENT:SetVehicleBase(veh)
    self.VehicleBase = veh
    
    if IsValid(self.VehicleBase) then
        if self.VehicleBase.IsGlideVehicle then
            local veh = self.VehicleBase

            if not istable(veh.traceFilter) then
                veh.traceFilter = {}
            end

            if not table.HasValue(veh.traceFilter, self) then
                veh.traceFilter[#veh.traceFilter + 1] = self
                Reforger.DevLog("Added reforger_engine to glide.traceFilter", self, self.Vehicle)
            end
        end
    end
end

function ENT:SetEnginePos(engineData)
    if not engineData or not istable(engineData) then return end

    local pos = engineData.offset

    if not pos then return end

    if engineData.world_coords then
        self:SetPos(pos)
    else
        self:SetPos(self.VehicleBase:GetPos() + pos)
    end
end

function ENT:Think()
    if CLIENT then return end

    if not IsValid(self.VehicleBase) then
        self:Remove()
        return
    end

    local textPos = self.VehicleBase:GetPos() + Vector(0, 0, self.max.z + 10)

    debugoverlay.BoxAngles(self:GetPos(), self.min, self.max, self:GetAngles(), 0.045, Color(225, 155, 155, 121))
    debugoverlay.Text(textPos, "max.z: " .. math.Round(self.max.z, 2), 0.02)

    self:NextThink(CurTime() + 0.0015)
    return true
end

function ENT:DoImpactEffect()
    return true
end

function ENT:OnTakeDamage(dmginfo)
    debugoverlay.Sphere( self:GetPos(), 4, 0.5, Color(235, 133, 0), true )
end

function ENT:OnRemove()
    if CLIENT then return end
    
    Reforger.Log("Fake Engine Removed")

    local veh = self.VehicleBase
    if not IsValid(veh) then return end

    if istable(veh.traceFilter) and table.HasValue(veh.traceFilter, self) then
        table.RemoveByValue(veh.traceFilter, self)
        Reforger.DevLog("Removed reforger_engine from glide.traceFilter", self, veh)
    end
end