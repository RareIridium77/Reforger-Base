// SECTION Reforger View Shared
local View = Reforger.View or {}

View.Type = {
    TPV = "tpv",  -- third-person view
    FPV = "fpv",  -- first-person view
    UV  = "uv"    -- undefined view
}

Reforger.View = View

function Reforger.View:GetViewType(ply)
    return ply.ReforgerView and ply:ReforgerView() or View.Type.FPV
end

local function IsClient() return CLIENT end
local function IsServer() return SERVER end

local plyMeta = FindMetaTable("Player")

function plyMeta:ReforgerView()
    local pod = self:GetVehicle()

    if IsValid(pod) then
        return pod:GetThirdPersonMode() and View.Type.TPV or View.Type.FPV
    end

    return View.Type.UV
end

function plyMeta:ReforgerShakeView(intensity, duration) // NOTE Does nothing on serverside
    if IsServer() then return end
    local scale = intensity or 1
    local time = duration or 0.5

    util.ScreenShake(self:GetPos(), scale * 5, 5, time, 100)
end


// !SECTION