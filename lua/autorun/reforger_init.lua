if CLIENT then return end

Reforger = Reforger or {}
Reforger.VERSION = "0.2.3"

include("reforger/core/logger.lua")
include("reforger/core/entityhooks.lua")
include("reforger/core/util.lua")
include("reforger/reforger_scanners.lua")
include("reforger/reforger_damage.lua")

local function EntityCreated(ent)
    timer.Simple(0, function()
        if not IsValid(ent) then return end
        if Reforger.IsValidReforger(ent) then
            Reforger.CallEntityFunctions(ent)
        end
    end)
end

hook.Add("OnEntityCreated", "Reforger.EntityHook", EntityCreated)

hook.Add("InitPostEntity", "Reforger.InitPostEntity", function()
    timer.Simple(5, function()
        hook.Run("Reforger.Init")
        Reforger.DevLog("Reforger version: "..Reforger.VERSION)
    end)
end)

-- Concommands

local function AdminDevToolValidation(ply)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then Reforger.Log("You are not admin.") end
    if GetConVar("developer"):GetInt() <= 0 then Reforger.Log("Developer mode disabled.") end
end

concommand.Add("reforger_init", function(ply)
    AdminDevToolValidation(ply)
    hook.Run("Reforger.Init")
    Reforger.DevLog("Manual reforger_init called")
end)
