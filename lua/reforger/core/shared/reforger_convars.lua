--[[-------------------------------------------------------------------------
    [Reforger] Base (Framework)

    Unified system for advanced vehicle logic and damage simulation.
    Supports LVS / Simfphys / Gmod Glide. Open-source.

    Created by RareIridium77
    https://github.com/RareIridium77

-------------------------------------------------------------------------]]

--[[
    Reforger Convar System
    - Unified API for creating and accessing server/client convars
    - Prefixes:
        * Server convars → "reforger."
        * Client convars → "cl_reforger."
    - Functions:
        * CreateConvar(name, value, helptext, min, max)
            - Creates convar with proper prefix depending on realm
            - Stores and reuses references in Reforger.CreatedConvars
        * Convar(name)
            - Returns convar reference if it exists
        * SafeCvar(name, mode, fallback)
            - Safely retrieves convar value in given type ("int", "float", "bool", "string")
            - Returns fallback if missing
        * SafeInt(name, fallback)
        * SafeFloat(name, fallback)
            - Shorthands for numeric access
    - Safety:
        * Prevents duplicate creation
        * Validates input types and provides fallback values
]]

local FCVAR_SERVER = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY)
local FCVAR_CLIENT = bit.bor(FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE)

Reforger = Reforger or {}
Reforger.CreatedConvars = Reforger.CreatedConvars or {}

local cachedConvars = cachedConvars or {}

local server_prefix = "reforger."
local client_prefix = "cl_reforger."

function _cacheConvar(convar)
    local fullname = convar:GetName()
    cachedConvars[fullname] = convar:GetString() -- cache initial value

    cvars.AddChangeCallback(fullname, function(name, old, new)
        cachedConvars[name] = new
    end, "Reforger_"..fullname)
end

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
        _cacheConvar(cvar);
        return cvar
    end

    if SERVER then
        Reforger.CreatedConvars[fullname] = CreateConVar(fullname, value, FCVAR_SERVER, helptext, min, max)
    else
        Reforger.CreatedConvars[fullname] = CreateConVar(fullname, value, FCVAR_CLIENT, helptext, min, max)
    end

    _cacheConvar(Reforger.CreatedConvars[fullname])

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
    local prefix = SERVER and server_prefix or client_prefix
    local fullname = prefix .. name

    local value = cachedConvars[fullname]

    if not value then return fallback or -1 end

    mode = string.lower(mode)

    local numered = tonumber(value)

    if mode == "int" then
        return numered and math.floor(numered) or fallback
    elseif mode == "float" then
        return numered or fallback
    elseif mode == "bool" then
        return tobool(numered) or fallback
    elseif mode == "string" then
        return value
    end

    return fallback or -1
end

function Reforger.SafeInt(name, fallback)
    return Reforger.SafeCvar(name, "int", fallback or -1)
end

function Reforger.SafeFloat(name, fallback)
    return Reforger.SafeCvar(name, "float", fallback or -1)
end