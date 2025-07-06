-- This file contains Reforger logging functions

if CLIENT then return end -- overthinker moment

Reforger = Reforger or {}

local dev_cvar = GetConVar("developer")

function Reforger.Log(...)
    local args = {...}

    MsgC(Color(146, 236, 104), "[Reforger] ")

    for _, arg in ipairs(args) do
        MsgC(Color(100, 178, 241), Reforger.SafeToString(arg))
    end

    MsgC("\n")
end

function Reforger.DevLog(...)
    if not dev_cvar or dev_cvar:GetInt() <= 0 then return end

    local caller = debug.getinfo(2, "Slfn")
    local src = caller.short_src or "unknown"
    local filename = string.match(src, "([^\\/]+)%.lua$") or src
    local line = caller.currentline or "?"
    local func = caller.name or "?"

    MsgC(Color(128, 104, 236), "[Dev-Reforger] ")
    MsgC(Color(200, 200, 200), "(" .. filename .. ":" .. line .. " - " .. func .. ") ")

    local args = {...}
    for _, arg in ipairs(args) do
        MsgC(Color(100, 178, 241), Reforger.SafeToString(arg))
    end

    MsgC("\n")
end

function Reforger.SafeToString(val)
    if val == nil then return "nil" end
    if isentity(val) and IsValid(val) then return tostring(val) .. " [" .. val:GetClass() .. "]" end
    if istable(val) then return "table: " .. tostring(val) end
    if isbool(val) then return val and "true" or "false" end
    return tostring(val)
end
