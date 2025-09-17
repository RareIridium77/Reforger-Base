--[[-------------------------------------------------------------------------
    [Reforger] Base (Framework)

    Unified system for advanced vehicle logic and damage simulation.
    Supports LVS / Simfphys / Gmod Glide. Open-source.

    Created by RareIridium77
    https://github.com/RareIridium77

-------------------------------------------------------------------------]]

--[[
    [Reforger] Base Framework

    Unified system for advanced vehicle logic and damage simulation.
    Supports multiple vehicle bases:
      * LVS
      * Simfphys
      * GMod Glide
    Created by RareIridium77 (GitHub: RareIridium77)

    Purpose:
    * Provides initialization of the Reforger framework
    * Handles compatibility checks (vehicle bases installed)
    * Manages network setup, global hooks, and reload logic

    Versioning:
    * Reforger.Version     → Current version number ("0.3")
    * Reforger.VersionType → Release type ("stable")

    Networking:
    * "Reforger.NotifyDisabled"  → Sent when framework is disabled server-side
    * "Reforger.InitializeEntity"→ Used to initialize entities

    Lifecycle:
    * InitPostEntity()
        - Verifies that at least one supported base exists
        - If none found, disables framework, removes hooks, warns server
        - Otherwise schedules `Reforger.Init` hook after 5 seconds
    * EntityCreated(ent)
        - Called when a new entity is created
        - Attempts to initialize entity under Reforger if valid
    * GlobalThink()
        - Runs every ~1ms
        - Dispatches `Reforger.GlobalThink` hook for internal logic

    Hooks:
    * OnEntityCreated → `Reforger:InitializeEntity` for all new entities
    * InitPostEntity  → Runs base compatibility check, sets up framework
    * Think           → Calls Reforger.GlobalThink with throttling
    * Reforger.Reload → Resets framework and reloads loader

    Special Features:
    * Automatic disabling if no LVS/Simfphys/Glide base found
    * Broadcasts disabled status to clients via net message
    * Provides developer log output and reload support
]]

AddCSLuaFile()
AddCSLuaFile("reforger/core/shared/reforger_loader.lua")

Reforger = Reforger or {}

Reforger.Version = "0.3"
Reforger.VersionType = "stable"
Reforger.CreatedConvars = Reforger.CreatedConvars or {}

if not Reforger.Init then include("reforger/core/shared/reforger_loader.lua")("reforger") end

if CLIENT then
    net.Receive("Reforger.NotifyDisabled", function()
        Reforger.Disabled = true
        chat.AddText(Color(255, 100, 100), "[Reforger] Framework disabled on server.")
        print("[Reforger] Framework disabled on server.")
    end)
end

local function EntityCreated(ent)
    if Reforger.Disabled then return end
    if not IsValid(ent) then return end
    Reforger:InitializeEntity(ent)
end
hook.Add("OnEntityCreated", "Reforger.EntityHook", EntityCreated)

if CLIENT then return end

if Reforger.Init then return end

util.AddNetworkString("Reforger.NotifyDisabled")
util.AddNetworkString("Reforger.InitializeEntity")

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
hook.Add("InitPostEntity", "Reforger.InitPostEntity", InitPostEntity)

local nextThink = 0
local thinkInterval = 0.001

local function GlobalThink()
    if CurTime() < nextThink then return end
    nextThink = CurTime() + thinkInterval

    if not Reforger.Init then return end
    hook.Run("Reforger.GlobalThink")
end

hook.Add("Think", "Reforger.GlobalThinkHook", GlobalThink)
hook.Add("Reforger.Reload", "Reforger.FReloaded", function()
    Reforger = Reforger or {}
    Reforger.CreatedConvars = {}

    include("reforger/core/shared/reforger_loader.lua")("reforger")
    Reforger.DevLog("Reforger reloaded via concommand.")
end)