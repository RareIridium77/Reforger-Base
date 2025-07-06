AddCSLuaFile()

DEFINE_BASECLASS("base_entity")

ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "Reforger Fake Player Collision"
ENT.Spawnable = false

ENT.IsReforgerEntity = true
ENT.PhysgunDisabled = true
ENT.DoNotDuplicate = true
ENT.DisableDuplicator = true

function ENT:Initialize()
    if CLIENT then return end

    self:SetNoDraw(true)
    self:SetTrigger(true)
    self:SetNotSolid(false)

    self:PhysicsInit( SOLID_BBOX )
    self:SetMoveType( MOVETYPE_NONE )
    self:SetCollisionGroup( COLLISION_GROUP_PLAYER )

    self.min = Vector(0, 0, 0)
    self.max = Vector(0, 0, 0)

    self.boundSet = false

    Reforger.Log("Fake Collision Created", self)

    
    if IsValid(self.VehicleBase) and self.VehicleBase.IsGlideVehicle then
        local veh = self.VehicleBase

        if not istable(veh.traceFilter) then
            veh.traceFilter = {}
        end

        if not table.HasValue(veh.traceFilter, self) then
            veh.traceFilter[#veh.traceFilter + 1] = self
            Reforger.DevLog("Added reforger_pod to glide.traceFilter", self, self.Vehicle)
        end
    end
end

function ENT:Think()
    if CLIENT then return end

    if not IsValid(self.Vehicle) or not IsValid(self.Player) or not self.Player:InVehicle() then
        self:Remove()
        return
    end

    local ply = self.Player

    local mins, maxs = ply:OBBMins(), ply:OBBMaxs()
    local vmins, vmaxs = self.Vehicle:OBBMins(), self.Vehicle:OBBMaxs()

    local newMin = Vector(mins.x * 0.5, mins.y * 0.5, mins.z * 5)
    local newMax = Vector(maxs.x * 0.5, maxs.y * 0.5, vmaxs.z)

    local seqID = ply:GetSequence()

    if seqID == 387 then -- sit_rollercoaster
        newMax = Vector(maxs.x * 0.5, maxs.y * 0.5, vmaxs.z < 40 and vmaxs.z * 1.7 or vmaxs.z)
    elseif seqID == 9 then -- sit
        newMax = Vector(maxs.x * 0.5, maxs.y * 0.5, vmaxs.z < 40 and vmaxs.z * 1.7 or vmaxs.z)
    elseif seqID == 386 then -- drive_pd
        newMax = Vector(maxs.x * 0.5, maxs.y * 0.5, vmaxs.z > 50 and vmaxs.z * 0.9 or vmaxs.z * 1.35)
    elseif seqID == 388 then -- drive_airboat
        newMax = Vector(
            maxs.x * 0.5,
            maxs.y * 0.5,
            vmaxs.z < 110 and vmaxs.z * 1.8 or vmaxs.z * 0.65
        )
    elseif seqID == 389 then -- drive_jeep
        newMax = Vector(maxs.x * 0.5, maxs.y * 0.5, vmaxs.z < 40 and vmaxs.z * 1.9 or vmaxs.z * 0.5)
    elseif seqID == 90 then -- cwalk_revolver
        newMax = Vector(maxs.x * 0.5, maxs.y * 0.5, vmaxs.z > 27 and vmaxs.z * 2.4 or vmaxs.z * (0.1 * vmaxs.z))
    else
        newMax = Vector(maxs.x * 0.1, maxs.y * 0.1, vmaxs.z * 0.1)
    end

    local offset = self.Vehicle:GetForward() * 4
    self:SetPos(self.Vehicle:GetPos() + offset)
    self:SetAngles(self.Vehicle:GetAngles())

    if not self.boundSet and (self.min:DistToSqr(newMin) > 1 or self.max:DistToSqr(newMax) > 1) then
        self.boundSet = true

        self.min = newMin * 0.85
        self.max = newMax * 0.85

        self:PhysicsInit(SOLID_BBOX)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetCollisionGroup( COLLISION_GROUP_PLAYER )
        self:SetCollisionBounds(self.min, self.max)
    end

    local textPos = self.Vehicle:GetPos() + Vector(0, 0, vmaxs.z + 10)

    debugoverlay.BoxAngles(self:GetPos(), self.min, self.max, self:GetAngles(), 0.045, Color(225, 155, 155, 121))

    debugoverlay.Text(textPos, "vmax.z: " .. math.Round(vmaxs.z, 2) .. " seq: " .. ply:GetSequenceName(seqID) .. " id: " .. seqID, 0.02)

    self:NextThink(CurTime() + 0.0015)
    return true
end

function ENT:DoImpactEffect()
    return true
end

function ENT:OnTakeDamage(dmginfo)
    if not IsValid(self.Player) then return end

    local attacker = dmginfo:GetAttacker()

    if attacker == self.Player then return end

    Reforger.ApplyPlayerDamage(self.Player, dmginfo:GetDamage(), dmginfo:GetAttacker(), dmginfo:GetInflictor())
    debugoverlay.Sphere( self:GetPos(), 2, 0.5, Color(255, 155, 255), true )
end

function ENT:OnRemove()
    if CLIENT then return end
    
    Reforger.Log("Fake Collision Removed")

    local veh = self.VehicleBase
    if not IsValid(veh) then return end

    if istable(veh.traceFilter) and table.HasValue(veh.traceFilter, self) then
        for k, v in ipairs(veh.traceFilter) do
            if v == self then
                table.remove(veh.traceFilter, k)
                break
            end
        end

        Reforger.DevLog("Removed reforger_pod from glide.traceFilter", self, veh)
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