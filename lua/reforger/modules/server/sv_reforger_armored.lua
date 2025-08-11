local Armored = {}
Armored._internal = {}

Reforger.Log("Reforger Armored Loaded")

local VehBase = Reforger.VehicleBases
local VehType = Reforger.VehicleTypes

function Armored.DamageAmmoracks(veh, dmginfo)
    if not IsValid(veh) then return end

    if dmginfo:GetDamage() <= 0 then return end

    if istable(veh.reforgerAmmoracks) then
        for _, ammorack in ipairs(veh.reforgerAmmoracks) do
            if IsValid(ammorack) and ammorack.TakeTransmittedDamage and not ammorack:GetDestroyed() then
                ammorack:TakeTransmittedDamage(dmginfo)
            end
        end
    end
end

function Armored.GetAmmoracks(veh)
    if not IsValid(veh) then return end
    return veh.reforgerAmmoracks or {}
end

function Armored.IsAmmorackDestroyed(veh) --// REVIEW Find better ways to check ammorack status
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

function Armored._internal:CacheAmmorack(veh)
    if veh.reforgerBase ~= VehBase.LVS then return end
    if veh.reforgerType ~= VehType.ARMORED then
        veh.reforgerAmmoracks = {}
        return
    end

    timer.Simple(0, function()
        if IsValid(veh.reforgerAmmoracks) then return end
        
        local ammorack_ents = Reforger.Scanners.PairEntityAll(veh, "lvs_wheeldrive_ammorack")

        if not istable(ammorack_ents) then return end

        if veh.reforgerAmmoracks == nil then
            veh.reforgerAmmoracks = ammorack_ents
        end

        Reforger.DevLog("Ammoracks cached")
    end)
end

Reforger.Armored = Armored