local FCVAR_SERVER = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY)
local FCVAR_CLIENT = bit.bor(FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE)

Reforger.CreatedConvars = Reforger.CreatedConvars or {}

function Reforger.CreateConvar(name, value, helptext, min, max)
    if not isstring(name) or name == "" then return end
    if not isstring(value) then return end
    if not isstring(helptext) then helptext = "" end
    if min ~= nil and not isnumber(min) then min = nil end
    if max ~= nil and not isnumber(max) then max = nil end

    local prefix = "reforger_"
    local fullname = prefix .. name

    -- Защита от повторного создания
    if ConVarExists(fullname) or Reforger.CreatedConvars[fullname] then return end

    local cvar

    if SERVER then
        cvar = CreateConVar(fullname, value, FCVAR_SERVER, helptext, min, max)
    elseif CLIENT then
        cvar = CreateConVar(fullname, value, FCVAR_CLIENT, helptext, min, max)
    end

    if IsValid(cvar) or cvar then
        Reforger.CreatedConvars[fullname] = cvar
    end
end

function Reforger.Convar(name)
    if not isstring(name) or name == "" then return nil end

    local fullname = "reforger_" .. name

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
    if not isstring(name) then return fallback or -1 end

    local cvar = Reforger.Convar(name)
    if cvar and (IsValid(cvar) or isfunction(cvar.GetInt)) then
        return cvar:GetInt()
    end

    return fallback or -1
end
