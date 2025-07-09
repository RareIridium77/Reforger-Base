local FCVAR_SERVER = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY)
local FCVAR_CLIENT = bit.bor(FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE)

Reforger.CreatedConvars = Reforger.CreatedConvars or {}

local server_prefix = "reforger."
local client_prefix = "cl_reforger."


-- CLIENT Convars will created with "cl_reforger." prefix
-- SERVER Convars will created with "reforger." prefix

function Reforger.CreateConvar(name, value, helptext, min, max)
    if not isstring(name) or name == "" then return end
    if not isstring(value) then return end
    if not isstring(helptext) then helptext = SERVER and "is a server convar" or "is a client convar" end -- just to know
    if min ~= nil and not isnumber(min) then min = nil end
    if max ~= nil and not isnumber(max) then max = nil end

    local prefix = SERVER and server_prefix or client_prefix
    local fullname = prefix .. name

    if ConVarExists(fullname) or Reforger.CreatedConvars[fullname] then return end

    if SERVER then
        Reforger.CreatedConvars[fullname] = CreateConVar(fullname, value, FCVAR_SERVER, helptext, min, max)
    else
        Reforger.CreatedConvars[fullname] = CreateConVar(fullname, value, FCVAR_CLIENT, helptext, min, max)
    end
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

function Reforger.SafeInt(name, fallback)
    local cvar = Reforger.Convar(name)
    if cvar and isfunction(cvar.GetInt) then
        return cvar:GetInt()
    end
    return fallback or -1
end
