--[[-------------------------------------------------------------------------
    [Reforger] Base (Framework)

    Unified system for advanced vehicle logic and damage simulation.
    Supports LVS / Simfphys / Gmod Glide. Open-source.

    Created by RareIridium77
    https://github.com/RareIridium77

-------------------------------------------------------------------------]]

--// REVIEW Fuck this all shit in this file needs to be refactored.

Reforger = Reforger or {}

Reforger.VehicleTypes = {
    LIGHT = "light",
    ARMORED = "armored",
    PLANE = "plane",
    HELICOPTER = "helicopter",
    UNDEFINED = "undefined"
}

Reforger.VehicleBases = {
    Glide = "glide",
    LVS = "lvs",
    Simfphys = "simfphys"
}

Reforger.ValidClasslist = {
    ["gmod_sent_vehicle_fphysics_gib"] = true,
    ["gmod_sent_vehicle_fphysics_base"] = true,
    ["simfphys_tankprojectile"] = true,
    ["glide_gib"] = true,
}

function Reforger.GetVehicleType(ent)
    local netType = Reforger.GetNetworkValue(ent, "String", "VehicleType", nil)
    
    if netType then return netType end

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

    elseif vehicle_base == "lvs" and ent.GetVehicleType then
        local vt = ent:GetVehicleType()

        local hasArmor = ent._armorParts and #ent._armorParts >= 2

        if hasArmor then -- tank or not. hasArmor - means its armored
            vehicle_type = types.ARMORED
        else
            vehicle_type = types.LIGHT
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

    Reforger.SetNetworkValue(ent, "String", "VehicleType", vehicle_type)

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

    local uav = ent:GetNWEntity("UAV")

    if (IsValid(uav) and uav.LVSUAV == true) or ent.LVSUAV == true then return false end
    if ent.IsReforgerEntity then return true end
    if ent.IsRocket then return true end
    if ent.LVS or ent.IsGlideVehicle or ent.lvsProjectile then return true end
    if Reforger.ValidClasslist and Reforger.ValidClasslist[class] then return true end
    return false
end

function Reforger.SafeEntity(ent)
    return IsValid(ent) and ent or game.GetWorld()
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

function Reforger.DoInDev(func)
    if not Reforger.IsDeveloper() then return end
    if not isfunction(func) then return end

    local success, err = pcall(func)
    if not success then
        Reforger.ErrorLog("Error in Dev function: " .. tostring(err))
    end
end