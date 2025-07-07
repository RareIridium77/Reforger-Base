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

-- LVS
include("reforger/modules/server/lvs/reforger_lvs_bulletsystem.lua")
include("reforger/modules/server/lvs/reforger_lvs_data.lua")

-- Glide
include("reforger/modules/server/glide/reforger_glide_fix_pod.lua") -- Pod Aim controlling fixer

-- Special scenario
include("reforger/modules/server/reforger_engines.lua")
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

local function GlobalThink()
    hook.Run("Reforger.GlobalThink", Reforger)
end

hook.Add("InitPostEntity", "Reforger.InitPostEntity", InitPostEntity)
hook.Add("OnEntityCreated", "Reforger.EntityHook", EntityCreated)
hook.Add("Think", "Reforger.GlobalThinkHook", GlobalThink)

-- Concommands

local function AdminDevToolValidation(ply)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then Reforger.Log("You are not admin.") end
    if GetConVar("developer"):GetInt() <= 0 then Reforger.Log("Developer mode disabled.") end
end

concommand.Add("reforger_init", function(ply)
    AdminDevToolValidation(ply)
    
    hook.Run("Reforger.Init")
    
    ply:ChatPrint("Manual reforge_init called")
end)
