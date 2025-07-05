-- This file contains Reforger logging functions

if CLIENT then return end -- overthinker moment

Reforger = Reforger or {}

local dev_cvar = GetConVar("developer")

function Reforger.Log(...)
    MsgC(
        Color(146, 236, 104), "[Reforger] ",
        Color(100, 178, 241), ..., "\n"
    )
end

function Reforger.DevLog(...)
    if not dev_cvar or dev_cvar:GetInt() <= 0 then return end

    local caller = debug.getinfo(2, "Slfn")
    local src = caller.short_src or "unknown"
    local filename = string.match(src, "([^\\/]+)%.lua$") or src
    local line = caller.currentline or "?"
    local func = caller.name or "?"

    MsgC(
        Color(128, 104, 236), "[Dev-Reforger] ",
        Color(200, 200, 200), "(" .. filename .. ":" .. line .. " - " .. func .. ") ",
        Color(100, 178, 241), ..., "\n"
    )
end

