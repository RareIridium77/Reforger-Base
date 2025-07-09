--[[-------------------------------------------------------------------------
    [Reforger] Base v0.2.3 (Framework)

    Unified system for advanced vehicle logic and damage simulation.
    Supports LVS / Simfphys / Gmod Glide. Open-source.

    Created by RareIridium77
    https://github.com/RareIridium77

-------------------------------------------------------------------------]]

AddCSLuaFile()
AddCSLuaFile("reforger/core/shared/reforger_loader.lua")

Reforger = Reforger or {}

Reforger.VERSION = "0.2.3"
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

local ignoreK = {
    IsValidReforger = true,
    SafeToString = true,
    DevLog = true,
    Log
}

local function DisableReforger()
    if not istable(Reforger) then return end

    for k, v in pairs(Reforger) do
        if ignoreK[k] == true then continue end

        if isfunction(v) then
            Reforger[k] = function() end
        elseif istable(v) then
            for subk, subv in pairs(v) do
                if isfunction(subv) then
                    v[subk] = function() end
                end
            end
        end
    end

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
        Reforger.Log("Reforger version: " .. Reforger.VERSION)
    end)
end

local function EntityCreated(ent)
    if not Reforger.Init then return end
    timer.Simple(0, function()
        if not IsValid(ent) then return end
        if Reforger.IsValidReforger(ent) then
            Reforger.CallEntityFunctions(ent)
        end
    end)
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

-- Concommands

function Reforger.AdminDevToolValidation(ply)
    if not IsValid(ply) then return false end
    if not ply:IsAdmin() then Reforger.Log("You are not admin.") return false end
    if GetConVar("developer"):GetInt() <= 0 then Reforger.Log("Developer mode disabled.") return false end

    return true
end

concommand.Add("reforger.init", function(ply)
    if not Reforger.AdminDevToolValidation(ply) then return end
    
    hook.Run("Reforger.Init")
    
    ply:ChatPrint("Manual reforge_init called")
end)

concommand.Add("reforger.table", function(ply)
    if not Reforger.AdminDevToolValidation(ply) then return end
    
    PrintTable(Reforger)
end)

concommand.Add("reforger.reload", function(ply)
    if not Reforger.AdminDevToolValidation(ply) then return end

    Reforger = Reforger or {}
    Reforger.CreatedConvars = {}

    include("reforger/core/shared/reforger_loader.lua")("reforger")
    Reforger.DevLog("Reforger reloaded via concommand.")
    
    hook.Run("Reforger.Init")

    if IsValid(ply) then
        ply:ChatPrint("Reforger scripts reloaded.")
    else
        print("[Reforger] Scripts reloaded manually.")
    end
end)