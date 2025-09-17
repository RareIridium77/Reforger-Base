--[[-------------------------------------------------------------------------
    [Reforger] Base (Framework)

    Unified system for advanced vehicle logic and damage simulation.
    Supports LVS / Simfphys / Gmod Glide. Open-source.

    Created by RareIridium77
    https://github.com/RareIridium77

-------------------------------------------------------------------------]]

--[[
    Reforger Vehicle Utilities
    - Provides unified functions to detect vehicle base, type, and health
    - Functions:
        * GetVehicleBase(ent)
            - Returns vehicle base: "lvs", "glide", "simfphys" or nil
        * GetVehicleType(ent)
            - Resolves vehicle type (LIGHT, PLANE, HELICOPTER, ARMORED, UNDEFINED)
        * GetHealth(ent)
            - Returns vehicle health depending on its base
    - Internal:
        * _ResolveVehicleType(ent) → Handles logic for determining vehicle type
    - Safety:
        * All functions validate Reforger-compatible entities before resolving
]]

Reforger = Reforger or {}

function Reforger.GetVehicleBase(ent)
    if not Reforger.IsValidReforger(ent) then return end
    if ent.reforgerBase ~= nil then return ent.reforgerBase end

    if ent.LVS then return "lvs" end
    if ent.IsGlideVehicle then return "glide" end
    if ent.IsSimfphysVehicle or ent:GetClass() == "gmod_sent_vehicle_fphysics_base" then return "simfphys" end
end

local function _ResolveVehicleType(ent)
    local types = Reforger.VehicleTypes
    if not Reforger.IsValidReforger(ent) then return types.UNDEFINED end
    if ent.reforgerType ~= nil then return ent.reforgerType end

    local vehicle_base = Reforger.GetVehicleBase(ent)
    if not vehicle_base then return types.UNDEFINED end

    if vehicle_base == "glide" then
        local vt = ent.VehicleType
        local gvht = Glide.VEHICLE_TYPE
        if vt == gvht.CAR or vt == gvht.MOTORCYCLE or vt == gvht.BOAT then return types.LIGHT end
        if vt == gvht.PLANE then return types.PLANE end
        if vt == gvht.HELICOPTER then return types.HELICOPTER end
        if vt == gvht.TANK then return types.ARMORED end

    elseif vehicle_base == "lvs" and ent.GetVehicleType then
        local vt = ent:GetVehicleType()
        if vt == "plane" then return types.PLANE end
        if vt == "helicopter" then return types.HELICOPTER end
        if ent.reforgerArmorCount and ent.reforgerArmorCount >= 2 then return types.ARMORED end
        return types.LIGHT

    elseif vehicle_base == "simfphys" then
        return ent.IsArmored and types.ARMORED or types.LIGHT
    end

    return types.UNDEFINED
end

function Reforger.GetVehicleType(ent)
    return _ResolveVehicleType(ent)
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
