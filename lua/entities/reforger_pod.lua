AddCSLuaFile()

DEFINE_BASECLASS("reforger_base_entity")

ENT.Type = "anim"
ENT.Base = "reforger_base_entity"
ENT.PrintName = "Reforger Fake Player Collision"
ENT.Spawnable = false

ENT.IsReforgerEntity = true
ENT.ReforgerDamageable = true
ENT.PhysgunDisabled = true
ENT.DoNotDuplicate = true
ENT.DisableDuplicator = true

if CLIENT then return end

local seqAdjustments = {
    sit_rollercoaster = { maxZ = 1.9, minZ = 0.1, offset = -2 },
    sit               = { maxZ = 1.9, minZ = 0.1, offset = -5 },
    sit_zen           = { maxZ = 1.9, minZ = 0.1 },
    drive_pd          = { maxZ = 1.9, minZ = 0.1 },
    drive_airboat     = { maxZ = 1.9, minZ = 0.1, offset = 7 },
    drive_jeep        = { maxZ = 2.2, minZ = 0.1, offset = 7 },
    cwalk_revolver    = { maxZ = 2.75, minZ = 0.23 },
}

function ENT:InitReforgerEntity()
    if CLIENT then return end

    self:SetNoDraw(true)
    self:SetTrigger(true)
    self:SetNotSolid(false)
    self:SetCollisionGroup(COLLISION_GROUP_PLAYER)
    self:SetCollisionBounds(Vector(-32, -32, 0), Vector(32, 32, 72))
    self:PhysicsInit(SOLID_OBB)
    self:SetPos(self:GetPos())

    self.seqAdjustments = seqAdjustments
    self.pseudoMin, self.pseudoMax = Vector(), Vector()
    self.pseudoAng = Angle()
end

function ENT:SetPlayer(ply)
    self.Player = ply
end

function ENT:SetVehicle(veh)
    if not IsValid(veh) then return end
    self.Vehicle = veh
    self:SetMoveParent(veh)
end

function ENT:Think()
    if CLIENT or not IsValid(self.Vehicle) or not IsValid(self.Player) or not self.Player:InVehicle() then
        self:Remove()
        return
    end

    local seqID = self.Player:GetSequence()
    local seqName = self.Player:GetSequenceName(seqID)
    local adjust = self.seqAdjustments[seqName]
    local vehPos, vehAng = self.Vehicle:GetPos(), self.Vehicle:GetAngles()
    local offset = self.Vehicle:GetForward() * (adjust and adjust.offset or 2)

    self.pseudoPos, self.pseudoAng = vehPos + offset, vehAng
    self.headZone = self.pseudoPos.z + (self.pseudoMax.z * 0.7225)

    local extraZ = 0

    local headBoneID = self.Player:LookupBone("ValveBiped.Bip01_Head1")
    if headBoneID then
        local headPos = self.Player:GetBonePosition(headBoneID)
        if headPos and headPos.z > self.pseudoPos.z + self.pseudoMax.z then
            local relativeHeadZ = headPos.z - self.pseudoPos.z
            self.pseudoMax.z = relativeHeadZ * 1.05
            self.headZone = self.pseudoPos.z + (self.pseudoMax.z * 0.7225)
            extraZ = (self.pseudoMax.z - self.pseudoMin.z) * 0.2 -- запас на extent
            Reforger.DevLog(("[FakeCollision] Adjusted pseudoMax.z to head bone height: %.2f"):format(self.pseudoMax.z))
        end
    end

    if self.lastSeqID ~= seqID then
        self.lastSeqID = seqID
        local vmins, vmaxs = self.Vehicle:OBBMins(), self.Vehicle:OBBMaxs()
        local newMin = Vector(vmins.x * 0.5, vmins.y * 0.5, vmins.z)
        local newMax = Vector(vmaxs.x * 0.5, vmaxs.y * 0.5, vmaxs.z)

        if adjust then
            newMax.z = newMax.z * adjust.maxZ
            newMin.z = newMax.z * adjust.minZ
        else
            newMax.z, newMin.z = newMax.z * 1.9, newMax.z * 0.1
        end

        self.pseudoMin, self.pseudoMax = newMin * 0.85, newMax * 0.85
        self.headZone = self.pseudoPos.z + (self.pseudoMax.z * 0.7225)
        Reforger.DevLog(('[FakeCollision] Updated pseudo-bounds for %s (%d)'):format(seqName, seqID))
    end

    local eyeDir = (self.Player:EyePos() - self.pseudoPos):GetNormalized()
    local eyePos = self.pseudoPos + eyeDir * 35
    local center = (eyePos + self.pseudoPos) * 0.5
    local extent = Vector(
        math.abs(eyePos.x - self.pseudoPos.x),
        math.abs(eyePos.y - self.pseudoPos.y),
        math.abs(eyePos.z - self.pseudoPos.z)
    ) * 0.5
    
    if self:GetPos() ~= center then self:SetPos(center) end
    
    extent:Add(Vector(12, 10, 15 + extraZ))

    if not self.lastExtent or self.lastExtent ~= extent then
        self.lastExtent = extent
        self:SetCollisionBounds(-extent, extent)
    end
    debugoverlay.BoxAngles(self.pseudoPos, self.pseudoMin, self.pseudoMax, self.pseudoAng, 0.06, Color(255, 255, 255, 10))
    self:NextThink(CurTime() + 0.025)
    return true
end

function ENT:DoImpactEffect(tr, dmgType)
    return true
end

function ENT:GetTraceFilter()
    return function(ent)
        return not (ent == self or ent == self.Player or ent.ReforgerDamageable)
    end
end

function ENT:OnTakeDamage(dmginfo)
    local attacker = dmginfo:GetAttacker()
    if not IsValid(self.Player) or not IsValid(self.VehicleBase) or not IsValid(attacker) or attacker == self.Player then return end

    local damage = dmginfo:GetDamage()
    local inflictor = dmginfo:GetInflictor()
    local damagePos = dmginfo:GetDamagePosition()
    local dmgType = dmginfo:GetDamageType()
    local isTraced = dmginfo:GetDamageCustom() == 1

    if dmginfo:IsExplosionDamage() or dmgType == DMG_DIRECT or Reforger.IsFireDamageType(self.VehicleBase, dmgType) then
        Reforger.ApplyPlayerDamage(self.Player, damage, attacker, inflictor, nil)
        return
    end

    Reforger.DevLog("[FakeCollision] OnTakeDamage | Damage: " .. tostring(damage))

    if self.VehicleBase.reforgerBase == Reforger.VehicleBases.Simfphys and GetConVar("sv_simfphys_playerdamage"):GetInt() <= 0 then return end

    local margin = 1.5

    local expandedMin = self.pseudoMin - Vector(margin, margin, margin)
    local expandedMax = self.pseudoMax + Vector(margin, margin, margin)

    local aimVector = attacker.GetAimVector and attacker:GetAimVector() or dmginfo:GetDamageForce():GetNormalized()

    local hitPos, _, hit = util.IntersectRayWithOBB(
        damagePos - (aimVector * 128),
        aimVector * 256,
        self.pseudoPos,
        self.pseudoAng,
        expandedMin,
        expandedMax
    )

    if not hit then
        Reforger.DevLog("[FakeCollision] Missed pseudo-hitbox")
        return 0
    end

    if not isTraced and self.VehicleBase.reforgerType == "armored" then
        local eyeDir = (self.Player:EyePos() - self.pseudoPos):GetNormalized()
        local eyePos = self.pseudoPos + eyeDir * 35
        local center = (eyePos + self.pseudoPos) * 0.5
        local trace = util.TraceLine({ start = center, endpos = hitPos, filter = self:GetTraceFilter() })
        if trace.Hit and trace.Entity ~= self.Vehicle then
            Reforger.DevLog("[FakeCollision] Blocked damage: no visibility to hit pos")
            return 0
        end
    end

    if damage <= 0 then return end
    if inflictor == NULL then inflictor = game.GetWorld() end

    local plyZ = self.Player:GetPos().z + self.Player:OBBMins().z
    if hitPos.z < plyZ then return end

    local isHeadshot = hitPos.z >= self.headZone - 4 and hitPos.z <= self.headZone + 6
    local finalDamage = isHeadshot and damage or damage * 0.4

    self.Player:SetLastHitGroup(isHeadshot and 0 or 2)
    Reforger.ApplyPlayerDamage(self.Player, finalDamage, attacker, inflictor, nil)

    local ed = EffectData()
    ed:SetOrigin(hitPos)
    ed:SetNormal((attacker:GetPos() - hitPos):GetNormalized())
    ed:SetScale(1.5)
    util.Effect("bloodspray", ed, true, true)
end
