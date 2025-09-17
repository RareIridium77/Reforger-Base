--[[-------------------------------------------------------------------------
    [Reforger] Base (Framework)

    Unified system for advanced vehicle logic and damage simulation.
    Supports LVS / Simfphys / Gmod Glide. Open-source.

    Created by RareIridium77
    https://github.com/RareIridium77

-------------------------------------------------------------------------]]

--[[
    Reforger Logging System
    - Provides structured logging with levels and developer-only debug tracing.
    - Integrates with GMod console coloring for readability.

    Functions:
        * IsDeveloper()
            - Returns true if `developer` ConVar is enabled.

        * SLog(level, ...)
            - Core logging function
            - Skips DEV logs if not in developer mode
            - Adds file/line/function trace for DEV logs
            - Uses color-coded prefixes and safe string conversion

        * SafeToString(val)
            - Converts any type to readable string
            - Handles nil, entities, tables, and booleans gracefully

        * Log(...)
            - INFO log

        * WarnLog(...)
            - WARN log

        * DevLog(...)
            - DEV log, only visible in dev mode

        * ErrorLog(...)
            - ERROR log

    Notes:
        - Colors are taken from `Reforger.LogColors`
        - Levels are defined in `Reforger.LogLevels`
        - DEV logs print caller info (file, line, function)
]]

Reforger = Reforger or {}

local dev_cvar = GetConVar("developer")
local loglevels = Reforger.LogLevels

function Reforger.IsDeveloper()
    return dev_cvar and dev_cvar:GetInt() == 1 or false
end

local isdevmode = Reforger.IsDeveloper

function Reforger.SLog(level, ...)
    if level == loglevels.DEV and not isdevmode() then return end
    
    local args = {...}
    local colorLevel = Reforger.LogColors[level] or color_white

    MsgC(colorLevel, string.format("[%s-Reforger] ", level))

    if level == loglevels.DEV then
        local info = debug.getinfo(3, "Slfn")
        local src = info.short_src or "unknown"
        local file = src:match("([^\\/]+)%.lua$") or src
        local line = info.currentline or "?"
        local func = info.name or "?"

        MsgC(Reforger.LogColors.LOC, string.format("(%s:%s - %s) ", file, line, func))
    end

    for _, arg in ipairs(args) do
        MsgC(Reforger.LogColors.TEXT, Reforger.SafeToString(arg))
    end

    MsgC("\n")
end

function Reforger.SafeToString(val)
    if val == nil then return "nil" end
    if isentity(val) and IsValid(val) then
        return tostring(val) .. " [" .. val:GetClass() .. "]"
    end
    if istable(val) then return "table: " .. tostring(val) end
    if isbool(val) then return val and "true" or "false" end
    return tostring(val)
end

-- Removed Deprecation

function Reforger.Log(...) Reforger.SLog(loglevels.INFO, ...) end
function Reforger.WarnLog(...) Reforger.SLog(loglevels.WARN, ...) end
function Reforger.DevLog(...) Reforger.SLog(loglevels.DEV, ...) end
function Reforger.ErrorLog(...) Reforger.SLog(loglevels.ERROR, ...) end

