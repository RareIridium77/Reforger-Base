--[[-------------------------------------------------------------------------
    [Reforger] Base (Framework)

    Unified system for advanced vehicle logic and damage simulation.
    Supports LVS / Simfphys / Gmod Glide. Open-source.

    Created by RareIridium77
    https://github.com/RareIridium77

-------------------------------------------------------------------------]]

-- // TODO Refactor all this shit

Reforger = Reforger or {}

function Reforger.GetVehicleBase(ent)
    if not Reforger.IsValidReforger(ent) then return end
    if ent.reforgerBase ~= nil then return ent.reforgerBase end

    if ent.LVS then return "lvs" end
    if ent.IsGlideVehicle then return "glide" end
    if ent.IsSimfphysVehicle or ent:GetClass() == "gmod_sent_vehicle_fphysics_base" then return "simfphys" end
end

function Reforger.GetVehicleType(ent)
    local types = Reforger.VehicleTypes

    if not Reforger.IsValidReforger(ent) then return types.UNDEFINED end
    if ent.reforgerType ~= nil then return ent.reforgerType end

    local vehicle_base = Reforger.GetVehicleBase(ent)
    local vehicle_type = types.UNDEFINED

    if vehicle_base == "glide" then
        local vt = ent.VehicleType
        local gvht = Glide.VEHICLE_TYPE

        if vt == gvht.CAR or vt == gvht.MOTORCYCLE or vt == gvht.BOAT then
            vehicle_type = types.LIGHT
        elseif vt == gvht.PLANE then
            vehicle_type = types.PLANE
        elseif vt == gvht.HELICOPTER then
            vehicle_type = types.HELICOPTER
        elseif vt == gvht.TANK then
            vehicle_type = types.ARMORED
        end

    elseif vehicle_base == "lvs" and ent.GetVehicleType then
        local vt = ent:GetVehicleType()
        local hasArmor = ent._armorParts and #ent._armorParts >= 2

        if vt == "plane" then
            vehicle_type = types.PLANE
        elseif vt == "helicopter" then
            vehicle_type = types.HELICOPTER
        elseif hasArmor then
            vehicle_type = types.ARMORED
        else
            vehicle_type = types.LIGHT
        end

    elseif vehicle_base == "simfphys" then
        vehicle_type = ent.IsArmored and types.ARMORED or types.LIGHT
    end

    return vehicle_type
end

function Reforger.GetHealth(ent)
    if not Reforger.IsValidReforger(ent) then return -1 end
    
    local veh_base = Reforger.GetVehicleBase(ent)

    if veh_base == "lvs" and ent.GetHP then
        return ent:GetHP()
    elseif veh_base == "glide" and ent.GetChassisHealth then
        return ent:GetChassisHealth()
    elseif veh_base == "simfphys" and ent.GetCurHealth then
        return ent:GetCurHealth()
    end

    return ent.Health and ent:Health() or -1
end
