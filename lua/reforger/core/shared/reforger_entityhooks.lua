--[[-------------------------------------------------------------------------
    [Reforger] Base (Framework)

    Unified system for advanced vehicle logic and damage simulation.
    Supports LVS / Simfphys / Gmod Glide. Open-source.

    Created by RareIridium77
    https://github.com/RareIridium77

-------------------------------------------------------------------------]]

Reforger = Reforger or {}
Reforger.EntityHooks = Reforger.EntityHooks or {}

function Reforger:AddEntityModule(idf, func)
    if not isstring(idf) or not isfunction(func) then return end
    self.EntityHooks[idf] = func
end

function Reforger:InitializeEntity(ent)
    if not self.IsValidReforger(ent) then return end
    if not istable(self.EntityHooks) then return end

    timer.Simple(0.15, function() -- // NOTE LVS have delayed initialization for armor parts and other things some reason
        if SERVER then
            ent.reforgerType = self.GetVehicleType(ent)
            ent.reforgerBase = self.GetVehicleBase(ent)

            self.Armored._internal:CacheAmmorack(ent)
            self.Engines._internal:CacheEngine(ent)
            self.Rotors._internal:CacheRotors(ent)
        end
    end)

    for idf, func in pairs(self.EntityHooks) do
        if isfunction(func) then
            local success, err = pcall(func, ent)
            if not success then
                self.DevLog("Error in EntityHook ["..idf.."]: "..tostring(err))
            end
        end
    end

    hook.Run("Reforger.EntityInitialized", ent)
end