--[[-------------------------------------------------------------------------
    [Reforger] Base (Framework)

    Unified system for advanced vehicle logic and damage simulation.
    Supports LVS / Simfphys / Gmod Glide. Open-source.

    Created by RareIridium77
    https://github.com/RareIridium77

-------------------------------------------------------------------------]]

Reforger = Reforger or {}

function Reforger.SafeEntity(ent)
    return IsValid(ent) and ent or game.GetWorld()
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

function Reforger.DoInDev(func)
    if not Reforger.IsDeveloper() then return end
    if not isfunction(func) then return end

    local success, err = pcall(func)
    if not success then
        Reforger.ErrorLog("Error in Dev function: " .. tostring(err))
    end
end