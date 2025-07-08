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

    hook.Run("Reforger.EntityFunctionsCalled", ent)

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
end
