--[[-------------------------------------------------------------------------
    [Reforger] Base v0.2.3 (Framework)

    Unified system for advanced vehicle logic and damage simulation.
    Supports LVS / Simfphys / Gmod Glide. Open-source.

    Created by RareIridium77
    https://github.com/RareIridium77

-------------------------------------------------------------------------]]

Reforger = Reforger or {}
Reforger.EntityHooks = Reforger.EntityHooks or {}

function Reforger.AddEntityFunction(idf, func)
    if not isstring(idf) or not isfunction(func) then return end
    if Reforger.EntityHooks[idf] then
        Reforger.DevLog("Overriding entity hook with ID: " .. idf)
    end
    Reforger.EntityHooks[idf] = func
end

function Reforger.CallEntityFunctions(ent)
    if not Reforger.IsValidReforger(ent) then return end
    if not istable(Reforger.EntityHooks) then return end

    timer.Simple(0, function()
        ent.reforgerType = Reforger.GetVehicleType(ent)
        ent.reforgerBase = Reforger.GetVehicleBase(ent)

        Reforger.CacheRotors(ent)
        Reforger.CacheAmmorack(ent)

        timer.Simple(0.5, function() -- because of net for glide
            Reforger.CacheEngine(ent) -- NOT FOR LVS (AGAIN)
        end)
    end)

    for idf, func in pairs(Reforger.EntityHooks) do
        if isfunction(func) then
            local success, err = pcall(func, ent)
            if not success then
                Reforger.DevLog("Error in EntityHook ["..idf.."]: "..tostring(err))
            end
        end
    end

    hook.Run("Reforger.EntityFunctionsCalled", ent)
end
