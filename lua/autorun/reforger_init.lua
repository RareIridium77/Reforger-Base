Reforger = Reforger or {}

Reforger.VERSION = "0.2.3"

Reforger.CreatedConvars = Reforger.CreatedConvars or {}

if CLIENT then return end

-- Shared files
AddCSLuaFile("reforger/core/shared/reforger_convars.lua") -- send to client
include("reforger/core/shared/reforger_convars.lua")

-- Including core files
include("reforger/core/server/reforger_logger.lua")
include("reforger/core/server/reforger_utils.lua")
include("reforger/core/server/reforger_entityhooks.lua")

-- Including files
include("reforger/modules/server/reforger_scanners.lua")
include("reforger/modules/server/reforger_damage.lua")

-- Special scenario
include("reforger/modules/server/reforger_lvs_data.lua")
include("reforger/modules/server/reforger_rotors.lua")
include("reforger/modules/server/reforger_tanks.lua")
include("reforger/modules/server/reforger_pods.lua")

-- Hooks

local function InitPostEntity()
    timer.Simple(5, function()
        hook.Run("Reforger.Init")
        Reforger.DevLog("Reforger version: "..Reforger.VERSION)
    end)
end

local function EntityCreated(ent)
    timer.Simple(0, function()
        if not IsValid(ent) then return end
        if Reforger.IsValidReforger(ent) then
            Reforger.CallEntityFunctions(ent)
        end
    end)
end

hook.Add("InitPostEntity", "Reforger.InitPostEntity", InitPostEntity)
hook.Add("OnEntityCreated", "Reforger.EntityHook", EntityCreated)

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
