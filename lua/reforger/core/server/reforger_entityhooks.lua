-- Bru bru bru bru bru I'm so bored

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

        Reforger.CacheRotors(ent)
        Reforger.CacheEngine(ent) -- NOT FOR LVS (AGAIN)
        Reforger.CacheAmmorack(ent)
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
