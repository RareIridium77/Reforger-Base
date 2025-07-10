if not Reforger then return end -- overthinker moment

Reforger.Log("Reforger Tanks Loaded")

local VehBase = Reforger.VehicleBases
local VehType = Reforger.VehicleTypes

function Reforger.CacheAmmorack(veh)

    if veh.reforgerBase ~= VehBase.LVS then return end
    if veh.reforgerType ~= VehType.ARMORED then
        veh.reforgerAmmoracks = {}
        return
    end

    timer.Simple(0, function()
        if IsValid(veh.reforgerAmmoracks) then return end
        
        local ammorack_ents = Reforger.PairEntityAll(veh, "lvs_wheeldrive_ammorack")

        if not istable(ammorack_ents) then return end

        if veh.reforgerAmmoracks == nil then
            veh.reforgerAmmoracks = ammorack_ents
        end
    end)
end

function Reforger.AmmoracksTakeTransmittedDamage(veh, dmginfo)
    if not IsValid(veh) then return end

    if dmginfo:GetDamage() <= 0 then return end

    if istable(veh.reforgerAmmoracks) then
        for _, ammorack in ipairs(veh.reforgerAmmoracks) do
            if IsValid(ammorack) and ammorack.TakeTransmittedDamage and not ammorack:GetDestroyed() then
                ammorack:TakeTransmittedDamage(dmginfo)
                Reforger.DevLog(ammorack, " got damage ", dmginfo:GetDamage())
            end
        end
    end
end

function Reforger.GetAmmoracks(veh)
    if not IsValid(veh) then return end
    return veh.reforgerAmmoracks or {}
end

function Reforger.IsAmmorackDestroyed(veh)
    if not IsValid(veh) or not istable(veh.reforgerAmmoracks) then return false end

    for _, ammorack in ipairs(veh.reforgerAmmoracks) do
        if not IsValid(ammorack) then continue end

        local hp = isfunction(ammorack.GetHP) and ammorack:GetHP() or 100
        if hp <= 0 then return true end

        if isfunction(ammorack.GetDestroyed) and ammorack:GetDestroyed() then
            return true
        end
    end

    return false
end

function Reforger.DamageDamagableParts(veh, damage)
    if not IsValid(veh) then return end

    if isnumber(damage) and damage <= 0 then return end

    local newDamage = isnumber(damage) and damage or 10

    if istable(veh._dmgParts) and #veh._dmgParts > 0 then
        for _, part in ipairs(veh._dmgParts) do
            if not IsValid(part) or not part.GetHP or not part.GetMaxHP then continue end

            local curHP = part:GetHP()
            local maxHP = part:GetMaxHP()
            local newHP = math.Clamp(curHP - damage, -maxHP, maxHP)

            if part.SetHP then
                Reforger.DevLog("Parts getting damage: ", damage)
                part:SetHP(newHP) end
        end
    end
end

concommand.Add("reforger.check.ammorack", function(ply, cmd, args)
    if not Reforger.AdminDevToolValidation(ply) then return end

    local tr = ply:GetEyeTrace()
    local ent = tr.Entity

    if not IsValid(ent) then
        ply:ChatPrint("Look at vehicle.")
        return
    end

    local ammoracks = Reforger.GetAmmoracks(ent)
    if #ammoracks == 0 then
        ply:ChatPrint("reforger.check.ammorack: Ammoracks not found.")
        return
    end

    for _, ammorack in ipairs(ammoracks) do
        local info = string.format("[%s] HP: %s", tostring(ammorack), isfunction(ammorack.GetHP) and ammorack:GetHP() or "???")
        ply:ChatPrint(info)
    end
end)