--[[-------------------------------------------------------------------------
    [Reforger] Base (Framework)

    Unified system for advanced vehicle logic and damage simulation.
    Supports LVS / Simfphys / Gmod Glide. Open-source.

    Created by RareIridium77
    https://github.com/RareIridium77

-------------------------------------------------------------------------]]

local FCVAR_SERVER = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY)
local FCVAR_CLIENT = bit.bor(FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE)

Reforger = Reforger or {}
Reforger.CreatedConvars = Reforger.CreatedConvars or {}

local server_prefix = "reforger."
local client_prefix = "cl_reforger."

--// NOTE CLIENT Convars will created with "cl_reforger." prefix
--// NOTE SERVER Convars will created with "reforger." prefix

function Reforger.CreateConvar(name, value, helptext, min, max)
    if not isstring(name) or name == "" then return end
    if not isstring(value) then return end
    if not isstring(helptext) then helptext = SERVER and "is a server convar" or "is a client convar" end -- just to know
    if min ~= nil and not isnumber(min) then min = nil end
    if max ~= nil and not isnumber(max) then max = nil end

    local prefix = SERVER and server_prefix or client_prefix
    local fullname = prefix .. name

    if Reforger.CreatedConvars[fullname] then
        return Reforger.CreatedConvars[fullname]
    end

    if ConVarExists(fullname) then
        local cvar = GetConVar(fullname)
        Reforger.CreatedConvars[fullname] = cvar
        return cvar
    end

    if SERVER then
        Reforger.CreatedConvars[fullname] = CreateConVar(fullname, value, FCVAR_SERVER, helptext, min, max)
    else
        Reforger.CreatedConvars[fullname] = CreateConVar(fullname, value, FCVAR_CLIENT, helptext, min, max)
    end
    return Reforger.CreatedConvars[fullname]
end

function Reforger.Convar(name)
    if not isstring(name) or name == "" then return nil end

    local prefix = SERVER and server_prefix or client_prefix
    local fullname = prefix .. name

    if Reforger.CreatedConvars[fullname] then
        return Reforger.CreatedConvars[fullname]
    end

    if ConVarExists(fullname) then
        local cvar = GetConVar(fullname)
        Reforger.CreatedConvars[fullname] = cvar
        return cvar
    end

    return nil
end

function Reforger.SafeCvar(name, mode, fallback)
    local cvar = Reforger.Convar(name)
    if not cvar then return fallback or -1 end

    assert(isstring(mode), "mode is not STRING value")

    mode = string.lower(mode)

    if mode == "int" and isfunction(cvar.GetInt) then
        return cvar:GetInt()
    elseif mode == "float" and isfunction(cvar.GetFloat) then
        return cvar:GetFloat()
    elseif mode == "bool" and isfunction(cvar.GetBool) then
        return cvar:GetBool()
    elseif mode == "string" and isfunction(cvar.GetString) then
        return cvar:GetString()
    end

    return fallback or -1
end

function Reforger.SafeInt(name, fallback)
    return Reforger.SafeCvar(name, "int", fallback or -1)
end

function Reforger.SafeFloat(name, fallback)
    return Reforger.SafeCvar(name, "float", fallback or -1)
end