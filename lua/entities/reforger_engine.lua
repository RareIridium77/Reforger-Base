AddCSLuaFile()

DEFINE_BASECLASS("base_entity")

ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "Reforger Fake Engine Collision"
ENT.Spawnable = false

ENT.IsReforgerEntity = true
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
    self.max = Vector(-4, -4, -4)

    self.boundSet = false

    Reforger.Log("Fake Engine Created", self)
end

function ENT:SetVehicleBase(veh)
    self.VehicleBase = veh
    
    if IsValid(self.VehicleBase) and self.VehicleBase.IsGlideVehicle then
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

function ENT:Think()
    if CLIENT then return end

    if not IsValid(self.VehicleBase) then
        self:Remove()
        return
    end

    if not self.boundSet and (self.min:DistToSqr(newMin) > 1 or self.max:DistToSqr(newMax) > 1) then
        self.boundSet = true

        self:PhysicsInit( SOLID_BBOX )
        self:SetMoveType( MOVETYPE_NONE )
        self:SetCollisionGroup( COLLISION_GROUP_PLAYER )
        self:SetCollisionBounds( self.min, self.max )
    end

    local textPos = self.VehicleBase:GetPos() + Vector(0, 0, self.max.z + 10)

    debugoverlay.BoxAngles(self:GetPos(), self.min, self.max, self:GetAngles(), 0.045, Color(225, 155, 155, 121))
    debugoverlay.Text(textPos, "max.z: " .. math.Round(vmaxs.z, 2), 0.02)

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
        for k, v in ipairs(veh.traceFilter) do
            if v == self then
                table.remove(veh.traceFilter, k)
                break
            end
        end

        Reforger.DevLog("Removed reforger_engine from glide.traceFilter", self, veh)
    end
end

if CLIENT then
    function ENT:Draw()
        if not IsValid(self) then return end
        render.SetColorMaterial()
        render.DrawBox(self:GetPos(), self:GetAngles(), self.min, self.max, Color(255, 0, 0, 100), true)
    end
end

if SERVER then
    concommand.Add("cross_player_sequence", function(ply, cmd)
        if not IsValid(ply) then return end
        
        local tr = ply:GetEyeTrace()
        local target = tr.Entity

        if not IsValid(target) then return end

        if target:IsVehicle() then
            target = target:GetDriver()

            if not IsValid(target) then
                ply:ChatPrint("[Cross] No entity found")
                return 
            end
        end

        local seqID = target:GetSequence()
        local seqName = target:GetSequenceName(seqID)

        ply:ChatPrint("[Cross] Sequence ID: " .. seqID .. " | Name: " .. seqName)
    end)

    concommand.Add("player_current_sequence", function(ply, cmd)
        print(ply:GetSequenceName(ply:GetSequence()))
    end)
end