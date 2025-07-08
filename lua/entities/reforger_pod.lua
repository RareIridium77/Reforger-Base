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
    sit_rollercoaster = { maxZ = 1.9, minZ = 0.1, offset = -10 },
    sit               = { maxZ = 1.9, minZ = 0.1, offset = -5 },
    sit_zen           = { maxZ = 1.9, minZ = 0.1 },
    drive_pd          = { maxZ = 1.9, minZ = 0.1 },
    drive_airboat     = { maxZ = 1.9, minZ = 0.1, offset = 7 },
    drive_jeep        = { maxZ = 2.2, minZ = 0.1, offset = 7 },
    cwalk_revolver    = { maxZ = 2.75, minZ = 0.23 },
}

function ENT:InitReforgerEntity()
    if CLIENT then return end

    self.headZone = 0
    self.min = Vector(0, 0, 0)
    self.max = Vector(0, 0, 0)

    self.boundSet = false
    self.lastSeqID = -1

    self:SetNoDraw( true )
    self:SetTrigger( true )
    self:SetNotSolid( false )

    self:SetCollisionGroup( COLLISION_GROUP_PLAYER )
    self.seqAdjustments = seqAdjustments
end

function ENT:SetPlayer(ply)
    self.Player = ply
end

function ENT:SetVehicle(veh)
    if not IsValid(veh) then return end

    self.Vehicle = veh
    self:SetMoveParent(self.Vehicle)
end

function ENT:Think()
    if CLIENT then return end

    local veh = self.Vehicle
    local ply = self.Player

    if not IsValid(veh) or not IsValid(ply) or not ply:InVehicle() then
        self:Remove()
        return
    end

    local seqID = ply:GetSequence()
    local seqName = ply:GetSequenceName(seqID)
    local vehPos = veh:GetPos()

    local mins, maxs = ply:OBBMins(), ply:OBBMaxs()
    local vmins, vmaxs = veh:OBBMins(), veh:OBBMaxs()

    local newMin = Vector(vmins.x * 0.5, vmins.y * 0.5, vmins.z)
    local newMax = Vector(vmaxs.x * 0.5, vmaxs.y * 0.5, vmaxs.z)

    local offsetMultiplier = 2

    local adjust = self.seqAdjustments[seqName]
    if adjust then
        newMax.z = newMax.z * adjust.maxZ
        newMin.z = newMax.z * adjust.minZ
        offsetMultiplier = adjust.offset or offsetMultiplier
    else
        newMax.z = newMax.z * 1.9
        newMin.z = newMax.z * 0.1
    end

    local offset = veh:GetForward() * offsetMultiplier
    local newPos = vehPos + offset

    self:SetPos(newPos)
    self:SetAngles(veh:GetAngles())

   self.headZone = vehPos.z + (newMax.z * 0.7225)

    local scaledMin = newMin * 0.85
    local scaledMax = newMax * 0.85

    if not self.boundSet or self.lastSeqID ~= seqID then
        self.boundSet = true
        self.lastSeqID = seqID

        self.min = scaledMin
        self.max = scaledMax

        self:PhysicsInit(SOLID_BBOX)
        self:SetCollisionBounds(scaledMin, scaledMax)

        Reforger.DevLog(("[FakeCollision] Updated bounds for %s (%d)"):format(seqName, seqID))
    end

    debugoverlay.Text(vehPos + Vector(0, 0, newMax.z),
        ("max.z: %.2f seq: %s id: %d"):format(newMax.z, seqName, seqID), 0.02)

    debugoverlay.Text(vehPos + Vector(0, 0, newMin.z),
        ("min.z: %.2f"):format(newMin.z), 0.02)

    debugoverlay.Box(newPos, scaledMin, scaledMax, 0.045, Color(255, 255, 255, 20))

    self:NextThink(CurTime() + 0.0015)
    return true
end

function ENT:DoImpactEffect( tr, nDamageType )
    return true 
end

function ENT:OnTakeDamage(dmginfo)
    Reforger.DevLog("[FakeCollision] OnTakeDamage called | Damage: " .. tostring(dmginfo:GetDamage()))

    if not IsValid(self.Player) then
        Reforger.DevLog("[FakeCollision] Invalid Player entity")
        return
    end

    if not IsValid(self.VehicleBase) then
        Reforger.DevLog("[FakeCollision] Invalid VehicleBase")
        return
    end

    if attacker == self.Player then
        Reforger.DevLog("[FakeCollision] Ignored self-damage")
        return
    end

    local damage        = dmginfo:GetDamage()
    local damageType    = dmginfo:GetDamageType()
    local damagePos     = dmginfo:GetDamagePosition()
    local damageCType   = dmginfo:GetDamageCustom()
    local attacker      = dmginfo:GetAttacker()
    local inflictor     = dmginfo:GetInflictor()
    local isSmallDamage = bit.band(damageType, DMG_BULLET + DMG_BUCKSHOT + DMG_CLUB) ~= 0
    local isTraced      = damageCType == 1

    debugoverlay.Sphere(damagePos, 4, 0.5, Color(170, 255, 100, 140), true)

    if not isTraced then
        local headCheckPos = self:GetPos()
        headCheckPos.z = self.headZone

        local trace = util.TraceLine({
            start = headCheckPos,
            endpos = damagePos,
            filter = {self, self.Player}
        })

        debugoverlay.Line(headCheckPos, damagePos, 1, Color(255, 0, 0), true)
        if trace.Hit and trace.Entity ~= self.Vehicle then
            Reforger.DevLog("[FakeCollision] Blocked damage: no visibility to hit pos")
            return
        end
    end

    if damage <= 0 or attacker == self.Player then return end
    if inflictor == NULL then inflictor = game.GetWorld() end

    local plyPos = self.Player:GetPos()
    local obbMinsZ = plyPos.z + self.Player:OBBMins().z

    if damagePos.z < obbMinsZ then
        debugoverlay.Sphere(damagePos, 3, 0.5, Color(0, 0, 255), true)
        return
    end

    local isHeadshot = damagePos.z >= self.headZone - 4 and damagePos.z <= self.headZone + 6
    local finalDamage = isHeadshot and damage or damage * 0.4

    self.Player:SetLastHitGroup(isHeadshot and 0 or 2) -- 0 Head, 2 Chest
    Reforger.ApplyPlayerDamage(self.Player, finalDamage, attacker, inflictor, nil)

    local ed = EffectData()
    ed:SetOrigin(damagePos)
    ed:SetNormal((attacker:GetPos() - damagePos):GetNormalized()) -- направление
    ed:SetScale(1.5) -- сила
    ed:SetColor(BLOOD_COLOR_RED) -- 0 = красная
    util.Effect("BloodImpact", ed, true, true)


    Reforger.DevLog(("[FakeCollision] Final Damage: %.2f | Headshot: %s | PosZ: %.2f | HeadZone: %.2f")
    :format(finalDamage, tostring(isHeadshot), damagePos.z, self.headZone))

    debugoverlay.Line(damagePos, Vector(damagePos.x, damagePos.y, self.headZone), 0.5, isHeadshot and Color(255, 0, 0) or Color(100, 141, 255))
    debugoverlay.Sphere(damagePos, 2, 0.2, isHeadshot and Color(255, 0, 0) or Color(255, 100, 100), true)
end
