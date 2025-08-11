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
ENT.CallDamageHook = false

if CLIENT then return end

local BaseEntityIgnore = {
    -- rpg_missile fix. https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/server/hl2/weapon_rpg.cpp#L395
    ["rpg_missile"] = {
        i = true,
        callback = function(missile, ent)
            timer.Simple(0, function()
                if not IsValid(missile) or not IsValid(ent) then return end

                local original = {
                    solid      = ent:GetSolid(),
                    solidFlags = ent:GetSolidFlags(),
                    colGroup   = ent:GetCollisionGroup(),
                }

                ent:SetSolid(SOLID_BBOX)
                ent:SetCollisionGroup(COLLISION_GROUP_WEAPON)
                ent:RemoveSolidFlags(FSOLID_TRIGGER)

                timer.Simple(0.05, function()
                    if not IsValid(ent) then return end

                    ent:SetSolid(original.solid)
                    ent:SetCollisionGroup(original.colGroup)
                    ent:SetSolidFlags(original.solidFlags)
                end)
            end)
        end
    }
}

function ENT:InitReforgerEntity()
end

function ENT:Initialize() 
    self:SetKeyValue("m_takedamage", "1")

    self:InitReforgerEntity()
    hook.Run("Reforger.ReforgerEntityInit", self)
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

function ENT:StartTouch(e)
    if not IsValid(e) then return end
    local ignorance = BaseEntityIgnore[e:GetClass()]

    if istable(ignorance) and ignorance.i == true and ignorance.callback then ignorance.callback(e, self) end
end
