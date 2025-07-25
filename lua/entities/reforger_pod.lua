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

local IsIgnoredDamageType = { -- reforger_pod uses this
    [DMG_GENERIC] = true,
    [DMG_BLAST] = true,
    [DMG_BLAST_SURFACE] = true,
    [DMG_BUCKSHOT] = true,
    [DMG_CLUB] = true,
    [DMG_SONIC] = true,
    [DMG_ACID] = true,
    [DMG_BURN] = true,
    [DMG_SLOWBURN] = true,
    [DMG_DROWN] = true,
    [DMG_PARALYZE] = true
}

local seqAdjustments = {
    sit_rollercoaster = { maxZ = 1.9, minZ = 0.1, offset = -2 },
    sit               = { maxZ = 1.9, minZ = 0.1, offset = -5 },
    sit_zen           = { maxZ = 1.9, minZ = 0.1, offset = -5 },
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
    
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON) -- solid to bullets
    self:SetCollisionBounds(Vector(-32, -32, 0), Vector(32, 32, 72))
    self:SetMoveType(MOVETYPE_NONE)
    
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
    local offset = self.Vehicle:GetForward() * (adjust and adjust.offset or 0)

    self.pseudoPos, self.pseudoAng = vehPos + offset, vehAng
    self.headZone = self.pseudoPos.z + (self.pseudoMax.z * 0.7225)

    local extraZ = 0

    if not self.headBoneID then
        local bone = self.Player:LookupBone("ValveBiped.Bip01_Head1")
        if bone then
            self.headBoneID = bone
            Reforger.DevLog(("[FakeCollision] Found head bone ID: %d for %s"):format(bone, self.Player:Nick()))
        end
    end

    if self.headBoneID then
        local headPos = self.Player:GetBonePosition(self.headBoneID)
        if headPos and headPos.z > self.pseudoPos.z + self.pseudoMax.z then
            local relativeHeadZ = headPos.z - self.pseudoPos.z
            self.pseudoMax.z = relativeHeadZ * 1.05
            self.headZone = self.pseudoPos.z + (self.pseudoMax.z * 0.7225)
            extraZ = (self.pseudoMax.z - self.pseudoMin.z) * 0.2 --margin for extent
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

    local podPos = self:GetPos()
    
    if podPos:DistToSqr(center) > 1 then self:SetPos(center) end
    
    extent:Add(Vector(12, 10, 15 + extraZ))

    if not self.lastExtent or self.lastExtent ~= extent then
        self.lastExtent = extent
        self:SetCollisionBounds(-extent, extent)
    end

    if Reforger.IsDeveloper() then
        debugoverlay.BoxAngles(self.pseudoPos, self.pseudoMin, self.pseudoMax, self.pseudoAng, 0.06, Color(255, 255, 255, 10))
        debugoverlay.Text(self.pseudoPos, "Seq ID: "..tostring(seqID).." Seq Name: "..seqName, 0.06)
    end

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
    local attackerPod = attacker.reforgerPod
    if IsValid(attackerPod) and attackerPod.VehicleBase == self.VehicleBase then
        return 
    end
    
    if not IsValid(self.Player) or not IsValid(self.VehicleBase) or not IsValid(attacker) or attacker == self.Player then return end

    local D = Reforger.Damage
    local damage = dmginfo:GetDamage()

    if damage < 1 then return end

    local inflictor = dmginfo:GetInflictor()
    local damagePos = dmginfo:GetDamagePosition()
    local dmgType = dmginfo:GetDamageType()
    local isTraced = dmginfo:GetDamageCustom() == 1
    local vehBase = self.VehicleBase.reforgerBase

    local isReforgerType = Reforger.IsValidReforger(inflictor)
    if not isReforgerType and IsIgnoredDamageType[dmgType] or D.IsFireDamageType(self.VehicleBase, dmgType) then
        D.ApplyPlayerDamage(self.Player, damage, attacker, inflictor, nil)
        return
    end

    if vehBase == Reforger.VehicleBases.Simfphys and GetConVar("sv_simfphys_playerdamage"):GetInt() <= 0 then return end

    local margin = 1.5

    local expandedMin = self.pseudoMin - Vector(margin, margin, margin)
    local expandedMax = self.pseudoMax + Vector(margin, margin, margin)

    local aimVector = Vector(0, 0, 0)

    if attacker.GetAimVector then
        local vec = attacker:GetAimVector()
        if isvector(vec) then
            aimVector = vec
        end
    end

    if not isvector(aimVector) or aimVector:IsZero() then
        local force = dmginfo:GetDamageForce()
        if force:IsZero() then return end
        aimVector = force:GetNormalized()
    end

    local hitPos, _, hit = util.IntersectRayWithOBB(
        damagePos - (aimVector * 128),
        aimVector * 256,
        self.pseudoPos,
        self.pseudoAng,
        expandedMin,
        expandedMax
    )

    if not hit then
        return 0
    end

    if not isTraced and self.VehicleBase.reforgerType == "armored" then
        local eyeDir = (self.Player:EyePos() - self.pseudoPos):GetNormalized()
        local eyePos = self.pseudoPos + eyeDir * 35
        local center = (eyePos + self.pseudoPos) * 0.5
        local trace = util.TraceLine({ start = center, endpos = hitPos, filter = self:GetTraceFilter() })
        if trace.Hit and trace.Entity ~= self.Vehicle then
            return 0
        end
    end

    if isTraced and self.VehicleBase.reforgerType == "armored" then
        damage = 0.35 * damage
    end

    if damage <= 0 then return end
    if inflictor == NULL then inflictor = game.GetWorld() end

    local plyZ = self.Player:GetPos().z + self.Player:OBBMins().z
    if hitPos.z < plyZ then return end

    local isHeadshot = hitPos.z >= self.headZone - 2 and hitPos.z <= self.headZone + 8
    local finalDamage = isHeadshot and damage or isTraced and damage * 0.4 or damage * 0.85

    self.Player:SetLastHitGroup(isHeadshot and 0 or 2)
    D.ApplyPlayerDamage(self.Player, finalDamage, attacker, inflictor, nil)

    local effectName, shouldEffect = hook.Run("Reforger.PodBloodEffect", attacker, hitPos, damage)

    if shouldEffect ~= false then 
        local ed = EffectData()
        ed:SetOrigin(hitPos)
        ed:SetNormal(IsValid(attacker) and (attacker:GetPos() - hitPos):GetNormalized() or Vector(0, 0, -1))
        ed:SetScale(damage * 0.05)
        util.Effect(type(effectName) == "string" and effectName or "BloodImpact", ed, true, true)
    end
end