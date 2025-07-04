if CLIENT then return end -- Im overthinker sorry

Reforger = Reforger or {}
Reforger.EntityHooks = {}

Reforger.VERSION = "0.2.3"

local dev_cvar = GetConVar("developer")

function Reforger.DevLog(...)
    if not dev_cvar or dev_cvar:GetInt() <= 0 then return end
    
    MsgC(
        Color(128, 104, 236), "[Reforger] ",
        Color(100, 178, 241), ..., "\n"
    )
end

function Reforger.AddEntityFunction(idf, func)
    if not isstring(idf) or not isfunction(func) then return end

    if Reforger.EntityHooks[idf] then
        Reforger.DevLog("Overriding entity hook with ID: " .. idf)
    end

    Reforger.EntityHooks[idf] = func
end

local function IsValidReforger(ent)
    if not IsValid(ent) then return false end

    return ent.LVS or ent.IsGlideVehicle or ent:GetClass() == "gmod_sent_vehicle_fphysics_base" or ent:GetClass() == "simfphys_tankprojectile"
end

local function Reforger_CallEntityFunctions(ent)
    if not IsValidReforger(ent) then return end
    if not istable(Reforger.EntityHooks) then return end

    for idf, func in pairs(Reforger.EntityHooks) do
        Reforger.DevLog("Tring to call '"..idf.."' from Entity Hooks")
        if isfunction(func) then
            local success, err = pcall(func, ent)
            if not success then
                Reforger.DevLog("Error in EntityHook [" .. idf .. "]: " .. tostring(err))
            end
        end
    end
end

local function Sex(ent)
    timer.Simple(0, function()
        if not IsValid(ent) then return end
        Reforger_CallEntityFunctions(ent)
    end)
end

include("reforger/reforger_scanners.lua")
include("reforger/reforger_damage.lua")

hook.Add("OnEntityCreated", "Reforger.Hook.EntityFunctions", Sex)
hook.Add("InitPostEntity", "Reforger.Hook.InitPostEntity", function()
    timer.Simple(5, function()
        hook.Run("Reforger.Init")
        
        Reforger.DevLog("Reforger current version: " .. Reforger.VERSION)
    end)
end)

concommand.Add("reforger_init", function()
    hook.Run("Reforger.Init")
end)