-- This file contains Reforger logging functions

if CLIENT then return end -- overthinker moment

Reforger = Reforger or {}

local dev_cvar = GetConVar("developer")

function Reforger.Log(...)
    MsgC(Color(146, 236, 104), "[Reforger] ", Color(100, 178, 241), ..., "\n")
end

function Reforger.DevLog(...)
    if not dev_cvar or dev_cvar:GetInt() <= 0 then return end
    MsgC(Color(128, 104, 236), "[Dev-Reforger] ", Color(100, 178, 241), ..., "\n")
end