AddCSLuaFile()

DEFINE_BASECLASS("base_entity")

ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "Reforger Base Entity"
ENT.Spawnable = false

ENT.IsReforgerEntity = true
ENT.ReforgerDamageable = false
ENT.PhysgunDisabled = true
ENT.DoNotDuplicate = true
ENT.DisableDuplicator = true

if CLIENT then return end

function ENT:InitReforgerEntity()
end

function ENT:Initialize()
    self.VehicleBase = nil 
    self:InitReforgerEntity()
end

function ENT:Think()
end

function ENT:OnTakeDamage(dmg)
end

function ENT:OnRemove()
    self:RemoveVehicleBase()
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

function ENT:RemoveVehicleBase()
    local veh = self.VehicleBase
    if not IsValid(veh) then return end

    if istable(veh.traceFilter) and table.HasValue(veh.traceFilter, self) then
        table.RemoveByValue(veh.traceFilter, self)
        Reforger.DevLog("Removed reforger_engine from glide.traceFilter", self, veh)
    end
end