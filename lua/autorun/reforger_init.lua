AddCSLuaFile()
AddCSLuaFile("reforger/core/shared/reforger_loader.lua")

Reforger = Reforger or {}

Reforger.VERSION = "0.2.3"
Reforger.CreatedConvars = Reforger.CreatedConvars or {}

include("reforger/core/shared/reforger_loader.lua")("reforger")

if CLIENT then return end

local function InitPostEntity()
    timer.Simple(5, function()
        hook.Run("Reforger.Init")
        Reforger.Init = true
        Reforger.DevLog("Reforger version: "..Reforger.VERSION)
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

local function GlobalThink() hook.Run("Reforger.GlobalThink", Reforger) end

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
