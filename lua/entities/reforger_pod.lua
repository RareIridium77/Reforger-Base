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
ENT.CallDamageHook = false

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

local COLLISION_UPDATE_INTERVAL   = 0.025 -- per 25ms update hitbox
local HEAD_ZONE_RATIO             = 0.7225 -- relative head position in hitbox
local COLLISION_MARGIN            = 1.5    -- expand OBB
local EYE_OFFSET                  = 35     -- eye offset from center

-- Damage multipliers
local DAMAGE_REDUCTION_ARMORED    = 0.35
local DAMAGE_REDUCTION_NONTRACE   = 0.85
local DAMAGE_REDUCTION_NONTRACE_ARMOR_BLOCK = 0.40 -- no trace, but armored

-- Extents / bounds
local DEFAULT_MAXZ_MULTIPLIER     = 1.9
local DEFAULT_MINZ_MULTIPLIER     = 0.1
local EXTENT_SCALE                = 0.85
local EXTENT_MARGIN               = Vector(17, 17, 20) -- add extent

-- Headshot zone
local HEADSHOT_ZONE_BOTTOM_OFFSET = 2
local HEADSHOT_ZONE_TOP_OFFSET    = 11
local HEAD_BONE_HEIGHT_MULT       = 1.05
local HEAD_EXTRA_MARGIN_RATIO     = 0.2

-- Eye calc
local EYE_DIR_DISTANCE            = 35
local EYE_CENTER_BLEND            = 0.5

-- Trace
local TRACE_LENGTH                = 256
local TRACE_BACK_OFFSET           = 5

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
    self.headZone = self.pseudoPos.z + (self.pseudoMax.z * HEAD_ZONE_RATIO)

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
            self.pseudoMax.z = relativeHeadZ * HEAD_BONE_HEIGHT_MULT
            self.headZone = self.pseudoPos.z + (self.pseudoMax.z * HEAD_ZONE_RATIO)
            extraZ = (self.pseudoMax.z - self.pseudoMin.z) * HEAD_EXTRA_MARGIN_RATIO --margin for extent
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
            newMax.z, newMin.z = newMax.z * DEFAULT_MAXZ_MULTIPLIER, newMax.z * DEFAULT_MINZ_MULTIPLIER
        end

        self.pseudoMin, self.pseudoMax = newMin * EXTENT_SCALE, newMax * EXTENT_SCALE
        self.headZone = self.pseudoPos.z + (self.pseudoMax.z * HEAD_ZONE_RATIO)
        Reforger.DevLog(('[FakeCollision] Updated pseudo-bounds for %s (%d)'):format(seqName, seqID))
    end

    local eyeDir = (self.Player:EyePos() - self.pseudoPos):GetNormalized()
    local eyePos = self.pseudoPos + eyeDir * EYE_OFFSET
    local center = (eyePos + self.pseudoPos) * 0.5
    local extent = Vector(
        math.abs(eyePos.x - self.pseudoPos.x),
        math.abs(eyePos.y - self.pseudoPos.y),
        math.abs(eyePos.z - self.pseudoPos.z)
    ) * 0.5

    local podPos = self:GetPos()
    
    if podPos:DistToSqr(center) > 1 then self:SetPos(center) end
    
    extent:Add(EXTENT_MARGIN + Vector(0, 0, extraZ))

    if not self.lastExtent or self.lastExtent ~= extent then
        self.lastExtent = extent
        self:SetCollisionBounds(-extent, extent)
    end

    if Reforger.IsDeveloper() then
        debugoverlay.BoxAngles(self.pseudoPos, self.pseudoMin, self.pseudoMax, self.pseudoAng, 0.06, Color(255, 255, 255, 10))
        debugoverlay.Text(self.pseudoPos, "Seq ID: "..tostring(seqID).." Seq Name: "..seqName, 0.06)
        debugoverlay.BoxAngles(self:GetPos(), -extent, extent, self:GetAngles(), 0.06, Color(255, 255, 255, 10))
    end

    self:NextThink(CurTime() + COLLISION_UPDATE_INTERVAL)
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
    if not isvector(self.pseudoPos) or not isangle(self.pseudoAng) then return end

    local attacker = dmginfo:GetAttacker()
    local attackerPod = attacker.reforgerPod
    if IsValid(attackerPod) and attackerPod.VehicleBase == self.VehicleBase then
        return
    end
    
    if not IsValid(self.Player) or not IsValid(self.VehicleBase) or not IsValid(attacker) or attacker == self.Player then return end

    local RDamage = Reforger.Damage
    local damage = dmginfo:GetDamage()

    if damage < 1 then return end

    local inflictor = dmginfo:GetInflictor()
    local damagePos = dmginfo:GetDamagePosition()
    local dmgType = dmginfo:GetDamageType()
    local isTraced = dmginfo:GetDamageBonus() == RDamage.Type.TRACED -- Upd: New Reforger Damage Type sending format
    local vehBase = self.VehicleBase.reforgerBase

    local isReforgerType = Reforger.IsValidReforger(inflictor)
    if not isReforgerType and IsIgnoredDamageType[dmgType] or RDamage.IsFireDamageType(self.VehicleBase, dmgType) then
        RDamage.ApplyPlayerDamage(self.Player, damage, attacker, inflictor, nil)
        return
    end

    if vehBase == Reforger.VehicleBases.Simfphys and GetConVar("sv_simfphys_playerdamage"):GetInt() <= 0 then return end

    local margin = COLLISION_MARGIN

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
    local start = damagePos - (aimVector * TRACE_BACK_OFFSET)
    local hitPos, _, hit = util.IntersectRayWithOBB(
        start,
        aimVector * TRACE_LENGTH,
        self.pseudoPos,
        self.pseudoAng,
        expandedMin,
        expandedMax
    )

    if not hit then
        return
    end

    if not isTraced and self.VehicleBase.reforgerType == "armored" then
        Reforger.DevLog("Damage is trace? ", isTraced, " Damage type: ", dmginfo:GetDamageBonus())
        
        local eyeDir = (self.Player:EyePos() - self.pseudoPos):GetNormalized()
        local eyePos = self.pseudoPos + eyeDir * 35
        local center = (eyePos + self.pseudoPos) * 0.5
        local trace = util.TraceLine({ start = center, endpos = hitPos, filter = self:GetTraceFilter() })
        if trace.Hit and trace.Entity ~= self.Vehicle then
            return
        end
    end

    if isTraced and self.VehicleBase.reforgerType == "armored" then
        damage = DAMAGE_REDUCTION_ARMORED * damage
    end

    if damage <= 0 then return end
    if inflictor == NULL then inflictor = game.GetWorld() end

    local plyZ = self.Player:GetPos().z + self.Player:OBBMins().z
    if hitPos.z < plyZ then return end

    local headBottom = self.headZone + HEADSHOT_ZONE_BOTTOM_OFFSET
    local headTop = self.headZone + HEADSHOT_ZONE_TOP_OFFSET

    local isHeadshot = hitPos.z >= headBottom and hitPos.z <= headTop
    local finalDamage = isHeadshot and damage or isTraced and damage * DAMAGE_REDUCTION_NONTRACE_ARMOR_BLOCK or damage * DAMAGE_REDUCTION_NONTRACE

    if isHeadshot then
        Reforger.DoInDev(function()
            debugoverlay.Sphere(Vector(hitPos.x, hitPos.y, headBottom), 1, 1, Color(0, 255, 0), true)
            debugoverlay.Sphere(Vector(hitPos.x, hitPos.y, headTop), 1, 1, Color(255, 0, 0), true)
            debugoverlay.Line(Vector(hitPos.x, hitPos.y, headBottom), Vector(hitPos.x, hitPos.y, headTop), 1, Color(0, 255, 255), true)
        end)
    end

    self.Player:SetLastHitGroup(isHeadshot and HITGROUP_HEAD or HITGROUP_CHEST)

    RDamage.ApplyPlayerDamage(self.Player, finalDamage, attacker, inflictor, nil)

    local effectName, shouldEffect = hook.Run("Reforger.PodBloodEffect", attacker, hitPos, damage)

    if shouldEffect ~= false then 
        local ed = EffectData()
        ed:SetOrigin(hitPos)
        ed:SetNormal(IsValid(attacker) and (attacker:GetPos() - hitPos):GetNormalized() or Vector(0, 0, -1))
        ed:SetScale(damage * 0.05)
        util.Effect(type(effectName) == "string" and effectName or "BloodImpact", ed, true, true)
    end
end