if CLIENT then return end

Reforger.VehicleTypes = {
    LIGHT = "light",
    ARMORED = "armored",
    PLANE = "plane",
    HELICOPTER = "helicopter",
    UNDEFINED = "undefined"
}

function Reforger.GetVehicleType(ent)
    if not Reforger.IsValidReforger(ent) then
        return Reforger.VehicleTypes.UNDEFINED
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

        if vt == "tank" then
            vehicle_type = types.ARMORED
        end

        if vt == "car" then
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

    local base = nil

    if ent.LVS then base = "lvs" end
    if ent.IsGlideVehicle then base = "glide" end
    if ent:GetClass() == "gmod_sent_vehicle_fphysics_base" then base = "simfphys" end

    return base
end

function Reforger.IsValidReforger(ent)
    if not IsValid(ent) then return false end
    return ent.LVS or ent.IsGlideVehicle or ent:GetClass() == "gmod_sent_vehicle_fphysics_base" or ent:GetClass() == "simfphys_tankprojectile"
end
