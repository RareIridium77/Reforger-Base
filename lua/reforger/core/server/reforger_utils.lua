--[[-------------------------------------------------------------------------
    Reforger Base Framework
    Created by: RareIridium77
    Version: 0.2.3

    GitHub: https://github.com/RareIridium77/
    Steam: https://steamcommunity.com/profiles/76561199078206115/

    Description:
    This is the core "framework" used by addons under the [Reforger] tag.
    It provides a unified damage, logic and compatibility layer between vehicle bases:
      - LVS
      - Simfphys
      - GMod Glide

    License:
    This "framework" is open-source. You are free to use, modify and redistribute it
    in your GMod projects. Attribution is appreciated but not required.

    Recommended tag: [Reforger]

    Notes:
    This script is core infrastructure. Any modification should be done with understanding
    of system-wide effects.

-------------------------------------------------------------------------]]

Reforger.VehicleTypes = {
    LIGHT = "light",
    ARMORED = "armored",
    PLANE = "plane",
    HELICOPTER = "helicopter",
    UNDEFINED = "undefined"
}

Reforger.ValidClasslist = {
    ["gmod_sent_vehicle_fphysics_gib"] = true,
    ["gmod_sent_vehicle_fphysics_base"] = true,
    ["simfphys_tankprojectile"] = true,
    ["glide_gib"] = true,
    ["prop_vehicle_prisoner_pod"] = true
}

function Reforger.GetVehicleType(ent)
    if not Reforger.IsValidReforger(ent) then
        return Reforger.VehicleTypes.UNDEFINED
    end

    if ent.reforgerType ~= nil then
        return ent.reforgerType
    end

    local types = Reforger.VehicleTypes
    local vehicle_base = Reforger.GetVehicleBase(ent)
    local vehicle_type = types.UNDEFINED

    if vehicle_base == "glide" then
        local vt = ent.VehicleType
        local gvht = Glide.VEHICLE_TYPE

        if vt == gvht.CAR or vt == gvht.MOTORCYCLE or vt == gvht.BOAT then
            vehicle_type = types.LIGHT
        end

        if vt == gvht.PLANE then vehicle_type = types.PLANE end
        if vt == gvht.HELICOPTER then vehicle_type = types.HELICOPTER end
        if vt == gvht.TANK then vehicle_type = types.ARMORED end

    elseif vehicle_base == "lvs" then
        local vt = ent:GetVehicleType()

        local has_armor = ent._armorParts and #ent._armorParts > 0

        if vt == "tank" or has_armor then
            vehicle_type = types.ARMORED
        else
            vehicle_type = types.LIGHT

            local armor_parts = ent._armorParts
            if istable(armor_parts) and next(armor_parts) ~= nil then
                vehicle_type = types.ARMORED
            end
        end

        if vt == "plane" then vehicle_type = types.PLANE end
        if vt == "helicopter" then vehicle_type = types.HELICOPTER end

    elseif vehicle_base == "simfphys" then
        if ent.IsArmored then
            vehicle_type = types.ARMORED
        else
            vehicle_type = types.LIGHT
        end
    end

    Reforger.DevLog("Vehicle Type: "..vehicle_type)

    return vehicle_type
end

function Reforger.GetVehicleBase(ent)
    if not Reforger.IsValidReforger(ent) then return end

    if ent.reforgerBase ~= nil then
        return ent.reforgerBase
    end

    local base = nil

    if ent.LVS then base = "lvs" end
    if ent.IsGlideVehicle then base = "glide" end
    if ent.IsSimfphysVehicle or ent:GetClass() == "gmod_sent_vehicle_fphysics_base" then base = "simfphys" end

    return base
end

function Reforger.IsValidReforger(ent)
    if not IsValid(ent) then return false end

    local class = ent:GetClass()

    if ent.IsReforgerEntity then return true end
    if ent.LVS or ent.IsGlideVehicle then return true end
    if Reforger.ValidClasslist and Reforger.ValidClasslist[class] then return true end
    return false
end


function Reforger.GetHealth(ent)
    if not Reforger.IsValidReforger() then return -1 end
    
    local veh_base = Reforger.GetVehicleBase()

    if veh_base == "lvs" and ent.GetHP then
        return ent:GetHP()
    elseif veh_base == "glide" and ent.GetChassisHealth then
        return ent:GetChassisHealth()
    elseif veh_base == "simfphys" and ent.GetCurHealth then
        return ent:GetCurHealth()
    end

    return ent.Health and ent:Health() or -1
end

concommand.Add("reforger.destroy", function(ply)
    if not Reforger.AdminDevToolValidation(ply) then return end

    local tr = ply:GetEyeTrace()
    if not IsValid(tr.Entity) then
        ply:ChatPrint("Смотрим не на сущность.")
        return
    end

    local ent = tr.Entity
    if not IsValid(ent) then
        return 
    end

    if ent.Destroy then ent:Destroy() end
    if ent.Explode then ent:Explode() end
    if ent.ExplodeVehicle then ent:ExplodeVehicle() end
end)