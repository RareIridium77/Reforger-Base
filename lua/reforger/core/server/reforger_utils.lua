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
    ["glide_gib"] = true
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

concommand.Add("reforger_dump_nwvars", function(ply, cmd, args)
    if not IsValid(ply) then return end

    local tr = ply:GetEyeTrace()
    if not IsValid(tr.Entity) then
        ply:ChatPrint("Смотрим не на сущность.")
        return
    end

    local ent = tr.Entity
    print("[NWVars DUMP] Сущность: " .. tostring(ent))

    local keys = ent:GetNetworkVars()
    if not keys then
        print("NW таблица не найдена. Возможно серверная часть ограничена.")
        return
    end

    PrintTable(keys)
end)

concommand.Add("reforger_destroy", function(ply)
    if not IsValid(ply) then return end

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