--[[-------------------------------------------------------------------------
    [Reforger] Base (Framework)

    Unified system for advanced vehicle logic and damage simulation.
    Supports LVS / Simfphys / Gmod Glide. Open-source.

    Created by RareIridium77
    https://github.com/RareIridium77

-------------------------------------------------------------------------]]

AddCSLuaFile()
AddCSLuaFile("reforger/core/shared/reforger_loader.lua")

Reforger = Reforger or {}

Reforger.Version = "0.2.6"
Reforger.VersionType = "non-stable"
Reforger.CreatedConvars = Reforger.CreatedConvars or {}

include("reforger/core/shared/reforger_loader.lua")("reforger")

if CLIENT then
    net.Receive("Reforger.NotifyDisabled", function()
        Reforger.Disabled = true
        chat.AddText(Color(255, 100, 100), "[Reforger] Framework disabled on server.")
        print("[Reforger] Framework disabled on server.")
    end)
end

if CLIENT then return end

util.AddNetworkString("Reforger.NotifyDisabled")


local function DisableReforger()
    if not istable(Reforger) then return end
    Reforger = {Disabled = true}

    Reforger.Disabled = true
end

local function InitPostEntity()
    local noBases = not LVS and not simfphys and not Glide
    if noBases then
        Reforger.Log(Color(255, 155, 155), "[Reforger] No compatible vehicle base detected (LVS / Simfphys / Glide). Framework disabled.")

        DisableReforger() -- Disable whole Reforger нахуй

        hook.Remove("OnEntityCreated", "Reforger.EntityHook")
        hook.Remove("Think", "Reforger.GlobalThinkHook")
        ErrorNoHalt("You have no installed LVS/Glide/Simfphys BASE. Addon disabled.")

        timer.Simple(1, function()
            net.Start("Reforger.NotifyDisabled")
            net.Broadcast()
        end)

        return
    end

    timer.Simple(5, function()
        if Reforger.Disabled or Reforger.Init then return end
        
        hook.Run("Reforger.Init")

        Reforger.Init = true
        Reforger.Log("Reforger version: " .. Reforger.Version .. " : ".. Reforger.VersionType)
    end)
end

local function EntityCreated(ent)
    if not Reforger.Init then return end
    if not IsValid(ent) then return end
    Reforger.CallEntityFunctions(ent)
end

local nextThink = 0
local thinkInterval = 0.001

local function GlobalThink()
    if CurTime() < nextThink then return end
    nextThink = CurTime() + thinkInterval

    if not Reforger.Init then return end
    hook.Run("Reforger.GlobalThink")
end

hook.Add("InitPostEntity", "Reforger.InitPostEntity", InitPostEntity)
hook.Add("OnEntityCreated", "Reforger.EntityHook", EntityCreated)
hook.Add("Think", "Reforger.GlobalThinkHook", GlobalThink)
hook.Add("Reforger.Reload", "Reforger.FReloaded", function()
    Reforger = Reforger or {}
    Reforger.CreatedConvars = {}

    include("reforger/core/shared/reforger_loader.lua")("reforger")
    Reforger.DevLog("Reforger reloaded via concommand.")
end)